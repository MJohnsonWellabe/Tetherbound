extends "res://tools/capture_stormwood_surge_phases.gd"

## F10#4 / S2 chapter frame matrix: forest, giant trunks, glass scars, rod line
## and the Stormheart, each in storm Calm and Break and again in the Long
## Storm aftermath (lighter rain, no lightning, scars), at full size for a
## code-blind Bars A/B judge. `--hud` keeps the HUD on (the F10#6 device
## profile capture); otherwise every HUD CanvasLayer is hidden.
##
##   xvfb-run -a -s "-screen 0 1920x1080x24" godot --path . \
##     --rendering-driver opengl3 --resolution 1920x1080 \
##     --script tools/capture_stormwood_f10_matrix.gd -- \
##     --out=res://ralph/reports/STORMWOOD/f10_4/r1 [--label=r1] \
##     [--stands=forest,giant,glass,rod_line,stormheart] [--phases=calm,break] \
##     [--no-aftermath] [--hud]
##
## Camera, placement and surge pinning are the parent tool's: the production
## CameraRig following the real Player, one Game.debug_teleport_to per stand,
## the surge clock pinned to `<phase start> + 2 s`. Staging is written to
## frames_<label>.json.

var _stands_only: Array[String] = []
var _phases_only: Array[String] = []
var _aftermath_on := true
var _hud := false
var _custom: Array[String] = []


func _run() -> void:
	_t0 = Time.get_ticks_msec()
	if DisplayServer.get_name() == "headless":
		push_error("matrix capture requires a rendering display; never use --headless")
		quit(1)
		return
	_biome_id = "stormwood"
	_character_id = "trainer"
	_label = "r1"
	_output_dir = "res://ralph/reports/STORMWOOD/f10_4/r1"
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			_output_dir = arg.trim_prefix("--out=")
		elif arg.begins_with("--label="):
			_label = arg.trim_prefix("--label=")
		elif arg.begins_with("--stands="):
			for part: String in arg.trim_prefix("--stands=").split(",", false):
				_stands_only.append(part.strip_edges())
		elif arg.begins_with("--phases="):
			for part: String in arg.trim_prefix("--phases=").split(",", false):
				_phases_only.append(part.strip_edges())
		elif arg == "--no-aftermath":
			_aftermath_on = false
		elif arg == "--hud":
			_hud = true
		elif arg.begins_with("--custom="):
			# id@x,z@fx,fy_above_ground,fz@pitch ; several separated by ';'
			for spec: String in arg.trim_prefix("--custom=").split(";", false):
				_custom.append(spec)
	if _phases_only.is_empty():
		_phases_only.assign(["calm", "break"])
	_coarse()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(_output_dir))
	if not await _mount_production_world() or not _prepare_capture_shell():
		_done()
		return
	_game = root.get_node(^"Game")
	_surge = _world.get_node_or_null(^"StormwoodSurge")
	_lightning = _world.get_node_or_null(^"StormwoodLightning")
	if _surge == null:
		_failures.append("StormwoodSurge node missing")
		_done()
		return
	_log("world mounted")
	_pin_day()
	_note("world hour pinned; Stormwood has one always-purple look (owner canon), so the hour is cosmetic")
	await _matrix_pass(false)
	if _aftermath_on:
		await _matrix_pass(true)
	_done()


