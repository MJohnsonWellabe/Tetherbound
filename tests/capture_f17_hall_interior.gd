extends SceneTree

## F17#6 quick Hall-interior look check (not acceptance evidence on its own:
## the full matrix, tests/capture_f17_visual_matrix.gd, walks there). Stands
## the player in the nave once (disclosed placement), aims the ordinary rig
## down the nave and at the Shrine Room, and saves day and night frames.
##
##   xvfb-run -a -s "-screen 0 1920x1080x24" godot --path . \
##     --rendering-method gl_compatibility --rendering-driver opengl3 \
##     --audio-driver Dummy --resolution 1920x1080 \
##     --script tests/capture_f17_hall_interior.gd -- --capture-dir=/abs/out
const SCENE := "res://scenes/world/meadows_playground.tscn"
const FLAGS := ["opening:beat:free_play", "opening:starter_granted"]


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var out := ""
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--capture-dir="):
			out = argument.substr("--capture-dir=".length())
	if DisplayServer.get_name() == "headless" or out.is_empty():
		print("F17 interior capture FAIL: native renderer and --capture-dir required")
		quit(2)
		return
	DirAccess.make_dir_recursive_absolute(out)
	await process_frame
	var game := root.get_node("Game")
	for flag: String in FLAGS:
		game.get("progression").call("set_flag", flag)
	root.get_viewport().disable_3d = true
	var world := (load(SCENE) as PackedScene).instantiate() as Node3D
	root.add_child(world)
	current_scene = world
	for _frame in 400:
		await physics_frame
	var hall := get_nodes_in_group("crossing_halls")[0] as Node3D
	var player := world.get_node("Player") as CharacterBody3D
	var rig := world.get_node("CameraRig") as Node3D
	var look := world.get_node("WorldLook")
	look.call("set_clock_frozen", true)
	var stands := {"nave": [Vector3(0, 0.9, -3), Vector3(0, 0, 14)], "shrine": [Vector3(7.5, 0.9, 0), Vector3(16, 0, 0)]}
	for stand: String in stands:
		var at: Vector3 = hall.to_global(stands[stand][0])
		var aim: Vector3 = hall.to_global(stands[stand][1])
		player.global_position = at
		player.velocity = Vector3.ZERO
		rig.set("yaw", atan2(-(aim.x - at.x), -(aim.z - at.z)))
		for _frame in 40:
			await physics_frame
		root.get_viewport().disable_3d = false
		for time_name: String in ["day", "night"]:
			look.call("apply_time", time_name)
			for _frame in 10:
				await process_frame
			await RenderingServer.frame_post_draw
			root.get_viewport().get_texture().get_image().save_png(out.path_join("%s_%s.png" % [stand, time_name]))
			print("F17 interior frame %s_%s dark=%s hall_night_ambient=%s" % [stand, time_name, look.call("is_dark"), hall.get("_night_ambient_on")])
		root.get_viewport().disable_3d = true
	quit(0)
