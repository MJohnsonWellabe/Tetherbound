extends RefCounted

## T3-ENCOUNTER. The weighted spawn tables, and the roll that turns them into a
## population.
##
## Owner directive, 2026-08-30: *"We should build the new encounter system that
## spawns the creatures randomly, but some of the alphas and such will always get
## placed in the same spots as that's part of the storyline."*
##
## Two populations, one director. A `spawns.json` entry that names a `table` is
## ROLLED -- this file decides which species stands there. An entry with no
## `table` is an ANCHOR and never reaches this file at all. Anchor is the
## default, so a cluster cannot become rolled by accident, only by an edit that
## shows up in a diff.
##
## WORLD-LIFE-0903: a spawn entry may also carry `wander_radius` (metres),
## read by `encounter_director.gd::_spawn_creatures()` and applied to every
## member of that cluster via `wild_creature.gd::configure()`, overriding its
## open-meadow default of 7m. This file never reads that key itself -- rolling
## a species and rolling how far it wanders are independent, and `_apply_plan()`
## duplicates a spawn entry wholesale before overwriting only `species`/`tier`/
## `time`/`weather`/`alpha`, so a rolled cluster keeps its authored
## `wander_radius` exactly as an anchor does.
##
## ## Pure logic, no nodes
##
## Everything here is static and takes its config as an argument, so
## `tests/test_spawn_tables.gd` exercises the whole roll headlessly -- the same
## split `save_game.gd`, `autoload/party.gd` and `chapter_curve.gd` already draw,
## and what docs/decisions/D02 asks for (the suite is pure logic; standing
## creatures on Terrain3D is the smoke tests' job).
##
## ## Determinism, which is the whole design
##
## `plan_for()` is a pure function of `(entries, world_seed, config)`. Two
## properties follow, and both are load-bearing:
##
##   * **Seed 0 is the authored world.** The roller is not entered at all: the
##     plan is empty and every rolled entry stands up its own authored `species`.
##     Every smoke test, every `tools/gate_f/segments/*.json` assertion and every
##     screenshot sees the world it has always seen -- by construction, not by
##     care. Those segments name `bramblebun` 58 times, `meadowhart` 42,
##     `pipwing` 33 and `mudsnout` 21; nothing about them changes.
##   * **A save's world is fixed.** The seed is save state, the plan is derived
##     from it, so reload and re-visit reproduce the same population with no
##     per-creature persistence and nothing to migrate.
##
## The roll draws from its OWN generator, seeded `hash("wild_species_%d_%d")`.
## It never touches the per-cluster `hash("wild_spawn_%d" % order)` rng that
## `encounter_director.gd` spends on scatter position, level, IVs, traits and the
## shiny draw -- so those land on byte-identical numbers at every seed. That
## separation is not tidiness: consuming even one value from the existing
## generator would silently relevel and reroll all 886 creatures in the chapter.

const CONFIG_PATH := "res://data/config/spawn_tables.json"

## The environment override, read once per process. `TB_WORLD_SEED=7 godot ...`
## plays or captures a rolled world without touching save data -- which is how a
## Gate F operator pins a seed, and how this system is usable at all while
## `roll_new_worlds` ships false.
const SEED_ENV_VAR := "TB_WORLD_SEED"

## Seed 0 means "the authored world". Declared rather than typed as a bare
## literal in four places, because it is a contract and not a magic number.
const AUTHORED_SEED := 0

static var _cfg: Dictionary = {}


static func config() -> Dictionary:
	if not _cfg.is_empty():
		return _cfg
	var file := FileAccess.open(CONFIG_PATH, FileAccess.READ)
	if file == null:
		push_error("spawn_tables.json is missing; the rolled population cannot be built")
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		push_error("spawn_tables.json did not parse as a JSON object")
		return {}
	_cfg = parsed
	return _cfg


