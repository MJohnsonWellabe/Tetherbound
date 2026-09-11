extends "res://tests/test_case.gd"
const OBSERVER := preload("res://tests/helpers/four_biome_road_coverage_observer.gd")
const ROAD := preload("res://tools/gate_f/road_creature_visibility_model.gd")

func test_actual_camera_heading_defines_full_horizontal_half_plane() -> void:
	for yaw in [0.0, PI/3.0, PI, -PI/2.0]:
		var basis := Basis(Vector3.UP, yaw)
		var forward := basis * Vector3.FORWARD
		assert_true(OBSERVER.in_forward_half_plane(forward * 20, forward))
		assert_false(OBSERVER.in_forward_half_plane(-forward * 20, forward))
		assert_true(OBSERVER.in_forward_half_plane(forward * 20 + Vector3.UP * 100, forward))
	assert_true(OBSERVER.in_forward_half_plane(Vector3.RIGHT, Vector3.FORWARD))
	assert_false(OBSERVER.in_forward_half_plane(Vector3.FORWARD, Vector3.UP))

func test_projection_scales_to_authoritative_720p_floor_without_changing_threshold() -> void:
	assert_almost_eq(OBSERVER.pixels_at_reference_height(15, 720), ROAD.MIN_VISIBLE_HEIGHT_PX, 0.00001)
	assert_almost_eq(OBSERVER.pixels_at_reference_height(30, 1440), ROAD.MIN_VISIBLE_HEIGHT_PX, 0.00001)
	assert_almost_eq(OBSERVER.pixels_at_reference_height(16.6666666667, 800), ROAD.MIN_VISIBLE_HEIGHT_PX, 0.00001)
	assert_eq(OBSERVER.pixels_at_reference_height(15, 0), 0.0)
	assert_true(OBSERVER.pixels_at_reference_height(14.9, 720) < ROAD.MIN_VISIBLE_HEIGHT_PX)

func test_route_metadata_reports_projection_but_never_claims_membership() -> void:
	var routes := [{"id":"bent", "points":[Vector3.ZERO,Vector3(10,0,0),Vector3(10,0,10)]}]
	var result := OBSERVER.nearest_route(Vector3(12,40,7), routes)
	assert_eq(result.id, "bent")
	assert_almost_eq(result.distance_m, 2.0, 0.00001)
	assert_almost_eq(result.along_m, 17.0, 0.00001)
	assert_eq(result.tangent, Vector3.BACK)
	assert_eq(result.classification, "nearest_only_not_membership")
	result = OBSERVER.nearest_route(Vector3(10000,0,0), routes)
	assert_eq(result.classification, "nearest_only_not_membership")
	assert_true(result.distance_m > 9000.0)
	assert_eq(OBSERVER.nearest_route(Vector3.ZERO, []).distance_m, null)
	assert_eq(OBSERVER.nearest_route(Vector3.ZERO, []).tangent, Vector3.ZERO)

func test_sample_heading_and_route_tangent_share_the_travel_direction() -> void:
	var travel := OBSERVER.travel_heading_from_sample_origin(
		Vector3(10, -40, 20), Vector3(4, 300, 28))
	assert_almost_eq(travel.length(), 1.0, 0.00001)
	assert_almost_eq(travel.y, 0.0, 0.00001)
	assert_eq(OBSERVER.travel_heading_from_sample_origin(Vector3.INF, Vector3.ZERO), Vector3.ZERO)
	var route := OBSERVER.align_route_tangent_to_travel(Vector3(0, 0, -4), travel)
	assert_true(route.dot(travel) > 0.0)
	assert_eq(route, Vector3.BACK)
	assert_eq(OBSERVER.align_route_tangent_to_travel(Vector3.ZERO, travel), Vector3.ZERO)

func test_only_aligned_road_samples_grade_visibility_failures() -> void:
	var aligned := OBSERVER.alignment_metrics(Vector3.FORWARD, Vector3.FORWARD, Vector3.FORWARD)
	assert_true(OBSERVER.alignment_is_eligible(aligned))
	assert_true(OBSERVER.is_road_failure(1, true))
	assert_false(OBSERVER.is_road_failure(1, false),
		"an unaligned camera sample remains telemetry, never a ROAD failure")
	assert_false(OBSERVER.is_road_failure(2, true))
	var backward := OBSERVER.alignment_metrics(Vector3.BACK, Vector3.FORWARD, Vector3.FORWARD)
	assert_false(OBSERVER.alignment_is_eligible(backward))
	assert_almost_eq(float(backward.camera_travel_dot), -1.0, 0.00001)
	assert_almost_eq(float(backward.camera_route_dot), -1.0, 0.00001)
	assert_almost_eq(float(backward.travel_route_dot), 1.0, 0.00001)
	var off_route := OBSERVER.alignment_metrics(Vector3.RIGHT, Vector3.RIGHT, Vector3.FORWARD)
	assert_false(OBSERVER.alignment_is_eligible(off_route),
		"camera following a perpendicular detour is not aligned road evidence")

func test_summary_separates_camera_telemetry_from_graded_road_failures() -> void:
	var observer := OBSERVER.new()
	observer._samples = 3
	observer._camera_below_two = 2
	observer._graded_road_samples = 1
	observer._below_two = 1
	observer._unaligned_road_samples = 1
	observer._off_route_samples = 1
	var summary: Dictionary = observer.result()
	assert_eq(summary.samples, 3)
	assert_eq(summary.camera_below_two_samples, 2)
	assert_eq(summary.graded_road_samples, 1)
	assert_eq(summary.below_two_samples, 1)
	assert_eq(summary.unaligned_road_samples, 1)
	assert_eq(summary.off_route_samples, 1)

func test_required_routes_follow_current_static_road_catalogue() -> void:
	var observer := OBSERVER.new()
	var expected := {}
	for row: Dictionary in ROAD._json(ROAD.MEADOWS_TERRAIN).trail.bands:
		expected[str(row.id)] = true
	var actual := {}
	for row: Dictionary in observer._routes("meadows"): actual[str(row.id)] = true
	assert_eq(actual, expected)
	assert_eq(observer._routes("cloudreach").size(), ROAD.CLOUDREACH_MAIN_ROUTE_IDS.size())
	expected.clear()
	var data := ROAD._json(ROAD.WATER_WORLD)
	for group in ["land_routes", "water_routes"]:
		for row: Dictionary in data.get(group, []):
			if bool(row.get("main_path", false)): expected[str(row.id)] = true
	actual.clear()
	for row: Dictionary in observer._routes("water"): actual[str(row.id)] = true
	assert_eq(actual, expected)
	assert_false(observer.result().complete_coverage)
	assert_false(OBSERVER.eligible_body(null))
