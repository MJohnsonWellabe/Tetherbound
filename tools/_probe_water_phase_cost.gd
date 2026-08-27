extends SceneTree

## GF-B-001 / STALL-2. What each phase of the water composer costs, measured
## the only way this container permits: several complete builds in ONE process,
## every repetition printed.
##
##   godot --headless --path . --script tools/_probe_water_phase_cost.gd
##
## WHY NOT `_probe_new_game_stall.gd`. That probe presses New Game and reports
## the whole stand-up, which is the right shape for ranking phases and the
## wrong shape for judging a change: three runs of the same build measured the
## untouched vegetation scatter at 10,120 / 14,258 / 16,834 ms on this box. A
## before/after pair of whole-boot numbers proves nothing here.
##
## This builds only `water.gd`, three times, and prints every phase of every
## repetition. Two things make it usable where the boot probe is not:
##
## 1. The repetitions are in the same process minutes apart from nothing else,
##    so their spread is the instrument's own noise and is printed rather than
##    averaged away.
## 2. It prints RATIOS against phases the change did not touch. The pond's
##    step-4 height RANGE scan walks exactly the rect the pond's 512x512 BAKE
##    walks, with the same `height_at`, and no optimisation of the bake can
##    reach it -- so `BAKE / RANGE` is a figure that cannot be moved by the box
##    being busy. That ratio, not the millisecond column, is the evidence.

const WATER := preload("res://scripts/world/water.gd")
const BOOT_LOG := preload("res://scripts/boot/boot_log.gd")
const REPS := 3

## `[numerator, denominator]` phase names. The denominator is always something
## this lane did not touch, walking comparable work.
const RATIOS := [
	["water: pond height BAKE (512x512)", "water: pond height RANGE scan (step 4)"],
	["water: river height BAKE (512x512)", "water: river height RANGE scan (step 4)"],
	["water: river waterline search (520 stations)", "water: pond height RANGE scan (step 4)"],
]


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var per_phase: Dictionary = {}
	var order: Array[String] = []
	var totals: Array[float] = []

	# `BOOT_LOG.phase()` reports -1 for the first mark of a process -- it has
	# no previous tick to subtract. Spending that -1 here means every phase of
	# every repetition below carries a real figure, instead of repetition 1's
	# first phase silently dropping out and shifting that row's columns.
	BOOT_LOG.phase("probe: consume the first-phase sentinel")

	for r in REPS:
		var before: int = BOOT_LOG.boot_phase_ms().size()
		var water: Node = WATER.new()
		root.add_child(water)
		var started := Time.get_ticks_usec()
		water.build()
		var elapsed := float(Time.get_ticks_usec() - started) / 1000.0
		totals.append(elapsed)
		var phases: Array = BOOT_LOG.boot_phase_ms()
		for i in range(before, phases.size()):
			var name: String = phases[i][0]
			var ms: int = phases[i][1]
			if ms < 0:
				continue
			if not per_phase.has(name):
				per_phase[name] = []
				order.append(name)
			per_phase[name].append(float(ms))
		root.remove_child(water)
		water.queue_free()

	print("\n=== water composer, %d complete builds in one process ===" % REPS)
	print("%-46s %9s %9s %9s   %s" % ["phase", "rep 1", "rep 2", "rep 3", "spread"])
	for name: String in order:
		var runs: Array = per_phase[name]
		var lo := INF
		var hi := -INF
		for v: float in runs:
			lo = minf(lo, v)
			hi = maxf(hi, v)
		var cells := ""
		for i in REPS:
			cells += "%9.0f" % (runs[i] if i < runs.size() else NAN)
		print("%-46s %s   %+.1f%%" % [name, cells, 100.0 * (hi - lo) / maxf(lo, 0.001)])

	var summed := 0.0
	for name: String in order:
		summed += _median(per_phase[name])
	print("\nmedian of every marked phase, summed: %.0f ms" % summed)
	print("whole build(): %.0f / %.0f / %.0f ms" % [totals[0], totals[1], totals[2]])

	print("\n=== ratios against phases this lane did not touch ===")
	print("(the millisecond column above moves with the box; these do not)")
	for pair: Array in RATIOS:
		if not per_phase.has(pair[0]) or not per_phase.has(pair[1]):
			print("   %-44s  -- phase absent" % pair[0])
			continue
		var num := _median(per_phase[pair[0]])
		var den := _median(per_phase[pair[1]])
		print("   %-44s / %-40s = %6.2f" % [pair[0], pair[1], num / maxf(den, 0.001)])

	quit(0)


func _median(values: Array) -> float:
	var sorted := values.duplicate()
	sorted.sort()
	return float(sorted[sorted.size() / 2])
