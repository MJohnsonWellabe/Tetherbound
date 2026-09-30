extends "res://tests/test_case.gd"

## RD-35 replaces D100 migration-through-load: old slots refuse intact.
## Current-schema saves still partition once, preserve authority and stable ids.
##
## The owner has saves. This code reads them. "Never silently destroy an old
## save" was already this project's rule (`save_game.gd` is never fatal on
## load); D100 extends it to never REWRITING one either, and the only way to
## know that holds is to compare the bytes on either side of a load rather than
## to reason about which functions open the file for writing.
##
## Everything here goes through `saver.load_slot()`, the real entry point --
## nothing calls the split directly, because "the load path leaves the file
## alone" is the claim, not "a function I called by hand does".

const SAVE_GAME := preload("res://scripts/save/save_game.gd")
const ITEM_DB := preload("res://autoload/item_db.gd")
const FIXTURE := preload("res://tests/helpers/split_save_fixture.gd")

const TEST_DIR := "user://test_legacy_split/"

var db: RefCounted = null
var saver: RefCounted = null


func before_each() -> void:
	FIXTURE.wipe(TEST_DIR)
	db = ITEM_DB.new()
	saver = SAVE_GAME.new(TEST_DIR)


func after_each() -> void:
	FIXTURE.wipe(TEST_DIR)


## A v18 slot, hand-written: old enough to run several migration steps on the
## way to v22, so the split sees a MIGRATED dictionary and not the file's own
## shape. v18 predates the clock (v19), the realm maps and the alpha pins.
func _write_v18_slot(slot: int) -> String:
	DirAccess.make_dir_recursive_absolute(TEST_DIR)
	var data := {
		"version": 18,
		"day": 12,
		"party": [{
			"species_id": "terrapup", "nickname": "Biscuit", "hp": 64.0,
			"level": 9, "xp": 40, "bond": 12,
		}],
		"inventory": [{"id": "wood", "n": 12}],
		"hotbar": ["", "", "", "", ""],
		"placed_buildings": [{
			"realm": "meadows", "id": "fence",
			"position": [3.0, 0.0, -4.0], "yaw_deg": 90.0, "paid": true,
		}],
		"farm_plots": [],
		"death_satchels": [],
		"satiety": 71.0,
		"map": {},
		"alpha_pins": [],
		"progression": {"flags": ["defeated_warden", "tam_tools_given"]},
		"realm_hearts": {},
		"current_realm": "meadows",
		"pending_realm_entry": "",
		"harvested_vegetation": {},
		"world_seed": 99,
		"felled_vegetation": {},
		"player_pose": {},
	}
	var path: String = saver.slot_path(slot)
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(JSON.stringify(data, "\t"))
	file.close()
	return path


func _bytes(path: String) -> PackedByteArray:
	return FileAccess.get_file_as_bytes(path)


func _modified(path: String) -> int:
	return FileAccess.get_modified_time(path)


# RD-35 preservation and current-schema split regressions.

func _refuse_unchanged(game: Object, slot: int) -> void:
	var path: String = saver.slot_path(slot)
	var disk_before := _bytes(path)
	var modified_before := _modified(path)
	var live_before: Dictionary = saver.snapshot(game).duplicate(true)
	var worlds_before: Array = saver.worlds().list_ids().duplicate()
	var characters_before: Array = saver.characters().list_ids().duplicate()
	assert_false(saver.load_slot(game, slot), "RD-35 refuses old slots instead of migrating")
	assert_eq(str(saver.last_load_result.get("code", "")), "incompatible_old_version")
	assert_eq(_bytes(path), disk_before)
	assert_eq(_modified(path), modified_before)
	assert_eq(saver.snapshot(game), live_before)
	assert_eq(saver.worlds().list_ids(), worlds_before)
	assert_eq(saver.characters().list_ids(), characters_before)


func test_loading_a_legacy_slot_leaves_the_original_file_byte_identical() -> void:
	var path := _write_v18_slot(1)
	assert_true(_bytes(path).size() > 0)
	_refuse_unchanged(FIXTURE.game(db), 1)
	assert_true(FileAccess.file_exists(path))


func test_loading_a_legacy_slot_twice_still_leaves_the_original_alone() -> void:
	_write_v18_slot(1)
	_refuse_unchanged(FIXTURE.game(db), 1)
	_refuse_unchanged(FIXTURE.game(db, false), 1)


