extends "res://tools/capture_cloudreach_frame_matrix.gd"

## Bounded slices of one committed camera set. Same production floor, follower,
## rig and preset checks as the chapter matrix. No earned-route/fight claim.
const CAMERA_SET := "res://tools/visual_judge/camera_sets/cloudreach-look.json"
const BOOT_3D_SCALE := 1.0 / 3.0
const RESTORE_DRAW_FRAMES := 8
var _look_chunk := "cliffhold"
var _fixed_views: Array = []
var _requested_hour := 10.0
var _requested_fov := 70.0
var _capture_resolution := Vector2i.ZERO
var _boot_receipt: Dictionary = {}


func _run() -> void:
	var has_preset := false
	var has_source := false
	for argument: String in OS.get_cmdline_user_args():
		has_preset = has_preset or argument in ["--preset=Low", "--preset=Medium", "--preset=High"]
		has_source = has_source or argument.begins_with("--source-commit=")
		if argument.begins_with("--chunk="):
			_look_chunk = argument.trim_prefix("--chunk=")
		if argument in ["--night", "--motion"] or argument.begins_with("--only="):
			push_error("Biome look uses only the fixed --chunk selector")
			quit(2)
			return
	if not has_preset or not has_source:
		push_error("Biome look requires --preset and exact --source-commit")
		quit(2)
		return
	var raw: Variant = JSON.parse_string(FileAccess.get_file_as_string(CAMERA_SET))
	if raw is Dictionary:
		seed(int(raw.get("seed", 2042)))
		for view: Dictionary in raw.get("views", []):
			if str(view.chunk) == _look_chunk:
				_fixed_views.append(view)
	if _fixed_views.is_empty() or _fixed_views.size() > 4:
		push_error("Unknown or unbounded biome look camera chunk")
		quit(2)
		return
	await super._run()


func _boot() -> bool:
	var resolution: Array = _graphics_capture.get("resolution", [])
	if resolution.size() != 2 or not is_equal_approx(root.scaling_3d_scale, 1.0):
		push_error("Cloudreach look requires a declared native-resolution capture")
		return false
	_capture_resolution = Vector2i(int(resolution[0]), int(resolution[1]))
	# Cloudreach's complete Forward+ build awaits thousands of actual draws.
	# Reduce only the unrecorded 3D raster; window size/aspect, quality preset,
	# construction, actors, physics, draw distance and world content stay intact.
	# Do not disable rendering: the production upload scheduler awaits post_draw.
	var boot_scale := BOOT_3D_SCALE if RenderingServer.get_current_rendering_method() == "forward_plus" else 1.0
	root.scaling_3d_scale = boot_scale
	_boot_receipt = {"method": "reduced_3d_boot_raster_full_world",
		"boot_3d_scale": root.scaling_3d_scale, "capture_3d_scale": 1.0,
		"window_resolution": resolution, "restore_draw_frames": RESTORE_DRAW_FRAMES,
		"scope": "Visual fixture only; not normal startup, campaign or performance proof"}
	print("LOOK_BOOT begin " + JSON.stringify(_boot_receipt))
	var started_ms := Time.get_ticks_msec()
	var booted: bool = await super._boot()
	_boot_receipt["world_boot_ms"] = Time.get_ticks_msec() - started_ms
	# Restore even on a failed parent boot. No image is saved at the boot scale.
	root.scaling_3d_scale = 1.0
	_set_render(true)
	if not booted:
		print("LOOK_BOOT failed " + JSON.stringify(_boot_receipt))
		return false
	for frame in RESTORE_DRAW_FRAMES:
		await RenderingServer.frame_post_draw
	_boot_receipt["restored_native_resolution"] = _native_resolution_ready()
	print("LOOK_BOOT restored " + JSON.stringify(_boot_receipt))
	if not _native_resolution_ready():
		push_error("Cloudreach look did not restore its native capture raster")
		return false
	return true


func _native_resolution_ready() -> bool:
	return is_equal_approx(root.scaling_3d_scale, 1.0) \
		and root.size == _capture_resolution \
		and Vector2i(root.get_texture().get_size()) == _capture_resolution


