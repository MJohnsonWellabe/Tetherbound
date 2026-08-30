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
	# An orb that grazed further out than a hit could possibly be should be worth
	# the worst bonus, not a negative one that inverts the whole formula.
	var scale: float = CATCH.accuracy_scale(BODY)
	var edge: float = CATCH.accuracy_bonus(scale, BODY)
	var beyond: float = CATCH.accuracy_bonus(scale * 4.0, BODY)
	assert_almost_eq(beyond, edge, 0.001)
	assert_true(beyond > 0.0)


func test_the_placement_scale_is_the_distance_a_hit_can_actually_be_at() -> void:
	# OP-0830-5, and the regression that stops it coming back. The bonus is
	# graded over the envelope `orb.gd::_check_target()` tests against -- the
	# body plus the orb's own radius. Scoring it over `body_radius` alone (which
	# is what shipped, and what the owner reported as "way too hard") pins four
	# throws in five at the worst possible placement, because a real assisted
	# throw's median miss distance is already larger than a small creature's
	# whole body.
	var orb_radius := float(CATCH.config().get("throw", {}).get("radius", 0.6))
	assert_true(CATCH.accuracy_scale(BODY) > BODY,
		"placement is being judged on a scale no thrown orb can hold; the "
		+ "envelope is body + orb radius, not the body alone")
	assert_almost_eq(CATCH.accuracy_scale(BODY), BODY + orb_radius, 0.001)


func test_a_throw_inside_the_body_is_not_scored_as_a_graze() -> void:
	# The measured failure in one assertion: a Bramblebun-sized target, and a
	# throw that passed a body's width off centre. That used to be worth exactly
	# `edge_bonus` -- the same as an orb that barely clipped the collision
	# sphere half a metre further out.
	var body := 0.325
	var close_throw: float = CATCH.accuracy_bonus(body, body)
	var barely_a_hit: float = CATCH.accuracy_bonus(CATCH.accuracy_scale(body), body)
	assert_true(close_throw > barely_a_hit + 0.1,
		"a throw one body-radius off centre (%.3f) scores the same as one that "
		% close_throw + "barely clipped the collision sphere (%.3f); aiming is "
		% barely_a_hit + "decoration again")


func test_the_ceiling_did_not_move() -> void:
	# The fix is the SCALE, not the bonus: a dead-centre throw is worth what it
	# has always been worth, and the worst legal placement is worth what it has
	# always been worth. Anyone reading this as "catching was made easier by
	# raising the odds" is reading it wrong.
	var chance: Dictionary = CATCH.config().get("chance", {})
	assert_almost_eq(CATCH.accuracy_bonus(0.0, BODY), float(chance.get("centre_bonus", 1.45)), 0.001)
	assert_almost_eq(
		CATCH.accuracy_bonus(CATCH.accuracy_scale(BODY), BODY),
		float(chance.get("edge_bonus", 0.80)), 0.001)


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


## --- placement: does aiming change the outcome at all? ----------------------

const ORB := preload("res://scripts/combat/orb.gd")


