extends RefCounted

## The trait table, loaded from data/traits/traits.json.
##
## Same shape and the same job as pal_species.gd: keep the numbers out of
## gameplay code so the whole roster of traits can be rebalanced, or replaced,
## without a line of combat or party code changing.
##
## Does NOT reference pal_instance.gd, and must not start. pal_instance preloads
## THIS file to apply modifiers, and two files that preload each other are a
## cyclic reference that refuses to load. That is also why the roll weights are
## read from data/config/party.json by the small loader at the bottom rather than
## borrowed from pal_instance's copy of the same config.

const TRAITS_PATH := "res://data/traits/traits.json"
const CONFIG_PATH := "res://data/config/party.json"

## The three stats a trait may touch. Named here so a typo in a stat key fails a
## test rather than silently multiplying nothing.
const STATS := ["hp", "attack", "defence"]

static var _table: Dictionary = {}
static var _config: Dictionary = {}


static func table() -> Dictionary:
	if not _table.is_empty():
		return _table
	var file := FileAccess.open(TRAITS_PATH, FileAccess.READ)
	if file == null:
		push_error("traits.json missing at %s" % TRAITS_PATH)
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		push_error("traits.json is not readable: %s" % TRAITS_PATH)
		return {}
	# Comment keys are stripped rather than trusted to be absent, unlike
	# species.json which keeps its prose strictly outside the `species` map. The
	# file invites `_comment_<topic>` keys inline, and one written a level too
	# high would otherwise become a rollable trait: a pal born "_comment_range"
	# with no modifiers, which reads as a data bug long after the edit that
	# caused it.
	var out: Dictionary = {}
	var entries: Dictionary = (parsed as Dictionary).get("traits", {})
	for id: String in entries.keys():
		if not id.begins_with("_"):
			out[id] = entries[id]
	_table = out
	return _table


static func has(trait_id: String) -> bool:
	return table().has(trait_id)


static func definition(trait_id: String) -> Dictionary:
	var entry: Variant = table().get(trait_id)
	return entry if entry is Dictionary else {}


static func ids() -> Array:
	return table().keys()


static func display_name(trait_id: String) -> String:
	return str(definition(trait_id).get("display_name", trait_id))


static func description(trait_id: String) -> String:
	return str(definition(trait_id).get("description", ""))


## What this trait multiplies `stat` by. Unknown trait, unknown stat and the
## empty trait id all return 1.0.
##
## Defaulting to 1.0 rather than 0.0 is the safe direction and the same choice
## catch_math.orb_multiplier made: a typo in a trait id should leave a pal
## ordinary, not leave it with no attack at all.
static func modifier(trait_id: String, stat: String) -> float:
	if trait_id.is_empty():
		return 1.0
	var mods: Variant = definition(trait_id).get("modifiers")
	if not mods is Dictionary:
		return 1.0
	return float((mods as Dictionary).get(stat, 1.0))


static func modifiers(trait_id: String) -> Dictionary:
	var out: Dictionary = {}
	for stat: String in STATS:
		out[stat] = modifier(trait_id, stat)
	return out


## Pick a trait. `roll` is 0..1 and supplied by the caller, so a catch is
## reproducible and a test can pin the outcome — the same contract catch_math
## uses for the throw itself.
##
## Weights come from data/config/party.json because rarity is tuning; what the
## trait DOES comes from traits.json because that is what the trait is.
static func roll(roll_value: float) -> String:
	var known: Array = ids()
	if known.is_empty():
		return ""
	var cfg: Dictionary = config().get("trait_roll", {})
	var weights: Dictionary = cfg.get("weights", {})
	var fallback := float(cfg.get("default_weight", 1.0))

	var total := 0.0
	for id: String in known:
		total += maxf(0.0, float(weights.get(id, fallback)))
	if total <= 0.0:
		return str(known[0])

	var target := clampf(roll_value, 0.0, 0.9999) * total
	var running := 0.0
	for id: String in known:
		running += maxf(0.0, float(weights.get(id, fallback)))
		if target < running:
			return id
	return str(known[known.size() - 1])


static func config() -> Dictionary:
	if not _config.is_empty():
		return _config
	var file := FileAccess.open(CONFIG_PATH, FileAccess.READ)
	if file == null:
		push_error("party.json missing at %s" % CONFIG_PATH)
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if parsed is Dictionary:
		_config = parsed
	return _config
