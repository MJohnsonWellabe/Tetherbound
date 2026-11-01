extends "res://tests/test_case.gd"

## P2-095 round 4 (UIPOSES): craft_presentation readable_r4 ships OFF; the tag
## chip fills by affordability.

const CRAFT := preload("res://scripts/ui/craft_panel.gd")


func test_readable_r4_ships_off() -> void:
	var cfg: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/craft_presentation.json"))
	assert_false(bool(cfg.get("readable_r4", true)), "readable_r4 defaults OFF")
	assert_true(int(cfg.get("r4_visible_rows", 0)) >= 5, "round 4 shows five or more rows")


func test_tag_chip_fill_follows_affordability() -> void:
	assert_eq(CRAFT.r4_tag_box(true).bg_color, UITokens.SUCCESS)
	assert_eq(CRAFT.r4_tag_box(false).bg_color, UITokens.DANGER)
