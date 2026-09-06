extends SceneTree

## Spike S2, question 3: heightfield-grounded creature cost.
##
## Reference only — throwaway instrument for
## docs/specs/STAGE_B_MULTIPLAYER_EXECUTION_PLAN.md Wave 0 lane 0.D, D-MP2's
## proposed kinematic heightfield mode for host-simulated creature bodies.
##
## One boot, two phases, same 40 wild bodies both times so the comparison is
## apples-to-apples:
##
##   (a) AS-IS — the 40 forced active via EncounterDirector's own
##       `_set_wild_active()` (production code, not a reimplementation), so
##       each one runs its real `_physics_process()`: gravity, friction,
##       `move_and_slide()` against Terrain3D collision, arena `hold_inside`.
##   (b) KINEMATIC HEIGHTFIELD — `set_physics_process(false)` on the same 40
##       (a probe-side call, not a code change to creature_body.gd), then a
##       probe-side per-frame loop sets each body's `position.y` from
##       `playground_world.ground_height_at(x, z)` — the same analytic
##       heightfield `creature_body.gd::place_on_ground()` already trusts
##       (`:1876`) — instead of running physics. The loop's own cost is
##       counted inside the timed window, since that IS the replacement cost.
##
##   godot --headless --path . --script tools/net/_probe_s2_heightfield.gd

const SCENE := "res://scenes/world/meadows_playground.tscn"
const SETTLE_FRAMES := 300
const SAMPLE_FRAMES := 600
const TARGET_COUNT := 40


func _init() -> void:
	await _run()


func _run() -> void:
	print("=== S2 heightfield-mode probe: %s ===" % Time.get_datetime_string_from_system())

	var world: Node = (load(SCENE) as PackedScene).instantiate()
	root.add_child(world)

	for i in SETTLE_FRAMES:
		await physics_frame

	var director: Node = world.get_node_or_null(^"EncounterDirector")
	if director == null:
		push_error("no EncounterDirector on the scene; probe cannot measure anything")
		quit(1)
		return

	var all_wild: Array = director.call("wild_creatures")
	print("total wild in the meadows: %d" % all_wild.size())

	var chosen: Array[Node3D] = []
	for w: Node3D in all_wild:
		if chosen.size() >= TARGET_COUNT:
			break
		if not is_instance_valid(w):
			continue
		director.call("_set_wild_active", w, true)
		if w.is_physics_processing():
			chosen.append(w)

	print("forced active for this probe: %d (target %d)" % [chosen.size(), TARGET_COUNT])
	for i in 10:
		await physics_frame

	# --- phase (a): as-is, full move_and_slide against Terrain3D collision ---
	var samples_a := await _sample_frames(SAMPLE_FRAMES)
	_report("(a) as-is: move_and_slide vs Terrain3D collision", chosen.size(), samples_a)

	# --- phase (b): kinematic heightfield mode -------------------------------
	for w: Node3D in chosen:
		w.set_physics_process(false)

	var samples_b: Array[float] = []
	for i in SAMPLE_FRAMES:
		var t0 := Time.get_ticks_usec()
		for w: Node3D in chosen:
			if not is_instance_valid(w):
				continue
			var p := w.global_position
			var ground: float = float(world.call("ground_height_at", p.x, p.z))
			if not is_nan(ground):
				w.global_position = Vector3(p.x, ground, p.z)
		await physics_frame
		var t1 := Time.get_ticks_usec()
		samples_b.append((t1 - t0) / 1000.0)

	_report("(b) kinematic heightfield: position.y from ground_height_at()", chosen.size(), samples_b)

	print("")
	print("=== summary ===")
	var med_a := _median(samples_a)
	var med_b := _median(samples_b)
	print("(a) as-is median:        %.3f ms" % med_a)
	print("(b) heightfield median:  %.3f ms" % med_b)
	print("delta (b - a):           %+.3f ms over %d bodies" % [med_b - med_a, chosen.size()])

	quit(0)


func _sample_frames(n: int) -> Array[float]:
	var samples: Array[float] = []
	for i in n:
		var t0 := Time.get_ticks_usec()
		await physics_frame
		var t1 := Time.get_ticks_usec()
		samples.append((t1 - t0) / 1000.0)
	return samples


func _report(label: String, count: int, samples: Array[float]) -> void:
	var sorted := samples.duplicate()
	sorted.sort()
	var median_ms: float = sorted[sorted.size() / 2]
	var p95_index: int = mini(sorted.size() - 1, int(float(sorted.size()) * 0.95))
	var p95_ms: float = sorted[p95_index]
	print("--- %s ---" % label)
	print("  bodies:       %d" % count)
	print("  median frame: %.3f ms" % median_ms)
	print("  p95 frame:    %.3f ms" % p95_ms)
	print("")


func _median(samples: Array[float]) -> float:
	var sorted := samples.duplicate()
	sorted.sort()
	return sorted[sorted.size() / 2]
