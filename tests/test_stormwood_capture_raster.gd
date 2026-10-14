extends "res://tests/test_case.gd"
const RASTER := preload("res://tools/stormwood_capture_raster.gd")


func test_json_and_native_numeric_dimensions_resolve_to_the_same_exact_raster() -> void:
	var parsed: Variant = JSON.parse_string("[1920,1080]")
	assert_eq(typeof(parsed[0]), TYPE_FLOAT, "exercise the actual JSON camera representation")
	var expected := RASTER.exact_size(parsed)
	assert_eq(expected, Vector2i(1920, 1080))
	for dimensions in [[1920, 1080], [1920.0, 1080], [1920, 1080.0], parsed, Vector2i(1920, 1080)]:
		assert_true(RASTER.matches_size(dimensions, expected))


func test_invalid_or_fractional_dimensions_cannot_be_truncated_into_a_match() -> void:
	for invalid in [null, [], [1920], [1920, 1080, 1], [1920.1, 1080], [1920, 1080.9], [0, 1080], [-1920, 1080], [INF, 1080], [NAN, 1080], [2147483648.0, 1080], ["1920", 1080], [true, 1080]]:
		assert_eq(RASTER.exact_size(invalid), Vector2i.ZERO)
		assert_false(RASTER.matches_size(invalid, Vector2i(1920, 1080)))
	assert_false(RASTER.matches_size([0, 0], Vector2i.ZERO))


func test_every_observed_size_and_mode_must_match_without_approximation() -> void:
	var observed := {"window_size": [1920, 1080], "viewport_size": [1920.0, 1080], "texture_size": [1920, 1080.0], "window_mode": 4, "content_scale_mode": 0.0}
	var expected := Vector2i(1920, 1080)
	assert_true(RASTER.matches_viewport(observed, expected))
	assert_true(RASTER.matches_viewport(JSON.parse_string(JSON.stringify(observed)), expected))
	for key in ["window_size", "viewport_size", "texture_size"]:
		for wrong in [[1920, 1061], [1919, 1080], [1920, 1080.01]]:
			var changed: Dictionary = observed.duplicate(true)
			changed[key] = wrong
			assert_false(RASTER.matches_viewport(changed, expected), "reject mismatched " + key)
	for key in ["window_mode", "content_scale_mode"]:
		for wrong in [null, "4", true, 4.5, 1]:
			var changed: Dictionary = observed.duplicate(true)
			changed[key] = wrong
			assert_false(RASTER.matches_viewport(changed, expected))
	assert_false(RASTER.matches_viewport({}, expected))


func test_raw_image_dimensions_use_the_same_exact_gate() -> void:
	var image := Image.create(3, 2, false, Image.FORMAT_RGBA8)
	var expected := RASTER.exact_size(JSON.parse_string("[3,2]"))
	assert_true(RASTER.matches_size(image.get_size(), expected))
	assert_false(RASTER.matches_size(image.get_size(), Vector2i(3, 3)))
	assert_eq(image.get_size(), Vector2i(3, 2), "checking a raster never resizes it")
