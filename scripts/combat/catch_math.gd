extends RefCounted

## Catch arithmetic, with no dependency on the scene tree.
##
## Same split as combat_math.gd and combat_ai.gd: every number a catch resolves
## passes through here, and nothing here knows about nodes, input or rendering.
## This is the part of M3 the owner will want changed — "catching is too hard",
## "a good throw doesn't feel worth it" — and both of those are questions about
## this file that a unit test can ask directly.
##
## The one rule that is not tuning: THE OUTCOME IS DECIDED ONCE. `resolve()`
## rolls, and `shakes_for` derives the wobble from the decision already made. A
## wobble that re-rolls per shake can contradict a result the game has already
## computed, and dramatising a lie is exactly what makes catch animations feel
## cheap.

const CONFIG_PATH := "res://data/config/catching.json"

static var _config: Dictionary = {}


static func config() -> Dictionary:
	if not _config.is_empty():
		return _config
	var file := FileAccess.open(CONFIG_PATH, FileAccess.READ)
	if file == null:
		push_error("catching.json missing at %s" % CONFIG_PATH)
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if parsed is Dictionary:
		_config = parsed
	return _config


## --- the odds -------------------------------------------------------------

## How much a target's remaining health is working against you.
##
## GAME_DESIGN.md §15 asks for two things at once: full-health throws must be
## ALLOWED, and full-health creatures must be EXTREMELY difficult. So this returns a
## small number rather than zero at full health, and rises to 1 at a sliver.
##
## The curve is back-loaded (exponent above 1) so that chipping a creature to half
## buys much less than taking it to a sliver. That is what keeps "damage it
## first" a genuine risk against "over-damage it and lose the catch entirely".
static func hp_factor(hp_fraction: float) -> float:
	var cfg: Dictionary = config().get("chance", {})
	var full := float(cfg.get("hp_factor_full", 0.10))
	var empty := float(cfg.get("hp_factor_empty", 1.0))
	var curve := maxf(float(cfg.get("hp_curve", 1.6)), 0.01)
	var hurt := pow(clampf(1.0 - hp_fraction, 0.0, 1.0), curve)
	return lerpf(full, empty, hurt)


## The scale a throw's placement is judged on: how far off centre the orb may
## pass and still be a hit at all.
##
## OP-0830-5, and the whole of it. See `accuracy_bonus()` below.
static func accuracy_scale(body_radius: float) -> float:
	var cfg := config()
	var orb_radius := float(cfg.get("throw", {}).get("radius", 0.60))
	var span := float(cfg.get("chance", {}).get("accuracy_span", 1.0))
	return maxf(body_radius + orb_radius * span, 0.001)


## What a throw's placement is worth, from how far off centre it struck.
##
## `offset` is metres from the target's centre of mass. A strike dead on the
## centre is worth `centre_bonus`; one passing at the very edge of what still
## counts as a hit is worth `edge_bonus`. If those two were equal, aiming would
## be decoration and this mechanic would have no subject.
##
## ## OWNER PLAYTEST, 2026-08-30 (OP-0830-5): *"catching is way too hard."*
##
## This function was the cause, and it was not the odds being low -- it was this
## term being **stuck at its worst value on nearly every throw the game can
## actually produce.**
##
## It used to divide by `body_radius`, on the reasoning that the bonus is scored
## against the CREATURE rather than against the orb's generous collision sphere.
## The reasoning is sound and the number was wrong, because `body_radius` is not
## a distance a real throw can hold. A Bramblebun's is **0.325 m**. Measured
## over 47 landed throws in real fights (`tools/_probe_catch_rate.gd`, three
## runs at two health tiers, every one of them with the launch assist committed
## and aiming at the predicted body centre):
##
##   * median real placement **0.375 m** -- already outside the whole scale;
##   * **77% of landed throws saturated the clamp** and scored the full
##     `edge_bonus` penalty;
##   * mean multiplier **0.845**, against a `centre_bonus` of 1.45 that this
##     config's own comment calls "the ONLY reason the aiming skill exists".
##
## So a perfectly aimed, assisted throw was scored as a graze roughly four times
## in five, the term varied by almost nothing, and every landed throw silently
## lost about 40% of the odds the HUD was advertising. The residual 0.375 m is
## not player error: it is the target moving during the orb's flight, which the
## launch prediction leads but cannot cancel.
##
## The fix is the SCALE, not the bonus. Placement is now judged over the
## envelope that defines a hit in the first place -- `body_radius` plus the
## orb's own radius, which is exactly the distance `orb.gd::_check_target()`
## tests against. A throw that passes dead centre still earns the full
## `centre_bonus`; one that only just clipped the envelope still earns
## `edge_bonus`; and everything between them now grades, which is what the term
## was written to do. Nothing here raises the ceiling: a dead-centre throw is
## worth exactly what it was worth before.
static func accuracy_bonus(offset: float, body_radius: float) -> float:
	var cfg: Dictionary = config().get("chance", {})
	var centre := float(cfg.get("centre_bonus", 1.45))
	var edge := float(cfg.get("edge_bonus", 0.75))
	if body_radius <= 0.0:
		return centre
	return lerpf(centre, edge, clampf(offset / accuracy_scale(body_radius), 0.0, 1.0))


static func orb_multiplier(orb_id: String) -> float:
	var orbs: Dictionary = config().get("orbs", {})
	var entry: Variant = orbs.get(orb_id)
	if entry is Dictionary:
		return float((entry as Dictionary).get("multiplier", 1.0))
	return 1.0


