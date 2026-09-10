extends SceneTree

## Regression for a creature standing on the trainer being carried across a
## debug/realm teleport as though the trainer were a moving platform.
##
##   godot --headless --path . --script tests/smoke_creature_platform_transfer.gd

const CREATURE_SCENE := preload("res://scenes/creatures/creature.tscn")
const CREATURE_BODY := preload("res://scripts/creatures/creature_body.gd")

var _failures: Array[String] = []
var _negative_control := false


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	_negative_control = OS.get_cmdline_user_args().has("--negative-control")
	var host := Node3D.new()
	root.add_child(host)
	var trainer := CharacterBody3D.new()
	trainer.name = "TeleportedTrainer"
	trainer.collision_layer = 1
	trainer.collision_mask = 1
	var trainer_shape := CollisionShape3D.new()
	var trainer_capsule := CapsuleShape3D.new()
	trainer_capsule.radius = 0.4
	trainer_capsule.height = 1.8
	trainer_shape.shape = trainer_capsule
	trainer_shape.position.y = 0.9
	trainer.add_child(trainer_shape)
	host.add_child(trainer)

	var creature := CREATURE_SCENE.instantiate() as CharacterBody3D
	creature.set_script(CREATURE_BODY)
	host.add_child(creature)
	creature.call("setup", "mosshock")
	if _negative_control:
		# Restore CharacterBody3D's engine default after production `_ready()` so
		# this same physical fixture proves the old behavior really carries.
		creature.platform_floor_layers = 0xFFFFFFFF
	creature.global_position = Vector3(0.0, 1.8, 0.0)
	for frame in 30:
		await physics_frame
	if not creature.is_on_floor():
		_failures.append("fixture creature never settled on the trainer capsule")
	var before := creature.global_position
	trainer.global_position += Vector3(100.0, 25.0, 80.0)
	trainer.velocity = Vector3.ZERO
	trainer.reset_physics_interpolation()
	for frame in 5:
		await physics_frame
	var carried := Vector2(creature.global_position.x - before.x,
		creature.global_position.z - before.z).length()
	print("CREATURE PLATFORM TRANSFER before=%s after=%s carried_xz=%.3f floor_layers=%d" % [
		before, creature.global_position, carried, creature.platform_floor_layers])
	if _negative_control:
		print("CREATURE PLATFORM TRANSFER NEGATIVE CONTROL expected_carry=true")
		if carried < 50.0:
			_failures.append("negative control did not reproduce trainer platform carry (%.2fm)" % carried)
	elif carried > 1.0:
		_failures.append("trainer teleport carried creature %.2fm despite unchanged creature intent" % carried)
	if _failures.is_empty():
		print("CREATURE PLATFORM TRANSFER OK")
		quit(0)
	else:
		for failure in _failures:
			printerr("FAIL: %s" % failure)
		quit(1)
