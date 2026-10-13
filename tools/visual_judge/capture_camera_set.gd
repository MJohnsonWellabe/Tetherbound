extends SceneTree

## Fixed-camera capture for one visual item (WORKFLOW 8.1 rule 10): boots the
## Meadows, stands the trainer at each view's `player` point (the 1.80 m
## ruler), puts a free camera at `pos` looking at `look_at` (or by
## yaw/pitch), sets WorldLook's named time and WorldWeather's preset, and
## saves <out>/<view id>.png. The same set gives the same cameras every round,
## unlike a walk whose stops drift with frame timing. HUD hidden; the
## companion stays recalled (its clearance is covered by the follower tests).
##
##   xvfb-run godot --path . --rendering-driver opengl3 --resolution 1920x1080 \
##     --script res://tools/visual_judge/capture_camera_set.gd -- \
##     --set=res://tools/visual_judge/camera_sets/F17-6.json --out=/abs/dir

const SCENE := "res://scenes/world/meadows_playground.tscn"
const SETTLE_FRAMES := 12
const RAIN_SETTLE_FRAMES := 16
const GRAPHICS := preload("res://scripts/ui/graphics_prefs.gd")


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var set_path := ""
	var out := ""
	var expected_preset := ""
	var selected_views: PackedStringArray = []
	for a: String in OS.get_cmdline_user_args():
		if a.begins_with("--set="):
			set_path = a.trim_prefix("--set=")
		elif a.begins_with("--out="):
			out = a.trim_prefix("--out=")
		elif a.begins_with("--preset="):
			expected_preset = a.trim_prefix("--preset=")
		elif a.begins_with("--views="):
			selected_views = a.trim_prefix("--views=").split(",", false)
	var camera_set: Variant = JSON.parse_string(FileAccess.get_file_as_string(set_path))
	if not camera_set is Dictionary or out == "":
		push_error("capture_camera_set: needs --set=<camera set json> and --out=<dir>")
		quit(2)
		return
	if DirAccess.make_dir_recursive_absolute(out) != OK:
		push_error("capture_camera_set: cannot create output directory")
		quit(2)
		return
	if not expected_preset.is_empty() and (GRAPHICS.selected() != expected_preset or GRAPHICS.restart_required()):
		push_error("capture_camera_set: actual preset/renderer does not match --preset=" + expected_preset)
		quit(2)
		return
	print("CAMERA_SET graphics: %s / %s" % [GRAPHICS.selected(), RenderingServer.get_current_rendering_method()])
	var views: Array = []
	for view: Dictionary in camera_set.get("views", []):
		if selected_views.is_empty() or str(view.get("id", "")) in selected_views:
			views.append(view)
	if views.is_empty() or (not selected_views.is_empty() and views.size() != selected_views.size()):
		push_error("capture_camera_set: empty set or unknown/duplicate --views selection")
		quit(2)
		return
	var world := (load(SCENE) as PackedScene).instantiate() as Node3D
	root.add_child(world)
	current_scene = world
	for i in 300:
		await physics_frame
	if not get_nodes_in_group(&"deployed_creature").is_empty():
		push_error("capture_camera_set: companion must be recalled in the isolated capture state")
		quit(2)
		return
	var hud := world.get_node_or_null(^"PlaygroundHUD")
	if hud != null:
		hud.set("visible", false)
	var look := world.get_node_or_null(^"WorldLook")
	var weather := world.get_node_or_null(^"WorldWeather")
	if look == null or weather == null:
		push_error("capture_camera_set: WorldLook and WorldWeather are required")
		quit(2)
		return
	if look != null:
		look.call("set_clock_frozen", true)
	var player := world.get_node_or_null(^"Player") as Node3D
	if player == null:
		push_error("capture_camera_set: fixed trainer ruler is missing")
		quit(2)
		return
	# A fixed composition must not let gravity/input move the ruler while
	# render frames settle. This diagnostic does not prove traversal.
	player.set_physics_process(false)
	var cam := Camera3D.new()
	root.add_child(cam)
	GRAPHICS.apply_camera(cam)
	var saved := 0
	for raw: Variant in views:
		var view: Dictionary = raw
		if player != null and view.get("player") is Array:
			var p: Array = view["player"]
			player.global_position = Vector3(float(p[0]), float(p[1]), float(p[2]))
			if player is CharacterBody3D:
				(player as CharacterBody3D).velocity = Vector3.ZERO
		var pos: Array = view.get("pos", [0, 0, 0])
		var eye := Vector3(float(pos[0]), float(pos[1]), float(pos[2]))
		cam.fov = float(view.get("fov", 70.0))
		if view.get("look_at") is Array:
			var t: Array = view["look_at"]
			cam.global_transform = Transform3D(Basis(), eye).looking_at(
				Vector3(float(t[0]), float(t[1]), float(t[2])), Vector3.UP)
		else:
			cam.global_transform = Transform3D(Basis.from_euler(Vector3(
				deg_to_rad(float(view.get("pitch", 0.0))), deg_to_rad(float(view.get("yaw", 0.0))), 0.0)), eye)
		cam.current = true
		if player != null and view.get("player") is Array:
			# Trainer faces away from the camera, as the follow camera shows them.
			var away := player.global_position - eye
			player.global_rotation.y = atan2(away.x, away.z)
		var weather_name := str(view.get("weather", "clear"))
		if weather != null:
			weather.call("set_weather", weather_name)
		if look != null:
			look.call("apply_time", str(view.get("time_name", "day")))
		for f in (RAIN_SETTLE_FRAMES if weather_name == "rain" else SETTLE_FRAMES):
			await process_frame
		await RenderingServer.frame_post_draw
		var image := root.get_viewport().get_texture().get_image()
		var file := out.path_join("%s.png" % str(view.get("id", "view")))
		if image != null and not image.is_empty() and image.save_png(file) == OK:
			saved += 1
			print("CAMERA_SET %s saved" % str(view.get("id", "")))
		else:
			push_error("CAMERA_SET image save failed: " + file)
	print("CAMERA_SET done: %d views" % saved)
	quit(0 if saved == views.size() else 2)
