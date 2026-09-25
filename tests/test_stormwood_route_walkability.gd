extends "res://tests/test_case.gd"

## F09: authored Stormwood roads are walkable on the production heightfield,
## and Deepwood reaches the Dynamo by two separate roads. Roads are not carved
## into the terrain, so each road's centre corridor is graded with the ground's
## true slope against the player's own floor limit.
const FIELD := preload("res://scripts/world/stormwood_heightfield.gd")
const WORLD_PATH := "res://data/config/stormwood_world.json"
const CAMPS_PATH := "res://data/config/stormwood_camps.json"
const TERRAIN_PATH := "res://data/config/terrain_stormwood.json"
const MAX_WALK_DEG := 45.0  # scenes/player/player.tscn floor_max_angle 0.7854
const SAMPLE_STEP_M := 1.0


func _read(path: String) -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string(path)) as Dictionary


func _xz(raw: Array) -> Vector2:
	return Vector2(float(raw[0]), float(raw[1]))


## The terrain contract's own road corridor (terrain_stormwood.json
## `route_half_width`), graded across its centre line and both edges.
func _half_width() -> float:
	return float(_read(TERRAIN_PATH).route_half_width)


func _steepest(field: RefCounted, points: Array) -> Dictionary:
	var half_width := _half_width()
	var worst := {"deg": 0.0, "at": Vector2.ZERO}
	for i in range(1, points.size()):
		var a := _xz(points[i - 1])
		var b := _xz(points[i])
		var side := (b - a).normalized().orthogonal()
		var steps := maxi(1, ceili(a.distance_to(b) / SAMPLE_STEP_M))
		for n in steps + 1:
			var centre := a.lerp(b, float(n) / steps)
			for offset: float in [-half_width, -half_width * 0.5, 0.0, half_width * 0.5, half_width]:
				var at := centre + side * offset
				var deg: float = field.slope_degrees_at(at.x, at.y)
				if deg > float(worst.deg):
					worst = {"deg": deg, "at": at}
	return worst


func _region(world: Dictionary, id: String) -> Dictionary:
	for region: Dictionary in world.regions:
		if str(region.id) == id:
			return region
	return {}


func test_every_authored_road_corridor_is_walkable() -> void:
	var field := FIELD.new()
	var world := _read(WORLD_PATH)
	assert_true(_half_width() >= 7.5, "the graded corridor is at least the terrain contract's road width")
	for route: Dictionary in world.routes:
		var worst := _steepest(field, route.points)
		assert_true(float(worst.deg) <= MAX_WALK_DEG, "%s climbs %.1f deg at %s, over the %.0f deg floor limit" % [
			route.id, float(worst.deg), worst.at, MAX_WALK_DEG])


func test_deepwood_reaches_the_dynamo_by_two_separate_roads() -> void:
	var world := _read(WORLD_PATH)
	var boundary := float(_region(world, "dynamo").bounds.min_z)
	assert_eq(boundary, float(_region(world, "deepwood").bounds.max_z), "Deepwood and the Dynamo share one boundary")
	var crossings: Array[Vector2] = []
	var crossing_routes: Array[String] = []
	for route: Dictionary in world.routes:
		var points: Array = route.points
		for i in range(1, points.size()):
			var a := _xz(points[i - 1])
			var b := _xz(points[i])
			if (a.y < boundary) == (b.y < boundary):
				continue
			crossings.append(a.lerp(b, (boundary - a.y) / (b.y - a.y)))
			crossing_routes.append(str(route.id))
	assert_true(crossings.size() >= 2 and crossing_routes.has("deepwood_road") and crossing_routes.has("dynamo_west_approach"),
		"two authored roads cross from Deepwood into the Dynamo: %s" % [crossing_routes])
	var widest := 0.0
	for i in crossings.size():
		for j in range(i + 1, crossings.size()):
			widest = maxf(widest, crossings[i].distance_to(crossings[j]))
	assert_true(widest >= 150.0, "the two Dynamo approaches are separate roads, not one road drawn twice (%.0f m apart)" % widest)


func test_the_alternate_dynamo_approach_joins_authored_places() -> void:
	var world := _read(WORLD_PATH)
	var alternate: Dictionary = {}
	var deepwood_vertices: Array[Vector2] = []
	for route: Dictionary in world.routes:
		if str(route.id) == "dynamo_west_approach":
			alternate = route
		elif str(route.id) in ["deepwood_road", "hall_loop"]:
			for raw: Array in route.points:
				deepwood_vertices.append(_xz(raw))
	assert_false(alternate.is_empty(), "the second Dynamo approach is authored")
	if alternate.is_empty():
		return
	assert_eq(str(alternate.get("requires_unlock", "")), "stormwood:rootgate_released",
		"the second approach lies beyond the Rootgate like the road it parallels")
	var points: Array = alternate.points
	assert_true(deepwood_vertices.has(_xz(points[0])), "it leaves from a Deepwood road junction")
	var ember := Vector2.INF
	for camp: Dictionary in _read(CAMPS_PATH).camps:
		if str(camp.id) == "ember_bivouac":
			ember = _xz(camp.at)
	assert_eq(_xz(points[points.size() - 1]), ember, "it arrives at Ember Bivouac, the Dynamo's camp")


func test_ordinary_roads_never_enter_the_glass_sink() -> void:
	# stormwood_world.json: "Ordinary routes never enter the Glass Sink." Only
	# the Crown's own island ring lies inside its rim.
	var sink: Dictionary = _read(TERRAIN_PATH).glass_sink
	var centre := Vector2(float(sink.centre[0]), float(sink.centre[1]))
	var rim := float(sink.outer_radius)
	for route: Dictionary in _read(WORLD_PATH).routes:
		if str(route.kind) == "island":
			continue
		var points: Array = route.points
		var nearest := INF
		for i in range(1, points.size()):
			var a := _xz(points[i - 1])
			var b := _xz(points[i])
			nearest = minf(nearest, Geometry2D.get_closest_point_to_segment(centre, a, b).distance_to(centre))
		assert_true(nearest > rim + _half_width(), "%s stays outside the Glass Sink rim (%.0f m from its centre, rim %.0f m)" % [
			route.id, nearest, rim])
