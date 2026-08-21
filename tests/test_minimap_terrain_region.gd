extends "res://tests/test_case.gd"

const MINIMAP := preload("res://scripts/ui/minimap.gd")


func test_corridor_world_window_maps_to_rectangular_texture_pixels() -> void:
	var bounds := {
		"min_x": -1024.0,
		"max_x": 1024.0,
		"min_z": -512.0,
		"max_z": 7680.0,
	}
	var source := MINIMAP.terrain_source_region(
		Vector2(0.0, 0.0), 96.0, Vector2(512.0, 2048.0), bounds)

	assert_eq(source.position, Vector2(244.0, 116.0),
		"the village window must sample inside the bake at its true corridor position")
	assert_eq(source.size, Vector2(24.0, 24.0),
		"square world metres must stay square in a correctly-aspected texture")


func test_region_conversion_scales_each_axis_independently() -> void:
	var bounds := {"min_x": 0.0, "max_x": 200.0, "min_z": 0.0, "max_z": 800.0}
	var source := MINIMAP.terrain_source_region(
		Vector2(100.0, 400.0), 80.0, Vector2(100.0, 200.0), bounds)

	assert_eq(source.position, Vector2(30.0, 90.0))
	assert_eq(source.size, Vector2(40.0, 20.0),
		"non-square texture texels must be represented honestly rather than assumed to be metres")
