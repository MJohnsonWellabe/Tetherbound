extends "res://tests/test_case.gd"

const CAPTURE := preload("res://tools/phase2_capture_locations.gd")


func test_respawn_and_stale_camera_are_rejected_instead_of_mislabeled() -> void:
	var stand := Vector2(210.0, 2350.0)
	var respawn := Vector3(0.0, 2.9, 162.0)
	assert_false(CAPTURE.capture_stand_failure(stand, respawn,
		Vector3(208.3, 72.1, 2352.9), 3.5, 8.2).is_empty())
	assert_false(CAPTURE.capture_stand_failure(stand, Vector3(210, 69.6, 2350),
		Vector3(0, 5, 162), 3.5, 8.2).is_empty())
	assert_false(CAPTURE.capture_stand_failure(stand, Vector3(213, 69.6, 2350),
		Vector3(213, 72, 2355), 3.5, 8.2).is_empty())


func test_valid_stand_allows_small_settling_but_rejects_obstruction() -> void:
	var stand := Vector2(210.0, 2350.0)
	var player := Vector3(210.2, 69.6, 2350.1)
	assert_eq(CAPTURE.capture_stand_failure(stand, player,
		Vector3(208.3, 72.1, 2353.5), 3.5, 8.2), "")
	assert_false(CAPTURE.capture_stand_failure(stand, player,
		player + Vector3.UP, 3.5, 8.2).is_empty())
	assert_false(CAPTURE.capture_stand_failure(stand, Vector3.INF,
		Vector3.ZERO, 3.5, 8.2).is_empty())
	# A real collision-shortened arm can remain safely clear of the capsule.
	var lens := player + Vector3(-1.9471245, 2.1638744, 0.0)
	var arm := {"endpoint": lens, "hit_length": 2.0, "requested_length": 5.2, "capsule_clearance": 1.0,
		"probe_radius": 0.25, "near_plane_corner_distances": [0.087, 0.087, 0.087, 0.087]}
	assert_false(CAPTURE.capture_stand_failure(stand, player, lens, 3.5, 8.2).is_empty())
	assert_eq(CAPTURE.capture_stand_failure(stand, player, lens, 3.5, 8.2, arm), "")
	for override: Dictionary in [{"endpoint": lens + Vector3.ONE}, {"hit_length": 0.0},
			{"hit_length": 5.2}, {"capsule_clearance": 0.0}, {"capsule_clearance": NAN},
			{"probe_radius": 0.05}, {"near_plane_corner_distances": [0.087, 0.087, 0.087]},
			{"near_plane_corner_distances": [0.087, 0.087, 0.087, NAN]}]:
		var invalid := arm.duplicate()
		invalid.merge(override, true)
		assert_false(CAPTURE.capture_stand_failure(stand, player, lens, 3.5, 8.2, invalid).is_empty())
	assert_false(CAPTURE.capture_stand_failure(stand, player, lens, 3.5, 2.5, arm).is_empty())
	assert_false(CAPTURE.capture_stand_failure(stand, player + Vector3(3, 0, 0), lens, 3.5, 8.2, arm).is_empty())


func test_historical_brine_swim_drift_is_not_a_valid_stand() -> void:
	var failure := CAPTURE.capture_stand_failure(Vector2(365.228026, 849.813092),
		Vector3(363.246765, -0.700217, 855.006104), Vector3(366.089569, 2.130639, 850.690247), 3.5, 8.2)
	assert_true(failure.contains("5.56m"), "the previous baseline drift must be rejected too")


func test_resolved_land_requires_matching_physical_floor_and_walkable_slope() -> void:
	var limit := deg_to_rad(45.0)
	assert_eq(CAPTURE.capture_floor_failure(10.0,
		{"position": Vector3(1, 10.1, 2), "normal": Vector3.UP}, limit), "")
	assert_false(CAPTURE.capture_floor_failure(10.0, {}, limit).is_empty())
	assert_false(CAPTURE.capture_floor_failure(10.0,
		{"position": Vector3(1, 12, 2), "normal": Vector3.UP}, limit).is_empty())
	assert_false(CAPTURE.capture_floor_failure(10.0,
		{"position": Vector3(1, 10, 2), "normal": Vector3(0.9, 0.2, 0).normalized()}, limit).is_empty())
	assert_false(CAPTURE.capture_floor_failure(10.0,
		{"position": Vector3.INF, "normal": Vector3.UP}, limit).is_empty())


func test_settled_land_needs_live_support_and_current_production_camera() -> void:
	var spec := {"swimming": false}
	var state := {"on_floor": true, "floor_normal_y": 1.0}
	var limit := deg_to_rad(45.0)
	# A non-Water realm needs no swim controller; live floor support suffices.
	assert_eq(CAPTURE.capture_surface_failure(spec, state, 10, limit, true), "")
	assert_false(CAPTURE.capture_surface_failure(spec, state, 10, limit, false).is_empty())
	state.on_floor = false
	assert_false(CAPTURE.capture_surface_failure(spec, state, 10, limit, true).is_empty())
	state.on_floor = true
	state.floor_normal_y = 0.2
	assert_false(CAPTURE.capture_surface_failure(spec, state, 10, limit, true).is_empty())
	state.floor_normal_y = 1.0
	state.dead = true
	assert_false(CAPTURE.capture_surface_failure(spec, state, 10, limit, true).is_empty())


func test_swimming_requires_expected_waterline_mode_and_living_state() -> void:
	var spec := {"swimming": true, "swim_body_y": -0.7}
	var state := {"mode": CAPTURE.SWIM_STATE.Mode.HUMAN, "on_floor": false}
	var limit := deg_to_rad(45.0)
	assert_eq(CAPTURE.capture_surface_failure(spec, state, -0.7, limit, true), "")
	assert_false(CAPTURE.capture_surface_failure(spec, state, -2.245, limit, true).is_empty())
	assert_false(CAPTURE.capture_surface_failure(spec, state, NAN, limit, true).is_empty())
	state.mode = CAPTURE.SWIM_STATE.Mode.LAND
	assert_false(CAPTURE.capture_surface_failure(spec, state, -0.7, limit, true).is_empty())
	state.mode = CAPTURE.SWIM_STATE.Mode.MOUNTED
	assert_false(CAPTURE.capture_surface_failure(spec, state, -0.7, limit, true).is_empty())
	state.mode = CAPTURE.SWIM_STATE.Mode.HUMAN
	state.drowning = true
	assert_false(CAPTURE.capture_surface_failure(spec, state, -0.7, limit, true).is_empty())
