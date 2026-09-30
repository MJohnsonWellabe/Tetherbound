extends "res://tools/catalogue_survey.gd"

## F26 computer comparison. Reuse production-world/camera/floor setup and
## the existing InputMap navigator. Never run headless or speed up physics.
## Timed interval has no PNG I/O; start/end captures bracket raw frame data.
## --biome=meadows|water|cloudreach|stormwood --preset=Low|Medium|High
## --source-commit=<full SHA> --output=res://.artifacts/lookdev/<fresh folder>
const GRAPHICS := preload("res://scripts/ui/graphics_prefs.gd")
const NAVIGATOR := preload("res://tests/helpers/stick_navigator.gd")
const ROUTES_PATH := "res://data/config/lookdev_routes.json"
var _preset := ""
var _source_commit := ""
var _capture: Dictionary = {}
var _route: Dictionary = {}
var _samples: Array[Dictionary] = []
var _measuring := false
var _previous_frame_usec := 0
var _route_started_usec := 0
var _route_finished_usec := 0
var _waypoints_reached := 0
var _navigation: RefCounted
var _clock_start: Dictionary = {}
var _clock_end: Dictionary = {}
var _timed_out := false


func _run() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--biome="):
			_biome_id = arg.trim_prefix("--biome=")
		elif arg.begins_with("--preset="):
			_preset = arg.trim_prefix("--preset=")
		elif arg.begins_with("--source-commit="):
			_source_commit = arg.trim_prefix("--source-commit=")
		elif arg.begins_with("--output="):
			_output_dir = arg.trim_prefix("--output=").trim_suffix("/")
	var config_text := FileAccess.get_file_as_string(ROUTES_PATH)
	var config: Variant = JSON.parse_string(config_text)
	var sha_pattern := RegEx.new()
	sha_pattern.compile("^[0-9a-f]{40}$")
	if DisplayServer.get_name() == "headless" or not config is Dictionary \
			or not config.get("routes", {}).has(_biome_id) or not GRAPHICS.PRESETS.has(_preset) \
			or sha_pattern.search(_source_commit) == null or _output_dir == "":
		print("F26 route requires real renderer, known route/preset, exact source SHA and fresh output.")
		quit(2)
		return
	_capture = config.capture
	_route = config.routes[_biome_id]
	_manifest["route_config_sha256"] = config_text.sha256_text()
	_manifest["route_revision"] = str(config.revision)
	var required_renderer := "gl_compatibility" if _preset == "Low" else "forward_plus"
	if RenderingServer.get_current_rendering_method() != required_renderer:
		print("F26 route refused renderer/preset mismatch; launch with --rendering-method " + required_renderer)
		quit(2)
		return
	if GRAPHICS.choose(_preset) != OK:
		print("F26 route could not persist the declared device preset.")
		quit(1)
		return
	root.size = Vector2i(int(_capture.resolution[0]), int(_capture.resolution[1]))
	if DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(_output_dir)):
		print("F26 route requires a fresh output directory; existing evidence kept.")
		quit(2)
		return
	if DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(_output_dir)) != OK:
		quit(1)
		return
	seed(int(_capture.seed))
	if not await _mount_production_world() or not _prepare_capture_shell():
		_write_route_receipt(false)
		quit(1)
		return
	# Only declared evidence setup teleports. Every timed leg walks through
	# the existing movement actions and live collision, without repairs.
	var start := _route_point(_route.start)
	if not start.is_finite():
		_failures.append("route start has no valid floor")
		_write_route_receipt(false)
		quit(1)
		return
	_player.global_position = start + Vector3.UP * float(_capture.floor_clearance_m)
	_player.velocity = Vector3.ZERO
	_rig.call("set_target", _player)
	_rig.global_position = _player.global_position
	_player.reset_physics_interpolation()
	_rig.reset_physics_interpolation()
	for frame in int(_capture.warmup_frames):
		await process_frame
	if not _player.is_on_floor():
		_failures.append("initial trainer did not settle on a production collider")
	if _biome_id != "stormwood":
		await _pin_time("day")
	if not _failures.is_empty():
		_write_route_receipt(false)
		quit(1)
		return
	_look.call("refresh_graphics")
	for frame in int(_capture.pose_frames):
		await process_frame
	await _route_still("start")
	if not _failures.is_empty():
		_write_route_receipt(false)
		quit(1)
		return
	_clock_start = _observed_environment()
	_navigation = NAVIGATOR.new(self, _player, _rig, _drive_route)
	process_frame.connect(_record_frame)
	_route_started_usec = Time.get_ticks_usec()
	_previous_frame_usec = _route_started_usec
	_measuring = true
	for raw: Array in _route.waypoints:
		var target := _route_point(raw)
		if not target.is_finite() or not await _walk_route_leg(target):
			_failures.append("physical route leg failed; no teleport correction")
			break
		_waypoints_reached += 1
	_release_route()
	while _failures.is_empty() and _samples.size() < int(_capture.minimum_timed_frames):
		if _wall_budget_exceeded():
			break
		await process_frame
	_navigation.reset()
	_release_route()
	_measuring = false
	_route_finished_usec = Time.get_ticks_usec()
	process_frame.disconnect(_record_frame)
	_clock_end = _observed_environment()
	await _route_still("end")
	_write_route_receipt(_failures.is_empty() and _waypoints_reached == _route.waypoints.size())
	quit(0 if _failures.is_empty() else 1)


