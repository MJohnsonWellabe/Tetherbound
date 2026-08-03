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
## ALLOWED, and full-health pals must be EXTREMELY difficult. So this returns a
## small number rather than zero at full health, and rises to 1 at a sliver.
##
## The curve is back-loaded (exponent above 1) so that chipping a pal to half
## buys much less than taking it to a sliver. That is what keeps "damage it
## first" a genuine risk against "over-damage it and lose the catch entirely".
static func hp_factor(hp_fraction: float) -> float:
	var cfg: Dictionary = config().get("chance", {})
	var full := float(cfg.get("hp_factor_full", 0.10))
	var empty := float(cfg.get("hp_factor_empty", 1.0))
	var curve := maxf(float(cfg.get("hp_curve", 1.6)), 0.01)
	var hurt := pow(clampf(1.0 - hp_fraction, 0.0, 1.0), curve)
	return lerpf(full, empty, hurt)


## What a throw's placement is worth, from how far off centre it struck.
##
## `offset` is metres from the target's centre of mass; `body_radius` is what
## counts as a clean hit. A dead-centre strike is worth `centre_bonus`, a hit
## that barely clipped the edge is worth `edge_bonus`.
##
## If those two were equal, aiming would be decoration and this milestone would
## have no subject. tests/test_catch_math.gd asserts they are not.
static func accuracy_bonus(offset: float, body_radius: float) -> float:
	var cfg: Dictionary = config().get("chance", {})
	var centre := float(cfg.get("centre_bonus", 1.45))
	var edge := float(cfg.get("edge_bonus", 0.75))
	if body_radius <= 0.0:
		return centre
	return lerpf(centre, edge, clampf(offset / body_radius, 0.0, 1.0))


static func orb_multiplier(orb_id: String) -> float:
	var orbs: Dictionary = config().get("orbs", {})
	var entry: Variant = orbs.get(orb_id)
	if entry is Dictionary:
		return float((entry as Dictionary).get("multiplier", 1.0))
	return 1.0


## The odds this throw succeeds, in 0..1.
##
## `species_rate` comes from data/pals/species.json, so a rare creature is data
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
	# Trainer-owned pals cannot be caught — a hard rule in CLAUDE.md, enforced
	# here so every future path into catching inherits it.
	return not is_fainted and not already_owned


static func starting_stock() -> int:
	return int(config().get("orbs", {}).get("starting_stock", 15))
