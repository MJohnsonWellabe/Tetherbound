extends SceneTree

## Throwaway N02 probe: how much of the world the soft-occluder list actually
## covers, per layer, straight off the committed bake -- no Terrain3D, no boot.
const BAKE := preload("res://scripts/world/scatter_bake.gd")
const VEG := preload("res://scripts/world/vegetation.gd")

func _init() -> void:
	var drained: Dictionary = {}
	var skipped: Dictionary = {}
	var by_layer: Dictionary = BAKE.load_all("playground", drained, {}, skipped)
	var veg := VEG.new()
	var total := 0
	for layer_name: String in by_layer.keys():
		var placements: Array = by_layer[layer_name]
		total += placements.size()
		var soft := VEG.SOFT_OCCLUDER_LAYERS.has(layer_name)
		var reach_min := 1e9
		var reach_max := 0.0
		if soft:
			for entry: Variant in placements:
				var p: Dictionary = entry
				var span: float = veg.call("_model_footprint_radius", str(p["model"]))
				var r: float = maxf(span * float(p["scale"]), VEG.SOFT_OCCLUDER_FLOOR_RADIUS)
				reach_min = minf(reach_min, r)
				reach_max = maxf(reach_max, r)
		print("%-14s %8d  soft=%s%s" % [layer_name, placements.size(), soft,
			("  reach %.2f-%.2f m" % [reach_min, reach_max]) if soft else ""])
	print("total %d" % total)
	veg.free()
	quit(0)