## The defect that made the whole aiming skill decorative.
##
## `orb.gd::_check_target()` fires when the orb's centre is within
## `body_radius + radius` -- 0.312 + 0.60 = 0.912 m for a Bramblebun -- and
## reported the strike offset as the distance at that same sample, clamped to
## `body_radius`. But the orb moves 0.283 m per 60Hz tick at `speed` 17, and
## only its ENDPOINT was sampled, so the first sample inside 0.912 m was never
## inside 0.312 m and the clamp saturated every time.
##
## Result: a dead-centre throw and one 0.30 m wide both reported 0.312 and both
## scored at `edge_bonus`. `centre_bonus` was unreachable. Every
## `catch launch: strike` line in the repo's own logs reads `offset=0.312`,
## including throws where the launch assist led the orb to the body centre.
##
## This test is the guard. It works on the segment arithmetic directly, which is
## where the fix lives, and it fails if the endpoint-only sampling ever returns.
func test_a_dead_centre_throw_is_scored_better_than_a_wide_one() -> void:
	var centre := Vector3(7.5, 1.0, 0.0)
	var body_radius := 0.312
	# One physics step of an orb at 17 m/s, arriving at the body. The step
	# ENDS 0.826 m from the centre -- the geometry the old code sampled.
	var step := 0.283

	var centred_from := centre + Vector3(step, 0.0, 0.0)
	var centred_to := centre - Vector3(step, 0.0, 0.0)
	var centred := ORB.closest_approach(centred_from, centred_to, centre)

	var wide_from := centred_from + Vector3(0.0, 0.0, 0.30)
	var wide_to := centred_to + Vector3(0.0, 0.0, 0.30)
	var wide := ORB.closest_approach(wide_from, wide_to, centre)

	assert_true(centred < wide,
		"a throw through the centre must measure closer than one 0.30m wide (centred %.3f, wide %.3f)" % [centred, wide])
	assert_true(centred < 0.01,
		"a throw straight through the centre must measure ~0 off centre, got %.3f" % centred)

	var centred_bonus := CATCH.accuracy_bonus(minf(centred, body_radius), body_radius)
	var wide_bonus := CATCH.accuracy_bonus(minf(wide, body_radius), body_radius)
	assert_true(centred_bonus > wide_bonus,
		"aiming must change the catch chance: centred scored %.3f, wide scored %.3f -- equal means the accuracy term is dead and the reticle is decoration" % [centred_bonus, wide_bonus])


## The endpoint of a step can be far outside the body while the step itself
## passed straight through it. Sampling only the endpoint therefore both
## mis-scored placement AND let a fast orb tunnel through a small creature.
func test_the_swept_step_catches_a_pass_through_the_body() -> void:
	var centre := Vector3.ZERO
	var from := Vector3(-0.5, 0.0, 0.0)
	var to := Vector3(0.5, 0.0, 0.0)
	assert_almost_eq(ORB.closest_approach(from, to, centre), 0.0, 0.001,
		"a step passing through the centre must measure zero")
	assert_almost_eq(ORB.closest_approach(from, to, Vector3(0.0, 0.0, 0.25)), 0.25, 0.001,
		"a step passing 0.25m beside the centre must measure 0.25")


## Past either end of the segment the answer is the endpoint distance, not the
## distance to the infinite line -- an orb that stopped short has not passed the
## creature.
func test_closest_approach_does_not_extrapolate_past_the_step() -> void:
	var from := Vector3(2.0, 0.0, 0.0)
	var to := Vector3(3.0, 0.0, 0.0)
	assert_almost_eq(ORB.closest_approach(from, to, Vector3.ZERO), 2.0, 0.001,
		"a step that never reached the target must measure its nearest endpoint")


## The second half of the same defect, and the subtler one.
##
## Fixing the swept step alone was not enough. The hit test fires on the step
## that first brings the orb within `body_radius + orb_radius` -- 0.912 m,
## because the orb is a forgiving 0.60 m sphere -- and the orb stops there. So
## the triggering step ENTERS the forgiveness sphere and never reaches the body,
## and measuring placement over that step still scored a perfect throw as a
## graze: a live `assist=true` throw aimed at the body centre logged
## `closest=0.821`, which the clamp pinned at `body_radius` exactly as before
## the fix.
##
## What `accuracy_bonus()` is asking is how well AIMED the throw was, which is a
## property of the trajectory rather than of wherever a generous collision
## sphere made first contact. Hence `closest_approach_ahead()`. After it, the
## same live throw logged `closest=0.158`.
func test_placement_is_scored_on_the_trajectory_not_where_the_orb_stopped() -> void:
	var centre := Vector3.ZERO
	var body_radius := 0.312
	var orb_radius := 0.60

	# The orb arriving dead on the centre, stopped at the surface of its own
	# forgiveness sphere -- the exact geometry the hit test produces.
	var heading := Vector3(-1.0, 0.0, 0.0)
	var contact := Vector3(body_radius + orb_radius, 0.0, 0.0)

	var over_the_step := ORB.closest_approach(
		contact, contact + heading * 0.283, centre
	)
	var over_the_trajectory := ORB.closest_approach_ahead(contact, heading, centre)

	assert_true(over_the_step > body_radius,
		"the step that triggers the hit stops short of the body (%.3f) -- this is why measuring it alone saturated the clamp" % over_the_step)
	assert_almost_eq(over_the_trajectory, 0.0, 0.001,
		"a throw heading straight through the centre must score as dead centre, got %.3f" % over_the_trajectory)

	assert_almost_eq(
		CATCH.accuracy_bonus(minf(over_the_trajectory, body_radius), body_radius),
		float(CATCH.config().get("chance", {}).get("centre_bonus", 1.45)), 0.001,
		"a dead-centre trajectory must earn centre_bonus; anything less means the bonus is unreachable in play"
	)