func _capture_row(row: Dictionary) -> void:
	if not _native_resolution_ready():
		_skips.append(str(row.row) + ": native capture raster changed")
		return
	var count := _frames.size()
	await super._capture_row(row)
	if not _native_resolution_ready():
		_skips.append(str(row.row) + ": native capture raster changed during pose")
	if _frames.size() > count:
		var captured: Image = _frames.back()["image"]
		if captured.get_size() != _capture_resolution:
			_skips.append(str(row.row) + ": saved frame is not native resolution")


func _pin_hour(_hour_from_parent: float) -> void:
	super._pin_hour(_requested_hour)
	if _camera != null:
		_camera.fov = _requested_fov


func _run_matrix() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	_manifest = FileAccess.open(OUT + "/manifest.txt", FileAccess.WRITE)
	_manifest_line("# Fixed Cloudreach look chunk: " + _look_chunk)
	_manifest_line("# camera_set_sha256 " + FileAccess.get_file_as_string(CAMERA_SET).sha256_text())
	_manifest_line("# profile_sha256 " + FileAccess.get_file_as_string("res://data/config/cloudreach_biome_look.json").sha256_text())
	_manifest_line("# candidate " + str(not preload("res://scripts/world/cloudreach_biome_look.gd").config().is_empty()))
	_manifest_line("# cliffhold_detail " + JSON.stringify({
		"candidate": not preload("res://scripts/world/cloudreach_cliffhold_detail.gd").config().is_empty(),
		"config_sha256": FileAccess.get_file_as_string("res://data/config/cloudreach_cliffhold_detail.json").sha256_text()}))
	_manifest_line("# graphics_capture " + JSON.stringify(_graphics_capture))
	_manifest_line("# boot_capture " + JSON.stringify(_boot_receipt))
	_manifest_line("# Fixture: direct chapter mount, five owned companions and upper-route flags; teleported trainer, production follower, frozen clock and weather transition timer (rain still follows player). No route, combat, Ally or visual PASS claim.")
	var weather := _world.get_node_or_null(^"WorldWeather")
	if weather == null or not weather.has_method("set_weather"):
		_skips.append("Production weather missing")
	else:
		# set_weather() deliberately leaves the production random timer running.
		# Prevent an old boot timer changing a slow A/B frame's pinned weather,
		# while retaining _process()'s production rain-follow-player behavior.
		weather.set("_cycle_timer", 0.0)
		weather.set("_next_change_at", INF)
		for view: Dictionary in _fixed_views:
			_requested_hour = float(view.time)
			_requested_fov = float(view.fov)
			weather.call("set_weather", str(view.weather))
			for frame in 24:
				await process_frame
			var stand: Array = view.stand
			var target: Array = view.target
			await _capture_row({"n": int(view.number), "region": str(view.region),
				"row": str(view.id), "time": str(view.time_name), "sheet": "regions",
				"stands": [Vector3(float(stand[0]), float(stand[1]), float(stand[2]))],
				"target": Vector3(float(target[0]), float(target[1]), float(target[2])),
				"pitch_deg": float(view.pitch), "why": "Committed single stand; no fallback camera"})
			if str(weather.call("weather")) != str(view.weather) \
					or not is_equal_approx(_camera.fov, _requested_fov) \
					or absf(_clock_hour() - _requested_hour) > 0.01:
				_skips.append(str(view.id) + ": observed weather/FOV/hour mismatch")
			_manifest_line("# observed " + str(view.id) + " weather=" + str(weather.call("weather"))
				+ " fov=" + str(_camera.fov) + " hour=" + str(_clock_hour()))
	_write_sheets()
	_finish(_frames.size())


func _finish(written: int) -> void:
	_set_render(true)
	var summary := "look chunk %s: %d/%d frames, %d failures" % [_look_chunk, written, _fixed_views.size(), _skips.size()]
	_manifest_line("# " + summary)
	var receipt_ok := _manifest != null
	if _manifest != null:
		_manifest.flush()
		receipt_ok = _manifest.get_error() == OK
		_manifest.close()
	receipt_ok = receipt_ok and FileAccess.get_file_as_string(OUT + "/manifest.txt").contains("# " + summary)
	for failure: String in _skips:
		push_error(failure)
	quit(0 if written == _fixed_views.size() and _skips.is_empty() and receipt_ok else 1)
