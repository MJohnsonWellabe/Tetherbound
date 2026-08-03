extends "res://tests/test_case.gd"

## Catch arithmetic.
##
## These pin the properties that make catching feel fair and make a good throw
## worth making — not specific tuned numbers. The odds themselves are the
## owner's to move on the Ally, and a test that pins the exact chance of a
## full-health catch would break every time catching is made to feel better,
## which trains people to ignore it.

const CATCH := preload("res://scripts/combat/catch_math.gd")
const SPECIES := preload("res://scripts/pals/pal_species.gd")

const BODY := 0.5


# --- health ---------------------------------------------------------------

func test_a_hurt_pal_is_easier_to_catch() -> void:
	assert_true(CATCH.hp_factor(0.2) > CATCH.hp_factor(0.9),
		"damaging a pal has to improve catch viability")


func test_a_full_health_throw_is_allowed_but_poor() -> void:
	# GAME_DESIGN.md §15 asks for both at once: full-health throws are ALLOWED,
	# and full-health pals are EXTREMELY difficult. Zero would break the first.
	var full := CATCH.hp_factor(1.0)
	assert_true(full > 0.0, "a full-health throw must be possible at all")
	assert_true(full < 0.35, "a full-health throw should be a long shot, got %f" % full)


func test_health_factor_is_monotonic() -> void:
	var previous := 0.0
	for step in 11:
		var factor: float = CATCH.hp_factor(1.0 - float(step) / 10.0)
		assert_true(factor >= previous,
			"catch viability must never dip as health falls (%f then %f)" % [previous, factor])
		previous = factor


func test_the_reward_is_back_loaded() -> void:
	# What keeps "damage it first" a real risk against "over-damage it and lose
	# the catch": halfway does much less than most of the way.
	var full := CATCH.hp_factor(1.0)
	var half := CATCH.hp_factor(0.5)
	var sliver := CATCH.hp_factor(0.05)
	assert_true(half - full < sliver - half,
		"taking a pal from half to a sliver should be worth more than full to half")


# --- aiming ---------------------------------------------------------------

func test_a_centred_hit_beats_a_clipped_one() -> void:
	# If this fails, aiming is decoration and the milestone has no subject.
	assert_true(CATCH.accuracy_bonus(0.0, BODY) > CATCH.accuracy_bonus(BODY, BODY),
		"a dead-centre throw has to be worth more than one that barely clipped")


func test_accuracy_saturates_rather_than_going_negative() -> void:
	# An orb that grazed further out than the body radius should be worth the
	# worst bonus, not a negative one that inverts the whole formula.
	var edge: float = CATCH.accuracy_bonus(BODY, BODY)
	var beyond: float = CATCH.accuracy_bonus(BODY * 4.0, BODY)
	assert_almost_eq(beyond, edge, 0.001)
	assert_true(beyond > 0.0)


func test_accuracy_survives_a_zero_sized_target() -> void:
	assert_true(CATCH.accuracy_bonus(0.0, 0.0) > 0.0)


# --- combined odds --------------------------------------------------------

func test_chance_stays_in_range() -> void:
	for hp in [0.0, 0.25, 0.5, 1.0]:
		for offset in [0.0, 0.25, 0.5, 2.0]:
			var chance: float = CATCH.catch_chance(0.4, hp, "basic", offset, BODY)
			assert_between(chance, 0.0, 1.0, "chance at hp %.2f offset %.2f" % [hp, offset])


func test_nothing_is_ever_certain() -> void:
	# A guaranteed catch removes the only tension the mechanic has.
	var best: float = CATCH.catch_chance(9.9, 0.0, "basic", 0.0, BODY)
	assert_true(best < 1.0, "even a perfect throw at a sliver of health was certain (%f)" % best)


func test_a_rare_species_is_harder_than_a_common_one() -> void:
	var common: float = CATCH.catch_chance(0.6, 0.5, "basic", 0.0, BODY)
	var rare: float = CATCH.catch_chance(0.15, 0.5, "basic", 0.0, BODY)
	assert_true(rare < common)


