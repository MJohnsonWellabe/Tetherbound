extends SceneTree

## Can the shared walker SEE what actually stops the body -- and can it get out
## of a pocket its own detour state has walked it into?
##
##   godot --headless --path . --script tests/smoke_stick_navigator_low_geometry.gd
##
## Two defects, both measured in the real world by other lanes and both living
## in `tests/helpers/stick_navigator.gd`, which every continuous harness in this
## repo walks with.
##
## THE FOOT-HEIGHT BLIND SPOT (W03-S08-FREEZE-0904 §3.4, CL-H14). `_free_space()`
## fired its lowest ray at 0.45 m. `player_controller.gd::STEP_HEIGHT` is 0.35,
## so anything whose top sits between those two numbers stops the body dead and
## is invisible to the probe. That is not a corner case: it is trunk flare and
## root, and it is what pinned S08-22. The probe's own spatial dump at the pin
## read `test_move` BLOCKED in all eight compass directions and three of eight
## CLEAR when the capsule was raised 0.4 m -- i.e. the geometry stopping the
## body topped out under 0.4 m, entirely below the lowest ray. So the walker
## read the flank as three metres of open air, committed a detour into it, and
## escaped only by noticing it had made no progress.
##
## The regression that guards the fix is the other half of this test, and it is
## the reason the constant could not just be lowered: the lowest ray must stay
## ABOVE `STEP_HEIGHT`, or every kerb, stair tread and bridge lip the body walks
## straight over starts reading as a wall and every outdoor detour thinks it is
## boxed in. Both cases are asserted here, from the same world.
##
## THE CONFINED LEG (W21-HARNESS-FIGHTS-0904, S06-50). One step after a
## workbench was placed at the player's feet, a `move_to` pinned the body inside
## a 2.7 m x 2.5 m box for its whole 711-second budget -- NOT frozen
## (`dead_travel_m` climbed to 1258 m while it jittered), and the very next
## `move_to` call, from that same position, walked away cleanly at ~3.9 m/s.
## A fresh walk escapes ground the previous walk could not leave, so what traps
## it is the walker's own accumulated detour state, not the terrain. Nothing in
## the file measured the LEG: `_stall` is only consulted outside a detour, and a
## committed side that oscillates inside a small box satisfies every
## progress check the detour machinery makes. This asserts the leg-level
## watchdog that ends it.
##
## Geometry is built here rather than loaded, for the same reason
## `tests/smoke_unstick.gd` and `tests/smoke_step_up.gd` build their own: the
## question is about the walker, not the meadow, and the world scene takes
## minutes to settle.

const PLAYER_SCENE := "res://scenes/player/player.tscn"
const NAVIGATOR := preload("res://tests/helpers/stick_navigator.gd")
const SETTLE_FRAMES := 30

## The obstacle that reproduces the blind spot: a slab whose top is at 0.40 m,
## above `player_controller.gd::STEP_HEIGHT` (0.35) so the body genuinely
## cannot walk over it, and below the old lowest probe ray (0.45) so the old
## probe could not see it.
const ROOT_TOP := 0.40
## The control: a kerb the body steps over. Below STEP_HEIGHT, so a probe that
## reports this as a wall has been lowered too far.
const KERB_TOP := 0.30
## Where the obstacles stand relative to the body, and how wide they are.
const OBSTACLE_AT := 1.2
const OBSTACLE_SPAN := 8.0

var _failures: Array[String] = []


func _init() -> void:
	_run()


func _run() -> void:
	await _low_geometry_case()
	await _kerb_case()
	await _confined_leg_case()

	if _failures.is_empty():
		print("\nstick navigator low-geometry smoke test passed")
		quit(0)
	else:
		print("")
		for f in _failures:
			print("  FAIL: %s" % f)
		quit(1)


## A root flare the body cannot enter must read as blocked, not as open air.
func _low_geometry_case() -> void:
	var world := _world("RootWorld")
	_box(world, "Floor", Vector3(60, 1, 60), Vector3(0, -0.5, 0))
	# A slab lying across -X, top at ROOT_TOP.
	_box(world, "RootFlare", Vector3(1.0, ROOT_TOP, OBSTACLE_SPAN),
		Vector3(-OBSTACLE_AT, ROOT_TOP * 0.5, 0))
	var player := _player(world, Vector3(0, 0.1, 0))
	var nav: RefCounted = NAVIGATOR.new(self, player, world.get_node(^"CameraRig"),
		func(_x: float, _y: float) -> void: pass)

	for i in SETTLE_FRAMES:
		await physics_frame

	var space: float = nav._free_space(Vector3.LEFT)
	var expected := OBSTACLE_AT - 0.5 - 0.4
	if space >= NAVIGATOR.BODY_WIDTH:
		_fail(("a %.2fm-tall root flare %.1fm to the west read as %.2fm of free space "
			+ "(BODY_WIDTH is %.2f, PROBE_REACH is %.1f). The body cannot enter it -- "
			+ "STEP_HEIGHT is 0.35 -- and the walker would commit a detour into it. "
			+ "This is CL-H14's blind spot.") % [
				ROOT_TOP, OBSTACLE_AT, space, NAVIGATOR.BODY_WIDTH, NAVIGATOR.PROBE_REACH])
	else:
		print("a %.2fm root flare %.1fm west reads as %.2fm of free space (wall is %.2fm away)"
			% [ROOT_TOP, OBSTACLE_AT, space, expected])

	# The far side has nothing in it: the probe must not have become blind the
	# other way, or "blocked" would mean nothing.
	var open: float = nav._free_space(Vector3.RIGHT)
	if open < NAVIGATOR.PROBE_REACH:
		_fail("open meadow to the east read as %.2fm, not the full %.1fm reach -- the probe is now seeing things that are not there"
			% [open, NAVIGATOR.PROBE_REACH])

	world.queue_free()
	await process_frame


