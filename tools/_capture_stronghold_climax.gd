extends SceneTree
## W06-FINALE-0904 (CL-O8 / CL-G5). Evidence frames for the chapter's climax:
## the Legendary Chamber with the creature BOUND, the Hall's gate face with the
## garrison in place, then the same two after the legendary is freed -- the
## creature out of the machine, the garrison withdrawn. Same rig as
## tools/_judge_capture_hall.gd (Terrain3D handed the capture camera, canvas
## layers hidden, weather cleared, player parked at the eye so the terrain
## bubble streams to the stand).
##
##   xvfb-run -a -s "-screen 0 1280x720x24" \
##     godot --path . --rendering-driver opengl3 --resolution 1280x720 \
##     --script tools/_capture_stronghold_climax.gd -- --out=res://shots/w06_after
##
## NEVER --headless with a rendering driver: hangs forever.
##
## `--only=<substring>` restricts stands. The freeing is driven through the
## climax's own `_free_the_legendary()` (the lever's path minus the dialogue,
## which has no panel to open here), so the after-frames are what the game
## itself does when the lever is pulled, not a posed copy of it.

const SCENE := "res://scenes/world/meadows_playground.tscn"
const DEFAULT_OUT_DIR := "res://shots/w06_climax"
const SETTLE_FRAMES := 90
const POSE_FRAMES := 10
const FOV := 70.0
const ELITE_FLAG := "defeated_stronghold_elite"
const WARDEN_FLAG := "defeated_warden"

var _out_dir := DEFAULT_OUT_DIR
var _only: Array[String] = []


func _init() -> void:
	_run()


func _hide_canvas_layers(node: Node) -> void:
	if node is CanvasLayer:
		(node as CanvasLayer).visible = false
	for child in node.get_children():
		_hide_canvas_layers(child)


func _wanted(name_value: String) -> bool:
	if _only.is_empty():
		return true
	for want: String in _only:
		if name_value.contains(want):
			return true
	return false


