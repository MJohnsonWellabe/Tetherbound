extends SceneTree

## Which way does the road-gate leaf actually face? The two callers in
## `playground_world.gd` disagree with each other by 90 degrees if you assume
## the obvious convention, and getting this wrong stands the final gate of the
## chapter sideways-on to the road it is supposed to shut. Measured off the
## prefab's own AABB rather than reasoned about.

const PREFABS := preload("res://scripts/world/building_prefabs.gd")

func _init() -> void:
	var prefabs: RefCounted = PREFABS.new()

	if not prefabs.call("load_recipes"):
		print("no recipes")
		quit(1)
		return
	var holder := Node3D.new()
	root.add_child(holder)
	prefabs.call("set_template_holder", holder)
	var leaf: Node3D = prefabs.call("instantiate", "road_gate_leaf")
	if leaf == null:
		print("no road_gate_leaf prefab")
		quit(1)
		return
	root.add_child(leaf)
	var aabb: AABB = prefabs.call("combined_aabb", leaf)
	print("road_gate_leaf local AABB size: x=%.2f y=%.2f z=%.2f" % [
		aabb.size.x, aabb.size.y, aabb.size.z])
	if aabb.size.x > aabb.size.z:
		print("  the panel SPANS LOCAL X -> yaw = atan2(bearing.x, bearing.z) puts it ACROSS the road")
	else:
		print("  the panel SPANS LOCAL Z -> yaw = atan2(bearing.x, bearing.z) + 90 puts it ACROSS the road")
	quit(0)
