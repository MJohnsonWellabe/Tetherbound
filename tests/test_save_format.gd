extends "res://tests/test_case.gd"

## R3.1. Save/load round-trips — `scripts/save/save_game.gd`.
##
## Every failure here is one a player would meet as lost progress: a party
## that comes back with the wrong HP, a satchel that reshuffles slots on
## reload, a version bump that bricks an old save instead of leaving it
## alone. `FakeGame` below stands in for the `Game` autoload — it needs no
## scene tree, no menu, nothing `save_game.gd` does not actually read or
## write (`day`, `party`, `inventory`, `placed_buildings`).
##
## Writes to a dedicated `user://test_saves_format/` directory rather than the
## real `user://saves/`, wiped before every test, so this file cannot leave
## behind a slot a later run — or a real playthrough on the same machine —
## would mistake for a real save.

const SAVE_GAME := preload("res://scripts/save/save_game.gd")
const ITEM_DB := preload("res://autoload/item_db.gd")
const INVENTORY := preload("res://autoload/inventory.gd")
const PARTY := preload("res://autoload/party.gd")
const PAL := preload("res://scripts/pals/pal_instance.gd")

const TEST_DIR := "user://test_saves_format/"

class FakeGame:
	extends RefCounted
	var day: int = 1
	var party: RefCounted = null
	var inventory: RefCounted = null
	var placed_buildings: Array = []

var db: RefCounted = null
var saver: RefCounted = null


func before_each() -> void:
	db = ITEM_DB.new()
	saver = SAVE_GAME.new(TEST_DIR)
	_wipe_test_dir()


func after_each() -> void:
	_wipe_test_dir()


func _wipe_test_dir() -> void:
	var dir := DirAccess.open(TEST_DIR)
	if dir == null:
		return
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if not dir.current_is_dir():
			dir.remove(file_name)
		file_name = dir.get_next()
	dir.list_dir_end()


func _game(seed_party: bool = true) -> RefCounted:
	var game := FakeGame.new()
	game.party = PARTY.new()
	game.inventory = INVENTORY.new(db)
	if seed_party:
		var pal: RefCounted = PAL.from_species("terrapup", {
			"display_name": "Terrapup", "type": "ground", "base_hp": 100.0,
			"base_attack": 20.0, "base_defence": 20.0,
		})
		pal.nickname = "Biscuit"
		pal.take_damage(35.0)
		game.party.add(pal)
	return game


func test_slot_count_is_between_three_and_five() -> void:
	# R3.1's own brief: "3-5 slots".
	assert_true(SAVE_GAME.SLOT_COUNT >= 3 and SAVE_GAME.SLOT_COUNT <= 5)


func test_a_fresh_slot_has_nothing_to_load() -> void:
	assert_false(saver.has_slot(0))
	assert_false(saver.load_slot(_game(), 0))
	assert_eq(saver.slot_info(0), {})


func test_save_then_load_round_trips_the_day_counter() -> void:
	var written := _game()
	written.day = 7
	assert_true(saver.save(written, 1))

	var read := _game(false)
	assert_true(saver.load_slot(read, 1))
	assert_eq(read.day, 7)


func test_save_then_load_round_trips_the_party() -> void:
	var written := _game()
	assert_true(saver.save(written, 1))

	var read := _game(false)
	assert_true(saver.load_slot(read, 1))
	assert_eq(read.party.size(), 1)
	var pal: RefCounted = read.party.at(0)
	assert_eq(str(pal.get("species_id")), "terrapup")
	assert_eq(str(pal.get("nickname")), "Biscuit")
	assert_almost_eq(float(pal.get("hp")), 65.0)
	assert_almost_eq(float(pal.get("max_hp")), 100.0)


func test_save_then_load_replaces_whatever_party_the_loading_game_already_had() -> void:
	var written := _game()
	assert_true(saver.save(written, 1))

	var read := _game(true)
	read.party.at(0).nickname = "Should not survive"
	assert_true(saver.load_slot(read, 1))
	assert_eq(read.party.size(), 1)
	assert_eq(str(read.party.at(0).get("nickname")), "Biscuit")


func test_save_then_load_round_trips_inventory_slot_positions() -> void:
	var written := _game()
	written.inventory.set_slot(3, {"id": "wood", "n": 12})
	written.inventory.set_slot(9, {"id": "stone", "n": 4})
	assert_true(saver.save(written, 1))

	var read := _game(false)
	assert_true(saver.load_slot(read, 1))
	assert_eq(read.inventory.stack_at(3), {"id": "wood", "n": 12})
	assert_eq(read.inventory.stack_at(9), {"id": "stone", "n": 4})
	assert_true(read.inventory.is_slot_empty(0))


func test_save_then_load_round_trips_tool_durability() -> void:
	var written := _game()
	written.inventory.set_slot(5, {"id": "axe", "n": 1, "durability": 3})
	assert_true(saver.save(written, 1))

	var read := _game(false)
	assert_true(saver.load_slot(read, 1))
	assert_eq(int(read.inventory.stack_at(5).get("durability", -1)), 3)


