extends SceneTree

## Explicit independent diagnostic batch, never a strict F48 producer entry.
## render.yml: script=tools/net/f48_diagnostic_via_render.gd
## args: out=ralph/reports/INTEGRATION/f48-diagnostic-<fresh> [render=1]
func _init() -> void:
	var output_path: String = ""
	var render: bool = false
	var cases: String = ""
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("out="): output_path = arg.trim_prefix("out=")
		elif arg == "render=1": render = true
		elif arg.begins_with("cases="):
			if not cases.is_empty():
				printerr("f48 diagnostic: duplicate cases selection")
				quit(2)
				return
			cases = arg.trim_prefix("cases=")
			if cases.is_empty():
				printerr("f48 diagnostic: empty cases selection")
				quit(2)
				return
	if output_path.is_empty() or output_path.contains("..") or output_path.is_absolute_path():
		printerr("f48 diagnostic: fresh relative out=<directory> required")
		quit(2)
		return
	var root_path: String = ProjectSettings.globalize_path("res://")
	var arguments: PackedStringArray = [root_path.path_join("tools/net/f48_diagnostic_batch.py"),
		"--output",root_path.path_join(output_path),"--godot",OS.get_executable_path(),"--run"]
	if render: arguments.append("--render")
	if not cases.is_empty(): arguments.append_array(["--cases",cases])
	var output: Array = []
	var code: int = OS.execute("python3",arguments,output,true)
	for value: Variant in output: print(str(value))
	print("F48 DIAGNOSTIC ONLY completed with raw batch exit %d; no acceptance credit" % code)
	quit(code)
