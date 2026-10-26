extends "res://tests/test_case.gd"

## r38 Ashfoot exterior: the backdrop grove keeps clear of every route, seat,
## structure and both shelter catalogue cameras, and its trunk colliders exist
## on a simulation shell with nothing drawn.
const EXTERIOR := preload("res://scripts/world/stormwood_ashfoot_exterior.gd")


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


func test_grove_keeps_clear_of_routes_seats_structures_and_cameras() -> void:
	var trees: Array = ((_read(EXTERIOR.CONFIG) as Dictionary).grove as Dictionary).trees
	assert_true(trees.size() >= 20, "the open horizon gets a grove (%d)" % trees.size())
	var routes: Array = (_read("res://data/config/stormwood_world.json") as Dictionary).routes
	var seats: Array[Vector2] = []
	for file: String in ["stormwood_npcs", "stormwood_pickups", "stormwood_trainers", "stormwood_encounters"]:
		_positions(_read("res://data/config/%s.json" % file), seats)
	var structures: Array[Vector2] = [Vector2(-372.78, 452.22), Vector2(-364.58, 459.58)]
	for file: String in ["stormwood_arches", "stormwood_camps", "stormwood_settlements"]:
		_positions(_read("res://data/config/%s.json" % file), structures)
	for raw: Variant in trees:
		var at := Vector2(float(raw[0]), float(raw[1]))
		for route: Dictionary in routes:
			var points: Array = route.points
			for i in range(1, points.size()):
				var a := Vector2(float(points[i - 1][0]), float(points[i - 1][1]))
				var b := Vector2(float(points[i][0]), float(points[i][1]))
				assert_true(at.distance_to(Geometry2D.get_closest_point_to_segment(at, a, b)) >= 11.0, "tree %s keeps 11 m from %s" % [at, route.id])
		for seat in seats:
			assert_true(at.distance_to(seat) >= 7.0, "tree %s keeps 7 m from a seat at %s" % [at, seat])
		for structure in structures:
			assert_true(at.distance_to(structure) >= 16.0, "tree %s keeps 16 m from %s" % [at, structure])


func test_trunk_colliders_are_built_on_a_simulation_shell() -> void:
	var world := FixtureWorld.new()
	var cfg: Dictionary = _read(EXTERIOR.CONFIG)
	var root := Node3D.new()
	world.add_child(root)
	var grove: Dictionary = (cfg.grove as Dictionary).duplicate()
	grove["enabled"] = true
	EXTERIOR.LANTERN_POOLS._grove(world, root, grove, true)
	var body := root.find_child("HollowGroveTrunks", true, false) as StaticBody3D
	assert_true(body != null, "trunk colliders on a simulation shell")
	if body != null:
		assert_eq(body.get_child_count(), (grove.trees as Array).size())
	assert_eq(root.find_children("*", "MeshInstance3D", true, false).size(), 0, "nothing drawn on a simulation shell")
	world.free()
