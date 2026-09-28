extends "res://tools/capture_cloudreach_frame_matrix.gd"

## Reuse the chapter's validated production-camera stands. Add a fixed seed
## and the JSON receipt expected by phase2_compact_evidence.py.
var _capture_seed := 2042


func _run() -> void:
	for argument: String in OS.get_cmdline_user_args():
		if argument == "--motion":
			push_error("Phase 2 JSON wrapper supports stills only; use capture_cloudreach_frame_matrix.gd for motion receipts.")
			quit(2)
			return
		if argument.begins_with("--seed="):
			_capture_seed = int(argument.trim_prefix("--seed="))
	seed(_capture_seed)
	await super._run()


func _finish(written: int) -> void:
	var records: Array[Dictionary] = []
	for frame: Dictionary in _frames:
		var identity := str(frame.name)
		records.append({"frame_id": "cloudreach_matrix__" + identity,
			"file": OUT.path_join(identity + ".png")})
	var receipt := {
		"seed": _capture_seed,
		"resolution": [root.size.x, root.size.y],
		"display_server": DisplayServer.get_name(),
		"rendering_method": RenderingServer.get_current_rendering_method(),
		"adapter": RenderingServer.get_video_adapter_name(),
		"frames": records,
		"failures": _skips,
		"complete": not records.is_empty() and _skips.is_empty(),
		"fixture_disclosure": "Existing chapter frame matrix: declared party/progress, teleport to validated authored route stands, production CameraRig yaw/pitch, pinned clock and hidden HUD. No earned-route or combat claim.",
		"stand_receipt": OUT.path_join("manifest.txt"),
	}
	var file := FileAccess.open(OUT.path_join("manifest.json"), FileAccess.WRITE)
	if file == null:
		push_error("Cannot open Phase 2 capture receipt: %s" % error_string(FileAccess.get_open_error()))
		quit(1)
		return
	file.store_string(JSON.stringify(receipt, "\t") + "\n")
	file.flush()
	var write_error := file.get_error()
	file.close()
	if write_error != OK:
		push_error("Cannot write Phase 2 capture receipt: %s" % error_string(write_error))
		quit(1)
		return
	super._finish(written)
