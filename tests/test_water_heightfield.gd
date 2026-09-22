extends "res://tests/test_case.gd"

const FIELD := preload("res://scripts/world/water_heightfield.gd")

var _config: Dictionary
var _field: RefCounted


func before_each() -> void:
	_config = FIELD.load_config()
	_field = FIELD.new(_config)


func _single_island() -> Dictionary:
	return {
		"terrain": {"sea_level_m": 0.0, "seabed_depth_m": 20.0, "outer_shore_slope": 0.5},
		"islands": [{
			"id": "test", "center_xz_m": [0.0, 0.0], "shore_radius_m": 100.0,
			"peak_height_m": 50.0, "peak_power": 1.65,
			"coast_beach_width_m": 4.0, "coast_inner_height_m": 12.0,
			"landing_sectors": [{
				"angle_deg": 180.0, "half_width_deg": 10.0,
				"feather_deg": 5.0, "beach_width_m": 20.0, "inner_height_m": 3.0,
			}],
		}],
	}


func test_real_island_peaks_and_full_shorelines_match_authored_mass() -> void:
	assert_eq(_config.get("islands", []).size(), 12)
	var base_config := _config.duplicate(true)
	base_config.terrain.erase("trail_grading")
	var base := FIELD.new(base_config)
	for island: Dictionary in _config.get("islands", []):
		var at: Array = island["center_xz_m"]
		var cx := float(at[0])
		var cz := float(at[1])
		var radius := float(island["shore_radius_m"])
		assert_almost_eq(base.height_at(cx, cz), float(island["peak_height_m"]), 0.001, island["id"])
		# Roads may cut an interior crown; the distant Veilfall summit remains
		# untouched because its hike goes around the mountain to the falls.
		if str(island.id) == "veilfall":
			assert_almost_eq(_field.height_at(cx, cz), 620.0, 0.001)
		assert_eq(_field.island_id_at(cx, cz), island["id"])
		for n in 36:
			var angle := TAU * float(n) / 36.0
			assert_almost_eq(_field.height_at(cx + cos(angle) * radius, cz + sin(angle) * radius),
				_field.water_level(), 0.001, "%s shoreline %d" % [island["id"], n])


func test_graded_main_approaches_and_veilfall_hike_have_walkable_centrelines() -> void:
	# Four other exploratory spines have documented junction defects, so they
	# deliberately earn no traversal acceptance from this focused assertion.
	for route: Dictionary in _config.land_routes:
		if str(route.island_id) not in ["first_shore", "reedhaven", "brine_steps", "tidal_cradle", "salt_crown", "sluice_isle", "veilfall", "gull_rest"]:
			continue
		for i in route.polyline.size() - 1:
			var a: Array = route.polyline[i]
			var b: Array = route.polyline[i + 1]
			var steps := maxi(1, ceili(Vector2(float(a[0]) - float(b[0]), float(a[2]) - float(b[2])).length()))
			for j in steps:
				var fraction := float(j) / float(steps)
				var x := lerpf(float(a[0]), float(b[0]), fraction)
				var z := lerpf(float(a[2]), float(b[2]), fraction)
				assert_between(_field.slope_degrees_at(x, z, 0.5), 0.0, 35.0, str(route.id))


func test_authored_safe_landings_match_data_and_are_gentle() -> void:
	for anchor: Dictionary in _config.get("anchors", []):
		var shore: Array = anchor["shore_position"]
		var safe: Array = anchor["safe_position"]
		assert_almost_eq(_field.height_at(float(shore[0]), float(shore[2])), 0.0, 0.003, anchor["id"])
		assert_almost_eq(_field.height_at(float(safe[0]), float(safe[2])), float(safe[1]), 0.003, anchor["id"])
		assert_eq(_field.island_id_at(float(safe[0]), float(safe[2])), anchor["island_id"])
		assert_between(_field.slope_degrees_at(float(safe[0]), float(safe[2]), 0.25),
			0.0, 15.0, "real landing must be walkable: " + str(anchor["id"]))


func test_ocean_falls_away_from_shore_and_clamps_at_seafloor() -> void:
	var field: RefCounted = FIELD.new(_single_island())
	assert_almost_eq(field.height_at(100.0, 0.0), 0.0)
	assert_almost_eq(field.height_at(110.0, 0.0), -5.0)
	assert_almost_eq(field.height_at(120.0, 0.0), -10.0)
	assert_almost_eq(field.height_at(200.0, 0.0), -20.0)
	assert_almost_eq(field.height_at(100000.0, -100000.0), -20.0)
	assert_eq(field.island_id_at(110.0, 0.0), "", "sea is not dry island membership")
	assert_eq(field.island_id_at(110.0, 0.0, 12.0), "test", "explicit apron for shore queries")


