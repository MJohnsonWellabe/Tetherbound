extends SceneTree

## Fixed render.yml offload for the original packaged four-peer F48 smoke.
## Full CI already runs the two-peer suites and all 24 transaction cuts.
## Only profile paths are relocated; the existing integrity gate, overlay
## owner, native smoke and process cleanup remain their original callers.
## No engine, save, reward or acceptance result is synthesized here.
func _init() -> void:
	if not OS.get_cmdline_user_args().is_empty():
		printerr("f48_smoke_via_render: this fixed smoke accepts no user arguments")
		quit(2)
		return
	var root := ProjectSettings.globalize_path("res://")
	var bundle := root.path_join("tests/fixtures/f48-inputs")
	var out := root.path_join("ralph/reports/INTEGRATION/main-green/native-f48-boss-four-smoke")
	if not FileAccess.file_exists(bundle.path_join("profile.json")):
		printerr("f48_smoke_via_render: the committed complete actual-input bundle is required")
		quit(2)
		return
	if DirAccess.dir_exists_absolute(out) or FileAccess.file_exists(out):
		printerr("f48_smoke_via_render: fresh native output required; preserve prior evidence")
		quit(2)
		return
	var python := OS.get_environment("TB_F48_PROCESS_PYTHON")
	if python.is_empty(): python = "python" if OS.get_name() == "Windows" else "python3"
	var profile := out.path_join("relocated-profile.json")
	var code := _execute(python, [root.path_join("tools/net/f48_relocate_profile.py"),
		"--bundle", bundle, "--output", profile])
	if code != 0:
		quit(code)
		return
	code = _execute(python, [root.path_join("tools/net/f48_ci_ready.py"),
		"--profile", profile, "--bundle", bundle])
	if code != 0:
		quit(code)
		return
	OS.set_environment("TB_F48_PROFILE", profile)
	OS.set_environment("TB_F48_PROCESS_PYTHON", python)
	OS.set_environment("GODOT_BIN", OS.get_executable_path())
	code = _execute("bash", [root.path_join("tools/net/run_net_smoke.sh"),
		"f48_boss_four", "--peers=4", "--out=" + out])
	print("f48_smoke_via_render: original packaged four-peer smoke exit %d" % code)
	quit(code)


func _execute(program: String, arguments: Array) -> int:
	var output: Array = []
	var code := OS.execute(program, arguments, output, true)
	for chunk: Variant in output: print(str(chunk))
	if code < 0:
		printerr("f48_smoke_via_render: could not launch required program " + program)
		return 1
	return code
