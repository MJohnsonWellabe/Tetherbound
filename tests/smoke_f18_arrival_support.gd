extends SceneTree

## Bounded real physics regression, synthetic Hall slab and wall only.
## This is not a live realm, earned loop, saved arrival or co-op witness.
class FlatWorld extends Node3D:
	func ground_height_at(_x: float, _z: float) -> float: return 0.0

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

func _run() -> void:
	var world := FlatWorld.new()
	root.add_child(world)
	_box(world, Vector3(0, -.08, 0), Vector3(14, .18, 30))
	var steep := _box(world, Vector3(20, 0, 0), Vector3(2, .1, 2))
	steep.rotation.z = PI / 3.0
	var actor := CharacterBody3D.new()
	actor.floor_max_angle = PI / 4.0
	var collision := CollisionShape3D.new()
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
	_box(world, Vector3(0, 1, 0), Vector3(.2, .2, 2))
	await physics_frame
	await physics_frame
	_check(not actor.get_world_3d().direct_space_state.intersect_shape(query, 1).is_empty(), "a real obstruction is still blocked")
	arrival.free()
	world.queue_free()
	await process_frame
	print("F18 SUPPORT: %d checks, %d failures" % [_checks, _failed])
	quit(0 if _failed == 0 else 1)
