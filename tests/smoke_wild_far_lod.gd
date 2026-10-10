extends SceneTree

## F26 performance: a peaceful wild far from every trainer steps its physics
## every `interval_ticks` with the elapsed time (wild_creature.gd
## `_far_lod_hold`). It must cover the same ground as a full-rate body, and
## step every tick again once a trainer is near.

const CREATURE_SCENE := preload("res://scenes/creatures/creature.tscn")
const WILD := preload("res://scripts/creatures/wild_creature.gd")

var _failures: Array[String] = []
var _world: Node3D


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	_world = Node3D.new()
	root.add_child(_world)
	var floor_body := StaticBody3D.new()
	var floor_shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(400.0, 1.0, 400.0)
	floor_shape.shape = box
	floor_body.add_child(floor_shape)
	floor_body.position = Vector3(0.0, -0.5, 0.0)
	_world.add_child(floor_body)
	var trainer := Node3D.new()
	_world.add_child(trainer)

	var cfg: Dictionary = WILD.physics_lod_config()
	var far_cfg: Dictionary = cfg.far_wild_tick
	var far_at := Vector3(float(far_cfg.distance_m) + 30.0, 0.05, 0.0)
	var lod := _wild(trainer, far_at)
	await _ticks(30)
	var lod_from := lod.global_position
	_walk(lod, lod_from + Vector3(6.0, 0.0, 0.0))
	var lod_steps := 0
	var full_steps := 0
	var lod_was := lod.global_position
	for i in 120:
		await physics_frame
		if not lod.global_position.is_equal_approx(lod_was):
			lod_steps += 1
		lod_was = lod.global_position
	var lod_moved := Vector2(lod.global_position.x - lod_from.x, lod.global_position.z - lod_from.z).length()
	_check(lod_steps > 0 and lod_steps <= 120 / int(far_cfg.interval_ticks) + 2,
		"a far wild steps about every %d ticks (%d steps in 120)" % [int(far_cfg.interval_ticks), lod_steps])
	_check(lod_moved > 2.0, "a far wild still wanders (%.2f m in 120 ticks)" % lod_moved)

	# Reference: the same walk at full rate over the same time.
	cfg.far_wild_tick.enabled = false
	var ref := _wild(trainer, far_at + Vector3(0.0, 0.0, -20.0))
	await _ticks(30)
	var ref_from := ref.global_position
	_walk(ref, ref_from + Vector3(6.0, 0.0, 0.0))
	var ref_was := ref.global_position
	for i in 120:
		await physics_frame
		if not ref.global_position.is_equal_approx(ref_was):
			full_steps += 1
		ref_was = ref.global_position
	var ref_moved := Vector2(ref.global_position.x - ref_from.x, ref.global_position.z - ref_from.z).length()
	_check(full_steps >= 100, "with the LOD disabled a wild steps every tick (%d)" % full_steps)
	_check(absf(lod_moved - ref_moved) < 0.6,
		"far LOD covers the same ground (%.2f m vs %.2f m)" % [lod_moved, ref_moved])
	cfg.far_wild_tick.enabled = true

	# A trainer arriving brings the body back to every tick within recheck_ticks.
	trainer.global_position = lod.global_position + Vector3(-20.0, 0.0, 0.0)
	_walk(lod, lod.global_position + Vector3(0.0, 0.0, 6.0))
	await _ticks(int(far_cfg.recheck_ticks) + 2)
	lod_steps = 0
	lod_was = lod.global_position
	for i in 30:
		await physics_frame
		if not lod.global_position.is_equal_approx(lod_was):
			lod_steps += 1
		lod_was = lod.global_position
	_check(lod_steps >= 25, "a wild near a trainer steps every tick (%d/30)" % lod_steps)

	if _failures.is_empty():
		print("wild far LOD smoke passed")
		quit(0)
	else:
		for failure in _failures:
			push_error(failure)
		quit(1)


func _wild(trainer: Node3D, at: Vector3) -> CharacterBody3D:
	var wild := CREATURE_SCENE.instantiate() as CharacterBody3D
	wild.set_script(WILD)
	_world.add_child(wild)
	_check(bool(wild.call("populate", "bramblebun", trainer)), "bramblebun populates")
	wild.set("aggressive", false)
	wild.global_position = at
	wild.set("home", at)
	wild.set("_target", at)
	wild.set("_pause_left", 1000.0)
	return wild


func _walk(wild: Node3D, to: Vector3) -> void:
	wild.set("_pause_left", 0.0)
	wild.set("_target", to)


func _ticks(count: int) -> void:
	for i in count:
		await physics_frame


func _check(ok: bool, what: String) -> void:
	print(("PASS " if ok else "FAIL ") + what)
	if not ok:
		_failures.append(what)
