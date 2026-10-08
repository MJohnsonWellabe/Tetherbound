extends "res://tools/catalogue_survey.gd"

## F26 Low visual-only route stills. Places the production trainer at each
## declared point of data/config/lookdev_routes.json (start + waypoints) and
## captures the production camera looking along the route. This is a still
## matrix for a code-blind visual judge on software/CPU renderers, where the
## timed physical walk (capture_lookdev_route.gd) cannot finish in its wall
## budget. It records NO frame time and makes no traversal/collision claim.
##   godot --path . --rendering-driver opengl3 --resolution 1920x1080 \
##     --script tools/capture_lookdev_route_stills.gd -- --biome=meadows \
##     --preset=Low --source-commit=<40-char SHA> --output=<fresh directory>

const BOOTSTRAP := preload("res://tools/lookdev_capture_bootstrap.gd")
const ROUTE_TOOL := preload("res://tools/capture_lookdev_route.gd")
const ROUTES_PATH := "res://data/config/lookdev_routes.json"
var _graphics_capture: Dictionary = {}
var _route: Dictionary = {}
var _requested_weather := ""


func _run() -> void:
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--weather="):
			_requested_weather = argument.trim_prefix("--weather=")
			if _requested_weather not in ["clear", "rain"]:
				push_error("Route still weather must be clear or rain when supplied")
				quit(1)
				return
	_graphics_capture = BOOTSTRAP.prepare(self)
	if _graphics_capture.is_empty():
		quit(1)
		return
	await super._run()


func _prepare_character_fixture(game: Node) -> void:
	# Same declared render fixture as the timed route: skip Grandpa's opening
	# modal so the ordinary HUD world is visible. Not an earned opening.
	if _biome_id != "meadows":
		return
	for flag: String in ROUTE_TOOL.MEADOWS_OPENING_FLAGS:
		game.get("progression").call("set_flag", flag)


func _load_plan() -> bool:
	var config: Variant = JSON.parse_string(FileAccess.get_file_as_string(ROUTES_PATH))
	if not config is Dictionary or not (config as Dictionary).get("routes", {}).has(_biome_id):
		push_error("route stills: no declared route for %s" % _biome_id)
		return false
	_route = config.routes[_biome_id]
	var points: Array = [_route.start]
	points.append_array(_route.waypoints)
	for index in points.size():
		# Honor the inherited, already-parsed named subset without changing
		# authored points, indices, next-point headings or default coverage.
		if not _matches_subset("%s__route_%02d" % [_biome_id, index]):
			continue
		var raw: Array = points[index]
		var here := Vector2(float(raw[0]), float(raw[raw.size() - 1]))
		var next_raw: Array = points[index + 1] if index + 1 < points.size() else points[index - 1]
		var there := Vector2(float(next_raw[0]), float(next_raw[next_raw.size() - 1]))
		var forward := (there - here).normalized()
		if index + 1 >= points.size():
			forward = -forward
		for time_name: String in _times:
			_planned.append({"frame_id": "%s__route_%02d__%s" % [_biome_id, index, time_name],
				"biome_id": _biome_id, "route_point_index": index,
				"route_point": raw, "position_xz": [here.x, here.y],
				"view_heading_deg": rad_to_deg(atan2(forward.x, forward.y)), "time": time_name})
	return not _planned.is_empty()


func _begin_manifest() -> void:
	super._begin_manifest()
	_manifest["graphics_capture"] = _graphics_capture
	_manifest["route"] = _route
	_manifest["fixture_disclosure"] = "Production scene, CameraRig and ordinary HUD. Debug travel at each declared route point and audit-only clock pin. Meadows seeds the timed route's declared MEADOWS_OPENING_FLAGS to skip its opening modal; other biomes use the base catalogue character fixture. Not an earned opening, campaign, traversal, save or frame-time proof."
	_manifest["route_stills_scope"] = "Visual-only stills at declared route points with production camera/HUD. Debug travel and clock pin. No frame time, traversal, collision or performance claim."
	_manifest["route_weather_fixture"] = _requested_weather
	_manifest["route_weather_scope"] = "Optional named production weather held for stills by emptying its scheduler order; idle particle follow/visibility stays live. No earned/cycle/save/co-op claim. Omitted option preserves original behavior."


