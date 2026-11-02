extends RefCounted

## Owner priority, 1 Nov (judges on almost every frame: "cameras inside
## foliage or walls"; Meadows mill stands, the Warden arena, the stronghold
## courtyard, Cloudreach plazas). `camera.json` `occlusion_fade`, OFF by
## default: the rig asks how far along its arm the first rendered occluder
## lies, and keeps the lens in front of it. The spring arm already stops at
## colliders; this covers what has none: canopies and foliage (MultiMesh
## scatter), visual-only walls, props and trim.
##
## Pure query: given a segment and the nodes to ignore, return the distance to
## the first hit. Skinned bodies (creatures, people) are ignored, as are
## effect cards and grass (no shadow) and anything shorter than
## `min_height_m`. MultiMesh scatter is indexed once per MultiMesh on a coarse
## grid so a query only tests the instances near the segment.

const CONFIG_PATH := "res://data/config/camera.json"
const GRID_M := 12.0

static var _cfg: Dictionary = {}
static var _loaded := false
static var _tris: Dictionary = {}
static var _grids: Dictionary = {}


static func config() -> Dictionary:
	if not _loaded:
		_loaded = true
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(CONFIG_PATH))
		if parsed is Dictionary and (parsed as Dictionary).get("occlusion_fade") is Dictionary:
			_cfg = (parsed as Dictionary)["occlusion_fade"]
	return _cfg


static func enabled() -> bool:
	return bool(config().get("enabled", false))


## Metres from `from` to the first rendered occluder on the way to `to`, or
## INF when the segment is clear. `ignore` holds nodes whose subtrees never
## count (the followed body, the person being spoken to).
static func first_hit(world: World3D, from: Vector3, to: Vector3, ignore: Array) -> float:
	if world == null:
		return INF
	var cfg := config()
	var min_height := float(cfg.get("min_height_m", 1.2))
	var best := INF
	var seg := to - from
	var length := seg.length()
	if length < 0.05:
		return INF
	for id: int in RenderingServer.instances_cull_ray(from, to, world.scenario):
		var node := instance_from_id(id)
		if node == null or not (node is GeometryInstance3D):
			continue
		var geometry := node as GeometryInstance3D
		if not geometry.is_visible_in_tree() \
				or geometry.cast_shadow == GeometryInstance3D.SHADOW_CASTING_SETTING_OFF \
				or geometry.cast_shadow == GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY:
			continue
		if _ignored(geometry, ignore):
			continue
		var hit := INF
		if geometry is MeshInstance3D:
			var mesh_node := geometry as MeshInstance3D
			if mesh_node.mesh == null or not mesh_node.skeleton.is_empty():
				continue
			if mesh_node.mesh.get_aabb().size.y * absf(mesh_node.global_basis.get_scale().y) < min_height:
				continue
			hit = _mesh_hit(mesh_node.mesh, mesh_node.global_transform, from, to)
		elif geometry is MultiMeshInstance3D:
			hit = _multimesh_hit(geometry as MultiMeshInstance3D, from, to, min_height)
		if hit < best:
			best = hit
	return best


