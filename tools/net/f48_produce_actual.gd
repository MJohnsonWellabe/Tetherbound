extends SceneTree

## Offload adapter for the existing render.yml script interface. This process
## hosts no world. Python verifies/restores original bytes, then serially owns
## the reviewed overlay and the real native producer's child processes.
func _init() -> void:
	var python := OS.get_environment("TB_F48_PROCESS_PYTHON")
	if python.is_empty(): python = "python" if OS.get_name() == "Windows" else "python3"
	var output: Array = []
	var arguments := PackedStringArray([
		ProjectSettings.globalize_path("res://tools/net/f48_produce_actual.py"),
		"--godot", OS.get_executable_path(),
		"--output", ProjectSettings.globalize_path("res://.tmp/f48-actual-producer")])
	var result := OS.execute(python, arguments, output, true)
	for line: String in output: print(line)
	quit(result)
