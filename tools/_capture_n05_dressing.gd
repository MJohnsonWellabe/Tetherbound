extends SceneTree
## N05-WORLD-DRESSING-0905. Evidence frames for the four dressing defects the
## 0904 lanes documented but did not own: the village fence junction behind
## Halda's conversation stand (W08), Bram's inn wall behind the bar (W08), the
## courtyard gauntlet trainer before and after the Meadows answers (W06), and
## the Legendary Chamber's lighting from the two stands W06's three blind
## judges saw (W06's tools/_capture_stronghold_climax.gd, which is not on main).
##
##   xvfb-run -a -s "-screen 0 1280x720x24" \
##     godot --path . --rendering-driver opengl3 --resolution 1280x720 \
##     --script tools/_capture_n05_dressing.gd -- --out=res://shots/n05_after
##
## NEVER --headless together with a rendering driver: it hangs.
## `--only=<substring,...>` restricts stands; `--skip-freed` skips the flag
## write that stands the garrison down (the "after" courtyard frame).

const SCENE := "res://scenes/world/meadows_playground.tscn"
const DEFAULT_OUT_DIR := "res://shots/n05"
const SETTLE_FRAMES := 90
const POSE_FRAMES := 10
const CONVERSATION_FOV := 40.0   # W08's data/config/camera.json `fov`
const CONVERSATION_ARM := 3.5    # W08's `distance`
const COURTYARD_FLAG := "defeated_stronghold_courtyard"
const FREED_FLAG := "legendary_freed"

