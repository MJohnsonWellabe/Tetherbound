extends SceneTree

## Scratch probe, BACKLOG-E1-VILLAGE-DAYTIME. Reads the baked scatter data
## directly (no world boot, no renderer) and lists every placement, across
## every layer, near the tournament-ground stand's eye/look line -- the
## unexplained orange spark/flare `ralph/reports/audit/E-2026-08-31.md` §E1
## found is close to the camera, so it is almost certainly a baked scatter
## instance (vegetation.gd), not a grass_field.gd procedural tuft (which is
## always green/olive per data/config/grass_field.json's own tint config).
##
##   godot --headless --path . --script tools/_probe_tournament_spark2.gd

const BAKE := preload("res://scripts/world/scatter_bake.gd")
const WORLD_NAME := "playground"


func _init() -> void:
	var drained := {}
	var by_layer: Dictionary = BAKE.load_all(WORLD_NAME, drained, {}, {})
	var centre := Vector2(17.0, 10.0)
	var radius := 10.0
	var hits: Array = []
	for layer_name: String in by_layer.keys():
		var entries: Array = by_layer[layer_name]
		for entry: Variant in entries:
			var placement: Dictionary = entry as Dictionary
			var pos: Vector3 = placement["position"]
			var d := Vector2(pos.x, pos.z).distance_to(centre)
			if d <= radius:
				hits.append({"d": d, "layer": layer_name, "model": placement["model"], "pos": pos})
	hits.sort_custom(func(a, b): return a["d"] < b["d"])
	print("[probe2] %d baked placements within %.1fm of (%.1f,%.1f)" % [hits.size(), radius, centre.x, centre.y])
	for h: Dictionary in hits:
		print("  %.2fm  layer=%-12s model=%-50s pos=%s" % [h["d"], h["layer"], h["model"], str(h["pos"])])
	quit(0)
