extends "res://tests/test_case.gd"

## F38#16 candidate: Tam's own outfit colour, with a matching portrait.
## OFF until a GPU verdict; with it off Tam's portrait path is unchanged.
const DIALOGUE_PANEL := preload("res://scripts/ui/dialogue_panel.gd")


func test_flag_is_off_and_only_tam_is_covered() -> void:
	var doc: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/character_body_flags.json"))
	var flag: Dictionary = doc["flags"]["scene_tam_outfit_1113"]
	assert_false(bool(flag.get("enabled", true)))
	assert_eq((flag["characters"] as Dictionary).keys(), ["villager_smith"])
	var body := str(flag["characters"]["villager_smith"]["body_albedo_override"])
	assert_true(ResourceLoader.exists(body), "the outfit texture is installed")
	for target: Variant in (flag["portrait_remap"] as Dictionary).values():
		assert_true(ResourceLoader.exists(str(target)), "the matching portrait is installed")


func test_portrait_is_unchanged_while_off() -> void:
	assert_eq(DIALOGUE_PANEL.body_flag_portrait("res://assets/ui/portraits/tam.png"), "res://assets/ui/portraits/tam.png")