## Every rendered occluder on the segment: {"node": GeometryInstance3D,
## "index": -1 for a mesh or the MultiMesh instance index}. Same filters as
## `first_hit`.
## `options` (camfx.json `fight_fade`): `include_shadowless` also takes
## geometry that casts no shadow (canopy leaf cards) when it is at least
## `shadowless_min_height_m` tall, so grass and effect cards still stay.
static func occluders(world: World3D, from: Vector3, to: Vector3, ignore: Array, options: Dictionary = {}) -> Array:
	var out: Array = []
	if world == null or from.distance_to(to) < 0.05:
		return out
	var min_height := float(config().get("min_height_m", 1.2))
	var shadowless: bool = options.get("include_shadowless", false) == true
	var shadowless_min := float(options.get("shadowless_min_height_m", 2.5))
	for id: int in RenderingServer.instances_cull_ray(from, to, world.scenario):
		var node := instance_from_id(id)
		if node == null or not (node is GeometryInstance3D):
			continue
		var geometry := node as GeometryInstance3D
		if not geometry.is_visible_in_tree() \
				or geometry.cast_shadow == GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY:
			continue
		var no_shadow := geometry.cast_shadow == GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		if no_shadow and not shadowless:
			continue
		var needed := maxf(min_height, shadowless_min) if no_shadow else min_height
		if _ignored(geometry, ignore):
			continue
		if geometry is MeshInstance3D:
			var mesh_node := geometry as MeshInstance3D
			if mesh_node.mesh == null or not mesh_node.skeleton.is_empty():
				continue
			if mesh_node.mesh.get_aabb().size.y * absf(mesh_node.global_basis.get_scale().y) < needed:
				continue
			if _mesh_hit(mesh_node.mesh, mesh_node.global_transform, from, to) < INF:
				out.append({"node": mesh_node, "index": -1})
		elif geometry is MultiMeshInstance3D:
			for index: int in _multimesh_hits(geometry as MultiMeshInstance3D, from, to, needed):
				out.append({"node": geometry, "index": index})
	return out


## Instance indices of `node` whose triangles cross the segment.
static func _multimesh_hits(node: MultiMeshInstance3D, from: Vector3, to: Vector3, min_height: float) -> Array:
	var out: Array = []
	var mm := node.multimesh
	if mm == null or mm.mesh == null:
		return out
	var box := mm.mesh.get_aabb()
	if box.size.y < min_height * 0.5:
		return out
	var grid := _grid_for(node)
	var to_local := node.global_transform.affine_inverse()
	var a := to_local * from
	var b := to_local * to
	var reach := box.size.length() * 0.5 * float(grid.get("max_scale", 1.0))
	var tris := _triangles(mm.mesh)
	if tris == null:
		return out
	var seg := b - a
	var length_sq := maxf(seg.length_squared(), 0.0001)
	var by_cell: Dictionary = grid.get("cells", {})
	var seen := {}
	var steps := maxi(1, int(ceil(a.distance_to(b) / (GRID_M * 0.5))))
	for s in steps + 1:
		var p := a.lerp(b, float(s) / float(steps))
		var cx := int(floor(p.x / GRID_M))
		var cz := int(floor(p.z / GRID_M))
		for dx in [-1, 0, 1]:
			for dz in [-1, 0, 1]:
				for i: int in by_cell.get(Vector2i(cx + dx, cz + dz), []):
					if seen.has(i):
						continue
					seen[i] = true
					var xf := mm.get_instance_transform(i)
					if xf.basis.determinant() == 0.0:
						# Already hidden by the fade; its own entry keeps it.
						xf = grid.get("hidden", {}).get(i, xf)
					var centre := xf * box.get_center()
					var t := clampf((centre - a).dot(seg) / length_sq, 0.0, 1.0)
					if (a + seg * t).distance_to(centre) > reach:
						continue
					var inv := xf.affine_inverse()
					if not tris.intersect_segment(inv * a, inv * b).is_empty():
						out.append(i)
	return out


## Fade bookkeeping for MultiMesh instances lives with the grid so a hidden
## instance's original transform is never lost.
static func hide_instance(node: MultiMeshInstance3D, index: int) -> void:
	var grid := _grid_for(node)
	var hidden: Dictionary = grid.get("hidden", {})
	if hidden.has(index):
		return
	var xf := node.multimesh.get_instance_transform(index)
	hidden[index] = xf
	grid["hidden"] = hidden
	node.multimesh.set_instance_transform(index, Transform3D(Basis.from_scale(Vector3.ZERO), xf.origin))


