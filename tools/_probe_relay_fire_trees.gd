extends SceneTree

## VP11 probe: which baked scatter placements sit around the `05-relay-camp`
## `fire` detail stand (`tools/_capture_locations.gd`, at [237,3678], look
## [241.4,3667.3], back 3.0)? The final recapture put a tree canopy across the
## whole frame there while PLACES round 10 (older bake) was clear. Reads the
## bake directly (`scripts/world/scatter_bake.gd::load_all`), no world load.
##
##   godot --headless --path . --script tools/_probe_relay_fire_trees.gd [-- --at=X,Z --radius=R]

const SCATTER_BAKE := preload("res://scripts/world/scatter_bake.gd")


func _init() -> void:
	var centre := Vector2(236.0, 3681.0)
	var radius := 20.0
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--at="):
			var p := arg.substr(5).split(",")
			centre = Vector2(float(p[0]), float(p[1]))
		elif arg.begins_with("--radius="):
			radius = float(arg.substr(9))
	var by_layer: Dictionary = SCATTER_BAKE.load_all("playground")
	var rows: Array = []
	for layer_name: String in by_layer.keys():
		for placement: Dictionary in by_layer[layer_name]:
			var pos: Vector3 = placement["position"]
			var d := Vector2(pos.x, pos.z).distance_to(centre)
			if d <= radius:
				rows.append([d, layer_name, placement["model"], pos, placement["scale"]])
	rows.sort_custom(func(a: Array, b: Array) -> bool: return a[0] < b[0])
	print("placements within %.1f m of (%.1f, %.1f): %d" % [radius, centre.x, centre.y, rows.size()])
	for r: Array in rows:
		if String(r[1]).findn("grass") >= 0 or String(r[1]).findn("flower") >= 0 or String(r[1]).findn("groundmat") >= 0:
			continue
		print("  %6.2f m  %-12s %-22s at (%.1f, %.1f, %.1f) scale %.2f" % [r[0], r[1], r[2], r[3].x, r[3].y, r[3].z, r[4]])
	quit(0)
