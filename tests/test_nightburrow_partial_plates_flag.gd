extends "res://tests/test_case.gd"

## F36#56 Nightburrow partial-plates arm (creature_coat_flags.json
## `creatures_ralph_nightburrow_partial_plates`, written by
## tools/art_pipeline/nightburrow_partial_plates.py). It ships OFF until the
## GPU judges it, and while OFF the live Nightburrow coat stays exactly what
## shipped before the arm existed: the creatures_f36_coat_lift_2 grade.

const BODY := preload("res://scripts/creatures/creature_body.gd")
const FLAGS_PATH := "res://data/config/creature_coat_flags.json"
const FLAG := "creatures_ralph_nightburrow_partial_plates"
const MODELS := "res://assets/creatures/tetherbound/burrowback/candidate_nat1024/models/"
const LIVE := MODELS + "creature_burrowback_nat1024_Image_0_nightburrow.png"
const SHIPPED := MODELS + "creature_burrowback_nat1024_Image_0_nightburrow_coat_lift.png"
const ARM_ALBEDO := MODELS + "creature_burrowback_nat1024_Image_0_nightburrow_partial_plates.png"
const ARM_GLOW := MODELS + "creature_burrowback_nat1024_Image_0_emissive_nightburrow_partial_plates.png"


func _parsed() -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(FLAGS_PATH))
	assert_true(parsed is Dictionary, "creature_coat_flags.json parses to an object")
	return parsed if parsed is Dictionary else {}


## Visual lane v1/b18 (4 Nov): the arm ships ON with its judged score (6.37 -> 6.67).
func test_arm_ships_on_with_its_score_and_names_its_new_files() -> void:
	var flags: Dictionary = _parsed().get("flags", {})
	assert_true(flags.has(FLAG), "the partial-plates arm is declared")
	var entry: Dictionary = flags.get(FLAG, {})
	assert_true(bool(entry.get("enabled", false)), "%s ships ON (judged gain)" % FLAG)
	assert_true(str(entry.get("_why_on", "")).contains("6.67"), "it records its mapped score")
	assert_true(str(entry.get("_why", "")).contains("F36#56"), "its _why names board row F36#56")
	var spec: Dictionary = (entry.get("coats", {}) as Dictionary).get(LIVE, {})
	assert_eq(str(spec.get("albedo", "")), ARM_ALBEDO, "the arm maps the live Nightburrow coat to its new albedo")
	assert_eq(str(spec.get("emission", "")), ARM_GLOW, "and to its trimmed glow map")
	assert_true(FileAccess.file_exists(ARM_ALBEDO), "the new albedo is on disk")
	assert_true(FileAccess.file_exists(ARM_GLOW), "the new glow map is on disk")
	assert_true(ARM_ALBEDO != SHIPPED and ARM_GLOW != SHIPPED, "the arm writes new files, not the shipped ones")


## v1/b22 (4 Nov): `creatures_ralph_nightburrow_value_lift` (ON) lifts this
## arm's albedo; with the lift OFF, ON still resolves to the arm.
const LIFT_FLAG := "creatures_ralph_nightburrow_value_lift"
const LIFT_ALBEDO := MODELS + "creature_burrowback_nat1024_Image_0_nightburrow_value_lift.png"


func test_on_resolves_to_the_arm_and_off_leaves_the_shipped_coat_path() -> void:
	var lift_off := _parsed()
	(lift_off.flags[LIFT_FLAG] as Dictionary)["enabled"] = false
	var on: Dictionary = BODY.parse_coat_flags(lift_off).get(LIVE, {})
	assert_eq(str(on.get("albedo", "")), ARM_ALBEDO, "ON: Nightburrow resolves to the partial-plates albedo")
	var lifted: Dictionary = BODY.parse_coat_flags(_parsed()).get(LIVE, {})
	assert_eq(str(lifted.get("albedo", "")), LIFT_ALBEDO, "with the shipped value lift, the plates albedo is lifted")
	assert_eq(str(lifted.get("emission", "")), ARM_GLOW, "and the arm's glow map is kept")
	var parsed := _parsed()
	(parsed.flags[LIFT_FLAG] as Dictionary)["enabled"] = false
	(parsed.flags[FLAG] as Dictionary)["enabled"] = false
	var resolved: Dictionary = BODY.parse_coat_flags(parsed)
	var spec: Dictionary = resolved.get(LIVE, {})
	assert_eq(str(spec.get("albedo", "")), SHIPPED, "OFF: Nightburrow still resolves to the shipped coat-lift grade")
	assert_false(spec.has("emission"), "OFF: the aspect glow map is left to the aspect swap")
	for from_path: String in resolved:
		var albedo := str((resolved[from_path] as Dictionary).get("albedo", ""))
		assert_true(albedo != ARM_ALBEDO, "OFF: no live coat resolves to the arm's albedo (%s)" % from_path)
