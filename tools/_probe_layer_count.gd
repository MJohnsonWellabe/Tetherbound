extends SceneTree

## HOW MANY INSTANCES DOES ONE SCATTER LAYER ACTUALLY PLACE, and where.
##
##   godot --headless --path . --script tools/_probe_layer_count.gd -- --layer=drygrass
##
## The whole-bake line ("computed 750071 placements across 11 layers") is the
## only count this project prints, and it cannot answer the question a density
## retune actually needs: how much of that is the layer I am about to change,
## and how much headroom is left under `test_scatter_perf_budget.gd`'s ceiling
## before I spend a 4.5-minute bake plus a 12-minute render finding out.
##
## Written for T1-GROUND-3's second-grass-species pass, where the first attempt
## un-suppressed `drygrass` at its authored density and measured no visible
## change: the near field is the grass FIELD's 300,000-tuft carpet, and a
## scatter layer sprinkled at a few hundred instances per visible frame cannot
## read as a second species against it however well it is shaped. The number
## below is what turns that from a guess into a retune.
##
## Also reports the per-band split, because `layer.band_scale` makes a layer's
## instances deliberately unevenly distributed and a single total hides exactly
## the thing that key exists to create.

const RULES := preload("res://scripts/world/scatter_rules.gd")
const HEIGHTFIELD := preload("res://scripts/world/playground_heightfield.gd")


func _init() -> void:
	var want := "drygrass"
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--layer="):
			want = arg.substr("--layer=".length())

	var config: Dictionary = RULES.config()
	var layers: Dictionary = config.get("layers", {})
	if not layers.has(want):
		print("no layer named '%s'" % want)
		quit(1)
		return

	var terrain_cfg := HEIGHTFIELD.load_config()
	var field := HEIGHTFIELD.new(terrain_cfg)
	var world_size := float(terrain_cfg.get("world_size", 512))
	print("world_size %.0f, base seed %d" % [world_size, _base_seed()])

	# The same seed this layer gets in a real bake -- `all_placements` walks
	# `layers.keys()` in order and offsets the base seed by the index, so a
	# layer probed with the wrong seed reports a plausible count for a
	# distribution the bake will never produce.
	var offset := 0
	var seed_value := 0
	for name: String in layers.keys():
		if name.begins_with("_"):
			continue
		if name == want:
			seed_value = _base_seed() + offset * 7919 + int((layers[name] as Dictionary).get("seed_offset", 0))
			break
		offset += 1

	var start := Time.get_ticks_msec()
	var drained: Array[Dictionary] = []
	var placed := RULES.placements_for(layers[want], field, world_size, seed_value, drained)
	var elapsed := Time.get_ticks_msec() - start

	print("layer '%s': %d placements (%d drained) in %.1fs" % [
		want, placed.size(), drained.size(), elapsed / 1000.0])

	var bands: Array = config.get("corridor_bands", [])
	var per_band := {}
	for entry: Variant in placed:
		var spot: Dictionary = entry
		var pos: Vector3 = spot["position"]
		var id := "outside every band"
		for band_entry: Variant in bands:
			var band: Dictionary = band_entry
			if pos.z >= float(band.get("z_min", -INF)) and pos.z < float(band.get("z_max", INF)):
				id = str(band.get("id", "?"))
				break
		per_band[id] = int(per_band.get(id, 0)) + 1

	print("  per band, and per 100m of band length -- the second number is the")
	print("  one that decides whether a walk through it reads as a change:")
	for band_entry: Variant in bands:
		var band: Dictionary = band_entry
		var id := str(band.get("id", "?"))
		var length: float = float(band.get("z_max", 0.0)) - float(band.get("z_min", 0.0))
		var count: int = int(per_band.get(id, 0))
		print("    %-32s %7d   %6.1f per 100m" % [id, count, 100.0 * count / maxf(length, 1.0)])
	if per_band.has("outside every band"):
		print("    %-32s %7d" % ["outside every band", per_band["outside every band"]])
	quit(0)


## `bake_playground_scatter.gd`'s own base seed, read from the same place it
## reads it -- vegetation.json's top-level `seed`, NOT the terrain config's.
func _base_seed() -> int:
	return int(RULES.config().get("seed", 1))
