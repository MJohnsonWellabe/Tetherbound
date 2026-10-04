extends RefCounted

## RD-10 authoring manifest. The levels are materialized in the live JSON so
## every existing director reads the same values without a second loader.
## Applying the manifest again accepts those exact values without scaling twice.
const CONFIG_PATH := "res://data/config/redesign_level_curve.json"
const CURVE_PATH := "res://data/config/chapter_curve.json"
const PATHS := [
	CURVE_PATH,
	"res://data/config/bands/band3_the_river_lock/trainers.json",
	"res://data/config/bands/band4_upper_meadows_ironwood/trainers.json",
	"res://data/config/bands/band5_stronghold_approach/trainers.json",
	"res://data/config/bands/band4_upper_meadows_ironwood/spawns.json",
	"res://data/config/bands/band5_stronghold_approach/spawns.json",
	"res://data/config/cloudreach_chapter.json",
	"res://data/config/cloudreach_solmane_climax.json",
	"res://data/config/stormwood_encounters.json",
	"res://data/config/stormwood_trainers.json",
	"res://data/config/stormwood_dynamo.json",
	"res://data/config/water_characters.json",
	"res://data/config/water_encounters.json",
	"res://data/config/water_alpha.json",
]


static func config() -> Dictionary:
	var raw: Variant = JSON.parse_string(FileAccess.get_file_as_string(CONFIG_PATH))
	return raw if raw is Dictionary else {}


## Both gates must be literal booleans. OFF returns the original base without
## reading overlays or changing any cached production dictionary. ON refuses
## a stale identity/value or malformed path before making any detached change.
static func apply(path: String, base: Dictionary, activation: Variant = false,
		authored: Dictionary = {}) -> Dictionary:
	if typeof(activation) != TYPE_BOOL or activation != true:
		return base
	var cfg := config() if authored.is_empty() else authored
	if typeof(cfg.get("runtime_enabled")) != TYPE_BOOL or cfg.get("runtime_enabled") != true:
		return base
	if not PATHS.has(path) or not _level_number(cfg.get("schema_version")) \
			or float(cfg.schema_version) != 1.0 or not cfg.get("overlays") is Dictionary:
		return {}
	var rows: Variant = cfg.overlays.get(path.trim_prefix("res://"))
	if not rows is Array:
		return {}
	var seen: Dictionary = {}
	for raw: Variant in rows:
		if not raw is Dictionary or not raw.get("at") is Array \
				or not raw.get("anchors") is Array or not raw.has("legacy") \
				or not _level_number(raw.get("value")) or not _level_path(raw.at):
			return {}
		var key := JSON.stringify(raw.at)
		if seen.has(key):
			return {}
		seen[key] = true
		for anchor: Variant in raw.anchors:
			if not anchor is Dictionary or not anchor.get("at") is Array or not anchor.has("value"):
				return {}
			var found := _slot(base, anchor.at)
			if found.is_empty() or not found.exists or found.value != anchor.value:
				return {}
		var slot := _slot(base, raw.at)
		if slot.is_empty():
			return {}
		if raw.legacy == null:
			if not slot.container is Dictionary or (slot.exists \
					and (not _level_number(slot.value) or float(slot.value) != float(raw.value))):
				return {}
		elif not _level_number(raw.legacy) or not slot.exists \
				or not _level_number(slot.value) or (float(slot.value) != float(raw.legacy) \
					and float(slot.value) != float(raw.value)):
			return {}
	if path == CURVE_PATH and not cfg.get("biomes") is Dictionary:
		return {}
	var next := base.duplicate(true)
	for raw: Dictionary in rows:
		var slot := _slot(next, raw.at)
		slot.container[slot.key] = raw.value
	if path == CURVE_PATH:
		next["biomes"] = cfg.biomes.duplicate(true)
	return next


static func _level_number(value: Variant) -> bool:
	return (value is int or value is float) and is_finite(float(value)) \
		and float(value) == floorf(float(value)) and float(value) >= 1.0 and float(value) <= 100.0


static func _level_path(tokens: Array) -> bool:
	if tokens.is_empty() or tokens.size() > 16:
		return false
	var words: Array[String] = []
	for token: Variant in tokens:
		if token is String:
			words.append(token)
		elif not (token is int or token is float) or not is_finite(float(token)) \
				or float(token) < 0.0 or float(token) != floorf(float(token)):
			return false
	if words.is_empty():
		return false
	var last: String = words[-1]
	return last in ["level", "ace_level", "level_ceiling", "warden_level", "wild_band",
		"trainer_levels", "level_range", "level_band"] \
		or (last in ["enter", "exit"] and words.size() > 1 and words[-2] == "team")


## A slot describes its parent without assigning anything. JSON array indices
## are floats; require a finite nonnegative integer before indexing the array.
static func _slot(root: Dictionary, tokens: Array) -> Dictionary:
	if tokens.is_empty() or tokens.size() > 16:
		return {}
	var node: Variant = root
	for index in tokens.size():
		var token: Variant = tokens[index]
		var key: Variant
		var exists := false
		if node is Dictionary and token is String:
			key = token
			exists = node.has(key)
		elif node is Array and (token is int or token is float) \
				and is_finite(float(token)) and float(token) >= 0.0 \
				and float(token) == floorf(float(token)) and float(token) < node.size():
			key = int(token)
			exists = true
		else:
			return {}
		if index == tokens.size() - 1:
			return {"container": node, "key": key, "exists": exists, "value": node[key] if exists else null}
		if not exists:
			return {}
		node = node[key]
	return {}
