extends SkeletonModifier3D

## P2-050 (UIPOSES lane, 1 Nov 2026): flag-off role stances for posted NPCs.
## GPU item score 28 Oct 5.88: "Oskar, Halda and Lark all stand in the same
## arms-down idle with no role prop or gesture". data/config/npc_post_stances.json
## names a stance per villager; this modifier layers that stance's per-bone
## euler offsets (degrees, bone-local) over the playing idle each frame, so
## breathing and weight shifts still show. Presentation only: no collider,
## dialogue, prompt or save change.
const CONFIG_PATH := "res://data/config/npc_post_stances.json"
static var _config: Dictionary = {}

var offsets: Array = []  # [[bone_name, x, y, z], ...]
var _indices: Array[int] = []


static func config() -> Dictionary:
	if _config.is_empty():
		var raw: Variant = JSON.parse_string(FileAccess.get_file_as_string(CONFIG_PATH))
		_config = raw if raw is Dictionary else {"enabled": false}
	return _config


## The offsets for a named NPC, or [] when the flag is off or it has no stance.
static func stance_for(npc_name: String, cfg: Dictionary = {}) -> Array:
	var source := cfg if not cfg.is_empty() else config()
	if not bool(source.get("enabled", false)):
		return []
	var stance := str((source.get("npcs", {}) as Dictionary).get(npc_name.to_lower(), ""))
	var rows: Variant = (source.get("stances", {}) as Dictionary).get(stance, [])
	return rows if rows is Array else []


## Attach under the NPC's one skeleton when it has a stance. Returns the
## modifier or null.
static func attach(npc: Node, npc_name: String) -> Node:
	var rows := stance_for(npc_name)
	if rows.is_empty() or npc == null:
		return null
	var skeletons := npc.find_children("*", "Skeleton3D", true, false)
	if skeletons.size() != 1:
		return null
	var modifier: SkeletonModifier3D = new()
	modifier.name = "PostStance"
	modifier.set("offsets", rows)
	(skeletons[0] as Skeleton3D).add_child(modifier)
	return modifier


func _process_modification() -> void:
	var skeleton := get_skeleton()
	if skeleton == null:
		return
	if _indices.size() != offsets.size():
		_indices.clear()
		for row: Array in offsets:
			_indices.append(skeleton.find_bone(str(row[0])))
	for i in offsets.size():
		var bone := _indices[i]
		if bone < 0:
			continue
		var row: Array = offsets[i]
		var delta := Quaternion.from_euler(Vector3(float(row[1]), float(row[2]), float(row[3])) * PI / 180.0)
		skeleton.set_bone_pose_rotation(bone, skeleton.get_bone_pose_rotation(bone) * delta)
