extends "res://tests/test_case.gd"

class ClockKey extends "res://scripts/world/home_key.gd":
	var clock := 1000
	var progress := -1.0
	func _now_msec() -> int: return clock
	func _animate(value: float) -> void: progress = value

class GameDouble extends Node:
	var requests: Array[Dictionary] = []
	func home_key_refusal() -> String: return ""
	func request_portal_action(payload: Dictionary) -> Dictionary:
		requests.append(payload)
		return {"ok": true, "request_id": "finish-request"}

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