func test_an_unknown_orb_does_not_silently_zero_the_odds() -> void:
	# A typo in an orb id should not quietly make catching impossible; it should
	# behave like a basic orb.
	assert_almost_eq(CATCH.orb_multiplier("does_not_exist"), 1.0, 0.001)


# --- the decision ---------------------------------------------------------

func test_a_low_roll_catches_and_a_high_roll_does_not() -> void:
	var certain: Dictionary = CATCH.resolve(0.9, 0.05, "basic", 0.0, BODY, 0.0)
	var hopeless: Dictionary = CATCH.resolve(0.9, 0.05, "basic", 0.0, BODY, 0.999)
	assert_true(certain["caught"], "a roll of zero should catch anything catchable")
	assert_false(hopeless["caught"], "a roll of nearly one should fail")


func test_the_wobble_never_contradicts_the_outcome() -> void:
	# The rule this whole file exists to protect: the outcome is decided once and
	# the shakes are derived from it. A wobble that can disagree with the result
	# already computed is a lie, and dramatising a lie is what makes catch
	# animations feel cheap.
	for step in 40:
		var roll := float(step) / 40.0
		var decision: Dictionary = CATCH.resolve(0.5, 0.4, "basic", 0.1, BODY, roll)
		var shakes: int = decision["shakes"]
		assert_true(shakes >= 1, "every throw should shake at least once")
		if bool(decision["caught"]):
			assert_eq(shakes, CATCH.shakes_for(true, decision["chance"], roll),
				"a successful catch must always shake the success count")


func test_resolve_is_reproducible() -> void:
	var first: Dictionary = CATCH.resolve(0.4, 0.6, "basic", 0.2, BODY, 0.37)
	var second: Dictionary = CATCH.resolve(0.4, 0.6, "basic", 0.2, BODY, 0.37)
	assert_eq(first["caught"], second["caught"])
	assert_almost_eq(float(first["chance"]), float(second["chance"]), 0.0001)
	assert_eq(first["shakes"], second["shakes"])


func test_a_near_miss_shakes_more_than_a_hopeless_throw() -> void:
	# The wobble count is honest information about how close the throw was.
	var near: int = CATCH.shakes_for(false, 0.5, 0.55)
	var hopeless: int = CATCH.shakes_for(false, 0.5, 0.99)
	assert_true(near > hopeless,
		"a near miss (%d shakes) should out-shake a hopeless throw (%d)" % [near, hopeless])


# --- legality -------------------------------------------------------------

func test_a_fainted_pal_cannot_be_caught() -> void:
	# §15: over-damaging a pal and causing a faint ENDS the capture opportunity.
	# A refusal, not a very low chance — rolling a fainted target at the 2% floor
	# would eventually catch one.
	assert_false(CATCH.can_be_caught(true, false))


func test_a_trainer_owned_pal_cannot_be_caught() -> void:
	# A hard rule in CLAUDE.md, enforced in the maths so every future path into
	# catching inherits it rather than each remembering.
	assert_false(CATCH.can_be_caught(false, true))


func test_a_healthy_wild_pal_can_be_caught() -> void:
	assert_true(CATCH.can_be_caught(false, false))


# --- the shipped numbers --------------------------------------------------

func test_every_species_declares_a_catch_rate() -> void:
	# A missing rate defaults silently, and a creature that is accidentally
	# trivial to catch is the kind of bug nobody reports because it feels good.
	for id: String in SPECIES.table().keys():
		var definition: Dictionary = SPECIES.definition(id)
		assert_true(definition.has("catch_rate"), "species '%s' has no catch_rate" % id)


func test_the_shipped_orb_stock_is_generous() -> void:
	# §15: players should never be afraid to experiment with basic orbs.
	assert_true(CATCH.starting_stock() >= 10,
		"only %d orbs; scarcity discourages the experimentation the design asks for" % CATCH.starting_stock())