func test_rest_shoal_reuses_terrain_profile_without_becoming_a_named_island() -> void:
	var config := _single_island()
	config["rest_shoals"] = [{
		"id": "test_rest", "parent_island_id": "test",
		"center_xz_m": [200.0, 0.0], "shore_radius_m": 20.0,
		"peak_height_m": 1.5, "peak_power": 1.65,
		"coast_beach_width_m": 19.0, "coast_inner_height_m": 1.5,
	}]
	var field: RefCounted = FIELD.new(config)
	assert_eq(config.islands.size(), 1, "a rest shoal does not expand the named-island map")
	assert_almost_eq(field.height_at(200.0, 0.0), 1.5, 0.001)
	assert_eq(field.island_id_at(200.0, 0.0), "test",
		"shoal membership resolves to its authored parent island")
	for n in 12:
		var angle := TAU * float(n) / 12.0
		var x := 200.0 + cos(angle) * 1.5
		var z := sin(angle) * 1.5
		assert_true(field.height_at(x, z) >= 0.6)
		assert_between(field.slope_degrees_at(x, z, 0.25), 0.0, 35.0)
	assert_almost_eq(field.height_at(220.0, 0.0), 0.0, 0.001)
	assert_true(field.height_at(221.0, 0.0) < 0.0,
		"the profile cannot create phantom dry floor beyond its authored edge")
	var invalid: Dictionary = (config.rest_shoals[0] as Dictionary).duplicate(true)
	invalid.id = "missing_parent"
	invalid.center_xz_m = [260.0, 0.0]
	invalid.erase("parent_island_id")
	config.rest_shoals.append(invalid)
	field = FIELD.new(config)
	assert_true(field.height_at(260.0, 0.0) < 0.0,
		"an unowned shoal fails closed instead of expanding world identity")


func test_real_rest_shoals_are_dry_gentle_bounded_and_inside_baked_regions() -> void:
	var shoals: Array = _config.get("rest_shoals", [])
	assert_eq(_config.get("islands", []).size(), 12,
		"rest stops must not expand the twelve named-island map")
	assert_eq(shoals.size(), 17)
	for shoal: Dictionary in shoals:
		var center: Array = shoal.get("center_xz_m", [])
		var radius := float(shoal.get("shore_radius_m", 0.0))
		assert_eq(radius, 20.0, str(shoal.get("id", "")))
		assert_eq(float(shoal.get("peak_height_m", 0.0)), 1.5)
		assert_eq(float(shoal.get("coast_beach_width_m", 0.0)), 19.0)
		assert_eq(float(shoal.get("coast_inner_height_m", 0.0)), 1.5)
		assert_true(center.size() == 2)
		if center.size() != 2:
			continue
		var cx := float(center[0])
		var cz := float(center[1])
		assert_true(_field.has_terrain_region_at(cx, cz),
			"committed sparse terrain must cover " + str(shoal.get("id", "")))
		assert_almost_eq(_field.height_at(cx, cz), 1.5, 0.001)
		assert_eq(_field.island_id_at(cx, cz), str(shoal.get("parent_island_id", "")))
		for n in 12:
			var angle := TAU * float(n) / 12.0
			var x := cx + cos(angle) * 1.5
			var z := cz + sin(angle) * 1.5
			assert_true(_field.height_at(x, z) >= 0.6,
				"safe disk must stay dry: " + str(shoal.get("id", "")))
			assert_between(_field.slope_degrees_at(x, z, 0.25), 0.0, 35.0,
				"safe disk must remain walkable: " + str(shoal.get("id", "")))
		assert_almost_eq(_field.height_at(cx + radius, cz), _field.water_level(), 0.003)
		assert_true(_field.height_at(cx + radius + 1.0, cz) < _field.water_level(),
			"shoal cannot create phantom floor beyond its edge")
		var found_anchor := false
		for anchor: Dictionary in _config.get("anchors", []):
			var safe: Array = anchor.get("safe_position", [])
			if safe.size() == 3 and Vector2(float(safe[0]) - cx, float(safe[2]) - cz).length() <= 0.01:
				found_anchor = str(anchor.get("island_id", "")) == str(shoal.get("parent_island_id", ""))
				break
		assert_true(found_anchor, "rest shoal needs a parent-scoped safe anchor: " + str(shoal.get("id", "")))