## The seed this process should use, given whatever the save carried.
##
## The environment wins, so a tool or a Gate F run can pin a world without
## editing save data or config. A non-numeric or absent value leaves the save's
## own seed alone; `TB_WORLD_SEED=0` is a legitimate and useful setting (it
## forces the authored world) so "0" must not read as "unset", which is why this
## checks `has_environment` rather than testing the parsed integer.
static func resolve_seed(save_seed: int) -> int:
	if OS.has_environment(SEED_ENV_VAR):
		var raw := OS.get_environment(SEED_ENV_VAR).strip_edges()
		if raw.is_valid_int():
			return int(raw)
		push_warning("%s='%s' is not an integer; using the save's own world seed" % [SEED_ENV_VAR, raw])
	return save_seed


## Whether a brand-new game should roll itself a seed rather than take 0.
##
## Ships false. See the design note: everything behind this flag is built and
## playable via `TB_WORLD_SEED`, and flipping a global determinism switch is a
## decision to take with T2-GATEF rather than underneath it.
static func rolls_new_worlds(cfg: Dictionary) -> bool:
	return bool(cfg.get("roll_new_worlds", false))


## A fresh world seed for a new game. Never returns `AUTHORED_SEED`, because a
## rolled world that happened to draw 0 would silently be the authored one and
## the player would never know which they had.
static func new_world_seed() -> int:
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	return rng.randi_range(1, 0x7FFFFFFF)


## The weight a tier is worth. Unknown tiers weigh nothing rather than
## defaulting to common: a typo that silently promoted a creature to the
## overwhelming majority of a table is exactly the kind of quiet balance failure
## this repo has paid for before, and `test_spawn_tables.gd` fails on an
## undeclared tier anyway.
static func tier_weight(tier: String, cfg: Dictionary) -> float:
	return float((cfg.get("tiers", {}) as Dictionary).get(tier, 0.0))


static func table(name: String, cfg: Dictionary) -> Dictionary:
	var tables: Dictionary = cfg.get("tables", {}) as Dictionary
	var entry: Variant = tables.get(name, {})
	return entry if entry is Dictionary else {}


## --- the roll ----------------------------------------------------------------


