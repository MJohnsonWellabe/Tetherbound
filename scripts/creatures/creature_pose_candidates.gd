extends RefCounted

## F36 review candidates. This creates instance-local clips from measured rig
## names without changing installed GLBs or durable character/world state.
## Only a code-blind PASS may add a species to enabled_species. Capture tools
## can preview an explicitly named body; ordinary gameplay cannot opt itself in.
const PATH := "res://data/creatures/f36_pose_candidates.json"
const LIBRARY := &"f36_candidate"
const BOUNDS := preload("res://scripts/characters/render_bounds.gd")
static var _data: Dictionary = {}
static var _hashes: Dictionary = {}


static func install(body: Node3D, model: Node3D, player: AnimationPlayer,
		look: Dictionary, original: Dictionary) -> Dictionary:
	if _data.is_empty():
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(PATH))
		if parsed is Dictionary:
			_data = parsed
	var id := str(body.get("species_id")).trim_prefix("water_")
	if id not in _data.get("enabled_species", []) and not bool(body.get_meta("f36_pose_preview", false)):
		return original
	var rows: Dictionary = _data.get("species", {})
	var recipe: Dictionary = rows.get(id, {})
	var model_path := str(look.get("model", ""))
	if recipe.is_empty() or model_path != str(recipe.get("model", "")):
		return original
	if not _hashes.has(model_path):
		_hashes[model_path] = FileAccess.get_sha256(model_path)
	if str(_hashes[model_path]) != str(recipe.get("source_sha256", "")):
		push_warning("F36 pose recipe stale for %s; preserving installed clips" % id)
		return original
	var skeletons := model.find_children("*", "Skeleton3D", true, false)
	if skeletons.size() != 1:
		return original
	var skeleton := skeletons[0] as Skeleton3D
	for bone: String in recipe.get("bones", []):
		if skeleton.find_bone(bone) < 0:
			push_warning("F36 pose recipe missing bone %s for %s" % [bone, id])
			return original
	var animation_root := player.get_node_or_null(player.root_node)
	if animation_root == null:
		return original
	var skeleton_path := str(animation_root.get_path_to(skeleton))
	var pivot_path := animation_root.get_path_to(model)
	var pivot_before := model.transform
	var box := BOUNDS.measure(model)
	var library := AnimationLibrary.new()
	var clips := original.duplicate(true)
	var profiles: Dictionary = _data.get("profiles", {})
	var roles: Dictionary = profiles.get(str(recipe.get("profile", "")), {})
	var rotations_before: Array[Quaternion] = []
	for bone_index in skeleton.get_bone_count():
		rotations_before.append(skeleton.get_bone_pose_rotation(bone_index))
	for role: String in roles:
		var spec: Dictionary = roles[role]
		var animation := Animation.new()
		animation.length = float(spec.duration_s)
		animation.loop_mode = Animation.LOOP_LINEAR if bool(spec.loop) else Animation.LOOP_NONE
		for bone: String in recipe.bones:
			var track := animation.add_track(Animation.TYPE_ROTATION_3D)
			animation.track_set_path(track, NodePath("%s:%s" % [skeleton_path, bone]))
			var rest := skeleton.get_bone_rest(skeleton.find_bone(bone)).basis.get_rotation_quaternion()
			for frame: Dictionary in spec.frames:
				var degrees: Array = frame.bones[bone]
				var delta := Quaternion.from_euler(Vector3(float(degrees[0]), float(degrees[1]), float(degrees[2])) * PI / 180.0)
				animation.rotation_track_insert_key(track, float(frame.phase) * animation.length, (rest * delta).normalized())
		var rotation_track := animation.add_track(Animation.TYPE_ROTATION_3D)
		animation.track_set_path(rotation_track, pivot_path)
		var position_track := animation.add_track(Animation.TYPE_POSITION_3D)
		animation.track_set_path(position_track, pivot_path)
		for frame: Dictionary in spec.frames:
			var rolled := pivot_before.basis * Basis(Vector3.BACK, deg_to_rad(float(frame.pivot_roll_deg)))
			var position := pivot_before.origin
			if role == "faint":
				# The fitted bind envelope leaves folded bodies hovering. Sample
				# the actual skin at this key, then translate without rescaling.
				for bone: String in recipe.bones:
					var bone_index := skeleton.find_bone(bone)
					var degrees: Array = frame.bones[bone]
					var delta := Quaternion.from_euler(Vector3(float(degrees[0]), float(degrees[1]), float(degrees[2])) * PI / 180.0)
					var rest := skeleton.get_bone_rest(bone_index).basis.get_rotation_quaternion()
					skeleton.set_bone_pose_rotation(bone_index, (rest * delta).normalized())
				skeleton.force_update_all_bone_transforms()
				var lowest := _posed_lowest_y(model, skeleton, rolled)
				position.y = -lowest if is_finite(lowest) else -(Transform3D(rolled, Vector3.ZERO) * box).position.y
			var time := float(frame.phase) * animation.length
			animation.rotation_track_insert_key(rotation_track, time, rolled.get_rotation_quaternion())
			animation.position_track_insert_key(position_track, time, position)
		library.add_animation(StringName(role), animation)
		clips[role] = "%s/%s" % [LIBRARY, role]
	for bone_index in rotations_before.size():
		skeleton.set_bone_pose_rotation(bone_index, rotations_before[bone_index])
	skeleton.force_update_all_bone_transforms()
	if player.has_animation_library(LIBRARY):
		player.remove_animation_library(LIBRARY)
	player.add_animation_library(LIBRARY, library)
	body.set_meta("f36_pose_candidate_installed", true)
	return clips


