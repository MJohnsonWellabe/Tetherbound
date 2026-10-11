extends RefCounted

## Authored upper-body idle variants on the installed humanoid animation.
## Only NPCs opt in. Feet/root motion, breathing, clothing and accessories stay
## on their own rig; walking, throwing and defeat clips retain their key poses.
const CONFIG_PATH := "res://data/config/npc_postures.json"
const LIBRARY := "npc_posture"
static var _config: Dictionary = {}


static func install(body: Node3D, cfg: Dictionary, idle: String) -> String:
	var data := config()
	var model := str(cfg.get("model", "")).get_file().get_basename()
	var names: Dictionary = data.get("by_name", {})
	var models: Dictionary = data.get("by_model", {})
	var role := str(names.get(str(body.name), models.get(model, "")))
	var profiles: Dictionary = data.get("profiles", {})
	if role.is_empty() or not profiles.has(role):
		return idle
	var player: AnimationPlayer = body.call("animation_player") as AnimationPlayer
	if player == null or not player.has_animation(idle):
		return idle
	var root := player.get_node_or_null(player.root_node)
	if root == null:
		return idle
	var source := player.get_animation(idle)
	var rotations: Dictionary = profiles[role]
	var tracks: Dictionary = {}
	for track: int in range(source.get_track_count()):
		if source.track_get_type(track) != Animation.TYPE_ROTATION_3D:
			continue
		var path := source.track_get_path(track)
		var bone := str(path.get_concatenated_subnames())
		if not rotations.has(bone):
			continue
		var skeleton := root.get_node_or_null(NodePath(path.get_concatenated_names())) as Skeleton3D
		if skeleton != null and skeleton.find_bone(bone) >= 0 and source.track_get_key_count(track) > 0:
			tracks[bone] = track
	# Never apply a partial pose to a replacement skeleton. Its neutral idle is
	# the safe fallback until a matching role is authored for the new rig.
	if tracks.size() != rotations.size():
		push_warning("NPC posture '%s' does not match %s's installed idle tracks" % [role, body.name])
		return idle
	var posed := source.duplicate(true) as Animation
	posed.resource_name = "%s_%s" % [LIBRARY, role]
	posed.loop_mode = Animation.LOOP_LINEAR
	for bone: String in rotations:
		var degrees: Array = rotations[bone]
		var radians := Vector3(deg_to_rad(float(degrees[0])), deg_to_rad(float(degrees[1])), deg_to_rad(float(degrees[2])))
		var offset := Basis.from_euler(radians, EULER_ORDER_XYZ).get_rotation_quaternion()
		var track: int = tracks[bone]
		for key: int in range(posed.track_get_key_count(track)):
			var rotation: Quaternion = posed.track_get_key_value(track, key)
			# Same bone-local XYZ frame as animate_humanoid.py's authored idle;
			# post-multiply so the rest/bind orientation is never replaced.
			posed.track_set_key_value(track, key, (rotation * offset).normalized())
	var library := AnimationLibrary.new()
	library.add_animation("idle", posed)
	if player.has_animation_library(LIBRARY):
		player.remove_animation_library(LIBRARY)
	player.add_animation_library(LIBRARY, library)
	return LIBRARY + "/idle"


static func config() -> Dictionary:
	if not _config.is_empty():
		return _config
	var file := FileAccess.open(CONFIG_PATH, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if parsed is Dictionary:
		_config = parsed
	return _config
