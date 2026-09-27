extends "res://tests/test_case.gd"

## V-VIS-9 / F10#4: the physical rod line (stormwood_rod_line.gd) stands
## beside the whole critical road, off the road, clear of every settlement,
## arch, camp, rod station, trainer and pocket junction, with cables only
## between neighbouring pylons.
const ROD_LINE := preload("res://scripts/world/stormwood_rod_line.gd")
const WORLD_PATH := "res://data/config/stormwood_world.json"
const TERRAIN_PATH := "res://data/config/terrain_stormwood.json"


func _routes() -> Array:
	return (JSON.parse_string(FileAccess.get_file_as_string(WORLD_PATH)) as Dictionary).routes


func test_pylons_line_every_critical_road() -> void:
	var cfg := ROD_LINE.config()
	var stands := ROD_LINE.layout(cfg, _routes())
	var per_route := {}
	for stand: Dictionary in stands:
		per_route[stand.route] = int(per_route.get(stand.route, 0)) + 1
	for id: Variant in cfg.routes:
		assert_true(int(per_route.get(str(id), 0)) >= 8, "%s carries at least 8 rod pylons (%d)" % [id, int(per_route.get(str(id), 0))])
	var cabled := stands.filter(func(s: Dictionary) -> bool: return bool(s.cable_from_previous))
	assert_true(cabled.size() >= stands.size() * 0.6, "most pylons are strung to the one before (%d of %d)" % [cabled.size(), stands.size()])


func test_pylons_stay_off_the_road_and_clear_of_seats() -> void:
	var cfg := ROD_LINE.config()
	var routes := _routes()
	var half := float((JSON.parse_string(FileAccess.get_file_as_string(TERRAIN_PATH)) as Dictionary).route_half_width)
	var avoid := ROD_LINE.exclusions(cfg, routes)
	assert_true(avoid.size() > 40, "exclusions gathered from every source (%d)" % avoid.size())
	for stand: Dictionary in ROD_LINE.layout(cfg, routes):
		var at: Vector2 = stand.at
		for p: Vector2 in avoid:
			assert_true(p.distance_to(at) >= float(cfg.exclusion_radius_m),
				"pylon at %s clears %s" % [str(at), str(p)])
		for route: Dictionary in routes:
			if str(route.get("kind", "")) == "spur":
				continue
			var pts: Array = route.points
			for i in range(1, pts.size()):
				var a := Vector2(float(pts[i - 1][0]), float(pts[i - 1][1]))
				var b := Vector2(float(pts[i][0]), float(pts[i][1]))
				var closest := Geometry2D.get_closest_point_to_segment(at, a, b)
				assert_true(closest.distance_to(at) > half * 0.9,
					"pylon at %s stands off %s's lane (%.1f m)" % [str(at), str(route.id), closest.distance_to(at)])


func test_cables_only_span_neighbours() -> void:
	var cfg := ROD_LINE.config()
	var stands := ROD_LINE.layout(cfg, _routes())
	for i in range(1, stands.size()):
		if bool(stands[i].cable_from_previous):
			var span := (stands[i].at as Vector2).distance_to(stands[i - 1].at as Vector2)
			assert_true(span <= float(cfg.max_span_m), "cable span %.1f m within max_span_m" % span)
	assert_false(bool(stands[0].cable_from_previous), "the first pylon has no cable behind it")
