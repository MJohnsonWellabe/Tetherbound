extends "res://tests/smoke_crossing_hall_circuit.gd"

## Native F17 views on the existing physical Hall circuit. The inherited
## post-opening fixture and initial placement are disclosed; all later travel
## and camera turns use the real controller bindings. No image resizing.
const GRAPHICS := preload("res://scripts/ui/graphics_prefs.gd")
var _output := ""
var _preset := ""
var _source := ""
var _views: Array[Dictionary] = []


func _run() -> void:
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--output="):
			_output = argument.trim_prefix("--output=")
		elif argument.begins_with("--preset="):
			_preset = argument.trim_prefix("--preset=")
		elif argument.begins_with("--source-commit="):
			_source = argument.trim_prefix("--source-commit=")
	var pattern := RegEx.new()
	pattern.compile("^[0-9a-f]{40}$")
	var renderer := "gl_compatibility" if _preset == "Low" else "forward_plus"
	if DisplayServer.get_name() == "headless" or not GRAPHICS.PRESETS.has(_preset) \
			or RenderingServer.get_current_rendering_method() != renderer \
			or DisplayServer.window_get_size() != Vector2i(1920, 1080) \
			or pattern.search(_source) == null or not _output.is_absolute_path() \
			or DirAccess.dir_exists_absolute(_output):
		_finish_failure("require native 1920x1080, matching preset/renderer, exact source and fresh absolute output")
		return
	if DirAccess.make_dir_recursive_absolute(_output) != OK or GRAPHICS.choose(_preset) != OK:
		_finish_failure("could not create fresh evidence directory or select preset")
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
	for time_name: String in ["day", "night"]:
		look.call("apply_time", time_name)
		look.call("refresh_graphics")
		for frame in 12:
			await process_frame
		if not await _save_view(label, time_name):
			return
	look.call("apply_time", "day")
	look.call("refresh_graphics")


func _save_view(label: String, time_name: String) -> bool:
	await RenderingServer.frame_post_draw
	var pixels := root.get_viewport().get_texture().get_image()
	if pixels == null or pixels.is_empty() or pixels.get_size() != Vector2i(1920, 1080):
		_failed = "native original image is missing or wrong resolution"
		return false
	var filename := "%03d-%s-%s.png" % [_views.size(), label.validate_filename().replace(" ", "-"), time_name]
	if pixels.save_png(_output.path_join(filename)) != OK:
		_failed = "could not save native original image"
		return false
	var camera := _rig.get_node("Camera3D") as Camera3D
	_views.append({"label": label, "time": time_name, "image": filename,
		"body": _player.global_position, "camera": camera.global_transform,
		"on_floor": _player.is_on_floor(), "preset": GRAPHICS.selected(),
		"features": GRAPHICS.values(), "elapsed_ms": Time.get_ticks_msec()})
	return true


func _after_hall_arrival(hall: Node3D) -> bool:
	# The ordinary reverse view shows the inhabited road from its destination.
	var original_yaw := float(_rig.get("yaw"))
	await _look_stick_to(original_yaw + PI)
	await _capture("village reverse from nave")
	await _look_stick_to(original_yaw)
	if not await super._after_hall_arrival(hall):
		_write_manifest(false)
		return false
	# Observe thirty wall-clock seconds of the live interior without disabling
	# rendering or advancing the clock. Original frames retain HUD and actors.
	var began := Time.get_ticks_msec()
	var next_sample := began
	while Time.get_ticks_msec() - began < 30000:
		await process_frame
		if Time.get_ticks_msec() >= next_sample:
			if not await _save_view("live interior motion", "day"):
				_write_manifest(false)
				return false
			next_sample += 1000
	_write_manifest(_failed.is_empty())
	return _failed.is_empty()


func _write_manifest(complete: bool) -> void:
	var file := FileAccess.open(_output.path_join("manifest.json"), FileAccess.WRITE)
	if file == null:
		_failed = "could not save visual manifest"
		return
	file.store_string(JSON.stringify({"source": _source, "complete": complete,
		"preset": _preset, "renderer": RenderingServer.get_current_rendering_method(),
		"resolution": [1920, 1080], "views": _views, "failure": _failed,
		"shortcuts": ["inherited post-opening flags and starter", "one inherited initial farmhouse placement", "injected physical joypad bindings", "production frozen day/night and clear weather"],
		"scope": "physical village/Hall circuit and native views; independent visual verdict required; no earned opening, device, fight or multiplayer proof"}, "\t") + "\n")
	file.close()


func _finish_failure(reason: String) -> void:
	if not _output.is_empty() and DirAccess.dir_exists_absolute(_output):
		_failed = reason
		_write_manifest(false)
	super._finish_failure(reason)
