extends "res://tests/test_case.gd"

## Pure protocol cases: this runner deliberately has no active SceneTree, so
## mounted transform and encounter-scene work stays with the two-peer smoke.

const PROXY := preload("res://scripts/creatures/shared_opponent_proxy.gd")
const CODEC := preload("res://scripts/save/water_capture_codec.gd")
const SPECIES := preload("res://scripts/creatures/creature_species.gd")
const COMBAT_MANAGER := preload("res://scripts/combat/combat_manager.gd")


class ProxyShell extends "res://scripts/creatures/shared_opponent_proxy.gd":
	func _ready() -> void:
		pass


class DirectorShell extends "res://scripts/combat/encounter_director.gd":
	var submitted: Array[Dictionary] = []

	func _ready() -> void:
		pass

	func submit_encounter_intent(intent: Dictionary) -> Dictionary:
		submitted.append(intent.duplicate(true))
		return {"ok": true, "pending": true}

	func _local_peer_id() -> int:
		return 22

	func _encounter_realm() -> String:
		return "meadows"

	func _realm_rpc_allowed(_peer: int, _completing: bool = false) -> bool:
		return true


class CatchLink extends Node:
	var reply: Dictionary = {"ok": false, "pending": true}

	func confirm_shared_catch_finish(_encounter_id: String, _claim_id: String) -> Dictionary:
		return reply.duplicate(true)


class ThrowShell extends Node:
	var clears := 0

	func resting_orb() -> Node3D:
		return null

	func clear_orb() -> void:
		clears += 1


class ManagerShell extends "res://scripts/combat/combat_manager.gd":
	var resolved := ""

	func _begin_resolve(outcome: String) -> void:
		resolved = outcome
		_outcome = outcome
		state = State.RESOLVING


class VerdictManagerShell extends Node:
	var accept := false

	func apply_host_catch_verdict(_verdict: Dictionary) -> bool:
		return accept

func _proxy(generation: int = 7) -> ProxyShell:
	var proxy := ProxyShell.new()
	proxy.body_generation = generation
	# Avoid the initial transform write: test packet validation and ordering
	# without a SceneTree-shaped fixture.
	proxy._pose_received = true
	return proxy


func _card() -> RefCounted:
	var host_instance: RefCounted = SPECIES.spawn("bramblebun")
	assert_true(host_instance != null, "fixture species is available")
	if host_instance == null:
		return null
	var payload := CODEC.encode(host_instance)
	assert_false(payload.is_empty(), "host card uses the canonical capture schema")
	return CODEC.decode(payload)


func _manager_waiting_for_finish(reply: Dictionary) -> Dictionary:
	var manager := ManagerShell.new()
	var link := CatchLink.new()
	var thrower := ThrowShell.new()
	link.reply = reply.duplicate(true)
	manager.set("_encounter_link", link)
	manager.set("_encounter_id", "fight-a")
	manager.set("_catch_claim_id", "claim-a")
	manager.set("_catch_finish_requires_host", true)
	manager.set("_catch_phase", COMBAT_MANAGER.CatchPhase.VERDICT)
	manager.set("_catch_succeeded", true)
	manager.set("_throw", thrower)
	manager.set("state", COMBAT_MANAGER.State.ACTIVE)
	return {"manager": manager, "link": link, "thrower": thrower}


func test_configure_rejects_invalid_card_or_generation_before_mutation() -> void:
	var proxy := _proxy()
	assert_false(proxy.configure_presentation(null, 7, Vector3.ZERO, Vector3.FORWARD, 0.05))
	assert_false(proxy.configure_presentation(_card(), 0, Vector3.ZERO, Vector3.FORWARD, 0.05))
	assert_eq(proxy.body_generation, 7, "invalid setup cannot replace the active generation")
	proxy.free()


