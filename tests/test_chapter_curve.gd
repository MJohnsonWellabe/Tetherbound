extends "res://tests/test_case.gd"

## GATEC-CURVE. data/config/chapter_curve.json -- the chapter's progression
## curve, and the checks that keep the authored content in the five band
## directories honest against it.
##
## Every failure here is silent at run time, which is why it is worth a build.
## A trainer authored two levels too low, a wild band that stops escalating, a
## region whose field creatures out-level the boss they lead to: none of them
## crash, none of them show up in a screenshot, and all of them are only
## noticed by playing the whole 3-4 hour chapter and feeling that an hour of it
## went flat. That is the most expensive way this repo has of finding a bug.
##
## The five-slot assertions are here rather than in a party test on purpose.
## `autoload/party.gd` already proves the cap is five and cannot be six
## (tests/test_party.gd); what nothing proved was that the cap still MEANS
## anything in the back half of the chapter, and that is a curve property --
## a creature caught twelve levels below the team it would join is not a
## choice, it is a decline.

const CURVE := preload("res://scripts/creatures/chapter_curve.gd")
const PROGRESSION := preload("res://scripts/creatures/progression.gd")
const PARTY := preload("res://autoload/party.gd")
const BAND_CONTENT := preload("res://scripts/data/band_content.gd")
const PERIMETER := preload("res://scripts/world/world_perimeter.gd")

const SPAWNS_PATH := "res://data/config/spawns.json"
const TRAINERS_PATH := "res://data/config/trainers.json"
const WARRENS_PATH := "res://data/config/burrow_warrens.json"


func _curve() -> Dictionary:
	return CURVE.config()


func _regions() -> Array:
	return CURVE.regions(_curve())


func _team(region: Dictionary) -> Dictionary:
	return region.get("team", {}) as Dictionary


func _five_slot() -> Dictionary:
	return _curve().get("five_slot", {}) as Dictionary


func _spawns() -> Array:
	return BAND_CONTENT.load_config(SPAWNS_PATH, "spawns").get("spawns", []) as Array


func _trainers() -> Array:
	return BAND_CONTENT.load_config(TRAINERS_PATH, "trainers").get("trainers", []) as Array


