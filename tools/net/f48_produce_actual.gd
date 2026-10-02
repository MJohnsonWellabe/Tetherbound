extends SceneTree

## Offload adapter for the existing render.yml script interface. This process
## hosts no world. Python verifies/restores original bytes, then serially owns
## the reviewed overlay and the real native producer's child processes.
func _init() -> void:
	var producer := "loop"
	for argument: String in OS.get_cmdline_user_args():
		if argument != "--producer=boss_four":
			push_error("Unknown actual-input producer argument: " + argument)
			quit(1)
			return
		producer = "boss_four"
	var python := OS.get_environment("TB_F48_PROCESS_PYTHON")
	if python.is_empty(): python = "python" if OS.get_name() == "Windows" else "python3"
	var output: Array = []
	var arguments := PackedStringArray([
		ProjectSettings.globalize_path("res://tools/net/f48_produce_actual.py"),
		"--godot", OS.get_executable_path(),
		# render.yml's uploader excludes hidden directories, including .tmp.
		"--output", ProjectSettings.globalize_path("res://ralph/reports/INTEGRATION/main-green/native-f48-" + producer),
		"--producer", producer])
	var result := OS.execute(python, arguments, output, true)
	for line: String in output: print(line)
	quit(result)
