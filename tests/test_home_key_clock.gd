extends "res://tests/test_case.gd"

class ClockKey extends "res://scripts/world/home_key.gd":
	var clock := 1000
	var progress := -1.0
	func _now_msec() -> int: return clock
	func _animate(value: float) -> void: progress = value

class GameDouble extends Node:
	var requests: Array[Dictionary] = []
	var messages: Array[String] = []
	var local := preload("res://autoload/player_state.gd").new()
	var world := preload("res://autoload/world_state.gd").new()
	var session: Node
	func push_world_message(message: String) -> void: messages.append(message)
	func home_key_refusal() -> String: return ""
	func request_portal_action(payload: Dictionary) -> Dictionary:
		requests.append(payload)
		return {"ok": true, "request_id": "finish-request"}

class EpochSession extends Node:
	var epoch := "epoch"
	func _altar_current_epoch() -> String: return epoch

func test_assigned_key_refusal_binding_preserves_modal_and_aim_input() -> void:
	var key_script := preload("res://scripts/world/home_key.gd")
	var press := InputEventAction.new()
	press.action = "hotbar_2"
	press.pressed = true
	assert_true(key_script.refusal_binding(press, ["food", "home_key", "", "", ""], false, false))
	assert_false(key_script.refusal_binding(press, ["home_key", "food"], false, false), "other assigned items are untouched")
	assert_false(key_script.refusal_binding(press, ["food", "home_key"], true, true), "aim cancel/throw is not key use")
	press.pressed = false
	assert_false(key_script.refusal_binding(press, ["food", "home_key"], false, false), "release is not another press")
	press.pressed = true
	press.action = "combat_item_1"
	assert_true(key_script.refusal_binding(press, ["home_key", ""], true, false), "slot1 uses actual combat mapping")
	assert_false(key_script.refusal_binding(press, ["home_key", ""], false, false))
	press.action = "hotbar_1"
	assert_false(key_script.refusal_binding(press, ["home_key", ""], true, false), "shared combat cancel mapping is untouched")
	assert_true(key_script.refusal_binding(press, ["home_key", ""], false, false))

func test_production_raise_uses_host_clock_despite_capped_frame_delta() -> void:
	var key := ClockKey.new()
	var game := GameDouble.new()
	var actor := Node3D.new()
	var rig := Skeleton3D.new()
	key._game = game
	key._settings = {"raise_seconds": 2.0, "response_timeout_seconds": 12.0}
	key._actor = actor
	key._rig = rig
	key._phase = "raising"
	key._use_id = "approved-use"
	key._raise_started_msec = 1000
	key._wait_started_msec = 1000
	key.clock = 2999
	key._process(0.016)
	assert_eq(key._phase, "raising", "host minimum cannot be shortened")
	assert_eq(game.requests.size(), 0)
	key.clock = 3500
	key._process(0.016)
	assert_eq(key.progress, 1.0)
	assert_eq(key._phase, "finishing", "2.5 wall seconds finish despite only .032 delta seconds")
	assert_eq(game.requests, [{"kind": "home_key_finish", "use_id": "approved-use"}])
	assert_eq(key._wait_started_msec, 3500, "reply timeout starts at this request")
	key.free()
	rig.free()
	actor.free()
	game.free()

func test_consumed_permit_handoff_keeps_original_result_without_animation_timeout() -> void:
	var key := ClockKey.new()
	var game := GameDouble.new()
	game.session = EpochSession.new()
	game.add_child(game.session)
	key._game = game
	key._settings = {"raise_seconds": 2.0, "response_timeout_seconds": 12.0}
	key._phase = "finishing"
	key._pending = "finish-request"
	key._use_id = "approved-use"
	key._wait_started_msec = 1000
	key.travel_started("another-request")
	assert_eq(key._phase, "finishing", "a different request cannot hand off")
	key.travel_started("finish-request")
	assert_eq(key._phase, "travelling")
	assert_true(key.owns_input())
	key.clock = 75000
	key._process(0.016)
	assert_eq(game.requests.size(), 0, "cold loading cannot cancel the consumed channel")
	assert_eq(key._pending, "finish-request", "the durable result still owns completion")
	key._result({"kind": "home_key_finish", "request_id": "another-request", "ok": true})
	assert_eq(key._phase, "travelling")
	key._result({"kind": "home_key_finish", "request_id": "finish-request", "ok": true, "saved": true})
	assert_eq(key._phase, "idle")
	assert_false(key.owns_input())
	key.free()
	game.free()

func test_waiting_save_releases_controls_and_identity_change_retires_only_presentation() -> void:
	var key := ClockKey.new()
	var game := GameDouble.new()
	game.session = EpochSession.new()
	game.add_child(game.session)
	key._game = game
	key._settings = {"raise_seconds": 2.0, "response_timeout_seconds": 12.0}
	key._phase = "finishing"
	key._pending = "finish-request"
	key.travel_started("finish-request")
	key.save_waiting("another-request")
	assert_true(key.owns_input())
	key.save_waiting("finish-request")
	assert_eq(key._phase, "settling")
	assert_false(key.owns_input(), "a failed writer cannot hold movement forever")
	assert_eq(key._pending, "finish-request", "original durable reply remains bound")
	assert_false(key.use(), "waiting original cannot start another trip")
	assert_eq(game.requests.size(), 0)
	game.world = preload("res://autoload/world_state.gd").new()
	key._process(0.016)
	assert_eq(key._phase, "idle", "Save/Load replacement retires stale presentation")
	assert_eq(game.requests.size(), 0, "retirement never cancels/ACKs/mints a permit")
	key._phase = "finishing"
	key._pending = "finish-request"
	key.travel_started("finish-request")
	game.session.epoch = "new-epoch"
	key._process(0.016)
	assert_eq(key._phase, "idle", "session epoch loss releases stale travel")
	key.free()
	game.free()
