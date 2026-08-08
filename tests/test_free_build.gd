extends "res://tests/test_case.gd"

## Free build: what it does to a cost, and what it survives.
##
## This is a development toggle (docs/decisions/D16) and it changes the economy
## of the game while it is on, which is exactly why it is tested rather than
## trusted. Two things have to hold:
##
##   - EVERY cost check goes through `GameState.build_cost_for`. Anything that
##     reads data/items/buildables.json directly to decide affordability is a
##     second answer to the same question, and one of the two will be wrong.
##   - the choice survives a launch, and a missing or corrupt settings file
##     leaves it OFF. A cheat that switches itself on because a JSON file was
##     truncated is worse than one that will not persist at all.
##
## GameState is instantiated here rather than reached through the `Game`
## autoload: the runner runs every test file in one process, and flipping the
## live game's toggle would follow this file into every test after it.

const GAME_STATE := preload("res://autoload/game_state.gd")
const ITEM_DB := preload("res://autoload/item_db.gd")
const INVENTORY := preload("res://autoload/inventory.gd")
const KEY_BINDINGS := preload("res://scripts/ui/key_bindings.gd")

## The one buildable that ships. Read from the catalogue rather than named twice,
## so adding a second entry cannot quietly retarget these tests.
var game: Node = null
var path: String = ""

## Counts up so no two tests share a file, whatever order they run in.
static var _serial: int = 0


func before_each() -> void:
	_serial += 1
	path = "user://test_free_build_%d.json" % _serial

	# _ready() is never called: it would mount the pause menu into a tree this
	# test does not have. The three fields it sets up are set up here instead.
	game = GAME_STATE.new()
	game.items = ITEM_DB.new()
	game.inventory = INVENTORY.new(game.items)


func after_each() -> void:
	if game != null:
		game.free()
		game = null
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


func _first_buildable() -> String:
	var catalogue: Array = game.items.buildables()
	return str((catalogue[0] as Dictionary).get("id", "")) if not catalogue.is_empty() else ""


## Enough of everything the first buildable asks for.
func _stock_up() -> void:
	for requirement in game.items.buildable(_first_buildable()).get("cost", []):
		game.inventory.add(str((requirement as Dictionary).get("id", "")), int((requirement as Dictionary).get("n", 0)))


# --- the default -------------------------------------------------------------


func test_free_build_is_off_until_it_is_switched_on() -> void:
	# The owner asked for a toggle, not for a game that starts cheating.
	assert_false(bool(game.free_build), "free build defaults to ON")


func test_a_piece_costs_what_the_catalogue_says_by_default() -> void:
	var id := _first_buildable()
	var expected: Array = game.items.buildable(id).get("cost", [])
	assert_true(expected.size() > 0, "the catalogue entry has no cost to check against")
	assert_eq(game.build_cost_for(id).size(), expected.size())
	assert_eq(game.build_cost_for(id), expected, "the cost was not the catalogue's")


func test_an_empty_satchel_cannot_afford_anything() -> void:
	assert_false(game.can_afford(_first_buildable()))


func test_a_full_satchel_can() -> void:
	_stock_up()
	assert_true(game.can_afford(_first_buildable()))


func test_one_missing_material_is_still_short() -> void:
	_stock_up()
	var requirement: Dictionary = (game.items.buildable(_first_buildable()).get("cost", [])[0]) as Dictionary
	game.inventory.remove(str(requirement.get("id", "")), 1)
	assert_false(game.can_afford(_first_buildable()), "one short still built")


# --- with the toggle on ------------------------------------------------------


func test_the_toggle_makes_the_cost_empty() -> void:
	# This is the whole mechanism. Placement (M8) will spend what this returns,
	# and an empty cost is how it spends nothing without knowing why.
	game.free_build = true
	assert_eq(game.build_cost_for(_first_buildable()).size(), 0)


func test_the_toggle_affords_an_empty_satchel() -> void:
	game.free_build = true
	assert_eq(game.inventory.used_slots(), 0, "the satchel was not empty to begin with")
	assert_true(game.can_afford(_first_buildable()), "free build did not make the piece affordable")


func test_switching_it_back_off_restores_the_cost() -> void:
	# A cheat that cannot be turned off is not a toggle.
	game.free_build = true
	game.free_build = false
	assert_true(game.build_cost_for(_first_buildable()).size() > 0)
	assert_false(game.can_afford(_first_buildable()))


func test_free_build_does_not_invent_buildables() -> void:
	# An empty cost must not read as "affordable" for an id no catalogue entry
	# answers to. Otherwise a typo becomes buildable the moment the cheat is on.
	game.free_build = true
	assert_false(game.can_afford("a_piece_that_does_not_exist"))
	assert_eq(game.build_cost_for("a_piece_that_does_not_exist").size(), 0)


func test_the_toggle_does_not_touch_the_satchel() -> void:
	# Free build changes what things cost, not what the player has. A cheat that
	# quietly topped the satchel up would corrupt every later gathering number.
	_stock_up()
	var before: int = int(game.inventory.used_slots())
	game.free_build = true
	var _cost: Array = game.build_cost_for(_first_buildable())
	var _afford: bool = game.can_afford(_first_buildable())
	assert_eq(game.inventory.used_slots(), before)


