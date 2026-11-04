extends "res://tests/test_case.gd"

## F36#54 Mosshock value lift (creature_coat_flags.json
## `creatures_ralph_mosshock_value_lift`). Judged gain, ships ON. Only the albedo
## changes; OFF leaves the live coat exactly as before.

const BODY := preload("res://scripts/creatures/creature_body.gd")
const FLAGS_PATH := "res://data/config/creature_coat_flags.json"
const FLAG := "creatures_ralph_mosshock_value_lift"
const MODELS := "res://assets/creatures/tetherbound/mosshock/candidate_owner1101/models/"
const LIVE := MODELS + "creature_mosshock_owner1101_Image_0.jpg"
const LIFT := MODELS + "creature_mosshock_owner1101_Image_0_value_lift.png"


func _parsed() -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(FLAGS_PATH))
	assert_true(parsed is Dictionary, "creature_coat_flags.json parses")
	return parsed if parsed is Dictionary else {}


func test_arm_ships_on_with_its_score() -> void:
	var entry: Dictionary = (_parsed().get("flags", {}) as Dictionary).get(FLAG, {})
	assert_true(bool(entry.get("enabled", false)), "%s ships ON (judged gain)" % FLAG)
	assert_true(str(entry.get("_why_on", "")).contains("6.55"), "it records its mapped score")
	assert_true(FileAccess.file_exists(LIFT), "the lifted albedo is on disk")


func test_on_lifts_only_the_albedo() -> void:
	var spec: Dictionary = BODY.parse_coat_flags(_parsed()).get(LIVE, {})
	assert_eq(str(spec.get("albedo", "")), LIFT, "ON: Mosshock's albedo resolves to the lift")
	var parsed := _parsed()
	(parsed.flags[FLAG] as Dictionary)["enabled"] = false
	var before: Dictionary = BODY.parse_coat_flags(parsed).get(LIVE, {})
	for key: String in before:
		assert_eq(str(spec.get(key, "")), str(before[key]), "ON keeps every other coat value (%s)" % key)


func test_off_keeps_the_live_coat() -> void:
	var parsed := _parsed()
	(parsed.flags[FLAG] as Dictionary)["enabled"] = false
	var spec: Dictionary = BODY.parse_coat_flags(parsed).get(LIVE, {})
	assert_false(str(spec.get("albedo", "")) == LIFT, "OFF: the lift is not used")
	for from_path: String in BODY.parse_coat_flags(parsed):
		var albedo := str((BODY.parse_coat_flags(parsed)[from_path] as Dictionary).get("albedo", ""))
		assert_true(albedo != LIFT, "OFF: no live coat resolves to the lift (%s)" % from_path.get_file())
