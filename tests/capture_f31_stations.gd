extends SceneTree

## F31#6 evidence: do the six homestead stations read as distinct objects at
## the normal camera? Real Meadows world; the station pieces (station_piece.gd,
## the same node the paid build plants) are set in a row on the homestead plot
## as a disclosed VISUAL-ONLY placement (no world record, no cost), and the
## ordinary rig frames them from the trainer's stance at day and night.
## Equipment for F31#6 only (no other way to verify it exists).
##
##   xvfb-run -a -s "-screen 0 1920x1080x24" godot --path . \
##     --rendering-method gl_compatibility --rendering-driver opengl3 \
##     --audio-driver Dummy --resolution 1920x1080 \
##     --script tests/capture_f31_stations.gd -- --capture-dir=/abs/out
const SCENE := "res://scenes/world/meadows_playground.tscn"
const PIECE := preload("res://scripts/build/station_piece.gd")
const ROW := ["den", "workbench", "forge", "kitchen", "altar", "farm"] # Den first: clear of the village signpost.
const ORIGIN := Vector3(-1.75, 0.0, -12.0) # Probed clear, flat 32x14 strip centred at (12, -12).
const SPACING := 4.0 # Den (4.4 m) still clears its neighbours; the row fits one front frame.


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var out := ""
	var only: PackedStringArray = []
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--capture-dir="):
			out = argument.substr("--capture-dir=".length())
		elif argument.begins_with("--stands="): # Optional comma list, to finish a cut-off run.
			only = argument.substr("--stands=".length()).split(",")
	if DisplayServer.get_name() == "headless" or out.is_empty():
		print("F31 stations capture FAIL: native renderer and --capture-dir required")
		quit(2)
		return
	DirAccess.make_dir_recursive_absolute(out)
	await process_frame
	var game := root.get_node("Game")
	for flag: String in ["opening:beat:free_play", "opening:starter_granted"]:
		game.get("progression").call("set_flag", flag)
	root.get_viewport().disable_3d = true
	var world := (load(SCENE) as PackedScene).instantiate() as Node3D
	root.add_child(world)
	current_scene = world
	for _frame in 300:
		await physics_frame
	for i in ROW.size():
		var piece: Node3D = PIECE.new()
		piece.name = "Capture_" + ROW[i]
		var x := ORIGIN.x + i * SPACING
		piece.position = Vector3(x, float(world.call("ground_height_at", x, ORIGIN.z)), ORIGIN.z)
		world.add_child(piece)
		piece.call("build", ROW[i], false)
	var player := world.get_node("Player") as CharacterBody3D
	var rig := world.get_node("CameraRig") as Node3D
	var look := world.get_node("WorldLook")
	look.call("set_clock_frozen", true)
	var mid := ORIGIN + Vector3(SPACING * (ROW.size() - 1) * 0.5, 0, 0)
	var stands := {"row": [mid + Vector3(3.0, 1.2, 10.5), mid + Vector3(3.0, 0, 0)], "forge_kitchen": [ORIGIN + Vector3(10.0, 1.2, 5.5), ORIGIN + Vector3(10.0, 0, 0)], "altar": [ORIGIN + Vector3(18.5, 1.2, 4.5), ORIGIN + Vector3(18.5, 0, 0)], "den": [ORIGIN + Vector3(2.8, 1.2, 6.0), ORIGIN + Vector3(2.8, 0, 0)], "workbench": [ORIGIN + Vector3(4.0, 1.2, 4.5), ORIGIN + Vector3(4.0, 0, 0)], "farm": [ORIGIN + Vector3(22.0, 1.2, 3.0), ORIGIN + Vector3(22.0, 0, 0)]}
	for stand: String in stands:
		if not only.is_empty() and not only.has(stand):
			continue
		var at: Vector3 = stands[stand][0]
		var aim: Vector3 = stands[stand][1]
		player.global_position = Vector3(at.x, float(world.call("ground_height_at", at.x, at.z)) + 0.9, at.z)
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
			print("F31 stations frame %s_%s" % [stand, time_name])
		root.get_viewport().disable_3d = true
	quit(0)
