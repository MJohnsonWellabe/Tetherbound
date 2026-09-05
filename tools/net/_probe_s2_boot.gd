extends SceneTree

## Spike S2, question 1: concurrent world boots.
##
## Reference only — throwaway instrument for
## docs/specs/STAGE_B_MULTIPLAYER_EXECUTION_PLAN.md Wave 0 lane 0.D. Boots
## exactly one world scene (Meadows or Cloudreach), settles it the same way
## tests/smoke_playground.gd does (240 physics frames), then prints wall-clock
## to "player on ground" plus static and peak-RSS memory, then quits.
##
## Concurrency is NOT modeled inside this script — the spike runs 1, then 2,
## then 4 of these as separate OS processes (each its own XDG_DATA_HOME, per
## tools/flake_rate.sh's pattern), driven from the report's shell harness, so
## the numbers reflect what N real host processes on one box actually cost.
##
##   godot --headless --path . --script tools/net/_probe_s2_boot.gd -- \
##       --scene=res://scenes/world/cloudreach_cliffs.tscn --tag=run1

const DEFAULT_SCENE := "res://scenes/world/meadows_playground.tscn"
const SETTLE_FRAMES := 240


func _init() -> void:
	await _run()


func _run() -> void:
	var args := _parse_args()
	var scene_path: String = args.get("scene", DEFAULT_SCENE)
	var tag: String = args.get("tag", "run")

	var t_wall_start := Time.get_ticks_msec()

	# Cloudreach's own world script (`cloudreach_world.gd::_place_player()`)
	# spawns at a realm-entry anchor read from `Game.pending_entry_for()`; with
	# no such entry pending it falls back to `meadows_entry`, whose position
	# is not guaranteed to sit over Cloudreach's analytic ground, so a bare
	# instantiate can drop the player into an infinite fall that has nothing
	# to do with this probe's own boot cost. `tests/smoke_cloudreach_arrival_
	# walk.gd` establishes the same realm-entry state before instantiating the
	# scene; mirrored here so the settle check means the same thing it does
	# for Meadows: "did the player actually land".
	if scene_path.contains("cloudreach"):
		var game := root.get_node_or_null(^"Game")
		if game != null:
			if game.has_method("reset_for_new_game"):
				game.call("reset_for_new_game")
			game.set("current_realm", "cloudreach")
			var flags: RefCounted = game.get("progression")
			if flags != null:
				flags.call("set_flag", "realm_key_cloudreach")

	var packed: PackedScene = load(scene_path)
	if packed == null:
		print("[%s] FAIL: could not load %s" % [tag, scene_path])
		quit(1)
		return

	var world: Node = packed.instantiate()
	root.add_child(world)

	for i in SETTLE_FRAMES:
		await physics_frame

	var t_settled := Time.get_ticks_msec()

	var player: CharacterBody3D = world.get_node_or_null(^"Player") as CharacterBody3D
	var on_floor := false
	var pos := Vector3.ZERO
	if player != null:
		on_floor = player.is_on_floor()
		pos = player.global_position

	var static_mem := OS.get_static_memory_usage()
	var perf_static := Performance.get_monitor(Performance.MEMORY_STATIC)
	var vm_hwm_kb := _read_vm_hwm_kb()

	# DIAGNOSTIC (S2, not part of the normal probe report): does this world's
	# own _ready() actually run to completion? A typed-variable assignment
	## error (e.g. cloudreach_world.gd:138) can abort the rest of _ready(),
	# which would explain a fall-forever spawn that has nothing to do with
	# this probe's own realm-entry setup above.
	var child_names: Array[String] = []
	for c: Node in world.get_children():
		child_names.append(c.name)
	print("[%s] DIAG world children after settle: %s" % [tag, ", ".join(child_names)])

	print("=== S2 boot probe [%s] scene=%s ===" % [tag, scene_path])
	print("[%s] wall_ms_to_settle=%d" % [tag, t_settled - t_wall_start])
	print("[%s] player_on_floor=%s pos=(%.1f, %.1f, %.1f)" % [tag, on_floor, pos.x, pos.y, pos.z])
	print("[%s] OS.get_static_memory_usage=%d bytes (%.1f MB)" % [
		tag, static_mem, static_mem / 1048576.0
	])
	print("[%s] Performance.MEMORY_STATIC=%d bytes (%.1f MB)" % [
		tag, perf_static, perf_static / 1048576.0
	])
	if vm_hwm_kb >= 0:
		print("[%s] VmHWM=%d kB (%.1f MB)" % [tag, vm_hwm_kb, vm_hwm_kb / 1024.0])
	else:
		print("[%s] VmHWM=UNAVAILABLE (could not read /proc/self/status)" % tag)
	print("[%s] RESULT wall_ms=%d static_mb=%.1f vmhwm_mb=%.1f on_floor=%s" % [
		tag, t_settled - t_wall_start, static_mem / 1048576.0,
		(vm_hwm_kb / 1024.0) if vm_hwm_kb >= 0 else -1.0, on_floor
	])

	quit(0 if on_floor else 1)


func _parse_args() -> Dictionary:
	var out := {}
	for raw: String in OS.get_cmdline_user_args():
		var s := raw
		if s.begins_with("--"):
			s = s.substr(2)
		var eq := s.find("=")
		if eq >= 0:
			out[s.substr(0, eq)] = s.substr(eq + 1)
	return out


## Linux-only. VmHWM is the process's peak resident set size ("high water
## mark"), which is what actually determines whether N concurrent boots fit
## in the box's RAM — RSS at the settle point undercounts any transient
## spike during scene build (e.g. terrain bake data momentarily duplicated).
func _read_vm_hwm_kb() -> int:
	var f := FileAccess.open("/proc/self/status", FileAccess.READ)
	if f == null:
		return -1
	while not f.eof_reached():
		var line := f.get_line()
		if line.begins_with("VmHWM:"):
			var digits := line.replace("VmHWM:", "").replace("kB", "").strip_edges()
			return int(digits)
	return -1
