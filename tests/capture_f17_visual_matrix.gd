extends "res://tests/smoke_crossing_hall_circuit.gd"

## F17#6 village/Hall capture matrix for the code-blind full-bar judge.
## Reuses the real farmhouse-door -> Main Street -> Hall nave walk and the
## Hall circuit helpers (parsed joypad move/look, real collision, one
## inherited initial fixture placement). Camera turns use the look stick only.
##
##   xvfb-run -a -s "-screen 0 1920x1080x24" godot --path . \
##     --rendering-method gl_compatibility --rendering-driver opengl3 \
##     --audio-driver Dummy --resolution 1920x1080 \
##     --script tests/capture_f17_visual_matrix.gd -- --capture-dir=/abs/out
##
## Stations: farm door (approach), mid street (left/right frontage, starter
## called out), Hall approach from the last houses (forward, reverse down the
## road), nave (forward, both arch walls,
## reverse to the door), Shrine Room (pedestals). Each station is shot at day,
## golden, night and in rain; the clock is frozen per shot. The 3D view is off
## while walking (software rendering) and on for each photograph only.
## Inert by default (not a test_*.gd); headless refuses.
const TIMES := ["day", "golden", "night"]
const SHOT_SETTLE_FRAMES := 10
const RAIN_SETTLE_FRAMES := 14

var _out := ""
var _rows: Array[Dictionary] = []
var _mid_done := false
var _approach_done := false
var _shot_events: Dictionary = {}
var _only: PackedStringArray = []


func _run() -> void:
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--capture-dir="):
			_out = argument.substr("--capture-dir=".length())
		elif argument.begins_with("--only="):
			# Iteration aid: shoot only frames whose "station_time_weather"
			# name starts with one of these comma-separated prefixes.
			_only = argument.substr("--only=".length()).split(",", false)
	if DisplayServer.get_name() == "headless" or _out.is_empty() or not _out.is_absolute_path():
		print("F17 matrix FAIL: needs a native renderer and an absolute --capture-dir")
		quit(2)
		return
	DirAccess.make_dir_recursive_absolute(_out)
	root.get_viewport().disable_3d = true
	await super()


func _capture(label: String) -> void:
	if _world == null or _player == null:
		return
	if label == "travel":
		var x := _player.global_position.x
		if not _mid_done and x > 50.0:
			# Mid street: call the starter out (a creature on screen, as
			# played) and look at both frontages.
			_mid_done = true
			await _press("creature_recall")
			for _frame in 60:
				await physics_frame
			var heading := float(_rig.get("yaw"))
			await _turn_to(heading + PI * 0.5)
			await _station("street-mid-left", false)
			await _turn_to(heading - PI * 0.5)
			await _station("street-mid-right", false)
			await _turn_to(heading)
		elif not _approach_done and x > 66.0:
			# Hall approach from the last houses, far enough back that the
			# roofline and tower are in frame; then back down the road.
			_approach_done = true
			var heading := float(_rig.get("yaw"))
			await _station("hall-approach", true)
			await _turn_to(heading + PI)
			await _station("hall-approach-reverse", false)
			await _turn_to(heading)
		return
	if _shot_events.has(label):
		return
	_shot_events[label] = true
	if label == "actual farmhouse doorway":
		await _station("farm-door", true)


