extends RefCounted

const CHARACTER := preload("res://scripts/save/character_save.gd")

## Compare the production reader's copied character with the live save projection.
## This proves persisted owner state, not a successful new write or a reconnect.
static func error(saved: Dictionary, expected: Dictionary, character_id: String) -> String:
	if character_id.is_empty() or saved.get("character_id") != character_id:
		return "Copied save has no readable character for this owner"
	var fields: Array[String] = CHARACTER.STATE_KEYS.duplicate()
	fields.append_array(["realm", "flags"])
	for field: String in fields:
		if not saved.has(field) or not expected.has(field):
			return "Copied character lacks " + field
		if saved[field] != expected[field]:
			return "Copied character differs from current owner: " + field
	return ""
