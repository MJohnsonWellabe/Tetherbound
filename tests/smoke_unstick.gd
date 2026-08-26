extends SceneTree

## Can a player who has been sealed in get out again -- and is a player merely
## leaning on a wall left alone?
##
##   godot --headless --path . --script tests/smoke_unstick.gd
##
## The defect this guards: Gate F segment S05 logged 1,019 consecutive route
## rows -- over eight minutes -- at exactly (91.39, -6.00, 821.68), region
## `corridor`, `input_context: world`, with the heading column swinging through
## more than twenty distinct values while x/z moved under two centimetres.
## Heading only changes when `_apply_movement` resolved a direction, so the
## stick was held for the whole eight minutes. Two walks in that segment stopped
## at that identical coordinate, and the harness's own `selfcheck_walk` froze
## the same way at (-161.03, 2.13, 286.01). Neither was recoverable without
## reloading the game. `player_controller.gd::_recover_if_entombed` is the fix.
##
## BOTH halves are the test, and the second is the more important one. A
## failsafe that moves a stuck player is easy; a failsafe that also moves a
## player who is simply walking into a cliff would be a worse bug than the one
## it replaces, because it would fire during ordinary play and teleport people
## mid-stride. So the wall case asserts the body is NOT recovered, by the
## controller's own counter rather than by looking at where it ended up.
##
## The seal has a LID. With a ceiling on it the lift fallback cannot resolve
## anything, so the only way this test can pass is the breadcrumb path -- the
## one that rewinds to ground the body actually stood on. That is deliberate:
## it is the path that can never grant access to somewhere the player had not
## already legitimately reached, and it is therefore the path worth pinning.
##
## Geometry is built here rather than loaded, for the same reason
## tests/smoke_step_up.gd builds its own: this question is about the controller,
## not the meadow, and the world scene takes minutes to settle.

const PLAYER_SCENE := "res://scenes/player/player.tscn"
const SETTLE_FRAMES := 30
## Long enough to lay several breadcrumbs (they are 2.5m apart and the walk
## speed is 5 m/s) before the seal closes.
const APPROACH_FRAMES := 180
## The failsafe waits 2.0s before it even looks, then rewinds. 6s of held input
## is three chances at it; if it has not fired by then it is not going to.
const SEALED_FRAMES := 360
## The wall case runs the same length, so "nothing happened" is measured over
## the same number of opportunities as "something did".
const WALL_FRAMES := 360
## Capsule is r=0.4. 0.55 leaves 0.15m of slack -- a pocket, not a room.
const SEAL_INNER := 0.55
const SEAL_HEIGHT := 2.0
## Recovery must land the body clear of the pocket. min_recovery_distance_m is
## 6.0; anything past a few metres proves it left, and the margin keeps this
## from tracking that constant exactly.
const ESCAPED_M := 3.0

var _failures: Array[String] = []


func _init() -> void:
	_run()


func _run() -> void:
	await _sealed_case()
	await _wall_case()

	if _failures.is_empty():
		print("\nunstick smoke test passed")
		quit(0)
	else:
		print("")
		for f in _failures:
			print("  FAIL: %s" % f)
		quit(1)


