class_name MeadowhartBareBody
extends RefCounted

## The installed Meadowhart art was delivered with a complete saddle baked
## into its one skinned surface.  That made an unfitted animal look fitted,
## even though RidingController correctly withheld its real RideSaddle until
## the craft.  This adapter removes only disconnected source components whose
## centroids occupy the authored tack band, then fills the source body's
## missing middle with a low-poly torso attached to the pelvis.  The original
## skin, bones, clips, head, neck, legs, tail and materials stay production
## art; the separately crafted RideSaddle remains the only tack added at run
## time.

const TORSO_NODE := "MeadowhartBareTorso"
const ANCHOR_NODE := "MeadowhartBareTorsoAnchor"

static var _bare_mesh_cache: Dictionary = {}


static func apply(art: Node3D, config: Dictionary) -> bool:
	if art == null or config.is_empty():
		return false
	var mesh_instance := _single_skinned_mesh(art)
	if mesh_instance == null or mesh_instance.mesh == null:
		push_error("Meadowhart bare-body repair requires one skinned production mesh")
		return false
	var source := mesh_instance.mesh as ArrayMesh
	if source == null:
		push_error("Meadowhart bare-body repair requires an ArrayMesh source")
		return false
	if source.get_surface_count() != 1:
		push_error("Meadowhart bare-body repair expected one source surface, got %d" % source.get_surface_count())
		return false
	# PackedScene instantiation may localise the imported ArrayMesh, so an
	# instance id is neither stable nor unique over the lifetime of a long world
	# session.  Keying the cache by it made every Meadowhart rebuild retain a
	# second full copy of the skinned vertex arrays; ids can also be recycled
	# after the source instance is freed.  The source contract below is the
	# stable identity we actually care about: imported resource/name, surface
	# shape and the authored removal band.  All instances may safely share the
	# resulting immutable bare ArrayMesh just as they shared the imported mesh.
	var key := _source_fingerprint(source, config)
	var bare: ArrayMesh = _bare_mesh_cache.get(key) as ArrayMesh
	if bare == null:
		bare = _strip_tack_components(source, config)
		if bare == null:
			return false
		_bare_mesh_cache[key] = bare
	mesh_instance.mesh = bare
	return _add_torso_for_fit(art, config, source.surface_get_material(0))


static func _source_fingerprint(source: ArrayMesh, config: Dictionary) -> String:
	var bounds := source.get_aabb()
	return "%s|%s|%d|%d|%d|%s|%s|%s|%s" % [
		source.resource_path,
		source.resource_name,
		source.surface_get_primitive_type(0),
		source.surface_get_array_len(0),
		source.surface_get_array_index_len(0),
		bounds,
		config.get("component_centroid_min", []),
		config.get("component_centroid_max", []),
		config.get("torso_half_extents", []),
	]


static func bind_torso_to_rig(art: Node3D, config: Dictionary) -> bool:
	var torso := art.find_child(TORSO_NODE, true, false) as MeshInstance3D
	var skeleton: Skeleton3D = null
	for candidate: Node in art.find_children("*", "Skeleton3D", true, false):
		skeleton = candidate as Skeleton3D
		break
	var bone_name := str(config.get("follow_bone", "pelvis"))
	var bone_index := skeleton.find_bone(bone_name) if skeleton != null else -1
	if torso == null or skeleton == null or bone_index < 0:
		push_error("Meadowhart bare torso cannot follow missing '%s' bone" % bone_name)
		return false

	var anchor := BoneAttachment3D.new()
	anchor.name = ANCHOR_NODE
	anchor.bone_name = bone_name
	skeleton.add_child(anchor)
	# Use local chains rather than global_transform: model assembly and bounds
	# fitting happen on the same frame, before global propagation is reliable.
	var skeleton_to_art := _to_ancestor(skeleton, art)
	var desired_in_art := torso.transform
	torso.get_parent().remove_child(torso)
	anchor.add_child(torso)
	torso.transform = skeleton.get_bone_global_rest(bone_index).affine_inverse() \
		* skeleton_to_art.affine_inverse() * desired_in_art
	return true


