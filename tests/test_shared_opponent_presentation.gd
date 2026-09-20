extends "res://tests/test_case.gd"

## Pure protocol cases: this runner deliberately has no active SceneTree, so
## mounted transform and encounter-scene work stays with the two-peer smoke.

const PROXY := preload("res://scripts/creatures/shared_opponent_proxy.gd")
const CODEC := preload("res://scripts/save/water_capture_codec.gd")
const SPECIES := preload("res://scripts/creatures/creature_species.gd")


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