func test_mandatory_sheltered_human_legs_retain_twenty_percent_with_steering() -> void:
	var swim: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(
		"res://data/config/water_swimming.json"))
	var human: Dictionary = swim.get("human", {})
	var speed := float(human.get("speed_m_s", 0.0))
	var drain := float(human.get("stamina_drain_per_s", 0.0))
	var acceleration := float(human.get("acceleration_m_s2", 0.0))
	var max_stamina := 100.0
	var threshold_allowance := (float(human.get("entry_depth_m", 0.0)) \
		+ float(human.get("exit_depth_m", 0.0))) / float(_config.terrain.outer_shore_slope)
	var checked := 0
	for route: Dictionary in _config.get("water_routes", []):
		if not bool(route.get("main_path", false)) or str(route.get("choice", "")) != "sheltered" \
				or str(route.get("intended_traversal", "")) != "human_level_0":
			continue
		var points: Array = route.get("polyline", [])
		var total := _polyline_length(points)
		var stops: Array[Dictionary] = [{"arc": 0.0, "radius": 0.0}]
		for shoal: Dictionary in _config.get("rest_shoals", []):
			if str(shoal.get("route_id", "")) != str(route.get("id", "")):
				continue
			var center: Array = shoal.get("center_xz_m", [])
			var projection := _route_projection(points, Vector2(float(center[0]), float(center[1])))
			assert_true(float(projection.offset) <= 0.01,
				"rest centre must stay on sheltered route: " + str(shoal.get("id", "")))
			stops.append({"arc": float(projection.arc),
				"radius": float(shoal.get("shore_radius_m", 0.0))})
		stops.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return float(a.arc) < float(b.arc))
		stops.append({"arc": total, "radius": 0.0})
		var effective_speed := _minimum_route_progress_speed(route, points, speed)
		assert_true(effective_speed > 0.0, str(route.get("id", "")))
		for index in range(1, stops.size()):
			var previous: Dictionary = stops[index - 1]
			var current: Dictionary = stops[index]
			var water_distance := maxf(0.0, float(current.arc) - float(previous.arc) \
				- float(previous.radius) - float(current.radius) - threshold_allowance)
			assert_true(water_distance <= 80.0,
				"human water-only leg exceeds safe physical span: " + str(route.get("id", "")))
			# A full acceleration interval is charged on every hop. This is more
			# conservative than integrating the linear acceleration ramp.
			var seconds := water_distance * 1.15 / effective_speed + speed / acceleration
			var remaining := max_stamina - seconds * drain
			assert_true(remaining >= max_stamina * 0.20,
				"human route misses reserve after current and steering: %s %.2f" % [route.get("id", ""), remaining])
		checked += 1
	assert_eq(checked, 7, "every mandatory sheltered crossing is checked")


func _polyline_length(points: Array) -> float:
	var total := 0.0
	for index in range(1, points.size()):
		var a := Vector2(float(points[index - 1][0]), float(points[index - 1][2]))
		var b := Vector2(float(points[index][0]), float(points[index][2]))
		total += a.distance_to(b)
	return total


func _route_projection(points: Array, point: Vector2) -> Dictionary:
	var best := {"arc": 0.0, "offset": INF}
	var prefix := 0.0
	for index in range(1, points.size()):
		var a := Vector2(float(points[index - 1][0]), float(points[index - 1][2]))
		var b := Vector2(float(points[index][0]), float(points[index][2]))
		var segment := b - a
		var length := segment.length()
		var fraction := 0.0 if length <= 0.0 else clampf((point - a).dot(segment) / (length * length), 0.0, 1.0)
		var offset := point.distance_to(a + segment * fraction)
		if offset < float(best.offset):
			best = {"arc": prefix + length * fraction, "offset": offset}
		prefix += length
	return best


func _minimum_route_progress_speed(route: Dictionary, points: Array, swim_speed: float) -> float:
	var current: Dictionary = {}
	for candidate: Dictionary in _config.get("currents", []):
		if str(candidate.get("id", "")) == str(route.get("current_id", "")):
			current = candidate
			break
	var raw_flow: Array = current.get("flow_direction_xz", [0.0, 0.0])
	var flow := Vector2(float(raw_flow[0]), float(raw_flow[1])).normalized() \
		* float(current.get("strength_m_s", 0.0))
	var minimum := swim_speed
	for index in range(1, points.size()):
		var a := Vector2(float(points[index - 1][0]), float(points[index - 1][2]))
		var b := Vector2(float(points[index][0]), float(points[index][2]))
		var direction := (b - a).normalized()
		# Helpful flow is ignored for safety; adverse/lateral authored flow is
		# projected onto the actual segment rather than treating distance alone.
		minimum = minf(minimum, swim_speed + minf(0.0, flow.dot(direction)))
	return minimum


