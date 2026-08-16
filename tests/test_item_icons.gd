extends "res://tests/test_case.gd"

## M-G groundwork. Every item in `data/items/items.json` now names an `icon`
## (res:// path to a 64px Kenney Game Icons silhouette) and a non-empty
## `description` (the fuller inventory-detail text, alongside the existing
## shorter `blurb`). This test guards both fields the same way
## test_map_icons.gd guards the map's icon vocabulary: existence, and that the
## file actually loads as a texture rather than just passing
## ResourceLoader.exists(). It also checks the small shared UI icon set
## (assets/ui/icons/ui/) that joined the same vendoring pass — see
## docs/ASSET_LEDGER.md's "Item + shared UI icons" row for the per-file source
## mapping.

const ITEMS_PATH := "res://data/items/items.json"
const UI_ICON_DIR := "res://assets/ui/icons/ui/"

## The shared UI icon set this task's brief names explicitly. Nothing in
## items.json points at these -- they are read directly by path wherever the
## HUD/build-menu/bond UI needs them, so (like test_map_icons.gd's
## ALWAYS_REQUIRED) they are checked by name rather than discovered from data.
const UI_ICONS: Array[String] = [
	"type_ground", "type_water", "type_air",
	"bond",
	"orb_tier_basic",
	"move_quick", "move_charged",
	"cat_survival", "cat_crafting", "cat_structures", "cat_furniture",
]


func _json(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	return parsed as Dictionary if typeof(parsed) == TYPE_DICTIONARY else {}


func _items() -> Dictionary:
	return _json(ITEMS_PATH).get("items", {}) as Dictionary


func test_items_json_has_items() -> void:
	assert_false(_items().is_empty(), "items.json named no items at all")


func test_every_item_has_an_icon_field_whose_file_exists() -> void:
	var items := _items()
	for item_id: String in items.keys():
		var item := items[item_id] as Dictionary
		var icon := str(item.get("icon", ""))
		assert_false(icon.is_empty(), "item '%s' has no icon field" % item_id)
		if not icon.is_empty():
			assert_true(ResourceLoader.exists(icon),
				"item '%s' names icon '%s' but no file exists there" % [item_id, icon])


func test_every_item_icon_loads_as_a_texture() -> void:
	# A file that exists but fails to import (corrupt PNG, wrong extension
	# masquerading as one) passes ResourceLoader.exists() and then draws
	# nothing -- load() and a type check catch that the existence check alone
	# would miss, same reasoning as test_map_icons.gd.
	var items := _items()
	for item_id: String in items.keys():
		var item := items[item_id] as Dictionary
		var icon := str(item.get("icon", ""))
		if icon.is_empty():
			continue
		var tex: Texture2D = load(icon) as Texture2D
		assert_ne(tex, null, "item '%s' icon %s exists but did not load as a Texture2D" % [item_id, icon])


func test_every_item_has_a_non_empty_description() -> void:
	var items := _items()
	for item_id: String in items.keys():
		var item := items[item_id] as Dictionary
		var description := str(item.get("description", ""))
		assert_false(description.is_empty(), "item '%s' has no description" % item_id)


func test_the_shared_ui_icon_set_is_vendored() -> void:
	for icon_name in UI_ICONS:
		var path := "%s%s.png" % [UI_ICON_DIR, icon_name]
		assert_true(ResourceLoader.exists(path),
			"shared UI icon '%s' has no file at %s" % [icon_name, path])


func test_the_shared_ui_icon_set_loads_as_textures() -> void:
	for icon_name in UI_ICONS:
		var path := "%s%s.png" % [UI_ICON_DIR, icon_name]
		var tex: Texture2D = load(path) as Texture2D
		assert_ne(tex, null, "%s exists but did not load as a Texture2D" % path)


## SE22. The Mill Bridge Gear is what opens the Old Mill Crossing, and the two
## properties that make it work as a gate item -- one per satchel, and its own
## silhouette in that satchel -- are exactly the two a later edit could break
## without anything crashing.
func test_the_mill_bridge_gear_is_a_single_stack_key_with_its_own_icon() -> void:
	var items := _items()
	assert_true(items.has("mill_bridge_gear"),
		"items.json has no `mill_bridge_gear`; SE22's crossing is keyed to an item that does not exist")
	if not items.has("mill_bridge_gear"):
		return
	var gear := items["mill_bridge_gear"] as Dictionary
	assert_eq(str(gear.get("kind", "")), "key",
		"the Mill Bridge Gear is not `kind: key`, so it sorts and reads as ordinary loot")
	assert_eq(int(gear.get("stack", 0)), 1,
		"the Mill Bridge Gear stacks; a gate item the player can hold two of is a bug waiting to be found")
	var icon := str(gear.get("icon", ""))
	assert_true(icon.ends_with("mill_bridge_gear.png"),
		"the Mill Bridge Gear shares another item's icon (%s) -- it needs its own silhouette" % icon)
	assert_true(ResourceLoader.exists(icon), "no icon file at %s" % icon)
