extends SceneTree

## Can the trainer step up a kerb-height ledge -- and NOT climb a wall?
##
##   godot --headless --path . --script tests/smoke_step_up.gd
##
## The step-up assist (player_controller.gd::_try_step_up) exists because a
## CharacterBody3D cannot climb even a 30cm ledge on its own -- the loft bug
## grandpa_house.gd worked around by shortening a beam, and the traversal
## audit's first fix. Both halves matter equally here: a ledge the player
## sticks on reads as broken, and a BARRIER the player can suddenly climb
## breaks every gate the world was sized around. So this walks into both.
##
## Geometry is built here rather than loaded: the world scene takes minutes to
## settle and this question is about the controller, not the meadow. A stub
## camera rig supplies the identity planar basis `_apply_movement` needs to
## turn stick input into motion at all.

const PLAYER_SCENE := "res://scenes/player/player.tscn"
const STEP_HEIGHT := 0.3
const WALL_HEIGHT := 2.0
const SETTLE_FRAMES := 30
const WALK_FRAMES := 300

var _failures: Array[String] = []


func _init() -> void:
	_run()


func _run() -> void:
	var world := Node3D.new()
	world.name = "StepWorld"
	root.add_child(world)

	# The stub rig: planar_basis() = identity, so pressing move_forward walks -Z.
	var rig_script := GDScript.new()
	rig_script.source_code = "extends Node3D\nfunc planar_basis() -> Basis:\n\treturn Basis.IDENTITY\n"
	rig_script.reload()
	var rig := Node3D.new()
	rig.name = "CameraRig"
	rig.set_script(rig_script)
	world.add_child(rig)

	_box(world, "Floor", Vector3(40, 1, 40), Vector3(0, -0.5, 0))
	# A kerb-height platform running from the step edge to the wall, so the
	# walk crosses UP it and then continues along its top.
	_box(world, "Step", Vector3(6, STEP_HEIGHT, 6), Vector3(0, STEP_HEIGHT * 0.5, -5.0))
	# The barrier at the far side: 1.7m of rise from the step top. If the
	# assist ever climbs this, every fence and gate in the game is in doubt.
	_box(world, "Wall", Vector3(6, WALL_HEIGHT, 0.5), Vector3(0, WALL_HEIGHT * 0.5, -8.25))

	var player := (load(PLAYER_SCENE) as PackedScene).instantiate() as CharacterBody3D
	player.set("camera_rig_path", NodePath("../CameraRig"))
	world.add_child(player)
	player.position = Vector3(0, 0.1, 0)

	for i in SETTLE_FRAMES:
		await physics_frame

	Input.action_press("move_forward")
	var highest := 0.0
	for i in WALK_FRAMES:
		await physics_frame
		highest = maxf(highest, player.global_position.y)
	Input.action_release("move_forward")

	var at := player.global_position
	if at.z > -2.5:
		_fail("the trainer never crossed the step edge (stuck at z=%.2f) -- the ledge is still a wall" % at.z)
	elif at.y < STEP_HEIGHT - 0.1:
		_fail("the trainer reached z=%.2f without standing on the step (y=%.2f) -- did the step exist?" % [at.z, at.y])
	else:
		print("stepped up the %.2fm ledge and walked its top (y=%.2f at z=%.2f)" % [STEP_HEIGHT, at.y, at.z])

	if at.z < -8.0:
		_fail("the trainer passed the wall line (z=%.2f) -- the barrier did not hold" % at.z)
	elif highest > STEP_HEIGHT + 1.0:
		_fail("the trainer reached y=%.2f against a %.1fm wall -- the assist is climbing barriers" % [highest, WALL_HEIGHT])
	else:
		print("the %.1fm wall held (stopped at z=%.2f, highest y=%.2f)" % [WALL_HEIGHT, at.z, highest])

	if _failures.is_empty():
		print("\nstep-up smoke test passed")
		quit(0)
	else:
		for f in _failures:
			print("  FAIL: %s" % f)
		quit(1)


func _box(parent: Node, box_name: String, size: Vector3, at: Vector3) -> void:
	var body := StaticBody3D.new()
	body.name = box_name
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	shape.shape = box
	body.add_child(shape)
	parent.add_child(body)
	body.position = at


func _fail(message: String) -> void:
	_failures.append(message)
