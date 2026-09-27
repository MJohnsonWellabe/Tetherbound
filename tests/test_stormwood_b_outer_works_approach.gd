extends "res://tests/test_case.gd"

## F09#1 relay blocker B2: the Outer Works approach floated up to 6.2 m over
## the ground with an open underside a player walked into and wedged, and
## Officer Kestrel's NPC and trainer seats stood inside its footprint. The
## approach is now a closed causeway whose foot is 14 m east of the rod
## station, clear of both seats.

const WORLD := preload("res://scripts/world/stormwood_world.gd")
const TREE := preload("res://scripts/world/stormheart_tree.gd")
const FIELD := preload("res://scripts/world/stormwood_heightfield.gd")


func _line() -> Dictionary:
	var field := FIELD.new()
	var base := Vector3(-100.0, field.height_at(-100.0, 5470.0), 5470.0)
	var foot: Vector2 = WORLD.APPROACH_FOOT
	var start := Vector3(foot.x, field.height_at(foot.x, foot.y) + 0.2, foot.y)
	var ex := foot.x - base.x
	var end := base + Vector3(ex, 6.0, -sqrt(TREE.OUTER_WORKS_OUTER_RADIUS * TREE.OUTER_WORKS_OUTER_RADIUS - ex * ex))
	return {"field": field, "start": start, "end": end, "base": base}


func _seat(path: String, id: String) -> Vector2:
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	var found := [Vector2.INF]
	var walk := func(node: Variant, recurse: Callable) -> void:
		if node is Dictionary:
			if str((node as Dictionary).get("id", "")) == id and (node as Dictionary).has("position"):
				var p: Array = node.position
				found[0] = Vector2(float(p[0]), float(p[-1]))
			for value: Variant in (node as Dictionary).values():
				recurse.call(value, recurse)
		elif node is Array:
			for value: Variant in node:
				recurse.call(value, recurse)
	walk.call(data, walk)
	return found[0]


func test_the_causeway_meets_the_ring_edge_and_never_dips_below_the_ground() -> void:
	var line := _line()
	var end: Vector3 = line.end
	var base: Vector3 = line.base
	assert_almost_eq(Vector2(end.x - base.x, end.z - base.z).length(), TREE.OUTER_WORKS_OUTER_RADIUS, 0.01,
		"the causeway ends on the deck's outer edge")
	var field: RefCounted = line.field
	var start: Vector3 = line.start
	var half := TREE.APPROACH_WIDTH * 0.5
	var deepest := 0.0
	for i in 41:
		var p := start.lerp(end, float(i) / 40.0)
		for off in [-half, 0.0, half]:
			var ground: float = field.height_at(p.x + off, p.z)
			assert_true(p.y >= ground - 0.1, "the deck of the causeway is never below the ground (z %.0f)" % p.z)
			deepest = maxf(deepest, p.y - ground)
	assert_true(TREE.APPROACH_SKIRT_DEPTH > deepest + 0.5,
		"its closed sides reach below the ground everywhere (%.2f m gap, %.1f m sides)" % [deepest, TREE.APPROACH_SKIRT_DEPTH])


func test_kestrels_seats_are_outside_the_causeway() -> void:
	var line := _line()
	var a := Vector2((line.start as Vector3).x, (line.start as Vector3).z)
	var b := Vector2((line.end as Vector3).x, (line.end as Vector3).z)
	var clear := TREE.APPROACH_WIDTH * 0.5 + 2.0
	for seat: Vector2 in [_seat("res://data/config/stormwood_npcs.json", "officer_kestrel"),
			_seat("res://data/config/stormwood_trainers.json", "officer_kestrel_outer_works")]:
		assert_true(seat != Vector2.INF, "Kestrel's seat is authored")
		var t := clampf((seat - a).dot(b - a) / (b - a).length_squared(), 0.0, 1.0)
		var d := seat.distance_to(a.lerp(b, t))
		assert_true(d > clear, "Kestrel's seat %s is %.1f m from the causeway's centre line (clear > %.1f)" % [str(seat), d, clear])


func test_the_causeway_is_closed_underneath() -> void:
	var tree: Node3D = TREE.new()
	tree.simulation_only = true
	var line := _line()
	tree.add_approach(line.start as Vector3, (line.end as Vector3) - (line.base as Vector3))
	var skirt := tree.get_node_or_null(^"OuterWorksApproachSkirt") as StaticBody3D
	assert_true(skirt != null, "the approach has closed sides")
	var shape := (skirt.get_child(0) as CollisionShape3D).shape as ConcavePolygonShape3D
	assert_true(shape.backface_collision, "its sides stop a body from either side")
	assert_eq(shape.get_faces().size(), 3 * 2 * 3, "two long sides and the deck end: two triangles (six vertices) each")
	assert_true(tree.get_node_or_null(^"OuterWorksApproach") != null, "the walkable deck is still there")
	tree.free()
