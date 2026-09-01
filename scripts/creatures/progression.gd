extends RefCounted

## Creature progression arithmetic (D30), with no dependency on the scene tree.
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


## XP a defeated wild creature of `enemy_level` pays out, before it is split across
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


## §11's "smaller XP from... bonding activities" (R4.1-remainder): a flat
## award every party member gets for resting through the night together,
## whether or not they fought that day. Combat's per-kill award excludes
## fainted members because they did not fight; this one does not, because
## resting at camp is not something a member can opt out of by being hurt.
static func rest_xp(cfg: Dictionary) -> int:
	var award_cfg: Dictionary = cfg.get("xp_award", {})
	return int(award_cfg.get("rest_bonus", 0))


## A stat at `level`, scaled linearly from its level-1 `base` by `growth` per
## level above 1. `stat_at_level(base, 1, growth)` is always exactly `base`,
## whatever `growth` is — level 1 is the species' base stat by definition, not
## a special case the caller has to route around.
static func stat_at_level(base: float, level: int, growth: float) -> float:
	return base * (1.0 + growth * float(maxi(level, 1) - 1))


## A wild creature's level, from `rng_value` in 0..1 supplied by the caller so
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


## The multiplier bond applies to a stat named by `key` (e.g. "attack_scale",
## "defence_scale", matching `bond.effects_per_node`'s own keys). 1.0 at zero
## nodes, so a freshly caught creature with no bond yet fights at its plain stats —
## bond is a bonus a trainer earns, never a penalty for not having earned it
## yet.
static func bond_stat_scale(nodes: int, key: String, cfg: Dictionary) -> float:
	var bond_cfg: Dictionary = cfg.get("bond", {})
	var effects: Dictionary = bond_cfg.get("effects_per_node", {})
	var per_node := float(effects.get(key, 0.0))
	return 1.0 + float(nodes) * per_node


## --- individuality (R4.2, GAME_DESIGN.md 11) --------------------------------

## The multiplier a per-stat quality roll (0.0-1.0, 0.5 = perfectly average)
## applies on top of the level curve. 1.0 exactly at `iv == 0.5` regardless of
## `variance_pct`, and 1.0 for every `iv` when `individuality` config is
## missing (`variance_pct` defaults to 0.0) — both are what keep every
## existing caller that does not roll individuality (a default 0.5 field, or
## a config with no `individuality` block) reproducing today's stats exactly.
static func individuality_multiplier(iv: float, cfg: Dictionary) -> float:
	var indiv_cfg: Dictionary = cfg.get("individuality", {})
	var variance := float(indiv_cfg.get("variance_pct", 0.0))
	return 1.0 + variance * (clampf(iv, 0.0, 1.0) - 0.5) * 2.0


## 1-5 stars/bars for an appraisal display (GAME_DESIGN.md 11: "show
## appraisal through stars/bars, not exact IV numbers" — never show `iv`
## itself). Buckets `iv` against `individuality.star_thresholds`, whose four
## cut points split 0..1 into five bands.
static func appraisal_stars(iv: float, cfg: Dictionary) -> int:
	var indiv_cfg: Dictionary = cfg.get("individuality", {})
	var thresholds: Array = indiv_cfg.get("star_thresholds", [0.2, 0.4, 0.6, 0.8])
	var stars := 1
	for threshold: Variant in thresholds:
		if iv >= float(threshold):
			stars += 1
	return stars


## Whether `nodes` bond nodes crossed is enough to unlock a creature's second
## trait (GAME_DESIGN.md 11: "a second trait can develop later through
## progression/bond").
static func trait_unlocked(nodes: int, cfg: Dictionary) -> bool:
	var trait_cfg: Dictionary = cfg.get("traits", {})
	var required := int(trait_cfg.get("unlock_bond_nodes", 5))
	return nodes >= required