func _after_hall_arrival(hall: Node3D) -> bool:
	var forward := float(_rig.get("yaw"))
	await _station("nave-forward", true)
	for side: String in ["left", "right"]:
		var centroid := Vector3.ZERO
		var count := 0
		for arch: Node in get_nodes_in_group("crossing_hall_arches"):
			var local := hall.to_local((arch as Node3D).global_position)
			if absf(local.x) > 1.0 and (local.x < 0.0) == (side == "left"):
				centroid += (arch as Node3D).global_position
				count += 1
		if count > 0:
			centroid /= float(count)
			await _turn_to(_yaw_toward(_xz(), Vector2(centroid.x, centroid.z)))
			await _station("nave-arches-" + side, false)
	await _turn_to(forward + PI)
	await _station("nave-reverse", true)
	var stands: Dictionary = {}
	for stand: Node in get_nodes_in_group("crossing_hall_pedestals"):
		stands[str(stand.get_meta("biome", ""))] = stand
	var route := _gallery_route(hall, stands)
	if route.is_empty():
		return false
	if not await _walk_to_target(hall, hall.to_global(route.door), Vector3.ZERO, "shrine doorway"):
		return false
	if not await _walk_to_target(hall, hall.to_global(route.aisle), Vector3.ZERO, "shrine aisle"):
		return false
	var centre := Vector3.ZERO
	for stand: Node3D in stands.values():
		centre += stand.global_position
	centre /= float(stands.size())
	var span := Vector2.ZERO
	for stand: Node3D in stands.values():
		var d := Vector2(stand.global_position.x - centre.x, stand.global_position.z - centre.z)
		span = Vector2(maxf(span.x, absf(d.x)), maxf(span.y, absf(d.y)))
	# Look down the long axis of the pedestal row from the aisle.
	var long_axis := Vector2(1, 0) if span.x >= span.y else Vector2(0, 1)
	var aim := Vector2(centre.x, centre.z) + long_axis * maxf(span.x, span.y)
	await _turn_to(_yaw_toward(_xz(), aim))
	await _station("shrine-pedestals", true)
	await _turn_to(_yaw_toward(_xz(), Vector2(centre.x, centre.z) - long_axis * maxf(span.x, span.y)))
	await _station("shrine-pedestals-reverse", false)
	var receipt := FileAccess.open(_out.path_join("frames.json"), FileAccess.WRITE)
	receipt.store_string(JSON.stringify({"renderer": RenderingServer.get_current_rendering_method(),
		"window": [DisplayServer.window_get_size().x, DisplayServer.window_get_size().y],
		"frames": _rows,
		"method": "real farmhouse->Main Street->Hall walk on parsed joypad move/look and collision after one inherited initial farmhouse placement; camera turns by look stick only; WorldLook named times with the clock frozen; WorldWeather presets; HUD visible as played; no body/camera/model writes, no image resizing."}, "\t") + "\n")
	receipt.close()
	print("F17 matrix PASS: %d frames saved to %s" % [_rows.size(), _out])
	return true


func _station(name: String, with_rain: bool) -> void:
	_release_all()
	var look := _world.get_node_or_null("WorldLook")
	var weather := _world.get_node_or_null("WorldWeather")
	if look == null or weather == null:
		_failed = "WorldLook/WorldWeather missing"
		return
	look.call("set_clock_frozen", true)
	for _frame in 20:
		await physics_frame
	root.get_viewport().disable_3d = false
	var shots: Array = []
	for time_name: String in TIMES:
		shots.append([time_name, "clear"])
	if with_rain:
		shots.append(["day", "rain"])
		shots.append(["night", "rain"])
	if not _only.is_empty():
		shots = shots.filter(func(shot: Array) -> bool:
			var shot_name := "%s_%s_%s" % [name, shot[0], shot[1]]
			for prefix: String in _only:
				if shot_name.begins_with(prefix): return true
			return false)
	for shot: Array in shots:
		weather.call("set_weather", shot[1])
		look.call("apply_time", shot[0])
		var settle := RAIN_SETTLE_FRAMES if shot[1] == "rain" else SHOT_SETTLE_FRAMES
		for _frame in settle:
			await process_frame
		await RenderingServer.frame_post_draw
		var image := root.get_viewport().get_texture().get_image()
		var file := "%s_%s_%s.png" % [name, shot[0], shot[1]]
		var saved := image != null and not image.is_empty() and image.save_png(_out.path_join(file)) == OK
		var cam := _rig.get_node_or_null("Camera3D") as Camera3D
		_rows.append({"station": name, "time": shot[0], "weather": shot[1], "image": file, "saved": saved,
			"body": [_player.global_position.x, _player.global_position.y, _player.global_position.z],
			"camera": [cam.global_position.x, cam.global_position.y, cam.global_position.z] if cam != null else [],
			"yaw": float(_rig.get("yaw"))})
		print("F17 matrix shot %s saved=%s" % [file, saved])
	weather.call("set_weather", "clear")
	look.call("apply_time", "day")
	root.get_viewport().disable_3d = true

