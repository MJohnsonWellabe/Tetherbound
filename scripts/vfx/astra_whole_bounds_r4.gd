extends RefCounted

## Read-only whole-body current-pose bounds, including feet, tail and wings.
## Never use the rest-pose box to place particles over empty folded-wing space.
const RENDER_BOUNDS := preload("res://scripts/characters/render_bounds.gd")
var _pivot: WeakRef
var _surfaces: Array[Dictionary] = []
var _selected_count := 0
var _bone_names: Array[String] = []
var _samples := PackedVector3Array()
var _cached_poses: Array = []
var _frame := -1
var _box := AABB()
var _valid := false
var _invalid_reason := "not_bound"

func bind(pivot: Node3D) -> bool:
	_surfaces.clear()
	_selected_count = 0
	_bone_names.clear()
	_frame = -1
	_box = AABB()
	_valid = false
	_pivot = weakref(pivot)
	for mesh: MeshInstance3D in RENDER_BOUNDS._mesh_instances(pivot):
		if not mesh.is_visible_in_tree() or mesh.skin == null: continue
		var skeleton := RENDER_BOUNDS._skeleton_for(mesh)
		if skeleton == null: continue
		var bind_bones := PackedInt32Array()
		var bind_poses: Array[Transform3D] = []
		for b in mesh.skin.get_bind_count():
			var bone := mesh.skin.get_bind_bone(b)
			if bone < 0: bone = skeleton.find_bone(mesh.skin.get_bind_name(b))
			bind_bones.append(bone if bone < skeleton.get_bone_count() else -1)
			bind_poses.append(mesh.skin.get_bind_pose(b))
		for surface in mesh.mesh.get_surface_count():
			var arrays := mesh.mesh.surface_get_arrays(surface)
			var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
			var bones: Variant = arrays[Mesh.ARRAY_BONES]
			var weights: Variant = arrays[Mesh.ARRAY_WEIGHTS]
			if vertices.is_empty() or bones == null or weights == null: continue
			if bones.size() != weights.size() or bones.size() % vertices.size() != 0: continue
			var stride := int(bones.size() / vertices.size())
			var selected := PackedInt32Array()
			for v in vertices.size(): selected.append(v)
			_selected_count += selected.size()
			if not selected.is_empty():
				_surfaces.append({"skeleton": weakref(skeleton), "mesh": weakref(mesh), "vertices": vertices,
					"bones": bones, "weights": weights, "stride": stride, "selected": selected,
					"bind_bones": bind_bones, "bind_poses": bind_poses})
	measure()
	return _valid

func _invalidate(reason: String) -> AABB:
	_box = AABB()
	_samples.clear()
	_cached_poses.clear()
	_valid = false
	_invalid_reason = reason
	_frame = Engine.get_process_frames()
	return _box

func measure() -> AABB:
	# Check weak references before the frame cache: a source can disappear
	# between two callers in the SAME frame (including host contact confirmation).
	var pivot := _pivot.get_ref() as Node3D if _pivot != null else null
	if not is_instance_valid(pivot): return _invalidate("pivot_missing")
	if pivot.is_queued_for_deletion() or not pivot.is_inside_tree(): return _invalidate("pivot_detached")
	if _surfaces.is_empty(): return _invalidate("no_skinned_surfaces")
	for surface: Dictionary in _surfaces:
		var skeleton := (surface.skeleton as WeakRef).get_ref() as Skeleton3D
		var mesh := (surface.mesh as WeakRef).get_ref() as MeshInstance3D
		if not is_instance_valid(skeleton): return _invalidate("skeleton_missing")
		if skeleton.is_queued_for_deletion() or not pivot.is_ancestor_of(skeleton): return _invalidate("skeleton_detached")
		if not is_instance_valid(mesh): return _invalidate("mesh_missing")
		if mesh.is_queued_for_deletion() or not mesh.is_visible_in_tree() or not pivot.is_ancestor_of(mesh):
			return _invalidate("mesh_detached_or_hidden")
	var frame := Engine.get_process_frames()
	if frame == _frame: return _box
	_frame = frame
	var poses: Array = []
	for surface: Dictionary in _surfaces:
		var skeleton := (surface.skeleton as WeakRef).get_ref() as Skeleton3D
		var to_pivot := RENDER_BOUNDS._chain(skeleton, pivot)
		var binds: Array[Transform3D] = []
		for b in surface.bind_bones.size():
			var bone := int(surface.bind_bones[b])
			binds.append(to_pivot * skeleton.get_bone_global_pose(bone) * surface.bind_poses[b]
				if bone >= 0 else Transform3D.IDENTITY)
		poses.append(binds)
	if _valid and poses == _cached_poses: return _box
	_cached_poses = poses
	_box = AABB()
	_samples.clear()
	_valid = false
	var started := false
	for surface_index in _surfaces.size():
		var surface: Dictionary = _surfaces[surface_index]
		var binds: Array = poses[surface_index]
		for v: int in surface.selected:
			var point := Vector3.ZERO
			var total := 0.0
			for j in int(surface.stride):
				var offset := v * int(surface.stride) + j
				var b := int(surface.bones[offset])
				var weight := float(surface.weights[offset])
				if weight <= 0.0 or b < 0 or b >= binds.size() or int(surface.bind_bones[b]) < 0: continue
				point += (binds[b] * surface.vertices[v]) * weight
				total += weight
			if total <= 0.0: continue
			point /= total
			if not point.is_finite(): return _invalidate("nonfinite_vertex")
			if v % 12 == 0: _samples.append(point)
			_box = _box.expand(point) if started else AABB(point, Vector3.ZERO)
			started = true
	if not started or not _box.size.is_finite() or _box.size.x <= 0.0 or _box.size.y <= 0.0 or _box.size.z <= 0.0:
		return _invalidate("empty_or_degenerate_body")
	_valid = true
	_invalid_reason = ""
	return _box

func receipt() -> Dictionary:
	var box := measure()
	var pivot := _pivot.get_ref() as Node3D if _pivot != null else null
	return {"valid": _valid, "reason": _invalid_reason, "method": "all_vertices_current_skin_pose",
		"selected_vertices": _selected_count, "posed_whole_body_bounds": bounds(box),
		"world_midpoint": vector(pivot.to_global(box.get_center())) if _valid else [],
		"surface_samples": _samples.size()}

func anchors() -> PackedVector3Array:
	measure()
	return _samples if _valid else PackedVector3Array()

static func vector(value: Vector3) -> Array:
	return [value.x, value.y, value.z]

static func bounds(value: AABB) -> Dictionary:
	return {"position": vector(value.position), "size": vector(value.size), "center": vector(value.get_center())}

static func transform(value: Transform3D) -> Dictionary:
	return {"origin": vector(value.origin), "basis_x": vector(value.basis.x),
		"basis_y": vector(value.basis.y), "basis_z": vector(value.basis.z)}