# --- the settings file -------------------------------------------------------


func test_the_choice_survives_a_relaunch() -> void:
	var prefs: RefCounted = KEY_BINDINGS.new(path)
	prefs.gameplay[GAME_STATE.PREF_FREE_BUILD] = true
	assert_true(prefs.save())

	var reloaded: RefCounted = KEY_BINDINGS.new(path)
	assert_eq(reloaded.load_overrides(), KEY_BINDINGS.LOAD_OK)
	assert_true(bool(reloaded.gameplay.get(GAME_STATE.PREF_FREE_BUILD, false)), "the toggle did not survive")
	reloaded.reset_all()


func test_it_shares_the_one_settings_file_with_the_controls() -> void:
	# One file in user://, not two. A second preferences file is a second thing
	# to migrate, and the next rebind would overwrite whichever wrote last.
	var prefs: RefCounted = KEY_BINDINGS.new(path)
	prefs.gameplay[GAME_STATE.PREF_FREE_BUILD] = true
	var key := InputEventKey.new()
	key.physical_keycode = KEY_J
	prefs.set_binding("jump", "keyboard", key)
	assert_true(prefs.save())
	prefs.reset_all()

	var file := FileAccess.open(path, FileAccess.READ)
	var data: Dictionary = JSON.parse_string(file.get_as_text()) as Dictionary
	assert_eq(int(data.get("version", 0)), KEY_BINDINGS.FORMAT_VERSION, "the toggle skipped the versioning")
	assert_true((data.get("controls", {}) as Dictionary).has("jump"))
	assert_true((data.get("gameplay", {}) as Dictionary).has(GAME_STATE.PREF_FREE_BUILD))


func test_a_rebind_does_not_wipe_the_toggle() -> void:
	# A save rewrites the whole document, so the controls half has to carry the
	# gameplay half through or the next rebind erases it.
	var prefs: RefCounted = KEY_BINDINGS.new(path)
	prefs.gameplay[GAME_STATE.PREF_FREE_BUILD] = true
	prefs.save()

	var later: RefCounted = KEY_BINDINGS.new(path)
	later.load_overrides()
	var key := InputEventKey.new()
	key.physical_keycode = KEY_L
	later.set_binding("sprint", "keyboard", key)
	later.save()
	later.reset_all()

	var reloaded: RefCounted = KEY_BINDINGS.new(path)
	reloaded.load_overrides()
	assert_true(bool(reloaded.gameplay.get(GAME_STATE.PREF_FREE_BUILD, false)), "rebinding a key turned the toggle off")
	reloaded.reset_all()


func test_no_settings_file_at_all_means_off() -> void:
	var prefs: RefCounted = KEY_BINDINGS.new(path)
	assert_eq(prefs.load_overrides(), KEY_BINDINGS.LOAD_MISSING)
	assert_false(bool(prefs.gameplay.get(GAME_STATE.PREF_FREE_BUILD, false)))


func test_a_corrupt_settings_file_means_off() -> void:
	# The file the controls read is the file this reads. A truncated write must
	# not be able to switch a cheat on.
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string('{"version": 1, "gameplay": {"free_build": true')
	file = null

	var prefs: RefCounted = KEY_BINDINGS.new(path)
	assert_eq(prefs.load_overrides(), KEY_BINDINGS.LOAD_UNREADABLE)
	assert_false(bool(prefs.gameplay.get(GAME_STATE.PREF_FREE_BUILD, false)), "a corrupt file switched free build on")


func test_a_file_from_a_newer_build_means_off() -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string('{"version": 99, "gameplay": {"free_build": true}}')
	file = null

	var prefs: RefCounted = KEY_BINDINGS.new(path)
	assert_eq(prefs.load_overrides(), KEY_BINDINGS.LOAD_FUTURE)
	assert_false(bool(prefs.gameplay.get(GAME_STATE.PREF_FREE_BUILD, false)))


func test_a_settings_file_that_never_heard_of_it_means_off() -> void:
	# Every existing player's file. Absent is off, with no migration.
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string('{"version": %d, "controls": {}}' % KEY_BINDINGS.FORMAT_VERSION)
	file = null

	var prefs: RefCounted = KEY_BINDINGS.new(path)
	assert_eq(prefs.load_overrides(), KEY_BINDINGS.LOAD_OK)
	assert_false(bool(prefs.gameplay.get(GAME_STATE.PREF_FREE_BUILD, false)))


func test_setting_it_with_nowhere_to_write_still_holds_for_the_session() -> void:
	# No menu means no settings file to reach. The toggle still flips, and
	# set_free_build says it did not save so the screen can tell the owner.
	assert_false(bool(game.set_free_build(true)), "a state with no menu reported a successful save")
	assert_true(bool(game.free_build), "the toggle did not take effect at all")
	assert_true(game.can_afford(_first_buildable()))
