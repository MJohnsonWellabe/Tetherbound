extends "res://tests/test_case.gd"

const MODEL := preload("res://tools/gate_f/road_creature_visibility_model.gd")


func test_projection_uses_the_measured_cp2_calibration() -> void:
	assert_almost_eq(MODEL.projected_height_px(1.0, 40.0), 15.0, 0.001)
	assert_almost_eq(MODEL.projected_height_px(2.0, 80.0), 15.0, 0.001)
	assert_almost_eq(MODEL.projected_height_px(0.75, 20.0), 22.5, 0.001)


func test_every_critical_route_has_two_forward_visible_creatures_at_every_sample() -> void:
	var result: Dictionary = MODEL.evaluate_all()
	var expected_route_counts := {
		"meadows": 5,
		"cloudreach": 6,
		"stormwood": 3,
		# Eight main island spines plus both authored choices for seven
		# required crossings. Optional island detours remain outside ROAD.
		"water": 22,
	}
	for realm_id: String in expected_route_counts:
		var routes: Array = result.get(realm_id, [])
		assert_eq(routes.size(), int(expected_route_counts[realm_id]),
			"critical route set changed in %s; update ROAD deliberately" % realm_id)
		for route: Dictionary in result[realm_id]:
			assert_true(int(route["samples"]) > 0, "%s/%s must be sampled" % [realm_id, route["id"]])
			assert_true(int(route["minimum_visible"]) >= MODEL.REQUIRED_VISIBLE,
				"%s/%s drops below two forward-visible bodies" % [realm_id, route["id"]])
			assert_eq(int(route["failing_samples"]), 0,
				"%s/%s has failing 10m samples" % [realm_id, route["id"]])
			assert_almost_eq(float(route["longest_failing_run_m"]), 0.0, 0.001,
				"%s/%s has an empty road run" % [realm_id, route["id"]])
	assert_true(MODEL.all_routes_pass(result))
