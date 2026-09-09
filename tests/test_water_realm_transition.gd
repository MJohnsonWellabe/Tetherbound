extends "res://tests/test_case.gd"

const STATE := preload("res://scripts/combat/water_alpha_state.gd")
const SPECIES := preload("res://scripts/creatures/creature_species.gd")
const ARBITER := preload("res://scripts/net/catch_arbiter.gd")
const MANAGER := preload("res://scripts/combat/combat_manager.gd")

class Transport extends "res://scripts/net/water_alpha_transport.gd":
	var permit := false
	var calls: Array = []
	var committed: Array = []
	func _transition_allowed(peer: int, completing: bool) -> bool:
		calls.append([peer, completing])
		return permit
	func _commit(intent: Dictionary, peer: int) -> Dictionary:
		committed.append([peer, intent.kind])
		return {"ok": true}

class Veilfall extends "res://scripts/net/water_veilfall_transport.gd":
	var calls: Array = []
	func _transition_allowed(peer: int, completing: bool) -> bool:
		calls.append([peer, completing])
		return false

class Director extends "res://scripts/combat/encounter_director.gd":
	func _is_host() -> bool:
		return true

class Alpha extends "res://scripts/combat/water_alpha.gd":
	var snapshots: Array = []
	func is_alpha_authority() -> bool:
		return true
	func _publish_snapshot() -> void:
		snapshots.append(authority.record().duplicate(true))

func test_water_submit_completion_names_and_receiver_dispatch() -> void:
	var transport := Transport.new()
	for kind: String in ["engage", "strike_intent", "attune", "catch_attempt", "catch_finished", "disengage"]:
		var result: Dictionary = transport.submit({"kind": kind})
		assert_false(result.pending, "refusal must not strand a pending request")
		assert_eq(result.kind, kind, "caller can settle its specific pending state")
	assert_eq(transport.calls, [[1, false], [1, false], [1, false], [1, false], [1, true], [1, true]])
	assert_false(transport._commit_if_allowed({"kind": "engage"}, 20).ok)
	assert_true(transport.committed.is_empty(), "closed inbound gate precedes virtual service dispatch")
	transport.permit = true
	assert_true(transport._commit_if_allowed({"kind": "engage"}, 20).ok)
	assert_eq(transport.committed, [[20, "engage"]], "prefence receiver permission executes original request")
	transport.permit = false
	transport.deliver(20, "snapshot", {})
	assert_eq(transport.calls.back(), [20, true], "results use receiver completion gate before world access")
	transport.free()

func test_veilfall_inherits_closed_request_and_response_gates() -> void:
	var transport := Veilfall.new()
	assert_false(transport.submit({"kind": "veilfall_control"}).pending)
	assert_false(transport._commit_if_allowed({"kind": "guardian_offer"}, 20).ok)
	transport.deliver(20, "verdict", {})
	assert_eq(transport.calls, [[1, false], [20, true], [20, true]])
	transport.free()

func _alpha_world() -> Node:
	var world := Node.new()
	var primary := Director.new()
	primary.name = "EncounterDirector"
	world.add_child(primary)
	var alpha := Alpha.new()
	alpha.name = "WaterAlpha"
	world.add_child(alpha)
	alpha.primary = primary
	alpha.authority = STATE.new()
	var enemy := SPECIES.spawn("water_aquaryn")
	alpha.authority.engage(20, "departing", "creature-a", enemy)
	alpha.authority.engage(30, "staying", "creature-b", enemy)
	alpha.set("_catch_arbiter", ARBITER.new())
	# The primary and Alpha deliberately have different encounter authorities.
	primary.set("_encounter_host", preload("res://scripts/net/encounter_host.gd").new())
	return world

func test_primary_callback_retires_alpha_and_releases_catch_without_losing_durable_result() -> void:
	var world := _alpha_world()
	var primary: Node = world.get_node("EncounterDirector")
	var alpha: Node = world.get_node("WaterAlpha")
	var state: RefCounted = alpha.authority
	var arbiter: RefCounted = alpha.get("_catch_arbiter")
	arbiter.claims[state.encounter_id] = {"peer": 20, "at_ms": Time.get_ticks_msec()}
	state.resolution = {"outcome": "defeated", "durable_fixture": true}
	primary.realm_transition_departing(20)
	assert_false(state.host.is_participant(state.encounter_id, 20))
	assert_true(state.host.is_participant(state.encounter_id, 30))
	assert_false(arbiter.claims.has(state.encounter_id))
	assert_true(state.eligible_characters.has("departing"), "ordinary departure must not erase reward eligibility")
	assert_eq(state.resolution, {"outcome": "defeated", "durable_fixture": true})
	assert_eq(alpha.snapshots.size(), 1, "final authority snapshot is queued before callback returns")
	primary.realm_transition_departing(20)
	assert_eq(alpha.snapshots.size(), 1, "duplicate withdrawal is inert")
	world.free()

func test_primary_settlement_tracks_only_local_pending_results_not_active_fights() -> void:
	var world := _alpha_world()
	var primary: Node = world.get_node("EncounterDirector")
	var alpha: Node = world.get_node("WaterAlpha")
	var manager := MANAGER.new()
	world.add_child(manager)
	primary.set("_manager", manager)
	manager.state = MANAGER.State.ACTIVE
	assert_true(primary.realm_transition_results_settled(), "an active fight alone is not a wait condition")
	for pending: String in ["_engage_pending", "_attune_pending", "_catch_finish_pending"]:
		alpha.set(pending, true)
		assert_false(primary.realm_transition_results_settled())
		alpha.set(pending, false)
		assert_true(primary.realm_transition_results_settled())
	manager.state = MANAGER.State.RESOLVING
	assert_false(primary.realm_transition_results_settled(), "local committed result must finish before drain")
	world.free()
