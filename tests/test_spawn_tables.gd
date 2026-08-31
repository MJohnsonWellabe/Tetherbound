extends "res://tests/test_case.gd"

## T3-ENCOUNTER. The weighted spawn tables and the roll that builds a population
## from them (`scripts/combat/spawn_tables.gd`, `data/config/spawn_tables.json`).
##
## Every failure this file guards is silent at run time, in the same way
## `test_spawns_data.gd`'s own header describes: a table naming a species that
## does not exist, a tier that weighs nothing, a rare creature saturating a
## region, a starter appearing in the ordinary wild population, or -- the one
## that would actually hurt -- the authored world seed no longer reproducing the
## authored world. None of them crash. All of them are found weeks later as "the
## meadow feels wrong", with nothing in any diff to point at.
##
## Pure logic, per docs/decisions/D02: `spawn_tables.gd` is entirely static and
## takes its config as an argument, so the whole roll is exercised here without a
## scene tree. Standing the result on Terrain3D is the smoke tests' job.

const SPAWN_TABLES := preload("res://scripts/combat/spawn_tables.gd")
const BAND_CONTENT := preload("res://scripts/data/band_content.gd")
const SPECIES := preload("res://scripts/creatures/creature_species.gd")
const CHAPTER_CURVE := preload("res://scripts/creatures/chapter_curve.gd")

const SPAWNS_PATH := "res://data/config/spawns.json"
const WEATHER_PATH := "res://data/config/weather.json"
const STARTER_SPECIES := ["terrapup", "ripplet", "galewisp"]

## Arbitrary non-zero seeds. Several, because a property that holds for one seed
## and not for another is exactly the kind of thing a single-seed test misses --
## the caps and the separation rule in particular only bind on the draws that
## actually produce a scarce result.
const SEEDS := [1, 7, 42, 1337, 90210, 2026083]


func _cfg() -> Dictionary:
	return SPAWN_TABLES.config()


func _spawns() -> Array:
	return BAND_CONTENT.load_config(SPAWNS_PATH, "spawns").get("spawns", []) as Array


func _curve() -> Dictionary:
	return CHAPTER_CURVE.config()


## Every species carrying `variant_of` -- the four aspect variants T3-CREATURES
## landed. The director derives this the same way; see its `_spawn_plan()`.
func _exceptional_species() -> Array:
	var out: Array = []
	for id: Variant in SPECIES.table():
		if str(id).begins_with("_"):
			continue
		if SPECIES.definition(str(id)).has("variant_of"):
			out.append(str(id))
	return out


func _plan(world_seed: int) -> Dictionary:
	return SPAWN_TABLES.plan_for(
		_spawns(), world_seed, _cfg(), _curve(), _exceptional_species())


func _table_species() -> Array[String]:
	var out: Array[String] = []
	for name: Variant in (_cfg().get("tables", {}) as Dictionary):
		if str(name).begins_with("_"):
			continue
		for entry: Variant in (SPAWN_TABLES.table(str(name), _cfg()).get("entries", []) as Array):
			var id := str((entry as Dictionary).get("species", ""))
			if not out.has(id):
				out.append(id)
	return out


