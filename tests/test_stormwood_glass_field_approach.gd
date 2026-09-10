extends "res://tests/test_case.gd"

const CATALOGUE := preload("res://scripts/combat/stormwood_encounter_catalogue.gd")
const FIELD := preload("res://scripts/world/stormwood_heightfield.gd")
const BOUNDS := preload("res://scripts/characters/render_bounds.gd")
const BAKE := preload("res://scripts/world/scatter_bake.gd")
const SCATTER := preload("res://scripts/world/stormwood_scatter.gd")


func test_named_alpha_clears_route_camera_and_wander_without_changing_encounter() -> void:
	var source: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/stormwood_encounters.json"))
	var named: Dictionary = {}
	for row: Dictionary in source.named_encounters:
		if str(row.id) == "glass_field_alpha":
			named = row
	assert_false(named.is_empty())
	if named.is_empty():
		return
	var field := FIELD.new()
	var runtime := CATALOGUE._named_spawn(named, field)
	var previous := named.duplicate(true)
	previous.position = [-310, 100, 5050]
	var previous_runtime := CATALOGUE._named_spawn(previous, field)
	var at := Vector2(float(named.position[0]), float(named.position[2]))
	assert_true(is_finite(float(runtime.centre[1])))
	assert_true(float(runtime.centre[1]) > 0.0)
	runtime.erase("centre")
	previous_runtime.erase("centre")
	assert_eq(runtime, previous_runtime, "Only the resolved position changes; stable order, count, combat, level, catchability and once flag survive")
	var species: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/creatures/species.json"))
	var look: Dictionary = species.species.voltarach.placeholder
	var model := (load(str(look.model)) as PackedScene).instantiate() as Node3D
	var box := BOUNDS.measure(model)
	model.free()
	assert_true(box.size.y > 0.0)
	var fit := minf(float(look.height) / box.size.y, float(look.radius) * 2.0 * float(look.footprint_allowance) / maxf(box.size.x, box.size.z))
	var half_x := maxf(absf(box.position.x), absf(box.end.x)) * fit
	var half_z := maxf(absf(box.position.z), absf(box.end.z)) * fit
	var mesh_radius := Vector2(half_x, half_z).length()
	var combat: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/combat.json"))
	var wander := float(combat.wild.wander_radius)
	# Every yaw fits this diagonal, with 2m extra for idle leg motion. Include
	# the authored 9m road corridor and the actual 5.2m exploration spring arm.
	var wildlife_envelope := mesh_radius + 2.0 + wander
	var required_clearance := wildlife_envelope + 9.0 + 5.2
	var world: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/stormwood_world.json"))
	var nearest_route := _nearest_route(at, world)
	assert_true(nearest_route > required_clearance, "Named alpha's mesh, idle motion and wander must clear the normal route camera envelope")
	assert_true(at.distance_to(Vector2(-310, 5050)) > required_clearance)
	assert_true(at.distance_to(Vector2(-310, 5050)) < 100.0, "Keep the encounter near its original landmark")
	# The former exact route/teleport overlap must be rejected by this guard.
	assert_false(_nearest_route(Vector2(-310, 5050), world) > required_clearance,
		"The former exact route/teleport position must fail the same geometric check")
	var max_slope := 0.0
	for sample in 17:
		var point := at if sample == 0 else at + Vector2.from_angle(TAU * float(sample - 1) / 16.0) * wildlife_envelope
		max_slope = maxf(max_slope, field.slope_degrees_at(point.x, point.y))
		assert_true(field.height_at(point.x, point.y) > 0.0)
	assert_true(max_slope < 30.0, "Actual terrain must support the resident and its ordinary wander")
	assert_true(BAKE.is_fresh("stormwood", int(SCATTER.config().seed), SCATTER.fingerprint()))
	var layers := {}
	var drained := {}
	# Read the actual baked regions touching the candidate envelope, using the
	# production decoder. The envelope straddles this pair's z boundary.
	for region in [Vector2i(-1, 9), Vector2i(-1, 10)]:
		var file := FileAccess.open("res://data/scatter/stormwood/region_%d_%d.bin" % [region.x, region.y], FileAccess.READ)
		assert_true(file != null)
		if file != null:
			BAKE._read_region(file, layers, drained)
	var nearest_solid := INF
	var config := SCATTER.config()
	for layer: String in layers:
		var spec: Dictionary = config.layers[layer]
		if not bool(spec.get("collides", false)):
			continue
		for entry: Dictionary in layers[layer]:
			var placement: Dictionary = entry.placement
			var point: Vector3 = placement.position
			var clearance := at.distance_to(Vector2(point.x, point.z)) - float(spec.collision_radius) * float(placement.scale)
			nearest_solid = minf(nearest_solid, clearance)
	assert_true(nearest_solid > wildlife_envelope, "The full idle/wander envelope must clear baked trunk/rock collision")
	print("GLASS FIELD APPROACH at=", at, " mesh_radius=", mesh_radius, " wander=", wander, " road=", nearest_route, " required=", required_clearance, " max_slope=", max_slope, " nearest_baked_solid=", nearest_solid)


func _nearest_route(at: Vector2, world: Dictionary) -> float:
	var nearest := INF
	for route: Dictionary in world.routes:
		for index in range(1, route.points.size()):
			var a := Vector2(float(route.points[index - 1][0]), float(route.points[index - 1][1]))
			var b := Vector2(float(route.points[index][0]), float(route.points[index][1]))
			nearest = minf(nearest, Geometry2D.get_closest_point_to_segment(at, a, b).distance_to(at))
	return nearest
