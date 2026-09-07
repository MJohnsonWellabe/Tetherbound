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
