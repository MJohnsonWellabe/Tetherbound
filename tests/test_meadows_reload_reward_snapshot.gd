extends "res://tests/test_case.gd"

const SNAPSHOT := preload("res://tests/helpers/meadows_reload_reward_snapshot.gd")

class Personal extends RefCounted:
	var redesign_character: Dictionary = {}

class RewardGameFixture extends Node:
	var local: RefCounted = Personal.new()

func _state() -> Dictionary:
	return {"party": [{"uid": "retained", "hp": 40.0, "xp": 5,
		"known_moves": ["learned_move"], "move_mastery_receipts": {"learned_move": ["fight1"]}}],
		"inventory": {"0": {"id": "orb_greater", "n": 2}},
		"redesign_character": {"essence": {"ground": 100}, "creatures": {
			"retained": {"breakthroughs": [10], "trait_primary": "hardy"}},
			"transaction_receipts": ["reward1"]}, "flags": ["relay_disabled"]}

func test_serialized_reward_snapshot_is_detached_from_live_state() -> void:
	var live := _state()
	var before: Dictionary = SNAPSHOT.from_state(live)
	live.redesign_character.essence.ground = 0
	live.party[0].known_moves.clear()
	live.inventory["0"].n = 0
	assert_eq(before.redesign_character.essence.ground, 100)
	assert_eq(before.party[0].known_moves, ["learned_move"])
	assert_eq(before.inventory["0"].n, 2)
	assert_false(SNAPSHOT.preserved(before, SNAPSHOT.from_state(live)))

func test_reload_rejects_lost_essence_breakthrough_traits_and_receipts() -> void:
	var before: Dictionary = SNAPSHOT.from_state(_state())
	var after := before.duplicate(true)
	after.redesign_character.essence.ground = 0
	assert_false(SNAPSHOT.preserved(before, after), "same HP/UID/XP cannot hide missing essence")
	after = before.duplicate(true)
	after.redesign_character.creatures.retained.breakthroughs.clear()
	assert_false(SNAPSHOT.preserved(before, after), "earned cap preparation must reload")
	after = before.duplicate(true)
	after.redesign_character.creatures.retained.trait_primary = ""
	assert_false(SNAPSHOT.preserved(before, after), "trait reward must reload")
	after = before.duplicate(true)
	after.redesign_character.transaction_receipts.clear()
	assert_false(SNAPSHOT.preserved(before, after), "reward deduplication receipt must reload")

func test_reload_rejects_lost_move_knowledge_and_mastery_with_same_basic_condition() -> void:
	var before: Dictionary = SNAPSHOT.from_state(_state())
	var after := before.duplicate(true)
	after.party[0].known_moves.clear()
	assert_false(SNAPSHOT.preserved(before, after))
	after = before.duplicate(true)
	after.party[0].move_mastery_receipts.clear()
	assert_false(SNAPSHOT.preserved(before, after))
	assert_true(SNAPSHOT.preserved(before, before.duplicate(true)))

func test_absent_or_malformed_reward_carriers_cannot_qualify_reload() -> void:
	assert_false(SNAPSHOT.preserved({}, {}))
	var partial := _state()
	partial.erase("redesign_character")
	assert_eq(SNAPSHOT.from_state(partial), {})
	partial = _state()
	partial["party"] = {}
	assert_eq(SNAPSHOT.from_state(partial), {})

func test_old_reward_records_are_cleared_before_load_without_modifying_snapshot() -> void:
	var game := RewardGameFixture.new()
	game.local.set("redesign_character", _state().redesign_character.duplicate(true))
	var before: Dictionary = SNAPSHOT.from_state(_state())
	assert_true(SNAPSHOT.clear_live_records(game))
	assert_false(game.local.get("redesign_character") == before.redesign_character)
	assert_eq(before.redesign_character.essence.ground, 100)
	game.free()
