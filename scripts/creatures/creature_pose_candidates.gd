extends RefCounted

## F36 review candidates. This creates instance-local clips from measured rig
## names without changing installed GLBs or durable character/world state.
## The owner enabled the installed-roster poses for Phase 1 (2026-10-10).
## Visual acceptance is separate; recipes still refuse a mismatched model/rig.
const PATH := "res://data/creatures/f36_pose_candidates.json"
const LIBRARY := &"f36_candidate"
const BOUNDS := preload("res://scripts/characters/render_bounds.gd")
static var _data: Dictionary = {}
static var _hashes: Dictionary = {}
static var _contact_heights: Dictionary = {}


static func install(body: Node3D, model: Node3D, player: AnimationPlayer,
		look: Dictionary, original: Dictionary, presentation_species: String = "") -> Dictionary:
	if _data.is_empty():
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(PATH))
		if parsed is Dictionary:
			_data = parsed
	var id := presentation_species if not presentation_species.is_empty() else str(body.get("species_id"))
	id = id.trim_prefix("water_")
	if id not in _data.get("enabled_species", []) and not bool(body.get_meta("f36_pose_preview", false)):
		return original
	var rows: Dictionary = _data.get("species", {})
	var recipe: Dictionary = rows.get(id, {})
	var model_path := str(look.get("model", ""))
	if recipe.is_empty() or model_path != str(recipe.get("model", "")):
		return original
	# Exported GLBs are imported PackedScenes, and their raw source bytes need
	# not exist in the PCK. Keep the source hash check where bytes are present;
	# packaged scenes retain the same model-path and skeleton validation below.
	if FileAccess.file_exists(model_path):
		if not _hashes.has(model_path):
			_hashes[model_path] = FileAccess.get_sha256(model_path)
		if str(_hashes[model_path]) != str(recipe.get("source_sha256", "")):
			push_warning("F36 pose recipe stale for %s; preserving installed clips" % id)
			return original
	elif not ResourceLoader.exists(model_path):
		return original
	var skeletons := model.find_children("*", "Skeleton3D", true, false)
	if skeletons.size() != 1:
		return original
	var skeleton := skeletons[0] as Skeleton3D
	for bone: String in recipe.get("bones", []):
		if skeleton.find_bone(bone) < 0:
			push_warning("F36 pose recipe missing bone %s for %s" % [bone, id])
			return original
	if not FileAccess.file_exists(model_path) and not _packaged_rig_matches(model, skeleton, recipe):
		push_warning("F36 packaged rig contract stale for %s; preserving installed clips" % id)
		return original
	var animation_root := player.get_node_or_null(player.root_node)
	if animation_root == null:
		return original
	var skeleton_path := str(animation_root.get_path_to(skeleton))
	var pivot_path := animation_root.get_path_to(model)
	var pivot_before := model.transform
	var box := BOUNDS.measure(model)
	var contact_key := "%s:%s:%s:%s" % [recipe.source_sha256, recipe.profile,
		pivot_before.basis, BOUNDS._chain(skeleton, model)]
	var surfaces: Array[Dictionary] = []
	if not _contact_heights.has(contact_key):
		for mesh: MeshInstance3D in BOUNDS._mesh_instances(model):
			if mesh.skin == null or BOUNDS._skeleton_for(mesh) != skeleton:
				continue
			for surface in mesh.mesh.get_surface_count():
				var arrays := mesh.mesh.surface_get_arrays(surface)
				surfaces.append({"skin": mesh.skin, "vertices": arrays[Mesh.ARRAY_VERTEX],
					"bones": arrays[Mesh.ARRAY_BONES], "weights": arrays[Mesh.ARRAY_WEIGHTS]})
		_contact_heights[contact_key] = {}
	var contacts: Dictionary = _contact_heights[contact_key]
	var library := AnimationLibrary.new()
	var clips := original.duplicate(true)
	var profiles: Dictionary = _data.get("profiles", {})
	var roles: Dictionary = profiles.get(str(recipe.get("profile", "")), {})
	for role: String in roles:
		var spec: Dictionary = roles[role]
		var animation := Animation.new()
		animation.length = float(spec.duration_s)
		animation.loop_mode = Animation.LOOP_LINEAR if bool(spec.loop) else Animation.LOOP_NONE
		for bone: String in recipe.bones:
			var track := animation.add_track(Animation.TYPE_ROTATION_3D)
			var bone_path := NodePath("%s:%s" % [skeleton_path, bone])
			animation.track_set_path(track, bone_path)
			var rest_transform := skeleton.get_bone_rest(skeleton.find_bone(bone))
			var rest := rest_transform.basis.get_rotation_quaternion()
			# Installed locomotion can animate root translation/scale. Pin the
			# recipe to its measured rest hierarchy rather than inherit a bob.
			var bone_position := animation.add_track(Animation.TYPE_POSITION_3D)
			animation.track_set_path(bone_position, bone_path)
			animation.position_track_insert_key(bone_position, 0.0, rest_transform.origin)
			animation.position_track_insert_key(bone_position, animation.length, rest_transform.origin)
			var bone_scale := animation.add_track(Animation.TYPE_SCALE_3D)
			animation.track_set_path(bone_scale, bone_path)
			animation.scale_track_insert_key(bone_scale, 0.0, rest_transform.basis.get_scale())
			animation.scale_track_insert_key(bone_scale, animation.length, rest_transform.basis.get_scale())
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
			if role in ["faint", "hit", "ride"]:
				# The standing AABB includes unfolded legs/wings. Ground the
				# actual skinned pose instead, without changing mesh or collision.
				var sample := "%s:%s" % [role, frame.phase]
				if not contacts.has(sample):
					var minimum := _posed_minimum_y(skeleton, model, surfaces, frame.bones, rolled)
					contacts[sample] = minimum if is_finite(minimum) else \
						(Transform3D(rolled, Vector3.ZERO) * box).position.y
				position.y = -float(contacts[sample])
			var time := float(frame.phase) * animation.length
			animation.rotation_track_insert_key(rotation_track, time, rolled.get_rotation_quaternion())
			animation.position_track_insert_key(position_track, time, position)
		library.add_animation(StringName(role), animation)
		clips[role] = "%s/%s" % [LIBRARY, role]
		if role == "hit":
			clips["hit_start_phase"] = float(spec.get("start_phase", 0.0))
			clips["hit_release_phase"] = float(spec.get("release_phase", spec.get("start_phase", 0.0)))
	if player.has_animation_library(LIBRARY):
		player.remove_animation_library(LIBRARY)
	player.add_animation_library(LIBRARY, library)
	body.set_meta("f36_pose_candidate_installed", true)
	return clips


