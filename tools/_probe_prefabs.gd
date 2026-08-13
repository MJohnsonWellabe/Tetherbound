extends SceneTree

## EV6 scratch probe: build every prefab recipe once and report its combined
## AABB, so recipe mistakes (missing modules, walls a metre adrift) surface
## before a full capture run.

const PREFABS := preload("res://scripts/world/building_prefabs.gd")


func _init() -> void:
	var lib: RefCounted = PREFABS.new()
	if not lib.call("load_recipes"):
		quit(1)
		return
	for name in ["workshop", "cottage_a", "cottage_b", "well", "fence_run", "wagon", "mill", "footbridge", "ranger_station"]:
		var node: Node3D = lib.call("instantiate", str(name))
		if node == null:
			print("%s: FAILED to build" % name)
			continue
		var aabb: AABB = lib.call("combined_aabb", node)
		print("%-10s min(%6.2f %6.2f %6.2f) max(%6.2f %6.2f %6.2f) size(%5.2f %5.2f %5.2f)" % [
			name,
			aabb.position.x, aabb.position.y, aabb.position.z,
			aabb.end.x, aabb.end.y, aabb.end.z,
			aabb.size.x, aabb.size.y, aabb.size.z,
		])
		node.free()
	quit(0)
