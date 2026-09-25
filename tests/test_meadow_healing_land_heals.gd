extends "res://tests/test_case.gd"

# F05, owner decision "the land heals": the pure parts of the three finale
# effects in `scripts/world/meadow_healing.gd` -- (A) the regreen's station
# falloff and alpha, (C) the pylon topple transform, its fall angle and its
# idempotence, (B) the deterministic returning-herd placement. The live world
# half (built over the production Meadows, and re-derived after a real
# save/load) is `tests/smoke_meadow_healing_land_heals.gd`.

const HEALING := preload("res://scripts/world/meadow_healing.gd")
const CONFIG_PATH := "res://data/config/meadow_healing.json"
const TERRAIN_PATH := "res://data/config/terrain_playground.json"


func _json(path: String) -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return parsed as Dictionary if parsed is Dictionary else {}


func _config() -> Dictionary:
	return _json(CONFIG_PATH)


# --- (A) regreen ---------------------------------------------------------------

func test_station_falloff_is_full_in_the_core_and_zero_at_the_rim() -> void:
	assert_almost_eq(HEALING.station_falloff(0.0, 8.0, 24.0, 0.85), 0.85, 0.0001, "centre = strength")
	assert_almost_eq(HEALING.station_falloff(8.0, 8.0, 24.0, 0.85), 0.85, 0.0001, "inner edge = strength")
	assert_almost_eq(HEALING.station_falloff(16.0, 8.0, 24.0, 1.0), 0.5, 0.0001, "smoothstep midpoint")
	assert_eq(HEALING.station_falloff(24.0, 8.0, 24.0, 1.0), 0.0, "rim = 0")
	assert_eq(HEALING.station_falloff(40.0, 8.0, 24.0, 1.0), 0.0, "outside = 0")
	assert_eq(HEALING.station_falloff(1.0, 0.0, 0.0, 1.0), 0.0, "a zero-radius station paints nothing")


func test_station_falloff_matches_the_heightfield_drain_factor() -> void:
	# The regreen must green exactly the contour `drain_factor()` browned. With
	# only one station in range, the two formulas must agree.
	var drains: Dictionary = _json(TERRAIN_PATH).get("drains", {})
	var station: Dictionary = {}
	for raw: Variant in (drains.get("stations", []) as Array):
		if str((raw as Dictionary).get("id", "")) == "stronghold_works":
			station = raw
	assert_false(station.is_empty(), "terrain_playground.json still has stronghold_works")
	if station.is_empty():
		return
	var field: RefCounted = preload("res://scripts/world/playground_heightfield.gd").new()
	var centre := Vector2(float(station["centre"][0]), float(station["centre"][1]))
	var global_strength := clampf(float(drains.get("strength", 1.0)), 0.0, 1.0)
	for d: float in [0.0, 10.0, 25.0, 33.0, 41.0]:
		var spot := centre + Vector2(d, 0.0)
		var expected := float(field.call("drain_factor", spot.x, spot.y))
		var mine := HEALING.station_falloff(d, float(station["inner"]), float(station["radius"]),
			float(station["strength"])) * global_strength
		assert_almost_eq(mine, expected, 0.0001, "d=%.0f" % d)


func test_regreen_alpha_takes_the_worst_station_and_spares_roads() -> void:
	var discs: Array = [
		{"centre": Vector2(0, 0), "radius": 20.0, "inner": 5.0, "strength": 0.5},
		{"centre": Vector2(10, 0), "radius": 20.0, "inner": 5.0, "strength": 1.0},
	]
	var at := Vector2(10, 0)
	assert_almost_eq(HEALING.regreen_alpha(at, discs, 1.0, 0.7, 0.0), 0.7, 0.0001, "worst station, times max_alpha")
	assert_almost_eq(HEALING.regreen_alpha(at, discs, 0.5, 0.7, 0.0), 0.35, 0.0001, "global drain strength scales it")
	assert_almost_eq(HEALING.regreen_alpha(at, discs, 1.0, 0.7, 1.0), 0.0, 0.0001, "a road stays a road")
	assert_almost_eq(HEALING.regreen_alpha(at, discs, 1.0, 0.7, 0.5), 0.35, 0.0001)
	assert_eq(HEALING.regreen_alpha(Vector2(500, 500), discs, 1.0, 0.7, 0.0), 0.0, "far away")


