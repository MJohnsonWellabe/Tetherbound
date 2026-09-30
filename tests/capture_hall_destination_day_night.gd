extends "res://tests/smoke_village_hall_redesign.gd"

## Literal F17#1 view witness only: two native original frames from the actual
## physical farmhouse doorway event, using the ordinary production camera.
## The inherited initial fixture and WorldLook day/night/clear weather are
## disclosed. The existing full farmhouse-to-Hall physical proof is reused.
var _destination_done := false


func _capture(label: String) -> void:
	if label != "actual farmhouse doorway" or _destination_done:
		return
	_destination_done = true
	_release_all()
	if DisplayServer.get_name() == "headless":
		_finish_failure("destination day/night frames require a native renderer")
		return
	var output := ""
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--capture-dir="):
			output = argument.substr("--capture-dir=".length())
	if output.is_empty() or not output.is_absolute_path():
		_finish_failure("destination frames require an explicit absolute capture directory")
		return
	if DirAccess.make_dir_recursive_absolute(output) != OK:
		_finish_failure("destination capture directory could not be created")
		return
	var camera := _rig.get_node_or_null("Camera3D") as Camera3D
	var look := _world.get_node_or_null("WorldLook")
	var weather := _world.get_node_or_null("WorldWeather")
	if camera == null or not camera.current or look == null or weather == null:
		_finish_failure("ordinary current CameraRig/WorldLook/WorldWeather is missing")
		return
	if RenderingServer.get_current_rendering_method() != "gl_compatibility":
		_finish_failure("destination witness requires the conservative Compatibility renderer")
		return
	if DisplayServer.window_get_size() != Vector2i(1920, 1080):
		_finish_failure("actual native window must be 1920x1080; no image resizing")
		return
	look.call("set_clock_frozen", true)
	weather.call("set_weather", "clear")
	# Release input and let the actual controller settle naturally. No body,
	# rig, lens, HUD or model transforms are changed for either photograph.
	for frame in 20:
		await physics_frame
	var body_at := _player.global_position
	var yaw := float(_rig.get("yaw"))
	var rows: Array[Dictionary] = []
	for time_name: String in ["day", "night"]:
		look.call("apply_time", time_name)
		for frame in 8:
			await process_frame
		await RenderingServer.frame_post_draw
		if _player.global_position.distance_to(body_at) > .005 or absf(angle_difference(float(_rig.get("yaw")), yaw)) > .001:
			_finish_failure("ordinary body/camera pose changed between day/night frames")
			return
		var image := root.get_viewport().get_texture().get_image()
		if image == null or image.is_empty() or image.get_size() != Vector2i(1920, 1080):
			_finish_failure("native original viewport image is not 1920x1080")
			return
		var filename := "farm-door-" + time_name + ".png"
		if image.save_png(output.path_join(filename)) != OK:
			_finish_failure("native original frame could not be saved")
			return
		rows.append({"time": time_name, "image": filename, "width": image.get_width(), "height": image.get_height(),
			"body": [body_at.x, body_at.y, body_at.z], "camera": [camera.global_position.x, camera.global_position.y, camera.global_position.z],
			"yaw": yaw, "renderer": RenderingServer.get_current_rendering_method()})
	var receipt := FileAccess.open(output.path_join("frames.json"), FileAccess.WRITE)
	if receipt == null:
		_finish_failure("native view receipt could not be saved")
		return
	receipt.store_string(JSON.stringify({"frames": rows, "shortcuts": "authored post-opening flags/starter; one inherited initial farmhouse floor placement/yaw; injected parsed joypad/look; production WorldLook day/night frozen and clear weather. No body/camera/HUD/model changes, image resizing, real-device or full visual-bar verdict."}, "\t") + "\n")
	receipt.close()
	print("F17#1 native original farmhouse-door day/night frames saved: same ordinary body/camera pose, Compatibility1920x1080, no resizing. Literal destination judgment remains code-blind and separate.")
	# Stop at the criterion's actual doorway view. The unchanged complete
	# farmhouse-to-Hall walk and circuit already have native-exit0 witnesses.
	quit(0)
