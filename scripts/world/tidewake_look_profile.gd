extends RefCounted

## One local presentation gate for the Tidewake rig and surface family.
## No world flags, persistence, traversal or multiplayer state are written.
const CONFIG := "res://data/config/tidewake_look.json"


static func settings() -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(CONFIG))
	if not parsed is Dictionary:
		return {}
	return resolve(parsed)


## The in-play profile for a parsed config (capture flags, sections_off and
## the cause_tidewake parts applied). Split out so tests can supply a config.
static func resolve(parsed: Dictionary) -> Dictionary:
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
	# tb/vis-water-sky (flag-off): lane batch switch that brings named
	# sections_off candidates into play together for the GPU batch judge.
	if bool(parsed.get("watersky_sections_on", false)):
		for section: Variant in parsed.get("watersky_sections", []):
			restore.append(str(section))
	# tb/cause-tidewake (flag-off): each enabled `cause_tidewake.<part>` brings
	# its listed sections_off candidates into play and merges its `merge` map
	# over the profile's top-level sections. Disabled parts change nothing.
	var cause_merges: Array[Dictionary] = []
	for part: Dictionary in cause_parts(parsed):
		for section: Variant in part.get("restore", []):
			restore.append(str(section))
		cause_merges.append(part.get("merge", {}))
	for section: Variant in parsed.get("sections_off", []):
		if not restore.has(str(section)):
			parsed.erase(str(section))
	for values: Dictionary in cause_merges:
		parsed = merge(parsed, values)
	return parsed


## The enabled `cause_tidewake` parts, in file order. A part is enabled by its
## own `enabled` key or, for captures only, by --tidewake-cause=<part>[,...].
static func cause_parts(parsed: Dictionary) -> Array[Dictionary]:
	var forced: PackedStringArray = []
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--tidewake-cause="):
			forced = arg.trim_prefix("--tidewake-cause=").split(",", false)
	var parts: Array[Dictionary] = []
	var cause: Variant = parsed.get("cause_tidewake", {})
	if not cause is Dictionary:
		return parts
	for key: String in cause:
		var part: Variant = cause[key]
		if key.begins_with("_") or not part is Dictionary:
			continue
		if bool(part.get("enabled", false)) or forced.has(key):
			parts.append(part)
	return parts


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