func _warrens() -> Dictionary:
	var file := FileAccess.open(WARRENS_PATH, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	return parsed if parsed is Dictionary else {}


# --- the table itself --------------------------------------------------------

func test_the_curve_covers_every_corridor_band() -> void:
	var ids: Array = []
	for entry: Variant in _regions():
		ids.append(str((entry as Dictionary).get("id", "")))
	assert_eq(ids.size(), BAND_CONTENT.BANDS.size(),
		"the curve has %d regions against the corridor's %d bands" % [ids.size(), BAND_CONTENT.BANDS.size()])
	for band: String in BAND_CONTENT.BANDS:
		assert_true(ids.has(band),
			"corridor band '%s' has no row in chapter_curve.json; content authored there has no strength to sit inside" % band)


func test_every_region_states_a_team_band_and_a_wild_band() -> void:
	for entry: Variant in _regions():
		var region: Dictionary = entry as Dictionary
		var id := str(region.get("id", ""))
		var team: Dictionary = _team(region)
		assert_true(team.has("enter") and team.has("exit"),
			"region '%s' names no expected team level band" % id)
		assert_true(int(team.get("enter", 0)) <= int(team.get("exit", 0)),
			"region '%s' expects the player to LOSE levels crossing it" % id)
		var wild: Array = region.get("wild_band", []) as Array
		assert_eq(wild.size(), 2, "region '%s' has no [low, high] wild band" % id)
		assert_true(int(wild[0]) <= int(wild[1]), "region '%s' has an inverted wild band" % id)


## The whole file resolves regions by upper z bound, and so does the world's own
## perimeter styling. If the two ever disagree, the corridor changes creature
## strength at one z and changes what its edges look like at another -- two
## different maps laid over each other, and nothing anywhere would report it.
func test_the_region_bounds_match_the_world_perimeters_own_bands() -> void:
	var expected: Array = [
		PERIMETER.BAND1_Z1, PERIMETER.BAND2_Z1, PERIMETER.BAND3_Z1, PERIMETER.BAND4_Z1,
	]
	var regions: Array = _regions()
	for i in expected.size():
		var region: Dictionary = regions[i] as Dictionary
		assert_almost_eq(float(region.get("z_to", 0.0)), float(expected[i]), 0.001,
			"region '%s' ends at z=%s; world_perimeter.gd puts that boundary at z=%s"
			% [str(region.get("id", "")), str(region.get("z_to", 0.0)), str(expected[i])])
	var last: Dictionary = regions[regions.size() - 1] as Dictionary
	assert_true(float(last.get("z_to", 0.0)) > PERIMETER.APPROACH_Z1,
		"the last region ends before the approach does; the stronghold end of the corridor falls off the table")


func test_region_bounds_ascend_so_lookup_is_unambiguous() -> void:
	var previous := -INF
	for entry: Variant in _regions():
		var region: Dictionary = entry as Dictionary
		var z := float(region.get("z_to", 0.0))
		assert_true(z > previous,
			"region '%s' ends at z=%.1f, at or before the region before it" % [str(region.get("id", "")), z])
		previous = z


# --- the curve actually curves ------------------------------------------------

func test_the_expected_team_never_goes_backwards() -> void:
	var previous_exit := 0
	for entry: Variant in _regions():
		var region: Dictionary = entry as Dictionary
		var team: Dictionary = _team(region)
		assert_true(int(team.get("enter", 0)) >= previous_exit,
			"region '%s' expects a team at level %d after the previous region left it at %d"
			% [str(region.get("id", "")), int(team.get("enter", 0)), previous_exit])
		previous_exit = int(team.get("exit", 0))


func test_the_opposition_never_goes_backwards() -> void:
	var previous: Array = [0, 0]
	for entry: Variant in _regions():
		var region: Dictionary = entry as Dictionary
		var wild: Array = region.get("wild_band", []) as Array
		assert_true(int(wild[0]) >= int(previous[0]) and int(wild[1]) >= int(previous[1]),
			"region '%s' fields weaker wild creatures (%d-%d) than the region before it (%d-%d); the field stops being opposition there"
			% [str(region.get("id", "")), int(wild[0]), int(wild[1]), int(previous[0]), int(previous[1])])
		previous = wild


## A region is allowed to be dangerous. It is not allowed to be a wall: the
## strongest thing in its field must be beatable by the team the region itself
## produces, or the only way through is the grind MEADOWS_PROGRESSION_SPEC.md
## section 11 forbids.
func test_no_regions_field_out_levels_what_that_region_brings_you_to() -> void:
	for entry: Variant in _regions():
		var region: Dictionary = entry as Dictionary
		var wild: Array = region.get("wild_band", []) as Array
		var exit_level := int(_team(region).get("exit", 0))
		assert_true(int(wild[1]) <= exit_level,
			"region '%s' fields level %d wild creatures but only carries the team to %d"
			% [str(region.get("id", "")), int(wild[1]), exit_level])


func test_every_region_has_something_beatable_the_moment_you_arrive() -> void:
	for entry: Variant in _regions():
		var region: Dictionary = entry as Dictionary
		var wild: Array = region.get("wild_band", []) as Array
		var enter_level := int(_team(region).get("enter", 0))
		assert_true(int(wild[0]) <= enter_level,
			"region '%s' has nothing below level %d in it and the team arrives at %d"
			% [str(region.get("id", "")), int(wild[0]), enter_level])


# --- the five-slot rule keeps biting -----------------------------------------

## THE LOAD-BEARING ONE for prompt 67. Under the single global [2, 6] band this
## file replaced, a creature caught in the stronghold approach arrived at level
## 4 against a team at 16 -- so no player would ever weigh it against a member
## they had raised, so the hard five-creature cap silently stopped being a
## decision after the first hour of a four-hour chapter. The cap cannot be
## loosened (CLAUDE.md: five, no storage, ever), so the only lever is that a
## late catch has to be close enough to argue for.
func test_a_catch_is_a_real_option_in_every_region() -> void:
	var deficit := int(_five_slot().get("max_catch_level_deficit", 2))
	for entry: Variant in _regions():
		var region: Dictionary = entry as Dictionary
		var wild: Array = region.get("wild_band", []) as Array
		var enter_level := int(_team(region).get("enter", 0))
		assert_true(int(wild[1]) >= enter_level - deficit,
			("region '%s' tops out at level %d against a team arriving at %d -- %d levels down, past the "
			+ "%d the curve allows. A catch there is not a choice, so the five-creature cap costs nothing there")
			% [str(region.get("id", "")), int(wild[1]), enter_level, enter_level - int(wild[1]), deficit])


## More desirable creatures than slots is the entire mechanism behind the cap.
## Asserted against the world's own spawn table, so deleting species from the
## Meadows fails here rather than quietly making the five free.
func test_the_meadows_offers_more_creatures_than_the_party_can_hold() -> void:
	var species := {}
	for entry: Variant in _spawns():
		species[str((entry as Dictionary).get("species", ""))] = true
	var floor_count := int(_five_slot().get("min_distinct_wild_species", 6))
	assert_true(floor_count > PARTY.MAX_CREATURES,
		"the curve's own floor of %d catchable species is not above the %d-slot party; the cap could never bite"
		% [floor_count, PARTY.MAX_CREATURES])
	assert_true(species.size() >= floor_count,
		"the wild table fields %d distinct species against the curve's floor of %d" % [species.size(), floor_count])


# --- authored content sits inside its own region ------------------------------

## A `gate_fight` (village tournament rounds, the South Bridge gatekeeper) is
## DELIBERATELY a step above its own region's ordinary wild/trainer band --
## that escalation over the field around it is what makes it read as a gate
## rather than another patrol. TOURNAMENT-2 fields band1_lower_meadows trainers
## up to level 12 against that region's 2-7 trainer_levels band for exactly
## this reason. Still checked against the CORRIDOR ceiling below, so a gate
## fight cannot run away to an arbitrary level -- only skip its own region's
## band, not every band.
func test_every_trainer_fights_at_their_own_regions_strength() -> void:
	var checked := 0
	var corridor_ceiling := 0
	for region: Variant in (_curve().get("regions", []) as Array):
		var band: Array = (region as Dictionary).get("trainer_levels", []) as Array
		if band.size() >= 2:
			corridor_ceiling = maxi(corridor_ceiling, int(band[1]))
	for entry: Variant in _trainers():
		var trainer: Dictionary = entry as Dictionary
		var position: Array = trainer.get("position", []) as Array
		if position.size() < 2:
			continue
		var region: Dictionary = CURVE.region_at(float(position[1]), _curve())
		var band: Array = region.get("trainer_levels", []) as Array
		if band.size() < 2:
			continue
		var is_gate_fight := bool(trainer.get("gate_fight", false))
		for member: Variant in (trainer.get("team", []) as Array):
			var level := int((member as Dictionary).get("level", 0))
			checked += 1
			if is_gate_fight:
				assert_true(level <= corridor_ceiling,
					"'%s' is a gate fight fielding a level %d creature, which exceeds the corridor's own highest authored trainer band (%d) -- a gate may exceed its own region, not the whole chapter"
					% [str(trainer.get("id", "")), level, corridor_ceiling])
				continue
			assert_true(level >= int(band[0]) and level <= int(band[1]),
				"'%s' stands in %s at z=%.0f and fields a level %d creature; that region's authored band is %d-%d"
				% [str(trainer.get("id", "")), str(region.get("id", "")), float(position[1]),
					level, int(band[0]), int(band[1])])
	assert_true(checked >= 15,
		"only %d trainer creatures were checked against a region band; the table or the positions moved" % checked)


## The Warrens is deliberately harder than the ridge outside it -- a dungeon
## that fights at field strength is not a dungeon. What it may not do is exceed
## its own region's authored opposition band, which is what `trainer_levels`
## covers for Band 2.
func test_the_warrens_fights_above_its_field_but_inside_its_region() -> void:
	var warrens: Dictionary = _warrens()
	var at: Array = (warrens.get("site", {}) as Dictionary).get("at", []) as Array
	assert_eq(at.size(), 2, "the warrens has no site position to resolve a region from")
	var region: Dictionary = CURVE.region_at(float(at[1]), _curve())
	var field: Array = region.get("wild_band", []) as Array
	var band: Array = region.get("trainer_levels", []) as Array
	var levels: Array = []
	for entry: Variant in (warrens.get("spawns", []) as Array):
		levels.append(int((entry as Dictionary).get("level", 0)))
	levels.append(int((warrens.get("guardian", {}) as Dictionary).get("level", 0)))
	for level: Variant in levels:
		assert_true(int(level) > int(field[1]),
			"the warrens fields a level %d creature, at or below the level %d field outside it"
			% [int(level), int(field[1])])
		assert_true(int(level) <= int(band[1]),
			"the warrens fields a level %d creature against its region's authored ceiling of %d"
			% [int(level), int(band[1])])


func test_every_wild_cluster_resolves_to_a_region_that_wants_it() -> void:
	var checked := 0
	for entry: Variant in _spawns():
		var spawn: Dictionary = entry as Dictionary
		var centre: Array = spawn.get("centre", []) as Array
		if centre.size() < 3:
			continue
		var band: Array = CURVE.wild_band_at(float(centre[2]), _curve())
		checked += 1
		assert_eq(band.size(), 2,
			"the '%s' cluster at z=%.0f resolves to no wild band" % [str(spawn.get("species", "")), float(centre[2])])
	assert_true(checked >= 10,
		"only %d clusters were resolved; the spawn table is smaller than the corridor it is meant to fill" % checked)


# --- the resolver -------------------------------------------------------------

func test_the_opening_meadow_still_rolls_the_levels_it_always_did() -> void:
	# int()-ed on both sides: JSON has no integer type, so the parsed band is
	# [2.0, 6.0] and a raw Array compare against [2, 6] fails on a file that is
	# perfectly correct.
	var band: Array = CURVE.wild_band_at(0.0, _curve())
	assert_eq([int(band[0]), int(band[1])], [2, 6],
		"Band 1's wild band moved off the historical [2, 6]; every opening smoke test and screenshot rolls against it")


func test_a_creature_in_the_approach_is_not_a_practice_meadow_creature() -> void:
	var opening: Array = CURVE.wild_band_at(0.0, _curve())
	var approach: Array = CURVE.wild_band_at(7400.0, _curve())
	assert_true(int(approach[0]) > int(opening[1]),
		"the stronghold approach's weakest wild creature (level %d) is no stronger than the practice meadow's strongest (level %d)"
		% [int(approach[0]), int(opening[1])])


## The rolled level has to actually follow the region, not just the table.
func test_the_roll_follows_the_region_it_is_rolled_in() -> void:
	var prog: Dictionary = PROGRESSION.config()
	var curve: Dictionary = _curve()
	for entry: Variant in _regions():
		var region: Dictionary = entry as Dictionary
		var z := float(region.get("z_to", 0.0)) - 1.0
		var cfg: Dictionary = CURVE.progression_config_at(z, prog, curve)
		var band: Array = region.get("wild_band", []) as Array
		assert_eq(PROGRESSION.roll_wild_level(cfg, 0.0), int(band[0]),
			"a bottom roll in '%s' is not its band's floor" % str(region.get("id", "")))
		assert_eq(PROGRESSION.roll_wild_level(cfg, 1.0), int(band[1]),
			"a top roll in '%s' is not its band's ceiling" % str(region.get("id", "")))


## `progression.gd::config()` hands out its own cached dictionary. Writing a
## per-spawn band into it would leave the last creature spawned deciding the
## band for every later caller in the process -- including the combat sandbox
## and any test that happened to run afterwards.
func test_resolving_a_region_never_mutates_the_shared_progression_config() -> void:
	var prog: Dictionary = PROGRESSION.config()
	var before: Array = ((prog.get("level", {}) as Dictionary).get("wild_band", []) as Array).duplicate()
	var cfg: Dictionary = CURVE.progression_config_at(7400.0, prog, _curve())
	assert_ne((cfg.get("level", {}) as Dictionary).get("wild_band", []), before,
		"the approach resolved to the same band as the global default; this test is proving nothing")
	assert_eq((prog.get("level", {}) as Dictionary).get("wild_band", []), before,
		"resolving a region rewrote progression.json's own cached global wild band")


## A scene with no corridor position at all (the combat sandbox, a unit test)
## must keep getting the global band rather than silently inheriting whichever
## region happens to be first in the table.
func test_a_caller_with_no_curve_falls_back_to_the_global_band() -> void:
	var prog: Dictionary = PROGRESSION.config()
	var cfg: Dictionary = CURVE.progression_config_at(0.0, prog, {})
	assert_eq(cfg, prog, "an empty curve did not fall back to the shipped progression config unchanged")
