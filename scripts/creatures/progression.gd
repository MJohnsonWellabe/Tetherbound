extends RefCounted

## Creature progression arithmetic (D30), with no dependency on the scene tree.
##
## Same split as scripts/combat/combat_math.gd: pure static functions over
## numbers from data/config/progression.json, so a level curve or a bond
## threshold can be tuned by editing data, not by finding every place the old
## number was hard-coded into gameplay code.
##
## Curve functions accept an explicit progression config. The reachable
## combat award also reads the shipped F27 rate, with an optional explicit
## rate config for focused proofs; rest and noncombat bonuses stay separate.

const CONFIG_PATH := "res://data/config/progression.json"
const COMBAT_XP_CONFIG_PATH := "res://data/config/essence.json"
const CONDITION := preload("res://scripts/creatures/creature_condition.gd")

static var _config: Dictionary = {}
static var _combat_xp_config: Dictionary = {}
static var _combat_xp_config_loaded := false


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


## F27 rate is cached separately from the existing curve. No Essence preload:
## the arithmetic has no inventory, owner-write or transaction dependency.
static func combat_xp_config() -> Dictionary:
	if _combat_xp_config_loaded: return _combat_xp_config
	_combat_xp_config_loaded = true
	var file := FileAccess.open(COMBAT_XP_CONFIG_PATH, FileAccess.READ)
	if file == null:
		push_error("Combat XP rate config missing at %s" % COMBAT_XP_CONFIG_PATH)
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if parsed is Dictionary: _combat_xp_config = parsed
	return _combat_xp_config


## Existing unreduced formula; never feed this directly to a victory grant.
## Kept explicit so the live award and future typed defeat cannot double-scale.
static func raw_xp_award_for(enemy_level: int, cfg: Dictionary) -> int:
	var award_cfg: Dictionary = cfg.get("xp_award", {})
	var base: Variant = award_cfg.get("base", 18.0)
	var per_level: Variant = award_cfg.get("per_enemy_level", 6.0)
	if enemy_level < 1 or enemy_level > 100: return 0
	for value: Variant in [base, per_level]:
		if not (value is int or value is float) or not is_finite(float(value)) or float(value) < 0.0: return 0
	var amount := float(base) + float(per_level) * float(enemy_level)
	return int(floorf(amount)) if is_finite(amount) and amount <= 2147483647.0 else 0


## CombatManager._award_victory already calls this for every won opponent,
## including each co-op participant reading the host's done record. Apply the
## authored reduction HERE, exactly once, before the existing bench split.
## Optional explicit rate supports focused arithmetic proofs; gameplay uses
## the shipped cached config. Rest and authored story/trainer bonuses stay separate.
static func xp_award_for(enemy_level: int, cfg: Dictionary, rate_cfg: Dictionary = {}) -> int:
	return scaled_combat_xp(enemy_level, cfg, combat_xp_config() if rate_cfg.is_empty() else rate_cfg)


## A positive eligible combat award cannot floor to zero. Invalid authoring
## refuses the amount explicitly, rather than silently falling back to full XP.
static func scaled_combat_xp(enemy_level: int, cfg: Dictionary, essence_cfg: Dictionary) -> int:
	var raw: Variant = essence_cfg.get("auto_xp_scale")
	if not (raw is int or raw is float) or not is_finite(float(raw)) \
			or float(raw) <= 0.0 or float(raw) >= 1.0:
		return 0
	var amount := raw_xp_award_for(enemy_level, cfg)
	return maxi(1, int(floor(float(amount) * float(raw)))) if amount > 0 else 0


## An eligible participant's configured share also stays positive after the
## second floor. The encounter owner excludes ineligible/fainted recipients;
## neither this arithmetic nor the UI decides who earned a defeat award.
static func scaled_party_combat_xp(enemy_level: int, cfg: Dictionary, essence_cfg: Dictionary) -> int:
	return party_share(scaled_combat_xp(enemy_level, cfg, essence_cfg), cfg)


