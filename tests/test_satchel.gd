extends "res://tests/test_case.gd"

## R3.2. Death satchels persist across save/load.
##
## `tests/test_player_death.gd` already covers `death_satchel.gd::build()`
## rehydrating a freshly-drained inventory; this file covers the persistence
## half that item adds: `GameState.register_death_satchel`'s own contract
## (same split `test_register_building.gd` draws for `register_building`),
## `death_satchel.gd::restore()` rehydrating from a save file's `state` array
## (as opposed to `build()`'s live `drain()` array — different source shape,
## same result), and a full `save_game.gd` round trip of a `death_satchels`
## entry. Historical migration helpers retain their empty-satchel defaults;
## real v1/v3 reads now exercise RD-35 refusal with live state and disk intact.
##
## Pure logic throughout, no scene tree: `player_death.gd`'s own
## `sync_state_to_game`/`restore_from_game` walk `get_tree()`'s groups and are
## therefore out of reach here, the same carve-out `test_player_death.gd`'s
## own header already states for the fade/tween/teleport half of that file.

const GAME_STATE := preload("res://autoload/game_state.gd")
const SAVE_GAME := preload("res://scripts/save/save_game.gd")
const ITEM_DB := preload("res://autoload/item_db.gd")
const INVENTORY := preload("res://autoload/inventory.gd")
const DEATH_SATCHEL := preload("res://scripts/world/death_satchel.gd")
const SPLIT_FIXTURE := preload("res://tests/helpers/split_save_fixture.gd")

const TEST_DIR := "user://test_saves_satchel/"

## A minimal stand-in for `Game`, the same shape `test_save_format.gd`'s own
## `FakeGame` uses — only the properties `save_game.gd` actually reads or
## writes, nothing `_ready()` would otherwise set up.
class FakeGame:
	extends RefCounted
	var day: int = 1
	var party: RefCounted = null
	var inventory: RefCounted = null
	var placed_buildings: Array = []
	## R7.6 / VERSION 9. The berry farm's beds — save_game.gd reads it on every
	## write, so a double that omits it fails the cast rather than this file's
	## own subject.
	var farm_plots: Array = []
	var death_satchels: Array = []
	## HARVEST-ALL / VERSION 10 — save_game.gd reads it on every write too.
	var harvested_vegetation: Dictionary = {}
	## RG9 / VERSION 11 — save_game.gd reads it on every write too.
	var felled_vegetation: Dictionary = {}
	var map: RefCounted = null
	var progression: RefCounted = null
	var satiety: float = 100.0
	var local: RefCounted = null

var db: RefCounted = null
var game: Node = null
var saver: RefCounted = null


func before_each() -> void:
	db = ITEM_DB.new()
	# _ready() is never called -- see test_register_building.gd's own note.
	# register_death_satchel touches nothing _ready() sets up.
	game = GAME_STATE.new()
	saver = SAVE_GAME.new(TEST_DIR)
	_wipe_test_dir()


func after_each() -> void:
	if game != null:
		game.free()
		game = null
	_wipe_test_dir()


func _wipe_test_dir() -> void:
	SPLIT_FIXTURE.wipe(TEST_DIR)


# --- GameState.register_death_satchel ---------------------------------------


func test_register_death_satchel_records_position_and_an_empty_state() -> void:
	var index: int = game.register_death_satchel(Vector3(3.0, 0.0, -5.0))
	assert_eq(index, 0)
	assert_eq(game.death_satchels.size(), 1)
	var entry: Dictionary = game.death_satchels[0]
	assert_eq(entry.get("position"), [3.0, 0.0, -5.0])
	assert_eq(entry.get("state"), [])


func test_multiple_registrations_each_get_their_own_increasing_index() -> void:
	var first: int = game.register_death_satchel(Vector3.ZERO)
	var second: int = game.register_death_satchel(Vector3(1.0, 0.0, 1.0))
	assert_eq(first, 0)
	assert_eq(second, 1)
	assert_eq(game.death_satchels.size(), 2)


# --- death_satchel.gd::restore() ---------------------------------------------


func test_restore_rehydrates_a_saved_state_array_exactly() -> void:
	var bag: RefCounted = INVENTORY.new(db)
	bag.add("wood", 10)
	bag.add("axe", 1)
	var dropped: Array = bag.drain()

	var built: Node3D = DEATH_SATCHEL.new()
	built.build(dropped, db)
	var saved: Array = built.state.call("save_data")

	var restored: Node3D = DEATH_SATCHEL.new()
	restored.restore(saved, db)

	assert_eq(restored.state.inventory.count("wood"), 10)
	assert_eq(restored.state.inventory.count("axe"), 1)


func test_restore_preserves_tool_durability_exactly() -> void:
	var bag: RefCounted = INVENTORY.new(db)
	bag.add("axe", 1)
	bag.damage_tool(bag.find_slot("axe"), 3)
	var before: Dictionary = bag.stack_at(bag.find_slot("axe"))
	var dropped: Array = bag.drain()

	var built: Node3D = DEATH_SATCHEL.new()
	built.build(dropped, db)
	var saved: Array = built.state.call("save_data")

	var restored: Node3D = DEATH_SATCHEL.new()
	restored.restore(saved, db)

	var slot := -1
	for i in restored.state.inventory.slot_count():
		if not restored.state.inventory.is_slot_empty(i):
			slot = i
			break
	assert_true(slot >= 0, "the restored axe must land somewhere in the satchel")
	assert_eq(restored.state.inventory.stack_at(slot).get("durability"), before.get("durability"),
		"restore must carry durability through untouched, the same as build() does")