func test_pose_rejects_malformed_generation_and_nonmonotonic_packets() -> void:
	var proxy := _proxy()
	assert_false(proxy.apply_pose(0, 1, Vector3.ZERO, Vector3.FORWARD), "wrong generation is refused")
	assert_false(proxy.apply_pose(7, 0, Vector3.ZERO, Vector3.FORWARD), "zero sequence is refused")
	assert_true(proxy.apply_pose(7, 2, Vector3(4, 0, 3), Vector3.RIGHT))
	assert_false(proxy.apply_pose(7, 2, Vector3(5, 0, 3), Vector3.RIGHT), "duplicate pose cannot rewind target")
	assert_false(proxy.apply_pose(7, 1, Vector3(1, 0, 3), Vector3.LEFT), "late pose cannot rewind target")
	assert_false(proxy.apply_pose(7, 3, Vector3.INF, Vector3.FORWARD), "nonfinite position is refused")
	assert_false(proxy.apply_pose(7, 3, Vector3.ZERO, Vector3.INF), "nonfinite facing is refused")
	assert_eq(proxy.last_pose_seq, 2)
	proxy.free()


func test_cues_are_global_serial_and_do_not_replay_out_of_order() -> void:
	var proxy := _proxy()
	assert_true(proxy.present_telegraph(2, 0.4, 1))
	assert_false(proxy.present_telegraph(2, 0.4, 2), "duplicate telegraph does not replay")
	assert_false(proxy.present_strike(1, 1), "older strike cannot follow newer telegraph")
	assert_true(proxy.present_strike(3, 1))
	assert_false(proxy.present_strike(3, 2), "duplicate strike does not replay")
	assert_eq(proxy.telegraph_count, 1)
	assert_eq(proxy.strike_count, 1)
	proxy.free()


func test_malformed_telegraph_duration_cannot_claim_a_cue_serial() -> void:
	var proxy := _proxy()
	assert_false(proxy.present_telegraph(1, NAN, 1))
	assert_eq(proxy.last_cue_serial, 0)
	assert_eq(proxy.telegraph_count, 0)
	proxy.free()


func test_catch_breakout_reengage_cannot_start_guest_ai() -> void:
	var proxy := _proxy()
	var opponent := Node3D.new()
	proxy.set_engaged(true, opponent)
	assert_false(proxy.engaged, "guest proxy never accepts a catch-breakout AI activation")
	opponent.free()
	proxy.free()

func test_pending_join_timeout_tombstones_and_disengages_once() -> void:
	var director := DirectorShell.new()
	director._pending_shared_join_id = "fight-timeout"
	director._pending_shared_join_deadline_ms = 0
	director._tick_pending_shared_join()
	assert_eq(director._pending_shared_join_id, "")
	assert_true(director._cancelled_shared_joins.has("fight-timeout"))
	assert_eq(director.submitted, [{"kind": "disengage", "encounter_id": "fight-timeout"}])
	director.free()


func test_late_record_for_cancelled_join_never_creates_presentation() -> void:
	var director := DirectorShell.new()
	director._cancelled_shared_joins = {"fight-late": true}
	director._rpc_encounter_record({
		"kind": "wild", "realm": "meadows", "encounter_id": "fight-late",
		"participants": {22: {"character_id": "guest"}},
	})
	var state: Dictionary = director.shared_opponent_presentation()
	assert_eq(str(state.get("active_encounter_id", "")), "")
	assert_eq(str(state.get("pending_encounter_id", "")), "")
	assert_eq(director.submitted, [{"kind": "disengage", "encounter_id": "fight-late"}],
		"late admitted record is answered only with cleanup")
	director.free()


