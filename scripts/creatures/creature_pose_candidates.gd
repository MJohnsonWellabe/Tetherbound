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
				# Ground the rolled fitted envelope, rather than lifting by the
				# gameplay radius (which ignores long/wide imported silhouettes).
				# Native posed-vertex/slope contact remains a required visual proof.
				var rolled_box := Transform3D(rolled, Vector3.ZERO) * box
				position.y = -rolled_box.position.y
			var time := float(frame.phase) * animation.length
			animation.rotation_track_insert_key(rotation_track, time, rolled.get_rotation_quaternion())
			animation.position_track_insert_key(position_track, time, position)
		library.add_animation(StringName(role), animation)
		clips[role] = "%s/%s" % [LIBRARY, role]
	if player.has_animation_library(LIBRARY):
		player.remove_animation_library(LIBRARY)
	player.add_animation_library(LIBRARY, library)
	body.set_meta("f36_pose_candidate_installed", true)
	return clips
