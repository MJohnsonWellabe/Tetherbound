extends "res://tests/test_case.gd"

const LOOK := preload("res://scripts/world/cloudreach_biome_look.gd")


func test_preview_is_restricted_to_the_explicit_capture_script() -> void:
	var opt_in := PackedStringArray(["--cloudreach-look-candidate"])
	assert_false(LOOK.preview_allowed(PackedStringArray(), opt_in))
	assert_false(LOOK.preview_allowed(PackedStringArray(["--script", "tests/run_tests.gd"]), opt_in))
	assert_false(LOOK.preview_allowed(PackedStringArray(["--script", "tools/capture_cloudreach_biome_look.gd"]), PackedStringArray()))
	assert_true(LOOK.preview_allowed(PackedStringArray(["--script", "res://tools/capture_cloudreach_biome_look.gd"]), opt_in))
	assert_true(LOOK.preview_allowed(PackedStringArray(["-s", "tools/capture_cloudreach_biome_look.gd"]), opt_in))
	for arguments: PackedStringArray in [
		PackedStringArray(["tools/capture_cloudreach_biome_look.gd"]),
		PackedStringArray(["--script", "tests/run_tests.gd", "--path", "tools/capture_cloudreach_biome_look.gd"]),
		PackedStringArray(["--", "--script", "tools/capture_cloudreach_biome_look.gd"]),
		PackedStringArray(["--script"]),
		PackedStringArray(["--script", "", "--script", "tools/capture_cloudreach_biome_look.gd"]),
		PackedStringArray(["--script", "tools/capture_cloudreach_biome_look.gd", "-s", "tests/run_tests.gd"]),
	]:
		assert_false(LOOK.preview_allowed(arguments, opt_in), "only the actual unambiguous script opts in")
	var spec: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(LOOK.PATH))
	assert_false(spec.enabled, "unjudged look remains OFF")


func test_rig_preserves_clock_and_quality_and_does_not_mutate_shared_config() -> void:
	var spec: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(LOOK.PATH))
	var base: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/art.json"))
	var before := base.duplicate(true)
	var result := LOOK.apply_rig(base, spec)
	assert_eq(base, before)
	assert_eq(result.day_length_seconds, base.day_length_seconds)
	for time: String in ["dawn", "day", "golden", "night", "night_end"]:
		assert_eq(result.times[time].hour, base.times[time].hour)
		for key: String in spec.grade:
			assert_eq(result.times[time].environment[key], spec.grade[key])
	assert_eq(result.times.night_end.same_as, "night")
	assert_false(result.times.night_end.has("sky"), "held night cannot inherit old daylight profile")
	for key: String in base:
		if key not in ["times", "environment"]:
			assert_eq(result[key], base[key], "no shared quality/clock/system change: " + key)


func test_disabled_rig_and_overlay_preserve_baseline() -> void:
	var base := {"sun": {"energy": 1.4}, "times": {"night": {"hour": 23.0}}}
	assert_eq(LOOK.apply_rig(base, {}), base)
	assert_eq(LOOK.apply_visual(base), base)