func test_save_then_load_round_trips_placed_buildings() -> void:
	var written := _game()
	written.placed_buildings = [
		{"id": "camp", "position": [1.0, 0.0, -2.5]},
		{"id": "storage", "position": [4.25, 0.0, 6.0]},
	]
	assert_true(saver.save(written, 1))

	var read := _game(false)
	assert_true(saver.load_slot(read, 1))
	assert_eq(read.placed_buildings.size(), 2)
	assert_eq(str((read.placed_buildings[0] as Dictionary).get("id")), "camp")
	assert_eq((read.placed_buildings[1] as Dictionary).get("position"), [4.25, 0.0, 6.0])


func test_save_then_load_round_trips_a_placed_buildings_rotation() -> void:
	# BG1: `GameState.register_building` now takes a `yaw_deg`, stored as a
	# plain extra key on the same dictionary — save_game.gd itself does not
	# know or care about `yaw_deg` specifically, it round-trips whatever the
	# dictionary holds, so this proves the whole entry survives unharmed
	# rather than re-testing register_building's own shape.
	var written := _game()
	written.placed_buildings = [
		{"id": "wall", "position": [2.0, 0.0, 0.0], "yaw_deg": 90.0},
	]
	assert_true(saver.save(written, 1))

	var read := _game(false)
	assert_true(saver.load_slot(read, 1))
	assert_eq(read.placed_buildings.size(), 1)
	assert_almost_eq(float((read.placed_buildings[0] as Dictionary).get("yaw_deg", -1.0)), 90.0)


func test_load_on_an_older_save_with_no_yaw_deg_does_not_crash_or_lose_the_entry() -> void:
	# A save written before BG1 shipped rotation has plain {id, position}
	# entries and no `yaw_deg` key at all. `save_game.gd` treats
	# `placed_buildings` opaquely, so this is really proving BG1 did not
	# quietly require a version bump `docs/decisions/D15`'s "carry on, do not
	# brick the player" rule would otherwise be broken by.
	var written := _game()
	written.placed_buildings = [{"id": "camp", "position": [0.0, 0.0, 0.0]}]
	assert_true(saver.save(written, 1))

	var read := _game(false)
	assert_true(saver.load_slot(read, 1))
	assert_eq(read.placed_buildings.size(), 1)
	assert_eq(str((read.placed_buildings[0] as Dictionary).get("id")), "camp")
	assert_false((read.placed_buildings[0] as Dictionary).has("yaw_deg"))


func test_load_on_a_missing_slot_returns_false_and_leaves_the_game_untouched() -> void:
	var game := _game()
	game.day = 4
	assert_false(saver.load_slot(game, 2))
	assert_eq(game.day, 4)
	assert_eq(game.party.size(), 1)


func test_load_on_a_corrupt_file_returns_false_and_leaves_the_game_untouched() -> void:
	DirAccess.make_dir_recursive_absolute(TEST_DIR)
	var file := FileAccess.open(saver.slot_path(1), FileAccess.WRITE)
	file.store_string("not valid json{{{")
	file = null

	var game := _game()
	game.day = 9
	assert_false(saver.load_slot(game, 1))
	assert_eq(game.day, 9)


func test_load_on_a_newer_version_refuses_and_leaves_the_game_untouched() -> void:
	DirAccess.make_dir_recursive_absolute(TEST_DIR)
	var file := FileAccess.open(saver.slot_path(1), FileAccess.WRITE)
	file.store_string(JSON.stringify({"version": SAVE_GAME.VERSION + 1, "day": 99}))
	file = null

	var game := _game()
	game.day = 2
	assert_false(saver.load_slot(game, 1))
	assert_eq(game.day, 2, "a newer save must be left alone, not guessed at")


func test_save_and_load_reject_an_out_of_range_slot() -> void:
	assert_false(saver.save(_game(), -1))
	assert_false(saver.save(_game(), SAVE_GAME.SLOT_COUNT))
	assert_false(saver.load_slot(_game(), -1))
	assert_false(saver.load_slot(_game(), SAVE_GAME.SLOT_COUNT))


func test_slot_info_reports_day_and_party_size_without_touching_the_caller() -> void:
	var written := _game()
	written.day = 3
	assert_true(saver.save(written, 2))

	var info: Dictionary = saver.slot_info(2)
	assert_eq(int(info.get("day")), 3)
	assert_eq(int(info.get("party_size")), 1)


func test_has_slot_reflects_what_was_actually_written() -> void:
	assert_false(saver.has_slot(0))
	saver.save(_game(), 0)
	assert_true(saver.has_slot(0))


func test_slots_are_independent_of_each_other() -> void:
	var first := _game()
	first.day = 1
	var second := _game(false)
	second.day = 42
	assert_true(saver.save(first, 0))
	assert_true(saver.save(second, 1))

	assert_eq(saver.slot_info(0).get("day"), 1)
	assert_eq(saver.slot_info(1).get("day"), 42)