## Walk, then seal the body in on all six sides while the stick stays held.
func _sealed_case() -> void:
	var world := _world("SealWorld")
	_box(world, "Floor", Vector3(60, 1, 60), Vector3(0, -0.5, 0))
	var player := _player(world, Vector3(0, 0.1, 0))

	for i in SETTLE_FRAMES:
		await physics_frame

	Input.action_press("move_forward")
	for i in APPROACH_FRAMES:
		await physics_frame

	var sealed_at := player.global_position
	var walked := sealed_at.distance_to(Vector3(0, 0.1, 0))
	if walked < 5.0:
		_fail("the approach walk only covered %.2fm -- the body never got moving, so the seal proves nothing" % walked)
		Input.action_release("move_forward")
		world.queue_free()
		await process_frame
		return
	_seal(world, sealed_at)
	# The seal is built around the body's CURRENT position, so give the physics
	# server the frame it needs to see the new shapes before judging anything.
	await physics_frame

	if not player.call("_entombed_at", player.global_transform):
		_fail("the seal did not seal -- the body still has a way out, so this case cannot test anything")
		Input.action_release("move_forward")
		world.queue_free()
		await process_frame
		return

	for i in SEALED_FRAMES:
		await physics_frame
	Input.action_release("move_forward")

	var escaped := player.global_position.distance_to(sealed_at)
	var recoveries := int(player.call("unstick_count"))
	if escaped < ESCAPED_M:
		_fail("sealed in at %.2f, %.2f, %.2f and still there %.1fs later (moved %.2fm, %d recoveries) -- this is the S05 freeze" % [
			sealed_at.x, sealed_at.y, sealed_at.z, float(SEALED_FRAMES) / 60.0, escaped, recoveries
		])
	elif recoveries < 1:
		_fail("the body left the seal (%.2fm) without the failsafe running -- the seal leaked" % escaped)
	else:
		print("sealed in and recovered %.2fm clear after %d recovery" % [escaped, recoveries])

	world.queue_free()
	await process_frame


## Walk into a plain wall and hold. Nothing may recover this body.
func _wall_case() -> void:
	var world := _world("WallWorld")
	_box(world, "Floor", Vector3(60, 1, 60), Vector3(0, -0.5, 0))
	# Tall and wide: a cliff face, the thing a player leans on all the time.
	_box(world, "Cliff", Vector3(40, 8, 1), Vector3(0, 4.0, -6.0))
	var player := _player(world, Vector3(0, 0.1, 0))

	for i in SETTLE_FRAMES:
		await physics_frame

	Input.action_press("move_forward")
	for i in WALL_FRAMES:
		await physics_frame
	Input.action_release("move_forward")

	var at := player.global_position
	var recoveries := int(player.call("unstick_count"))
	if at.z > -4.0:
		_fail("the body never reached the cliff (z=%.2f) -- the wall case tested nothing" % at.z)
	elif recoveries != 0:
		_fail("leaning on a cliff triggered %d recovery -- the failsafe fires during ordinary play" % recoveries)
	else:
		print("leant on a cliff for %.1fs at z=%.2f and was left alone" % [float(WALL_FRAMES) / 60.0, at.z])

	world.queue_free()
	await process_frame


func _world(world_name: String) -> Node3D:
	var world := Node3D.new()
	world.name = world_name
	root.add_child(world)

	# The stub rig: planar_basis() = identity, so pressing move_forward walks -Z.
	var rig_script := GDScript.new()
	rig_script.source_code = "extends Node3D\nfunc planar_basis() -> Basis:\n\treturn Basis.IDENTITY\n"
	rig_script.reload()
	var rig := Node3D.new()
	rig.name = "CameraRig"
	rig.set_script(rig_script)
	world.add_child(rig)
	return world


func _player(world: Node3D, at: Vector3) -> CharacterBody3D:
	var player := (load(PLAYER_SCENE) as PackedScene).instantiate() as CharacterBody3D
	player.set("camera_rig_path", NodePath("../CameraRig"))
	world.add_child(player)
	player.position = at
	return player


## Six sides, built around a body that is already standing there.
func _seal(world: Node3D, centre: Vector3) -> void:
	var t := 0.5
	var span := (SEAL_INNER + t) * 2.0
	var mid := centre + Vector3(0, SEAL_HEIGHT * 0.5, 0)
	_box(world, "SealNorth", Vector3(span, SEAL_HEIGHT, t), mid + Vector3(0, 0, -(SEAL_INNER + t * 0.5)))
	_box(world, "SealSouth", Vector3(span, SEAL_HEIGHT, t), mid + Vector3(0, 0, SEAL_INNER + t * 0.5))
	_box(world, "SealWest", Vector3(t, SEAL_HEIGHT, span), mid + Vector3(-(SEAL_INNER + t * 0.5), 0, 0))
	_box(world, "SealEast", Vector3(t, SEAL_HEIGHT, span), mid + Vector3(SEAL_INNER + t * 0.5, 0, 0))
	_box(world, "SealLid", Vector3(span, t, span), centre + Vector3(0, SEAL_HEIGHT + t * 0.5, 0))


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