## R4.9: the tier ladder. Every orb in `catching.json`'s `orbs` table is a
## real inventory item id (`orb_basic`, `orb_greater`, ...), so this is the
## one place that decides which tier a throw actually uses -- the strongest
## one the player is carrying, never a weaker one left in the same satchel.
##
## `counts` is `{orb_id: n}`. Returns "" if every tier is empty, which the
## caller reads as "no legal throw" the same way `stock() <= 0` already did.
static func best_orb(counts: Dictionary) -> String:
	var orbs: Dictionary = config().get("orbs", {})
	var best_id := ""
	var best_multiplier := -1.0
	for id: String in orbs.keys():
		if int(counts.get(id, 0)) <= 0:
			continue
		var multiplier := orb_multiplier(id)
		if multiplier > best_multiplier:
			best_multiplier = multiplier
			best_id = id
	return best_id


## Every real orb tier id, in `catching.json` order. `throw_aim.gd` reads
## these to know which inventory ids to count -- the tier table is data, so
## nothing in code should ever hard-code a tier's item id.
static func orb_ids() -> Array:
	return config().get("orbs", {}).keys()


## The odds this throw succeeds, in 0..1.
##
## `species_rate` comes from data/creatures/species.json, so a rare creature is data
## rather than a special case in code.
static func catch_chance(
	species_rate: float, hp_fraction: float, orb_id: String,
	offset: float, body_radius: float
) -> float:
	var cfg: Dictionary = config().get("chance", {})
	var raw := species_rate \
		* hp_factor(hp_fraction) \
		* orb_multiplier(orb_id) \
		* accuracy_bonus(offset, body_radius)
	return clampf(raw, float(cfg.get("min", 0.02)), float(cfg.get("max", 0.95)))


## --- the decision ---------------------------------------------------------

## Decide a throw. `roll` is 0..1 and supplied by the caller so tests can pin it
## and a fight stays reproducible.
##
## Returns the whole decision — success, the odds it was decided at, and how many
## times the orb should shake before settling. Everything the presentation layer
## needs is here, so nothing downstream ever has to roll again.
static func resolve(
	species_rate: float, hp_fraction: float, orb_id: String,
	offset: float, body_radius: float, roll: float
) -> Dictionary:
	var chance := catch_chance(species_rate, hp_fraction, orb_id, offset, body_radius)
	var caught := roll < chance
	return {
		"caught": caught,
		"chance": chance,
		"shakes": shakes_for(caught, chance, roll),
	}


## Apply a caller-owned failure bound after the ordinary catch roll.
##
## This does not belong in `resolve()` itself: ordinary catches must retain the
## uncapped geometric odds above. The opening sequence has one explicit content
## promise of its own (docs/specs/OPENING_SEQUENCE.md: its tutorial catch cannot fail
## twice), so CombatManager opts into this helper only for that configured beat
## and species. `prior_failures` counts landed, legal throws; physical misses and
## refusals never call catch resolution and therefore never advance the bound.
##
## The outcome is still decided once, here, before any wobble is performed. If
## the bound converts a failed roll, its shake count is rebuilt from the final
## outcome so the presentation cannot contradict the decision.
static func apply_failure_bound(
	decision: Dictionary, prior_failures: int, max_failures: int
) -> Dictionary:
	var bounded := decision.duplicate()
	if bool(bounded.get("caught", false)) or max_failures < 0 \
			or prior_failures < max_failures:
		return bounded
	bounded["caught"] = true
	bounded["shakes"] = shakes_for(
		true,
		float(bounded.get("chance", 0.0)),
		float(bounded.get("roll", 0.0))
	)
	bounded["failure_bound_applied"] = true
	return bounded


## How many times the orb wobbles before it settles or breaks open.
##
## Derived from the decision, never from a fresh roll. On a failure the count is
## honest information: a throw that came close shakes more times before breaking
## out than a hopeless one, so the wobble tells the player something true about
## how near they were.
static func shakes_for(caught: bool, chance: float, roll: float) -> int:
	var cfg: Dictionary = config().get("resolve", {})
	if caught:
		return int(cfg.get("shakes_on_success", 3))

	var most := int(cfg.get("max_shakes_on_failure", 3))
	if chance <= 0.0:
		return 1
	# How far into the winning range the roll fell. A roll just past the
	# threshold was nearly a catch; one at the far end never had a hope.
	var nearness := clampf(chance / maxf(roll, 0.0001), 0.0, 1.0)
	if nearness >= float(cfg.get("near_miss_threshold", 0.75)):
		return most
	return maxi(1, int(round(nearness * float(most))))


## --- legality -------------------------------------------------------------

## Can this creature be thrown at at all?
##
## Separate from the odds on purpose. §15 says a faint ENDS the capture
## opportunity — that is not "a very low chance", it is a refusal, and the
## player should be told which of the two they are looking at. Rolling a fainted
## target at 2% would eventually catch one.
static func can_be_caught(is_fainted: bool, already_owned: bool) -> bool:
	# Trainer-owned creatures cannot be caught — a hard rule in CLAUDE.md, enforced
	# here so every future path into catching inherits it.
	return not is_fainted and not already_owned


static func starting_stock() -> int:
	return int(config().get("orbs", {}).get("starting_stock", 15))
