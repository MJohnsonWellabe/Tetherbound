extends "res://tests/test_case.gd"

## F36#80 Thundertunnel (LANE-BELOW6, 11 Nov 2026). GPU High G-below6:
## 4.63 -> 6.04 (+1.41), 3/3. The mole-velvet coat with lit storm lines ships
## ON, cites that verdict, and is the coat the live table resolves.

const BODY := preload("res://scripts/creatures/creature_body.gd")
const COAT_PATH := "res://data/config/creature_coat_flags.json"
const SOURCE := "res://assets/creatures/tetherbound/thundertunnel/candidate_owner1101/models/creature_thundertunnel_owner1101_Image_0.jpg"


func test_thundertunnel_coat_ships_on_and_cites_the_verdict() -> void:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(COAT_PATH))
	var entry: Dictionary = ((parsed as Dictionary).get("flags", {}) as Dictionary).get("below6_floor_thundertunnel", {})
	assert_true(bool(entry.get("enabled", false)), "below6_floor_thundertunnel ships ON (judged gain)")
	var why := str(entry.get("_why_on", ""))
	assert_true(why.contains("G-below6-thundertunnel-heartwood.md"), "it cites its GPU verdict")
	assert_true(why.contains("4.63 -> 6.04"), "and its judged score")


func test_live_coat_table_resolves_the_velvet_and_its_storm_lines() -> void:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(COAT_PATH))
	var spec: Dictionary = BODY.parse_coat_flags(parsed).get(SOURCE, {})
	assert_true(str(spec.get("albedo", "")).ends_with("_value_lift_floor1.png"), "Thundertunnel wears the floor1 velvet")
	assert_true(str(spec.get("emission", "")).ends_with("_value_lift_floor1_glow.png"), "its storm lines are lit")
	assert_true(ResourceLoader.exists(str(spec.get("albedo", ""))), "the graded albedo exists")
	assert_true(ResourceLoader.exists(str(spec.get("emission", ""))), "the glow map exists")
