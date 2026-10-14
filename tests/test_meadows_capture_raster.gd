extends "res://tests/test_case.gd"

const RASTER := preload("res://tools/meadows_capture_raster.gd")
const CAMERA_SET := "res://tools/visual_judge/camera_sets/F38-village-hall-slice.json"


func test_authored_json_presets_match_native_integer_rasters() -> void:
	var plan: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(CAMERA_SET))
	assert_eq(typeof(plan.resolution_by_preset.Medium[0]), TYPE_FLOAT,
		"exercise the JSON representation that failed the actual R5 capture")
	for preset: String in ["Low", "Medium", "High"]:
		var expected := Vector2i(1280, 720) if preset == "Low" else Vector2i(1920, 1080)
		assert_true(RASTER.matches_preset(plan, preset, [expected.x, expected.y]))
		assert_true(RASTER.matches_preset(plan, preset, [float(expected.x), expected.y]))
		assert_true(RASTER.matches_preset(plan, preset, [expected.x, float(expected.y)]))
		assert_true(RASTER.matches_preset(plan, preset, expected))
		assert_true(RASTER.matches_preset(plan, preset, plan.resolution_by_preset[preset]))
	assert_false(RASTER.matches_preset(plan, "Low", [1920, 1080]))
	assert_false(RASTER.matches_preset(plan, "Medium", [1280, 720]))
	assert_false(RASTER.matches_preset(plan, "High", [1920, 1061]))
	assert_false(RASTER.matches_preset(plan, "Medium", [1080, 1920]))


func test_invalid_authored_or_observed_dimensions_cannot_be_coerced_into_a_match() -> void:
	var plan := {"resolution_by_preset": {"Medium": [1920.0, 1080.0]}}
	for invalid in [null, [], [1920], [1920, 1080, 1], [1920.1, 1080], [1920, 1080.9],
			[0, 1080], [-1920, 1080], [INF, 1080], [1920, INF], [NAN, 1080], [1920, NAN],
			[2147483648.0, 1080], ["1920", 1080], [1920, "1080"], [true, 1080], [1920, false],
			Vector2(1920, 1080), Vector2i(0, 1080), {"x": 1920, "y": 1080}]:
		assert_eq(RASTER.exact_size(invalid), Vector2i.ZERO)
		assert_false(RASTER.matches_preset(plan, "Medium", invalid))
		var malformed := {"resolution_by_preset": {"Medium": invalid}}
		assert_false(RASTER.matches_preset(malformed, "Medium", [1920, 1080]))
		assert_false(RASTER.matches_preset(malformed, "Medium", invalid),
			"two equally invalid dimensions must never count as a match")


func test_missing_or_malformed_preset_mapping_fails_closed() -> void:
	for malformed in [{}, {"resolution_by_preset": null}, {"resolution_by_preset": []},
			{"resolution_by_preset": "1920x1080"}, {"resolution_by_preset": {}},
			{"resolution_by_preset": {"Other": [1920, 1080]}}]:
		assert_false(RASTER.matches_preset(malformed, "Medium", [1920, 1080]))
		assert_false(RASTER.matches_preset(malformed, "Medium", []))
	var plan: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(CAMERA_SET))
	assert_false(RASTER.matches_preset(plan, "", []))
	assert_false(RASTER.matches_preset(plan, "medium", [1920, 1080]))
	assert_false(RASTER.matches_preset(plan, "Ultra", [1920, 1080]))
