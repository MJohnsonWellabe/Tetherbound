extends SceneTree

## Does the third-person camera's spring arm sweep a shape, or a hairline?
##
##   godot --headless --path . --script tests/smoke_camera_probe.gd
##
## A blind playtest reported the camera collapsing into the trainer's head
## indoors. `scenes/world/meadows_playground.tscn` set the rig's `spring_length`
## and `margin` but nothing anywhere ever assigned its `shape`, and a
## SpringArm3D with no shape falls back to a single, infinitely thin raycast
## down its own centre line. That has two failure modes, both of which the
## playtest saw as one symptom: the ray slips between furniture edges and the
## camera is then drawn inside them, and when the ray does hit something nearer
## than `margin` the arm collapses to about nothing.
##
## Neither is reachable by tuning distance or margin, so neither would be caught
## by a test that only read the numbers back. This asserts the behaviour that
## separates the two casts: an obstacle placed BESIDE the centre line, which a
## hairline ray passes clean through and a swept ball stops on.
##
## The second half is what stops this passing vacuously. The same geometry is
## re-run with the shape cleared, and the arm is required NOT to see it. If that
## ever starts detecting, the obstacle has drifted onto the centre line and the
## first half is no longer testing shape-casting at all.

const RIG_SCRIPT := "res://scripts/player/camera_rig.gd"
const SCENE := "res://scenes/world/meadows_playground.tscn"

## The arm casts along its own +Z (SpringArm3D::process_spring), so with an
## unrotated rig everything below is laid out down +Z.
const ARM_LENGTH := 5.0
const OBSTACLE_AT_Z := 3.0

## Far enough off the centre line that a zero-radius ray misses it outright,
## near enough that a 0.25m ball does not. Deliberately thin in x for the same
## reason: this is a chair back seen edge-on, which is the shape the playtest
## walked the camera through.
const OBSTACLE_OFFSET_X := 0.2
const OBSTACLE_SIZE := Vector3(0.1, 3.0, 0.4)

const SETTLE_FRAMES := 8

var _failures: Array[String] = []
var _world: Node3D = null


func _init() -> void:
	_run()


func _run() -> void:
	_world = Node3D.new()
	root.add_child(_world)
	# A frame before anything is positioned: `_init` runs before the tree is
	# fully up, and `global_position` on a node whose parent is not yet inside
	# it errors and silently does nothing.
	await physics_frame
	_spawn_obstacle()
	for i in SETTLE_FRAMES:
		await physics_frame

	await _the_arm_stops_on_something_beside_its_centre_line()
	await _the_same_arm_with_no_shape_walks_straight_through()
	_the_scene_gets_a_shape_without_anyone_setting_one_by_hand()
	_report()


# --- the cases --------------------------------------------------------------


func _the_arm_stops_on_something_beside_its_centre_line() -> void:
	var arm := _spawn_arm()
	for i in SETTLE_FRAMES:
		await physics_frame

	if arm.shape == null:
		_fail("camera_rig.gd::_ready() left the spring arm with no shape; it is still a hairline raycast")
	elif arm.get_hit_length() >= arm.spring_length:
		_fail("the arm reports its full %.2fm with a solid object 0.2m off its centre line at %.1fm; "
			% [arm.get_hit_length(), OBSTACLE_AT_Z]
			+ "it is not sweeping the shape")
	else:
		print("shape cast: arm shortened to %.2fm of %.2fm on an obstacle beside the centre line"
			% [arm.get_hit_length(), arm.spring_length])
	arm.queue_free()
	await physics_frame


## Proves the case above is about the shape and not about the obstacle simply
## being in the way. Clearing `shape` is the exact state the game shipped in.
func _the_same_arm_with_no_shape_walks_straight_through() -> void:
	var arm := _spawn_arm()
	arm.shape = null
	for i in SETTLE_FRAMES:
		await physics_frame

	if arm.get_hit_length() < arm.spring_length:
		_fail("a shapeless arm ALSO stopped on the obstacle (%.2fm of %.2fm); the obstacle has drifted "
			% [arm.get_hit_length(), arm.spring_length]
			+ "onto the centre line and this file is no longer testing shape-casting")
	else:
		print("hairline cast: shapeless arm reports its full %.2fm, as it did in the shipped build"
			% arm.get_hit_length())
	arm.queue_free()
	await physics_frame


## The rig the player actually gets. The fix lives in `_ready()` rather than in
## the .tscn, so a scene that never gains a `shape` property is still correct —
## what must hold is that the booted rig has one.
func _the_scene_gets_a_shape_without_anyone_setting_one_by_hand() -> void:
	var packed: PackedScene = load(SCENE)
	if packed == null:
		_fail("could not load %s" % SCENE)
		return
	var state := packed.get_state()
	for i in state.get_node_count():
		if str(state.get_node_name(i)) != "CameraRig":
			continue
		for p in state.get_node_property_count(i):
			if str(state.get_node_property_name(i, p)) == "shape":
				print("note: %s now sets CameraRig.shape itself" % SCENE)
				return
		print("%s sets no CameraRig.shape; camera_rig.gd::_ready() is the only thing that can" % SCENE)
		return
	_fail("no CameraRig node in %s; this test is measuring nothing" % SCENE)


# --- building the world -----------------------------------------------------


func _spawn_arm() -> SpringArm3D:
	var arm := SpringArm3D.new()
	arm.set_script(load(RIG_SCRIPT))
	_world.add_child(arm)
	# After add_child, so `_ready` (which sets spring_length from movement.json)
	# has already run and this is the length the assertions compare against.
	arm.spring_length = ARM_LENGTH
	arm.global_position = Vector3.ZERO
	arm.global_rotation = Vector3.ZERO
	return arm


func _spawn_obstacle() -> void:
	var box := BoxShape3D.new()
	box.size = OBSTACLE_SIZE
	var shape := CollisionShape3D.new()
	shape.shape = box
	var body := StaticBody3D.new()
	body.add_child(shape)
	_world.add_child(body)
	body.global_position = Vector3(OBSTACLE_OFFSET_X, 0.0, OBSTACLE_AT_Z)


# --- reporting --------------------------------------------------------------


func _fail(message: String) -> void:
	_failures.append(message)


func _report() -> void:
	print("")
	if _failures.is_empty():
		print("camera probe: OK — the spring arm sweeps a ball, not a hairline.")
		quit(0)
		return
	for line in _failures:
		print("camera probe FAIL: %s" % line)
	quit(1)