func test_catch_finish_waits_for_the_exact_claim_reply() -> void:
	var director := DirectorShell.new()
	var pending: Dictionary = director.confirm_shared_catch_finish("fight-a", "claim-a")
	assert_true(bool(pending.get("pending", false)))
	assert_eq(director.submitted, [{"kind": "catch_finished",
		"encounter_id": "fight-a", "claim_id": "claim-a"}])
	director._receive_catch_finish_verdict({"ok": true, "kind": "catch_finished",
		"encounter_id": "fight-b", "claim_id": "claim-b",
		"delta": {"caught": true, "creature": CODEC.encode(_card())}})
	assert_true(bool(director.confirm_shared_catch_finish("fight-a", "claim-a").get(
		"pending", false)), "a different encounter/claim reply is ignored")
	var card := CODEC.encode(_card())
	director._receive_catch_finish_verdict({"ok": true, "kind": "catch_finished",
		"encounter_id": "fight-a", "claim_id": "claim-a",
		"delta": {"caught": true, "claim_id": "claim-a", "creature": card}})
	var confirmed: Dictionary = director.confirm_shared_catch_finish("fight-a", "claim-a")
	assert_true(bool(confirmed.get("ok", false)))
	assert_true(bool(confirmed.get("caught", false)))
	assert_eq(str((confirmed.get("creature", {}) as Dictionary).get("species_id", "")),
		"bramblebun", "the host's canonical card is the only capture payload")
	director.free()


func test_catch_finish_timeout_is_terminal_and_late_success_is_ignored() -> void:
	var director := DirectorShell.new()
	director._shared_catch_finish_pending = {"encounter_id": "fight-a", "claim_id": "claim-a",
		"deadline_ms": 0}
	var timed_out: Dictionary = director.confirm_shared_catch_finish("fight-a", "claim-a")
	assert_false(bool(timed_out.get("pending", true)))
	assert_false(bool(timed_out.get("ok", true)))
	assert_eq(str(timed_out.get("code", "")), "finish_timeout")
	director._receive_catch_finish_verdict({"ok": true, "kind": "catch_finished",
		"encounter_id": "fight-a", "claim_id": "claim-a",
		"delta": {"caught": true, "creature": CODEC.encode(_card())}})
	assert_eq(str(director.confirm_shared_catch_finish("fight-a", "claim-a").get(
		"code", "")), "finish_timeout", "late success cannot resurrect a timed-out catch")
	director.free()


func test_cached_finish_retry_is_bound_to_peer_encounter_and_claim() -> void:
	var director := DirectorShell.new()
	var verdict := {"ok": true, "pending": false, "kind": "catch_finished",
		"peer": 22, "encounter_id": "fight-a", "claim_id": "claim-a",
		"code": "", "reason": "", "delta": {"caught": false, "claim_id": "claim-a"}}
	director._shared_catch_finish_results["claim-a"] = {"encounter_id": "fight-a", "peer": 22,
		"expires_ms": Time.get_ticks_msec() + 10_000, "verdict": verdict}
	assert_eq(director._host_catch_finished({"encounter_id": "fight-a",
		"claim_id": "claim-a"}, 22), verdict,
		"an exact accepted retry survives runtime disposal")
	var wrong_peer: Dictionary = director._host_catch_finished({"encounter_id": "fight-a",
		"claim_id": "claim-a"}, 23)
	assert_false(bool(wrong_peer.get("ok", true)))
	assert_eq(str(wrong_peer.get("code", "")), "not_claimant",
		"the cached result is not a bearer token for another sender")
	director.free()


