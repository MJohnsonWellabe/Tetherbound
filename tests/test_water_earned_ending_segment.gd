extends "res://tests/test_case.gd"

const ENDING := preload("res://tests/helpers/water_earned_ending_segment.gd")
const PARTY := preload("res://autoload/party.gd")
const CREATURE := preload("res://scripts/creatures/creature_instance.gd")

class Flags extends RefCounted:
	var values: Dictionary = {}
	func has(key: String) -> bool:
		return values.has(key)

class WorldState extends RefCounted:
	var flags := Flags.new()
	var water_capture_claims: Dictionary = {}

class LocalState extends RefCounted:
	var flags := Flags.new()

class GameState extends Node:
	var world := WorldState.new()
	var local := LocalState.new()
	var party := PARTY.new()
	var pending_catch: RefCounted

func test_missing_live_entry_cannot_claim_ending() -> void:
	var segment := ENDING.new()
	var outcome: Dictionary = await segment.run_earned(null, null, null)
	assert_false(outcome.ok)
	assert_eq(outcome.failures.size(), 1)

func test_settlement_requires_personal_receipt_world_ack_and_exact_five() -> void:
	var game := GameState.new()
	for index in 5:
		assert_true(game.party.add(CREATURE.new()))
	var segment := ENDING.new()
	segment._game = game
	segment._carried_ids = segment._party_ids()
	segment._claim_id = "observed-guardian-claim"
	for flag in ENDING.END_FLAGS:
		game.world.flags.values[flag] = true
	assert_false(segment._settled(), "World flags alone do not prove the personal farewell")
	game.local.flags.values["water_capture_receipt:observed-guardian-claim"] = true
	game.world.water_capture_claims[segment._claim_id] = {}
	assert_false(segment._settled(), "Host must finish the durable acknowledgment")
	game.world.water_capture_claims.clear()
	game.pending_catch = CREATURE.new()
	assert_false(segment._settled(), "Pending newcomer is never a completed ceremony")
	game.pending_catch = null
	assert_true(segment._settled())
	for flag in ENDING.END_FLAGS:
		game.world.flags.values.erase(flag)
		assert_false(segment._settled(), flag)
		game.world.flags.values[flag] = true
	game.party.remove_at(4)
	assert_false(segment._settled(), "An ending cannot drop an owned slot")
	game.party.add(CREATURE.new())
	assert_false(segment._settled(), "Same count is not the same retained party")
	game.free()