static func _single_skinned_mesh(art: Node3D) -> MeshInstance3D:
	var found: MeshInstance3D = null
	for candidate: Node in art.find_children("*", "MeshInstance3D", true, false):
		var mesh_instance := candidate as MeshInstance3D
		if mesh_instance == null or mesh_instance.mesh == null or mesh_instance.skin == null:
			continue
		if found != null:
			return null
		found = mesh_instance
	return found


static func _strip_tack_components(source: ArrayMesh, config: Dictionary) -> ArrayMesh:
	var arrays: Array = source.surface_get_arrays(0)
	if arrays.size() != Mesh.ARRAY_MAX:
		push_error("Meadowhart source surface did not expose the standard mesh arrays")
		return null
	var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
	if vertices.is_empty() or indices.is_empty() or indices.size() % 3 != 0:
		push_error("Meadowhart source surface has invalid indexed triangle geometry")
		return null

	var parents: Array[int] = []
	var ranks: Array[int] = []
	parents.resize(vertices.size())
	ranks.resize(vertices.size())
	for vertex_index in vertices.size():
		parents[vertex_index] = vertex_index
	for triangle_index in range(0, indices.size(), 3):
		_join(parents, ranks, indices[triangle_index], indices[triangle_index + 1])
		_join(parents, ranks, indices[triangle_index + 1], indices[triangle_index + 2])

	var component_sums: Dictionary = {}
	var component_counts: Dictionary = {}
	for vertex_index in vertices.size():
		var root := _root(parents, vertex_index)
		component_sums[root] = component_sums.get(root, Vector3.ZERO) + vertices[vertex_index]
		component_counts[root] = int(component_counts.get(root, 0)) + 1
	var band_min := _vector3(config.get("component_centroid_min", []), Vector3(-INF, 0.42, -0.62))
	var band_max := _vector3(config.get("component_centroid_max", []), Vector3(INF, 1.52, 0.32))
	var removed: Dictionary = {}
	for root: int in component_sums:
		var centre: Vector3 = component_sums[root] / float(component_counts[root])
		if centre.x >= band_min.x and centre.x <= band_max.x \
				and centre.y >= band_min.y and centre.y <= band_max.y \
				and centre.z >= band_min.z and centre.z <= band_max.z:
			removed[root] = true

	var kept_indices := PackedInt32Array()
	for triangle_index in range(0, indices.size(), 3):
		if not removed.has(_root(parents, indices[triangle_index])):
			kept_indices.append(indices[triangle_index])
			kept_indices.append(indices[triangle_index + 1])
			kept_indices.append(indices[triangle_index + 2])
	if removed.is_empty() or kept_indices.is_empty() or kept_indices.size() == indices.size():
		push_error("Meadowhart tack-band repair removed no usable source components")
		return null

	var rebuilt_arrays := arrays.duplicate(true)
	rebuilt_arrays[Mesh.ARRAY_INDEX] = kept_indices
	var rebuilt := ArrayMesh.new()
	# The installed GLB has one primitive and no morph targets/LOD extension
	# (held by the focused source contract). Godot 4.7 exposes no
	# surface_get_lods() reconstruction API, so round-trip exactly the arrays it
	# does expose instead of calling a nonexistent compatibility method.
	if source.get_blend_shape_count() != 0:
		push_error("Meadowhart bare-body repair does not accept an unverified morph-target source")
		return null
	rebuilt.add_surface_from_arrays(source.surface_get_primitive_type(0), rebuilt_arrays)
	rebuilt.surface_set_material(0, source.surface_get_material(0))
	rebuilt.surface_set_name(0, source.surface_get_name(0))
	rebuilt.resource_name = "%s_bare" % source.resource_name
	return rebuilt