## Detached snapshot math uses the same canonical stat functions as
## CreatureInstance._apply_level_stats. Live HP, XP, UI events and saves are
## untouched here. The host commits this with the resource debit or neither.
static func staged_next_level(row: Dictionary, cap: int, cfg: Dictionary) -> Dictionary:
	var level_raw: Variant = row.get("level")
	if not (level_raw is int or level_raw is float) or not is_finite(float(level_raw)) \
			or float(level_raw) != floorf(float(level_raw)) or int(level_raw) < 1 or int(level_raw) >= cap:
		return {}
	if not _staged_row_valid(row, cfg): return {}
	var next := row.duplicate(true)
	var fraction := float(row.hp) / float(row.max_hp)
	next.level = int(row.level) + 1
	next.xp = 0 if int(next.level) == cap else int(row.xp)
	next.levels_gained_with_you = int(row.levels_gained_with_you) + 1
	var growth: Dictionary = cfg.get("level", {}).get("growth_per_level", {})
	for stat: String in ["hp", "attack", "defence"]:
		var value := stat_at_level(float(row["base_" + stat]), int(next.level), float(growth.get(stat, 0.0))) \
			* individuality_multiplier(float(row["iv_" + stat]), cfg) + float(row.get("boost_" + stat, 0))
		if not is_finite(value) or value <= 0.0:
			return {}
		next["max_hp" if stat == "hp" else stat] = value
	next.hp = float(next.max_hp) * fraction
	return next


static func _staged_row_valid(row: Dictionary, cfg: Dictionary) -> bool:
	var level_raw: Variant = row.get("level")
	if not (level_raw is int or level_raw is float) or not is_finite(float(level_raw)) \
			or float(level_raw) != floorf(float(level_raw)) or int(level_raw) < 1 or int(level_raw) > 100:
		return false
	for field: String in ["hp", "max_hp", "base_hp", "base_attack", "base_defence", "iv_hp", "iv_attack", "iv_defence", "xp", "levels_gained_with_you"]:
		var raw: Variant = row.get(field)
		if not (raw is int or raw is float) or not is_finite(float(raw)) or float(raw) < 0.0:
			return false
	for stat: String in ["hp", "attack", "defence"]:
		var boost: Variant = row.get("boost_" + stat, 0)
		if not (boost is int or boost is float) or not is_finite(float(boost)) \
				or float(boost) < 0.0 or float(boost) != floorf(float(boost)) \
				or float(row["iv_" + stat]) > 1.0 or float(row["base_" + stat]) <= 0.0:
			return false
	if float(row.max_hp) <= 0.0 or float(row.hp) > float(row.max_hp) \
			or float(row.xp) != floorf(float(row.xp)) or int(row.xp) >= xp_to_next(int(row.level), cfg) \
			or float(row.levels_gained_with_you) != floorf(float(row.levels_gained_with_you)):
		return false
	return true


## Detached participant XP for the host defeat/rest transaction. Caller owns
## eligibility, positive award math and the creature's admitted typed cap.
## At the cap XP becomes zero; it cannot bank for a later breakthrough.
static func staged_xp(row: Dictionary, cap: int, amount: int, cfg: Dictionary) -> Dictionary:
	if cap < 1 or cap > 100 or amount <= 0 or amount > 2147483647: return {}
	var current := row.duplicate(true)
	var level_raw: Variant = current.get("level")
	var banked: Variant = current.get("xp")
	if not (level_raw is int or level_raw is float) or not is_finite(float(level_raw)) \
			or float(level_raw) != floorf(float(level_raw)) or int(level_raw) > cap: return {}
	if not (banked is int or banked is float) or not is_finite(float(banked)) \
			or float(banked) < 0.0 or float(banked) != floorf(float(banked)) \
			or float(banked) > 2147483647: return {}
	if int(level_raw) == cap: current.xp = 0
	if not _staged_row_valid(current, cfg): return {}
	if int(current.level) == cap: return current
	var remaining := int(current.xp) + amount
	current.xp = 0
	while int(current.level) < cap:
		var needed := xp_to_next(int(current.level), cfg)
		if needed <= 0: return {}
		if remaining < needed: break
		remaining -= needed
		current = staged_next_level(current, cap, cfg)
		if current.is_empty(): return {}
	current.xp = 0 if int(current.level) == cap else remaining
	return current


