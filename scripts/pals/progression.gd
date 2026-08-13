extends RefCounted

## Pal progression arithmetic (D30), with no dependency on the scene tree.
##
## Same split as scripts/combat/combat_math.gd: pure static functions over
## numbers from data/config/progression.json, so a level curve or a bond
## threshold can be tuned by editing data, not by finding every place the old
## number was hard-coded into gameplay code.
##
## Every function here takes its config dict as an explicit argument rather
## than reading `config()` internally the way combat_math's damage functions
## do. combat_math is called mid-fight, always against the one real
## combat.json; progression numbers get asked about from tests that want to
## pin a curve without touching the shipped file, and from a future save/load
## or catch flow that may want to roll a level against a config it already
## has in hand. Passing it in keeps both cases the same function call.

const CONFIG_PATH := "res://data/config/progression.json"

static var _config: Dictionary = {}


## The shipped progression.json, cached after the first read. Callers that do
## not need a custom config for a test can pass `Progression.config()`
## straight into any function below.
static func config() -> Dictionary:
	if not _config.is_empty():
		return _config
	var file := FileAccess.open(CONFIG_PATH, FileAccess.READ)
	if file == null:
		push_error("progression.json missing at %s" % CONFIG_PATH)
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if parsed is Dictionary:
		_config = parsed
	return _config


## XP required to climb from `level` to `level + 1`.
##
## `base * level ^ exponent`, floored to an int. Monotonically increasing for
## any base > 0 and exponent > 0 — each level costs strictly more than the
## last, which is the one property the curve actually has to hold; the exact
## shape is the owner's to tune on the Ally.
static func xp_to_next(level: int, cfg: Dictionary) -> int:
	var level_cfg: Dictionary = cfg.get("level", {})
	var base := float(level_cfg.get("xp_to_next_base", 40.0))
	var exponent := float(level_cfg.get("xp_to_next_exponent", 1.6))
	return int(base * pow(float(maxi(level, 1)), exponent))


## XP a defeated wild pal of `enemy_level` pays out, before it is split across
## the party that fought it.
static func xp_award_for(enemy_level: int, cfg: Dictionary) -> int:
	var award_cfg: Dictionary = cfg.get("xp_award", {})
	var base := float(award_cfg.get("base", 18.0))
	var per_level := float(award_cfg.get("per_enemy_level", 6.0))
	return int(base + per_level * float(enemy_level))


## What one party member's share of `amount` xp is, floored so a three-way
## split can never hand out fractional xp.
static func party_share(amount: int, cfg: Dictionary) -> int:
	var award_cfg: Dictionary = cfg.get("xp_award", {})
	var share := float(award_cfg.get("party_share", 0.35))
	return int(floor(float(amount) * share))


## A stat at `level`, scaled linearly from its level-1 `base` by `growth` per
## level above 1. `stat_at_level(base, 1, growth)` is always exactly `base`,
## whatever `growth` is — level 1 is the species' base stat by definition, not
## a special case the caller has to route around.
static func stat_at_level(base: float, level: int, growth: float) -> float:
	return base * (1.0 + growth * float(maxi(level, 1) - 1))


## A wild pal's level, from `rng_value` in 0..1 supplied by the caller so
## tests can pin it and encounters stay reproducible (the same house rule as
## combat_math.rolled_damage's `roll` argument). 0.0 gives the bottom of
## `wild_band`, 1.0 gives the top, and everything between is a linear
## interpolation rounded to the nearest whole level.
static func roll_wild_level(cfg: Dictionary, rng_value: float) -> int:
	var level_cfg: Dictionary = cfg.get("level", {})
	var band: Array = level_cfg.get("wild_band", [1, 1])
	var low := int(band[0]) if band.size() > 0 else 1
	var high := int(band[1]) if band.size() > 1 else low
	var roll := clampf(rng_value, 0.0, 1.0)
	return int(round(lerpf(float(low), float(high), roll)))


## How many bond thresholds `bond` has crossed, 0 to `thresholds.size()`. A
## count rather than a named tier because the UI and the stat-scaling both
## just need "how many", and naming the tiers is a presentation decision that
## does not belong in pure arithmetic.
static func bond_nodes(bond: int, cfg: Dictionary) -> int:
	var bond_cfg: Dictionary = cfg.get("bond", {})
	var thresholds: Array = bond_cfg.get("thresholds", [])
	var nodes := 0
	for threshold: Variant in thresholds:
		if bond >= int(threshold):
			nodes += 1
	return nodes


## The multiplier bond applies to a stat named by `key` (e.g. "attack_scale",
## "defence_scale", matching `bond.effects_per_node`'s own keys). 1.0 at zero
## nodes, so a freshly caught pal with no bond yet fights at its plain stats —
## bond is a bonus a trainer earns, never a penalty for not having earned it
## yet.
static func bond_stat_scale(nodes: int, key: String, cfg: Dictionary) -> float:
	var bond_cfg: Dictionary = cfg.get("bond", {})
	var effects: Dictionary = bond_cfg.get("effects_per_node", {})
	var per_node := float(effects.get(key, 0.0))
	return 1.0 + float(nodes) * per_node
