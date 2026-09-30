extends RefCounted

## RD-09/10: one order, preserving the established Water runtime namespace.
const PATH := "res://data/config/biome_order.json"
static var _test_overrides: Dictionary = {}

## Isolated regression fixtures may exercise retired crossings using the SAME
## flag. Shipping defaults stay in JSON; this hook is unavailable in release.
static func set_test_overrides(overrides: Dictionary) -> bool:
	if not OS.has_feature("debug"): return false
	for key: Variant in overrides:
		if key != "legacy_physical_crossings" or not overrides[key] is bool: return false
	_test_overrides = overrides.duplicate(true)
	return true

static func clear_test_overrides() -> void:
	_test_overrides = {}

static func config() -> Dictionary:
	var raw: Variant = JSON.parse_string(FileAccess.get_file_as_string(PATH))
	if not raw is Dictionary or not raw.get("live") is Array or not raw.get("reserved") is Array:
		push_error("Biome order config is missing or invalid")
		return {}
	var out: Dictionary = raw.duplicate(true)
	out.merge(_test_overrides, true)
	return out

static func ids(include_reserved: bool = true) -> Array[String]:
	var data := config()
	var out: Array[String] = []
	for id: Variant in data.get("live", []):
		out.append(str(id))
	if include_reserved:
		for id: Variant in data.get("reserved", []):
			out.append(str(id))
	return out

static func canonical_id(runtime_id: String) -> String:
	var aliases: Dictionary = config().get("runtime_aliases", {})
	for id: Variant in aliases:
		if str(aliases[id]) == runtime_id:
			return str(id)
	return runtime_id

static func runtime_id(id: String) -> String:
	return str((config().get("runtime_aliases", {}) as Dictionary).get(id, id))

static func runtime_ids(include_reserved: bool = false) -> Array[String]:
	var out: Array[String] = []
	for id: String in ids(include_reserved):
		out.append(runtime_id(id))
	return out

static func ordered_runtime_ids(available: Array) -> Array[String]:
	var out: Array[String] = []
	for id: String in runtime_ids(true):
		if available.has(id):
			out.append(id)
	return out

static func display_name(id: String) -> String:
	return str((config().get("display_names", {}) as Dictionary).get(canonical_id(id), "Unknown biome"))

static func legacy_physical_crossings() -> bool:
	return bool(config().get("legacy_physical_crossings", false))
