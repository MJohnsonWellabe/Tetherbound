extends SceneTree

## OW5 throwaway: where does the vegetation scatter's load time actually go?
##
##   godot --headless --path . --script tools/_probe_ow5_veg_cost.gd
##
## The item claims `vegetation.gd::build()` is one of two systems that build the
## entire world at load and will not survive a 48x larger map. That is a claim
## about a total. This splits the total into the phases that scale differently,
## because "1.38 million instances built in GDScript" is only actionable if you
## know whether the cost is the placement MATHS (pure, per-candidate), the
## MultiMesh fill (per-instance, cheap per unit), the per-instance COLLIDER
## NODES (per-solid-instance, expensive per unit) or the harvest points.
##
## Delete when OW5's scatter half lands or is written up.

const RULES := preload("res://scripts/world/scatter_rules.gd")
const HEIGHTFIELD := preload("res://scripts/world/playground_heightfield.gd")
const VEGETATION := preload("res://scripts/world/vegetation.gd")


func _init() -> void:
	_run()


func _run() -> void:
	await process_frame

	var t0 := Time.get_ticks_usec()
	var field: RefCounted = HEIGHTFIELD.new()
	var t1 := Time.get_ticks_usec()

	var cfg: Dictionary = RULES.config()
	var drained: Dictionary = {}
	var by_layer: Dictionary = RULES.all_placements(field, 512.0, int(cfg.get("seed", 1)), drained)
	var t2 := Time.get_ticks_usec()

	var total := 0
	for name: String in by_layer.keys():
		total += (by_layer[name] as Array).size()
	var drained_total := 0
	for name: String in drained.keys():
		drained_total += (drained[name] as Array).size()

	print("heightfield construct : %8.1f ms" % ((t1 - t0) / 1000.0))
	print("all_placements (pure) : %8.1f ms  -> %d placements across %d layers (+%d drained out)" % [
		(t2 - t1) / 1000.0, total, by_layer.size(), drained_total
	])

	# The whole thing, node work included, through the real entry point.
	var veg: Node3D = VEGETATION.new()
	root.add_child(veg)
	var t3 := Time.get_ticks_usec()
	veg.call("build", 512.0)
	var t4 := Time.get_ticks_usec()
	var stats: Dictionary = veg.call("stats")
	print("vegetation.build()    : %8.1f ms  -> %s" % [(t4 - t3) / 1000.0, stats])

	# How many nodes it left behind, which is the number that scales worst:
	# each is a real Node in the SceneTree, not a MultiMesh row.
	var nodes := 0
	var bodies := 0
	var shapes := 0
	for child in veg.get_children():
		nodes += 1
		if child is StaticBody3D:
			bodies += 1
			shapes += child.get_child_count()
	print("scene nodes under Vegetation: %d direct children (%d StaticBody3D holding %d CollisionShape3D)" % [
		nodes, bodies, shapes
	])

	# Per-layer, so a 48x projection can be made per layer rather than by
	# multiplying one total that hides which layer dominates.
	print("")
	for name: String in by_layer.keys():
		print("  %-16s %6d" % [name, (by_layer[name] as Array).size()])

	quit()
