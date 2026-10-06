extends "res://tests/test_case.gd"

## A refused touch must release the stone for its next retry. Host and guest
## refusals carry the request id but not the stone id; before this the stone
## ignored them and stayed pending, silent, for the whole ack timeout.
class Stone extends "res://scripts/world/waystone.gd":
	var messages: Array[String] = []
	func _character_state() -> Dictionary: return {"character_id": "stone-owner"}
	func _message(text: String, _force: bool = false) -> void: messages.append(text)

var _stone: Stone

func before_each() -> void:
	_stone = Stone.new()
	_stone.waystone_id = "meadows_mill"
	_stone._pending = true
	_stone._pending_request_id = "epoch:3"

func after_each() -> void:
	_stone.free()

func _reply(extra: Dictionary) -> Dictionary:
	var reply := {"kind": "waystone_touch", "request_id": "epoch:3", "character_id": "stone-owner", "ok": false,
		"reason": "Your authoritative travel state is not ready."}
	reply.merge(extra, true)
	return reply

func test_refusal_without_stone_id_releases_and_names_the_reason() -> void:
	_stone._on_action_result(_reply({}))
	assert_false(_stone._pending, "the refusal releases the stone for its retry")
	assert_eq(_stone.messages, ["Your authoritative travel state is not ready."])

func test_other_requests_and_other_stones_are_ignored() -> void:
	_stone._on_action_result(_reply({"request_id": "epoch:2"}))
	assert_true(_stone._pending, "another request's reply is not ours")
	_stone._on_action_result(_reply({"waystone_id": "tidewake_dock"}))
	assert_true(_stone._pending, "an echoed different stone is not ours")
	_stone._on_action_result(_reply({"character_id": "someone-else"}))
	assert_true(_stone._pending, "another character's reply is not ours")
	assert_true(_stone.messages.is_empty())