func _weather_presets() -> Dictionary:
	var file := FileAccess.open(WEATHER_PATH, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	return (parsed as Dictionary).get("presets", {}) if parsed is Dictionary else {}


func _region_of(z: float) -> String:
	return str(CHAPTER_CURVE.region_at(z, _curve()).get("id", ""))


func _entry_by_order() -> Dictionary:
	var out := {}
	for entry: Variant in _spawns():
		out[int((entry as Dictionary).get("order", -1))] = entry
	return out


# --- the tables are well-formed ----------------------------------------------

func test_the_config_loads_and_declares_tables() -> void:
	assert_false(_cfg().is_empty(), "spawn_tables.json is missing or did not parse")
	var tables: Dictionary = _cfg().get("tables", {}) as Dictionary
	assert_false(tables.is_empty(), "spawn_tables.json declares no tables; nothing could ever roll")


func test_every_table_species_is_in_the_species_table() -> void:
	# The rename that breaks this is silent: the roll hands the director a
	# species id it push_errors on and skips, and the cluster is simply not in
	# the world -- the same failure `test_spawns_data.gd` guards for the
	# authored half of the population.
	for id: String in _table_species():
		assert_true(SPECIES.has(id),
			"a spawn table names '%s', which is not in species.json" % id)


func test_every_table_entry_declares_a_tier_that_carries_weight() -> void:
	# A misspelt tier weighs nothing (`tier_weight` deliberately does not fall
	# back to common), so the species would silently never roll. That is the
	# quiet half of the failure; this is the loud half.
	var tiers: Dictionary = _cfg().get("tiers", {}) as Dictionary
	assert_false(tiers.is_empty(), "spawn_tables.json declares no tier weights")
	for name: Variant in (_cfg().get("tables", {}) as Dictionary):
		if str(name).begins_with("_"):
			continue
		var entries: Array = SPAWN_TABLES.table(str(name), _cfg()).get("entries", []) as Array
		assert_false(entries.is_empty(), "table '%s' has no entries" % str(name))
		for entry: Variant in entries:
			var spawn: Dictionary = entry
			var tier := str(spawn.get("tier", ""))
			assert_true(tiers.has(tier),
				"table '%s' entry '%s' has tier '%s', which is not declared in `tiers`" % [
					str(name), str(spawn.get("species", "?")), tier])
			assert_true(SPAWN_TABLES.tier_weight(tier, _cfg()) > 0.0,
				"tier '%s' weighs zero; anything using it can never be drawn" % tier)


func test_the_tier_weights_land_inside_the_owner_s_own_rarity_bands() -> void:
	# The owner's brief ("Core Rarity Structure") asks for Uncommon at 5-10% of
	# eligible habitat encounters, Rare at 1-3%, Exceptional well below 1%. Those
	# are percentages of a table's eligible weight -- which is the denominator
	# this whole system exists to supply, so it is worth pinning that the numbers
	# actually shipped satisfy the brief rather than merely being labelled.
	#
	# Measured against a representative table shape of three commons plus two
	# uncommons, which is what the live tables are.
	var common := SPAWN_TABLES.tier_weight("common", _cfg())
	var uncommon := SPAWN_TABLES.tier_weight("uncommon", _cfg())
	var base := 3.0 * common + 2.0 * uncommon
	assert_between(uncommon / base * 100.0, 5.0, 10.0,
		"an uncommon species must sit in the brief's 5-10%% band of eligible encounters")
	assert_between(SPAWN_TABLES.tier_weight("rare", _cfg()) / (base + SPAWN_TABLES.tier_weight("rare", _cfg())) * 100.0,
		1.0, 3.0, "a rare species must sit in the brief's 1-3%% band")
	assert_true(SPAWN_TABLES.tier_weight("exceptional", _cfg()) / (base + SPAWN_TABLES.tier_weight("exceptional", _cfg())) * 100.0 < 1.0,
		"an exceptional species must sit 'well below 1%' per the brief")


func test_no_starter_species_can_be_rolled() -> void:
	# The counterpart to `test_spawns_data.gd`'s own starter pin, and the reason
	# that one is no longer sufficient on its own: it reads the TABLE, and the
	# table is no longer the whole population. A starter reachable in the
	# ordinary wild would break the First-Hour Fun Rebuild's rule that the first
	# creature of each starter species is the opening choice.
	for id: String in _table_species():
		assert_false(STARTER_SPECIES.has(id),
			"'%s' is a starter species and must not be rollable in the ordinary wild population" % id)


func test_no_evolved_form_can_be_rolled() -> void:
	# D20 generalised: anything with an `evolves_from` is somebody's reward, not
	# part of the wild population. Same extension of the same rule to the rolled
	# half.
	for id: String in _table_species():
		assert_false(SPECIES.definition(id).has("evolves_from"),
			"'%s' is an evolved form and can be rolled wild; evolutions are earned, not encountered (D20)" % id)


func test_no_aspect_variant_can_be_rolled() -> void:
	# The owner's brief prefers "authored or semi-authored spawn logic over
	# random saturation" for the Exceptional/Alpha tier, and T3-CREATURES placed
	# all four aspect variants deliberately -- Nightburrow one individual in the
	# whole chapter, at night, in the deep warrens. Letting the roller also
	# produce them would be exactly the saturation the brief forbids.
	for id: String in _exceptional_species():
		assert_false(_table_species().has(id),
			"'%s' is an aspect variant and is placed by hand; it must not also be rollable" % id)


func test_every_table_weather_gate_names_a_real_preset() -> void:
	# Silent at runtime for the identical reason `test_spawns_data.gd` gives for
	# the authored half: the director's `Array.has()` just never matches, and the
	# creature never spawns for any weather at all.
	var presets := _weather_presets()
	for name: Variant in (_cfg().get("tables", {}) as Dictionary):
		if str(name).begins_with("_"):
			continue
		for entry: Variant in (SPAWN_TABLES.table(str(name), _cfg()).get("entries", []) as Array):
			var gate: Variant = (entry as Dictionary).get("weather", [])
			if not (gate is Array):
				continue
			for preset: Variant in gate as Array:
				assert_true(presets.has(str(preset)),
					"table '%s' gates '%s' on weather '%s', which is not a preset in weather.json" % [
						str(name), str((entry as Dictionary).get("species", "?")), str(preset)])


func test_every_table_region_gate_names_a_real_region() -> void:
	var known: Array[String] = []
	for entry: Variant in CHAPTER_CURVE.regions(_curve()):
		known.append(str((entry as Dictionary).get("id", "")))
	for name: Variant in (_cfg().get("tables", {}) as Dictionary):
		if str(name).begins_with("_"):
			continue
		for entry: Variant in (SPAWN_TABLES.table(str(name), _cfg()).get("entries", []) as Array):
			var regions: Variant = (entry as Dictionary).get("regions", [])
			if not (regions is Array):
				continue
			for region: Variant in regions as Array:
				assert_true(known.has(str(region)),
					"table '%s' gates '%s' to region '%s', which chapter_curve.json does not declare" % [
						str(name), str((entry as Dictionary).get("species", "?")), str(region)])


func test_every_rolled_spawn_entry_names_a_table_that_exists() -> void:
	# A typo here means the director push_errors and the cluster silently falls
	# back to its authored species -- which looks exactly like a working world,
	# for that cluster, forever.
	for entry: Variant in _spawns():
		var spawn: Dictionary = entry
		var name := str(spawn.get("table", ""))
		if name == "":
			continue
		assert_false(SPAWN_TABLES.table(name, _cfg()).is_empty(),
			"spawns.json order %d names table '%s', which spawn_tables.json does not declare" % [
				int(spawn.get("order", -1)), name])


# --- determinism, which is the whole design ----------------------------------

func test_the_authored_seed_reproduces_the_authored_world() -> void:
	# THE load-bearing test of this lane. Seed 0 must not merely "usually" leave
	# the world alone -- the roller must not be entered at all, so that every
	# smoke test, every tools/gate_f/segments/*.json species assertion and every
	# existing save sees the exact meadow it has always seen.
	#
	# Those segments name `bramblebun` 58 times, `meadowhart` 42, `pipwing` 33
	# and `mudsnout` 21. This assertion is what says none of them moved.
	assert_true(_plan(SPAWN_TABLES.AUTHORED_SEED).is_empty(),
		"the authored world seed produced a non-empty roll plan; seed 0 must leave every cluster alone")


func test_the_same_seed_builds_the_same_world_twice() -> void:
	# A save carries its seed and derives its population from it, so this is what
	# makes reload return the player to the world they left -- and what lets a
	# Gate F run at a pinned seed be reproducible evidence.
	for world_seed: int in SEEDS:
		var first := _plan(world_seed)
		var second := _plan(world_seed)
		assert_eq(first.size(), second.size(),
			"seed %d produced two different plan sizes" % world_seed)
		for order: Variant in first:
			assert_eq(str((first[order] as Dictionary).get("species", "")),
				str((second[order] as Dictionary).get("species", "")),
				"seed %d rolled order %s differently on a second pass" % [world_seed, str(order)])


func test_different_seeds_build_different_worlds() -> void:
	# The owner's actual ask. A roll that produced the same population for every
	# seed would pass every other test in this file.
	var baseline := _plan(SEEDS[0])
	var any_different := false
	for world_seed: int in SEEDS.slice(1):
		var other := _plan(world_seed)
		for order: Variant in baseline:
			if str((baseline[order] as Dictionary).get("species", "")) \
					!= str((other.get(order, {}) as Dictionary).get("species", "")):
				any_different = true
	assert_true(any_different,
		"every seed produced an identical population; the roll is not actually rolling")


func test_a_rolled_world_actually_moves_most_of_the_population() -> void:
	# Guards the opposite failure from the one above: a roll that technically
	# differs but leaves 99% of clusters on their authored species would look
	# like variety in a test and like nothing at all in play.
	var plan := _plan(SEEDS[1])
	var authored := _entry_by_order()
	var changed := 0
	for order: Variant in plan:
		if str((plan[order] as Dictionary).get("species", "")) \
				!= str((authored.get(order, {}) as Dictionary).get("species", "")):
			changed += 1
	assert_true(changed >= plan.size() / 4,
		"only %d of %d rolled clusters changed species; the population barely moves" % [
			changed, plan.size()])


func test_the_plan_only_ever_touches_clusters_that_opted_in() -> void:
	# Anchor is the default and the plan must respect it: an entry with no
	# `table` carries authored design -- an alpha, an elder, a gate, a role, a
	# test pin -- and the roller has no opinion about it.
	var authored := _entry_by_order()
	for world_seed: int in SEEDS:
		for order: Variant in _plan(world_seed):
			var entry: Dictionary = authored.get(order, {})
			assert_ne(str(entry.get("table", "")), "",
				"seed %d rolled order %s, which named no table and is an anchor" % [world_seed, str(order)])


func test_a_rolled_cluster_keeps_its_position_count_and_order() -> void:
	# The plan carries species (and optionally a gate, an alpha and -- Audit
	# B3 -- the tier the species was drawn at, so presentation can read it)
	# and nothing else. Position, headcount and `order` are the inputs the
	# cluster's own seeded rng derives scatter, level, IVs, traits and the
	# shiny draw from, and a roll that moved any of them would relevel and
	# reroll the chapter.
	for world_seed: int in SEEDS:
		for order: Variant in _plan(world_seed):
			var rolled: Dictionary = _plan(world_seed)[order]
			for key: Variant in rolled:
				assert_true(str(key) in ["species", "tier", "alpha", "time", "weather"],
					"the roll plan carried '%s' for order %s; it may only decide species, tier, gate and alpha" % [
						str(key), str(order)])


# --- spawn protection --------------------------------------------------------

func test_no_region_exceeds_its_scarce_tier_caps() -> void:
	# The brief's Spawn Protection Rules, as a check rather than as an intention.
	var caps: Dictionary = (_cfg().get("protection", {}) as Dictionary).get("max_per_region", {}) as Dictionary
	var authored := _entry_by_order()
	for world_seed: int in SEEDS:
		var counts := {}
		for order: Variant in _plan(world_seed):
			var species := str((_plan(world_seed)[order] as Dictionary).get("species", ""))
			var tier := _tier_of(species, str((authored[order] as Dictionary).get("table", "")))
			if not (tier == "rare" or tier == "exceptional"):
				continue
			var region := _region_of(_centre_z(authored[order]))
			var key := "%s/%s" % [region, tier]
			counts[key] = int(counts.get(key, 0)) + 1
			assert_true(counts[key] <= int(caps.get(tier, 99)),
				"seed %d put %d '%s' clusters in %s; the cap is %d" % [
					world_seed, int(counts[key]), tier, region, int(caps.get(tier, 99))])


func test_two_scarce_encounters_are_never_in_the_same_clearing() -> void:
	# The owner named this failure directly: "Avoid a situation where the player
	# walks through one clearing and sees Sparkit + Cindercub + Shadelet +
	# Frostclaw + Nightburrow. That would destroy the rarity."
	var separation := float((_cfg().get("protection", {}) as Dictionary).get("min_separation_m", 0.0))
	assert_true(separation > 0.0, "spawn_tables.json declares no minimum separation for scarce spawns")
	var authored := _entry_by_order()
	for world_seed: int in SEEDS:
		var placed: Array[Vector3] = []
		for order: Variant in _plan(world_seed):
			var species := str((_plan(world_seed)[order] as Dictionary).get("species", ""))
			if not _tier_of(species, str((authored[order] as Dictionary).get("table", ""))) in ["rare", "exceptional"]:
				continue
			var at := _centre_of(authored[order])
			for other: Vector3 in placed:
				assert_true(at.distance_to(other) >= separation,
					"seed %d put two scarce encounters %.0fm apart; the floor is %.0fm" % [
						world_seed, at.distance_to(other), separation])
			placed.append(at)


func test_a_rolled_alpha_never_crowds_an_authored_one() -> void:
	# The owner's sentence has two halves and this is the second: "some of the
	# alphas and such will always get placed in the same spots as that's part of
	# the storyline". An authored alpha spends its region's budget FIRST, so the
	# roll can only ever fill what the story left free.
	var cap := int((_cfg().get("protection", {}) as Dictionary).get("alpha_max_per_region", 0))
	assert_true(cap > 0, "spawn_tables.json declares no per-region alpha cap")
	var authored := _entry_by_order()
	for world_seed: int in SEEDS:
		var counts := {}
		for entry: Variant in _spawns():
			var spawn: Dictionary = entry
			if not (spawn.has("alpha") or spawn.has("elder")):
				continue
			var region := _region_of(_centre_z(spawn))
			counts[region] = int(counts.get(region, 0)) + 1
		var plan := _plan(world_seed)
		for order: Variant in plan:
			if not (plan[order] as Dictionary).has("alpha"):
				continue
			var region := _region_of(_centre_z(authored[order]))
			counts[region] = int(counts.get(region, 0)) + 1
			assert_true(int(counts[region]) <= cap,
				"seed %d put %d alphas in %s; the cap is %d" % [
					world_seed, int(counts[region]), region, cap])


func test_a_rolled_alpha_is_never_crowded_against_another_alpha() -> void:
	# The brief's "one major Alpha within a local region at a time", expressed as
	# distance rather than as a per-band count -- because the authored chapter
	# puts two of its own alphas 67m apart, so a cap tight enough to mean "one
	# per region" would either be violated by the authored world or would refuse
	# every rolled alpha outside Band 1. Authored alphas are the fixed points; a
	# ROLLED one has to stand clear of all of them and of each other.
	var separation := float((_cfg().get("protection", {}) as Dictionary).get("alpha_min_separation_m", 0.0))
	assert_true(separation > 0.0, "spawn_tables.json declares no minimum separation between alphas")
	var authored := _entry_by_order()
	for world_seed: int in SEEDS:
		var plan := _plan(world_seed)
		var fixed: Array[Vector3] = []
		for entry: Variant in _spawns():
			var spawn: Dictionary = entry
			if spawn.has("alpha") or spawn.has("elder"):
				fixed.append(_centre_of(spawn))
		for order: Variant in plan:
			if not (plan[order] as Dictionary).has("alpha"):
				continue
			var at := _centre_of(authored[order])
			for other: Vector3 in fixed:
				assert_true(at.distance_to(other) >= separation,
					"seed %d promoted an alpha at order %s, %.0fm from another alpha; the floor is %.0fm" % [
						world_seed, str(order), at.distance_to(other), separation])
			fixed.append(at)


func test_a_rolled_alpha_never_lands_on_a_cluster_that_authored_its_own() -> void:
	# The owner's own words -- "some of the alphas and such will always get
	# placed in the same spots as that's part of the storyline". An authored
	# alpha block is that promise, and a promotion that overwrote one would break
	# it silently, since both end up as an `alpha` key on the same entry.
	var authored := _entry_by_order()
	for world_seed: int in SEEDS:
		var plan := _plan(world_seed)
		for order: Variant in plan:
			if not (plan[order] as Dictionary).has("alpha"):
				continue
			var spawn: Dictionary = authored[order]
			assert_false(spawn.has("alpha") or spawn.has("elder"),
				"seed %d promoted order %s, which already authors its own alpha/elder" % [
					world_seed, str(order)])


func test_a_rolled_world_is_still_the_ground_dominant_meadows() -> void:
	# The brief's Population Philosophy is a constraint on the whole system, not
	# a note: "The Meadows should still visually read as: Ground biome with ponds,
	# waterways and flying wildlife", and "A normal traversal through the Meadows
	# should mostly show Ground creatures, Water creatures near water, and Air
	# creatures overhead."
	#
	# A rolled population is exactly the thing that could drift that without
	# anybody editing a species entry, and no other test in the repo would notice.
	# Measured against the authored world's own shape (60.0% ground / 36.2% air /
	# 3.7% water, T3-CREATURES handover 7.5) with room for a roll to move it.
	var authored := _entry_by_order()
	for world_seed: int in SEEDS:
		var plan := _plan(world_seed)
		var by_type := {"ground": 0, "air": 0, "water": 0}
		var population := 0
		for entry: Variant in _spawns():
			var spawn: Dictionary = entry
			var order := int(spawn.get("order", -1))
			var species := str((plan.get(order, {}) as Dictionary).get("species", spawn.get("species", "")))
			var creature_type := str(SPECIES.definition(species).get("type", ""))
			var count := int(spawn.get("count", 1))
			population += count
			if by_type.has(creature_type):
				by_type[creature_type] = int(by_type[creature_type]) + count
		assert_true(population > 0, "seed %d produced no population at all" % world_seed)
		var ground_share := float(by_type["ground"]) / float(population) * 100.0
		assert_true(ground_share >= 50.0,
			"seed %d left the Meadows only %.1f%% Ground; the brief keeps this the Ground-dominant biome" % [
				world_seed, ground_share])
		assert_true(float(by_type["air"]) / float(population) * 100.0 <= 45.0,
			"seed %d filled %.1f%% of the Meadows with Air creatures" % [
				world_seed, float(by_type["air"]) / float(population) * 100.0])


func test_a_rolled_world_keeps_the_same_headcount() -> void:
	# Density is T3-DENSITY's file and its problem. The roll decides WHAT stands
	# at a cluster and never HOW MANY, so the chapter's authored 886 must survive
	# every seed untouched -- a roll that also moved density would silently
	# undo another lane's tuning pass.
	var authored_population := 0
	for entry: Variant in _spawns():
		authored_population += int((entry as Dictionary).get("count", 1))
	for world_seed: int in SEEDS:
		var population := 0
		var plan := _plan(world_seed)
		for entry: Variant in _spawns():
			var spawn: Dictionary = entry
			# The plan carries no `count`; this reads the authored one back for
			# every cluster, rolled or not, which is the property under test.
			assert_false((plan.get(int(spawn.get("order", -1)), {}) as Dictionary).has("count"),
				"seed %d rolled a headcount; density is not this system's to change" % world_seed)
			population += int(spawn.get("count", 1))
		assert_eq(population, authored_population,
			"seed %d changed the chapter's wild headcount" % world_seed)


func test_a_rolled_species_never_appears_in_a_region_its_table_excludes() -> void:
	# The brief's geographic restriction, enforced rather than intended. Band 1
	# in particular must keep its gentle roster: no burrowback strays onto the
	# opening meadow, and the chapter's aggressive flier stays in the later
	# regions where the ambush was authored.
	var authored := _entry_by_order()
	for world_seed: int in SEEDS:
		var plan := _plan(world_seed)
		for order: Variant in plan:
			var species := str((plan[order] as Dictionary).get("species", ""))
			var table_name := str((authored[order] as Dictionary).get("table", ""))
			var region := _region_of(_centre_z(authored[order]))
			for entry: Variant in (SPAWN_TABLES.table(table_name, _cfg()).get("entries", []) as Array):
				var candidate: Dictionary = entry
				if str(candidate.get("species", "")) != species:
					continue
				var regions: Variant = candidate.get("regions", [])
				if regions is Array and not (regions as Array).is_empty():
					assert_true((regions as Array).has(region),
						"seed %d rolled '%s' into %s, which table '%s' does not allow it in" % [
							world_seed, species, region, table_name])


# --- the seed plumbing -------------------------------------------------------

func test_a_new_world_seed_is_never_the_authored_one() -> void:
	# A rolled world that happened to draw 0 would silently be the authored one,
	# and the player would have no way to tell which they had.
	for _i in 50:
		assert_ne(SPAWN_TABLES.new_world_seed(), SPAWN_TABLES.AUTHORED_SEED,
			"new_world_seed() returned the authored seed")


func test_the_new_world_flag_is_a_declared_boolean() -> void:
	# It ships false on purpose (see the design note). What must not happen is
	# that it goes missing and the default silently becomes something else.
	assert_true(_cfg().has("roll_new_worlds"),
		"spawn_tables.json no longer declares `roll_new_worlds`; new games would take an undeclared default")
	assert_eq(typeof(_cfg()["roll_new_worlds"]), TYPE_BOOL,
		"`roll_new_worlds` must be a boolean")


func test_a_save_seed_survives_resolution_when_nothing_overrides_it() -> void:
	# `TB_WORLD_SEED` cannot be set from inside a running Godot process, so the
	# override branch is exercised by running the suite with it set rather than
	# from here. What IS checkable here is the branch every ordinary boot takes:
	# with no override, the save's own seed is what the world is built from.
	if OS.has_environment(SPAWN_TABLES.SEED_ENV_VAR):
		return  # a deliberately seeded run; the override is the thing under test there
	for candidate: int in [0, 1, 4242]:
		assert_eq(SPAWN_TABLES.resolve_seed(candidate), candidate,
			"resolve_seed changed the save's own world seed with no override present")


# --- helpers -----------------------------------------------------------------

func _centre_of(spawn: Dictionary) -> Vector3:
	var raw: Variant = spawn.get("centre", [])
	var list: Array = raw if raw is Array else []
	if list.size() < 3:
		return Vector3.ZERO
	return Vector3(float(list[0]), float(list[1]), float(list[2]))


func _centre_z(spawn: Dictionary) -> float:
	return _centre_of(spawn).z


func _tier_of(species: String, table_name: String) -> String:
	for entry: Variant in (SPAWN_TABLES.table(table_name, _cfg()).get("entries", []) as Array):
		if str((entry as Dictionary).get("species", "")) == species:
			return str((entry as Dictionary).get("tier", ""))
	return ""
