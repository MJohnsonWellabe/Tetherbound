extends SceneTree

## Offload adapter for the existing render.yml script interface. This process
## hosts no world. Python verifies/restores original bytes, then serially owns
## the reviewed overlay and the real native producer's child processes.
func _init() -> void:
	var producer := "loop"
	var options: Dictionary = {}
	for argument: String in OS.get_cmdline_user_args():
		var pair: PackedStringArray = argument.split("=", true, 1)
		if pair.size() != 2 or pair[1].is_empty() or options.has(pair[0]) or pair[0] not in ["--producer", "--loop-output", "--loop-profile", "--loop-profile-sha256", "--behind-guest-peer", "--shipping-config"]:
			push_error("Unknown actual-input producer argument: " + argument)
			quit(1)
			return
		options[pair[0]] = pair[1]
	producer = str(options.get("--producer", "loop"))
	if producer not in ["loop", "boss_four", "behind"]:
		push_error("Unknown actual-input producer: " + producer)
		quit(1)
		return
	if options.has("--shipping-config") and options["--shipping-config"] != "true":
		push_error("--shipping-config must be true when supplied")
		quit(1)
		return
	var python := OS.get_environment("TB_F48_PROCESS_PYTHON")
	if python.is_empty(): python = "python" if OS.get_name() == "Windows" else "python3"
	var output: Array = []
	var arguments := PackedStringArray([
		ProjectSettings.globalize_path("res://tools/net/f48_produce_actual.py"),
		"--godot", OS.get_executable_path(),
		# render.yml's uploader excludes hidden directories, including .tmp.
		"--output", ProjectSettings.globalize_path("res://ralph/reports/INTEGRATION/main-green/native-f48-" + producer),
		"--producer", producer])
	if options.has("--shipping-config"):
		arguments.append("--shipping-config")
	for option: String in ["--loop-output", "--loop-profile", "--loop-profile-sha256", "--behind-guest-peer"]:
		if options.has(option):
			arguments.append(option)
			var value := str(options[option])
			arguments.append(ProjectSettings.globalize_path(value) if option in ["--loop-output", "--loop-profile"] else value)
	var result := OS.execute(python, arguments, output, true)
	for line: String in output: print(line)
	quit(result)
