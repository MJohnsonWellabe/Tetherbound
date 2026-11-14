extends "res://tests/test_case.gd"

## F38#10 candidate: Players seat cards and the Quest Log story card.
## OFF until a GPU verdict; with it off neither tab reads a fill block.
const TAB_PLAYERS := preload("res://scripts/ui/tab_players.gd")


func test_flag_is_off() -> void:
	var cfg: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/menu.json"))
	var block: Dictionary = cfg["panel_fill_1113"]
	assert_false(bool(block.get("enabled", true)))
	assert_true(block.has("players") and block.has("quest_log"))
	assert_true(TAB_PLAYERS.panel_fill_cfg("players").is_empty())
	assert_true(TAB_PLAYERS.panel_fill_cfg("quest_log").is_empty())


func test_the_region_art_the_quest_card_uses_is_installed() -> void:
	for realm: String in ["meadows", "water", "cloudreach", "stormwood"]:
		assert_true(ResourceLoader.exists("res://assets/ui/region_bands/%s.png" % realm), realm)
