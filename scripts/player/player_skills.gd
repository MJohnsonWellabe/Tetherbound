extends RefCounted

const CONFIG_PATH := "res://data/config/player_skills.json"
const IDS := ["running", "catching", "riding", "swimming", "flying"]

var revealed: bool = false
var revision: int = 0
var _config: Dictionary
var _levels: Dictionary = {}
var _xp: Dictionary = {}


func _init(config: Dictionary = {}) -> void:
	_config = config.duplicate(true) if not config.is_empty() else JSON.parse_string(FileAccess.get_file_as_string(CONFIG_PATH))
	for id: String in IDS:
		_levels[id] = 0
		_xp[id] = 0.0


func level(id: String) -> int:
	return int(_levels.get(id, 0))


func cap() -> int:
	return int(_config.level_cap)


func xp_needed(at_level: int) -> float:
	return float(_config.xp_base) + float(_config.xp_per_level) * at_level


func fraction(id: String) -> float:
	return float(_xp.get(id, 0.0)) / xp_needed(level(id)) if level(id) < cap() else 0.0


func add_xp(id: String, amount: float) -> bool:
	if not IDS.has(id) or not is_finite(amount) or amount <= 0.0 or level(id) >= cap():
		return false
	_xp[id] += amount
	while level(id) < cap() and float(_xp[id]) >= xp_needed(level(id)):
		_xp[id] -= xp_needed(level(id))
		_levels[id] += 1
	if level(id) == cap():
		_xp[id] = 0.0
	revision += 1
	return true


func enter_realm(realm: String) -> void:
	if not revealed and _config.reveal_realms.has(realm):
		revealed = true
		revision += 1


func can_use_candy(id: String, item_id: String) -> bool:
	var gain := int(_config.candy_levels.get(item_id, 0))
	return IDS.has(id) and gain > 0 and level(id) + gain <= cap()


func use_candy(id: String, item_id: String) -> bool:
	if not can_use_candy(id, item_id):
		return false
	var progress := fraction(id)
	_levels[id] += int(_config.candy_levels[item_id])
	_xp[id] = 0.0 if level(id) == cap() else progress * xp_needed(level(id))
	revision += 1
	return true


func efficiency(id: String) -> float:
	var spec: Dictionary = _config.skills.get(id, {})
	return 1.0 - minf(float(spec.get("efficiency_cap", 0.0)), level(id) * float(spec.get("efficiency_per_level", 0.0)))


func catch_bonus() -> float:
	var spec: Dictionary = _config.skills.catching
	return minf(float(spec.chance_cap), level("catching") * float(spec.chance_per_level))


func handling_bonus() -> float:
	var spec: Dictionary = _config.skills.riding
	return minf(float(spec.handling_cap), level("riding") * float(spec.handling_per_level))


func save_data() -> Dictionary:
	return {"version":1,"revealed":revealed,"levels":_levels.duplicate(),"xp":_xp.duplicate()}


func load_data(data: Dictionary) -> void:
	# A missing legacy block starts at zero. Never invent past activity.
	var levels: Dictionary = data.get("levels", {}) if data.get("levels", {}) is Dictionary else {}
	var xp: Dictionary = data.get("xp", {}) if data.get("xp", {}) is Dictionary else {}
	for id: String in IDS:
		var raw_level: Variant = levels.get(id, 0)
		var raw_xp: Variant = xp.get(id, 0.0)
		_levels[id] = clampi(int(raw_level), 0, cap()) if (raw_level is int or raw_level is float) and is_finite(float(raw_level)) else 0
		_xp[id] = clampf(float(raw_xp), 0.0, xp_needed(level(id)) - 0.000001) if (raw_xp is int or raw_xp is float) and is_finite(float(raw_xp)) and level(id) < cap() else 0.0
	revealed = data.get("revealed", false) == true
	revision += 1