## Imported resources have a stable UID and preserve the measured skeleton
## rest hierarchy and skin binds even when the exporter omits raw GLB bytes.
static func _packaged_rig_matches(model: Node3D, skeleton: Skeleton3D, recipe: Dictionary) -> bool:
	var uid := str(recipe.get("resource_uid", ""))
	if uid.is_empty() or ResourceLoader.get_resource_uid(str(recipe.model)) != ResourceUID.text_to_id(uid):
		return false
	var bones: Dictionary = recipe.get("rig_contract", {})
	var binds: Dictionary = recipe.get("bind_contract", {})
	if bones.size() != skeleton.get_bone_count() or binds.is_empty():
		return false
	for name: String in bones:
		var bone := skeleton.find_bone(name)
		if bone < 0:
			return false
		var parent := skeleton.get_bone_parent(bone)
		var parent_name := str(skeleton.get_bone_name(parent)) if parent >= 0 else ""
		var contract: Dictionary = bones[name]
		if parent_name != str(contract.parent) or not _transform_matches(skeleton.get_bone_rest(bone), contract.rest):
			return false
	var seen := {}
	for mesh: MeshInstance3D in BOUNDS._mesh_instances(model):
		if mesh.skin == null or BOUNDS._skeleton_for(mesh) != skeleton:
			continue
		var skin := mesh.skin
		if skin.get_bind_count() != binds.size():
			return false
		for bind in skin.get_bind_count():
			var bone := skin.get_bind_bone(bind)
			if bone >= skeleton.get_bone_count():
				return false
			var name := str(skin.get_bind_name(bind)) if bone < 0 else str(skeleton.get_bone_name(bone))
			if not binds.has(name) or not _transform_matches(skin.get_bind_pose(bind), binds[name]):
				return false
			seen[name] = true
	return seen.size() == binds.size()


