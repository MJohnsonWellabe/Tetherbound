extends RefCounted

## One local presentation gate for the Tidewake rig and surface family.
## No world flags, persistence, traversal or multiplayer state are written.
const CONFIG := "res://data/config/tidewake_look.json"


static func settings() -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(CONFIG))
	if not parsed is Dictionary:
		return {}
	# Explicit, process-local capture override; never persisted or replicated.
	# It also brings back the sections listed in `sections_off` (unjudged
	# candidates that ship in the file but not in play).
	if OS.get_cmdline_user_args().has("--tidewake-look-candidate"):
		parsed.enabled = true
		return parsed
	# Capture-only: restore just the named unjudged sections, so a judged
	# round can attribute its result to one candidate instead of all of them.
	var restore: PackedStringArray = []
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--tidewake-look-sections="):
			restore = arg.trim_prefix("--tidewake-look-sections=").split(",", false)
	for section: Variant in parsed.get("sections_off", []):
		if not restore.has(str(section)):
			parsed.erase(str(section))
	return parsed


static func overlay(base: Dictionary, section: String, supplied: Dictionary = {}) -> Dictionary:
	var profile := supplied if not supplied.is_empty() else settings()
	if not bool(profile.get("enabled", false)):
		return base
	var values: Dictionary = profile.get(section, {})
	return merge(base, values)


static func merge(base: Dictionary, values: Dictionary) -> Dictionary:
	var result := base.duplicate(true)
	for key: Variant in values:
		if result.get(key) is Dictionary and values[key] is Dictionary:
			result[key] = merge(result[key], values[key])
		else:
			result[key] = values[key]
	return result
