extends RefCounted

## Persistent, data-driven Realm Heart selection.
##
## Earning and placing a Heart are durable story facts, so they live in the
## existing progression flag store.  The one piece that is not a set of facts
## is the player's current choice: exactly one Heart power may be active.  This
## small composed state object owns that selection and nothing scene-specific.

const CONFIG_PATH := "res://data/config/realm_hearts.json"

var revision: int = 0
var _config: Dictionary = {}
var _active_id: String = ""


func _init(config_override: Dictionary = {}) -> void:
	_config = config_override.duplicate(true) if not config_override.is_empty() else _read_config()


func heart(id: String) -> Dictionary:
	var hearts: Variant = _config.get("hearts", {})
	if not hearts is Dictionary:
		return {}
	var raw: Variant = (hearts as Dictionary).get(id, {})
	return (raw as Dictionary).duplicate(true) if raw is Dictionary else {}


func realm(id: String) -> Dictionary:
	var realms: Variant = _config.get("realms", {})
	if not realms is Dictionary:
		return {}
	var raw: Variant = (realms as Dictionary).get(id, {})
	return (raw as Dictionary).duplicate(true) if raw is Dictionary else {}


func scene_for_realm(id: String) -> String:
	return str(realm(id).get("scene", ""))


func entry_key_for_realm(id: String) -> String:
	return str(realm(id).get("entry_key_flag", ""))


func is_earned(id: String, progression: RefCounted) -> bool:
	return _has_story_flag(progression, str(heart(id).get("earned_flag", "")))


func is_placed(id: String, progression: RefCounted) -> bool:
	return _has_story_flag(progression, str(heart(id).get("placed_flag", "")))


func place(id: String, progression: RefCounted) -> bool:
	var spec := heart(id)
	if spec.is_empty() or not is_earned(id, progression):
		return false
	var flag := str(spec.get("placed_flag", ""))
	if flag == "" or progression == null:
		return false
	progression.call("set_flag", flag)
	return true


## Equip one placed Heart.  Assigning the id replaces the old selection in one
## write, so there is no frame in which two realm powers can both be active.
func activate(id: String, progression: RefCounted) -> bool:
	if not is_placed(id, progression):
		return false
	if _active_id == id:
		return true
	_active_id = id
	revision += 1
	return true


func clear_active() -> void:
	if _active_id == "":
		return
	_active_id = ""
	revision += 1


func active_id() -> String:
	return _active_id


func active_power() -> Dictionary:
	if _active_id == "":
		return {}
	var raw: Variant = heart(_active_id).get("power", {})
	return (raw as Dictionary).duplicate(true) if raw is Dictionary else {}


func stamina_capacity_multiplier() -> float:
	return maxf(1.0, float(active_power().get("max_stamina_multiplier", 1.0)))


func save_data() -> Dictionary:
	return {"active_id": _active_id}


## Unknown, malformed, or no-longer-placed selections load inactive.  A save
## must never manufacture a power that its story flags do not support.
func load_data(data: Dictionary, progression: RefCounted = null) -> void:
	var candidate := str(data.get("active_id", ""))
	if candidate != "" and heart(candidate).is_empty():
		candidate = ""
	if candidate != "" and progression != null and not is_placed(candidate, progression):
		candidate = ""
	_active_id = candidate
	revision += 1


func _has_story_flag(progression: RefCounted, flag: String) -> bool:
	return progression != null and flag != "" and bool(progression.call("has", flag))


func _read_config() -> Dictionary:
	var file := FileAccess.open(CONFIG_PATH, FileAccess.READ)
	if file == null:
		push_error("realm Heart config missing: %s" % CONFIG_PATH)
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		push_error("realm Heart config is not valid JSON: %s" % CONFIG_PATH)
		return {}
	return parsed as Dictionary
