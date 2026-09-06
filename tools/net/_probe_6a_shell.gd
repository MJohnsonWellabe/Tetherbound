extends SceneTree

## Wave 6 lane 6.A. WHAT A REALM SHELL ACTUALLY COSTS.
##
## Spike S2 (`ralph/reports/MP-0D-SPIKE-HOSTCOST-0905/REPORT.md`) measured a
## POST-HOC free -- freeing nodes after `_ready()` had already built them --
## and got 30 % of the frame time back for 1.2 % of the memory, because the
## 385,333-prop scatter and Terrain3D's resident data were built before
## anything was freed. D97 was amended on the strength of that: a shell is a
## SKIP-BUILD flag. This probe measures the skip-build variant, which is the
## measurement D97's amendment defers the shell's memory budget to.
##
##   ~/godot-bin/godot --headless --path . --script tools/net/_probe_6a_shell.gd -- --mode=full
##   ~/godot-bin/godot --headless --path . --script tools/net/_probe_6a_shell.gd -- --mode=shell
##
## One mode per process, deliberately: two worlds in one process share an
## allocator and neither number would mean anything. Compare the two runs.
##
## `--realm=meadows|cloudreach` picks the world. Meadows is the expensive one
## and the one S2's table is about.
##
## `--mode=host_pair --realm=<A> --shell=<B>` is the DECISIVE measurement and
## the reason this probe exists rather than S2's: it builds realm A in full
## and then stands realm B up beside it as a shell, in ONE process, exactly
## the way `realm_shells.gd::_stand_up()` does. That is what a host actually
## pays under directive rule 16, and no combination of the single-world
## numbers predicts it, because the two worlds share an allocator, a physics
## server and a resource cache.
##
## The pair is bounded at two: the Meadows and Cloudreach are the only realms
## (CLAUDE.md forbids a Biome 2 implementation), so a host holds at most ONE
## shell however many peers join. Four peers do not mean four shells.

const SETTLE_FRAMES := 240
const SAMPLE_FRAMES := 300

const SCENES := {
	"meadows": "res://scenes/world/meadows_playground.tscn",
	"cloudreach": "res://scenes/world/cloudreach_cliffs.tscn",
}


func _init() -> void:
	await _run()


func _run() -> void:
	var mode := "full"
	var realm := "meadows"
	var shell_realm := ""
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--mode="):
			mode = arg.substr(7)
		elif arg.begins_with("--realm="):
			realm = arg.substr(8)
		elif arg.begins_with("--shell="):
			shell_realm = arg.substr(8)
	var scene := str(SCENES.get(realm, ""))
	if scene.is_empty():
		print("6A-SHELL: unknown realm '%s'" % realm)
		quit(2)
		return

	print("=== 6.A shell cost: realm=%s mode=%s  %s ==="
		% [realm, mode, Time.get_datetime_string_from_system()])
	# Measured BEFORE the scene is even loaded, so the delta is the world and
	# not the engine.
	var static_boot := OS.get_static_memory_usage()

	var t0 := Time.get_ticks_msec()
	var packed: PackedScene = load(scene)
	var world: Node = packed.instantiate()
	if mode == "shell":
		# The same two writes `realm_shells.gd::_stand_up()` makes, in the same
		# place: before `add_child()`, which is what runs `_ready()`.
		world.set("simulation_only", true)
		world.set("shell_realm", realm)
	root.add_child(world)
	for i in SETTLE_FRAMES:
		await physics_frame
	var boot_ms := Time.get_ticks_msec() - t0

	var static_first := OS.get_static_memory_usage()
	var vmhwm_first := _status_kb("VmHWM:")
	var shell_ms := 0
	if mode == "host_pair":
		if shell_realm.is_empty():
			shell_realm = "cloudreach" if realm == "meadows" else "meadows"
		print("--- realm %s standing; adding a %s SHELL beside it ---" % [realm, shell_realm])
		var t1 := Time.get_ticks_msec()
		var shell_scene := str(SCENES.get(shell_realm, ""))
		var shell_node: Node = (load(shell_scene) as PackedScene).instantiate()
		shell_node.set("simulation_only", true)
		shell_node.set("shell_realm", shell_realm)
		root.add_child(shell_node)
		for i in SETTLE_FRAMES:
			await physics_frame
		shell_ms = Time.get_ticks_msec() - t1
		print("shell stood up in %.1f s" % (shell_ms / 1000.0))

	var static_after := OS.get_static_memory_usage()
	var samples := await _sample_frames(SAMPLE_FRAMES)

	print("--- %s / %s ---" % [realm, mode])
	if mode == "host_pair":
		print("first world alone: %.1f MB static, %.1f MB VmHWM"
			% [(static_first - static_boot) / 1048576.0, vmhwm_first / 1024.0])
		print("the %s SHELL added: %.1f MB static, %.1f MB VmHWM, %.1f s"
			% [shell_realm, (static_after - static_first) / 1048576.0,
				(_status_kb("VmHWM:") - vmhwm_first) / 1024.0, shell_ms / 1000.0])
	print("boot (load+instantiate+add_child+%d physics frames): %.1f s" % [SETTLE_FRAMES, boot_ms / 1000.0])
	print("static_mem: %.1f MB (world alone: %.1f MB)"
		% [static_after / 1048576.0, (static_after - static_boot) / 1048576.0])
	print("VmHWM: %.1f MB   VmRSS: %.1f MB"
		% [_status_kb("VmHWM:") / 1024.0, _status_kb("VmRSS:") / 1024.0])
	print("median frame: %.3f ms   p95: %.3f ms" % [_median(samples), _p95(samples)])
	print("S2 reference (full Meadows boot, 4 vCPU box): 49.9 s warm / 84.2 s cold, 2,783 MB static, 3,237 MB VmHWM")
	print("6A-SHELL-RESULT %s%s %s boot_s=%.1f static_mb=%.1f world_mb=%.1f vmhwm_mb=%.1f median_ms=%.3f" % [
		realm, ("+" + shell_realm + "-shell") if mode == "host_pair" else "", mode,
		(boot_ms + shell_ms) / 1000.0, static_after / 1048576.0,
		(static_after - static_boot) / 1048576.0, _status_kb("VmHWM:") / 1024.0, _median(samples),
	])
	quit(0)


func _sample_frames(n: int) -> Array[float]:
	var samples: Array[float] = []
	for i in n:
		var t0 := Time.get_ticks_usec()
		await physics_frame
		samples.append((Time.get_ticks_usec() - t0) / 1000.0)
	return samples


func _median(samples: Array[float]) -> float:
	var s := samples.duplicate()
	s.sort()
	return s[s.size() / 2]


func _p95(samples: Array[float]) -> float:
	var s := samples.duplicate()
	s.sort()
	return s[mini(s.size() - 1, int(float(s.size()) * 0.95))]


func _status_kb(field: String) -> int:
	var f := FileAccess.open("/proc/self/status", FileAccess.READ)
	if f == null:
		return -1
	while not f.eof_reached():
		var line := f.get_line()
		if line.begins_with(field):
			return int(line.replace(field, "").replace("kB", "").strip_edges())
	return -1
