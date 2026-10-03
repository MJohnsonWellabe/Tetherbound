extends SceneTree

const CAPSULE_DIAGNOSTIC := preload("res://tests/helpers/f18_capsule_diagnostic.gd")

## Bounded real physics regression, synthetic Hall, slopes and obstructions.
## This is not a live realm, earned loop, saved arrival or co-op witness.
class FlatWorld extends Node3D:
	func ground_height_at(_x: float, _z: float) -> float: return 0.0

class ProbeBody extends CharacterBody3D:
	func _physics_process(delta: float) -> void:
		velocity.y -= 26.0 * delta
		move_and_slide()

var _failed := 0
var _checks := 0

func _init() -> void: _run.call_deferred()

func _check(ok: bool, reason: String) -> void:
	_checks += 1
	if not ok:
		_failed += 1
		print("F18 SUPPORT FAIL: " + reason)

func _box(parent: Node, at: Vector3, size: Vector3) -> StaticBody3D:
	var body := StaticBody3D.new()
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	collision.shape = shape
	body.add_child(collision)
	parent.add_child(body)
	body.position = at
	return body

func _actor(world: Node3D, at: Vector3) -> ProbeBody:
	var actor := ProbeBody.new()
	actor.floor_snap_length = .4
	var collision := CollisionShape3D.new()
	collision.name = "Collision"
	var capsule := CapsuleShape3D.new()
	capsule.radius = .4
	capsule.height = 1.8
	collision.shape = capsule
	collision.position.y = .9
	actor.add_child(collision)
	world.add_child(actor)
	actor.global_position = at
	actor.set_physics_process(false)
	return actor

func _concave_boxes(world: Node3D, boxes: Array) -> StaticBody3D:
	# One real concave shape/RID owns both floor and obstruction. Using
	# BoxMesh's actual triangles avoids a mocked collision/contact producer.
	var faces := PackedVector3Array()
	for box: Array in boxes:
		var mesh := BoxMesh.new()
		mesh.size = box[1]
		for vertex: Vector3 in mesh.get_faces(): faces.append(vertex + (box[0] as Vector3))
	var shape := ConcavePolygonShape3D.new()
	shape.set_faces(faces)
	var collision := CollisionShape3D.new()
	collision.shape = shape
	var body := StaticBody3D.new()
	body.add_child(collision)
	world.add_child(body)
	return body

func _landing_check(arrival: Node, world: Node3D, actor: CharacterBody3D, target: Vector3, accepted: bool, label: String) -> Vector3:
	var before := actor.global_transform
	var collision := actor.get_node(^"Collision") as CollisionShape3D
	# Shipping _travel_owner passes the actual native capsule property.
	# A GDScript literal .4 need not equal that native real_t exactly.
	var radius: float = (collision.shape as CapsuleShape3D).radius
	if accepted: print("F18_CAPSULE_RADIUS_BINDING " + JSON.stringify({"case": label, "shape_radius": radius,
		"literal_exact_match": radius == .4, "production_radius_exact_match": radius == (collision.shape as CapsuleShape3D).radius}))
	var landing: Vector3 = arrival.call("_capsule_landing", world, actor, target, radius)
	if accepted and not landing.is_finite(): CAPSULE_DIAGNOSTIC.report(arrival, world, actor, target, radius, label)
	_check(landing.is_finite() == accepted, label)
	_check(actor.global_transform == before, label + " leaves the actual actor pose unchanged")
	if accepted and landing.is_finite():
		var query := PhysicsShapeQueryParameters3D.new()
		query.shape = collision.shape
		query.transform = collision.global_transform
		query.transform.origin += landing - actor.global_position
		query.collision_mask = actor.collision_mask
		query.exclude = [actor.get_rid()]
		_check(landing.is_finite() and actor.get_world_3d().direct_space_state.intersect_shape(query, 1).is_empty(), label + " clears the complete capsule")
	elif accepted:
		_check(false, label + " clears the complete capsule")
	return landing

