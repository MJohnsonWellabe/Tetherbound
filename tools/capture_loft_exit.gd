extends SceneTree

## The loft, from the vantages a first-time player actually occupies while
## trying to leave it (PT-03).
##
##   LOFT_TAG=before xvfb-run -a -s "-screen 0 1280x720x24" godot --path . \
##     --rendering-driver opengl3 --resolution 1280x720 \
##     --script tools/capture_loft_exit.gd
##
## Two testers — one of them the owner, twice — could not find the stairs out
## of the opening room. `archive/reports/docs-reviews-full/2026-08-15-full-blind-playtest/
## PLAYER_LOG.md` beats 16-20 record the shape of it: a 4x90 panorama from the
## get-up spot, no stairs seen, then a jump over the rail. So this renders that
## panorama plus the two frames the panorama's gaps hide, through the REAL
## interior camera profile the house swaps to on entry — not a free-flying
## beauty camera, because the whole finding is about what the third-person rig
## puts on screen from head height in a 5.4m-deep room.
##
## Frames land in shots/loft_exit/<LOFT_TAG>/. Nothing here is part of the
## survey; it exists so a before/after pair can be judged blind.

const SCENE := "res://scenes/world/meadows_playground.tscn"
const SETTLE_FRAMES := 60
const SHOT_FRAMES := 20

## Where the opening leaves the player standing once they get up: the bed
## marker shifted along the bed's length by sequence_director.gd's own
## BED_LIE_REACH, dropped to the loft floor. Derived here rather than read
## from the director because the director has already advanced past `wake` by
## the time anything renders.
const BED_LIE_REACH := 1.5

## A neutral standing look. The point of the panorama is what a player sees
## when they are NOT already aiming at the answer, so every frame shares one
## modest downward pitch instead of being aimed at the stair head.
const PITCH_DEG := -10.0

## [offset from the get-up spot, look direction, filename] — all house-local,
## all on the horizontal plane. The look direction only sets yaw; pitch is
## fixed above.
## Ordered by how much of the argument each frame carries, not by compass
## bearing: a run under llvmpipe is minutes per frame and may have to be cut
## short, and the three that matter are the ones a player facing the open half
## of the room actually gets.
const VANTAGES := [
	[Vector3.ZERO, Vector3(1, 0, 0), "02-wake-east"],
	[Vector3.ZERO, Vector3(0, 0, -1), "01-wake-north"],
	# The one bearing that points straight at the stair head from the get-up
	# spot. If the affordance works, 02 and 01 should already carry it and this
	# frame is only the confirmation; if this is the ONLY frame that reads, it
	# has not worked, because nothing tells a new player to face this way.
	[Vector3.ZERO, Vector3(3.6, 0, -2.8), "05-wake-toward-stairhead"],
	# Cut from the run, kept for the next person who needs them: the rest of
	# the tester's own 4x90 panorama, plus the loft's open east edge looking
	# north — the vantage they reached at beat 18 and still jumped from.
	# Restore any of these if you have the minutes; each frame is ~10 of them
	# under llvmpipe, on top of a ~24 minute scene boot.
	# [Vector3(2.0, 0, -1.7), Vector3(0, 0, -1), "06-loft-edge-north"],
	# [Vector3.ZERO, Vector3(0, 0, 1), "03-wake-south"],
	# [Vector3.ZERO, Vector3(-1, 0, 0), "04-wake-west"],
]


func _init() -> void:
	_run()


## Script constants are not reachable through `Object.get()`; the constant map
## is. Used rather than copying the house's numbers here, so a rebuilt room
## moves this capture with it.
func _house_const(house: Node3D, key: String) -> Variant:
	return house.get_script().get_script_constant_map().get(key)


func _run() -> void:
	var tag := OS.get_environment("LOFT_TAG")
	if tag == "":
		tag = "current"
	var out := "res://shots/loft_exit/%s" % tag
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out))

	var world: Node = (load(SCENE) as PackedScene).instantiate()
	root.add_child(world)
	for i in SETTLE_FRAMES:
		await process_frame

	# No HUD, no fade overlay, no "Get up" prompt: this is a question about the
	# room, and the opening's fade is a CanvasLayer that would otherwise render
	# six black frames.
	var stack: Array[Node] = [world]
	while not stack.is_empty():
		var node: Node = stack.pop_back()
		if node is CanvasLayer:
			(node as CanvasLayer).visible = false
		stack.append_array(node.get_children())

	var house: Node3D = world.get_node_or_null(^"GrandpaHouse") as Node3D
	var player: Node3D = world.get_node_or_null(^"Player") as Node3D
	var rig: Node3D = world.get_node_or_null(^"CameraRig") as Node3D
	if house == null or player == null or rig == null:
		push_error("loft capture needs the house, the player and the camera rig")
		quit(1)
		return

	# The interior profile the house itself applies on entry. Asked for
	# explicitly rather than trusted to the Area3D, because the player is
	# teleported here rather than walked in and body_entered may never fire.
	rig.call("set_target", player, _house_const(house, "INTERIOR_PROFILE"))

	# The loft floor's walking surface, from the house's own constants, so this
	# does not go stale the next time the room is rebuilt.
	var loft_y: float = float(_house_const(house, "FLOOR_H")) + 0.25
	var bed_local: Vector3 = house.to_local(house.call("marker", "bed"))
	var stand := Vector3(bed_local.x, loft_y + 0.05, bed_local.z + BED_LIE_REACH)

	for spec: Array in VANTAGES:
		var offset: Vector3 = spec[0]
		var at := stand + Vector3(offset.x, 0.0, offset.z)
		var dir: Vector3 = spec[1]
		var name: String = spec[2]

		player.global_position = house.to_global(at)
		if player is CharacterBody3D:
			(player as CharacterBody3D).velocity = Vector3.ZERO

		var forward := house.to_global(at + Vector3(dir.x, 0.0, dir.z)) - house.to_global(at)
		forward.y = 0.0
		forward = forward.normalized()
		# The rig hangs its camera along +Z of its own basis, so the camera
		# looks down -Z: yaw solves forward = (-sin y, 0, -cos y).
		var yaw := atan2(-forward.x, -forward.z)
		for i in SHOT_FRAMES:
			rig.set("yaw", yaw)
			rig.set("pitch", deg_to_rad(PITCH_DEG))
			await process_frame

		var image := root.get_texture().get_image()
		image.save_png("%s/%s.png" % [out, name])
		print("shot -> %s/%s.png" % [out, name])

	print("done: %d frames in %s" % [VANTAGES.size(), out])
	quit(0)
