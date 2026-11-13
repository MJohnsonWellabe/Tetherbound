extends "res://tests/test_case.gd"

## F41#8 / F41#18: Staticub storm fur, landed ON (13 Nov 2026,
## G-below6-staticub-fur-dialogue-c673.md: Nysa 5.95 -> 6.45, F41#8 Maud and
## Bryn 6.09 -> 6.27, both 3/3). It is the coat the table resolves for the r10
## Staticub, in place of the value-lift copy; OFF restores the lift.

const BODY := preload("res://scripts/creatures/creature_body.gd")
const COAT_PATH := "res://data/config/creature_coat_flags.json"
const SOURCE := "res://assets/creatures/tetherbound/staticub/candidate_r10/models/creature_staticub_r10_Image_0.jpg"
const FLAG := "below6_staticub_storm_fur"


func test_storm_fur_ships_on_with_its_verdict_and_resolves() -> void:
	var parsed: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(COAT_PATH))
	var entry: Dictionary = (parsed.flags as Dictionary).get(FLAG, {})
	assert_true(bool(entry.get("enabled", false)), "storm fur ships ON")
	var why := str(entry.get("_why_on", ""))
	assert_true(why.contains("G-below6-staticub-fur-dialogue-c673") and why.contains("5.95") and why.contains("6.45"),
		"it cites its verdict and scores")
	var spec: Dictionary = BODY.parse_coat_flags(parsed).get(SOURCE, {})
	assert_true(str(spec.get("albedo", "")).ends_with("_Image_0_storm.png"), "ON: the storm fur is the live coat")
	assert_true(ResourceLoader.exists(str(spec.get("albedo", ""))))


func test_off_restores_the_value_lift() -> void:
	var parsed: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(COAT_PATH))
	((parsed.flags as Dictionary)[FLAG] as Dictionary)["enabled"] = false
	var live: Dictionary = BODY.parse_coat_flags(parsed).get(SOURCE, {})
	assert_true(str(live.get("albedo", "")).ends_with("_value_lift.png"), "OFF: the value lift is the coat")
