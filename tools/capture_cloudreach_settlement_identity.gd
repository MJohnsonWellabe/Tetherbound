extends "res://tools/capture_cloudreach_frame_matrix.gd"

## F08#3: the existing five settlement stands, day and night. Reuse the
## production matrix's exact-source/preset preflight, real floor checks and
## native following companion rather than parking the follower off camera.
## All party/progression/clock staging remains the matrix's disclosed fixture;
## this is settlement presentation evidence, not an earned route or gate proof.
## --preset=Low --low-resolution=1280x720 --source-commit=<SHA>
## --output=res://shots/lane-e/<fresh-folder>

func _run() -> void:
	# Reject selectors before the inherited dispatcher can enter motion mode.
	for arg: String in OS.get_cmdline_user_args():
		if arg in ["--motion", "--night"] or arg.begins_with("--only="):
			push_error("Settlement identity always captures all five stands at day and night; partial selectors are unsupported")
			quit(2)
			return
	await super._run()


func _run_matrix() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	_manifest = FileAccess.open(OUT + "/manifest.txt", FileAccess.WRITE)
	_manifest_line("# Cloudreach settlement identity: 5 existing stands x day/night; production matrix camera/floor/follower; staged five-owned party and progression")
	if not _graphics_capture.is_empty():
		_manifest_line("# graphics_capture " + JSON.stringify(_graphics_capture))
	var number := 100
	for view: Dictionary in [
		{"id":"place_cliffhold_approach", "at":Vector3(-267,838,4020.3), "target":Vector3(-340,838,3970), "pitch":5.0},
		{"id":"place_cliffhold_court", "at":Vector3(-309.2,830,3991.2), "target":Vector3(-350,841,3980), "pitch":8.0},
		{"id":"place_cliffhold_windwatch", "at":Vector3(-356,830,3962), "target":Vector3(-360,843,3988), "pitch":14.0},
		{"id":"place_galefoot_approach", "at":Vector3(-280,180,480), "target":Vector3(-290,190,528), "pitch":8.0},
		{"id":"place_galefoot_hearth", "at":Vector3(-271,180,522), "target":Vector3(-294,190,528), "pitch":10.0},
	]:
		for time_name: String in ["day", "night"]:
			number += 1
			await _capture_row({"n":number,
				"region":"upper_cloudreach" if str(view.id).contains("cliffhold") else "gate_lower_cliffs",
				"row":view.id, "time":time_name, "sheet":"regions",
				"stands":[view.at], "target":view.target, "pitch_deg":view.pitch,
				"why":"Existing settlement identity stand; floor-verified trainer, production rig and native following companion"})
	if _frames.size() != 10:
		_skips.append("Settlement identity requires 10 frames; captured %d" % _frames.size())
	_write_sheets()
	_finish(_frames.size())


func _finish(written: int) -> void:
	# Unlike the general matrix's legacy partial mode, this bounded recorder
	# requires every view in every invocation, including without a preset.
	_set_render(true)
	var summary := "settlement identity: %d/10 frames written, %d rows skipped" % [written, _skips.size()]
	_manifest_line("# " + summary)
	var receipt_ok := _manifest != null
	if _manifest != null:
		_manifest.flush()
		receipt_ok = _manifest.get_error() == OK
		_manifest.close()
	var receipt := FileAccess.get_file_as_string(OUT + "/manifest.txt") if receipt_ok else ""
	receipt_ok = receipt_ok and receipt.contains("# " + summary)
	if not _graphics_capture.is_empty():
		receipt_ok = receipt_ok and receipt.contains("# graphics_capture " + JSON.stringify(_graphics_capture))
	if not receipt_ok:
		push_error("settlement identity: final receipt open/write/flush/readback failed")
	for failure: String in _skips:
		push_error(failure)
	quit(0 if written == 10 and _skips.is_empty() and receipt_ok else 1)
