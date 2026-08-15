extends RefCounted

## Named TM definitions, read once from data/moves/tms.json (R4.4).
##
## Same shape as move_db.gd/trait_db.gd on purpose: a TM id names a move to
## teach and which species types may learn it, and nothing else re-parses
## the JSON. Unknown ids do NOT throw -- see move_db.gd's own header for why.

const TMS_PATH := "res://data/moves/tms.json"

var _tms: Dictionary = {}


func _init(tms_path: String = TMS_PATH) -> void:
	_tms = _read(tms_path).get("tms", {})


static func load_default() -> RefCounted:
	return (load("res://scripts/creatures/tm_db.gd") as GDScript).new()


func _read(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("TM data missing: %s" % path)
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("TM data is not a JSON object: %s" % path)
		return {}
	return parsed as Dictionary


func has(id: String) -> bool:
	return _tms.has(id)


func tm_ids() -> Array:
	return _tms.keys()


func tm(id: String) -> Dictionary:
	var value: Variant = _tms.get(id, {})
	return value as Dictionary if typeof(value) == TYPE_DICTIONARY else {}


func display_name(id: String) -> String:
	return str(tm(id).get("display_name", id))


func move_id(id: String) -> String:
	return str(tm(id).get("move_id", ""))


func compatible_types(id: String) -> Array:
	var value: Variant = tm(id).get("compatible_types", [])
	return value as Array if typeof(value) == TYPE_ARRAY else []


func is_compatible(id: String, creature_type: String) -> bool:
	return compatible_types(id).has(creature_type)


func colour(id: String) -> Color:
	return Color(str(tm(id).get("colour", "#888888")))
