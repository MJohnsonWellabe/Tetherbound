extends SceneTree

## P2-020: a creature standing still joins the grass field's clearing group
## with a radius scaled from its body (creature_body.gd `_update_grass_clear`),
## and leaves it on its first moving frame.

const CREATURE_SCENE := preload("res://scenes/creatures/creature.tscn")
const WILD := preload("res://scripts/creatures/wild_creature.gd")
const BODY := preload("res://scripts/creatures/creature_body.gd")
const GRASS_FIELD := preload("res://scripts/world/grass_field.gd")

var _failures: Array[String] = []


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var world := Node3D.new()
	root.add_child(world)
	var floor_body := StaticBody3D.new()
	var floor_shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(80.0, 1.0, 80.0)
	floor_shape.shape = box
	floor_body.add_child(floor_shape)
	floor_body.position = Vector3(0.0, -0.5, 0.0)
	world.add_child(floor_body)
	var trainer := Node3D.new()
	world.add_child(trainer)
	trainer.position = Vector3(30.0, 0.0, 0.0)  # far enough that a peaceful wild keeps wandering

	# A settled grass ring: the camera has stopped before the creature settles.
	var camera := Camera3D.new()
	world.add_child(camera)
	camera.global_position = Vector3(0.0, 4.0, 8.0)
	camera.make_current()
	var field := GRASS_FIELD.new()
	field.call("configure_profile", {"enabled": false}, [], PackedVector3Array())
	world.add_child(field)
	field.set("_material", ShaderMaterial.new())
	field.set("_camera", camera)
	field.call("_process", 0.016)
	var cfg: Dictionary = BODY.grass_clear_config()
	var wild := CREATURE_SCENE.instantiate() as CharacterBody3D
	wild.set_script(WILD)
	world.add_child(wild)
	_check(bool(wild.call("populate", "bramblebun", trainer)), "bramblebun populates")
	wild.set("aggressive", false)
	wild.global_position = Vector3(0.0, 0.05, 0.0)
	wild.set("home", wild.global_position)
	wild.set("_target", wild.global_position)
	wild.set("_pause_left", 1000.0)

	var settle_ticks := int(ceil(float(cfg.get("settle_s", 0.6)) * Engine.physics_ticks_per_second)) + 20
	for i in settle_ticks:
		await physics_frame
	_check(wild.is_in_group(BODY.GRASS_CLEAR_GROUP), "an idle creature joins the grass clearing")
	var radius := float(wild.get_meta(BODY.GRASS_CLEAR_RADIUS_META, 0.0))
	var expected := float(wild.call("body_radius")) * float(cfg.get("radius_scale", 1.6))
	_check(is_equal_approx(radius, expected), "its clearing radius is body_radius * radius_scale (%.2f vs %.2f)" % [radius, expected])
	# The ring has not stepped since the camera stopped; the patch still lands.
	field.call("_process", 0.016)
	var built: PackedVector3Array = field.get("_built")
	var has_patch := false
	for spot: Vector3 in built:
		if Vector2(spot.x - wild.global_position.x, spot.y - wild.global_position.z).length() < 0.5:
			has_patch = true
	_check(has_patch, "a creature settling after the camera stopped still gets its grass patch (%d footprints)" % built.size())

	wild.set("_pause_left", 0.0)
	wild.set("_target", wild.global_position + Vector3(6.0, 0.0, 0.0))
	var left := false
	for i in 120:
		await physics_frame
		if not wild.is_in_group(BODY.GRASS_CLEAR_GROUP):
			left = true
			break
	_check(left, "a creature that starts walking leaves the grass clearing")

	if _failures.is_empty():
		print("creature grass clear smoke passed")
		quit(0)
	else:
		for failure in _failures:
			push_error(failure)
		quit(1)


func _check(ok: bool, what: String) -> void:
	print(("PASS " if ok else "FAIL ") + what)
	if not ok:
		_failures.append(what)
