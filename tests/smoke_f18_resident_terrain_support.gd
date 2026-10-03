extends SceneTree

## Real native baked Meadows data and real physics, with isolated probe bodies
## and disclosed camera/position/data fixtures. No player/save/co-op acceptance.
const SUPPORT := preload("res://scripts/world/waystone_terrain_support.gd")
const ARRIVAL := preload("res://scripts/net/foundation_portal_arrival.gd")
const HEIGHT := preload("res://scripts/world/terrain_height.gd")

class ProbeWorld extends Node3D:
	var terrain: Node3D
	func ground_height_at(x: float, z: float) -> float: return HEIGHT.height_at(terrain, x, z)

class ProbeBody extends CharacterBody3D:
	var contacts := 0
	func _physics_process(delta: float) -> void:
		velocity.y -= 26.0 * delta
		move_and_slide()
		if is_on_floor(): contacts += 1

var checks := 0
var failures: Array[String] = []

func _initialize() -> void: _run.call_deferred()

func _check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures.append(message)
		print("F18 RESIDENT SUPPORT FAIL: " + message)

func _body(world: Node3D, at: Vector3) -> ProbeBody:
	var body := ProbeBody.new()
	body.floor_snap_length = .4
	var collision := CollisionShape3D.new()
	collision.name = "Collision"
	var capsule := CapsuleShape3D.new()
	capsule.radius = .4
	capsule.height = 1.8
	collision.shape = capsule
	collision.position.y = .9
	body.add_child(collision)
	world.add_child(body)
	body.position = at
	return body

func _frames(count: int) -> void:
	for frame in count: await physics_frame

func _vector_record(value: Vector3) -> Array:
	return [value.x, value.y, value.z]

func _collider_record(collider: Object, rid: RID) -> Dictionary:
	var record := {"rid": str(rid)}
	if is_instance_valid(collider):
		record["instance_id"] = collider.get_instance_id()
		record["class"] = collider.get_class()
		if collider is Node:
			record["path"] = str(collider.get_path()) if collider.is_inside_tree() else str(collider.name)
	return record

func _overlap_record(probe: ProbeBody, collision: CollisionShape3D, at: Transform3D) -> Dictionary:
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = collision.shape
	query.transform = at
	query.collision_mask = probe.collision_mask
	query.exclude = [probe.get_rid()]
	# Diagnostics report every returned overlap and explicitly disclose a cap.
	var hits: Array[Dictionary] = probe.get_world_3d().direct_space_state.intersect_shape(query, 2048)
	var records: Array[Dictionary] = []
	for hit: Dictionary in hits:
		var record := _collider_record(hit.get("collider"), hit.get("rid", RID()))
		record["shape"] = hit.get("shape", -1)
		record["hit_instance_id"] = hit.get("collider_id", 0)
		records.append(record)
	return {"origin": _vector_record(at.origin), "query_margin": query.margin,
		"collision_mask": query.collision_mask, "hits": records, "saturated": hits.size() == 2048}

