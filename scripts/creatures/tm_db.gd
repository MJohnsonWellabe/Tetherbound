extends RefCounted

## Named TM definitions, read once from data/moves/tms.json (R4.4).
##
## Same shape as move_db.gd/trait_db.gd on purpose: a TM id names a move to
## teach and which species types may learn it, and nothing else re-parses
## the JSON. Unknown ids do NOT throw -- see move_db.gd's own header for why.

const TMS_PATH := "res://data/moves/tms.json"

var _tms: Dictionary = {}


func _init(tms_path: String = TMS_PATH, cached_tms: Variant = null) -> void:
	if cached_tms is Dictionary:
		_tms = cached_tms
	else:
		_tms = _read(tms_path).get("tms", {})


## One parsed table per process, re-read only when the file changes (see
## move_db.gd::load_default). Read-only for callers: accessors hand out copies.
## Keep parsed data alive without retaining an instance of this same script.
## Live callers still share one facade; a released facade can be recreated
## from the cached table without reparsing during party/save validation.
static var _shared: WeakRef = null
static var _shared_tms: Dictionary = {}
static var _shared_stamp := ""


static func load_default() -> RefCounted:
	# Modified time and size: a test writing a temporary table within the same
	# second still reloads.
	var stamp := "%d:%d" % [FileAccess.get_modified_time(TMS_PATH), FileAccess.get_size(TMS_PATH)]
	var shared: RefCounted = _shared.get_ref() if _shared != null else null
	if shared != null and stamp == _shared_stamp:
		return shared
	if stamp != _shared_stamp:
		shared = (load("res://scripts/creatures/tm_db.gd") as GDScript).new()
		_shared_tms = shared.get("_tms")
		_shared_stamp = stamp
	else:
		shared = (load("res://scripts/creatures/tm_db.gd") as GDScript).new(TMS_PATH, _shared_tms)
	_shared = weakref(shared)
	return shared


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


## A copy: the table behind `load_default()` is shared by every caller.
func tm(id: String) -> Dictionary:
	return _tm(id).duplicate(true)


func _tm(id: String) -> Dictionary:
	var value: Variant = _tms.get(id, {})
	return value as Dictionary if typeof(value) == TYPE_DICTIONARY else {}


func display_name(id: String) -> String:
	return str(_tm(id).get("display_name", id))


func move_id(id: String) -> String:
	return str(_tm(id).get("move_id", ""))


func compatible_types(id: String) -> Array:
	return _compatible_types(id).duplicate()


func _compatible_types(id: String) -> Array:
	var value: Variant = _tm(id).get("compatible_types", [])
	return value as Array if typeof(value) == TYPE_ARRAY else []


func is_compatible(id: String, creature_type: String) -> bool:
	return _compatible_types(id).has(creature_type)


func colour(id: String) -> Color:
	return Color(str(_tm(id).get("colour", "#888888")))
