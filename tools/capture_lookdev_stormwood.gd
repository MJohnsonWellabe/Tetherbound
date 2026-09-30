extends "res://tools/capture_stormwood_f10_matrix.gd"

const BOOTSTRAP := preload("res://tools/lookdev_capture_bootstrap.gd")
var _graphics_capture: Dictionary = {}


func _run() -> void:
	_graphics_capture = BOOTSTRAP.prepare(self)
	if _graphics_capture.is_empty():
		quit(1)
		return
	# Full visual weather matrix, using the existing authored phase/aftermath
	# staging. Production always-purple grading is preserved in every phase.
	_phases_only.assign(PHASES)
	_hud = true
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--phases=") or arg == "--no-aftermath":
			push_error("Look-dev Stormwood matrix requires all phases and aftermath")
			quit(2)
			return
	await super._run()


func _capture(frame_id: String, description: String, full_size: bool, extra: Dictionary = {}) -> void:
	await super._capture(frame_id, description, full_size, extra.merged({"graphics_capture": _graphics_capture}, true))
	if not _frames.is_empty() and _frames.back().get("size", []) != [1920, 1080]:
		_failures.append("Stormwood look-dev frame is not native 1920x1080")


func _done() -> void:
	var expected := _matrix_stands().size() * (PHASES.size() + 1)
	if _frames.size() != expected:
		_failures.append("Stormwood matrix captured %d/%d planned frames" % [_frames.size(), expected])
	var file := FileAccess.open("%s/frames_%s.json" % [_output_dir, _label], FileAccess.WRITE)
	if file == null:
		_failures.append("Stormwood matrix receipt could not be opened")
	else:
		file.store_string(JSON.stringify({"graphics_capture": _graphics_capture, "frames": _frames,
			"failures": _failures, "complete": _failures.is_empty(), "planned_frames": expected,
			"scope": "Production CameraRig, staged stand/phase and aftermath flag, health restoration between Break frames, hour pin with production always-purple grading, ordinary HUD. Existing physics catch-up cap retained. Visual audit only; no earned campaign, performance, Hall or owner Ally claim."}, "\t") + "\n")
		file.flush()
		var error := file.get_error()
		file.close()
		if error != OK:
			_failures.append("Stormwood matrix receipt flush failed")
	for failure: String in _failures:
		push_error(failure)
	quit(0 if _failures.is_empty() else 1)