func _run() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			_out_dir = a.substr("--out=".length())
		elif a.begins_with("--only="):
			for name in a.substr("--only=".length()).split(",", false):
				_only.append(name.strip_edges())
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(_out_dir))
	var packed: PackedScene = load(SCENE)
	if packed == null:
		push_error("could not load %s" % SCENE)
		quit(1)
		return
	var world: Node = packed.instantiate()
	root.add_child(world)
	for i in SETTLE_FRAMES:
		await physics_frame

	_hide_canvas_layers(root)
	var rig: Node = world.get_node_or_null(^"CameraRig")
	if rig != null:
		rig.set_process(false)
		rig.set_physics_process(false)

	var camera := Camera3D.new()
	camera.fov = FOV
	camera.far = 3000.0
	world.add_child(camera)
	camera.make_current()
	var terrain: Node = world.get("_terrain") as Node
	if terrain != null and terrain.has_method("set_camera"):
		terrain.call("set_camera", camera)

	var look: Node = world.get_node_or_null(^"WorldLook")
	var weather: Node = world.get_node_or_null(^"WorldWeather")
	if weather != null:
		weather.set_process(false)
		weather.set_physics_process(false)
	if look != null:
		look.set_process(false)
		look.set_physics_process(false)
		if look.has_method("set_weather"):
			look.call("set_weather", {})
		look.call("apply_time", "day")

	var player: Node3D = world.get_node_or_null(^"Player") as Node3D
	if player != null:
		player.visible = false
		player.set_physics_process(false)
		if player is CharacterBody3D:
			(player as CharacterBody3D).velocity = Vector3.ZERO

	var hold: Node3D = world.get_node_or_null(^"Stronghold") as Node3D
	var climax: Node = world.get_node_or_null(^"StrongholdClimax")
	if climax == null:
		for child in world.get_children():
			if child.get_script() != null and str(child.get_script().resource_path).ends_with("stronghold_climax.gd"):
				climax = child
				break
	if hold == null or climax == null:
		push_error("no Stronghold (%s) or no climax node (%s)" % [str(hold != null), str(climax != null)])
		quit(1)
		return

	var written: Array[String] = []
	var failures: Array[String] = []

	# --- stands ---------------------------------------------------------------
	var chamber: Vector3 = hold.call("marker", "legendary_chamber")
	var machine: Node3D = hold.call("machine") as Node3D
	var machine_at: Vector3 = machine.global_position if machine != null else chamber
	var reveal: Vector3 = hold.call("marker", "reveal_stand")
	var yaw := hold.rotation.y
	var local_x := Vector3(cos(yaw), 0.0, -sin(yaw))
	# From the reveal stand: the arch face-on, the creature in the ring.
	var stand_face := Vector3(reveal.x, reveal.y + 1.7, reveal.z)
	# From the doorway on the chamber's +x wall: the way the player walks in.
	var door := chamber + local_x * 12.5
	var stand_door := Vector3(door.x, chamber.y + 1.7, door.z)
	# A raised three-quarter from the door corner, so the whole machine and
	# its occupant fit in one frame.
	var corner := chamber + local_x * 11.5 - Vector3(-sin(yaw), 0.0, -cos(yaw)) * 9.0
	var stand_corner := Vector3(corner.x, chamber.y + 5.5, corner.z)
	var aim_ring := machine_at + Vector3(0.0, 5.0, 0.0)
	var aim_low := machine_at + Vector3(0.0, 3.5, 0.0)

	# The Hall's gate face, from the ramp foot (design sec10 H-03), at night,
	# when the garrison's fires and lamps are what is lighting it.
	var gate_eye := Vector3(8.0, _ground(world, 8.0, 7505.0) + 1.7, 7505.0)
	var gate_aim := gate_eye + Vector3(0.0, 0.0, 40.0)
	# The outer works yard, where the garrison camp stands, from the gate sill.
	var works: Vector3 = hold.call("marker", "outer_works")
	var entrance: Vector3 = hold.call("marker", "entrance") if bool(hold.call("has_marker", "entrance")) else works
	var toward := works - entrance
	toward.y = 0.0
	toward = toward.normalized()
	var yard_eye := works - toward * 10.0 + Vector3(0.0, 3.0, 0.0)
	var yard_aim := works + Vector3(0.0, 0.8, 0.0)
	# Closer: 18 m up the causeway from its foot, on the deck itself (the
	# stronghold knows its own walking surface), where the sentries, sconces
	# and causeway braziers are people-sized rather than pinpricks.
	var cause := entrance + toward * 18.0
	var cause_y := float(hold.call("ground_height_at", cause.x, cause.z)) if hold.has_method("ground_height_at") else NAN
	if is_nan(cause_y):
		cause_y = _ground(world, cause.x, cause.z)
	var cause_eye := Vector3(cause.x, cause_y + 1.7, cause.z)
	var cause_aim := entrance + toward * 46.0 + Vector3(0.0, 3.0, 0.0)

	var torch := OmniLight3D.new()
	torch.light_energy = 0.0
	torch.visible = false
	world.add_child(torch)

	# BEFORE the lever: bound.
	await _shoot(camera, look, stand_face, aim_ring, "C-01-chamber-face-bound", written, failures, "day", player)
	await _shoot(camera, look, stand_door, aim_low, "C-02-chamber-door-bound", written, failures, "day", player)
	await _shoot(camera, look, stand_corner, aim_ring, "C-03-chamber-corner-bound", written, failures, "day", player)
	await _shoot(camera, look, gate_eye, gate_aim, "G-01-gate-night-held", written, failures, "night", player)
	await _shoot(camera, look, cause_eye, cause_aim, "G-01b-causeway-night-held", written, failures, "night", player)
	await _shoot(camera, look, yard_eye, yard_aim, "G-02-yard-night-held", written, failures, "night", player)

	# The lever, the game's own way. The Warden gate is what the lever checks;
	# `_free_the_legendary` is the stage the lever leads to.
	var game := root.get_node_or_null(^"/root/Game")
	if game != null and game.get("progression") != null:
		game.get("progression").call("set_flag", ELITE_FLAG)
		game.get("progression").call("set_flag", WARDEN_FLAG)
	climax.call("_free_the_legendary")
	# Give the step-out and the garrison's withdrawal their full run.
	for i in 8 * 60:
		await physics_frame
	await _shoot(camera, look, stand_face, aim_ring, "C-04-chamber-face-freed", written, failures, "day", player)
	await _shoot(camera, look, stand_corner, aim_ring, "C-05-chamber-corner-freed", written, failures, "day", player)
	await _shoot(camera, look, gate_eye, gate_aim, "G-03-gate-night-freed", written, failures, "night", player)
	await _shoot(camera, look, cause_eye, cause_aim, "G-03b-causeway-night-freed", written, failures, "night", player)
	await _shoot(camera, look, yard_eye, yard_aim, "G-04-yard-night-freed", written, failures, "night", player)

	print("\nwrote %d frames to %s" % [written.size(), _out_dir])
	for path in written:
		print("  %s" % path)
	if not failures.is_empty():
		print("FAILURES:")
		for line in failures:
			print("  %s" % line)
	quit(0 if failures.is_empty() else 2)


func _ground(world: Node, x: float, z: float) -> float:
	var y := float(world.call("ground_height_at", x, z))
	return 0.0 if is_nan(y) else y


func _shoot(camera: Camera3D, look: Node, eye: Vector3, target: Vector3, name_value: String,
		written: Array[String], failures: Array[String], hour: String, player: Node3D) -> void:
	if not _wanted(name_value):
		return
	camera.global_position = eye
	camera.look_at(target, Vector3.UP)
	if player != null:
		player.global_position = eye
	# Two settle passes with a drawn frame between them, per _judge_capture_hall's
	# own finding: the second visit is the one Terrain3D has streamed for.
	for pass_index in 2:
		for i in 60:
			await physics_frame
		for i in POSE_FRAMES:
			await process_frame
		await RenderingServer.frame_post_draw
	if look != null:
		if look.has_method("set_weather"):
			look.call("set_weather", {})
		look.call("apply_time", hour)
	for i in POSE_FRAMES:
		await process_frame
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	if image == null:
		failures.append("%s: viewport returned no image" % name_value)
		return
	var path := "%s/%s.png" % [_out_dir, name_value]
	if image.save_png(path) != OK:
		failures.append("%s: save_png failed" % name_value)
		return
	written.append(path)
	print("  %-28s -> %s" % [name_value, path])
