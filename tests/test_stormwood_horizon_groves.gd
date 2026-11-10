extends "res://tests/test_case.gd"

## Stormwood swing part 2 (LANE-MESHY): `groves_1110` visual-only layered
## grove bands round the open stands. OFF until judged.

const GROVES := preload("res://scripts/world/stormwood_horizon_groves.gd")


func _json(path: String) -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string(path))


func _flat(_x: float, _z: float) -> float:
	return 100.0


func _low(_x: float, _z: float) -> float:
	return -200.0


func test_ships_on_and_presentation_scoped() -> void:
	var cfg := GROVES.config()
	assert_true(bool(cfg.get("enabled", false)), "groves_1110 ships ON after its judged gain")
	assert_true(str(cfg.get("_why_on_1110", "")).contains("G-stormwood-groves"), "the judged gain is recorded")
	assert_eq(str(cfg.get("scope", "")), "client_presentation")
	assert_false(bool(cfg.get("casts_shadow", true)), "distant groves cast no shadow")


func test_placements_are_deterministic_and_clear_of_roads_landmarks_and_seats() -> void:
	var cfg := GROVES.config()
	var a := GROVES.placements(cfg, Callable(self, "_flat"))
	var b := GROVES.placements(cfg, Callable(self, "_flat"))
	assert_true(a.size() > 100, "bands plant real groves (%d)" % a.size())
	assert_eq(a.size(), b.size(), "same seed, same groves")
	assert_eq(a[a.size() / 2].at, b[b.size() / 2].at, "same seed, same positions")
	var world := _json("res://data/config/stormwood_world.json")
	var half := float(_json("res://data/config/terrain_stormwood.json").route_half_width)
	var road_clear := half + float(cfg.route_margin_m)
	var bad_road := 0
	var bad_landmark := 0
	var bad_seat := 0
	var seats := preload("res://scripts/world/stormwood_scatter.gd").seats()
	for p: Dictionary in a:
		var at: Vector2 = p.at
		for route: Dictionary in world.routes:
			var pts: Array = route.points
			for i in range(1, pts.size()):
				var s0 := Vector2(float(pts[i - 1][0]), float(pts[i - 1][1]))
				var s1 := Vector2(float(pts[i][0]), float(pts[i][1]))
				if at.distance_to(Geometry2D.get_closest_point_to_segment(at, s0, s1)) < road_clear:
					bad_road += 1
		for landmark: Dictionary in world.landmarks:
			if at.distance_to(Vector2(float(landmark.position[0]), float(landmark.position[2]))) < float(cfg.landmark_margin_m):
				bad_landmark += 1
		for seat: Dictionary in seats:
			if at.distance_to(seat.at) < float(cfg.seat_margin_m):
				bad_seat += 1
	assert_eq(bad_road, 0, "no grove tree on or beside a route")
	assert_eq(bad_landmark, 0, "no grove tree at a landmark")
	assert_eq(bad_seat, 0, "no grove tree on an authored seat")


func test_bands_stay_out_of_the_stand_and_off_low_ground() -> void:
	var cfg := GROVES.config()
	var nearest := INF
	for grove: Dictionary in cfg.groves:
		var centre := Vector2(float(grove.centre[0]), float(grove.centre[1]))
		var single := cfg.duplicate(true)
		single.groves = [grove]
		for p: Dictionary in GROVES.placements(single, Callable(self, "_flat")):
			nearest = minf(nearest, (p.at as Vector2).distance_to(centre))
	assert_true(nearest >= 150.0, "nearest grove tree is 150 m or more from its stand (%.1f)" % nearest)
	assert_eq(GROVES.placements(cfg, Callable(self, "_low")).size(), 0, "crater and sink floors stay bare")