func _contact_diagnostic(world: ProbeWorld, probe: ProbeBody, arrival: Node, target: Vector3) -> void:
	# Observations only: do not move the actor, alter a production predicate,
	# suppress a failing assertion, or exclude any floor/terrain/wall RID.
	var before := probe.global_transform
	var collision := probe.get_node(^"Collision") as CollisionShape3D
	var radius: float = (collision.shape as CapsuleShape3D).radius
	var samples: Array[Dictionary] = []
	for offset: Vector2 in [Vector2.ZERO, Vector2(-radius, 0), Vector2(radius, 0), Vector2(0, -radius), Vector2(0, radius)]:
		var at := target + Vector3(offset.x, 0, offset.y)
		var terrain: float = float(arrival.call("_ground_height", world, at))
		var sample := {"at": _vector_record(at), "terrain_height": terrain,
			"production_height": float(arrival.call("_landing_height", world, probe, at, radius)), "hit": false}
		if is_finite(terrain):
			var ray_from := Vector3(at.x, terrain + radius, at.z)
			var ray_to := Vector3(at.x, terrain - radius, at.z)
			var ray := PhysicsRayQueryParameters3D.create(ray_from, ray_to, probe.collision_mask, [probe.get_rid()])
			var hit := probe.get_world_3d().direct_space_state.intersect_ray(ray)
			sample["ray_from"] = _vector_record(ray_from)
			sample["ray_to"] = _vector_record(ray_to)
			if not hit.is_empty():
				sample["hit"] = true
				sample["position"] = _vector_record(hit.position)
				sample["normal"] = _vector_record(hit.normal)
				sample["collider"] = _collider_record(hit.get("collider"), hit.get("rid", RID()))
				sample["shape"] = hit.get("shape", -1)
		samples.append(sample)
	var lifted := collision.global_transform
	lifted.origin.y += probe.safe_margin
	var canonical: float = float(arrival.call("_landing_height", world, probe, target, radius))
	var canonical_overlap: Dictionary = {"skipped": "canonical physical floor missing"}
	if is_finite(canonical):
		var canonical_transform := collision.global_transform
		# Change only the query's Y; retain the actual actor's X/Z and basis.
		canonical_transform.origin.y += canonical + probe.safe_margin - probe.global_position.y
		canonical_overlap = _overlap_record(probe, collision, canonical_transform)
	var motion := PhysicsTestMotionParameters3D.new()
	motion.from = probe.global_transform
	motion.motion = Vector3.ZERO
	motion.margin = probe.safe_margin
	motion.recovery_as_collision = true
	motion.max_collisions = 32
	var result := PhysicsTestMotionResult3D.new()
	var recovered := PhysicsServer3D.body_test_motion(probe.get_rid(), motion, result)
	var contacts: Array[Dictionary] = []
	for i in result.get_collision_count():
		contacts.append({"depth": result.get_collision_depth(i), "normal": _vector_record(result.get_collision_normal(i)),
			"point": _vector_record(result.get_collision_point(i)), "collider": _collider_record(result.get_collider(i), result.get_collider_rid(i)),
			"collider_shape": result.get_collider_shape(i), "local_shape": result.get_collision_local_shape(i)})
	print("F18_SUPPORT_CONTACT_DIAGNOSTIC " + JSON.stringify({"actor_position": _vector_record(probe.global_position),
		"collision_origin": _vector_record(collision.global_position), "safe_margin": probe.safe_margin,
		"is_on_floor": probe.is_on_floor(), "floor_normal": _vector_record(probe.get_floor_normal()), "rays": samples,
		"raw": _overlap_record(probe, collision, collision.global_transform), "plus_safe_margin": _overlap_record(probe, collision, lifted),
		"canonical_actor_y": canonical_overlap, "zero_motion": {"collided": recovered, "margin": motion.margin,
			"travel": _vector_record(result.get_travel()), "remainder": _vector_record(result.get_remainder()),
			"contacts": contacts, "saturated": result.get_collision_count() == motion.max_collisions},
		"actor_transform_unchanged": probe.global_transform == before}))

