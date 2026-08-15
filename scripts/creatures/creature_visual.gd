extends RefCounted

## Visual-roll tunables for creatures (OF27): today, just the shiny odds.
##
## Same split as combat_math.gd/progression.gd/catch_math.gd: a pure static
## reader over data/config/creatures_visual.json, cached after the first
## read, so nothing that wants to know the odds re-parses the file per spawn.
## OF28 is expected to grow this file (or a sibling data/creatures/
## palettes.json) with per-species base/shiny colour palettes; this file
## deliberately starts with only the one number OF27 needs.

const CONFIG_PATH := "res://data/config/creatures_visual.json"

## 1/128 — Pokemon GO's own shiny rate, and the number the owner's own report
## named ("Rare and nothing different than just the colors"). Only used if
## the config file is missing or malformed; the shipped file states the same
## number explicitly so it can be retuned without touching code.
const DEFAULT_SHINY_CHANCE := 0.0078

static var _config: Dictionary = {}


static func config() -> Dictionary:
	if not _config.is_empty():
		return _config
	var file := FileAccess.open(CONFIG_PATH, FileAccess.READ)
	if file == null:
		push_error("creatures_visual.json missing at %s" % CONFIG_PATH)
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if parsed is Dictionary:
		_config = parsed
	return _config


## The odds a single wild roll comes up shiny, 0..1.
static func shiny_chance() -> float:
	return float(config().get("shiny_chance", DEFAULT_SHINY_CHANCE))
