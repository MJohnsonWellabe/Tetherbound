extends "res://tests/test_case.gd"

const COMPASS := preload("res://scripts/ui/compass_bar.gd")


func test_project_yaw_converts_to_cardinal_headings() -> void:
	assert_almost_eq(COMPASS.heading_degrees(0.0), 180.0, 0.001,
		"project yaw zero faces +Z, which the compass names south")
	assert_almost_eq(COMPASS.heading_degrees(PI), 0.0, 0.001,
		"world -Z must read north")
	assert_almost_eq(COMPASS.heading_degrees(PI * 0.5), 90.0, 0.001,
		"world +X must read east")


func test_world_bearings_share_the_heading_convention() -> void:
	var here := Vector2.ZERO
	assert_almost_eq(COMPASS.bearing_degrees(here, Vector2(0.0, -10.0)), 0.0, 0.001)
	assert_almost_eq(COMPASS.bearing_degrees(here, Vector2(10.0, 0.0)), 90.0, 0.001)
	assert_almost_eq(COMPASS.bearing_degrees(here, Vector2(0.0, 10.0)), 180.0, 0.001)
	assert_almost_eq(COMPASS.bearing_degrees(here, Vector2(-10.0, 0.0)), 270.0, 0.001)


func test_shortest_delta_wraps_cleanly_across_north() -> void:
	assert_almost_eq(COMPASS.signed_heading_delta(350.0, 10.0), 20.0, 0.001)
	assert_almost_eq(COMPASS.signed_heading_delta(10.0, 350.0), -20.0, 0.001)


func test_tape_centres_visible_targets_and_clamps_offscreen_targets() -> void:
	assert_almost_eq(COMPASS.tape_x(0.0, 500.0), 250.0, 0.001)
	assert_almost_eq(COMPASS.tape_x(-180.0, 500.0), COMPASS.EDGE_INSET, 0.001)
	assert_almost_eq(COMPASS.tape_x(180.0, 500.0), 500.0 - COMPASS.EDGE_INSET, 0.001)
