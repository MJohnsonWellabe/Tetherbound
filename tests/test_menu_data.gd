extends "res://tests/test_case.gd"

## The menu's data files, checked as data.
##
## The menu is deliberately described in JSON rather than coded, which moves a
## whole class of bug out of the compiler's reach: a typo'd script path shows as
## a silently blank tab, a renamed item id shows as a build cost nobody can ever
## meet, and a columns value that does not divide the slot count shows as a
## ragged grid. None of that is visible from a green build.

const ITEM_DB := preload("res://autoload/item_db.gd")
const INVENTORY := preload("res://autoload/inventory.gd")

const MENU_CONFIG := "res://data/config/menu.json"
const MENU_TAB_BASE := "res://scripts/ui/menu_tab.gd"

var config: Dictionary = {}
var db: RefCounted = null


func before_each() -> void:
	config = _json(MENU_CONFIG)
	db = ITEM_DB.new()


func _json(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	return parsed as Dictionary if typeof(parsed) == TYPE_DICTIONARY else {}


func test_the_menu_config_parses() -> void:
	assert_false(config.is_empty(), "data/config/menu.json failed to parse")
	assert_true(config.has("tabs"))


func test_every_tab_has_an_id_a_label_and_a_script_that_exists() -> void:
	var tabs: Array = config.get("tabs", [])
	assert_true(tabs.size() >= 3, "backpack, pals and build are all expected")
	for entry in tabs:
		var tab: Dictionary = entry
		assert_false(str(tab.get("id", "")).is_empty(), "a tab has no id")
		assert_false(str(tab.get("label", "")).is_empty(), "tab %s has no label" % tab.get("id"))
		var script_path := str(tab.get("script", ""))
		assert_true(
			ResourceLoader.exists(script_path),
			"tab %s points at a missing script: %s" % [tab.get("id"), script_path]
		)


func test_every_tab_script_is_a_menu_tab() -> void:
	# A tab whose script does not extend the base would be added to the content
	# area and then never told to build, poll or hand over focus — an empty
	# panel with no error anywhere.
	for entry in config.get("tabs", []):
		var script: GDScript = load(str((entry as Dictionary).get("script", "")))
		assert_ne(script, null)
		var base: Script = script.get_base_script()
		assert_ne(base, null, "tab %s extends nothing" % (entry as Dictionary).get("id"))
		assert_eq(
			base.resource_path, MENU_TAB_BASE,
			"tab %s must extend menu_tab.gd" % (entry as Dictionary).get("id")
		)


func test_tab_ids_are_unique() -> void:
	var seen: Array[String] = []
	for entry in config.get("tabs", []):
		var id := str((entry as Dictionary).get("id", ""))
		assert_false(seen.has(id), "two tabs share the id %s" % id)
		seen.append(id)


func test_the_expected_three_tabs_are_present() -> void:
	var ids: Array[String] = []
	for entry in config.get("tabs", []):
		ids.append(str((entry as Dictionary).get("id", "")))
	for expected in ["backpack", "pals", "build"]:
		assert_true(ids.has(expected), "no %s tab" % expected)


func test_every_action_the_menu_binds_exists_in_the_input_map() -> void:
	# The menu reads action names out of JSON. A name that is not in
	# project.godot's input map does not error — it just never fires, and the
	# menu becomes unopenable with no clue why.
	var actions: Array[String] = [
		str(config.get("open_action", "")),
		str(config.get("close_action", "")),
		str(config.get("cycle_action", "")),
		str(config.get("reverse_cycle_action", "")),
	]
	var shortcuts: Dictionary = config.get("shortcuts", {})
	for action in shortcuts.keys():
		actions.append(str(action))
	for action in actions:
		assert_true(InputMap.has_action(action), "menu.json names an unbound action: %s" % action)


func test_every_shortcut_points_at_a_real_tab() -> void:
	var ids: Array[String] = []
	for entry in config.get("tabs", []):
		ids.append(str((entry as Dictionary).get("id", "")))
	var shortcuts: Dictionary = config.get("shortcuts", {})
	for action in shortcuts.keys():
		assert_true(ids.has(str(shortcuts[action])), "%s opens a tab that does not exist" % action)


func test_the_grid_columns_divide_the_slot_count() -> void:
	var columns: int = int((config.get("backpack", {}) as Dictionary).get("columns", 0))
	assert_true(columns > 0)
	assert_eq(INVENTORY.SLOT_COUNT % columns, 0, "the last row of the satchel would be ragged")


func test_the_theme_resource_loads() -> void:
	# One theme for the whole menu. If it fails to load the menu still runs, in
	# the engine's default grey, with a focus ring nobody can see on a handheld.
	var theme: Theme = load("res://scenes/ui/menu_theme.tres")
	assert_ne(theme, null)
	assert_ne(theme.get_stylebox("focus", "Button"), null, "focus must be styled; it is the cursor")


func test_the_menu_scene_loads_and_is_a_canvas_layer() -> void:
	var packed: PackedScene = load("res://scenes/ui/game_menu.tscn")
	assert_ne(packed, null)
	var state := packed.get_state()
	assert_eq(state.get_node_type(0), "CanvasLayer")


func test_every_buildable_costs_items_that_exist() -> void:
	var buildables: Array = db.buildables()
	assert_true(buildables.size() >= 1, "the build menu needs at least one entry")
	for entry in buildables:
		var piece: Dictionary = entry
		assert_false(str(piece.get("id", "")).is_empty())
		assert_false(str(piece.get("name", "")).is_empty())
		var cost: Array = piece.get("cost", [])
		assert_true(cost.size() > 0, "%s is free, which is almost certainly a typo" % piece.get("id"))
		for requirement in cost:
			var id := str((requirement as Dictionary).get("id", ""))
			assert_true(db.has(id), "%s costs an item that does not exist: %s" % [piece.get("id"), id])
			assert_true(int((requirement as Dictionary).get("n", 0)) > 0)


func test_a_buildable_can_actually_be_afforded() -> void:
	# A cost above what the satchel can physically hold would be a piece that is
	# permanently unbuildable, and the menu would never say so.
	var bag: RefCounted = INVENTORY.new(db)
	for entry in db.buildables():
		for requirement in (entry as Dictionary).get("cost", []):
			var id := str((requirement as Dictionary).get("id", ""))
			var need := int((requirement as Dictionary).get("n", 0))
			assert_true(
				bag.has_room_for(id, need),
				"%s needs %d %s, more than a satchel can carry" % [(entry as Dictionary).get("id"), need, id]
			)
