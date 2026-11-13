extends "res://tests/test_case.gd"

## F41#8 / F41#18 candidate: Staticub storm fur. OFF until a GPU verdict; when
## on it is the coat the table resolves, in place of the value-lift copy.

const BODY := preload("res://scripts/creatures/creature_body.gd")
const COAT_PATH := "res://data/config/creature_coat_flags.json"
const SOURCE := "res://assets/creatures/tetherbound/staticub/candidate_r10/models/creature_staticub_r10_Image_0.jpg"
const FLAG := "below6_staticub_storm_fur"


func test_candidate_is_off_and_resolves_when_on() -> void:
	var parsed: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(COAT_PATH))
	var entry: Dictionary = (parsed.flags as Dictionary).get(FLAG, {})
	assert_false(bool(entry.get("enabled", true)), "candidate is OFF")
	var live: Dictionary = BODY.parse_coat_flags(parsed).get(SOURCE, {})
	assert_true(str(live.get("albedo", "")).ends_with("_value_lift.png"), "live coat is still the value lift")
	entry["enabled"] = true
	var spec: Dictionary = BODY.parse_coat_flags(parsed).get(SOURCE, {})
	assert_true(str(spec.get("albedo", "")).ends_with("_Image_0_storm.png"), "ON: the storm fur wins")
	assert_true(ResourceLoader.exists(str(spec.get("albedo", ""))))
