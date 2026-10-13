extends "res://tools/capture_stormwood_f10_matrix.gd"

## Bounded look-pass pieces, using production mounting, camera and Surge logic.
## --stands and --phases select a piece of the committed camera set, never a
## new camera. A piece is visual evidence only, not the full F41 matrix.
## --look-candidate previews one profile in memory. Other catalog flags retain
## their exact committed values in both halves of a matched comparison.
const LOOK := preload("res://scripts/world/stormwood_look.gd")
const CAMERAS := "res://tools/visual_judge/camera_sets/F41-look.json"
var _look_candidate := false
var _camera_set: Dictionary = {}
var _clock_hour := 12.0
var _aftermath_only := false
var _expected_frame_ids: Array[String] = []


func _run() -> void:
	_camera_set = JSON.parse_string(FileAccess.get_file_as_string(CAMERAS))
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
	_look_candidate = OS.get_cmdline_user_args().has("--look-candidate")
	LOOK.capture_preview = _look_candidate
	_hud = true
	await super._run()


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
	super._done()


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