func test_overlapping_discs_share_one_world_aligned_grid() -> void:
	var one: Array = [{"centre": Vector2(0, 0), "radius": 9.0}]
	var both: Array = [{"centre": Vector2(0, 0), "radius": 9.0}, {"centre": Vector2(3, 0), "radius": 9.0}]
	var cells_one := HEALING.regreen_cells(one, 3.0)
	var cells_both := HEALING.regreen_cells(both, 3.0)
	assert_eq(cells_one.size(), 36, "a 9 m disc on a 3 m grid is a 6x6 block")
	assert_eq(cells_both.size(), 42, "the overlap is drawn once: 6x6 plus one new column")
	var seen: Dictionary = {}
	for key: Vector2i in cells_both:
		assert_false(seen.has(key), "no duplicate cell %s" % str(key))
		seen[key] = true


func test_regreen_config_names_real_baked_stations_and_installed_textures() -> void:
	var block: Dictionary = _config().get("regreen", {})
	assert_true(bool(block.get("enabled", false)))
	var ids: Dictionary = {}
	for raw: Variant in ((_json(TERRAIN_PATH).get("drains", {}) as Dictionary).get("stations", []) as Array):
		ids[str((raw as Dictionary).get("id", ""))] = true
	var stations: Array = block.get("stations", [])
	assert_eq(stations.size(), 12)
	for raw: Variant in stations:
		assert_true(ids.has(str(raw)), "station '%s' exists" % str(raw))
		assert_false(str(raw).begins_with("relay_"), "the relay heals its own skin at the console")
	assert_true(ResourceLoader.exists(str(block.get("albedo", ""))), "installed grass albedo")
	assert_true(ResourceLoader.exists(str(block.get("normal", ""))), "installed grass normal")
	assert_almost_eq(float(block.get("fade_seconds", 0.0)),
		float((_config().get("dead_ground", {}) as Dictionary).get("fade_seconds", -1.0)), 0.001,
		"the regreen crossfades with the dark skins over the same seconds")
	assert_true(float(block.get("lift", 0.0)) > 0.09, "above the 0.09 dead-ground skins")


# --- (C) pylons ----------------------------------------------------------------

func test_topple_tips_up_toward_the_fall_direction_about_the_pivot() -> void:
	var start := Transform3D(Basis.IDENTITY, Vector3(10, 3, 20))
	var pivot := Vector3(10.85, 0, 20)
	var fallen := HEALING.topple_transform(start, pivot, Vector2(1, 0), deg_to_rad(90.0))
	assert_true(fallen.basis.y.is_equal_approx(Vector3(1, 0, 0)), "up now points along +X, got %s" % str(fallen.basis.y))
	# The centre, 3 m above a pivot 0.85 m away, swings to 3 m out along X and
	# 0.85 m up.
	assert_true(fallen.origin.is_equal_approx(Vector3(13.85, 0.85, 20)), "origin %s" % str(fallen.origin))
	# The pivot itself is a fixed point of the rotation.
	var pivot_local := start.affine_inverse() * pivot
	assert_true((fallen * pivot_local).is_equal_approx(pivot), "pivot stays put")
	var z_fall := HEALING.topple_transform(start, Vector3(10, 0, 19), Vector2(0, -1), deg_to_rad(90.0))
	assert_true(z_fall.basis.y.is_equal_approx(Vector3(0, 0, -1)), "falls toward -Z when asked")


func test_topple_keeps_scale_and_zero_angle_is_identity() -> void:
	var start := Transform3D(Basis(Vector3.UP, 0.7).scaled(Vector3.ONE * 2.5), Vector3(1, 2, 3))
	var same := HEALING.topple_transform(start, Vector3(1, 0, 3), Vector2(0.6, 0.8), 0.0)
	assert_true(same.is_equal_approx(start), "zero angle moves nothing")
	var fallen := HEALING.topple_transform(start, Vector3(1, 0, 3), Vector2(0.6, 0.8), 1.2)
	assert_almost_eq(fallen.basis.get_scale().x, 2.5, 0.001, "uniform fit scale survives")


func test_fall_angle_follows_the_ground() -> void:
	assert_almost_eq(HEALING.fall_angle_deg(10.0, 0.0, 0.0, 3.0, 70.0, 108.0), 93.0, 0.001, "level: 90 + sink")
	assert_true(HEALING.fall_angle_deg(10.0, 0.0, 3.0, 3.0, 70.0, 108.0) < 90.0, "rising ground stops it early")
	assert_true(HEALING.fall_angle_deg(10.0, 0.0, -3.0, 3.0, 70.0, 108.0) > 93.0, "falling ground lets it go further")
	assert_almost_eq(HEALING.fall_angle_deg(10.0, 0.0, 50.0, 3.0, 70.0, 108.0), 70.0, 0.001, "clamped")
	assert_almost_eq(HEALING.fall_angle_deg(10.0, NAN, 1.0, 3.0, 70.0, 108.0), 93.0, 0.001, "no ground = level")