func _matrix_stands() -> Array:
	var ground := func(x: float, z: float) -> float: return float(_world.call("ground_height_at", x, z))
	var rod_node := _world.get_node_or_null(^"StormwoodRodStations/verge_rod_station") as Node3D
	var station := rod_node.global_position if rod_node != null else Vector3(-650.0, ground.call(-650.0, 830.0), 830.0)
	var gh := deg_to_rad(92.3)
	var giant := Vector2(-240.0, 4463.6)
	var all := [
		{"id": "forest", "at": Vector2(-470.0, 3905.0),
			"focus": Vector3(-430.0, ground.call(-430.0, 3990.0) + 6.0, 3990.0), "pitch": 4.0,
			"text": "Deepwood forest near Lantern Hollow"},
		{"id": "giant", "at": giant,
			"focus": Vector3(giant.x + sin(gh) * 80.0, ground.call(-160.0, 4460.0) + 14.0, giant.y + cos(gh) * 80.0), "pitch": 6.0,
			"text": "Fallen Giant stand (Deepwood giant trunks)"},
		{"id": "glass", "at": Vector2(-310.0, 5050.0),
			"focus": Vector3(-100.0, ground.call(-310.0, 5050.0) + 20.0, 5470.0), "pitch": 2.0,
			"text": "Glass Field glass scars toward the Stormheart"},
		{"id": "rod_line", "at": Vector2(station.x, station.z) + Vector2(46.0, -58.0).normalized() * 30.0,
			"focus": station + Vector3.UP * 5.0, "pitch": 6.0,
			"text": "Verge Rod Station pylon (rod line), 30 m"},
		{"id": "stormheart", "at": Vector2(-100.0, 5390.0),
			"focus": Vector3(-100.0, ground.call(-100.0, 5390.0) + 45.0, 5470.0), "pitch": 14.0,
			"text": "Stormheart giant trunk from the southern approach road, 80 m"},
	]
	for spec: String in _custom:
		var part := spec.split("@")
		var at := part[1].split(",")
		var f := part[2].split(",")
		var fx := float(f[0])
		var fz := float(f[2])
		all.append({"id": part[0], "at": Vector2(float(at[0]), float(at[1])),
			"focus": Vector3(fx, ground.call(fx, fz) + float(f[1]), fz), "pitch": float(part[3]),
			"text": "custom stand " + part[0]})
	if _stands_only.is_empty():
		return all
	return all.filter(func(s: Dictionary) -> bool: return _stands_only.has(str(s.id)))


func _matrix_pass(aftermath: bool) -> void:
	if aftermath:
		var flags: RefCounted = _game.get("progression")
		if not bool(flags.call("has", "stormwood:long_storm_ended")):
			flags.call("set_flag", "stormwood:long_storm_ended", true)
		_note("flag stormwood:long_storm_ended set (aftermath pass)")
	var phases: Array = ["calm"] if aftermath else _phases_only
	for stand: Dictionary in _matrix_stands():
		await _stand(stand.at, stand.focus, float(stand.pitch))
		for phase: String in phases:
			await _enter_phase(phase, aftermath)
			_heal()
			if phase == "break" and not aftermath:
				await _await_sky_bolt()
			_hud_visible(_hud)
			var id := "%s_%s%s" % [stand.id, "aftermath_" if aftermath else "", phase]
			await _capture(id, "%s, %s%s" % [stand.text, "aftermath " if aftermath else "storm ", phase.capitalize()], true)
			_log("captured " + id)


## Native viewport size (1920x1080 on the documented command) instead of the
## parent's 1280x720, and the HUD state recorded as it really was.
func _capture(frame_id: String, description: String, full_size: bool, extra: Dictionary = {}) -> void:
	var image := await _grab()
	if image == null or image.is_empty():
		_failures.append("%s: empty viewport image" % frame_id)
		return
	var path := ProjectSettings.globalize_path("%s/%s.jpg" % [_output_dir, frame_id])
	if image.save_jpg(path, 0.85) != OK:
		_failures.append("%s: save_jpg failed" % frame_id)
		return
	_frames.append({
		"id": frame_id, "file": frame_id + ".jpg", "label": _label, "description": description,
		"size": [image.get_width(), image.get_height()], "full_size_requested": full_size,
		"camera": "player camera (production CameraRig/Camera3D)", "hud": _hud,
		"renderer": RenderingServer.get_current_rendering_driver_name(),
		"adapter": RenderingServer.get_video_adapter_name(),
		"player": _vec3(_player.global_position), "camera_pos": _vec3(_camera.global_position),
		"region": _region(), "surge_phase": str(_surge.get("phase")), "surge_elapsed": _surge_elapsed(),
		"long_storm_ended": bool(_game.get("progression").call("has", "stormwood:long_storm_ended")),
		"presentation": _presentation_state(), "staged": _staged.duplicate(),
	}.merged(extra, true))


## Break's decorative sky lightning fires every 0.55-1.3 s; a still taken at a
## random instant usually misses it. Step finely until a bolt or cloud flash is
## lit (at most ~20 s of game time) so the Break frame shows the phase's own
## lightning; the moment is recorded in the frame's staging.
func _await_sky_bolt() -> void:
	if _surge == null or not _surge.has_method("bolt_level"):
		return
	_fine(2)
	var waited := 0
	while waited < 600 and float(_surge.call("bolt_level")) < 0.3:
		await process_frame
		waited += 1
	_coarse()
	_note("Break frames timed on a decorative sky bolt (bolt_level >= 0.3) when one fires within ~20 s")
