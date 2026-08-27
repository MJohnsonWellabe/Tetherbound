extends SceneTree

## GF-B-001 / STALL-WATER. What one `height_at()` costs, and whether a change
## to it moved the answer.
##
##   godot --headless --path . --script tools/_probe_heightfield_cost.gd
##
## WHY THIS EXISTS RATHER THAN JUST RUNNING THE BOOT PROBE. The New Game stall
## is dominated by `height_at()` call volume: two 512x512 water bakes are
## 524,288 of them on their own. `tools/_probe_new_game_stall.gd` measures the
## whole stand-up and takes minutes; this measures the one function and takes
## seconds, so an optimisation can be iterated on rather than guessed at.
##
## TWO NUMBERS, AND THE SECOND IS THE IMPORTANT ONE.
##
## 1. Microseconds per call. This container CANNOT time reliably -- the Gate F
##    defects lane measured the same untouched vegetation scatter at 10,120 /
##    14,258 / 16,834 ms in three runs minutes apart. So this runs the same
##    grid REPS times and reports every repetition, not just a mean: a change
##    is only believable if the slowest patched run beats the fastest unpatched
##    one, or if the ratio between two grids measured in the SAME process moved.
##
## 2. A checksum of every height sampled. `height_at()` is the ground itself --
##    the scatter gates placements on thresholds read off it, the bake paints
##    from it, the water composer finds its waterline with it. Any optimisation
##    here has to be BIT-IDENTICAL, and this is what proves it. Print it before
##    the change, print it after, and if the two differ the change is a terrain
##    edit wearing a performance change's clothes.

const HEIGHTFIELD := preload("res://scripts/world/playground_heightfield.gd")
const REPS := 3
const BAKE_SIZE := 512


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var config: Dictionary = HEIGHTFIELD.load_config()
	var field: RefCounted = HEIGHTFIELD.new(config)

	# One call before anything is timed. Every shaping pass guards its own
	# `_..._ready` flag and `height_at()` calls all of them unconditionally, so
	# this single call builds every lazy cache in the object -- otherwise the
	# first grid pays for all of them and reads as slower than the second.
	field.call("height_at", 0.0, 0.0)

	var grids := _grids(config)
	for name: String in grids:
		var rect: Rect2 = grids[name]
		print("\n=== %s ===" % name)
		print("rect  %.1f,%.1f  %.1f x %.1f m   (%d x %d samples)" % [
			rect.position.x, rect.position.y, rect.size.x, rect.size.y, BAKE_SIZE, BAKE_SIZE])
		var checksum := 0
		var best := INF
		for r in REPS:
			var started := Time.get_ticks_usec()
			var values := _sample(field, rect)
			var elapsed := Time.get_ticks_usec() - started
			var per_call := float(elapsed) / float(BAKE_SIZE * BAKE_SIZE)
			best = minf(best, float(elapsed))
			print("   rep %d: %8.1f ms   %6.2f us/call" % [r + 1, float(elapsed) / 1000.0, per_call])
			var this_sum: int = hash(values.to_byte_array())
			if r == 0:
				checksum = this_sum
			elif this_sum != checksum:
				print("   !! rep %d disagrees with rep 1 -- height_at is NOT deterministic" % (r + 1))
		print("   best %.1f ms  (%.2f us/call)" % [best / 1000.0, best / float(BAKE_SIZE * BAKE_SIZE)])
		print("   CHECKSUM %d   -- must not change across a performance-only edit" % checksum)

	quit(0)


## The two rects the water composer actually bakes over, plus one control.
##
## The pond rect is `water.gd::_region()`'s own derivation and the river rect
## is `_river_region()`'s, reproduced here rather than imported because both
## are private to a Node that needs a scene tree. They are reproduced closely
## enough to cost the same, which is all this probe asks of them -- it reports
## timings, not geometry, and `smoke_pond_water` owns the geometry.
func _grids(config: Dictionary) -> Dictionary:
	var water: Dictionary = config.get("water", {})
	var centre: Array = water.get("pond_centre", [0.0, 0.0])
	var c := Vector2(float(centre[0]), float(centre[1]))
	var pond := Rect2(c - Vector2(96, 96), Vector2(192, 192))

	var lo := Vector2(INF, INF)
	var hi := Vector2(-INF, -INF)
	for entry: Variant in config.get("river", {}).get("course", []):
		var at: Array = (entry as Dictionary).get("at", [])
		if at.size() < 2:
			continue
		var pad := float((entry as Dictionary).get("half_width", 9.0)) + float((entry as Dictionary).get("rim", 5.0)) + 4.0
		var p := Vector2(float(at[0]), float(at[1]))
		lo = Vector2(minf(lo.x, p.x - pad), minf(lo.y, p.y - pad))
		hi = Vector2(maxf(hi.x, p.x + pad), maxf(hi.y, p.y + pad))
	var river := Rect2(lo, hi - lo) if lo.x <= hi.x else pond

	return {
		"pond bake region": pond,
		"river bake region": river,
		# Open meadow well away from both, as a control: a phase that is cheap
		# here and dear over the river says the river's own segment walk is
		# what a change moved, not the noise underneath everything.
		"open meadow (control)": Rect2(c + Vector2(260, 260), Vector2(192, 192)),
	}


func _sample(field: RefCounted, rect: Rect2) -> PackedFloat64Array:
	var out := PackedFloat64Array()
	out.resize(BAKE_SIZE * BAKE_SIZE)
	var i := 0
	for py in BAKE_SIZE:
		var wz := rect.position.y + (float(py) + 0.5) / BAKE_SIZE * rect.size.y
		for px in BAKE_SIZE:
			var wx := rect.position.x + (float(px) + 0.5) / BAKE_SIZE * rect.size.x
			out[i] = field.call("height_at", wx, wz)
			i += 1
	return out
