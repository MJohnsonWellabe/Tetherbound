extends "res://tests/smoke_crossing_hall_circuit.gd"

## Native F17 views on the existing physical Hall circuit. The inherited
## post-opening fixture and initial placement are disclosed; all later travel
## and camera turns use the real controller bindings. No image resizing.
const GRAPHICS := preload("res://scripts/ui/graphics_prefs.gd")
var _output := ""
var _preset := ""
var _source := ""
var _views: Array[Dictionary] = []
var _output_created_here := false
var _paired_high := false


func _run() -> void:
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--output="):
			_output = argument.trim_prefix("--output=")
		elif argument.begins_with("--preset="):
			_preset = argument.trim_prefix("--preset=")
		elif argument.begins_with("--source-commit="):
			_source = argument.trim_prefix("--source-commit=")
		elif argument == "--paired-high":
			_paired_high = true
	var pattern := RegEx.new()
	pattern.compile("^[0-9a-f]{40}$")
	var renderer := "gl_compatibility" if _preset == "Low" else "forward_plus"
	if DisplayServer.get_name() == "headless" or not GRAPHICS.PRESETS.has(_preset) \
			or (_paired_high and _preset != "Medium") \
			or RenderingServer.get_current_rendering_method() != renderer \
			or DisplayServer.window_get_size() != Vector2i(1920, 1080) \
			or pattern.search(_source) == null or not _output.is_absolute_path() \
			or DirAccess.dir_exists_absolute(_output):
		_finish_failure("require native 1920x1080, matching preset/renderer, exact source and fresh absolute output")
		return
	if DirAccess.make_dir_recursive_absolute(_output) != OK:
		_finish_failure("could not create fresh evidence directory")
		return
	_output_created_here = true
	if GRAPHICS.choose(_preset) != OK:
		_finish_failure("could not select preset")
		return
	await super._run()


func _capture(label: String) -> void:
	_release_all()
	var look := _world.get_node_or_null("WorldLook")
	var weather := _world.get_node_or_null("WorldWeather")
	if look == null or weather == null:
		_failed = "production light/weather nodes are missing"
		return
	look.call("set_clock_frozen", true)
	weather.call("set_weather", "clear")
	var camera := _rig.get_node_or_null("Camera3D") as Camera3D
	if camera == null or not camera.current:
		_failed = "ordinary production camera is not current"
		return
	for frame in 20:
		await physics_frame
	var body_at := _player.global_position
	var yaw := float(_rig.get("yaw"))
	var camera_at := camera.global_transform
	var weather_processing := weather.is_processing()
	weather.set_process(false)
	for weather_name: String in ["clear", "rain"]:
		weather.call("set_weather", weather_name)
		for frame in 120:
			await process_frame
		for time_name: String in ["day", "night"]:
			look.call("apply_time", time_name)
			for preset: String in _capture_presets():
				if GRAPHICS.choose(preset) != OK:
					_failed = "could not apply capture preset " + preset
					weather.set_process(weather_processing)
					return
				look.call("refresh_graphics")
				for frame in 12:
					await process_frame
				if _player.global_position.distance_to(body_at) > .005 \
						or absf(angle_difference(float(_rig.get("yaw")), yaw)) > .001 \
						or camera.global_position.distance_to(camera_at.origin) > .005 \
						or camera.global_basis.get_rotation_quaternion().angle_to(camera_at.basis.get_rotation_quaternion()) > .001:
					_failed = "ordinary body/camera pose changed between paired time/weather/preset views"
					weather.set_process(weather_processing)
					return
				if not await _save_view(label, time_name, weather_name):
					weather.set_process(weather_processing)
					return
	if GRAPHICS.choose(_preset) != OK:
		_failed = "could not restore travel preset " + _preset
	weather.call("set_weather", "clear")
	weather.set_process(weather_processing)
	look.call("apply_time", "day")
	look.call("refresh_graphics")