func test_fall_direction_is_deterministic_and_unit() -> void:
	var a := HEALING.fall_direction("ApproachConduits/Pylon_3")
	var b := HEALING.fall_direction("ApproachConduits/Pylon_3")
	assert_true(a.is_equal_approx(b), "same key, same direction on every peer")
	assert_almost_eq(a.length(), 1.0, 0.0001)
	var other := HEALING.fall_direction("ApproachConduits/Pylon_4")
	assert_false(a.is_equal_approx(other), "neighbours do not all fall the same way")
	var turned := HEALING.fall_direction("ApproachConduits/Pylon_3", 2, 8)
	assert_almost_eq(a.angle_to(turned), -PI * 0.5, 0.0001, "candidate 2 of 8 is a quarter turn round")


func test_a_fallen_pylon_is_never_toppled_twice_and_its_collider_goes_down_with_it() -> void:
	var healing: Node3D = HEALING.new()
	var holder := Node3D.new()
	holder.name = "ApproachConduits"
	var pylon := MeshInstance3D.new()
	pylon.name = "Pylon_0"
	var box := BoxMesh.new()
	box.size = Vector3(1.7, 6.0, 1.7)
	pylon.mesh = box
	pylon.transform = Transform3D(Basis.IDENTITY, Vector3(100, 3, 200))
	holder.add_child(pylon)
	var collider := StaticBody3D.new()
	collider.name = "Collision"
	collider.transform = Transform3D(Basis.IDENTITY, Vector3(100, 2.1, 200))
	var shape := CollisionShape3D.new()
	collider.add_child(shape)
	holder.add_child(collider)
	var block: Dictionary = (_config().get("pylons", {}) as Dictionary).duplicate()

	assert_true(bool(healing.call("_topple_one", pylon, holder, block, 0.0, 0.0)), "first topple happens")
	var once := pylon.transform
	assert_true(once.basis.y.dot(Vector3.UP) < 0.35, "it is lying down (up.y = %.2f)" % once.basis.y.dot(Vector3.UP))
	assert_true(collider.transform.basis.y.dot(Vector3.UP) < 0.35, "its collider is lying down too")
	assert_false(shape.disabled, "and collides again once down")
	var collider_once := collider.transform
	assert_false(bool(healing.call("_topple_one", pylon, holder, block, 0.0, 0.0)), "second topple refused")
	assert_true(pylon.transform.is_equal_approx(once), "an already-fallen pylon is not rotated again")
	assert_true(collider.transform.is_equal_approx(collider_once), "nor is its collider")
	holder.free()
	healing.free()


func test_the_severed_spokes_stay_standing() -> void:
	var block: Dictionary = _config().get("pylons", {})
	var holders: Array = block.get("holders", [])
	for spoke: String in ["Spoke_north", "Spoke_west", "SeveredSpokes"]:
		for raw: Variant in holders:
			assert_false(spoke.match(str(raw)), "'%s' matched '%s'" % [spoke, str(raw)])
	for live: String in ["TetherConduits", "Conduits_north", "ApproachConduits"]:
		var any := false
		for raw: Variant in holders:
			any = any or live.match(str(raw))
		assert_true(any, "'%s' falls" % live)


# --- (B) the herd ------------------------------------------------------------

func test_herd_placement_is_deterministic_spaced_and_clear_of_the_veridian() -> void:
	var config := _config()
	var block: Dictionary = config.get("herd_return", {})
	var display: Dictionary = config.get("herd_display", {})
	var site := Vector2(float(display["at"][0]), float(display["at"][1]))
	var places := HEALING.herd_placements(block)
	assert_true(places.size() >= 6 and places.size() <= 8, "6-8 animals, got %d" % places.size())
	assert_eq(str(block.get("species", "")), "meadowhart")
	var again := HEALING.herd_placements(block)
	var clear := float(block.get("keep_clear_of_display_m", 8.0))
	for i in places.size():
		var at: Vector2 = places[i]["at"]
		assert_true(at.is_equal_approx(again[i]["at"] as Vector2), "same spot every build")
		assert_true(at.distance_to(site) >= clear, "member %d is %.1f m from the Veridian site" % [i, at.distance_to(site)])
		assert_true(at.distance_to(Vector2(400, 5900)) <= 65.0, "member %d stands on the Highfield" % i)
		for j in range(i + 1, places.size()):
			assert_true(at.distance_to(places[j]["at"] as Vector2) >= 4.0, "members %d/%d do not overlap" % [i, j])


func test_herd_placement_skips_malformed_entries() -> void:
	var places := HEALING.herd_placements({"members": [[1.0, 2.0, 30.0], [5.0], "x", [3.0, 4.0]]})
	assert_eq(places.size(), 2)
	assert_almost_eq(float(places[0]["facing_deg"]), 30.0)
	assert_almost_eq(float(places[1]["facing_deg"]), 0.0)