func test_a_current_version_slot_is_also_left_alone_by_its_own_load() -> void:
	var game := FIXTURE.populated_game(db)
	assert_true(saver.save(game, 2))
	var path: String = saver.slot_path(2)
	var before := _bytes(path)
	assert_true(saver.load_slot(FIXTURE.game(db, false), 2))
	assert_eq(_bytes(path), before)


func test_a_refused_old_slot_creates_no_world_or_character() -> void:
	_write_v18_slot(1)
	_refuse_unchanged(FIXTURE.game(db, false), 1)
	assert_eq(saver.worlds().list_ids(), [])
	assert_eq(saver.characters().list_ids(), [])


func test_a_refused_old_slot_does_not_write_migration_provenance() -> void:
	var path := _write_v18_slot(3)
	var original: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(path))
	_refuse_unchanged(FIXTURE.game(db), 3)
	var retained: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(path))
	assert_eq(retained, original)
	assert_false(retained.has("split_locator"))
	assert_false(retained.has("migrated_from"))


func test_a_refused_old_slot_keeps_its_old_values_inspectable() -> void:
	var path := _write_v18_slot(1)
	_refuse_unchanged(FIXTURE.game(db), 1)
	var original: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(path))
	assert_eq(int(original.get("version")), 18)
	assert_eq(int(original.get("day")), 12)
	assert_eq(int(original.get("world_seed")), 99)
	assert_eq(str(original.party[0].nickname), "Biscuit")
	assert_false(original.has("clock_elapsed_seconds"))


func test_current_split_puts_each_flag_on_its_own_side_of_the_line() -> void:
	var game := FIXTURE.populated_game(db)
	assert_true(saver.save(game, 1))
	var world: Dictionary = saver.worlds().read(str(game.world.world_id))
	var character: Dictionary = saver.characters().read(str(game.local.character_id))
	var world_ids: Array = world.get("flags", {}).get("flags", [])
	var player_ids: Array = character.get("flags", {}).get("flags", [])
	assert_true(world_ids.has("defeated_warden"))
	assert_false(world_ids.has("tam_tools_given"))
	assert_true(player_ids.has("tam_tools_given"))
	assert_false(player_ids.has("defeated_warden"))


func test_a_second_current_load_does_not_rewrite_advanced_world_authority() -> void:
	var game := FIXTURE.populated_game(db)
	assert_true(saver.save(game, 1))
	var world_id := str(game.world.world_id)
	var moved: Dictionary = saver.worlds().state(world_id)
	moved["day"] = 40
	assert_true(saver.worlds().write(world_id, moved))
	var original_slot := _bytes(saver.slot_path(1))
	var world_bytes := _bytes(saver.worlds().path_for(world_id))
	var reloaded := FIXTURE.game(db, false)
	assert_true(saver.load_slot(reloaded, 1))
	assert_eq(reloaded.day, 40, "split authority wins over stale current merged slot")
	assert_eq(_bytes(saver.slot_path(1)), original_slot)
	assert_eq(_bytes(saver.worlds().path_for(world_id)), world_bytes)


func test_continuing_current_slot_preserves_world_and_character_identity() -> void:
	var game := FIXTURE.populated_game(db)
	assert_true(saver.save(game, 1))
	var world_id := str(game.world.world_id)
	var character_id := str(game.local.character_id)
	var reloaded := FIXTURE.game(db, false)
	assert_true(saver.load_slot(reloaded, 1))
	assert_eq(str(reloaded.world.world_id), world_id)
	assert_eq(str(reloaded.local.character_id), character_id)
	reloaded.day = 13
	assert_true(saver.save(reloaded, 1))
	assert_eq(saver.worlds().list_ids(), [world_id])
	assert_eq(saver.characters().list_ids(), [character_id])
	assert_eq(int(saver.worlds().read(world_id).get("day")), 13)


func test_slot_info_explains_old_refusal_and_accepts_current_schema() -> void:
	var old_path := _write_v18_slot(1)
	var old_bytes := _bytes(old_path)
	var info: Dictionary = saver.slot_info(1)
	assert_eq(str(info.get("load_result", {}).get("code", "")), "incompatible_old_version")
	assert_true(str(info.get("load_result", {}).get("message", "")).to_lower().contains("start a new game"))
	assert_true(saver.save(FIXTURE.populated_game(db), 2))
	assert_true(bool(saver.slot_info(2).get("load_result", {}).get("ok", false)))
	assert_eq(_bytes(old_path), old_bytes, "a different current slot leaves old history untouched")
