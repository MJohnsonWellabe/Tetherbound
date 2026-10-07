extends "res://tools/capture_cloudreach_frame_matrix.gd"

## F08#3: the existing five settlement stands, day and night. Reuse the
## production matrix's exact-source/preset preflight, real floor checks and
## native following companion rather than parking the follower off camera.
## All party/progression/clock staging remains the matrix's disclosed fixture;
## this is settlement presentation evidence, not an earned route or gate proof.
## --preset=Low --low-resolution=1280x720 --source-commit=<SHA>
## --output=res://shots/lane-e/<fresh-folder>
var _windwatch_only := false

func _run() -> void:
	# Reject selectors before the inherited dispatcher can enter motion mode.
	for arg: String in OS.get_cmdline_user_args():
		if arg == "--only=windwatch":
			_windwatch_only = true
		elif arg in ["--motion", "--night"] or arg.begins_with("--only="):
			push_error("Settlement identity supports only --only=windwatch or the default complete day/night matrix")
			quit(2)
			return
	await super._run()


func _parse_args() -> void:
	# The general matrix uses numeric selectors; this child owns its explicit
	# two-view supplement. Parse its output/active options without converting
	# the literal "windwatch" selector to an integer in the parent parser.
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--output="):
			OUT = arg.trim_prefix("--output=").strip_edges().trim_suffix("/")
		elif arg.begins_with("--active="):
			_active_species = arg.trim_prefix("--active=").strip_edges()


func _run_matrix() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	_manifest = FileAccess.open(OUT + "/manifest.txt", FileAccess.WRITE)
	_manifest_line("# Cloudreach settlement identity: 5 existing stands x day/night; production matrix camera/floor/follower; staged five-owned party and progression")
	_manifest_line("# coverage " + ("Windwatch day/night supplement; other 8 judged views retained from37690725109" if _windwatch_only else "full 10-view matrix"))
	if not _graphics_capture.is_empty():
		_manifest_line("# graphics_capture " + JSON.stringify(_graphics_capture))
	var number := 100
	for view: Dictionary in [
		{"id":"place_cliffhold_approach", "at":Vector3(-267,838,4020.3), "target":Vector3(-340,838,3970), "pitch":5.0},
		{"id":"place_cliffhold_court", "at":Vector3(-309.2,830,3991.2), "target":Vector3(-350,841,3980), "pitch":8.0},
		# Existing matrix row25's third court stand, farther from the tower;
		# 5-degree stick pitch keeps the camera higher than the blocked low view.
		{"id":"place_cliffhold_windwatch", "at":Vector3(-352,830,3954), "target":Vector3(-360,843,3988), "pitch":5.0},
		{"id":"place_galefoot_approach", "at":Vector3(-280,180,480), "target":Vector3(-290,190,528), "pitch":8.0},
		{"id":"place_galefoot_hearth", "at":Vector3(-271,180,522), "target":Vector3(-294,190,528), "pitch":10.0},
	]:
		for time_name: String in ["day", "night"]:
			number += 1
			if _windwatch_only and str(view.id) != "place_cliffhold_windwatch":
				continue
			await _capture_row({"n":number,
				"region":"upper_cloudreach" if str(view.id).contains("cliffhold") else "gate_lower_cliffs",
				"row":view.id, "time":time_name, "sheet":"regions",
				"stands":[view.at], "target":view.target, "pitch_deg":view.pitch,
				"why":"Existing settlement identity stand; floor-verified trainer, production rig and native following companion"})
	var expected := 2 if _windwatch_only else 10
	if _frames.size() != expected:
		_skips.append("Settlement identity requires %d frames; captured %d" % [expected, _frames.size()])
	_write_sheets()
	_finish(_frames.size())


func _finish(written: int) -> void:
	# Unlike the general matrix's legacy partial mode, this bounded recorder
	# requires every planned view, including without a preset. The explicit
	# Windwatch supplement requires both lighting states; default still ten.
	_set_render(true)
	var expected := 2 if _windwatch_only else 10
	var summary := "settlement identity: %d/%d frames written, %d rows skipped" % [written, expected, _skips.size()]
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
	quit(0 if written == expected and _skips.is_empty() and receipt_ok else 1)
