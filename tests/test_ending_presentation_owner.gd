extends "res://tests/test_case.gd"

## Real sequence ownership method, synthetic UI/Session projections. No
## physical ending, save, or transport success is asserted here.
const DIRECTOR := preload("res://scripts/story/sequence_director.gd")
const ENDING := preload("res://scripts/story/regional_homecoming.gd")
const OWNER := preload("res://tests/fixtures/regional_ending_owner.gd")

class PanelFixture extends CanvasLayer:
	var closing_press: bool = true
	func owns_input() -> bool: return closing_press

class SessionFixture extends Node:
	var pending: bool = false
	var original: Dictionary = {}
	func _altar_current_epoch() -> String: return "epoch_a"
	func owns_input() -> bool: return pending
	func retained_training_transaction(_actions: Array) -> Dictionary:
		return {"intent": original.duplicate(true)}

class GameFixture extends RefCounted:
	var world := preload("res://autoload/world_state.gd").new()
	var local := OWNER.LocalStub.new()
	var party := OWNER.PartyStub.new()
	var session: Node

func test_completed_homecoming_retains_actual_ownership_through_closing_press_and_original_ack() -> void:
	var game := GameFixture.new()
	game.world.reward_delivery_namespace = "world_a"
	var session := SessionFixture.new()
	game.session = session
	var panel := PanelFixture.new()
	var director: Node = DIRECTOR.new()
	director.set("_dialogue", panel)
	var original := {"character_id": game.local.character_id, "world_instance_id": "world_a",
		"session_epoch": "epoch_a", "party_revision": 0, "party_signature": ENDING.party_signature(game.party),
		"outcome_id": "original_outcome", "home_return_receipt": "original_arrival"}
	director.set("_regional_presentation_id", "regional_homecoming_0")
	director.set("_regional_presentation_world", weakref(game.world))
	director.set("_regional_presentation_context", original.duplicate(true))
	# completed() consumes the speak-once context; the closing press still owns
	# the actual dialogue. F18's opening conversation field is deliberately empty.
	director.set("_homecoming_context", {})
	assert_true(director.call("owns_regional_presentation", panel, game))
	panel.closing_press = false
	assert_false(director.call("owns_regional_presentation", panel, game))
	session.pending = true
	session.original = ENDING.acknowledgement_intent(original, ENDING.SEEN_FLAG)
	assert_true(director.call("owns_regional_presentation", session, game))
	session.original.character_id = "foreign_character"
	assert_false(director.call("owns_regional_presentation", session, game))
	panel.closing_press = true
	game.party.revision = 1
	assert_false(director.call("owns_regional_presentation", panel, game))
	game.party.revision = 0
	game.world = preload("res://autoload/world_state.gd").new()
	game.world.reward_delivery_namespace = "world_a"
	assert_false(director.call("owns_regional_presentation", panel, game), "same namespace cannot replace actual world identity")
	director.free()
	panel.free()
	session.free()