## Detached property adapter calls the EXISTING condition arithmetic without
## a live CreatureInstance, feed event, scene mutation or copied mood formula.
class TrainingConditionSnapshot extends RefCounted:
	var values: Dictionary = {}
	func _get(property: StringName) -> Variant:
		return values.get(str(property))
	func _set(property: StringName, value: Variant) -> bool:
		if not values.has(str(property)): return false
		values[str(property)] = value
		return true


static func staged_training_condition(row: Dictionary, levels_gained: int,
		victory: bool, condition_cfg: Dictionary = {}) -> Dictionary:
	if levels_gained < 0 or levels_gained > 59 or not row.get("fainted") is bool: return {}
	var mood: Variant = row.get("happiness")
	if not (mood is int or mood is float) or not is_finite(float(mood)) or float(mood) < 0.0: return {}
	var cfg := CONDITION.config() if condition_cfg.is_empty() else condition_cfg
	var happiness: Variant = cfg.get("happiness")
	if not happiness is Dictionary: return {}
	for field: String in ["max", "on_victory", "on_level_up"]:
		var value: Variant = happiness.get(field)
		if not (value is int or value is float) or not is_finite(float(value)): return {}
	if float(happiness.max) < 0.0 or float(mood) > float(happiness.max): return {}
	var snapshot := TrainingConditionSnapshot.new()
	snapshot.values = row.duplicate(true)
	if victory:
		var fought: Variant = row.get("battles_fought")
		if row.fainted or not (fought is int or fought is float) or not is_finite(float(fought)) \
				or float(fought) != floorf(float(fought)) or float(fought) < 0.0 or float(fought) >= 2147483647.0:
			return {}
		snapshot.values.battles_fought = int(fought) + 1
		CONDITION.note_victory(snapshot, cfg)
	for _level: int in levels_gained:
		CONDITION.note_level_up(snapshot, cfg)
	return snapshot.values


## Pure full-party XP proposal for an actual host defeat. The combat owner
## derives active UID, eligible UIDs and caps from its admitted/frozen records;
## none is accepted from a client packet. This provides no journal/CAS/ACK.
## Compose this with type essence, existing victory/bond/condition effects and
## the host defeat receipt before promotion. No legacy award caller is changed.
static func staged_combat_party_xp(party_rows: Array, host_active_uid: String,
		host_eligible_uids: Array, host_caps: Dictionary, host_enemy_level: int,
		cfg: Dictionary, essence_cfg: Dictionary) -> Dictionary:
	if party_rows.is_empty() or party_rows.size() > 5 or host_active_uid.is_empty() \
			or host_enemy_level < 1 or host_enemy_level > 100 or host_eligible_uids.is_empty(): return {}
	var by_uid: Dictionary = {}
	for raw: Variant in party_rows:
		if not raw is Dictionary or not raw.get("uid") is String or str(raw.uid).is_empty() \
				or by_uid.has(raw.uid) or not raw.get("fainted") is bool: return {}
		by_uid[raw.uid] = raw
	if not by_uid.has(host_active_uid): return {}
	var eligible: Dictionary = {}
	for uid: Variant in host_eligible_uids:
		if not uid is String or not by_uid.has(uid) or eligible.has(uid): return {}
		var raw: Dictionary = by_uid[uid]
		var hp: Variant = raw.get("hp")
		var cap: Variant = host_caps.get(uid)
		if raw.fainted or not (hp is int or hp is float) or not is_finite(float(hp)) or float(hp) <= 0.0 \
				or not (cap is int or cap is float) or not is_finite(float(cap)) \
				or float(cap) != floorf(float(cap)) or not int(cap) in [10, 20, 30, 40, 50, 60]: return {}
		eligible[uid] = int(cap)
	if not eligible.has(host_active_uid): return {}
	var full := scaled_combat_xp(host_enemy_level, cfg, essence_cfg)
	var share := scaled_party_combat_xp(host_enemy_level, cfg, essence_cfg)
	if full <= 0 or share <= 0: return {}
	var next := party_rows.duplicate(true)
	var awards: Dictionary = {}
	for index: int in next.size():
		var uid: String = next[index].uid
		if not eligible.has(uid): continue
		var amount := full if uid == host_active_uid else share
		var changed := staged_xp(next[index], int(eligible[uid]), amount, cfg)
		if changed.is_empty(): return {}
		var gained := int(changed.level) - int(next[index].level)
		changed = staged_training_condition(changed, gained, true)
		if changed.is_empty(): return {}
		awards[uid] = {"authored_award": amount, "levels": gained, "battle_credit": 1,
			"happiness_before": next[index].happiness, "happiness_after": changed.happiness,
			"old_level": int(next[index].level), "level": int(changed.level), "xp": int(changed.xp),
			"cap": int(eligible[uid]), "at_cap": int(changed.level) == int(eligible[uid])}
		next[index] = changed
	return {"party": next, "before_party": party_rows.duplicate(true), "awards": awards,
		"ready_to_commit": false, "requires": ["actual_host_wild_defeat_and_participants",
			"canonical_admitted_per_uid_caps", "same_record_XP_essence_victory_and_defeat_receipt_CAS",
			"canonical_learnset_refresh", "owner_save_ACK"]}