var _out_dir := DEFAULT_OUT_DIR
var _only: Array[String] = []
var _skip_freed := false


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
		elif a == "--skip-freed":
			_skip_freed = true
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
	camera.fov = 70.0
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

	var written: Array[String] = []
	var failures: Array[String] = []

	# --- the village: Halda's stand and the fence behind it -------------------
	var halda: Node3D = world.find_child("Halda", true, false) as Node3D
	if halda != null:
		var at := halda.global_position
		var forward := -halda.global_transform.basis.z
		forward.y = 0.0
		forward = forward.normalized()
		print("[n05] Halda at %s facing %s" % [str(at), str(forward)])
		var chest := at + Vector3(0.0, 1.15, 0.0)
		# W08's frame 1 has the tournament bracket board (village_npcs.json:
		# "the bracket board at [20, 15]") over Halda's shoulder, so its lens
		# stood 3.5 m from her on the far side from the board, swung a little
		# so her body does not hide the fence run behind her. Her authored
		# facing looks back into the square (F-01 of the first capture round
		# proved that: houses, no fence), so the board, not `facing_deg`, is
		# what places this stand.
		var board := Vector3(20.0, at.y, 15.0)
		var away := (at - board).normalized()
		for pair: Array in [["F-05-halda-w08-stand", 14.0], ["F-01-halda-two-shot-left", 40.0]]:
			var dir := away.rotated(Vector3.UP, deg_to_rad(float(pair[1])))
			var eye := at + dir * CONVERSATION_ARM + Vector3(0.0, 1.55, 0.0)
			await _shoot(camera, look, eye, chest, str(pair[0]), CONVERSATION_FOV, written, failures, player)
		# The fence itself: the boundary's [30,11] corner and the run past her.
		await _shoot(camera, look, Vector3(20.0, 2.4, 6.0), Vector3(30.0, 0.6, 11.0),
			"F-03-fence-corner-30-11", 55.0, written, failures, player)
		await _shoot(camera, look, Vector3(27.0, 2.2, 5.0), Vector3(20.0, 0.6, 19.0),
			"F-04-fence-run-behind-halda", 55.0, written, failures, player)
	else:
		failures.append("no 'Halda' node in the world")

	# --- Bram's inn, across the bar ---------------------------------------------
	var inn := _find_inn(world)
	var interior: Node3D = inn.get_node_or_null(^"Interior") as Node3D if inn != null else null
	if interior != null:
		var bram: Vector3 = interior.call("bar_position")
		var eye := interior.to_global(Vector3(-0.55, 1.6, -0.9))
		await _shoot(camera, look, eye, bram + Vector3(0.0, 1.3, 0.0), "I-01-inn-across-the-bar",
			CONVERSATION_FOV, written, failures, player)
		await _shoot(camera, look, interior.to_global(Vector3(0.4, 1.6, 2.2)),
			interior.to_global(Vector3(0.0, 1.0, -4.0)), "I-02-inn-from-the-door", 60.0, written, failures, player)
	else:
		failures.append("no inn interior in the world")

	# --- the stronghold ----------------------------------------------------------
	var hold: Node3D = world.get_node_or_null(^"Stronghold") as Node3D
	if hold == null:
		failures.append("no Stronghold node")
	else:
		var chamber: Vector3 = hold.call("marker", "legendary_chamber")
		var machine: Node3D = hold.call("machine") as Node3D
		var machine_at: Vector3 = machine.global_position if machine != null else chamber
		var reveal: Vector3 = hold.call("marker", "reveal_stand")
		var yaw := hold.rotation.y
		var local_x := Vector3(cos(yaw), 0.0, -sin(yaw))
		# W06's two chamber stands, verbatim: the arch face-on from the reveal
		# stand, and a raised three-quarter from the door corner.
		var stand_face := Vector3(reveal.x, reveal.y + 1.7, reveal.z)
		var corner := chamber + local_x * 11.5 - Vector3(-sin(yaw), 0.0, -cos(yaw)) * 9.0
		var stand_corner := Vector3(corner.x, chamber.y + 5.5, corner.z)
		var aim_ring := machine_at + Vector3(0.0, 5.0, 0.0)
		await _shoot(camera, look, stand_face, aim_ring, "C-01-chamber-face", 70.0, written, failures, player)
		await _shoot(camera, look, stand_corner, aim_ring, "C-03-chamber-corner", 70.0, written, failures, player)
		# The bound creature itself, from where the player stands to read it.
		var legendary: Vector3 = hold.call("marker", "legendary_stand")
		var eye_l := reveal + Vector3(0.0, 1.7, 0.0)
		await _shoot(camera, look, eye_l, legendary + Vector3(0.0, 1.6, 0.0), "C-02-chamber-creature", 55.0,
			written, failures, player)

		# The courtyard gauntlet trainer: held, then after the Meadows answers.
		var trainer_at: Vector3 = hold.call("marker", "trainer_stronghold_courtyard")
		var court: Vector3 = hold.call("marker", "courtyard")
		var toward := trainer_at - court
		toward.y = 0.0
		toward = toward.normalized() if toward.length() > 0.01 else Vector3(1, 0, 0)
		var yard_eye := trainer_at - toward * 9.0 + Vector3(0.0, 2.2, 0.0)
		var yard_aim := trainer_at + Vector3(0.0, 1.2, 0.0)
		var body_before := world.find_child("Warder Solene", true, false)
		print("[n05] courtyard trainer body before: %s" % ("present at %s" % str((body_before as Node3D).global_position) if body_before != null else "MISSING"))
		await _shoot(camera, look, yard_eye, yard_aim, "Y-01-courtyard-held", 60.0, written, failures, player)
		if not _skip_freed:
			var game := root.get_node_or_null(^"/root/Game")
			var progression: Variant = game.get("progression") if game != null else null
			if progression == null:
				failures.append("no progression on /root/Game; cannot set %s" % FREED_FLAG)
			else:
				progression.call("set_flag", COURTYARD_FLAG)
				progression.call("set_flag", FREED_FLAG)
				var healing: Node = world.get_node_or_null(^"MeadowHealing")
				var waited := 0
				while healing != null and not bool(healing.call("applied")) and waited < 600:
					await physics_frame
					waited += 1
				if healing != null:
					print("[n05] MeadowHealing applied after %d frames: %s" % [waited, str(healing.call("report"))])
				for i in 30:
					await physics_frame
				var body_after := world.find_child("Warder Solene", true, false)
				var gone := body_after == null or not is_instance_valid(body_after) or body_after.is_queued_for_deletion()
				print("[n05] courtyard trainer body after legendary_freed (beaten): %s" % ("WITHDRAWN" if gone else "STILL STANDING"))
				await _shoot(camera, look, yard_eye, yard_aim, "Y-02-courtyard-freed", 60.0, written, failures, player)

	print("\nwrote %d frames to %s" % [written.size(), _out_dir])
	for path in written:
		print("  %s" % path)
	if not failures.is_empty():
		print("FAILURES:")
		for line in failures:
			print("  %s" % line)
	quit(0 if failures.is_empty() else 2)


func _find_inn(world: Node) -> Node3D:
	var village: Node = world.get_node_or_null(^"Village")
	if village == null:
		return null
	for child in village.get_children():
		if (child as Node).name.begins_with("inn_"):
			return child as Node3D
	return null


func _shoot(camera: Camera3D, look: Node, eye: Vector3, target: Vector3, name_value: String, fov: float,
		written: Array[String], failures: Array[String], player: Node3D) -> void:
	if not _wanted(name_value):
		return
	camera.fov = fov
	camera.global_position = eye
	camera.look_at(target, Vector3.UP)
	if player != null:
		player.global_position = eye
	# Two settle passes with a drawn frame between them (tools/_judge_capture_hall.gd's
	# finding): the second visit is the one Terrain3D has streamed for.
	for pass_index in 2:
		for i in 60:
			await physics_frame
		for i in POSE_FRAMES:
			await process_frame
		await RenderingServer.frame_post_draw
	if look != null:
		if look.has_method("set_weather"):
			look.call("set_weather", {})
		look.call("apply_time", "day")
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
	print("  %-30s -> %s" % [name_value, path])