static func _add_torso_for_fit(art: Node3D, config: Dictionary,
		source_material: Material = null) -> bool:
	var sphere := SphereMesh.new()
	sphere.radius = 0.5
	sphere.height = 1.0
	# A deliberately restrained low-poly contour, matching the faceted source
	# silhouette instead of the smooth featureless oval rejected by R5.
	sphere.radial_segments = 12
	sphere.rings = 6
	var torso := MeshInstance3D.new()
	torso.name = TORSO_NODE
	torso.mesh = sphere
	torso.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	torso.material_override = _torso_material(source_material, config)
	art.add_child(torso)

	var centre := _vector3(config.get("torso_center", []), Vector3(0.0, 0.98, -0.16))
	var half_extents := _vector3(config.get("torso_half_extents", []), Vector3(0.27, 0.34, 0.58))
	if half_extents.x <= 0.0 or half_extents.y <= 0.0 or half_extents.z <= 0.0:
		push_error("Meadowhart bare torso half-extents must be positive")
		return false
	# It begins in imported-model coordinates so creature_body._fit() measures
	# the repaired silhouette.  bind_torso_to_rig() moves this exact transform
	# into the pelvis rest frame afterwards.
	torso.transform = Transform3D(Basis.from_scale(half_extents * 2.0), centre)
	return true


static func _torso_material(source_material: Material, config: Dictionary) -> Material:
	# Reuse a clean, tightly cropped fur region of the installed creature's own
	# atlas, including its matching normal/roughness maps. A flat invented colour
	# made the replacement announce itself as a plastic oval beside the textured
	# neck and haunch. The duplicate is local; source skin stays immutable.
	if source_material is BaseMaterial3D:
		var matched := source_material.duplicate() as BaseMaterial3D
		if matched != null:
			matched.resource_name = "meadowhart_bare_torso_fur"
			matched.albedo_color = Color.WHITE
			matched.uv1_scale = _vector3(config.get("torso_uv1_scale", []),
				Vector3(0.10, 0.10, 1.0))
			matched.uv1_offset = _vector3(config.get("torso_uv1_offset", []),
				Vector3(0.30, 0.66, 0.0))
			matched.roughness = maxf(matched.roughness, 0.78)
			matched.metallic = 0.0
			return matched
	var fallback := StandardMaterial3D.new()
	fallback.resource_name = "meadowhart_bare_torso_fallback"
	fallback.albedo_color = Color(str(config.get("torso_colour", "#ad8048")))
	fallback.roughness = 0.92
	fallback.metallic = 0.0
	return fallback


static func _vector3(raw: Variant, fallback: Vector3) -> Vector3:
	if raw is Array and (raw as Array).size() == 3:
		return Vector3(float(raw[0]), float(raw[1]), float(raw[2]))
	return fallback


static func _to_ancestor(node: Node3D, ancestor: Node3D) -> Transform3D:
	var chain := Transform3D()
	var cursor := node
	while cursor != null and cursor != ancestor:
		chain = cursor.transform * chain
		cursor = cursor.get_parent() as Node3D
	return chain


static func _root(parents: Array[int], vertex_index: int) -> int:
	var root := vertex_index
	while parents[root] != root:
		root = parents[root]
	var cursor := vertex_index
	while parents[cursor] != cursor:
		var next := parents[cursor]
		parents[cursor] = root
		cursor = next
	return root


static func _join(parents: Array[int], ranks: Array[int], left: int, right: int) -> void:
	var left_root := _root(parents, left)
	var right_root := _root(parents, right)
	if left_root == right_root:
		return
	if ranks[left_root] < ranks[right_root]:
		parents[left_root] = right_root
	elif ranks[left_root] > ranks[right_root]:
		parents[right_root] = left_root
	else:
		parents[right_root] = left_root
		ranks[left_root] += 1
