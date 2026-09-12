extends SceneTree

## COMBAT-3 production-body proof. The unit suite owns authority and manager
## rules; this smoke advances the real CharacterBody3D through its actual
## physics method and pins direction, distance, duration, and momentum stop.

const CREATURE_SCENE := preload("res://scenes/creatures/creature.tscn")
const CREATURE_BODY := preload("res://scripts/creatures/creature_body.gd")

var failures: Array[String] = []


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var body: CharacterBody3D = CREATURE_SCENE.instantiate() as CharacterBody3D
	body.set_script(CREATURE_BODY)
	root.add_child(body)
	await process_frame
	body.global_position = Vector3.ZERO
	body.velocity = Vector3.ZERO
	if not body.call("begin_combat_burst", Vector3(2.0, 0.0, -1.0), 3.0, 0.2, 71):
		failures.append("the production creature body refused a valid authorized burst")
	var expected := Vector3(2.0, 0.0, -1.0).normalized()
	var start := Vector2(body.global_position.x, body.global_position.z)
	var frames := 0
	while bool(body.call("combat_burst_active")) and frames < 30:
		await physics_frame
		frames += 1
	var finish := Vector2(body.global_position.x, body.global_position.z)
	var displacement := Vector3(finish.x - start.x, 0.0, finish.y - start.y)
	if absf(displacement.length() - 3.0) > 0.03:
		failures.append("burst travelled %.3fm instead of 3.0m" % displacement.length())
	if displacement.length() > 0.001 and displacement.normalized().dot(expected) < 0.999:
		failures.append("burst moved %s instead of stick direction %s" % [displacement, expected])
	if bool(body.call("combat_burst_active")):
		failures.append("burst remained active after its authored 0.2 seconds")
	if frames < 10 or frames > 14:
		failures.append("0.2s burst took %d physics frames at 60 Hz" % frames)
	await physics_frame
	var after_tail := Vector2(body.global_position.x, body.global_position.z)
	if after_tail.distance_to(finish) > 0.01:
		failures.append("burst retained %.3fm of unauthored momentum" % after_tail.distance_to(finish))
	body.queue_free()
	await process_frame
	if failures.is_empty():
		print("PASS: production creature bursts 3m in 0.2s along input and stops cleanly")
		quit(0)
		return
	for failure in failures:
		print("FAIL: %s" % failure)
	quit(1)
