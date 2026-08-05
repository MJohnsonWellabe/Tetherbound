extends SceneTree

## Photograph a PRE-BUILT house's front door, shut and open, inside and out.
##
##   xvfb-run -a -s "-screen 0 1600x900x24" /opt/godot/godot --path . \
##     --rendering-driver opengl3 --resolution 1600x900 \
##     --script tools/preview_doors.gd -- grandpa
##
## `tools/preview_build.gd` proves the door works on a cottage this tool builds
## itself. That is not the same claim: the owner's report was about the houses
## the WORLD builds, which come from `data/config/settlement.json` through the
## scatter, stand on real terrain, and get their doors hung by
## `scripts/building/doors.gd` after the fact. Every one of those steps is a
## place a door can end up in the wrong house, at the wrong height, facing the
## wrong way — and all of them place successfully and assert green.
##
## IT ALSO PROBES THE DOORWAY WITH THE PHYSICS ENGINE, which a picture cannot do.
## The second half of "there's no way to open doors" was that the doorway wall's
## collision is one measured box, and a box has no hole in it: every cottage in
## the Meadows was sealed and no player had ever been inside one. A door swinging
## open in front of an invisible wall looks perfect in a screenshot.

const HEIGHTFIELD := preload("res://scripts/world/playground_heightfield.gd")
const RULES := preload("res://scripts/world/scatter_rules.gd")
const STATION := preload("res://scripts/building/station.gd")
const SCENE := "res://scenes/world/meadows_playground.tscn"
const OUT := "res://shots/_doors_%s.png"

## Terrain streams in, the scatter runs, and `doors.gd` waits for both.
const SETTLE_FRAMES := 200

## Metres in front of and behind the door for the camera and the probe.
const STANDOFF := 3.4
## Chest height. What a ray through a doorway should be able to reach.
const CHEST := 1.0
## Along the door's own X from its hinge, far enough to be in the pier rather
## than in the opening.
const PIER := 1.3


func _init() -> void:
	_run()


func _run() -> void:
	var site := "grandpa"
	for arg in OS.get_cmdline_user_args():
		site = str(arg)

	var world: Node = (load(SCENE) as PackedScene).instantiate()
	root.add_child(world)
	for i in SETTLE_FRAMES:
		await physics_frame

	var structures: Node3D = world.get_node_or_null(^"Structures") as Node3D
	var doors: Node = world.get_node_or_null(^"Doors")
	if structures == null or doors == null:
		print("doors FAIL: the scene has no Structures or no Doors")
		quit(1)
		return
	var hung: int = int(doors.call("hung"))
	print("hung %d door(s) in the settlement" % hung)
	if hung == 0:
		print("doors FAIL: the settlement's houses have no doors in them")
		quit(1)
		return

	# The door of the named site: the nearest one to that site's own origin.
	var origin := _origin_of(site)
	var door: Node = structures.call("nearest_station", origin, 14.0, STATION.BEHAVIOUR_DOOR)
	if door == null:
		print("doors FAIL: no door within 14m of site '%s'" % site)
		quit(1)
		return
	var at: Vector3 = door.call("where")
	var facing: float = float(door.get("facing"))
	# WHICH SIDE IS OUTSIDE is decided by the building, not by the door: the far
	# side from the room's own centre. A door's local +Z points into the house on
	# one wall and out of it on the opposite one, so guessing costs you a whole
	# session of frames taken from inside a wall.
	var through: Vector3 = Basis(Vector3.UP, facing) * Vector3(0.0, 0.0, 1.0)
	var outward: Vector3 = through if through.dot(at - origin) > 0.0 else -through
	var along: Vector3 = Basis(Vector3.UP, facing) * Vector3(1.0, 0.0, 0.0)
	print("%s's door at %.2f, %.2f, %.2f facing %.0f degrees" % [
		site, at.x, at.y, at.z, rad_to_deg(facing)
	])

	var player: CharacterBody3D = world.get_node_or_null(^"Player") as CharacterBody3D
	var camera: Camera3D = _camera(world)
	if camera == null:
		print("doors FAIL: no camera in the scene")
		quit(1)
		return

	var aim := at + Vector3.UP * 1.25
	for state: String in ["closed", "open"]:
		if state == "open":
			# Opened from OUTSIDE, through the same call the `interact` press uses.
			doors.call("open_nearest", at + outward * 1.2)
			door.call("snap")
		if player != null:
			_stand(player, at + outward * 1.9 + along * 0.9, at)
			for i in 10:
				await physics_frame
		camera.global_position = at + outward * STANDOFF + along * 1.6 + Vector3.UP * 2.0
		camera.look_at(aim, Vector3.UP)
		await _shoot("%s_outside_%s" % [site, state])

		if player != null:
			_stand(player, at - outward * 2.2 + along * 1.0, at)
			for i in 10:
				await physics_frame
		camera.global_position = at - outward * 2.6 + along * 0.4 + Vector3.UP * 1.55
		camera.look_at(aim, Vector3.UP)
		await _shoot("%s_inside_%s" % [site, state])

	# --- and the part a picture cannot answer ---------------------------------
	var space := (world as Node3D).get_world_3d().direct_space_state
	var outside := at + outward * 1.6 + Vector3.UP * CHEST
	var inside := at - outward * 1.6 + Vector3.UP * CHEST
	var through_doorway := _ray(space, outside, inside)
	var through_pier := _ray(space, outside + along * PIER, inside + along * PIER)
	print("with the door OPEN:")
	print("  through the doorway: %s" % ("BLOCKED — the doorway is sealed" if through_doorway else "clear"))
	print("  through the pier:    %s" % ("solid" if through_pier else "OPEN — the wall is not there"))

	doors.call("open_nearest", at + outward * 1.2)
	door.call("snap")
	await physics_frame
	var shut := _ray(space, outside, inside)
	print("with the door SHUT:")
	print("  through the doorway: %s" % ("blocked by the leaf" if shut else "CLEAR — the shut door stops nothing"))

	var ok := (not through_doorway) and through_pier and shut
	print("")
	print("doors: %s" % ("OK — the doorway is passable, the wall is not, and the shut door blocks it"
		if ok else "FAIL"))
	quit(0 if ok else 1)


