extends SceneTree

## GATE-D4b: name the pale panels round 1 of the blind visual pass called
## "unlit or untextured billboard quads that failed to resolve", visible over
## the horizon in three of five Band 4 frames. Walks the built world for large
## visuals standing north of the field camp and prints what they actually are,
## because a critic looking at forty pixels can say a thing reads as a bug but
## not what the thing is.
##
##   godot --headless --path . --script tools/_probe_d4_panels.gd
##
## ANSWER: `RiftCollapse/StormWall` -- three QuadMeshes 360-460m wide and
## 122-190m tall at z 7870-7968, unshaded, alpha-blended, no depth write off,
## `_slab_material()` in scripts/world/rift_collapse.gd. Its own header calls
## them "a painted horizon" that "has to look like the sky it stands in", and
## down a spoke road, framed by terrain, they do. From Band 4's open pasture
## 1.4-1.9km south they are three overlapping grey rectangles with hard
## vertical corners standing above a bare ridge, which is what the critic saw.
## Not band content and not this lane's file to fix -- recorded for the
## coordinator with the geometry named, so the next pass argues about the
## storm wall's viewing angles rather than re-deriving what the panes are.

const SCENE := "res://scenes/world/meadows_playground.tscn"


func _init() -> void:
	var world: Node = (load(SCENE) as PackedScene).instantiate()
	root.add_child(world)
	for i in 120:
		await process_frame
	var stack: Array[Node] = [world]
	var hits: Array[String] = []
	while not stack.is_empty():
		var node: Node = stack.pop_back()
		stack.append_array(node.get_children())
		if not node is VisualInstance3D:
			continue
		var v := node as VisualInstance3D
		var aabb := v.get_aabb()
		var p: Vector3 = v.global_transform * aabb.get_center()
		var size := aabb.size * v.global_transform.basis.get_scale()
		if p.z < 6100.0 or p.z > 9000.0 or absf(p.x - 330.0) > 900.0:
			continue
		if size.length() < 8.0:
			continue
		hits.append("%-42s %-22s at (%.0f, %.0f, %.0f) size (%.1f, %.1f, %.1f)" % [
			v.get_path(), v.get_class(), p.x, p.y, p.z, size.x, size.y, size.z])
	hits.sort()
	for h in hits:
		print(h)
	print("total: %d" % hits.size())
	quit(0)
