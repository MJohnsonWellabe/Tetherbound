extends "res://tests/test_case.gd"

## Catch arithmetic.
##
## These pin the properties that make catching feel fair and make a good throw
## worth making — not specific tuned numbers. The odds themselves are the
## owner's to move on the Ally, and a test that pins the exact chance of a
## full-health catch would break every time catching is made to feel better,
## which trains people to ignore it.

const CATCH := preload("res://scripts/combat/catch_math.gd")
const SPECIES := preload("res://scripts/creatures/creature_species.gd")

const BODY := 0.5


# --- health ---------------------------------------------------------------

func test_a_hurt_creature_is_easier_to_catch() -> void:
	assert_true(CATCH.hp_factor(0.2) > CATCH.hp_factor(0.9),
		"damaging a creature has to improve catch viability")


func test_a_full_health_throw_is_allowed_but_poor() -> void:
	# GAME_DESIGN.md §15 asks for both at once: full-health throws are ALLOWED,
	# and full-health creatures are EXTREMELY difficult. Zero would break the first.
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
		"taking a creature from half to a sliver should be worth more than full to half")


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


# --- orb tiers (R4.9) ------------------------------------------------------

func test_a_better_orb_beats_a_basic_orb_at_the_same_throw() -> void:
	# The whole point of a tier ladder: carrying a better orb has to be worth
	# something, or "better orbs are meaningful progression rewards"
	# (GAME_DESIGN.md §15) is a lie.
	var basic: float = CATCH.catch_chance(0.4, 0.5, "orb_basic", 0.0, BODY)
	var greater: float = CATCH.catch_chance(0.4, 0.5, "orb_greater", 0.0, BODY)
	assert_true(greater > basic,
		"orb_greater (%f) should beat orb_basic (%f) at identical hp/aim" % [greater, basic])


func test_best_orb_picks_the_strongest_tier_actually_owned() -> void:
	assert_eq(CATCH.best_orb({"orb_basic": 3, "orb_greater": 1}), "orb_greater",
		"a single greater orb should still outrank a full stack of basic ones")


func test_best_orb_never_picks_a_tier_at_zero() -> void:
	# Owning zero is the same as not owning it — the satchel can carry a
	# stale key at 0 (a slot that emptied without being removed), and that
	# must not read as "carrying" the tier.
	assert_eq(CATCH.best_orb({"orb_basic": 0, "orb_greater": 0}), "",
		"no tier in stock should mean no legal throw, not a silent fallback")
	assert_eq(CATCH.best_orb({"orb_basic": 5, "orb_greater": 0}), "orb_basic")


func test_orb_ids_names_every_configured_tier() -> void:
	var ids: Array = CATCH.orb_ids()
	assert_true(ids.has("orb_basic"))
	assert_true(ids.has("orb_greater"))


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


func test_tutorial_failure_bound_allows_one_failed_landed_throw_then_catches() -> void:
	# Exact Gate A opening reproduction: Bramblebun at 26/124 HP with a basic
	# orb. Pin a deliberately losing roll to prove policy rather than luck.
	var hp_fraction := 26.0 / 124.0
	var ordinary: Dictionary = CATCH.resolve(
		SPECIES.catch_rate("bramblebun"), hp_fraction, "orb_basic", BODY, BODY, 0.999
	)
	assert_false(ordinary["caught"], "the chosen roll must lose under ordinary catch balance")

	var first: Dictionary = CATCH.apply_failure_bound(ordinary, 0, 1)
	assert_false(first["caught"], "the tutorial still allows one honest breakout")
	assert_almost_eq(float(first["chance"]), float(ordinary["chance"]), 0.0001,
		"the tutorial policy must not retune the ordinary catch chance")

	var second: Dictionary = CATCH.apply_failure_bound(ordinary, 1, 1)
	assert_true(second["caught"], "the configured tutorial catch must not fail twice")
	assert_eq(int(second["shakes"]), CATCH.shakes_for(true, float(second["chance"]), 0.0),
		"the wobble must describe the final assisted outcome")


func test_failure_bound_is_opt_in_and_never_changes_ordinary_catches() -> void:
	var ordinary: Dictionary = CATCH.resolve(0.6, 26.0 / 124.0, "orb_basic", BODY, BODY, 0.999)
	var unbounded: Dictionary = CATCH.apply_failure_bound(ordinary, 99, -1)
	assert_false(unbounded["caught"], "a disabled bound must preserve ordinary RNG forever")
	assert_false(unbounded.has("failure_bound_applied"))


func test_a_near_miss_shakes_more_than_a_hopeless_throw() -> void:
	# The wobble count is honest information about how close the throw was.
	var near: int = CATCH.shakes_for(false, 0.5, 0.55)
	var hopeless: int = CATCH.shakes_for(false, 0.5, 0.99)
	assert_true(near > hopeless,
		"a near miss (%d shakes) should out-shake a hopeless throw (%d)" % [near, hopeless])


# --- legality -------------------------------------------------------------

func test_a_fainted_creature_cannot_be_caught() -> void:
	# §15: over-damaging a creature and causing a faint ENDS the capture opportunity.
	# A refusal, not a very low chance — rolling a fainted target at the 2% floor
	# would eventually catch one.
	assert_false(CATCH.can_be_caught(true, false))


func test_a_trainer_owned_creature_cannot_be_caught() -> void:
	# A hard rule in CLAUDE.md, enforced in the maths so every future path into
	# catching inherits it rather than each remembering.
	assert_false(CATCH.can_be_caught(false, true))


func test_a_healthy_wild_creature_can_be_caught() -> void:
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


## OF19: the owner's concrete target ("only like 5 orbs wasted would be
## reasonable" for an ordinary Meadows creature) pinned as a real assertion
## rather than left to eyeballing. Bramblebun is the practice creature and
## sits in the 0.5-0.55 common band the owner named. This is deliberately NOT
## a best-case throw: hp=0.2 is low but not a hairline sliver, and offset ==
## body_radius is a merely-clipped hit rather than dead centre, because the
## owner's other reported symptom is that the throw itself is hard to read —
## a test pinned only to a perfect throw would miss that entirely. Expected
## value is 1/chance orbs to land a catch (geometric distribution mean).
func test_a_common_species_at_low_health_costs_about_five_orbs_or_fewer() -> void:
	var rate: float = SPECIES.catch_rate("bramblebun")
	var chance: float = CATCH.catch_chance(rate, 0.2, "orb_basic", BODY, BODY)
	var expected_orbs := 1.0 / chance
	assert_true(expected_orbs <= 5.5,
		("a common Meadows creature at low HP should cost about 5 orbs or " +
		"fewer even on a merely-clipped throw, got %.2f expected orbs " +
		"(chance %.3f)") % [expected_orbs, chance])