func _save_view(label: String, time_name: String, weather_name: String = "clear", motion: bool = false) -> bool:
	await RenderingServer.frame_post_draw
	if str(_world.get_node("WorldWeather").call("weather")) != weather_name:
		_failed = "observed weather differs from capture label " + weather_name
		return false
	var pixels := root.get_viewport().get_texture().get_image()
	if pixels == null or pixels.is_empty() or pixels.get_size() != Vector2i(1920, 1080):
		_failed = "native original image is missing or wrong resolution"
		return false
	var extension := "jpg" if motion else "png"
	var filename := "%04d-%s-%s-%s-%s.%s" % [_views.size(), label.validate_filename().replace(" ", "-"), time_name, weather_name, GRAPHICS.selected().to_lower(), extension]
	var saved := pixels.save_jpg(_output.path_join(filename), .95) if motion else pixels.save_png(_output.path_join(filename))
	if saved != OK:
		_failed = "could not save native original image"
		return false
	var camera := _rig.get_node("Camera3D") as Camera3D
	_views.append({"label": label, "time": time_name, "weather": weather_name, "image": filename,
		"body": _coordinates(_player.global_position), "camera": _coordinates(camera.global_position),
		"camera_basis": [_coordinates(camera.global_basis.x), _coordinates(camera.global_basis.y), _coordinates(camera.global_basis.z)],
		"on_floor": _player.is_on_floor(), "preset": GRAPHICS.selected(), "motion_sample": motion,
		"encoding": "native-resolution JPEG95" if motion else "native-resolution PNG",
		"features": GRAPHICS.values(), "elapsed_ms": Time.get_ticks_msec()})
	return true


func _after_hall_arrival(hall: Node3D) -> bool:
	# The ordinary reverse view shows the inhabited road from its destination.
	var original_yaw := float(_rig.get("yaw"))
	await _look_stick_to(original_yaw + PI)
	if absf(angle_difference(float(_rig.get("yaw")), original_yaw + PI)) > deg_to_rad(3.0):
		_failed = "ordinary look-stick did not reach reverse view"
		_write_manifest(false)
		return false
	await _capture("village reverse from nave")
	await _look_stick_to(original_yaw)
	if absf(angle_difference(float(_rig.get("yaw")), original_yaw)) > deg_to_rad(3.0):
		_failed = "ordinary look-stick did not restore forward view"
		_write_manifest(false)
		return false
	if not await super._after_hall_arrival(hall):
		_write_manifest(false)
		return false
	# Observe thirty wall-clock seconds of the live interior without disabling
	# rendering or advancing the clock. Original frames retain HUD and actors.
	var weather := _world.get_node("WorldWeather")
	weather.call("set_weather", "clear")
	weather.set_process(false)
	for preset: String in _capture_presets():
		if GRAPHICS.choose(preset) != OK:
			_failed = "could not apply motion preset " + preset
			_write_manifest(false)
			return false
		_world.get_node("WorldLook").call("refresh_graphics")
		for frame in 12:
			await process_frame
		var began := Time.get_ticks_msec()
		var next_sample := began
		while Time.get_ticks_msec() - began < 30000:
			await process_frame
			if Time.get_ticks_msec() >= next_sample:
				if not await _save_view("live interior motion", "day", "clear", true):
					_write_manifest(false)
					return false
				# Record actual timestamps; slow rendering is retained, never
				# presented as smooth fixed-rate motion by the video packager.
				next_sample = Time.get_ticks_msec() + 100
	_write_manifest(_failed.is_empty())
	return _failed.is_empty()


func _write_manifest(complete: bool) -> void:
	var file := FileAccess.open(_output.path_join("manifest.json"), FileAccess.WRITE)
	if file == null:
		_failed = "could not save visual manifest"
		return
	file.store_string(JSON.stringify({"source": _source, "complete": complete,
		"presets": _capture_presets(), "renderer": RenderingServer.get_current_rendering_method(),
		"resolution": [1920, 1080], "views": _views, "failure": _failed,
		"shortcuts": ["inherited post-opening flags and starter", "one inherited initial farmhouse placement", "injected physical joypad bindings", "production frozen day/night and selected clear/rain weather; weather scheduler held only for stationary capture"],
		"scope": "physical village/Hall circuit and native views; independent visual verdict required; no earned opening, device, fight or multiplayer proof"}, "\t") + "\n")
	file.close()


func _coordinates(value: Vector3) -> Array[float]:
	return [value.x, value.y, value.z]


func _capture_presets() -> Array[String]:
	var presets: Array[String] = ["Medium", "High"] if _paired_high else [_preset]
	return presets


func _release_all() -> void:
	super._release_all()
	Input.flush_buffered_events()


func _look_stick_to(wanted: float) -> void:
	for frame in 240:
		var error := rad_to_deg(angle_difference(float(_rig.get("yaw")), wanted))
		_pad_release("look_left")
		_pad_release("look_right")
		Input.flush_buffered_events()
		if absf(error) < 3.0:
			break
		_pad_press("look_left" if error > 0.0 else "look_right", clampf(absf(error) / STEER_FULL_DEG, .35, 1.0))
		Input.flush_buffered_events()
		await physics_frame
	_pad_release("look_left")
	_pad_release("look_right")
	Input.flush_buffered_events()
	await process_frame


func _finish_failure(reason: String) -> void:
	if _output_created_here:
		_failed = reason
		_write_manifest(false)
	super._finish_failure(reason)