## A kerb the body walks straight over must NOT read as a wall.
func _kerb_case() -> void:
	var world := _world("KerbWorld")
	_box(world, "Floor", Vector3(60, 1, 60), Vector3(0, -0.5, 0))
	_box(world, "Kerb", Vector3(1.0, KERB_TOP, OBSTACLE_SPAN),
		Vector3(-OBSTACLE_AT, KERB_TOP * 0.5, 0))
	var player := _player(world, Vector3(0, 0.1, 0))
	var nav: RefCounted = NAVIGATOR.new(self, player, world.get_node(^"CameraRig"),
		func(_x: float, _y: float) -> void: pass)

	for i in SETTLE_FRAMES:
		await physics_frame

	var space: float = nav._free_space(Vector3.LEFT)
	if space < NAVIGATOR.PROBE_REACH:
		_fail(("a %.2fm kerb -- under STEP_HEIGHT 0.35, the body walks over it -- read as %.2fm "
			+ "of free space instead of the full %.1fm reach. The probe has been lowered past "
			+ "the step height and every outdoor detour will now think it is boxed in.") % [
				KERB_TOP, space, NAVIGATOR.PROBE_REACH])
	else:
		print("a %.2fm kerb reads as the full %.1fm of free space, the way a steppable lip must"
			% [KERB_TOP, space])

	world.queue_free()
	await process_frame


## A leg that has stopped going anywhere must give up on its own state.
##
## This case does NOT build the Warrens mouth. It builds the MEASUREMENT: a body
## that walks at full speed, in whatever direction the navigator asks for, and
## can never leave a 2.7 m x 2.5 m box -- which is precisely what S06-50 logged
## for 44,100 frames (`dead_travel_m` 1,258 m, `input_context` `world`, 0 held).
## Modelling the confinement rather than the terrain is deliberate and is the
## honest choice here: the real site is a specific patch of the Burrow Warrens
## approach reached after twenty minutes of play, and the thing under test is
## not that patch -- it is whether ANY leg that has demonstrably stopped going
## anywhere can spend its entire budget doing so. Driven against a real
## `CharacterBody3D` in real geometry the walker escapes every synthetic pocket
## built for it (tried: a three-sided pocket, and an eleven-trunk thicket with
## sub-0.45 m flares); what it cannot currently do is notice.
func _confined_leg_case() -> void:
	var world := _world("ConfinedWorld")
	_box(world, "Floor", Vector3(80, 1, 80), Vector3(0, -0.5, 0))
	var rig := world.get_node(^"CameraRig")
	# A stub body: it moves when driven, at a real walking speed, and is clamped
	# into the box S06-50 was measured inside. Nothing else about it matters to
	# the navigator, which reads position, `locomotion_enabled()` and the world.
	var body_script := GDScript.new()
	body_script.source_code = """extends Node3D
var half := Vector2(1.35, 1.25)
var speed := 5.0
func locomotion_enabled() -> bool:
	return true
func drive(x: float, z: float) -> void:
	var step := Vector3(x, 0.0, z) * speed / 60.0
	var next := global_position + step
	global_position = Vector3(
		clampf(next.x, -half.x, half.x), global_position.y,
		clampf(next.z, -half.y, half.y))
"""
	body_script.reload()
	var body := Node3D.new()
	body.name = "ConfinedBody"
	body.set_script(body_script)
	world.add_child(body)
	body.global_position = Vector3.ZERO

	var travelled := {"m": 0.0}
	var last := {"at": Vector3.ZERO}
	var nav: RefCounted = NAVIGATOR.new(self, body, rig,
		func(x: float, y: float) -> void:
			body.call("drive", x, y)
			travelled["m"] += last["at"].distance_to(body.global_position)
			last["at"] = body.global_position
	)

	# Forty seconds of walking: two full watchdog windows and change.
	var budget := 2400
	var arrived: bool = await nav.walk_to(Vector3(0, 0, -60.0), budget, 2.0)
	var resets: int = nav.confined_resets()

	if arrived:
		_fail("the stub body reached a target outside its own clamp -- the case is broken, not the walker")
	elif travelled["m"] < 20.0:
		_fail("only %.1fm of stick travel in %d frames: the stub body is not being driven, so nothing here is measured"
			% [travelled["m"], budget])
	elif resets < 1:
		_fail(("%d frames (%.1fs) of walking, %.0fm of dead travel, and the body never left a "
			+ "2.7m x 2.5m box -- and the leg noticed %d times. This is S06-50: every check in "
			+ "the detour machine reads healthy while the walk goes nowhere, and only the frame "
			+ "budget ends it.") % [budget, budget / 60.0, travelled["m"], resets])
	else:
		print("confined for %.1fs with %.0fm of dead travel: the leg abandoned its own state %d time(s)"
			% [budget / 60.0, travelled["m"], resets])

	world.queue_free()
	await process_frame


func _world(world_name: String) -> Node3D:
	var world := Node3D.new()
	world.name = world_name
	root.add_child(world)

	# The stub rig: planar_basis() = identity, so +local-Z is world +Z.
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