## A throw genuinely passing wide still scores wide. The fix must make aiming
## matter, not make every throw free.
##
## OP-0830-5 moved where "wide" starts, and this test moved with it -- so the
## reasoning is written out rather than left as a changed number.
##
## It used to assert that a throw passing **0.35 m** off a 0.312 m body scored
## exactly `edge_bonus`, i.e. the worst placement possible. That reads as a
## strict test and is in fact the defect the owner reported: `orb.gd` counts a
## hit out to `body_radius + orb radius` (0.912 m here), so 0.35 m is not a wide
## throw at all -- it is a throw inside the middle third of the envelope, and
## `tools/_probe_catch_rate.gd` measured the MEDIAN real assisted throw at
## 0.375 m. Pinning that at `edge_bonus` is what made 77% of landed throws score
## as grazes and made aiming worth nothing.
##
## So the claim is kept and re-anchored: a throw at the far edge of what still
## counts as a hit scores `edge_bonus`, a throw beyond it cannot score better,
## and a throw a third of the way out scores strictly worse than dead centre.
## Aiming still matters; it just is not all-or-nothing any more.
func test_a_wide_trajectory_still_scores_at_the_edge() -> void:
	var centre := Vector3.ZERO
	var body_radius := 0.312
	var heading := Vector3(-1.0, 0.0, 0.0)
	var scale: float = CATCH.accuracy_scale(body_radius)

	var wide_contact := Vector3(0.9, 0.0, scale)
	var wide := ORB.closest_approach_ahead(wide_contact, heading, centre)
	assert_almost_eq(wide, scale, 0.001, "a throw passing at the envelope must measure it")
	assert_almost_eq(
		CATCH.accuracy_bonus(minf(wide, scale), body_radius),
		float(CATCH.config().get("chance", {}).get("edge_bonus", 0.80)), 0.001,
		"a trajectory at the outer edge of the hit envelope must score at edge_bonus"
	)

	# And the middle of the envelope is genuinely between the two, not pinned to
	# either end. This is the assertion that would have caught the shipped
	# defect.
	var middling: float = CATCH.accuracy_bonus(0.35, body_radius)
	assert_true(middling < CATCH.accuracy_bonus(0.0, body_radius),
		"a throw 0.35m off centre must be worth less than a dead-centre one")
	assert_true(middling > CATCH.accuracy_bonus(scale, body_radius) + 0.1,
		"a throw 0.35m off centre (%.3f) is still being scored as a graze; that is "
		% middling + "the OP-0830-5 defect")


## An orb already past the creature measures from where it is, never from a
## closest approach it has already flown through.
func test_a_departing_orb_does_not_score_a_closest_approach_it_has_passed() -> void:
	var centre := Vector3.ZERO
	var away := Vector3(1.0, 0.0, 0.0)
	var position := Vector3(0.8, 0.0, 0.0)
	assert_almost_eq(ORB.closest_approach_ahead(position, away, centre), 0.8, 0.001,
		"an orb moving away from the creature must measure its current distance")
