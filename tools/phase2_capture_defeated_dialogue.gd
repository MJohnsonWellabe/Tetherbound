extends "res://tools/phase2_capture_dialogue.gd"

## Visual-only post-win conversation survey. This uses authored defeated or
## win text in the production panel at the trainer's post. It does not win a
## battle, alter the defeat ledger, or prove an in-world defeated body pose.
const DIALOGUE := preload("res://scripts/story/dialogue_runner.gd")

func _defeated_id(row: Dictionary) -> String:
	var source := str(row.get("authored_source", ""))
	var authored := str(row.get("authored_id", ""))
	if source.is_empty():
		return ""
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://" + source))
	if not parsed is Dictionary:
		return ""
	var config := parsed as Dictionary
	for group: String in ["trainers", "npcs", "characters", "villagers"]:
		for raw: Variant in config.get(group, []):
			if not raw is Dictionary:
				continue
			var spec := raw as Dictionary
			if str(spec.get("id", spec.get("name", ""))) != authored:
				continue
			for field: String in ["defeated", "win_conversation"]:
				if not str(spec.get(field, "")).is_empty():
					return str(spec[field])
			for id: Variant in spec.get("dialogue_ids", []):
				if str(id).contains("defeated") or str(id).contains("victory"):
					return str(id)
			if _biome_id == "stormwood" and group == "trainers":
				return "stormwood_trainer_%s_defeated" % authored
	return ""

func _load_plan() -> bool:
	if not super._load_plan():
		return false
	var selected: Array[Dictionary] = []
	for row: Dictionary in _planned:
		var conversation := _defeated_id(row)
		if conversation.is_empty():
			continue
		row["defeated_dialogue_id"] = conversation
		row["frame_id"] = str(row.frame_id) + "__defeated"
		selected.append(row)
	_planned = selected
	return not _planned.is_empty()

func _dialogue_for(row: Dictionary) -> String:
	var conversation := str(row.get("defeated_dialogue_id", ""))
	return conversation if DIALOGUE.table().has(conversation) else ""

func _begin_manifest() -> void:
	super._begin_manifest()
	_manifest["defeated_fixture"] = "Authored post-win text opened in production DialoguePanel at the trainer post. No battle was won and no defeat flag was changed; world-body aftermath remains a separate capture."
