extends "res://tests/test_case.gd"

## D100's hard requirement, and the one this lane was told to stop rather than
## half-ship: **a v<=22 slot splits on first load into one world plus one
## character, and the original file is never modified and never deleted.**
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


# --- the requirement itself ---------------------------------------------------

func test_loading_a_legacy_slot_leaves_the_original_file_byte_identical() -> void:
	var path := _write_v18_slot(1)
	var before := _bytes(path)
	var before_time := _modified(path)
	assert_true(before.size() > 0, "the fixture wrote something to compare against")

	var game := FIXTURE.game(db, false)
	assert_true(saver.load_slot(game, 1), "the legacy slot still loads")

	assert_true(FileAccess.file_exists(path), "and the original is still there -- never deleted")
	assert_eq(_bytes(path), before,
		"the original slot file must be byte-identical after a load")
	assert_eq(_modified(path), before_time,
		"and untouched, not merely rewritten with the same content")


func test_loading_a_legacy_slot_twice_still_leaves_the_original_alone() -> void:
	var path := _write_v18_slot(1)
	var before := _bytes(path)
	var game := FIXTURE.game(db, false)
	assert_true(saver.load_slot(game, 1))
	assert_true(saver.load_slot(FIXTURE.game(db, false), 1))
	assert_eq(_bytes(path), before, "a second load is not a second chance to damage it")


func test_a_current_version_slot_is_also_left_alone_by_its_own_load() -> void:
	# v22 is "v<=22" too. The rule is not about old files, it is about the
	# original file, whatever version it is.
	var game := FIXTURE.populated_game(db)
	assert_true(saver.save(game, 2))
	var path: String = saver.slot_path(2)
	var before := _bytes(path)
	assert_true(saver.load_slot(FIXTURE.game(db, false), 2))
	assert_eq(_bytes(path), before)


# --- what the split produced --------------------------------------------------

func test_the_split_writes_one_world_and_one_character_under_d100_names() -> void:
	_write_v18_slot(1)
	var game := FIXTURE.game(db, false)
	assert_true(saver.load_slot(game, 1))
	var worlds: RefCounted = saver.call("worlds")
	var characters: RefCounted = saver.call("characters")
	assert_true(bool(worlds.call("has", "legacy-slot-1")),
		"D100 names the migrated world legacy-slot-<n>; got %s" % str(worlds.call("list_ids")))
	assert_true(bool(characters.call("has", "legacy-slot-1")),
		"and the migrated character the same; got %s" % str(characters.call("list_ids")))


func test_both_halves_record_where_they_were_migrated_from() -> void:
	_write_v18_slot(3)
	assert_true(saver.load_slot(FIXTURE.game(db, false), 3))
	var world: Dictionary = (saver.call("worlds") as RefCounted).call("read", "legacy-slot-3")
	var character: Dictionary = (saver.call("characters") as RefCounted).call("read", "legacy-slot-3")
	assert_eq(str(world.get("migrated_from", "")), "slot_3",
		"a migrated world says which slot it came from, so the original can be found again")
	assert_eq(str(character.get("migrated_from", "")), "slot_3")


func test_the_split_carries_the_migrated_values_not_the_files_own_v18_shape() -> void:
	_write_v18_slot(1)
	assert_true(saver.load_slot(FIXTURE.game(db, false), 1))
	var world: Dictionary = (saver.call("worlds") as RefCounted).call("read", "legacy-slot-1")
	var character: Dictionary = (saver.call("characters") as RefCounted).call("read", "legacy-slot-1")
	assert_eq(int(world.get("day", 0)), 12)
	assert_eq(int(world.get("world_seed", 0)), 99)
	assert_eq((world.get("placed_buildings", []) as Array).size(), 1)
	# v19 added the clock; a v18 file has none, and the migration's answer is
	# the "no carried clock" sentinel rather than hour zero.
	assert_true(float(world.get("clock_elapsed_seconds", 0.0)) < 0.0,
		"a save that predates the clock opens at the authored morning")
	assert_almost_eq(float(character.get("satiety", 0.0)), 71.0)
	assert_eq((character.get("party", []) as Array).size(), 1)
	assert_true((character.get("realm_maps", {}) as Dictionary).has("meadows"),
		"the migration built the realm maps a v18 file does not have")


func test_the_split_puts_each_flag_on_its_own_side_of_the_line() -> void:
	_write_v18_slot(1)
	assert_true(saver.load_slot(FIXTURE.game(db, false), 1))
	var world: Dictionary = (saver.call("worlds") as RefCounted).call("read", "legacy-slot-1")
	var character: Dictionary = (saver.call("characters") as RefCounted).call("read", "legacy-slot-1")
	var world_ids: Array = ((world.get("flags", {}) as Dictionary).get("flags", []) as Array)
	var player_ids: Array = ((character.get("flags", {}) as Dictionary).get("flags", []) as Array)
	assert_true(world_ids.has("defeated_warden"))
	assert_false(world_ids.has("tam_tools_given"))
	assert_true(player_ids.has("tam_tools_given"))
	assert_false(player_ids.has("defeated_warden"))


func test_a_second_load_does_not_rewrite_a_world_the_player_has_since_played() -> void:
	# The split is a MIGRATION. Re-running it over a world the player has
	# continued from would throw away everything done since.
	_write_v18_slot(1)
	assert_true(saver.load_slot(FIXTURE.game(db, false), 1))
	var worlds: RefCounted = saver.call("worlds")
	var path := str(worlds.call("path_for", "legacy-slot-1"))
	var moved: Dictionary = worlds.call("read", "legacy-slot-1")
	moved["day"] = 40
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(JSON.stringify(moved, "\t"))
	file.close()

	assert_true(saver.load_slot(FIXTURE.game(db, false), 1))
	assert_eq(int((worlds.call("read", "legacy-slot-1") as Dictionary).get("day", 0)), 40,
		"the second load must not put the migrated world back to day 12")


func test_continuing_a_migrated_slot_keeps_writing_the_world_it_migrated_to() -> void:
	# Otherwise the first save after a migration mints a SECOND world beside
	# the one that was just built, and half the progress lands in each.
	_write_v18_slot(1)
	var game := FIXTURE.game(db, false)
	assert_true(saver.load_slot(game, 1))
	assert_eq(str(game.world.world_id), "legacy-slot-1",
		"the load adopts the migrated id onto the live world")
	assert_eq(str(game.local.character_id), "legacy-slot-1")
	game.day = 13
	assert_true(saver.save(game, 1))
	var worlds: RefCounted = saver.call("worlds")
	assert_eq(worlds.call("list_ids"), ["legacy-slot-1"],
		"and one world, not two -- got %s" % str(worlds.call("list_ids")))
	assert_eq(int((worlds.call("read", "legacy-slot-1") as Dictionary).get("day", 0)), 13)


# --- the UI half of D100's legacy rule ----------------------------------------

func test_slot_info_marks_an_older_build_slot_as_legacy_and_a_current_one_not() -> void:
	_write_v18_slot(1)
	var info: Dictionary = saver.slot_info(1)
	assert_true(bool(info.get("legacy", false)),
		"a v18 slot is listed under the legacy mark until it is opened once")
	assert_eq(int(info.get("day", 0)), 12, "and still reads its day and party for the list")
	assert_eq(int(info.get("party_size", -1)), 1)

	assert_true(saver.save(FIXTURE.populated_game(db), 1))
	assert_false(bool((saver.slot_info(1) as Dictionary).get("legacy", true)),
		"a slot re-saved at the current version is not legacy any more")
