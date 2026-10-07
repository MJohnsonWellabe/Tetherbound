extends SceneTree

## Offload adapter for the existing render.yml script interface. This process
## hosts no world. Python verifies/restores original bytes, then serially owns
## the reviewed overlay and the real native producer's child processes.
func _init() -> void:
	var producer := "loop"
	var options: Dictionary = {}
	for argument: String in OS.get_cmdline_user_args():
		var pair: PackedStringArray = argument.split("=", true, 1)
		if pair.size() != 2 or pair[1].is_empty() or options.has(pair[0]) or pair[0] not in ["--producer", "--loop-output", "--loop-profile", "--loop-profile-sha256", "--behind-guest-peer", "--diagnostic-trace", "--players-capture"]:
			push_error("Unknown actual-input producer argument: " + argument)
			quit(1)
			return
		options[pair[0]] = pair[1]
	producer = str(options.get("--producer", "loop"))
	if producer not in ["loop", "boss_four", "behind"]:
		push_error("Unknown actual-input producer: " + producer)
		quit(1)
		return
	if options.has("--players-capture"):
		if producer != "boss_four" or options["--players-capture"] != "1":
			push_error("Players capture requires --producer=boss_four --players-capture=1")
			quit(1)
			return
		var resolution := OS.get_environment("TB_NET_PROOF_RESOLUTION")
		if resolution.is_empty() and DisplayServer.get_name() != "headless":
			# render.yml already selects this native window's raster. Forward
			# it through the existing peer-render environment, not a new profile.
			var window_size := DisplayServer.window_get_size()
			resolution = "%dx%d" % [window_size.x, window_size.y]
		if resolution not in ["1280x720", "1920x1080"]:
			push_error("Players capture requires the existing render resolution 1280x720 or 1920x1080")
			quit(1)
			return
		OS.set_environment("TB_NET_PROOF_RENDER", "1")
		OS.set_environment("TB_NET_PROOF_RESOLUTION", resolution)
		OS.set_environment("TB_F48_CAPTURE_PLAYERS", "1")
		print("F48 Players capture enabled: four original native ENet peers at " + resolution + "; visual evidence requires review, no earned campaign credit.")
	if options.has("--diagnostic-trace"):
		if options["--diagnostic-trace"] != "1":
			push_error("Actual-input diagnostic trace requires --diagnostic-trace=1")
			quit(1)
			return
		# The existing Python adapter inherits and records both trace flags.
		# This diagnostic invocation keeps the original profile and deadlines.
		OS.set_environment("TB_PEER_PHASE_TRACE", "1")
		OS.set_environment("TB_BACKGROUND_WORK_TRACE", "1")
		print("F48 diagnostic trace enabled: diagnostic only, no acceptance credit.")
	var python := OS.get_environment("TB_F48_PROCESS_PYTHON")
	if python.is_empty(): python = "python" if OS.get_name() == "Windows" else "python3"
	var output: Array = []
	var arguments := PackedStringArray([
		ProjectSettings.globalize_path("res://tools/net/f48_produce_actual.py"),
		"--godot", OS.get_executable_path(),
		# render.yml's uploader excludes hidden directories, including .tmp.
		"--output", ProjectSettings.globalize_path("res://ralph/reports/INTEGRATION/main-green/native-f48-" + producer),
		"--producer", producer])
	for option: String in ["--loop-output", "--loop-profile", "--loop-profile-sha256", "--behind-guest-peer"]:
		if options.has(option):
			arguments.append(option)
			var value := str(options[option])
			arguments.append(ProjectSettings.globalize_path(value) if option in ["--loop-output", "--loop-profile"] else value)
	var result := OS.execute(python, arguments, output, true)
	for line: String in output: print(line)
	quit(result)
