extends SceneTree

## CI launcher for collect_script_profile.py --project: runs the collector
## (which starts a second, headless engine on physics_route_probe.gd with the
## built-in script profiler attached) and prints its summary.
## -- --biome=meadows|water --source-commit=<sha> [--native]


func _init() -> void:
	var biome := "meadows"
	var commit := ""
	var native := false
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--biome="):
			biome = arg.trim_prefix("--biome=")
		elif arg.begins_with("--source-commit="):
			commit = arg.trim_prefix("--source-commit=")
		elif arg == "--native":
			native = true
	var project := ProjectSettings.globalize_path("res://")
	var output := ProjectSettings.globalize_path("user://script-profile-" + biome)
	var args := [project.path_join("tools/performance/collect_script_profile.py"),
		"--engine", OS.get_executable_path(), "--project", project, "--biome", biome,
		"--source-commit", commit, "--output", output, "--timeout-seconds", "1500"]
	if native:
		args.append("--profile-native-calls")
	var out: Array = []
	var code := OS.execute("python3", args, out, true)
	for line: String in out:
		print(line)
	quit(code)
