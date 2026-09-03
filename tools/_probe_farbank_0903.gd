extends SceneTree

## TREE-SILHOUETTE-0903. The composition plan's own coordinate for the basin
## far-side grove, (-420,560), probes underwater (see
## _probe_tree_silhouette_0903.gd). Scans a grid around the mill's far side
## for the nearest dry, plantable ground so the anchor can be re-sited
## against real terrain instead of the plan's guess.
##
##   godot --headless --path . --script tools/_probe_farbank_0903.gd

const HEIGHTFIELD := preload("res://scripts/world/playground_heightfield.gd")


func _init() -> void:
	var f: RefCounted = HEIGHTFIELD.new()
	var water: float = float(f.water_level())
	print("water level %.2f" % water)
	print("%8s %8s %7s %7s %6s" % ["x", "z", "h", "slope", "dry?"])
	for x in range(-460, -370, 8):
		for z in range(520, 610, 8):
			var h: float = f.height_at(float(x), float(z))
			var hx: float = f.height_at(float(x) + 1.0, float(z))
			var hz: float = f.height_at(float(x), float(z) + 1.0)
			var dx := hx - h
			var dz := hz - h
			var slope := rad_to_deg(atan2(sqrt(dx * dx + dz * dz), 1.0))
			var dry := h > water + 1.0
			if dry and slope < 21.0:
				print("%8d %8d %7.2f %7.2f %6s" % [x, z, h, slope, "DRY"])
	quit(0)
