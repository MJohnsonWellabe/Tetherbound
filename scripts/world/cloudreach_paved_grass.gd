extends RefCounted

## P2-025 (Cloudreach "Tall grass intrudes through shrine paving"), flag-off.
##
## The look pass and the ground-cover pass plant grass tufts as MultiMesh
## instances over every turf collider, and a paved box (the Sky Shrine dais,
## its steps, plaza pavers) still shows blades through its top on the GPU and
## CPU frames. After every builder has run, this collapses each tuft instance
## that stands on or just under the top of a paved masonry box. Visual only:
## no collider, surface, route, flag or save changes; nothing else moves.
##
## Switch: data/config/cloudreach_grounding.json "clear_paved_grass" (default
## false). Preview: --cloudreach-paving-candidate.

const PREVIEW_ARG := "--cloudreach-paving-candidate"
const CELL_M := 16.0


static func enabled(cfg: Dictionary) -> bool:
	return bool(cfg.get("clear_paved_grass", false)) or OS.get_cmdline_user_args().has(PREVIEW_ARG)


## Paved tops as {basis_inv: Transform3D (world -> box local), half: Vector3}.
static func paved_boxes(world: Node, paving_materials: Array, min_side_m: float) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var stack: Array[Node] = [world]
	while not stack.is_empty():
		var node: Node = stack.pop_back()
		for child: Node in node.get_children():
			stack.append(child)
		var mesh := node as MeshInstance3D
		if mesh == null or not (mesh.mesh is BoxMesh) or not _visible(mesh):
			continue
		if not paving_materials.has(mesh.material_override):
			continue
		var size: Vector3 = (mesh.mesh as BoxMesh).size
		var xform := _xform(mesh)
		var scaled := Vector3(size.x * xform.basis.x.length(), size.y * xform.basis.y.length(),
			size.z * xform.basis.z.length())
		if minf(scaled.x, scaled.z) < min_side_m:
			continue
		# Only boxes whose top faces up (pavers, dais, steps), not tilted carvings.
		if xform.basis.y.normalized().dot(Vector3.UP) < 0.95:
			continue
		out.append({"to_local": xform.affine_inverse(), "half": size * 0.5,
			"aabb": xform * AABB(-size * 0.5, size)})
	return out


## True when a tuft rooted at `point` (world) stands on the box top or pokes
## through it from below (within `below_m` under the top).
static func covers(box: Dictionary, point: Vector3, below_m: float, above_m: float) -> bool:
	var local: Vector3 = (box.to_local as Transform3D) * point
	var half: Vector3 = box.half
	if absf(local.x) > half.x or absf(local.z) > half.z:
		return false
	return local.y <= half.y + above_m and local.y >= half.y - below_m


## Collapses every covered tuft instance; returns how many were cleared.
static func clear(world: Node, paving_materials: Array, cfg: Dictionary) -> int:
	var boxes := paved_boxes(world, paving_materials, float(cfg.get("paved_min_side_m", 2.0)))
	if boxes.is_empty():
		return 0
	var below := float(cfg.get("paved_below_m", 1.6))
	var above := float(cfg.get("paved_above_m", 0.6))
	var cleared := 0
	var stack: Array[Node] = [world]
	while not stack.is_empty():
		var node: Node = stack.pop_back()
		for child: Node in node.get_children():
			stack.append(child)
		var instances := node as MultiMeshInstance3D
		if instances == null or instances.multimesh == null:
			continue
		var multimesh := instances.multimesh
		if multimesh.transform_format != MultiMesh.TRANSFORM_3D or multimesh.instance_count == 0:
			continue
		var xform := _xform(instances)
		var bounds := (xform * multimesh.get_aabb()).grow(1.0)
		# A renderer without real mesh storage (headless) reports an empty AABB.
		var bounded := multimesh.get_aabb().size.length() > 0.001
		var grid := {}
		for box: Dictionary in boxes:
			var box_aabb: AABB = box.aabb
			if bounded and not bounds.intersects(box_aabb):
				continue
			for cx in range(floori(box_aabb.position.x / CELL_M), floori(box_aabb.end.x / CELL_M) + 1):
				for cz in range(floori(box_aabb.position.z / CELL_M), floori(box_aabb.end.z / CELL_M) + 1):
					var key := Vector2i(cx, cz)
					if not grid.has(key):
						grid[key] = []
					(grid[key] as Array).append(box)
		if grid.is_empty():
			continue
		var count := multimesh.visible_instance_count if multimesh.visible_instance_count >= 0 \
			else multimesh.instance_count
		for index in count:
			var t := multimesh.get_instance_transform(index)
			var root := xform * t.origin
			var cell: Variant = grid.get(Vector2i(floori(root.x / CELL_M), floori(root.z / CELL_M)))
			if cell == null:
				continue
			for box: Dictionary in cell:
				if covers(box, root, below, above):
					multimesh.set_instance_transform(index, Transform3D(Basis().scaled(Vector3.ZERO), t.origin))
					cleared += 1
					break
	return cleared


## Works in and out of a SceneTree (the headless test runner has none).
static func _xform(node: Node3D) -> Transform3D:
	if node.is_inside_tree():
		return node.global_transform
	var result := node.transform
	var parent := node.get_parent()
	while parent != null:
		if parent is Node3D:
			result = (parent as Node3D).transform * result
		parent = parent.get_parent()
	return result


static func _visible(node: Node3D) -> bool:
	if node.is_inside_tree():
		return node.is_visible_in_tree()
	var current: Node = node
	while current != null:
		if current is Node3D and not (current as Node3D).visible:
			return false
		current = current.get_parent()
	return true
