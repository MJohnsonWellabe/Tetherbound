extends "res://tests/test_case.gd"

## The pond evidence runner is nonshipping, but preflight-only is a safety
## contract: a coordinator may ask it to inspect Terrain3D readiness without
## clearing or replacing the last evidence frames. Keep the contract explicit
## even though the runner itself cannot be instantiated inside the pure suite.

const CAPTURE_PATH := "res://tools/capture_pond_day_readability.gd"


func test_preflight_reads_user_args_after_double_dash() -> void:
	var source := _source()
	assert_true(source.contains("OS.get_cmdline_user_args().has(\"--preflight-only\")"),
		"preflight-only must read Godot user args, which carry arguments after --")
	assert_false(source.contains("OS.get_cmdline_args().has(\"--preflight-only\")"),
		"engine args omit the coordinator's --preflight-only user argument")


func test_preflight_skips_evidence_mutation_before_capture() -> void:
	var source := _source()
	var preflight_guard := source.find("if not _preflight_only:")
	var clear_call := source.find("_clear_pngs(OUT_DIR)")
	var save_guard := source.find("if _preflight_only:")
	var save_call := source.find("image.save_png(path)")
	assert_true(preflight_guard >= 0 and preflight_guard < clear_call,
		"preflight-only must guard output-directory clearing")
	assert_true(save_guard >= 0 and save_guard < save_call,
		"preflight-only must exit the view before PNG save")


func _source() -> String:
	var file := FileAccess.open(CAPTURE_PATH, FileAccess.READ)
	if file == null:
		_fail("could not read %s" % CAPTURE_PATH)
		return ""
	return file.get_as_text()