## Decide what stands at every ROLLED cluster, for one world seed.
##
## Returns `{order: {"species": String, "alpha": Dictionary, "time": String,
## "weather": Array}}` -- a plan, keyed by the entry's own `order`, holding only
## the keys that actually apply. An entry absent from the plan stands up its
## authored species unchanged, which is every anchor and (at
## `AUTHORED_SEED`) every rolled entry too.
##
## `entries` is the merged spawn table. `regions_cfg` is `chapter_curve.json`'s
## own config, used to name the region a cluster falls in -- the unit the brief's
## "one major Alpha within a local region at a time" is expressed in.
## `exceptional_species` is the species the caller considers already-exceptional
## (in practice: everything with a `variant_of` in species.json, i.e. the four
## aspect variants), so an ANCHORED Nightburrow spends its region's exceptional
## budget before any roll gets to.
##
## Deliberately one pass over the whole table rather than a decision per cluster
## at spawn time: the caps and the separation rule are global properties, and a
## per-cluster decision cannot see the clusters it has not reached yet. Walking
## in ascending `order` makes the pass deterministic, and `order` is authored and
## reserved per band so nobody else's edit can reorder it.
static func plan_for(
	entries: Array,
	world_seed: int,
	cfg: Dictionary,
	regions_cfg: Dictionary,
	exceptional_species: Array = []
) -> Dictionary:
	if world_seed == AUTHORED_SEED:
		# THE contract. Not an optimisation -- the roller is never entered, so
		# the authored world is reproduced exactly rather than approximately.
		return {}
	if cfg.is_empty():
		return {}

	var ordered := _sorted_by_order(entries)
	var budgets := _authored_budgets(ordered, regions_cfg, exceptional_species)
	var protection: Dictionary = cfg.get("protection", {}) as Dictionary
	var separation := float(protection.get("min_separation_m", 0.0))
	var caps: Dictionary = protection.get("max_per_region", {}) as Dictionary
	var alpha_cap := int(protection.get("alpha_max_per_region", 0))
	var alpha_separation := float(protection.get("alpha_min_separation_m", 0.0))
	var placed_rare: Array = []  # world positions of rare-or-above results so far
	# Authored alphas first: the chapter's own alphas are never the thing a
	# separation rule pushes aside.
	var placed_alphas: Array = _authored_alpha_positions(ordered)

	var plan := {}
	for entry: Variant in ordered:
		var spawn: Dictionary = entry
		var table_name := str(spawn.get("table", ""))
		if table_name == "":
			continue  # an anchor; this file has no opinion about it
		var chosen := table(table_name, cfg)
		if chosen.is_empty():
			push_error("spawns.json order %d names table '%s', which is not in spawn_tables.json" % [
				int(spawn.get("order", -1)), table_name])
			continue

		var order := int(spawn.get("order", -1))
		var centre := _centre_of(spawn)
		var region := _region_id(centre.z, regions_cfg)
		# Its own generator, seeded from (world_seed, order). See this file's
		# header for why it must not be the cluster's own rng.
		var rng := RandomNumberGenerator.new()
		rng.seed = hash("wild_species_%d_%d" % [world_seed, order])

		var pick := _draw(chosen, region, rng, cfg)
		if pick.is_empty():
			continue  # nothing eligible here; the authored species stands
		# Spawn protection, applied after the draw rather than by pre-filtering
		# the table: a rare result that is refused falls back to the common pool
		# instead of leaving a hole in the world, and the fallback is what keeps
		# the population's density exactly what T3-DENSITY authored.
		var tier := str(pick.get("tier", "common"))
		if _is_scarce(tier):
			var spent := int((budgets.get(region, {}) as Dictionary).get(tier, 0))
			var too_many := caps.has(tier) and spent >= int(caps[tier])
			if too_many or _too_close(centre, placed_rare, separation):
				pick = _draw(chosen, region, rng, cfg, true)
				if pick.is_empty():
					continue
				tier = str(pick.get("tier", "common"))
			else:
				_spend(budgets, region, tier)
				placed_rare.append(centre)

		var result := {"species": str(pick.get("species", "")), "tier": tier}
		# A table entry may carry its own presence gate. Nothing in the live
		# tables does today; the pending five all do (see spawn_tables.json's
		# `_pending`), and a rolled cluster that draws a night species has to
		# acquire the night gate or the gate would mean nothing.
		if str(pick.get("time", "")) != "":
			result["time"] = str(pick["time"])
		var weather: Variant = pick.get("weather", [])
		if weather is Array and not (weather as Array).is_empty():
			result["weather"] = (weather as Array).duplicate()

		# The other half of the owner's sentence: the alphas that are NOT
		# authored. Drawn second and always, so the sequence of draws for a given
		# cluster does not depend on which branch the species roll took.
		var alpha_roll := rng.randf()
		if not spawn.has("alpha") and not spawn.has("elder"):
			var alpha_spent := int((budgets.get(region, {}) as Dictionary).get("alpha", 0))
			var chance := float(chosen.get("alpha_chance", 0.0))
			# The separation, not the cap, is what actually expresses the brief's
			# "one major Alpha within a local region at a time" -- see
			# spawn_tables.json's `_comment_alpha_separation` for the measurement
			# that decided it.
			if alpha_roll < chance and alpha_spent < alpha_cap \
					and not _too_close(centre, placed_alphas, alpha_separation):
				result["alpha"] = (cfg.get("alpha_promotion", {}) as Dictionary).duplicate()
				_spend(budgets, region, "alpha")
				placed_alphas.append(centre)

		plan[order] = result
	return plan


## Count what the AUTHORED world already spends, before any roll is made.
##
## This is the mechanism behind "one major Alpha within a local region at a time"
## and behind the rare caps: an anchored alpha, elder or aspect variant occupies
## its region's budget, so a rolled one can never crowd the individual the story
## put there. Counted from the same merged table the roll walks, so an entry
## added by another lane is counted automatically.
static func _authored_budgets(ordered: Array, regions_cfg: Dictionary, exceptional_species: Array) -> Dictionary:
	var budgets := {}
	for entry: Variant in ordered:
		var spawn: Dictionary = entry
		if str(spawn.get("table", "")) != "":
			continue  # rolled; it has not spent anything yet
		var region := _region_id(_centre_of(spawn).z, regions_cfg)
		if spawn.has("alpha") or spawn.has("elder"):
			_spend(budgets, region, "alpha")
		if exceptional_species.has(str(spawn.get("species", ""))):
			_spend(budgets, region, "exceptional")
	return budgets


