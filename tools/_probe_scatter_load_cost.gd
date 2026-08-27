extends SceneTree

## GF-B-001 / STALL-2. What the scatter's disk bake costs to LOAD, measured the
## only way this container permits: several loads in one process, every
## repetition printed.
##
##   godot --headless --path . --script tools/_probe_scatter_load_cost.gd
##
## WHY THIS EXISTS. `HIST-085` has pointed at the vegetation scatter for a long
## time, and the water lane handed over a negative result that narrows it a
## long way: the scatter did NOT respond to `height_at` getting 5x faster, so
## whatever it spends is not terrain queries. `vegetation.gd`'s own boot-phase
## print then says where it goes -- `placements=12,792 ms` of a ~16.4 s build --
## and `scatter_bake.is_fresh()` says that phase is a FILE READ, not
## `all_placements()` recomputing anything.
##
## So this times the read on its own, with no scene, no Terrain3D and no
## instancer: `is_fresh`, then `load_all`, repeated. It also counts what came
## back per layer and how much of it `grass_field.gd` throws away immediately
## afterwards, because that is the other half of the question -- a load is not
## only slow, it may be loading things nothing will ever build.

const BAKE := preload("res://scripts/world/scatter_bake.gd")
const GRASS_FIELD := preload("res://scripts/world/grass_field.gd")
const RULES := preload("res://scripts/world/scatter_rules.gd")
const WORLD := "playground"
const REPS := 3


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var cfg: Dictionary = RULES.config()
	var base_seed := int(cfg.get("seed", 1))

	var t0 := Time.get_ticks_usec()
	var fresh: bool = BAKE.is_fresh(WORLD, base_seed)
	print("is_fresh(%s, seed %d) = %s   [%.0f ms]" % [
		WORLD, base_seed, fresh, float(Time.get_ticks_usec() - t0) / 1000.0])
	if not fresh:
		print("the bake is STALE -- `vegetation.gd` would recompute, and this probe is")
		print("measuring the wrong thing. Re-bake before drawing any conclusion.")
		quit(1)
		return

	var suppressed: Dictionary = GRASS_FIELD.suppressed_layers()
	var by_layer: Dictionary = {}
	var drained: Dictionary = {}
	for r in REPS:
		by_layer = {}
		drained = {}
		var started := Time.get_ticks_usec()
		by_layer = BAKE.load_all(WORLD, drained)
		print("load_all rep %d: %8.0f ms" % [r + 1, float(Time.get_ticks_usec() - started) / 1000.0])

	print("\n%-14s %10s %10s   %s" % ["layer", "kept", "drained", "built?"])
	var total := 0
	var wasted := 0
	for layer_name: String in by_layer.keys():
		var kept: int = (by_layer[layer_name] as Array).size()
		var gone: int = (drained[layer_name] as Array).size() if drained.has(layer_name) else 0
		var built := not suppressed.has(layer_name)
		total += kept + gone
		if not built:
			wasted += kept + gone
		print("%-14s %10d %10d   %s" % [layer_name, kept, gone, "yes" if built else "NO -- grass field owns this ground"])
	print("\n%d placements read; %d of them (%.1f%%) are dropped by grass_field.gd" % [
		total, wasted, 100.0 * float(wasted) / maxf(1.0, float(total))])
	print("suppressed layers: %s" % ", ".join(suppressed.keys()))

	print("\nCHECKSUM %d   -- must not change across a performance-only edit" % _fingerprint(by_layer, drained))

	quit(0)


## Every placement the load produced, in the order it produced them, as one
## number. This is what makes an optimisation of `scatter_bake.gd` checkable
## rather than merely plausible.
##
## ORDER IS BEHAVIOUR here, not presentation. `vegetation.gd::_mark_harvestable`
## walks each layer's array by index and makes a deterministic slice of it into
## real gather points, so an array that holds the same placements in a different
## order puts the axe on different trees. The layer name and the index are
## therefore hashed alongside the placement's own fields, not just the set of
## fields.
func _fingerprint(by_layer: Dictionary, drained: Dictionary) -> int:
	var parts := PackedFloat64Array()
	for source: Dictionary in [by_layer, drained]:
		var names := source.keys()
		names.sort()
		for layer_name: String in names:
			parts.append(float(hash(layer_name)))
			var list: Array = source[layer_name]
			parts.append(float(list.size()))
			for i in list.size():
				var placement: Dictionary = list[i]
				var spot: Vector3 = placement["position"]
				parts.append(float(i))
				parts.append(float(hash(str(placement["model"]))))
				parts.append(spot.x)
				parts.append(spot.y)
				parts.append(spot.z)
				parts.append(float(placement["yaw"]))
				parts.append(float(placement["scale"]))
				if placement.has("normal"):
					var normal: Vector3 = placement["normal"]
					parts.append(normal.x)
					parts.append(normal.y)
					parts.append(normal.z)
				else:
					parts.append(-9999.0)
	return hash(parts.to_byte_array())