func _bounded_cases() -> void:
	var arrival := preload("res://scripts/net/foundation_portal_arrival.gd").new()
	# Explicit isolated pose fixtures; only normal move_and_slide produces
	# on_floor. No Session, permit, durable writer or gameplay actor is used.
	for sign_value: float in [-1.0, 1.0]:
		var world := FlatWorld.new()
		root.add_child(world)
		world.position.x = 60.0 if sign_value < 0 else 70.0
		var slope := _box(world, Vector3(0, -.05, 0), Vector3(4, .1, 4))
		slope.rotation.z = sign_value * .2
		var actor := _actor(world, world.global_position + Vector3(4, 3, 0))
		await physics_frame
		await physics_frame
		var landing := _landing_check(arrival, world, actor, world.global_position, true, "mirrored walkable slope %s uses actual full-capsule cast" % sign_value)
		if landing.is_finite():
			actor.global_position = landing
			actor.velocity = Vector3.ZERO
			actor.set_physics_process(true)
			for frame in 30: await physics_frame
			actor.set_physics_process(false)
			_check(actor.is_on_floor(), "mirrored slope obtains actual ordinary controller floor contact")
			var before := actor.global_transform
			_check(arrival._supported_capsule(world, actor, world.global_position, .4), "mirrored slope passes complete final supported capsule guard")
			_check(actor.global_transform == before, "final slope guard observes without moving actor")
		world.queue_free()
		await process_frame
	for kind: String in ["separate_platform", "shared_platform", "shared_wall", "tiny_ceiling", "tiny_floor"]:
		var world := FlatWorld.new()
		root.add_child(world)
		world.position.x = 80.0
		if kind == "shared_platform" or kind == "shared_wall":
			var obstruction: Array = [Vector3(.2, .1, .2), Vector3(.08, .2, .08)] if kind == "shared_platform" \
				else [Vector3(.15, .9, 0), Vector3(.02, 1.8, 2)]
			_concave_boxes(world, [[Vector3(0, -.05, 0), Vector3(4, .1, 4)], obstruction])
		else:
			_box(world, Vector3(0, -.05, 0), Vector3(.1, .1, .1) if kind == "tiny_floor" else Vector3(4, .1, 4))
			if kind == "separate_platform": _box(world, Vector3(.2, .1, .2), Vector3(.08, .2, .08))
			if kind == "tiny_ceiling": _box(world, Vector3(0, 1.8002, 0), Vector3(2, .0004, 2))
		var actor := _actor(world, world.global_position + Vector3(4, 3, 0))
		await physics_frame
		await physics_frame
		_landing_check(arrival, world, actor, world.global_position, false, "initial solver refuses " + kind)
		world.queue_free()
		await process_frame
	var world := FlatWorld.new()
	root.add_child(world)
	world.position.x = 90.0
	var hall := _concave_boxes(world, [[Vector3(0, -.05, 0), Vector3(4, .1, 4)]])
	var actor := _actor(world, world.global_position + Vector3(0, .1, 0))
	actor.set_physics_process(true)
	for frame in 30: await physics_frame
	actor.set_physics_process(false)
	_check(actor.is_on_floor(), "deep-embed fixture begins with actual ordinary floor contact")
	var grounded_pose := actor.global_transform
	actor.position.y -= .02
	var embedded_pose := actor.global_transform
	_check(not arrival._supported_capsule(world, actor, world.global_position, .4), "skin exception refuses excessive floor embedding")
	_check(actor.global_transform == embedded_pose, "embed refusal does not recover or move actor")
	var ungrounded := _actor(world, world.global_position + Vector3(0, -.00005, 0))
	var ungrounded_pose := ungrounded.global_transform
	_check(not ungrounded.is_on_floor() and not arrival._supported_capsule(world, ungrounded, world.global_position, .4), "skin overlap without actual controller floor contact is refused")
	_check(ungrounded.global_transform == ungrounded_pose, "ungrounded skin refusal leaves pose unchanged")
	ungrounded.queue_free()
	actor.global_transform = grounded_pose
	var hall_shape := (hall.get_child(0) as CollisionShape3D).shape as ConcavePolygonShape3D
	var original_faces := hall_shape.get_faces()
	var wall_mesh := BoxMesh.new()
	wall_mesh.size = Vector3(.02, 1.8, 2)
	var with_wall := original_faces.duplicate()
	for vertex: Vector3 in wall_mesh.get_faces(): with_wall.append(vertex + Vector3(.15, .9, 0))
	hall_shape.set_faces(with_wall)
	await physics_frame
	await physics_frame
	_check(not arrival._supported_capsule(world, actor, world.global_position, .4), "final skin guard refuses a wall on the same concave floor shape/RID")
	_check(actor.global_transform == grounded_pose, "shared Hall wall refusal leaves actual pose unchanged")
	hall_shape.set_faces(original_faces)
	_box(world, Vector3(0, 1.8002, 0), Vector3(2, .0004, 2))
	await physics_frame
	await physics_frame
	_check(not arrival._supported_capsule(world, actor, world.global_position, .4), "final skin guard refuses tiny ceiling overlap")
	_check(actor.global_transform == grounded_pose, "tiny ceiling refusal leaves actual pose unchanged")
	world.queue_free()
	await process_frame
	arrival.free()