## Where the AUTHORED alphas stand, for the separation rule below.
##
## Seeded before any roll for the same reason the budgets are: an authored alpha
## is the story's, and the roll gives way to it rather than the other way round.
static func _authored_alpha_positions(ordered: Array) -> Array:
	var out: Array = []
	for entry: Variant in ordered:
		var spawn: Dictionary = entry
		if str(spawn.get("table", "")) != "":
			continue
		if spawn.has("alpha") or spawn.has("elder"):
			out.append(_centre_of(spawn))
	return out


## Weighted draw over the table's eligible entries.
##
## `commons_only` is the fallback path a refused rare result takes. Eligibility
## is the brief's hard gates: an entry's `regions` list is a geographic
## restriction, and an unknown tier weighs nothing so it can never be drawn.
##
## Walks the table's authored array order, so the same rng state always produces
## the same answer -- a Dictionary iteration order would not promise that.
static func _draw(
	chosen: Dictionary, region: String, rng: RandomNumberGenerator,
	cfg: Dictionary, commons_only: bool = false
) -> Dictionary:
	var eligible: Array = []
	var total := 0.0
	for entry: Variant in (chosen.get("entries", []) as Array):
		var candidate: Dictionary = entry
		var tier := str(candidate.get("tier", ""))
		if commons_only and _is_scarce(tier):
			continue
		var regions: Variant = candidate.get("regions", [])
		if regions is Array and not (regions as Array).is_empty() \
				and not (regions as Array).has(region):
			continue
		var weight := tier_weight(tier, cfg)
		if weight <= 0.0:
			continue
		eligible.append({"entry": candidate, "weight": weight})
		total += weight
	if eligible.is_empty() or total <= 0.0:
		return {}
	var roll := rng.randf() * total
	for item: Variant in eligible:
		roll -= float((item as Dictionary)["weight"])
		if roll <= 0.0:
			return (item as Dictionary)["entry"]
	# Floating-point residue only; the last eligible entry is the right answer.
	return (eligible[eligible.size() - 1] as Dictionary)["entry"]


## Rare and above. The tiers the caps and the separation rule apply to -- and the
## direct answer to the owner's named failure, "the player walks through one
## clearing and sees Sparkit + Cindercub + Shadelet + Frostclaw + Nightburrow".
static func _is_scarce(tier: String) -> bool:
	return tier == "rare" or tier == "exceptional"


static func _too_close(centre: Vector3, placed: Array, separation: float) -> bool:
	if separation <= 0.0:
		return false
	for other: Variant in placed:
		if centre.distance_to(other as Vector3) < separation:
			return true
	return false


static func _spend(budgets: Dictionary, region: String, key: String) -> void:
	if not budgets.has(region):
		budgets[region] = {}
	var region_budget: Dictionary = budgets[region]
	region_budget[key] = int(region_budget.get(key, 0)) + 1


static func _region_id(z: float, regions_cfg: Dictionary) -> String:
	var list: Array = regions_cfg.get("regions", []) as Array
	if list.is_empty():
		return ""
	for entry: Variant in list:
		var region: Dictionary = entry
		if z < float(region.get("z_to", 0.0)):
			return str(region.get("id", ""))
	return str((list[list.size() - 1] as Dictionary).get("id", ""))


static func _centre_of(spawn: Dictionary) -> Vector3:
	var raw: Variant = spawn.get("centre", [])
	var list: Array = raw if raw is Array else []
	if list.size() < 3:
		return Vector3.ZERO
	return Vector3(float(list[0]), float(list[1]), float(list[2]))


## Ascending `order`, which is the only stable identity a spawn entry has: it is
## authored, reserved per band, and unique across the whole merged table
## (`tests/test_band_content.gd::test_order_is_unique_across_every_band` pins
## that). Sorting here rather than trusting the merge means the plan is the same
## whatever order the caller hands entries over in.
static func _sorted_by_order(entries: Array) -> Array:
	var ordered := entries.duplicate()
	ordered.sort_custom(func(a: Variant, b: Variant) -> bool:
		return int((a as Dictionary).get("order", 0)) < int((b as Dictionary).get("order", 0)))
	return ordered
