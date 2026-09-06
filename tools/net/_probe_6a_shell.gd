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

## Lane MP-REALM-REOPEN. The three phases of a stand-up, timed separately, and
## the number the reopen actually turns on: the WORST 60-consecutive-physics-
## frame wall time during the build. `tools/net/peer_runner.gd` heartbeats
## every 60 physics frames and `net_harness.gd` calls a peer silent after 15 s,
## so a shell whose worst 60-frame window exceeds 15 s kills the session it is
## standing in -- and a real host stutters for exactly as long. `boot_ms` alone
## cannot see this: a 24 s boot spread evenly over 240 frames is fine, and the
## same 24 s spent in three 8 s slices is not.
const SETTLE_FRAMES := 240
const SAMPLE_FRAMES := 300
const HEARTBEAT_FRAMES := 60

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
	var load_ms := Time.get_ticks_msec() - t0
	var t_inst := Time.get_ticks_msec()
	var world: Node = packed.instantiate()
	var instantiate_ms := Time.get_ticks_msec() - t_inst
	if mode == "shell":
		# The same two writes `realm_shells.gd::_stand_up()` makes, in the same
		# place: before `add_child()`, which is what runs `_ready()`.
		world.set("simulation_only", true)
		world.set("shell_realm", realm)
	var t_add := Time.get_ticks_msec()
	root.add_child(world)
	var add_child_ms := Time.get_ticks_msec() - t_add
	var build := await _watch_build(SETTLE_FRAMES, world)
	var boot_ms := Time.get_ticks_msec() - t0
	_print_phases("%s/%s" % [realm, mode], load_ms, instantiate_ms, add_child_ms, build)

	var static_first := OS.get_static_memory_usage()
	var vmhwm_first := _status_kb("VmHWM:")
	var shell_ms := 0
	if mode == "host_pair":
		if shell_realm.is_empty():
			shell_realm = "cloudreach" if realm == "meadows" else "meadows"
		print("--- realm %s standing; adding a %s SHELL beside it ---" % [realm, shell_realm])
		var t1 := Time.get_ticks_msec()
		var shell_scene := str(SCENES.get(shell_realm, ""))
		var shell_packed: PackedScene = load(shell_scene) as PackedScene
		var pair_load_ms := Time.get_ticks_msec() - t1
		var t1b := Time.get_ticks_msec()
		var shell_node: Node = shell_packed.instantiate()
		var pair_inst_ms := Time.get_ticks_msec() - t1b
		shell_node.set("simulation_only", true)
		shell_node.set("shell_realm", shell_realm)
		var t1c := Time.get_ticks_msec()
		root.add_child(shell_node)
		var pair_add_ms := Time.get_ticks_msec() - t1c
		var pair_build := await _watch_build(SETTLE_FRAMES, shell_node)
		shell_ms = Time.get_ticks_msec() - t1
		_print_phases("%s-shell beside %s" % [shell_realm, realm],
			pair_load_ms, pair_inst_ms, pair_add_ms, pair_build)
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


## Walk physics frames while the build runs, keeping every frame's wall time.
## Returns the worst single frame and the worst 60-frame window, which is the
## heartbeat criterion.
##
## At least `n` frames, and then as many more as the world needs to finish: a
## sliced shell build (`scripts/world/shell_build_budget.gd`) deliberately
## outlives any fixed frame count, and stopping the clock at 240 frames would
## report a boot that had not happened and a memory figure for half a world.
func _watch_build(n: int, world: Node) -> Dictionary:
	var frames: Array[float] = []
	var cap := 20000
	var watched := 0
	while watched < n or not _built(world):
		if watched >= cap:
			print("WARNING: world never reported shell_build_complete within %d frames" % cap)
			break
		var t := Time.get_ticks_usec()
		await physics_frame
		frames.append((Time.get_ticks_usec() - t) / 1000.0)
		watched += 1
	print("build watched for %d physics frames" % frames.size())
	var worst_frame := 0.0
	for f: float in frames:
		worst_frame = maxf(worst_frame, f)
	# Rolling sum over HEARTBEAT_FRAMES consecutive frames.
	var worst_window := 0.0
	var window := 0.0
	for i in frames.size():
		window += frames[i]
		if i >= HEARTBEAT_FRAMES:
			window -= frames[i - HEARTBEAT_FRAMES]
		if i >= HEARTBEAT_FRAMES - 1:
			worst_window = maxf(worst_window, window)
	return {"worst_frame_ms": worst_frame, "worst_60_frame_window_s": worst_window / 1000.0}


## A world with no such method is a pre-lane build; treat it as finished.
func _built(world: Node) -> bool:
	if world == null or not is_instance_valid(world):
		return true
	if not world.has_method("shell_build_complete"):
		return true
	return bool(world.call("shell_build_complete"))


func _print_phases(label: String, load_ms: int, instantiate_ms: int, add_child_ms: int,
		build: Dictionary) -> void:
	print("--- phases: %s ---" % label)
	print("load_ms=%d  instantiate_ms=%d  add_child_ms=%d" % [load_ms, instantiate_ms, add_child_ms])
	print("worst single frame during build: %.0f ms" % float(build.get("worst_frame_ms", 0.0)))
	print("worst 60-physics-frame window during build: %.1f s  (heartbeat dies above 15.0 s)"
		% float(build.get("worst_60_frame_window_s", 0.0)))
	print("6A-SHELL-PHASES %s load_ms=%d instantiate_ms=%d add_child_ms=%d worst_frame_ms=%.0f worst_hb_window_s=%.1f"
		% [label.replace(" ", "_"), load_ms, instantiate_ms, add_child_ms,
			float(build.get("worst_frame_ms", 0.0)), float(build.get("worst_60_frame_window_s", 0.0))])


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
