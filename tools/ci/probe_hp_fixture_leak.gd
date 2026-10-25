extends SceneTree
## Temporary NETFIX probe: run the hp-fixture child repeatedly with --verbose
## (CPU contended) and print what leaks at exit. Removed with the fix.
func _initialize() -> void:
	var path := ProjectSettings.globalize_path("res://tools/ci/probe_hp_fixture_runner.gd")
	var burners: Array[int] = []
	for i in 3: burners.append(OS.create_process("sh", ["-c", "while :; do :; done"]))
	var runs := int(OS.get_environment("PROBE_RUNS")) if OS.has_environment("PROBE_RUNS") else 40
	var leaks := 0
	for i in runs:
		var out: Array = []
		var t := Time.get_ticks_msec()
		var code := OS.execute(OS.get_executable_path(), ["--headless", "--verbose", "--path", ProjectSettings.globalize_path("res://"), "--script", path], out, true)
		var text := "\n".join(out)
		var leaked := text.contains("ObjectDB instances leaked") or text.contains("resources still in use")
		print("PROBE run=%d code=%d ms=%d leaked=%s" % [i, code, Time.get_ticks_msec() - t, leaked])
		if code != 0 and not leaked: print(text.right(1500))
		if leaked:
			leaks += 1
			for line: String in text.split("\n"):
				if line.contains("eaked") or line.contains("still in use") or line.contains("Resource") and line.contains("use") or line.contains("HP_FIXTURE_RESULT"):
					print("  ", line.left(400))
			var tail := text.split("\n")
			print("  --- tail ---")
			for k in range(maxi(0, tail.size() - 60), tail.size()): print("  ", tail[k].left(300))
	for pid in burners: OS.kill(pid)
	print("PROBE leaks=%d/%d" % [leaks, runs])
	quit(0)
