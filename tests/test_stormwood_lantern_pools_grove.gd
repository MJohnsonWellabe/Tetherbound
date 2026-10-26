extends "res://tests/test_case.gd"

## The Lantern Pools grove keeps clear of every route, seat and structure,
## and its trunk colliders exist on a simulation shell with nothing drawn.
const POOLS := preload("res://scripts/world/stormwood_lantern_pools.gd")


class FixtureWorld extends Node3D:
	var simulation_only := true

	func ground_height_at(_x: float, _z: float) -> float:
		return 0.0


func _read(path: String) -> Variant:
	return JSON.parse_string(FileAccess.get_file_as_string(path))


func _positions(value: Variant, out: Array[Vector2]) -> void:
	if value is Dictionary:
		for key: String in (value as Dictionary).keys():
			var item: Variant = value[key]
			if key in ["position", "at"] and item is Array and (item as Array).size() in [2, 3] \
					and (item as Array).all(func(n: Variant) -> bool: return n is float or n is int):
				var a := item as Array
				out.append(Vector2(float(a[0]), float(a[a.size() - 1])))
			else:
				_positions(item, out)
	elif value is Array:
		for item: Variant in value:
			_positions(item, out)


func _segment_distance(p: Vector2, a: Vector2, b: Vector2) -> float:
	return p.distance_to(Geometry2D.get_closest_point_to_segment(p, a, b))


func test_grove_keeps_clear_of_routes_seats_and_structures() -> void:
	var cfg: Dictionary = _read(POOLS.CONFIG)
	var trees: Array = (cfg.grove as Dictionary).trees
	assert_true(trees.size() > 40, "the hollow is ringed")
	var routes: Array = (_read("res://data/config/stormwood_world.json") as Dictionary).routes
	var seats: Array[Vector2] = []
	for file: String in ["stormwood_npcs", "stormwood_pickups", "stormwood_trainers", "stormwood_encounters"]:
		_positions(_read("res://data/config/%s.json" % file), seats)
	var structures: Array[Vector2] = []
	for file: String in ["stormwood_arches", "stormwood_camps", "stormwood_settlements"]:
		_positions(_read("res://data/config/%s.json" % file), structures)
	var nearest_route := INF
	var nearest_seat := INF
	var nearest_structure := INF
	var nearest_pool := INF
	for raw: Variant in trees:
		var at := Vector2(float(raw[0]), float(raw[1]))
		for route: Dictionary in routes:
			var points: Array = route.points
			for i in range(1, points.size()):
				nearest_route = minf(nearest_route, _segment_distance(at,
					Vector2(float(points[i - 1][0]), float(points[i - 1][1])), Vector2(float(points[i][0]), float(points[i][1]))))
		for seat in seats:
			nearest_seat = minf(nearest_seat, at.distance_to(seat))
		for spot in structures:
			nearest_structure = minf(nearest_structure, at.distance_to(spot))
		for pool: Dictionary in cfg.pools:
			nearest_pool = minf(nearest_pool, at.distance_to(Vector2(float(pool.at[0]), float(pool.at[1]))) - float(pool.radius_m) * 1.25)
	assert_true(nearest_route >= 11.0, "every tree keeps 11 m from every route (%.1f)" % nearest_route)
	assert_true(nearest_seat >= 7.0, "every tree keeps 7 m from every seat, pickup and cluster (%.1f)" % nearest_seat)
	assert_true(nearest_structure >= 16.0, "every tree keeps 16 m from arches, camps and buildings (%.1f)" % nearest_structure)
	assert_true(nearest_pool >= 4.0, "every tree keeps 4 m beyond each basin (%.1f)" % nearest_pool)


func test_trunk_colliders_are_built_on_a_simulation_shell() -> void:
	var cfg: Dictionary = _read(POOLS.CONFIG)
	var grove: Dictionary = (cfg.grove as Dictionary).duplicate()
	grove.enabled = true
	var world := FixtureWorld.new()
	var root := Node3D.new()
	world.add_child(root)
	POOLS._grove(world, root, grove, true)
	var body := root.get_node("HollowGrove/HollowGroveTrunks") as StaticBody3D
	assert_eq(body.get_child_count(), (grove.trees as Array).size(), "one trunk collider per tree")
	assert_eq(root.get_node("HollowGrove").get_child_count(), 1, "nothing is drawn on a simulation shell")
	world.free()


func test_meshy_lantern_post_replaces_the_box_post_with_a_lit_lantern() -> void:
	var cfg: Dictionary = _read(POOLS.CONFIG)
	var hero: Dictionary = (cfg.lantern_model as Dictionary).duplicate()
	var body := Node3D.new()
	assert_true(POOLS._hero_lantern(body, hero, cfg), "the Meshy lantern post loads")
	var model := body.find_child("LanternPostModel", true, false) as Node3D
	assert_true(model != null, "the post model is seated")
	var light := body.find_child("LanternLight", true, false) as OmniLight3D
	assert_true(light != null, "one warm light hangs at the lantern")
	if light != null:
		assert_true(light.position.y > 1.0 and light.position.y < float(hero.height_m), "the light sits at lantern height, below the post top")
	body.free()
