extends SceneTree

## Spike S2, question 4: simulation-only shell.
##
## Reference only — throwaway instrument for
## docs/specs/STAGE_B_MULTIPLAYER_EXECUTION_PLAN.md Wave 0 lane 0.D, D-MP3's
## "realm shell" (heightfield, encounter director, world records, spawn
## containers; no grass, water rendering, VFX, HUD or audio).
##
## Boots the real Meadows scene, settles it exactly like tests/smoke_playground
## does, measures baseline RSS + physics-frame time, THEN — from the probe,
## never from a code change — frees or disables every rendering-heavy node it
## can find by name, settles again, and measures the delta.
##
## Whether a given node could be disabled "without errors" is read from THIS
## PROCESS'S OWN LOG after the fact (grep the run's stdout/stderr for `ERROR:`
## between the two `=== TEARDOWN ===` markers this script prints) — GDScript
## has no try/catch, so that is the only honest way to answer the question.
##
##   godot --headless --path . --script tools/net/_probe_s2_shell.gd 2>&1 | tee run.log

const SCENE := "res://scenes/world/meadows_playground.tscn"
const SETTLE_FRAMES := 240
const SAMPLE_FRAMES := 300

## Node names this probe tries to remove. GrassField/Water are built at
## runtime by playground_world.gd (`_stand_up_the_grass_field()` /
## `_build_water()`), not saved in the .tscn, so they only exist to find AFTER
## `_ready()` has run — which is why this cannot be a boot-time flag today and
## has to be a post-hoc probe.
const TEARDOWN_TARGETS := [
	"GrassField", "Water", "WorldWeather", "WorldAudio",
	"PlaygroundHUD", "CombatHUD", "DialoguePanel", "NamePrompt", "StarterPicker",
]


func _init() -> void:
	await _run()


func _run() -> void:
	print("=== S2 simulation-only shell probe: %s ===" % Time.get_datetime_string_from_system())

	var world: Node = (load(SCENE) as PackedScene).instantiate()
	root.add_child(world)

	for i in SETTLE_FRAMES:
		await physics_frame

	var static_before := OS.get_static_memory_usage()
	var vmhwm_before := _read_vm_hwm_kb()
	var samples_before := await _sample_frames(SAMPLE_FRAMES)
	print("--- BEFORE teardown ---")
	print("static_mem: %.1f MB   VmHWM: %.1f MB" % [static_before / 1048576.0, vmhwm_before / 1024.0])
	print("median frame: %.3f ms   p95: %.3f ms" % [_median(samples_before), _p95(samples_before)])
	print("")

	print("=== TEARDOWN begin ===")
	var found: Array[String] = []
	var missing: Array[String] = []
	for name: String in TEARDOWN_TARGETS:
		var node: Node = world.get_node_or_null(NodePath(name))
		if node == null:
			missing.append(name)
			continue
		found.append(name)
		print("[teardown] freeing %s" % name)
		node.set_process(false)
		node.set_physics_process(false)
		if node is CanvasItem:
			(node as CanvasItem).hide()
		elif node is Node3D:
			(node as Node3D).hide()
		node.queue_free()

	# Let every queue_free() actually take before measuring again.
	for i in 10:
		await process_frame
	print("=== TEARDOWN end ===")
	print("found and torn down: %s" % ", ".join(found))
	print("not present in this scene: %s" % ", ".join(missing))
	print("")

	for i in SETTLE_FRAMES:
		await physics_frame

	var static_after := OS.get_static_memory_usage()
	var vmhwm_after := _read_vm_hwm_kb()
	var samples_after := await _sample_frames(SAMPLE_FRAMES)
	print("--- AFTER teardown ---")
	print("static_mem: %.1f MB   VmHWM: %.1f MB" % [static_after / 1048576.0, vmhwm_after / 1024.0])
	print("median frame: %.3f ms   p95: %.3f ms" % [_median(samples_after), _p95(samples_after)])
	print("")

	print("=== summary ===")
	print("static_mem delta: %+.1f MB" % ((static_after - static_before) / 1048576.0))
	print("VmHWM delta (high-water mark, never decreases): %.1f MB before, %.1f MB after" % [
		vmhwm_before / 1024.0, vmhwm_after / 1024.0
	])
	print("median frame delta: %+.3f ms" % (_median(samples_after) - _median(samples_before)))

	# Read the OS actively for RSS too (VmRSS), since VmHWM cannot go down —
	# freeing nodes should show up here even if the peak stays what it was.
	var rss_after := _read_vm_rss_kb()
	if rss_after >= 0:
		print("current VmRSS after teardown: %.1f MB" % (rss_after / 1024.0))

	quit(0)


func _sample_frames(n: int) -> Array[float]:
	var samples: Array[float] = []
	for i in n:
		var t0 := Time.get_ticks_usec()
		await physics_frame
		var t1 := Time.get_ticks_usec()
		samples.append((t1 - t0) / 1000.0)
	return samples


func _median(samples: Array[float]) -> float:
	var s := samples.duplicate()
	s.sort()
	return s[s.size() / 2]


func _p95(samples: Array[float]) -> float:
	var s := samples.duplicate()
	s.sort()
	return s[mini(s.size() - 1, int(float(s.size()) * 0.95))]


func _read_vm_hwm_kb() -> int:
	return _read_status_field("VmHWM:")


func _read_vm_rss_kb() -> int:
	return _read_status_field("VmRSS:")


func _read_status_field(field: String) -> int:
	var f := FileAccess.open("/proc/self/status", FileAccess.READ)
	if f == null:
		return -1
	while not f.eof_reached():
		var line := f.get_line()
		if line.begins_with(field):
			var digits := line.replace(field, "").replace("kB", "").strip_edges()
			return int(digits)
	return -1
