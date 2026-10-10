extends SceneTree

## F26 performance: a wild creature resting on its floor skips the
## move_and_slide sweep (creature_body.gd `_rest_slide_skippable`), and
## anything that could move it brings the sweep straight back. A real body on
## a real StaticBody3D floor, ticked by the engine's own physics.

const CREATURE_SCENE := preload("res://scenes/creatures/creature.tscn")
const WILD := preload("res://scripts/creatures/wild_creature.gd")

var _failures: Array[String] = []


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var world := Node3D.new()
	root.add_child(world)
	var floor_body := StaticBody3D.new()
	var floor_shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(60.0, 1.0, 60.0)
	floor_shape.shape = box
	floor_body.add_child(floor_shape)
	floor_body.position = Vector3(0.0, -0.5, 0.0)
	world.add_child(floor_body)

	var wild := CREATURE_SCENE.instantiate() as CharacterBody3D
	wild.set_script(WILD)
	world.add_child(wild)
	_check(bool(wild.call("populate", "bramblebun", null)), "bramblebun populates")
	wild.global_position = Vector3(0.0, 0.05, 0.0)
	wild.set("home", wild.global_position)
	wild.set("_target", wild.global_position)
	wild.set("_pause_left", 1000.0)

	# Settle, then rest: most ticks skip the sweep, the body never drifts and
	# keeps its floor contact.
	await _ticks(30)
	var rest_at := wild.global_position
	var skipped := 0
	for i in 60:
		await physics_frame
		if int(wild.get("_rest_slide_skipped")) > 0:
			skipped += 1
	_check(skipped >= 45, "a resting wild skips most sweeps (%d/60)" % skipped)
	_check(skipped < 60, "a resting wild still re-sweeps every refresh_ticks")
	_check(wild.is_on_floor(), "a resting wild keeps floor contact")
	_check(wild.global_position.distance_to(rest_at) < 0.001, "a resting wild does not drift")

	# A reposition from outside (the director's reground, a teleport) re-sweeps:
	# lifted into the air, the body falls back to its floor.
	wild.global_position = rest_at + Vector3.UP * 2.0
	await _ticks(60)
	_check(absf(wild.global_position.y - rest_at.y) < 0.05,
		"a lifted wild falls back to the floor (y %.3f vs %.3f)" % [wild.global_position.y, rest_at.y])

	# A wander request moves it at once.
	wild.set("_pause_left", 0.0)
	wild.set("_target", rest_at + Vector3(5.0, 0.0, 0.0))
	await _ticks(60)
	_check(wild.global_position.distance_to(rest_at) > 0.5, "a wandering wild moves")

	# An impulse moves a resting wild.
	wild.set("_pause_left", 1000.0)
	await _ticks(60)
	var shoved_from := wild.global_position
	wild.call("add_impulse", Vector3.RIGHT, 6.0)
	await _ticks(20)
	_check(wild.global_position.distance_to(shoved_from) > 0.2, "an impulse moves a resting wild")

	# Engaged in a fight (the shared-wild host fight, a charge, a pinned tell),
	# the body sweeps every tick: the skip is a peaceful-only optimisation.
	await _ticks(60)
	var opponent := Node3D.new()
	world.add_child(opponent)
	opponent.global_position = wild.global_position + Vector3(0.0, 0.0, 3.0)
	wild.call("set_engaged", true, opponent)
	skipped = 0
	for i in 40:
		await physics_frame
		if bool(wild.get("rest_slide_skip_allowed")) or int(wild.get("_rest_slide_skipped")) > 0:
			skipped += 1
	_check(skipped == 0, "an engaged wild never skips a sweep (%d ticks did)" % skipped)
	wild.call("set_engaged", false)
	wild.set("_pause_left", 1000.0)
	await _ticks(30)

	# Disabled in config, every tick sweeps.
	var cfg: Dictionary = wild.call("physics_lod_config")
	cfg.rest_slide_skip.enabled = false
	await _ticks(30)
	skipped = 0
	for i in 30:
		await physics_frame
		if int(wild.get("_rest_slide_skipped")) > 0:
			skipped += 1
	_check(skipped == 0, "disabled config sweeps every tick (%d skipped)" % skipped)
	cfg.rest_slide_skip.enabled = true

	if _failures.is_empty():
		print("wild rest slide skip smoke passed")
		quit(0)
	else:
		for failure in _failures:
			push_error(failure)
		quit(1)


func _ticks(count: int) -> void:
	for i in count:
		await physics_frame


func _check(ok: bool, what: String) -> void:
	print(("PASS " if ok else "FAIL ") + what)
	if not ok:
		_failures.append(what)
