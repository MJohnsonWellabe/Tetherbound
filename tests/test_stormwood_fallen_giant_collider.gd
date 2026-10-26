extends "res://tests/test_case.gd"

## The Fallen Giant hero blocks on every shell and leaves deepwood_road and
## its roadside encounter passable.
const DRESSING := preload("res://scripts/world/stormwood_destination_dressing.gd")


class FixtureWorld extends Node3D:
	var simulation_only := true

	func ground_height_at(_x: float, _z: float) -> float:
		return 0.0


func test_collider_is_built_headless_and_clears_the_road() -> void:
	var world := FixtureWorld.new()
	var hero: Dictionary = DRESSING._read(DRESSING.CONFIG).fallen_giant.hero
	DRESSING._install_hero(world, hero, false)
	var holder := world.get_node("FallenGiantHero") as Node3D
	var body := holder.get_node_or_null("FallenGiantBody") as StaticBody3D
	assert_true(body != null, "a simulation-only shell builds the collider")
	if body == null:
		world.free()
		return
	assert_eq(body.get_child_count(), (hero.collider_boxes as Array).size())
	assert_eq(holder.get_child_count(), 1, "no model is drawn on a simulation shell")
	var routes: Array = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/stormwood_world.json")).routes
	var points: Array[Vector2] = []
	for route: Dictionary in routes:
		if str(route.id) != "deepwood_road":
			continue
		var line: Array = route.points
		for i in range(1, line.size()):
			var a := Vector2(float(line[i - 1][0]), float(line[i - 1][1]))
			var b := Vector2(float(line[i][0]), float(line[i][1]))
			for k in 401:
				points.append(a.lerp(b, float(k) / 400.0))
	points.append(Vector2(-203.36, 4467.668))
	var nearest := INF
	for shape: CollisionShape3D in body.get_children():
		var size := (shape.shape as BoxShape3D).size
		var pose := holder.transform * shape.transform
		for point in points:
			var local := pose.affine_inverse() * Vector3(point.x, pose.origin.y, point.y)
			nearest = minf(nearest, Vector2(maxf(absf(local.x) - size.x * 0.5, 0.0),
				maxf(absf(local.z) - size.z * 0.5, 0.0)).length())
	assert_true(nearest >= 8.0, "every box keeps 8 m from deepwood_road and its encounter (%.1f m)" % nearest)
	world.free()
