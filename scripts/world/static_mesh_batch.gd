extends RefCounted

## PERF (F26#5, 2026-10-05). Static kit geometry, merged per material.
##
## A settlement building is composed from dozens of MegaKit modules
## (building_prefabs.gd), and every module surface is its own draw call in
## the main pass and again in each directional shadow cascade. Measured at the
## Meadows F26 start stand: the Village alone was 6,417 of 8,641 draw calls.
## Imported glTF modules also each carry their own copy of the kit's shared
## materials (1,902 surfaces over 368 material objects), so batching by
## material identity alone would merge almost nothing.
##
## `merge(root)` folds every eligible MeshInstance3D under `root` into one
## MeshInstance3D per (equivalent material, render settings, vertex format),
## in `root`'s local space, and hides the originals. The originals stay in the
## tree, so code that looks a module up by name, reads its material or its
## bounds keeps working; they simply stop being submitted to the renderer.
## Geometry, materials and shading are unchanged: the same triangles with the
## same materials, drawn in fewer calls.
##
## Eligible means static and plain. A mesh is left alone (and keeps drawing
## itself) when it, or any ancestor below `root`:
##   - carries a script (interiors, lights, doors, interactables animate or
##     rebuild their own children);
##   - has meta `static_batch_skip` (a plain module some script moves by
##     reference, such as a door leaf);
## or when the mesh itself is skinned, has blend shapes, a material overlay,
## instance transparency, a material that depends on per-object space or
## sorting (`_blended`), a visibility-range begin, a mirrored transform, a
## non-triangle surface, or anything drawn beneath it in the tree.
##
## Unbatched meshes are drawn exactly as before. Each merged surface gets a
## fresh automatic LOD chain (`_with_lods`) and keeps the copied visibility
## range.

const SKIP_META := &"static_batch_skip"
const BATCH_PREFIX := "StaticBatch"

static var _material_keys: Dictionary = {}


## Returns {"meshes": merged source meshes, "surfaces": merged source surfaces,
## "batches": resulting draw surfaces}.
static func merge(root: Node3D) -> Dictionary:
	var stats := {"meshes": 0, "surfaces": 0, "batches": 0}
	if root == null:
		return stats
	var groups := {}
	var order: Array = []
	var merged_nodes: Array[MeshInstance3D] = []
	for mi: MeshInstance3D in _eligible(root):
		var xform := _relative(mi, root)
		if xform.basis.determinant() <= 0.0:
			continue
		var mesh := mi.mesh
		# A node is batched whole or not at all: hiding it must never lose a
		# surface that was left out.
		var whole := true
		for surface in mesh.get_surface_count():
			var material := mi.get_active_material(surface)
			if material == null or not _surface_ok(mesh, surface) or _blended(material):
				whole = false
				break
		if not whole:
			continue
		for surface in mesh.get_surface_count():
			var material := mi.get_active_material(surface)
			var key := "%s|%d|%d|%d|%.2f|%.2f|%d|%d" % [
				_material_key(material), mi.cast_shadow, mi.layers, mi.gi_mode,
				mi.visibility_range_end, mi.visibility_range_end_margin,
				mi.visibility_range_fade_mode, _format_key(mesh, surface)]
			if not groups.has(key):
				groups[key] = {"material": material, "template": mi, "parts": []}
				order.append(key)
			(groups[key].parts as Array).append([mesh, surface, xform])
			stats.surfaces += 1
		merged_nodes.append(mi)
	# Build every merged mesh before touching the tree, so a failure leaves the
	# building exactly as it was rather than half batched.
	var built: Array = []
	for key: String in order:
		var group: Dictionary = groups[key]
		var tool := SurfaceTool.new()
		tool.begin(Mesh.PRIMITIVE_TRIANGLES)
		for part: Array in group.parts:
			tool.append_from(part[0] as Mesh, int(part[1]), part[2] as Transform3D)
		var merged := tool.commit()
		if merged == null or merged.get_surface_count() == 0:
			push_error("static_mesh_batch: a merged group under %s came back empty; left unbatched" % root.name)
			return {"meshes": 0, "surfaces": 0, "batches": 0}
		built.append([_with_lods(merged, group.material as Material), group.template])
	var index := 0
	for entry: Array in built:
		var template := entry[1] as MeshInstance3D
		var batch := MeshInstance3D.new()
		batch.name = "%s_%d" % [BATCH_PREFIX, index]
		batch.mesh = entry[0] as Mesh
		batch.cast_shadow = template.cast_shadow
		batch.layers = template.layers
		batch.gi_mode = template.gi_mode
		batch.visibility_range_end = template.visibility_range_end
		batch.visibility_range_end_margin = template.visibility_range_end_margin
		batch.visibility_range_fade_mode = template.visibility_range_fade_mode
		batch.set_meta(SKIP_META, true)
		root.add_child(batch)
		index += 1
	for mi: MeshInstance3D in merged_nodes:
		mi.visible = false
	stats.meshes = merged_nodes.size()
	stats.batches = index
	return stats


## The importer gave each kit module an automatic LOD chain; a SurfaceTool
## merge drops it, which raised primitives ~10% at the Meadows stands. Rebuild
## the chain on the merged surface the same way the importer does.
static func _with_lods(merged: ArrayMesh, material: Material) -> ArrayMesh:
	var importer := ImporterMesh.new()
	importer.add_surface(Mesh.PRIMITIVE_TRIANGLES, merged.surface_get_arrays(0), [], {}, material)
	importer.generate_lods(25.0, 60.0, [])
	var out := importer.get_mesh()
	if out == null or out.get_surface_count() == 0:
		merged.surface_set_material(0, material)
		return merged
	return out