func test_manager_grants_only_after_exact_canonical_finish_confirmation() -> void:
	var pending_fixture := _manager_waiting_for_finish({"ok": false, "pending": true})
	var pending: ManagerShell = pending_fixture["manager"]
	pending._finish_catch()
	assert_eq(int(pending.get("_catch_phase")), COMBAT_MANAGER.CatchPhase.VERDICT,
		"pending confirmation keeps the catch at its verdict")
	assert_eq(pending.resolved, "")
	assert_eq(pending.caught_instance(), null, "a wobble alone never grants a creature")
	(pending_fixture["link"] as Node).free()
	(pending_fixture["thrower"] as Node).free()
	pending.free()

	var refused_fixture := _manager_waiting_for_finish({"ok": false, "pending": false,
		"caught": false, "code": "not_claimant", "reason": "That claim expired."})
	var refused: ManagerShell = refused_fixture["manager"]
	refused._finish_catch()
	assert_ne(refused.resolved, COMBAT_MANAGER.OUTCOME_CAUGHT)
	assert_eq(refused.caught_instance(), null, "host refusal cannot grant the local enemy")
	(refused_fixture["link"] as Node).free()
	(refused_fixture["thrower"] as Node).free()
	refused.free()

	var canonical := _card()
	canonical.nickname = "Host Canonical"
	var accepted_fixture := _manager_waiting_for_finish({"ok": true, "pending": false,
		"caught": true, "creature": CODEC.encode(canonical)})
	var accepted: ManagerShell = accepted_fixture["manager"]
	accepted._finish_catch()
	assert_eq(accepted.resolved, COMBAT_MANAGER.OUTCOME_CAUGHT)
	var caught: RefCounted = accepted.caught_instance()
	assert_true(caught != null)
	assert_eq(str(caught.nickname), "Host Canonical",
		"the granted creature is decoded from the host's canonical card")
	(accepted_fixture["link"] as Node).free()
	(accepted_fixture["thrower"] as Node).free()
	accepted.free()


func test_stale_attempt_verdict_does_not_erase_current_finish_wait() -> void:
	var director := DirectorShell.new()
	var manager := VerdictManagerShell.new()
	director._manager = manager
	director._shared_catch_finish_pending = {"encounter_id": "fight-b", "claim_id": "claim-b"}
	director._shared_catch_finish_reply = {"encounter_id": "fight-b", "claim_id": "claim-b",
		"ok": true}
	director._deliver_encounter_verdict({"kind": "catch_attempt", "encounter_id": "fight-a",
		"attempt": 1, "ok": true})
	assert_false(director._shared_catch_finish_pending.is_empty(),
		"a stale attempt rejected by the manager cannot erase the current finish wait")
	assert_false(director._shared_catch_finish_reply.is_empty())
	manager.accept = true
	director._deliver_encounter_verdict({"kind": "catch_attempt", "encounter_id": "fight-b",
		"attempt": 2, "ok": true})
	assert_true(director._shared_catch_finish_pending.is_empty(),
		"the attempt actually accepted by the manager begins a fresh finish lifecycle")
	assert_true(director._shared_catch_finish_reply.is_empty())
	manager.free()
	director.free()


func test_offline_exact_attempt_refusal_clears_wait_without_grant() -> void:
	var director := DirectorShell.new()
	var manager_fixture := _manager_waiting_for_finish({"ok": false, "pending": true})
	var manager: ManagerShell = manager_fixture["manager"]
	manager.set("_catch_finish_requires_host", false)
	manager.set("_catch_claim_id", "")
	manager.set("_catch_phase", COMBAT_MANAGER.CatchPhase.NONE)
	manager.set("_catch_awaiting_host", true)
	manager.set("_catch_attempt_requires_exact", true)
	manager.set("_catch_awaiting_attempt", 7)
	director._manager = manager
	var refusal: Dictionary = director._encounter_pending({"kind": "catch_attempt",
		"encounter_id": "fight-a", "attempt": 7}, false,
		"You are not connected to this world.")
	assert_eq(str(refusal.get("encounter_id", "")), "fight-a")
	assert_eq(int(refusal.get("attempt", 0)), 7)
	director._deliver_encounter_verdict(refusal)
	assert_false(bool(manager.get("_catch_awaiting_host")),
		"a synchronous offline refusal completes the exact pending request")
	assert_eq(manager.caught_instance(), null)
	assert_ne(manager.resolved, COMBAT_MANAGER.OUTCOME_CAUGHT)
	(manager_fixture["link"] as Node).free()
	(manager_fixture["thrower"] as Node).free()
	manager.free()
	director.free()
