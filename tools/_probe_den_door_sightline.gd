extends SceneTree

## CONTENT-0828B. Is the branch door actually VISIBLE from where the player
## fights the guardian?
##
##   godot --headless --path . --script tools/_probe_den_door_sightline.gd
##
## (Headless is correct here: this renders nothing, it only measures. The
## `--headless` hang `docs/AGENT_WORKFLOW.md` warns about is specifically
## `--headless` combined with a real rendering driver.)
##
## WHY THIS EXISTS. CONTENT-0828's claim for the Warrens payoff is that the
## fight becomes "a fight for what is through the door" -- that what the player
## can see across the den WHILE THE ALPHA IS STILL ALIVE is a sealed way on
## with something lit behind it. Its own report then flagged the evidence as
## not supporting that: "01-den-alpha-and-door does not deliver its own brief.
## The stand was chosen to put the alpha and the lit door in one photograph,
## and at the angle the cave actually has, the door is out of frame. The claim
## that the door is visible from the den floor rests on 03, which is a head-on
## stand." A head-on stand proves the door looks like a door. It does not prove
## anybody fighting the guardian ever looks at it.
##
## So measure it instead of photographing it again. From each stand a player
## actually occupies while fighting -- the den doorway they enter by, and a
## ring around the guardian at engage range -- this reports the angle between
## "facing the guardian" and "facing the door", against the 70-degree camera
## the game ships. Anything past half of that is off-screen while the player is
## looking at what is trying to kill them.

const SCENE := "res://scenes/world/meadows_playground.tscn"
const SETTLE_FRAMES := 120
## `camera_rig.gd`'s own field of view. Half of it is the off-screen boundary.
const FOV_DEG := 70.0
const EYE_H := 1.6


func _init() -> void:
	_run()


func _run() -> void:
	var packed: PackedScene = load(SCENE)
	if packed == null:
		push_error("could not load %s" % SCENE)
		quit(1)
		return
	var world: Node = packed.instantiate()
	root.add_child(world)
	for i in SETTLE_FRAMES:
		await physics_frame

	var warrens: Node3D = world.get_node_or_null(^"BurrowWarrens") as Node3D
	if warrens == null:
		push_error("no BurrowWarrens in the scene")
		quit(1)
		return
	var door: Node3D = warrens.get_node_or_null(^"VaultDoor") as Node3D
	if door == null:
		push_error("no VaultDoor -- it is already open, or the node was renamed")
		quit(1)
		return
	var guardian: Node3D = warrens.call("guardian") as Node3D
	if guardian == null or not is_instance_valid(guardian):
		push_error("no guardian placed; there is no fight to measure")
		quit(1)
		return

	var den: Vector3 = warrens.call("marker", "den")
	var g_at := guardian.global_position
	var d_at := door.global_position

	print("den centre     %.1f, %.1f" % [den.x, den.z])
	print("guardian       %.1f, %.1f" % [g_at.x, g_at.z])
	print("branch door    %.1f, %.1f" % [d_at.x, d_at.z])
	print("camera fov %.0f deg, so anything past %.0f deg off the guardian is off-screen"
		% [FOV_DEG, FOV_DEG * 0.5])
	print("")

	# The stands a player is actually at. The hall doorway is where they come
	# in; the ring is engage range around the guardian, which is where the
	# fight is fought.
	var stands: Array = [["hall doorway", warrens.to_global(Vector3(0.0, 0.0, 33.0))]]
	for step in 8:
		var angle := TAU * float(step) / 8.0
		stands.append(["fight ring %3.0f deg" % rad_to_deg(angle),
			g_at + Vector3(cos(angle), 0.0, sin(angle)) * 5.0])

	var space := (world.get_node_or_null(^"Player") as Node3D).get_world_3d().direct_space_state
	var on_screen := 0
	var measured := 0
	for stand: Array in stands:
		var at: Vector3 = stand[1]
		at.y = float(warrens.call("built_floor_height_at", at.x, at.z))
		if is_nan(at.y):
			print("%-20s  not on the den floor; skipped" % str(stand[0]))
			continue
		at.y += EYE_H
		var to_guardian := Vector2(g_at.x - at.x, g_at.z - at.z)
		var to_door := Vector2(d_at.x - at.x, d_at.z - at.z)
		if to_guardian.length() < 0.1 or to_door.length() < 0.1:
			continue
		measured += 1
		var off := rad_to_deg(absf(to_guardian.angle_to(to_door)))
		# Occlusion as well as angle: a door inside the frustum but behind a
		# boulder is not visible either, and this cave is full of boulders.
		var query := PhysicsRayQueryParameters3D.create(at, d_at)
		query.collide_with_areas = false
		var hit: Dictionary = space.intersect_ray(query)
		var blocked_by := ""
		if not hit.is_empty():
			var collider: Object = hit.get("collider")
			var name_value := str((collider as Node).name) if collider is Node else "?"
			# The door's own body is the thing we are looking AT.
			if not name_value.begins_with("VaultDoor"):
				blocked_by = name_value
		var visible := off <= FOV_DEG * 0.5 and blocked_by == ""
		if visible:
			on_screen += 1
		print("%-20s  %5.1f m to door, %5.1f deg off the guardian  %s%s" % [
			str(stand[0]), to_door.length(), off,
			"ON SCREEN" if visible else "off screen",
			"" if blocked_by == "" else "  (blocked by %s)" % blocked_by])

	print("")
	print("%d of %d stands have the shut door on screen while the player faces the guardian."
		% [on_screen, measured])
	if measured > 0 and on_screen * 2 < measured:
		print("VERDICT: the door is NOT what the player is looking at during the fight.")
		print("The claim that this is a fight FOR what is behind the door rests on the")
		print("player turning around, not on anything the fight itself shows them.")
	else:
		print("VERDICT: the door reads from the fight.")
	quit(0)