static func show_instance(node: MultiMeshInstance3D, index: int) -> void:
	if not is_instance_valid(node) or node.multimesh == null:
		return
	var grid := _grid_for(node)
	var hidden: Dictionary = grid.get("hidden", {})
	if not hidden.has(index):
		return
	node.multimesh.set_instance_transform(index, hidden[index])
	hidden.erase(index)


static func _ignored(node: Node, ignore: Array) -> bool:
	for owner_node: Variant in ignore:
		if owner_node is Node and is_instance_valid(owner_node) \
				and (node == owner_node or (owner_node as Node).is_ancestor_of(node)):
			return true
	return false


static func _triangles(mesh: Mesh) -> TriangleMesh:
	var key := mesh.get_instance_id()
	if not _tris.has(key):
		_tris[key] = mesh.generate_triangle_mesh()
	return _tris[key]


static func _mesh_hit(mesh: Mesh, xf: Transform3D, from: Vector3, to: Vector3) -> float:
	var tris := _triangles(mesh)
	if tris == null:
		return INF
	var inv := xf.affine_inverse()
	var result := tris.intersect_segment(inv * from, inv * to)
	if result.is_empty():
		return INF
	return from.distance_to(xf * Vector3(result["position"]))


static func _multimesh_hit(node: MultiMeshInstance3D, from: Vector3, to: Vector3, min_height: float) -> float:
	var mm := node.multimesh
	if mm == null or mm.mesh == null:
		return INF
	var box := mm.mesh.get_aabb()
	if box.size.y < min_height * 0.5:
		return INF
	var grid := _grid_for(node)
	var to_local := node.global_transform.affine_inverse()
	var a := to_local * from
	var b := to_local * to
	var reach := box.size.length() * 0.5 * float(grid.get("max_scale", 1.0))
	var cells := {}
	var steps := maxi(1, int(ceil(a.distance_to(b) / (GRID_M * 0.5))))
	for s in steps + 1:
		var p := a.lerp(b, float(s) / float(steps))
		var cx := int(floor(p.x / GRID_M))
		var cz := int(floor(p.z / GRID_M))
		for dx in [-1, 0, 1]:
			for dz in [-1, 0, 1]:
				cells[Vector2i(cx + dx, cz + dz)] = true
	var tris := _triangles(mm.mesh)
	if tris == null:
		return INF
	var best := INF
	var seg := b - a
	var length_sq := maxf(seg.length_squared(), 0.0001)
	var by_cell: Dictionary = grid.get("cells", {})
	for cell: Vector2i in cells:
		for i: int in by_cell.get(cell, []):
			var xf := mm.get_instance_transform(i)
			var centre := xf * box.get_center()
			var t := clampf((centre - a).dot(seg) / length_sq, 0.0, 1.0)
			if (a + seg * t).distance_to(centre) > reach:
				continue
			var inv := xf.affine_inverse()
			var result := tris.intersect_segment(inv * a, inv * b)
			if result.is_empty():
				continue
			var at := node.global_transform * (xf * Vector3(result["position"]))
			best = minf(best, from.distance_to(at))
	return best


static func _grid_for(node: MultiMeshInstance3D) -> Dictionary:
	var mm := node.multimesh
	var key := mm.get_instance_id()
	var count := mm.visible_instance_count if mm.visible_instance_count >= 0 else mm.instance_count
	if _grids.has(key) and int((_grids[key] as Dictionary).get("count", -1)) == count:
		return _grids[key]
	var cells := {}
	var max_scale := 1.0
	for i in count:
		var xf := mm.get_instance_transform(i)
		max_scale = maxf(max_scale, xf.basis.get_scale().length() / sqrt(3.0))
		var cell := Vector2i(int(floor(xf.origin.x / GRID_M)), int(floor(xf.origin.z / GRID_M)))
		if not cells.has(cell):
			cells[cell] = []
		(cells[cell] as Array).append(i)
	var grid := {"count": count, "cells": cells, "max_scale": max_scale}
	_grids[key] = grid
	return grid