## Existing Good/Great/Rare Candy keep their authored number of levels. The
## host resolves the actual item definition and consumes ONE item atomically
## with this candidate. At cap no candidate means no candy is consumed.
static func staged_candy_levels(row: Dictionary, cap: int, count: int, cfg: Dictionary) -> Dictionary:
	if cap < 1 or cap > 100 or count <= 0 or count > 2147483647 or not _staged_row_valid(row, cfg): return {}
	if int(row.level) >= cap: return {}
	var current := row.duplicate(true)
	var levels := mini(count, cap - int(row.level))
	for _index: int in levels:
		current = staged_next_level(current, cap, cfg)
		if current.is_empty(): return {}
	return current


## The live bench split receives an ALREADY reduced award. Never apply the
## F27 rate twice; a positive eligible share has a one-XP rounding floor.
static func party_share(amount: int, cfg: Dictionary) -> int:
	var award_cfg: Dictionary = cfg.get("xp_award", {})
	var share: Variant = award_cfg.get("party_share", 0.35)
	if amount <= 0 or amount > 2147483647 or not (share is int or share is float) \
			or not is_finite(float(share)) or float(share) <= 0.0 or float(share) > 1.0: return 0
	return maxi(1, int(floor(float(amount) * float(share))))


## §11's "smaller XP from... bonding activities" (R4.1-remainder): a flat
## award every party member gets for resting through the night together,
## whether or not they fought that day. Combat's per-kill award excludes
## fainted members because they did not fight; this one does not, because
## resting at camp is not something a member can opt out of by being hurt.
static func rest_xp(cfg: Dictionary) -> int:
	var award_cfg: Dictionary = cfg.get("xp_award", {})
	return int(award_cfg.get("rest_bonus", 0))


## `creature_bed`'s own full_heal_seconds (see progression.json's comment on
## that block) -- centralized so a UI reading for a time-remaining display and
## `game_state.gd`'s own per-second heal tick can never disagree about it.
static func creature_bed_full_heal_seconds(cfg: Dictionary) -> float:
	return maxf(float(cfg.get("creature_bed", {}).get("full_heal_seconds", 120.0)), 1.0)


## OWNER-0902-REST-VISIBILITY. Owner playtest 2026-09-02 finding 7: "No way to
## tell when a creature finishes resting." Seconds until `creature`'s bed
## recovery reaches full HP -- the exact inverse of
## `game_state.gd::_tick_creature_bed_recovery`'s own per-second heal rate
## (`max_hp / full_heal_seconds`), so a UI reading this can never show a
## number the tick loop that actually drives recovery disagrees with. 0 for a
## creature that is not resting, already at full HP, or has no max_hp to
## recover toward -- "0 seconds left" is what "would read as done right now"
## should say, not a defined-but-wrong number.
static func rest_seconds_remaining(creature: RefCounted, cfg: Dictionary) -> float:
	if creature == null or not bool(creature.get("resting")):
		return 0.0
	var max_hp := float(creature.get("max_hp"))
	if max_hp <= 0.0:
		return 0.0
	var missing := max_hp - float(creature.get("hp"))
	if missing <= 0.0:
		return 0.0
	return missing / max_hp * creature_bed_full_heal_seconds(cfg)


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
