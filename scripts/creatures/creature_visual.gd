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


## CREATURE-PRESENTATION. Multiplier applied to a creature material's emission
## energy when its colourway texture is swapped in.
##
## These models ship SELF-LIT: the same painted albedo is wired into the
## emission slot at full energy, so every creature adds a copy of its own
## texture to whatever the sun is already doing. Measured on mudsnout, whose
## repainted albedo is a saturated mid-brown (hue 24, sat 0.63, value 0.37) and
## whose rendered body in daylight is a pale peach -- the emission pass washes
## saturation out and flattens the value range that carries a face. That is a
## large part of why the roster reads as pastel blobs at distance while its
## textures do not.
##
## Scaled rather than switched off: the emission is doing real work at dusk and
## in the warrens, where an unlit creature would be a black shape.
static func emission_scale() -> float:
	return float(config().get("emission_scale", 1.0))
