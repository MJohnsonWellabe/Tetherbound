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


## CREATURE-LEGIBILITY-0903. The ground-contact shadow block -- see this key's
## own `_comment_contact_shadow` in the config file for why it exists and why
## it applies to every creature rather than opting in per species.
static func contact_shadow() -> Dictionary:
	var block: Variant = config().get("contact_shadow", {})
	return block if block is Dictionary else {}


static func contact_shadow_enabled() -> bool:
	return bool(contact_shadow().get("enabled", true))


static func contact_shadow_radius_scale() -> float:
	return float(contact_shadow().get("radius_scale", 1.35))


static func contact_shadow_opacity() -> float:
	return float(contact_shadow().get("opacity", 0.45))


static func contact_shadow_core_fraction() -> float:
	return float(contact_shadow().get("core_fraction", 0.35))


static func contact_shadow_edge_power() -> float:
	return float(contact_shadow().get("edge_power", 1.6))


## OP-0905-03 ("Bramblebun colour is awful", docs/owner/OWNER_PLAYTEST_2026-09-05.md).
## The soft-knee ceiling `creature_body.gd::_soft_knee_bright()` compresses the
## `field_emission`/`field_degreen` multiply toward, so a species pushed hard
## for grass-separation (Bramblebun's shipped 2.5 -> a raw 3.5x/3.24x multiply)
## lands as a real brightening instead of an ACES-clipped, texture-crushing
## wash of near-white. See that function's own comment for why 1.75 (not the
## sub-1.0 value first floated for this key) is the right default for THIS
## architecture: these materials' un-brightened tint is already a flat white
## (1,1,1) over a textured base, so any ceiling below 1.0 would darken every
## brightened species below its own normal shipped look. TUNABLE -- re-measure
## against `tools/_probe_grass_separation.gd`'s render-based sweep before
## treating 1.75 as settled; this session could only verify it numerically
## (`tools/_probe_field_bright_values.gd`), not against a real render.
const DEFAULT_FIELD_BRIGHT_CEILING := 1.75


static func field_bright_ceiling() -> float:
	return float(config().get("field_bright_ceiling", DEFAULT_FIELD_BRIGHT_CEILING))
