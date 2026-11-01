extends "res://tests/test_case.gd"

## P2-095: craft_presentation.json `rendered_item_icons` swaps craft-panel
## icons for ones rendered from installed meshes, and only where one exists.

const PANEL := preload("res://scripts/ui/craft_panel.gd")
const FLAT := {"icon": "res://assets/ui/icons/items/axe.png"}


func test_the_flag_ships_off() -> void:
	var cfg: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/craft_presentation.json"))
	assert_eq(cfg.get("rendered_item_icons"), true, "rendered_item_icons ships ON: cloud yardstick 1 Nov, 6.80 -> 7.36")


func test_off_keeps_the_items_json_icon() -> void:
	assert_eq(PANEL.icon_path_for("axe", FLAT, false), "res://assets/ui/icons/items/axe.png")


func test_on_uses_the_rendered_icon_when_baked() -> void:
	assert_eq(PANEL.icon_path_for("axe", FLAT, true), "res://assets/ui/icons/items_rendered/axe.png")
	assert_true(ResourceLoader.exists(PANEL.icon_path_for("axe", FLAT, true)))


func test_on_falls_back_where_nothing_was_baked() -> void:
	assert_eq(PANEL.icon_path_for("tidesteel_ingot", {"icon": "res://x.png"}, true), "res://x.png",
		"an item with no rendered icon keeps its own")
	assert_eq(PANEL.icon_path_for("", FLAT, true), "res://assets/ui/icons/items/axe.png")


func test_every_configured_icon_was_baked() -> void:
	var cfg: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/craft_item_icons.json"))
	for id: String in cfg.get("items", {}):
		assert_true(ResourceLoader.exists("%s/%s.png" % [PANEL.RENDERED_ICON_DIR, id]),
			"craft_item_icons.json lists %s but no icon was baked" % id)
