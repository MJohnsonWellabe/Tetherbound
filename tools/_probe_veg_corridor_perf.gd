extends SceneTree

## VEG-CORRIDOR. Measures the corridor fill's real cost: instance count and
## wall-clock for `scatter_rules.all_placements()` -- the exact call
## `vegetation.gd::build()` makes at boot -- with and without `corridor_fill`,
## on the actual shipped config and heightfield. No scene, no Terrain3D, no
## rendering, so this is safe under `--headless` and does not need the
## import cache's render assets, just the two scripts.
##
##   godot --headless --path . --script tools/_probe_veg_corridor_perf.gd
##
## "Before" is not read from git history: `corridor_fill` is strictly
## additive and opt-in per layer (scatter_rules.gd::_place_corridor_fill's own
## header), so stripping that one key from every layer's config in memory
## reproduces the pre-VEG-CORRIDOR code path exactly, including its own
## already-identical placements -- which this also uses as the regression
## check the backlog item asked for ("keep the existing square's placements
## identical"). Per-layer counts use the SAME per-layer seed offset
## `all_placements` itself applies, so the numbers here match a real boot's
## `[playground] scattered %d props` line, not an approximation of it.

const RULES := preload("res://scripts/world/scatter_rules.gd")
const HEIGHTFIELD := preload("res://scripts/world/playground_heightfield.gd")


func _config_without_corridor_fill() -> Dictionary:
	var stripped: Dictionary = RULES.config().duplicate(true)
	var layers: Dictionary = stripped.get("layers", {})
	for name: String in layers.keys():
		if name.begins_with("_"):
			continue
		(layers[name] as Dictionary).erase("corridor_fill")
	return stripped


func _run() -> void:
	var field: RefCounted = HEIGHTFIELD.new()
	var world_size := float(HEIGHTFIELD.load_config().get("world_size", 512))
	var base_seed := int(RULES.config().get("seed", 1))
	var half := world_size * 0.5

	var t0 := Time.get_ticks_msec()
	var after: Dictionary = RULES.all_placements(field, world_size, base_seed)
	var t1 := Time.get_ticks_msec()

	# Swap the live config for one with corridor_fill stripped from every
	# layer, call the exact same entry point, then restore it -- `config()`
	# caches `_config` in a static var, so this is the only way to get the
	# "before" code path through the real function rather than a re-
	# implementation of it.
	var real_config: Dictionary = RULES.config()
	RULES._config = _config_without_corridor_fill()
	var t2 := Time.get_ticks_msec()
	var before: Dictionary = RULES.all_placements(field, world_size, base_seed)
	var t3 := Time.get_ticks_msec()
	RULES._config = real_config

	var total_before := 0
	var total_after := 0
	var outside_before := 0
	var outside_after := 0
	var identical_prefix := true

	print("layer            before   after     new")
	for name: String in before.keys():
		var b: Array = before[name]
		var a: Array = after[name]
		for i in b.size():
			if i >= a.size() or not (a[i]["position"] as Vector3).is_equal_approx(b[i]["position"] as Vector3):
				identical_prefix = false
				print("  MISMATCH in '%s' at index %d -- corridor_fill is not append-only" % [name, i])
				break
		for p: Variant in b:
			var spot: Vector3 = (p as Dictionary)["position"]
			if absf(spot.x) > half or absf(spot.z) > half:
				outside_before += 1
		for p: Variant in a:
			var spot: Vector3 = (p as Dictionary)["position"]
			if absf(spot.x) > half or absf(spot.z) > half:
				outside_after += 1
		print("%-16s %6d  %6d   %5d" % [name, b.size(), a.size(), a.size() - b.size()])
		total_before += b.size()
		total_after += a.size()

	print("")
	print("TOTAL            %6d  %6d   %5d  (%.2fx)" % [
		total_before, total_after, total_after - total_before, float(total_after) / float(total_before)
	])
	print("outside the old +-%.0fm square: before %d, after %d" % [half, outside_before, outside_after])
	print("all_placements() wall time: before %dms, after %dms (delta %dms)" % [t3 - t2, t1 - t0, (t1 - t0) - (t3 - t2)])
	print("old-square placements identical (append-only holds): %s" % identical_prefix)
	quit(0)


func _init() -> void:
	_run()
