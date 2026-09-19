extends SceneTree

const MANAGER := preload("res://scripts/combat/combat_manager.gd")
const ARENA := preload("res://scripts/combat/combat_arena.gd")
var failures: Array[String] = []

class FlatWorld extends Node3D:
	var slope := 0.0
	func ground_height_at(x: float, _z: float) -> float:
		return x * tan(slope)

func _init() -> void:
	_run.call_deferred()

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

func _check(condition: bool, label: String) -> void:
	if not condition:
		failures.append(label)
	print("%s: %s" % ["PASS" if condition else "FAIL", label])

func _run() -> void:
	var world := FlatWorld.new()
	root.add_child(world)
	var floor_body := _box(world, Vector3(0, -0.5, 0), Vector3(40, 1, 40))
	var player := CharacterBody3D.new()
	var collision := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.4
	capsule.height = 1.8
	collision.shape = capsule
	collision.position.y = 0.9
	player.add_child(collision)
	world.add_child(player)
	var manager := MANAGER.new()
	world.add_child(manager)
	manager.set_process(false)
	manager.set_physics_process(false)
	var arena := ARENA.new()
	world.add_child(arena)
	arena.set_process(false)
	arena.set_physics_process(false)
	arena.set("radius", 8.0)
	manager.set("_player", player)
	manager.set("_arena", arena)
	await physics_frame
	await physics_frame
	manager.call("_stand_the_trainer_aside", Vector3.FORWARD)
	_check(player.position.distance_to(Vector3(4.4, 0, 1.2)) < 0.01, "open side preserves intended grounded placement")
	player.position = Vector3.ZERO
	# Endpoint is clear, but reaching it would cross a closed cottage wall.
	var right_wall := _box(world, Vector3(2, 1.5, 0), Vector3(0.3, 3, 10))
	await physics_frame
	await physics_frame
	manager.call("_stand_the_trainer_aside", Vector3.FORWARD)
	_check(player.position.distance_to(Vector3(-4.4, 0, 1.2)) < 0.01, "blocked transit selects clear opposite side")
	player.position = Vector3.ZERO
	var left_wall := _box(world, Vector3(-2, 1.5, 0), Vector3(0.3, 3, 10))
	await physics_frame
	await physics_frame
	manager.call("_stand_the_trainer_aside", Vector3.FORWARD)
	_check(player.position.distance_to(Vector3.ZERO) < 0.01, "both blocked retains actual starting location")
	floor_body.queue_free()
	await physics_frame
	await physics_frame
	player.position = Vector3(0, 0, 12)
	manager.call("_stand_the_trainer_aside", Vector3.FORWARD)
	_check(player.position.distance_to(Vector3(0, 0, 12)) < 0.01, "unsupported claimed floor retains actual starting location")
	right_wall.queue_free()
	left_wall.queue_free()
	world.slope = deg_to_rad(10.0)
	var ramp := _box(world, Vector3(0, -0.5, 0).rotated(Vector3.BACK, world.slope), Vector3(40, 1, 40))
	ramp.rotation.z = world.slope
	player.position = Vector3.ZERO
	await physics_frame
	await physics_frame
	manager.call("_stand_the_trainer_aside", Vector3.FORWARD)
	var expected := Vector3(4.4, 4.4 * tan(world.slope), 1.2)
	_check(player.position.distance_to(expected) < 0.01, "supported gentle slope uses real grounded candidate")
	player.position = Vector3.ZERO
	arena.set("radius", 0.5)
	manager.call("_stand_the_trainer_aside", Vector3.FORWARD)
	_check(player.position.distance_to(Vector3.ZERO) < 0.01, "small arena does not stage beyond its radius")
	world.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)