static func _posed_lowest_y(model: Node3D, skeleton: Skeleton3D, root_basis: Basis) -> float:
	var lowest := INF
	var root_pose := Transform3D(root_basis, Vector3.ZERO)
	for raw: Node in model.find_children("*", "MeshInstance3D", true, false):
		var mesh := raw as MeshInstance3D
		if mesh.mesh == null or not mesh.visible:
			continue
		var skin := mesh.skin
		var palette: Array[Transform3D] = []
		if skin != null and BOUNDS._skeleton_for(mesh) == skeleton:
			for bind_index in skin.get_bind_count():
				var bone := skin.get_bind_bone(bind_index)
				if bone < 0:
					bone = skeleton.find_bone(skin.get_bind_name(bind_index))
				palette.append(skeleton.get_bone_global_pose(bone) * skin.get_bind_pose(bind_index)
					if bone >= 0 and bone < skeleton.get_bone_count() else Transform3D.IDENTITY)
		var skin_pose := root_pose * BOUNDS._chain(skeleton, model)
		var plain_pose := root_pose * BOUNDS._render_transform(mesh, model)
		for surface in mesh.mesh.get_surface_count():
			var arrays := mesh.mesh.surface_get_arrays(surface)
			var vertices := arrays[Mesh.ARRAY_VERTEX] as PackedVector3Array
			var bones: Variant = arrays[Mesh.ARRAY_BONES]
			var weights: Variant = arrays[Mesh.ARRAY_WEIGHTS]
			var weighted: bool = not palette.is_empty() and bones is PackedInt32Array \
				and weights is PackedFloat32Array and not vertices.is_empty() \
				and bones.size() == weights.size() and bones.size() % vertices.size() == 0
			var stride := int(bones.size() / vertices.size()) if weighted else 0
			for index in vertices.size():
				var posed := Vector3.ZERO
				var total := 0.0
				for influence in stride:
					var offset := index * stride + influence
					var bind_index := int(bones[offset])
					var weight := float(weights[offset])
					if weight > 0.0 and bind_index >= 0 and bind_index < palette.size():
						posed += (palette[bind_index] * vertices[index]) * weight
						total += weight
				var at := skin_pose * (posed / total) if total > 0.0 else plain_pose * vertices[index]
				lowest = minf(lowest, at.y)
	return lowest