func _ray(space: PhysicsDirectSpaceState3D, from: Vector3, to: Vector3) -> bool:
	var query := PhysicsRayQueryParameters3D.create(from, to)
	query.collide_with_areas = false
	query.collide_with_bodies = true
	return not space.intersect_ray(query).is_empty()


func _stand(player: Node3D, at: Vector3, look: Vector3) -> void:
	player.global_position = at + Vector3.UP * 0.1
	var flat := Vector3(look.x, at.y, look.z)
	if flat.distance_to(at) > 0.05:
		player.look_at(flat, Vector3.UP)


func _origin_of(site: String) -> Vector3:
	var sites: Dictionary = RULES.settlement().get("sites", {})
	var entry: Variant = sites.get(site, {})
	if not entry is Dictionary:
		return Vector3.ZERO
	var at: Array = (entry as Dictionary).get("origin", [0.0, 0.0])
	var field: RefCounted = HEIGHTFIELD.new()
	var x := float(at[0])
	var z := float(at[1])
	return Vector3(x, float(field.call("height_at", x, z)), z)


## A CAMERA OF OUR OWN, not the gameplay one.
##
## The first version of this took the scene's camera and set `top_level`. It came
## back with four frames of the village from a hundred metres away, because the
## camera hangs off a `SpringArm3D` and a spring arm rewrites its child's
## transform from an INTERNAL physics notification — which `set_physics_process(false)`
## does not touch. Nothing warns; the camera simply goes back where the rig wants
## it every frame. A fresh camera parented to the world has no rig to argue with.
##
## The HUD goes with it. Half the frame was movement telemetry and a minimap,
## which is right for the game and wrong for a photograph of a door.
func _camera(world: Node) -> Camera3D:
	for node in world.find_children("*", "CanvasLayer", true, false):
		(node as CanvasLayer).visible = false
	var rig := world.get_node_or_null(^"CameraRig")
	if rig != null:
		rig.set_process(false)
		rig.set_physics_process(false)
	var camera := Camera3D.new()
	camera.name = "DoorPreviewCamera"
	camera.fov = 55.0
	world.add_child(camera)
	camera.make_current()
	return camera


func _shoot(name: String) -> void:
	for i in 6:
		await process_frame
	await RenderingServer.frame_post_draw
	var shot := root.get_texture().get_image()
	if shot != null:
		shot.save_png(OUT % name)
		print("wrote %s" % (OUT % name))