static func _eligible(root: Node3D) -> Array[MeshInstance3D]:
	var out: Array[MeshInstance3D] = []
	var stack: Array[Node] = []
	for child: Node in root.get_children():
		stack.append(child)
	while not stack.is_empty():
		var node: Node = stack.pop_back()
		if node.get_script() != null or node.has_meta(SKIP_META):
			continue
		if node is Node3D and not (node as Node3D).visible:
			continue
		# Hiding a merged mesh hides its whole subtree, so a mesh with anything
		# drawn beneath it (a light, a scripted or skipped node, another mesh)
		# keeps drawing itself. Its descendants are still considered alone.
		if node is MeshInstance3D and _mesh_ok(node as MeshInstance3D) and not _draws_beneath(node):
			out.append(node as MeshInstance3D)
		for child: Node in node.get_children():
			stack.append(child)
	return out


static func _draws_beneath(node: Node) -> bool:
	for child: Node in node.get_children():
		if child is VisualInstance3D or child.get_script() != null or child.has_meta(SKIP_META) \
				or _draws_beneath(child):
			return true
	return false


static func _mesh_ok(mi: MeshInstance3D) -> bool:
	var mesh := mi.mesh
	if mesh == null or mesh.get_surface_count() == 0:
		return false
	if mi.skin != null or mi.material_overlay != null or mi.transparency > 0.0 \
			or mi.visibility_range_begin > 0.0:
		return false
	if mesh is ArrayMesh and (mesh as ArrayMesh).get_blend_shape_count() > 0:
		return false
	return true


## A material that cannot survive a merge:
## - alpha-blended surfaces sort per object; merged, their draw order inside
##   the batch would change (alpha scissor and hash are depth-tested and safe);
## - anything that reads a vertex in the mesh's own space or the node's
##   transform (a custom `vertex()` such as banner cloth, MODEL_MATRIX,
##   NODE_POSITION, billboards, object-space triplanar) would see the
##   building's space instead once merged;
## - a next pass inherits the same limits, so it must qualify too.
static func _blended(material: Material) -> bool:
	if material == null:
		return false
	if material is BaseMaterial3D:
		var base := material as BaseMaterial3D
		var mode := base.transparency
		if mode == BaseMaterial3D.TRANSPARENCY_ALPHA or mode == BaseMaterial3D.TRANSPARENCY_ALPHA_DEPTH_PRE_PASS:
			return true
		if base.billboard_mode != BaseMaterial3D.BILLBOARD_DISABLED:
			return true
		if (base.uv1_triplanar and not base.uv1_world_triplanar) or (base.uv2_triplanar and not base.uv2_world_triplanar):
			return true
	elif material is ShaderMaterial:
		var shader := (material as ShaderMaterial).shader
		if shader == null:
			return false
		var code := shader.code
		if code.contains("ALPHA") and not code.contains("ALPHA_SCISSOR_THRESHOLD"):
			return true
		if code.contains("void vertex(") or code.contains("void vertex (") or code.contains("MODEL_MATRIX") \
				or code.contains("NODE_POSITION"):
			return true
	else:
		return true
	return _blended(material.next_pass)


static func _surface_ok(mesh: Mesh, surface: int) -> bool:
	if mesh is ArrayMesh:
		return (mesh as ArrayMesh).surface_get_primitive_type(surface) == Mesh.PRIMITIVE_TRIANGLES
	return true


static func _format_key(mesh: Mesh, surface: int) -> int:
	# Mixing surfaces with and without an attribute would zero-fill it, e.g.
	# black vertex colour. Only the attribute bits matter here.
	if not mesh is ArrayMesh:
		return -1
	var mask := Mesh.ARRAY_FORMAT_NORMAL | Mesh.ARRAY_FORMAT_TANGENT | Mesh.ARRAY_FORMAT_COLOR \
		| Mesh.ARRAY_FORMAT_TEX_UV | Mesh.ARRAY_FORMAT_TEX_UV2 | Mesh.ARRAY_FORMAT_BONES \
		| Mesh.ARRAY_FORMAT_WEIGHTS | Mesh.ARRAY_FORMAT_CUSTOM0 | Mesh.ARRAY_FORMAT_CUSTOM1 \
		| Mesh.ARRAY_FORMAT_CUSTOM2 | Mesh.ARRAY_FORMAT_CUSTOM3
	return (mesh as ArrayMesh).surface_get_format(surface) & mask


## Equal for two material objects whose stored properties are equal, so the
## kit's per-module copies of MI_Plaster fold into one batch. Textures and
## other resources compare by path, or by identity when unsaved.
static func _material_key(material: Material) -> String:
	var id := material.get_instance_id()
	if _material_keys.has(id):
		return _material_keys[id]
	var parts: PackedStringArray = [material.get_class()]
	for property: Dictionary in material.get_property_list():
		if not (int(property.usage) & PROPERTY_USAGE_STORAGE):
			continue
		var name := str(property.name)
		if name in ["resource_name", "resource_path", "resource_local_to_scene", "script"]:
			continue
		var value: Variant = material.get(name)
		if value is Resource:
			var resource := value as Resource
			parts.append("%s=%s" % [name, resource.resource_path if resource.resource_path != "" \
				else "#%d" % resource.get_instance_id()])
		elif value is Object:
			parts.append("%s=#%d" % [name, (value as Object).get_instance_id()])
		else:
			parts.append("%s=%s" % [name, var_to_str(value)])
	var key := "|".join(parts).sha256_text()
	_material_keys[id] = key
	return key


static func _relative(node: Node3D, ancestor: Node3D) -> Transform3D:
	var xform := Transform3D.IDENTITY
	var at: Node = node
	while at != null and at != ancestor:
		if at is Node3D:
			xform = (at as Node3D).transform * xform
		at = at.get_parent()
	return xform