func _pin_time(time_name: String) -> Dictionary:
	var observed: Dictionary = await super._pin_time(time_name)
	if observed.is_empty() or _requested_weather.is_empty():
		return observed
	var weather := _world.get_node_or_null("WorldWeather")
	if weather == null or not weather.has_method("set_weather"):
		_failures.append("Route weather fixture requires production WorldWeather")
		return {}
	weather.set("_order", [])
	weather.set_process(true)
	weather.call("set_weather", _requested_weather)
	weather.call("_follow_player")
	for _frame in LIGHT_SETTLE_FRAMES:
		await process_frame
	if str(weather.call("weather")) != _requested_weather:
		_failures.append("Route production weather differs from requested fixture")
		return {}
	var rain: GPUParticles3D = weather.get("_rain")
	if rain == null:
		_failures.append("Route production rain emitter unavailable")
		return {}
	observed["route_weather"] = str(weather.call("weather"))
	observed["rain_particles_visible"] = rain.visible
	observed["rain_particles_emitting"] = rain.emitting
	return observed


func _capture_row(row: Dictionary) -> void:
	var raw: Array = row.route_point
	if raw.size() == 2:
		await super._capture_row(row)
		return
	# Authored XYZ (stacked Cloudreach floors): travel by XZ for streaming,
	# then stand on the declared height exactly as the timed route does.
	var game := root.get_node_or_null(^"Game")
	if game == null or not bool(game.call("debug_teleport_to", float(raw[0]), float(raw[2]), _biome_id, "")):
		_failures.append("%s: Game.debug_teleport_to refused destination" % str(row.frame_id))
		_write_manifest()
		return
	for _frame in ARRIVE_FRAMES:
		await physics_frame
	var yaw := deg_to_rad(float(row.view_heading_deg))
	var forward := Vector2(sin(yaw), cos(yaw))
	_player.global_position = Vector3(float(raw[0]), float(raw[1]) + TRAINER_CLEARANCE, float(raw[2]))
	_player.velocity = Vector3.ZERO
	_player.rotation.y = atan2(forward.x, forward.y)
	_rig.call("set_target", _player)
	var camera_yaw := capture_yaw(forward)
	_rig.set("yaw", camera_yaw)
	_rig.rotation = Vector3(float(_rig.get("pitch")), camera_yaw, 0.0)
	_rig.global_position = _player.global_position
	_camera.make_current()
	_player.reset_physics_interpolation()
	_rig.reset_physics_interpolation()
	_camera.reset_physics_interpolation()
	for _frame in POPULATE_FRAMES:
		await physics_frame
	var observed_clock := await _pin_time(str(row.time))
	if observed_clock.is_empty():
		_write_manifest()
		return
	for _frame in POSE_FRAMES:
		await process_frame
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	var path := "%s/%s.png" % [_output_dir, str(row.frame_id)]
	if image == null or image.is_empty() or image.get_size() != root.size:
		_failures.append("%s: viewport image is empty or wrong-sized" % str(row.frame_id))
	elif image.save_png(path) != OK:
		_failures.append("%s: save_png failed" % str(row.frame_id))
	else:
		var record := row.duplicate(true)
		record["file"] = path
		record["debug_travel"] = true
		record["player_position"] = _vec3(_player.global_position)
		record["camera_position"] = _vec3(_camera.global_position)
		record["observed_clock"] = observed_clock
		_records.append(record)
		print("ROUTE STILL %s -> %s" % [str(row.frame_id), path])
	_write_manifest()