static func _transform_matches(transform: Transform3D, column_major: Array) -> bool:
	if column_major.size() != 16:
		return false
	var columns := [transform.basis.x, transform.basis.y, transform.basis.z, transform.origin]
	var tolerance := float(_data.get("rig_tolerance", 0.0001))
	for column in 4:
		var actual: Vector3 = columns[column]
		for row in 3:
			if absf(actual[row] - float(column_major[column * 4 + row])) > tolerance:
				return false
	return true


## Bake the collapse's contact once per source/profile/fitted basis. This
## follows the renderer's skin transform, including named and eight-weight
## binds, while leaving the live skeleton's current animation untouched.
static func _posed_minimum_y(skeleton: Skeleton3D, model: Node3D,
		surfaces: Array[Dictionary], rotations: Dictionary, rolled: Basis) -> float:
	var poses: Array[Transform3D] = []
	poses.resize(skeleton.get_bone_count())
	for bone in skeleton.get_bone_count():
		var pose := skeleton.get_bone_rest(bone)
		var degrees: Array = rotations.get(str(skeleton.get_bone_name(bone)), [0, 0, 0])
		var delta := Quaternion.from_euler(Vector3(float(degrees[0]), float(degrees[1]),
			float(degrees[2])) * PI / 180.0)
		var scale := pose.basis.get_scale()
		pose.basis = Basis(pose.basis.get_rotation_quaternion() * delta)
		pose.basis.x *= scale.x
		pose.basis.y *= scale.y
		pose.basis.z *= scale.z
		poses[bone] = pose
	# Skeleton indices need not be parent-first. Compose each parent chain.
	var global_poses: Array[Transform3D] = []
	for bone in skeleton.get_bone_count():
		var pose := poses[bone]
		var parent := skeleton.get_bone_parent(bone)
		while parent >= 0:
			pose = poses[parent] * pose
			parent = skeleton.get_bone_parent(parent)
		global_poses.append(pose)
	var to_model := BOUNDS._chain(skeleton, model)
	var minimum := INF
	for surface: Dictionary in surfaces:
		var vertices: PackedVector3Array = surface.vertices
		var bones: Variant = surface.bones
		var weights: Variant = surface.weights
		if vertices.is_empty() or bones == null or weights == null \
				or bones.size() != weights.size() or bones.size() % vertices.size() != 0:
			continue
		var skin := surface.skin as Skin
		var binds: Array[Transform3D] = []
		var valid_binds: Array[bool] = []
		for bind in skin.get_bind_count():
			var bone := skin.get_bind_bone(bind)
			if bone < 0:
				bone = skeleton.find_bone(skin.get_bind_name(bind))
			var valid := bone >= 0 and bone < global_poses.size()
			valid_binds.append(valid)
			binds.append(to_model * global_poses[bone] * skin.get_bind_pose(bind) if valid else Transform3D.IDENTITY)
		var stride := int(bones.size() / vertices.size())
		for vertex in vertices.size():
			var point := Vector3.ZERO
			var total := 0.0
			for influence in stride:
				var offset := vertex * stride + influence
				var weight := float(weights[offset])
				var bind := int(bones[offset])
				if weight <= 0.0 or bind < 0 or bind >= binds.size() or not valid_binds[bind]:
					continue
				point += (binds[bind] * vertices[vertex]) * weight
				total += weight
			if total > 0.0:
				minimum = minf(minimum, (rolled * (point / total)).y)
	return minimum
