extends "res://tests/test_case.gd"

## The shared host runtime is deliberately testable without a world: its link
## adapter is the boundary that prevents listen-server immunity, and terminal
## latching prevents each departing local presentation from re-running ecology.
const RUNTIME := preload("res://scripts/combat/shared_wild_host_fight.gd")


class Link extends Node:
	var pick: Dictionary = {}
	var picked: Array[Dictionary] = []
	var deliveries: Array[Dictionary] = []

	func host_pick_struck_participant(encounter_id: String, cfg: Dictionary,
			origin: Vector3, facing: Vector3) -> Dictionary:
		picked.append({"encounter_id": encounter_id, "cfg": cfg.duplicate(true),
			"origin": origin, "facing": facing})
		return pick.duplicate(true)

	func host_deliver_enemy_hit(encounter_id: String, peer_id: int, payload: Dictionary) -> void:
		deliveries.append({"encounter_id": encounter_id, "peer_id": peer_id,
			"payload": payload.duplicate(true)})


func test_shared_runtime_never_claims_the_host_as_the_local_fallback_peer() -> void:
	var runtime := RUNTIME.new()
	assert_eq(runtime.local_encounter_peer_id(), 0,
		"the host runtime must use its delivery adapter for host peer one")
	runtime.free()


func test_shared_runtime_forwards_pick_and_host_hit_through_its_authority_adapter() -> void:
	var link := Link.new()
	link.pick = {"peer_id": 1, "card": {"defence": 4.0}}
	var runtime := RUNTIME.new()
	runtime.authority_link = link
	var pick := runtime.host_pick_struck_participant("fight-1", {"power": 8.0},
		Vector3.ZERO, Vector3.FORWARD)
	runtime.host_deliver_enemy_hit("fight-1", 1, {"damage": 3.0})
	assert_eq(pick, link.pick)
	assert_eq(link.picked.size(), 1)
	assert_eq(str(link.picked[0].get("encounter_id", "")), "fight-1")
	assert_eq(link.deliveries, [{"encounter_id": "fight-1", "peer_id": 1,
		"payload": {"damage": 3.0}}])
	runtime.free()
	link.free()


func test_terminal_outcome_is_latched_so_ecology_can_finalize_once() -> void:
	var runtime := RUNTIME.new()
	assert_true(runtime.mark_terminal("won"))
	assert_eq(runtime.terminal_outcome, "won")
	assert_false(runtime.mark_terminal("caught"),
		"a later local manager exit must not run a second terminal lifecycle")
	assert_eq(runtime.terminal_outcome, "won")
	runtime.free()

class Body extends Node3D:
	var engagements: Array[bool] = []
	var _opponent: Node3D

	func set_engaged(value: bool, _target: Node3D = null) -> void:
		engagements.append(value)


func test_catch_pause_suspends_authority_physics_and_breakout_resumes_prior_state() -> void:
	var runtime := RUNTIME.new()
	var body := Body.new()
	var target := Node3D.new()
	body.set_physics_process(true)
	runtime.set("_wild", body)
	runtime.pause_for_catch()
	assert_eq(body.engagements, [false])
	assert_false(body.is_physics_processing(), "orb wobble must suspend host AI")
	runtime.resume_after_catch(target)
	assert_eq(body.engagements, [false, true])
	assert_true(body.is_physics_processing(), "breakout restores the pre-catch host simulation")
	runtime.set("_wild", null)
	body.free()
	target.free()
	runtime.free()
