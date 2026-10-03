extends "res://tests/smoke_net_f18_travel.gd"

# peers: 1
## Actual traversal/input refusal only, explicitly separate from earned travel.
## --flying selects the flight proof; default is the dry-to-water walk proof.
func _run() -> void:
	await process_frame
	heartbeat_silence_tolerance_s = 150.0
	if OS.get_cmdline_user_args().has("--f18-draw-on-request"):
		RenderingServer.set_render_loop_enabled(false)
		print("F18_NATIVE_SAMPLING: native display/Compatibility1280x720; automatic rendering disabled, one actual refusal draw requested; Dummy audio. No continuous-render performance or audio acceptance.")
	require_peer_logs_without(["SCRIPT ERROR", "Parse Error", "Invalid call", "ERROR:"],
		"F18 traversal refusal peer logs have no engine/script errors")
	if not await launch(1, "title"):
		quit(await finish())
		return
	var flying: bool = OS.get_cmdline_user_args().has("--flying")
	if not await _f18_pass(0, "f18_boot_world" if flying else "f18_boot_water_fixture", {}, 12000): return
	if not await _f18_pass(0, "f18_fixture", {}): return
	if flying:
		if not await _f18_pass(0, "fly_setup", {"species": "galecrest", "settle": 30, "search_rings": 3}): return
	else:
		if not await _f18_pass(0, "f18_stage_water_lesson", {}): return
	var kind: String = "flying" if flying else "swimming"
	if not await _f18_pass(0, "f18_traversal_refusal", {"kind": kind}): return
	if OS.get_cmdline_user_args().has("--native-peer=0"):
		var pixels: Dictionary = _f18_witnesses.back().result.data.get("native_pixels", {})
		check(pixels.get("passed") == true and pixels.get("captured") == true,
			"F18 actual refusal native frame captured; independent visual verdict still required")
	var file := FileAccess.open(_run_dir.path_join("F18_WITNESSES.json"), FileAccess.WRITE)
	if file != null: file.store_string(JSON.stringify(_f18_witnesses, "\t"))
	print("F18_TRAVERSAL_REFUSAL_FIXTURES: own key/starter/free-play; " +
		("flight unlock/carrier/launch-site fixture, actual ground double Jump thereafter." if flying else
		"direct Water scene and one dry lesson staging fixture, actual stick walk into water thereafter."))
	print("No earned opening/unlock/portal crossing or rendered/audio acceptance claimed.")
	quit(await finish())
