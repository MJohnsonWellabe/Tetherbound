extends RefCounted

## Turns one `map_reveal:<id>` dialogue effect into personal map knowledge.
## The effect id resolves through one data file so NPC prose never embeds map
## coordinates, alpha species data, or renderer details. The destination is
## still authored by the map/spawn tables and pinned here by focused tests.

const CONFIG_PATH := "res://data/config/meadows_map_reveals.json"
static var _definitions: Dictionary = {}


static func apply(map_state: RefCounted, reveal_id: String) -> bool:
	if map_state == null:
		return false
	var definition := definition(reveal_id)
	if definition.is_empty():
		push_warning("dialogue map reveal '%s' is not authored" % reveal_id)
		return false
	var changed := false
	for region: Variant in definition.get("regions", []):
		changed = bool(map_state.call("discover_region", str(region))) or changed
	for landmark: Variant in definition.get("landmarks", []):
		changed = bool(map_state.call("discover_landmark", str(landmark))) or changed
	for raw: Variant in definition.get("alphas", []):
		if typeof(raw) != TYPE_DICTIONARY:
			continue
		var alpha := raw as Dictionary
		var position_raw: Variant = alpha.get("position", [])
		if typeof(position_raw) != TYPE_ARRAY or (position_raw as Array).size() < 2:
			continue
		var position := position_raw as Array
		changed = bool(map_state.call("pin_alpha",
			int(alpha.get("order", 0)), str(alpha.get("species", "")),
			str(alpha.get("display_name", "")),
			Vector3(float(position[0]), 0.0, float(position[1])),
			str(alpha.get("icon", "")))) or changed
	return changed


static func display_name(reveal_id: String) -> String:
	return str(definition(reveal_id).get("display_name", reveal_id.capitalize()))


static func definition(reveal_id: String) -> Dictionary:
	_ensure_loaded()
	var raw: Variant = _definitions.get(reveal_id, {})
	return raw as Dictionary if typeof(raw) == TYPE_DICTIONARY else {}


static func _ensure_loaded() -> void:
	if not _definitions.is_empty():
		return
	var file := FileAccess.open(CONFIG_PATH, FileAccess.READ)
	if file == null:
		push_error("dialogue map reveal config missing")
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("dialogue map reveal config is invalid")
		return
	var raw: Variant = (parsed as Dictionary).get("reveals", {})
	if typeof(raw) == TYPE_DICTIONARY:
		_definitions = raw as Dictionary
