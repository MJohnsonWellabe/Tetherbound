extends SceneTree

## Native placement proof for the two actual calm bodies derived from
## dynamo_cluster_24 after its critical-space re-site.
##
##   godot --headless --path . --script tools/probe_stormwood_cluster24_clearance.gd

const ORDER_TEXT := "284525011"
const ROAD_A := Vector2(-100.0, 5350.0)
const ROAD_B := Vector2(-100.0, 5470.0)
const STORMHEART := Vector2(-100.0, 5470.0)
const TIMEOUT_FRAMES := 1800


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var game := root.get_node_or_null(^"Game")
	game.call("reset_for_new_game")
	game.set("current_realm", "stormwood")
	var world := (load("res://scenes/world/stormwood.tscn") as PackedScene).instantiate() as Node3D
	root.add_child(world)
	current_scene = world
	var director: Node
	for frame in TIMEOUT_FRAMES:
		director = world.get_node_or_null(^"EncounterDirector")
		if director != null and bool(director.get("population_ready")):
			break
		await physics_frame
	if director == null or not bool(director.get("population_ready")):
		printerr("CLUSTER24 PROBE FAIL: population not ready")
		quit(1)
		return
	var bodies: Array[Node3D] = []
	for child in world.get_children():
		if child is Node3D and ORDER_TEXT in str(child.name):
			bodies.append(child as Node3D)
	if bodies.size() != 2:
		printerr("CLUSTER24 PROBE FAIL: expected 2 actual bodies, found %d" % bodies.size())
		quit(1)
		return
	var failed := false
	for body in bodies:
		var at := Vector2(body.global_position.x, body.global_position.z)
		var ground := float(world.call("ground_height_at", at.x, at.y))
		var road_distance := Geometry2D.get_closest_point_to_segment(at, ROAD_A, ROAD_B).distance_to(at)
		var stormheart_distance := at.distance_to(STORMHEART)
		var nearby := _nearby_colliders(body, 5.0)
		print("CLUSTER24 BODY node=%s species=%s position=%s ground=%.3f seat_delta=%.3f road=%.3f stormheart=%.3f nearby_colliders=%s" % [
			body.name, str(body.get("species_id")), body.global_position, ground,
			body.global_position.y - ground, road_distance, stormheart_distance, str(nearby)])
		if not is_finite(ground) or absf(body.global_position.y - ground) > 6.0:
			failed = true
		if road_distance < 20.0 or stormheart_distance > 160.0:
			failed = true
	if failed:
		printerr("CLUSTER24 PROBE FAIL")
		quit(1)
	else:
		print("CLUSTER24 PROBE OK")
		quit(0)


func _nearby_colliders(body: Node3D, radius: float) -> Array[String]:
	var shape := SphereShape3D.new()
	shape.radius = radius
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = shape
	query.transform = Transform3D(Basis.IDENTITY, body.global_position)
	var collision_body := body as CollisionObject3D
	query.exclude = [collision_body.get_rid()] if collision_body != null else []
	query.collide_with_areas = false
	query.collide_with_bodies = true
	var names: Array[String] = []
	for hit: Dictionary in body.get_world_3d().direct_space_state.intersect_shape(query, 32):
		var collider: Object = hit.get("collider")
		if collider is Node:
			names.append(str((collider as Node).get_path()))
	return names
