extends "res://tests/test_case.gd"

const MODEL := preload("res://tools/gate_f/road_creature_visibility_model.gd")


func test_projection_uses_the_measured_cp2_calibration() -> void:
	assert_almost_eq(MODEL.projected_height_px(1.0, 40.0), 15.0, 0.001)
	assert_almost_eq(MODEL.projected_height_px(2.0, 80.0), 15.0, 0.001)
	assert_almost_eq(MODEL.projected_height_px(0.75, 20.0), 22.5, 0.001)


func test_current_authored_road_baseline_is_recorded() -> void:
	var result: Dictionary = MODEL.evaluate_all()
	var expected := {
		"meadows": {
			"band1_lower_meadows": [242, 124, 130.0],
			"band2_stone_and_root": [267, 184, 320.0],
			"band3_the_river_lock": [239, 144, 160.0],
			"band4_upper_meadows_ironwood": [345, 182, 200.0],
			"band5_stronghold_approach": [67, 25, 60.0],
		},
		"cloudreach": {
			"arrival_gate_road": [92, 92, 920.0],
			"lower_cliff_road": [69, 66, 550.0],
			"broken_causeway_main": [187, 187, 1870.0],
			"windscar_floor_loop": [179, 171, 1640.0],
			"windscar_counterweight_pass": [192, 192, 1920.0],
			"upper_summit_road": [155, 155, 1550.0],
		},
		"stormwood": {
			"ash_road": [261, 225, 670.0],
			"conductor_road": [249, 242, 920.0],
			"deepwood_road": [300, 220, 870.0],
		},
	}
	for realm_id: String in expected:
		var actual_by_id := {}
		for route: Dictionary in result[realm_id]:
			actual_by_id[str(route["id"])] = route
		assert_eq(actual_by_id.size(), (expected[realm_id] as Dictionary).size(),
			"route set changed in %s; update the ROAD measurement deliberately" % realm_id)
		for route_id: String in expected[realm_id]:
			assert_true(actual_by_id.has(route_id), "%s/%s must still be sampled" % [realm_id, route_id])
			if not actual_by_id.has(route_id):
				continue
			var route: Dictionary = actual_by_id[route_id]
			var baseline: Array = expected[realm_id][route_id]
			assert_eq(int(route["samples"]), int(baseline[0]), "%s/%s sample count" % [realm_id, route_id])
			assert_eq(int(route["failing_samples"]), int(baseline[1]), "%s/%s failing samples" % [realm_id, route_id])
			assert_almost_eq(float(route["longest_failing_run_m"]), float(baseline[2]), 0.001,
				"%s/%s longest run" % [realm_id, route_id])
	assert_false(MODEL.all_routes_pass(result),
		"this baseline test must be updated to a zero-failure gate when ROAD data lands")