func _run() -> void:
	var world := FlatWorld.new()
	root.add_child(world)
	_box(world, Vector3(0, -.08, 0), Vector3(14, .18, 30))
	var steep := _box(world, Vector3(20, 0, 0), Vector3(2, .1, 2))
	steep.rotation.z = PI / 3.0
	var actor := CharacterBody3D.new()
	actor.floor_max_angle = PI / 4.0
	var collision := CollisionShape3D.new()
	collision.name = "Collision"
	var capsule := CapsuleShape3D.new()
	capsule.radius = .4
	capsule.height = 1.8
	collision.shape = capsule
	collision.position.y = .9
	actor.add_child(collision)
	world.add_child(actor)
	actor.position = Vector3(6, 1, 0)
	var arrival := preload("res://scripts/net/foundation_portal_arrival.gd").new()
	await physics_frame
	await physics_frame
	var target := Vector3(0, .3, 0)
	var height: float = arrival._landing_height(world, actor, target, capsule.radius)
	_check(is_finite(height) and absf(height - .01) < .00001, "actual slab top, not raw terrain, owns support")
	for offset: Vector2 in [Vector2(-.4, 0), Vector2(.4, 0), Vector2(0, -.4), Vector2(0, .4)]:
		var edge: float = arrival._landing_height(world, actor, target + Vector3(offset.x, 0, offset.y), capsule.radius)
		_check(is_finite(edge) and absf(edge - height) < .00001, "capsule edge is supported by the same real slab")
	_check(not is_finite(arrival._landing_height(world, actor, Vector3(50, 0, 0), capsule.radius)), "missing physical floor cannot use analytical terrain")
	_check(not is_finite(arrival._landing_height(world, actor, Vector3(20, 0, 0), capsule.radius)), "steep physical floor remains refused")
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = capsule
	query.transform = collision.global_transform
	query.transform.origin += Vector3(target.x, height + actor.safe_margin, target.z) - actor.global_position
	query.collision_mask = actor.collision_mask
	query.exclude = [actor.get_rid()]
	_check(actor.get_world_3d().direct_space_state.intersect_shape(query, 1).is_empty(), "supported landing clears the complete capsule")
	_landing_check(arrival, world, actor, target, true, "initial full-capsule solver accepts the actual Hall slab")
	var wrong_radius_pose := actor.global_transform
	_check(not arrival._capsule_landing(world, actor, target, capsule.radius * .5).is_finite(), "initial solver rejects a radius that does not match the actual capsule")
	_check(actor.global_transform == wrong_radius_pose, "wrong-radius refusal leaves actual actor pose unchanged")
	_landing_check(arrival, world, actor, Vector3(50, 0, 0), false, "initial full-capsule solver refuses missing physical floor")
	_landing_check(arrival, world, actor, Vector3(20, 0, 0), false, "initial full-capsule solver refuses steep physical floor")
	_box(world, Vector3(0, 1, 0), Vector3(.2, .2, 2))
	await physics_frame
	await physics_frame
	_check(not actor.get_world_3d().direct_space_state.intersect_shape(query, 1).is_empty(), "a real obstruction is still blocked")
	arrival.free()
	world.queue_free()
	await process_frame
	await _bounded_cases()
	print("F18 SUPPORT: %d checks, %d failures" % [_checks, _failed])
	quit(0 if _failed == 0 else 1)
