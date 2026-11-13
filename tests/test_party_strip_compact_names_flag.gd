extends "res://tests/test_case.gd"

## F39#19 candidate: creature names on the fight roster's compact rows.
## OFF until a GPU verdict; with it off the compact strip is unchanged.
const PARTY_STRIP := preload("res://scripts/ui/party_strip.gd")


func test_flag_is_off_and_the_compact_strip_is_unchanged() -> void:
	var cfg: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/combat_roster_visual.json"))
	var block: Dictionary = cfg["compact_names_1113"]
	assert_false(bool(block.get("enabled", true)))
	assert_true(float(block.get("row_width", 0.0)) > PARTY_STRIP.COMPACT_ROW_WIDTH, "the candidate widens the rows for a name")
	assert_false(PARTY_STRIP.compact_names_enabled())
	assert_eq(PARTY_STRIP.compact_row_width(), PARTY_STRIP.COMPACT_ROW_WIDTH)
