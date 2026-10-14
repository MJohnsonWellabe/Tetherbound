extends "res://tools/capture_stormwood_f10_matrix.gd"

## Bounded look-pass pieces, using production mounting, camera and Surge logic.
## --stands and --phases select a piece of the committed camera set, never a
## new camera. A piece is visual evidence only, not the full F41 matrix.
## --look-candidate previews one profile in memory. Other catalog flags retain
## their exact committed values in both halves of a matched comparison.
const LOOK := preload("res://scripts/world/stormwood_look.gd")
const CAMERAS := "res://tools/visual_judge/camera_sets/F41-look.json"
const RASTER := preload("res://tools/stormwood_capture_raster.gd")
var _look_candidate := false
var _camera_set: Dictionary = {}
var _clock_hour := 12.0
var _aftermath_only := false
var _expected_frame_ids: Array[String] = []
var _last_native_viewport: Dictionary = {}
var _capture_resolution := Vector2i.ZERO


func _run() -> void:
	_camera_set = JSON.parse_string(FileAccess.get_file_as_string(CAMERAS))
	_capture_resolution = RASTER.exact_size(_camera_set.get("resolution"))
	if _capture_resolution == Vector2i.ZERO:
		push_error("Stormwood camera resolution must contain two exact positive integer dimensions")
		quit(2)
		return
	if not _validate_request():
		quit(2)
		return
	var has_preset := false
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--preset="):
			has_preset = true
		if arg.begins_with("--clock-hour="):
			_clock_hour = float(arg.trim_prefix("--clock-hour="))
		if arg.begins_with("--custom="):
			push_error("Stormwood look comparisons require the committed camera set")
			quit(2)
			return
	if not _clock_hour in _camera_set.clock_hours:
		push_error("Stormwood look hour must come from its fixed camera set")
		quit(2)
		return
	if not has_preset:
		push_error("Stormwood look capture requires named preset and source SHA")
		quit(2)
		return
	if not await _prepare_native_viewport():
		quit(2)
		return
	if OS.get_cmdline_user_args().has("--viewport-readiness-only"):
		# Exercise the production preflight and raw-image gate, then quit before
		# the parent loads any world. No capture receipt, image save or preview.
		var image := await _grab()
		if image == null or _world != null:
			push_error("Stormwood viewport probe failed its raw image or unloaded-world check")
			quit(2)
			return
		var source := ""
		for arg: String in OS.get_cmdline_user_args():
			if arg.begins_with("--source-commit="):
				source = arg.trim_prefix("--source-commit=")
		print("STORMWOOD_VIEWPORT_PROBE PASS ", JSON.stringify({
			"source_commit": source, "native_viewport": _last_native_viewport,
			"image_size": [image.get_width(), image.get_height()],
			"resolution_input_types": [typeof(_camera_set.resolution[0]), typeof(_camera_set.resolution[1])],
			"world_loaded": false, "renderer": RenderingServer.get_current_rendering_method()}))
		quit(0)
		print("STORMWOOD_VIEWPORT_PROBE QUIT_SCHEDULED")
		return
	_look_candidate = OS.get_cmdline_user_args().has("--look-candidate")
	LOOK.capture_preview = _look_candidate
	_hud = true
	await super._run()


func _prepare_native_viewport() -> bool:
	# A decorated 1080p window can be clamped to the Windows work area even
	# after root.size is assigned. Fullscreen uses the display's physical size;
	# reject a different display size rather than rescale a captured image.
	if DisplayServer.get_name() == "headless":
		push_error("Stormwood look capture requires a native display")
		return false
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	root.content_scale_factor = 1.0
	root.mode = Window.MODE_EXCLUSIVE_FULLSCREEN
	root.size = _capture_resolution
	for _frame in 30:
		await process_frame
		await RenderingServer.frame_post_draw
		_last_native_viewport = _native_viewport_state()
		if _native_viewport_matches(_last_native_viewport):
			print("STORMWOOD LOOK VIEWPORT_READY ", JSON.stringify(_last_native_viewport))
			return true
	push_error("Stormwood native viewport must match the fixed camera raster before world load: " + JSON.stringify(_last_native_viewport))
	return false


func _native_viewport_state() -> Dictionary:
	var window_size := DisplayServer.window_get_size(root.get_window_id())
	var viewport_size := Vector2i(root.get_visible_rect().size)
	var texture_size := Vector2i(root.get_texture().get_size())
	return {"window_size": [window_size.x, window_size.y],
		"viewport_size": [viewport_size.x, viewport_size.y],
		"texture_size": [texture_size.x, texture_size.y],
		"window_mode": int(root.mode), "content_scale_mode": int(root.content_scale_mode)}


func _native_viewport_matches(observed: Dictionary) -> bool:
	return RASTER.matches_viewport(observed, _capture_resolution)


func _grab() -> Image:
	var image := await super._grab()
	_last_native_viewport = _native_viewport_state()
	if not _native_viewport_matches(_last_native_viewport) or image == null \
			or not RASTER.matches_size(image.get_size(), _capture_resolution):
		_failures.append("native viewport/raster changed before capture; no image resize or save: " + JSON.stringify(_last_native_viewport))
		return null
	return image


