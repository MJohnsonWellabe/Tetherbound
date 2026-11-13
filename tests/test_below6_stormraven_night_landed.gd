extends "res://tests/test_case.gd"

## F41#13 Stormraven (LANE-BELOW6, 13 Nov 2026). GPU High
## G-below6-stormraven-r3: 5.76 -> 6.67 (+0.91), 3/3. The near-black feather
## coat with lit lightning lines and a cool rim ships ON, cites that verdict,
## and is the coat the live table resolves.

const BODY := preload("res://scripts/creatures/creature_body.gd")
const COAT_PATH := "res://data/config/creature_coat_flags.json"
const SOURCE := "res://assets/creatures/tetherbound/stormraven/candidate_owner1101/models/creature_stormraven_owner1101_Image_0.jpg"


func test_night_coat_ships_on_and_cites_the_verdict() -> void:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(COAT_PATH))
	var entry: Dictionary = ((parsed as Dictionary).get("flags", {}) as Dictionary).get("below6_stormraven_night", {})
	assert_true(bool(entry.get("enabled", false)), "below6_stormraven_night ships ON (judged gain)")
	var why := str(entry.get("_why_on", ""))
	assert_true(why.contains("G-below6-stormraven-r3.md"), "it cites its GPU verdict")
	assert_true(why.contains("5.76 -> 6.67"), "and its judged score")


func test_live_coat_table_resolves_the_night_coat() -> void:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(COAT_PATH))
	var spec: Dictionary = BODY.parse_coat_flags(parsed).get(SOURCE, {})
	assert_true(str(spec.get("albedo", "")).ends_with("_Image_0_night.png"), "Stormraven wears the night coat")
	assert_true(str(spec.get("emission", "")).ends_with("_glow_read_r2.png"), "its lightning lines are lit")
	assert_true(ResourceLoader.exists(str(spec.get("albedo", ""))), "the night albedo exists")
	assert_true(ResourceLoader.exists(str(spec.get("emission", ""))), "the glow map exists")
	assert_true(float(spec.get("rim", 0.0)) >= 0.9, "the dark body keeps a strong rim")