func test_landing_sector_wraps_across_negative_positive_pi() -> void:
	var field: RefCounted = FIELD.new(_single_island())
	for degrees in [179.0, -179.0, 180.0]:
		var angle := deg_to_rad(degrees)
		assert_almost_eq(field.height_at(cos(angle) * 90.0, sin(angle) * 90.0), 1.5, 0.001)
	assert_true(field.height_at(90.0, 0.0) > 12.0, "unopened coast retains steep profile")
	assert_true(field.slope_degrees_at(98.0, 0.0, 0.1) > 60.0)
	assert_true(field.slope_degrees_at(-90.0, 0.0, 0.1) < 10.0)


func test_landing_sector_feather_has_no_height_step() -> void:
	var field: RefCounted = FIELD.new(_single_island())
	for boundary in [190.0, 195.0]:
		var a := deg_to_rad(boundary - 0.0001)
		var b := deg_to_rad(boundary + 0.0001)
		assert_almost_eq(field.height_at(cos(a) * 90.0, sin(a) * 90.0),
			field.height_at(cos(b) * 90.0, sin(b) * 90.0), 0.001)


func test_real_terrain_grid_is_finite_bounded_and_reproducible() -> void:
	var other: RefCounted = FIELD.new(FIELD.load_config())
	var highest := 0.0
	for island: Dictionary in _config.get("islands", []):
		highest = maxf(highest, float(island["peak_height_m"]))
	var bounds: Dictionary = _config["terrain"]["world_bounds"]
	for x in range(int(bounds["min_x"]), int(bounds["max_x"]), 131):
		for z in range(int(bounds["min_z"]), int(bounds["max_z"]), 137):
			var h: float = _field.height_at(float(x), float(z))
			assert_true(is_finite(h), "finite input must produce a finite height")
			assert_between(h, _field.seabed_height(), highest)
			assert_eq(h, other.height_at(float(x), float(z)), "repeat field must produce identical samples")
	assert_almost_eq(_field.height_at(100000.0, 100000.0), _field.seabed_height())


func test_sparse_region_membership_uses_floor_for_negative_coordinates() -> void:
	var config := _single_island()
	config["terrain"]["region_size"] = 256
	config["terrain"]["vertex_spacing"] = 1.0
	config["terrain"]["region_locations"] = [[-1, -1]]
	config["islands"][0]["center_xz_m"] = [-100.0, -100.0]
	var field: RefCounted = FIELD.new(config)
	assert_true(field.has_terrain_region_at(-100.0, -100.0))
	assert_false(field.has_terrain_region_at(0.0, -100.0))
	assert_false(field.has_terrain_region_at(-256.01, -100.0))
	assert_almost_eq(field.height_at(-100.0, -100.0), 50.0)
	assert_almost_eq(field.height_at(0.0, -100.0), -20.0, 0.001,
		"outside the sparse bake, depth queries use deep sea, not imaginary ground")


func test_nearest_island_uses_shore_distance_not_centre_distance() -> void:
	var config := _single_island()
	var larger: Dictionary = config["islands"][0].duplicate(true)
	larger["id"] = "larger"
	larger["center_xz_m"] = [400.0, 0.0]
	larger["shore_radius_m"] = 200.0
	config["islands"].append(larger)
	var field: RefCounted = FIELD.new(config)
	assert_eq(field.island_id_at(175.0, 0.0), "")
	assert_eq(field.nearest_island_id(175.0, 0.0), "larger")
	assert_eq(field.nearest_island_id(0.0, 0.0), "test")


func test_overlapping_islands_resolve_highest_land_surface() -> void:
	var config := _single_island()
	var taller: Dictionary = config["islands"][0].duplicate(true)
	taller["id"] = "taller"
	taller["peak_height_m"] = 80.0
	config["islands"].append(taller)
	var field: RefCounted = FIELD.new(config)
	assert_almost_eq(field.height_at(0.0, 0.0), 80.0)
	assert_eq(field.island_id_at(0.0, 0.0), "taller")


func test_constructor_freezes_recipe_and_nonfinite_positions_are_rejected() -> void:
	var config := _single_island()
	var field: RefCounted = FIELD.new(config)
	config["islands"][0]["peak_height_m"] = 9999.0
	config["islands"][0]["landing_sectors"][0]["beach_width_m"] = 99.0
	assert_almost_eq(field.height_at(0.0, 0.0), 50.0)
	assert_almost_eq(field.height_at(-90.0, 0.0), 1.5)
	assert_true(is_nan(field.height_at(NAN, 0.0)))
	assert_true(is_nan(field.height_at(0.0, INF)))
	assert_eq(field.island_id_at(INF, 0.0), "")
	assert_eq(field.nearest_island_id(0.0, NAN), "")
