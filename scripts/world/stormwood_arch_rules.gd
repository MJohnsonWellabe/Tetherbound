extends RefCounted

const PATH := "res://data/config/stormwood_arches.json"

static func config() -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string(PATH))

static func definition(id: String) -> Dictionary:
	for arch: Dictionary in config().arches:
		if str(arch.id) == id:
			return arch
	return {}

static func lit_flag(id: String) -> String:
	return "stormwood:arch:%s:lit" % id

static func is_lit(arch: Dictionary, flags: RefCounted) -> bool:
	return bool(arch.get("starts_lit", false)) or flags.has(lit_flag(str(arch.id)))

static func is_available(arch: Dictionary, flags: RefCounted) -> bool:
	var gate := str(arch.get("requires_flag", ""))
	return gate.is_empty() or flags.has(gate)

static func linked_twin(id: String, flags: RefCounted) -> Dictionary:
	var source := definition(id)
	if source.is_empty() or not is_available(source, flags) or not is_lit(source, flags):
		return {}
	for arch: Dictionary in config().arches:
		if str(arch.id) != id and str(arch.pair) == str(source.pair) and is_available(arch, flags) and is_lit(arch, flags):
			return arch
	return {}
