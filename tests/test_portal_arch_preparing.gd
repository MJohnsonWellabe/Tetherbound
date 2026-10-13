extends "res://tests/test_case.gd"

## A guest's host answers portal_enter NOT_READY while it builds that guest's
## realm shell. One press is enough: the arch holds it, shows "Preparing the
## way…" and queues it again while the player is in reach, within its bound.

class GameDouble extends Node:
	var requests: Array[Dictionary] = []
	var messages: Array[String] = []
	var player := Node3D.new()
	func push_world_message(message: String) -> void: messages.append(message)
	func find_player() -> Node3D: return player
	func portal_view(_arch_id: String) -> Dictionary: return {"ready": true, "open": true}
	func request_portal_action(payload: Dictionary) -> Dictionary:
		requests.append(payload)
		return {"ok": true, "request_id": "enter-%d" % requests.size()}

class PromptDouble extends Node3D:
	var in_reach := true
	var label := ""
	var actionable := true
	func interaction_offer(_from: Vector3) -> Dictionary: return {"label": label} if in_reach else {}

func _arch(game: GameDouble) -> Node3D:
	var arch: Node3D = load("res://scripts/world/portal_arch.gd").new()
	arch.arch_id = "stormwood"
	arch._row = {"id": "stormwood", "kind": "live", "biome": "stormwood"}
	arch._settings = {"refresh_seconds": 0.25, "response_timeout_seconds": 12.0,
		"not_ready_retry_seconds": 0.0, "not_ready_retry_limit_seconds": 60.0}
	arch._game = game
	arch._prompt = PromptDouble.new()
	return arch

func test_a_not_ready_enter_is_held_and_queued_again_while_in_reach() -> void:
	var game := GameDouble.new()
	var arch := _arch(game)
	assert_true(arch._queue("portal_enter"))
	arch._result({"kind": "portal_enter", "ok": false, "request_id": "enter-1", "reason": arch.NOT_READY})
	assert_eq(game.messages, ["Preparing the way…"], "said once, not the refusal")
	assert_eq(arch._prompt.label, "Preparing the way…")
	assert_false(arch._prompt.actionable, "a second press is not offered meanwhile")
	arch._process(0.016)
	assert_eq(game.requests.size(), 2, "the same enter is queued again")
	assert_eq(game.requests[1], {"kind": "portal_enter", "arch_id": "stormwood"})
	arch._result({"kind": "portal_enter", "ok": false, "request_id": "enter-2", "reason": arch.NOT_READY})
	assert_eq(game.messages.size(), 1)
	arch._prompt.in_reach = false
	arch._process(0.016)
	assert_eq(game.requests.size(), 2, "a player who walked away is not sent through")
	assert_eq(arch._retry_at_msec, -1)
	arch._prompt.in_reach = true
	assert_true(arch._queue("portal_enter"))
	arch._result({"kind": "portal_enter", "ok": false, "request_id": "enter-3", "reason": "Stand at the arch."})
	assert_eq(game.messages.back(), "Stand at the arch.", "any other answer is shown as before")
	arch._prompt.free()
	arch.free()
	game.player.free()
	game.free()