func test_restore_on_an_empty_saved_state_leaves_an_empty_but_valid_satchel() -> void:
	var restored: Node3D = DEATH_SATCHEL.new()
	restored.restore([], db)
	assert_eq(restored.state.inventory.used_slots(), 0)


# --- save_game.gd round trip -------------------------------------------------


func test_save_then_load_round_trips_death_satchels() -> void:
	var written := FakeGame.new()
	written.local = SPLIT_FIXTURE.IdHolder.new()
	written.local.character_id = "satchel-test-character"
	written.death_satchels = [
		{"position": [3.0, 0.0, -5.0], "state": [{"id": "wood", "n": 10}, null]},
	]
	assert_true(saver.save(written, 0))

	var read := FakeGame.new()
	read.local = SPLIT_FIXTURE.IdHolder.new()
	read.local.character_id = "satchel-test-character"
	assert_true(saver.load_slot(read, 0))
	assert_eq(read.death_satchels.size(), 1)
	var entry := read.death_satchels[0] as Dictionary
	assert_eq(entry.get("position"), [3.0, 0.0, -5.0])
	var state := entry.get("state") as Array
	assert_eq(state.size(), 2)
	assert_eq((state[0] as Dictionary).get("id"), "wood")
	assert_eq((state[0] as Dictionary).get("n"), 10)
	assert_eq(state[1], null)


func test_v3_helper_defaults_satchels_but_actual_load_refuses_without_mutation() -> void:
	var legacy := {
		"version": 3, "day": 5, "party": [], "inventory": [],
		"placed_buildings": [], "satiety": 100.0, "map": {}, "progression": {},
	}
	# The historical pure helper remains covered; its result is never passed
	# through the production reader as an independently authored current save.
	var migrated: Dictionary = saver.call("_migrate_to_current", legacy.duplicate(true), 3, 0)
	assert_eq(migrated.get("death_satchels"), [])
	assert_eq(int(migrated.get("day", 0)), 5, "the historical helper preserves the old day")
	assert_eq(int(migrated.get("version", 0)), SAVE_GAME.RESET_MAX_VERSION)
	_assert_legacy_load_refusal(legacy)


func test_v1_helper_defaults_satchels_but_actual_load_refuses_without_mutation() -> void:
	var legacy := {"version": 1, "day": 2, "party": [], "inventory": [], "placed_buildings": []}
	var migrated: Dictionary = saver.call("_migrate_to_current", legacy.duplicate(true), 1, 0)
	assert_eq(migrated.get("death_satchels"), [])
	assert_eq(int(migrated.get("day", 0)), 2)
	assert_eq(int(migrated.get("version", 0)), SAVE_GAME.RESET_MAX_VERSION)
	_assert_legacy_load_refusal(legacy)


func _assert_legacy_load_refusal(legacy: Dictionary) -> void:
	var path: String = saver.slot_path(0)
	assert_eq(DirAccess.make_dir_recursive_absolute(TEST_DIR), OK)
	var file := FileAccess.open(path, FileAccess.WRITE)
	assert_true(file != null)
	if file == null:
		return
	file.store_string(JSON.stringify(legacy))
	file.close()
	var bytes := FileAccess.get_file_as_bytes(path)
	var modified := FileAccess.get_modified_time(path)
	var read := FakeGame.new()
	read.day = 23
	read.satiety = 61.5
	read.inventory = INVENTORY.new(db)
	read.inventory.add("wood", 7)
	read.local = SPLIT_FIXTURE.IdHolder.new()
	read.local.character_id = "arriving-satchel-owner"
	read.death_satchels = [{"position": [4.0, 1.0, -8.0], "state": [{"id": "wood", "n": 3}]}]
	var before: Dictionary = saver.call("snapshot", read).duplicate(true)
	var worlds: RefCounted = saver.get("_worlds")
	var characters: RefCounted = saver.get("_characters")
	var world_ids: Array = worlds.call("list_ids").duplicate()
	var character_ids: Array = characters.call("list_ids").duplicate()
	assert_false(bool(saver.load_slot(read, 0)), "RD-35 refuses actual old reads before applying state")
	var result: Dictionary = saver.get("last_load_result")
	assert_eq(result.get("code"), "incompatible_old_version")
	assert_true(str(result.get("message", "")).contains("older version"))
	assert_true(str(result.get("message", "")).contains("Start a new game"))
	assert_eq(saver.call("snapshot", read), before, "refusal preserves every arriving live field")
	assert_eq(read.local.character_id, "arriving-satchel-owner")
	assert_eq(read.inventory.count("wood"), 7)
	assert_eq(FileAccess.get_file_as_bytes(path), bytes, "old document is not overwritten")
	assert_eq(FileAccess.get_modified_time(path), modified)
	assert_eq(worlds.call("list_ids"), world_ids, "refusal creates no world document")
	assert_eq(characters.call("list_ids"), character_ids, "refusal creates no portable character")