func _validate_request() -> bool:
	var selections: Dictionary = {}
	var args := OS.get_cmdline_user_args()
	_aftermath_only = args.has("--aftermath-only")
	if _aftermath_only and args.has("--no-aftermath"):
		push_error("Conflicting aftermath capture selections")
		return false
	for arg: String in args:
		var key := arg.get_slice("=", 0)
		if key not in ["--stands", "--phases", "--clock-hour", "--preset"]:
			continue
		if not arg.contains("=") or selections.has(key):
			push_error("Missing value or repeated capture selection: " + key)
			return false
		selections[key] = arg.substr(key.length() + 1)
	if selections.has("--clock-hour") and not str(selections["--clock-hour"]).is_valid_float():
		push_error("Capture hour must be numeric")
		return false
	if selections.get("--preset", "") not in _camera_set.presets:
		push_error("Stormwood look requires the fixed Medium or High preset")
		return false
	if _aftermath_only and selections.has("--phases"):
		push_error("Aftermath-only captures Calm; omit --phases")
		return false
	var known_stands: Array = []
	for view: Dictionary in _camera_set.views:
		known_stands.append(str(view.id))
	var chosen: Dictionary = {}
	for key: String in ["--stands", "--phases"]:
		var allowed: Array = known_stands if key == "--stands" else _camera_set.phases
		var defaults: Array = known_stands if key == "--stands" else ["calm", "break"]
		var values: Array = []
		if selections.has(key):
			for part: String in str(selections[key]).split(",", true):
				var value := part.strip_edges()
				if value not in allowed or value in values:
					push_error("Unknown, empty or duplicate capture selection: " + key + "=" + value)
					return false
				values.append(value)
		else:
			values = defaults
		chosen[key] = values
	for stand: String in chosen["--stands"]:
		if not _aftermath_only:
			for phase: String in chosen["--phases"]:
				_expected_frame_ids.append(stand + "_" + phase)
		if not args.has("--no-aftermath"):
			_expected_frame_ids.append(stand + "_aftermath_calm")
	return true


func _matrix_pass(aftermath: bool) -> void:
	if _aftermath_only and not aftermath:
		return
	await super._matrix_pass(aftermath)


func _done() -> void:
	var actual: Array[String] = []
	for frame: Dictionary in _frames:
		actual.append(str(frame.id))
	actual.sort()
	var expected := _expected_frame_ids.duplicate()
	expected.sort()
	if actual != expected:
		_failures.append("incomplete capture piece: expected %s; observed %s" % [str(expected), str(actual)])
	print("STORMWOOD LOOK FINALIZE_BEGIN t_msec=", Time.get_ticks_msec(), " frames=", _frames.size(), " failures=", _failures.size())
	super._done()
	# SceneTree.quit schedules exit at the end of this iteration. This marker
	# proves the receipt/quit call returned, never that native teardown finished.
	print("STORMWOOD LOOK QUIT_SCHEDULED t_msec=", Time.get_ticks_msec())


func _matrix_stands() -> Array:
	var stands: Array = []
	for view: Dictionary in _camera_set.views:
		if not _stands_only.is_empty() and str(view.id) not in _stands_only:
			continue
		var focus: Array = view.focus
		stands.append({"id": view.id,
			"at": Vector2(float(view.pos[0]), float(view.pos[2])),
			"focus": Vector3(float(focus[0]), float(_world.call("ground_height_at", float(focus[0]), float(focus[2]))) + float(focus[1]), float(focus[2])),
			"pitch": float(view.pitch), "text": view.text})
	if stands.is_empty():
		_failures.append("no requested stand exists in the committed camera set")
	return stands


func _pin_day() -> void:
	# The legacy 'day' preset is 08:00; the fixed comparison explicitly pins
	# 12:00 or 00:00 while retaining Stormwood's invariant purple presentation.
	var cycle: RefCounted = _look.get("_cycle")
	_look.call("resume_at_elapsed", float(cycle.call("elapsed_for_hour", _clock_hour)))
	_look.call("set_clock_frozen", true)
	_note("fixed camera-set clock hour %.2f; presentation remains purple" % _clock_hour)


func _stand(xz: Vector2, look_at: Vector3, pitch_deg: float, probe_above: float = 4.0) -> void:
	await super._stand(xz, look_at, pitch_deg, probe_above)
	for view: Dictionary in _camera_set.views:
		if Vector2(float(view.pos[0]), float(view.pos[2])).is_equal_approx(xz):
			_camera.fov = float(view.fov)
			break


func _capture(frame_id: String, description: String, full_size: bool, extra: Dictionary = {}) -> void:
	var look := _world.get_node_or_null("StormwoodLook")
	# Let the bounded material walk finish after streamed chunks settle.
	if _look_candidate:
		if look == null:
			_failures.append("StormwoodLook missing in candidate")
			return
		for _frame in 240:
			if (look.get("_pending") as Array).is_empty():
				break
			await process_frame
		if not (look.get("_pending") as Array).is_empty():
			_failures.append("material traversal did not settle within 240 frames")
			return
		if (look.get("_meshes") as Dictionary).is_empty():
			_failures.append("candidate has no adapted vegetation mesh assets")
			return
	var frame_count := _frames.size()
	await super._capture(frame_id, description, full_size, extra.merged({
		"look_candidate": _look_candidate,
		"look_config_sha256": FileAccess.get_file_as_string(LOOK.CONFIG_PATH).sha256_text(),
		"camera_set_sha256": FileAccess.get_file_as_string(CAMERAS).sha256_text(),
		"look_material_variants": (look.get("_materials") as Dictionary).size() if look != null else 0,
		"look_mesh_variants": (look.get("_meshes") as Dictionary).size() if look != null else 0,
		"clock_hour": float(_look.call("hour")), "fov": _camera.fov,
		"requested_frame_ids": _expected_frame_ids,
		"scope": "fixed-camera look-pass piece; staged position and Surge; no earned route or full matrix claim"
	}, true))
	if _frames.size() > frame_count:
		_frames.back()["native_viewport"] = _last_native_viewport.duplicate(true)