func _run() -> void:
	await process_frame
	if not ClassDB.class_exists("Terrain3D"):
		_check(false, "required native Terrain3D missing")
		_finish()
		return
	var config: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/terrain_playground.json"))
	var world := ProbeWorld.new()
	root.add_child(world)
	var camera := Camera3D.new()
	world.add_child(camera)
	camera.global_position = Vector3(96.2, 10.0, 14.0)
	camera.make_current()
	world.terrain = ClassDB.instantiate("Terrain3D")
	world.terrain.name = "Terrain"
	world.terrain.set("region_size", int(config.region_size))
	world.terrain.set("vertex_spacing", float(config.vertex_spacing))
	world.add_child(world.terrain)
	world.terrain.set("data_directory", "res://data/terrain/playground")
	world.terrain.call("set_camera", camera)
	world.terrain.set("collision_mode", 1)
	world.terrain.set("collision_radius", 256)
	world.terrain.set("collision_shape_size", 64)
	await _frames(6)
	var target := Vector3(344.3, 0, 926.6)
	target.y = world.ground_height_at(target.x, target.z)
	_check(target.is_finite(), "authored Trail Camp native height exists")
	var probe := _body(world, Vector3(96.2, 3, 14))
	probe.set_physics_process(false)
	var arrival := ARRIVAL.new()
	_check(not is_finite(arrival._landing_height(world, probe, target, .4)), "original distant dynamic bubble has no Trail Camp physical floor")
	var stone := Node3D.new()
	world.add_child(stone)
	stone.global_position = target + Vector3(0, 0, 3)
	_check(SUPPORT.mount(world, stone), "resident patch mounts from actual native vertices at vertex_spacing2")
	_check(SUPPORT.mount(world, stone) and stone.get_child_count() == 1, "mount is idempotent")
	await _frames(2)
	var physical: float = arrival._landing_height(world, probe, target, .4)
	_check(is_finite(physical), "camera946m away still has actual physical floor")
	if not is_finite(physical):
		arrival.free()
		world.queue_free()
		await process_frame
		_finish()
		return
	for offset: Vector2 in [Vector2(-.4, 0), Vector2(.4, 0), Vector2(0, -.4), Vector2(0, .4)]:
		_check(is_finite(arrival._landing_height(world, probe, target + Vector3(offset.x, 0, offset.y), .4)), "all capsule perimeter rays hit real resident terrain")
	var shape := stone.get_child(0).get_child(0).shape as ConcavePolygonShape3D
	var source: PackedVector3Array = SUPPORT.native_faces(world.terrain.get("data"), 2.0, stone.global_position)
	var stored: PackedVector3Array = shape.get_faces()
	var exact := source.size() == stored.size() and stored.size() <= SUPPORT.MAX_VERTICES
	for i in mini(source.size(), stored.size()):
		exact = exact and stone.to_global(stored[i]).distance_to(source[i]) <= .0001
	_check(exact, "bounded patch retains native vertices without invented height or double offset")
	probe.global_position = Vector3(target.x, physical + probe.safe_margin, target.z)
	probe.velocity = Vector3.ZERO
	probe.set_physics_process(true)
	await _frames(30)
	_check(probe.is_on_floor() and probe.contacts > 0 and probe.global_position.distance_to(Vector3(target.x, physical + probe.safe_margin, target.z)) < .1,
		"actual physics body gets stable contact on distant patch")
	var before := probe.global_position
	camera.global_position = target + Vector3(0, 10, 0)
	await _frames(60)
	_check(probe.is_on_floor() and probe.velocity.length() < .1 and probe.global_position.distance_to(before) < .1,
		"dynamic bubble overlap does not shove the body or lose contact")
	_contact_diagnostic(world, probe, arrival, target)
	_check(arrival._supported_capsule(world, probe, target, .4), "final production support/capsule guard accepts actual supported body")
	probe.set_physics_process(false)
	var wall := StaticBody3D.new()
	var wall_collision := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(.2, .2, 2)
	wall_collision.shape = box
	wall.add_child(wall_collision)
	world.add_child(wall)
	wall.global_position = Vector3(target.x, physical + .9, target.z)
	await _frames(2)
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = probe.get_node(^"Collision").shape
	query.transform = probe.get_node(^"Collision").global_transform
	query.exclude = [probe.get_rid()]
	_check(not probe.get_world_3d().direct_space_state.intersect_shape(query, 1).is_empty(), "resident terrain never waives a real full-capsule wall obstruction")
	_check(not arrival._supported_capsule(world, probe, target, .4), "final production guard refuses an obstruction added after the initial landing")
	wall.queue_free()
	probe.set_physics_process(false)
	camera.global_position = Vector3(96.2, 10, 14)
	await _frames(4)
	stone.queue_free()
	await _frames(2)
	_check(not is_finite(arrival._landing_height(world, probe, target, .4)), "disposal removes resident floor outside native bubble")
	var replacement := Node3D.new()
	world.add_child(replacement)
	replacement.global_position = target + Vector3(0, 0, 3)
	_check(SUPPORT.mount(world, replacement), "fresh owner remount builds its own patch")
	var data: Object = world.terrain.get("data")
	var hole := Vector3(344, 0, 930)
	data.call("set_control_hole", hole, true)
	data.call("update_maps", 3, true, false)
	await _frames(2)
	_check(not replacement.has_node(NodePath(SUPPORT.CHILD_NAME)), "control map change invalidates old collision")
	_check(SUPPORT.native_faces(data, 2.0, replacement.global_position).is_empty() and not SUPPORT.mount(world, replacement), "painted native hole stays refused without filling vertices")
	_check(SUPPORT.native_faces(data, 2.0, Vector3(100000, 0, 100000)).is_empty(), "missing native region stays refused")
	_check(SUPPORT.native_faces(data, 0.0, target).is_empty() and SUPPORT.native_faces(data, .25, target).is_empty(), "invalid or oversized requests never bake the whole terrain")
	arrival.free()
	world.queue_free()
	await process_frame
	_finish()

func _finish() -> void:
	print("F18_RESIDENT_TERRAIN_SUPPORT " + JSON.stringify({"checks": checks, "failures": failures,
		"fixtures": "isolated baked-terrain native instance, probe bodies, camera moves, temporary in-memory painted hole; no files saved"}))
	quit(0 if failures.is_empty() else 1)
