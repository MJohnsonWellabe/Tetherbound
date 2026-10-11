extends "res://tests/test_case.gd"

## F27#1 finding (coordinator 2026-10-11): the clock rotation must not replace
## a just-decided action's row in the shared training slot before that action's
## requester has had time to read it. Real adapter check; fake world only.
const ADAPTER := preload("res://scripts/world/bounty_host_adapter.gd")
const ESSENCE := preload("res://scripts/creatures/essence.gd")
const BOARD := preload("res://scripts/world/bounty_board.gd")

class FakeWorld extends RefCounted:
	var reward_delivery_namespace := "world-ns"
	var reward_deliveries: Dictionary = {}

class FakeGame extends Node:
	var world := FakeWorld.new()

class FakeSession extends Node:
	var game := FakeGame.new()
	func _game() -> Node: return game


func test_the_morning_rotation_waits_after_a_newly_decided_harvest_row() -> void:
	var session := FakeSession.new()
	var adapter: Node = ADAPTER.new()
	adapter.set("_session", session)
	var id := ESSENCE.training_delivery_id("world-ns", "char-a")
	assert_false(adapter.call("_slot_settling", "char-a"), "an empty slot never holds the rotation")
	session.game.world.reward_deliveries[id] = {"action": "resource", "intent": {"source": "crop"}, "status": "accepted"}
	assert_true(float(BOARD.config().get("rotate_after_action_grace_s", 0.0)) > 0.0)
	assert_true(adapter.call("_slot_settling", "char-a"), "a just-accepted harvest row holds the rotation")
	adapter.get("_slot_seen")["char-a"]["since_ms"] = Time.get_ticks_msec() - 3600000
	assert_false(adapter.call("_slot_settling", "char-a"), "after the grace the rotation proceeds")
	session.game.world.reward_deliveries[id] = {"action": "bounty_claim", "intent": {"instance": "x"}, "status": "accepted"}
	assert_false(adapter.call("_slot_settling", "char-a"), "a bounty row never holds the rotation")
	adapter.free()
	session.game.free()
	session.free()
