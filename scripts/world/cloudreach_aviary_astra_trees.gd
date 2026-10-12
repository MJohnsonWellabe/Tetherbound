extends RefCounted

## Candidate-only presentation thinning of two precisely bound decorative trees.
## The calling Aviary flag owns this change. Anchors, meshes, materials and all
## collision stay intact; unexpected collision fails before either tree changes.
static func apply(world: Node3D, spec: Dictionary) -> Dictionary:
	var bindings: Array = spec.get("bindings", [])
	var fraction := float(spec.get("scale_fraction", 1.0))
	if bindings.size() != 2 or fraction <= 0.0 or fraction >= 1.0:
		return {"complete": false, "failure": "Expected two bound trees and a thinning fraction"}
	var trees: Array[Node3D] = []
	for binding: Dictionary in bindings:
		var tree := world.get_node_or_null(NodePath(str(binding.path))) as Node3D
		if tree == null:
			return {"complete": false, "failure": "Missing approach tree: " + str(binding.path)}
		var xyz: Array = binding.position
		var expected := Vector3(float(xyz[0]), float(xyz[1]), float(xyz[2]))
		if tree.global_position.distance_to(expected) > 0.05 \
				or not tree.scale.is_equal_approx(Vector3.ONE * float(binding.scale)):
			return {"complete": false, "failure": "Approach tree transform changed: " + str(binding.path)}
		if tree.scene_file_path != str(binding.scene):
			return {"complete": false, "failure": "Approach tree asset changed: " + str(binding.path)}
		if tree is CollisionObject3D or tree is CollisionShape3D \
				or not tree.find_children("*", "CollisionObject3D", true, false).is_empty() \
				or not tree.find_children("*", "CollisionShape3D", true, false).is_empty():
			return {"complete": false, "failure": "Approach tree has collision; visual-only thinning refused"}
		if tree.has_meta("astra_tree_thinned"):
			return {"complete": false, "failure": "Approach tree already thinned"}
		trees.append(tree)
	var rows: Array[Dictionary] = []
	for index in trees.size():
		var tree := trees[index]
		var before := bounds(tree)
		var old_scale := tree.scale
		tree.scale *= fraction
		tree.set_meta("astra_tree_thinned", true)
		rows.append({"path": str(bindings[index].path), "scene": tree.scene_file_path,
			"anchor": vector(tree.global_position), "old_scale": vector(old_scale),
			"new_scale": vector(tree.scale), "scale_fraction": fraction,
			"old_bounds": box(before), "new_bounds": box(bounds(tree)),
			"collision_objects": 0, "collision_shapes": 0,
			"mesh_or_material_replaced": false, "hidden": false})
	return {"complete": true, "trees": rows, "anchors_unchanged": true,
		"scope": "Two decorative trees reduced to saplings; no movement, collider or actor change"}


static func bounds(tree: Node3D) -> AABB:
	var nodes: Array[Node] = [tree]
	nodes.append_array(tree.find_children("*", "MeshInstance3D", true, false))
	var result := AABB()
	var first := true
	for node: Node in nodes:
		var mesh := node as MeshInstance3D
		if mesh == null or mesh.mesh == null:
			continue
		var local := mesh.get_aabb()
		for corner in 8:
			var point := mesh.global_transform * local.get_endpoint(corner)
			if first:
				result = AABB(point, Vector3.ZERO)
				first = false
			else:
				result = result.expand(point)
	return result


static func vector(value: Vector3) -> Array:
	return [value.x, value.y, value.z]


static func box(value: AABB) -> Dictionary:
	return {"position": vector(value.position), "size": vector(value.size)}
