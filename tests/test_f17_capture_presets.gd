extends "res://tests/test_case.gd"

const CAPTURE := preload("res://tools/capture_f17_visual.gd")

func test_native_capture_preset_branches_return_typed_strings() -> void:
	# Execute the production preset selection without constructing a SceneTree.
	var low: Array[String] = CAPTURE.capture_presets("Low", false)
	assert_eq(low.size(), 1)
	assert_eq(low[0], "Low")
	var medium: Array[String] = CAPTURE.capture_presets("Medium", false)
	assert_eq(medium.size(), 1)
	assert_eq(medium[0], "Medium")
	var paired: Array[String] = CAPTURE.capture_presets("Medium", true)
	assert_eq(paired.size(), 2)
	assert_eq(paired[0], "Medium")
	assert_eq(paired[1], "High")
