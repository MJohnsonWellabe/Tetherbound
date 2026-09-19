extends SceneTree

## A single knockback must decay, not feed its previous contribution back into
## locomotion and accelerate a fighter while neither side supplies new input.
const SCENE := preload("res://scenes/creatures/creature.tscn")
const BODY := preload("res://scripts/creatures/creature_body.gd")
const ARENA := preload("res://scripts/combat/combat_arena.gd")

func _init() -> void:
	_run.call_deferred()

func _run() -> void:
	var body: CharacterBody3D = SCENE.instantiate()
	body.set_script(BODY)
	root.add_child(body)
	await physics_frame
	body.velocity = Vector3.ZERO
	body.call("add_impulse", Vector3.RIGHT, 6.0)
	var maximum := 0.0
	for frame in 60:
		await physics_frame
		maximum = maxf(maximum, Vector2(body.velocity.x, body.velocity.z).length())
	var free_tail := Vector2(body.velocity.x, body.velocity.z).length()
	var arena := ARENA.new()
	root.add_child(arena)
	body.arena = arena
	body.global_position = Vector3(arena.radius - 0.001, 0, 0)
	body.velocity = Vector3.ZERO
	body.set("_impulse", Vector3.ZERO)
	body.call("add_impulse", Vector3(1, 0, 1), 6.0)
	var edge_maximum := 0.0
	for frame in 60:
		await physics_frame
		edge_maximum = maxf(edge_maximum, Vector2(body.velocity.x, body.velocity.z).length())
	var edge_tail := Vector2(body.velocity.x, body.velocity.z).length()
	body.queue_free()
	arena.queue_free()
	await process_frame
	print("Single 6m/s impulse: peak horizontal speed %.3fm/s" % maximum)
	print("Arena diagonal 6m/s impulse: peak horizontal speed %.3fm/s" % edge_maximum)
	if maximum < 4.5 or maximum > 6.01 or edge_maximum < 2.0 or edge_maximum > 6.01 \
			or free_tail > 0.01 or edge_tail > 0.01:
		print("FAIL: impulse missing, amplified, or retained a locomotion tail (%.4f, %.4f)" % [free_tail, edge_tail])
		quit(1)
	else:
		print("PASS: single impulse does not amplify itself")
		quit(0)