func _route_point(raw: Array) -> Vector3:
	if raw.size() == 3:
		return Vector3(float(raw[0]), float(raw[1]), float(raw[2]))
	if raw.size() != 2:
		return Vector3(INF, INF, INF)
	var height := float(_world.call("ground_height_at", float(raw[0]), float(raw[1])))
	if not is_finite(height):
		return Vector3(INF, INF, INF)
	return Vector3(float(raw[0]), resolve_capture_ground(_player, float(raw[0]), float(raw[1]), height), float(raw[1]))


func _drive_route(x: float, y: float) -> void:
	Input.action_press(&"move_right", clampf(x, 0.0, 1.0))
	Input.action_press(&"move_left", clampf(-x, 0.0, 1.0))
	Input.action_press(&"move_back", clampf(y, 0.0, 1.0))
	Input.action_press(&"move_forward", clampf(-y, 0.0, 1.0))


func _wall_budget_exceeded() -> bool:
	if not _timed_out and Time.get_ticks_usec() - _route_started_usec \
			> float(_capture.maximum_wall_seconds) * 1000000.0:
		_timed_out = true
		_failures.append("route wall-clock budget exceeded")
	return _timed_out


func _walk_route_leg(target: Vector3) -> bool:
	_navigation.reset()
	# Use the existing navigator's physical step, with the declared total leg
	# budget also counting a fight/dialogue hold. Never wait ten hidden minutes
	# on its campaign-oriented walk_to() hold allowance during an FPS route.
	for frame in int(_capture.leg_budget_frames):
		if _wall_budget_exceeded():
			return false
		var offset := target - _player.global_position
		offset.y = 0.0
		if offset.length() <= float(_capture.arrival_tolerance_m):
			return true
		if not _navigation.can_walk():
			_release_route()
			_navigation.reset()
			await physics_frame
		else:
			await _navigation.step(target)
	return false


func _release_route() -> void:
	for action: StringName in [&"move_right", &"move_left", &"move_back", &"move_forward"]:
		Input.action_release(action)


func _record_frame() -> void:
	if not _measuring:
		return
	var now := Time.get_ticks_usec()
	_samples.append({"wall_ms": (now - _previous_frame_usec) / 1000.0,
		"process_ms": Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0,
		"physics_ms": Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0,
		"position": _vec3(_player.global_position)})
	_previous_frame_usec = now


func _route_still(label: String) -> void:
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	if image == null or image.is_empty() or image.get_size() != root.size \
			or image.save_png(_output_dir.path_join(label + ".png")) != OK:
		_failures.append("route %s screenshot failed" % label)


func _write_route_receipt(complete: bool) -> void:
	var data := {"complete": complete, "source_commit": _source_commit,
		"route_revision": _manifest.get("route_revision", ""),
		"route_config_sha256": _manifest.get("route_config_sha256", ""),
		"biome": _biome_id, "preset": _preset,
		"renderer": RenderingServer.get_current_rendering_method(), "display": DisplayServer.get_name(),
		"adapter": RenderingServer.get_video_adapter_name(), "resolution": [root.size.x, root.size.y],
		"engine": Engine.get_version_info(), "route": _route, "camera": _manifest.get("production_camera", {}),
		"waypoints_reached": _waypoints_reached, "samples": _samples, "failures": _failures,
		"environment_start": _clock_start, "environment_end": _clock_end,
		"elapsed_ms": maxf(0.0, (_route_finished_usec - _route_started_usec) / 1000.0),
		"scope": "Direct production-scene setup and one declared start teleport; timed InputMap/collision route. No speedup, hidden rendering, earned campaign, GPU-only timing or four-creature fight claim. PNG I/O outside timed interval. Stormwood live Surge/weather, others pinned day; route matrix and owner Ally test remain separate."}
	var file := FileAccess.open(_output_dir.path_join("route.json"), FileAccess.WRITE)
	if file == null:
		_failures.append("Cannot write route receipt")
		push_error("Cannot write route receipt")
		return
	file.store_string(JSON.stringify(data, "\t") + "\n")
	file.flush()
	var error := file.get_error()
	file.close()
	if error != OK:
		_failures.append("Cannot flush route receipt")
		push_error("Cannot flush route receipt")


func _observed_environment() -> Dictionary:
	var observed := {"position": _vec3(_player.global_position)}
	if _look.has_method("time_of_day"):
		observed["time_of_day"] = _look.call("time_of_day")
	if _look.has_method("hour"):
		observed["hour"] = _look.call("hour")
	if _weather != null and _weather.has_method("weather"):
		observed["weather"] = _weather.call("weather")
	var surge := _world.get_node_or_null(^"StormwoodSurge")
	if surge != null and surge.has_method("phase_info_at"):
		observed["surge"] = surge.call("phase_info_at", _player.global_position)
	return observed
