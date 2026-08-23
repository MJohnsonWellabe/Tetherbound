extends "res://tests/test_case.gd"

## Two halves of the same defect, found in the Gate B continuous run of
## 2026-08-23 and both pinned here because both are pure functions.
##
## The run's forensics: after a breakout the fight stayed armed with the
## Bramblebun twenty-five metres off, and every press was accepted --
## `eligible=true`, reticle inside the body, launch assist applied -- while the
## orb hit the ground eighteen metres short. Nineteen orbs, none of which could
## physically have landed, and each one reported to the player as the same four
## words: "the orb went wide".
##
## So: the game must not take a locked-on throw it cannot deliver, and a miss
## must say how near it came. Neither needs a flight to test.

const THROW := preload("res://scripts/combat/throw_aim.gd")

## data/config/catching.json's production numbers. Kept as named constants
## because the reach assertion below is only meaningful against the real ones.
const SPEED := 17.0
const GRAVITY := 14.0


## v²/g is the furthest a projectile can be thrown on flat ground -- about 20.6m
## at the production numbers. The 25m throws in the Gate B log were not unlucky.
func test_flat_reach_matches_the_physics() -> void:
	var origin := Vector3.ZERO
	assert_true(
		THROW.within_ballistic_reach(origin, Vector3(0.0, 0.0, -18.0), SPEED, GRAVITY),
		"18m is inside v^2/g and must stay throwable")
	assert_false(
		THROW.within_ballistic_reach(origin, Vector3(0.0, 0.0, -25.0), SPEED, GRAVITY),
		"25m is beyond v^2/g -- this is the Gate B case that spent 19 orbs")
	# The boundary itself, from both sides.
	var limit := SPEED * SPEED / GRAVITY
	assert_true(
		THROW.within_ballistic_reach(origin, Vector3(0.0, 0.0, -(limit - 0.5)), SPEED, GRAVITY),
		"just inside the limit must be throwable")
	assert_false(
		THROW.within_ballistic_reach(origin, Vector3(0.0, 0.0, -(limit + 0.5)), SPEED, GRAVITY),
		"just outside the limit must not be")


## Height is part of reach, not a rounding error: uphill costs range and
## downhill buys it. A creature on a rise at the edge of the flat limit is out
## of reach even though the flat distance says otherwise.
func test_rise_and_drop_change_the_reach() -> void:
	var origin := Vector3.ZERO
	var near_limit := Vector3(0.0, 0.0, -19.0)
	assert_true(
		THROW.within_ballistic_reach(origin, near_limit, SPEED, GRAVITY),
		"19m level is inside reach")
	assert_false(
		THROW.within_ballistic_reach(origin, near_limit + Vector3.UP * 4.0, SPEED, GRAVITY),
		"the same 19m four metres UP must be out of reach")
	assert_true(
		THROW.within_ballistic_reach(origin, near_limit + Vector3.DOWN * 6.0, SPEED, GRAVITY),
		"the same 19m six metres DOWN must still be in reach")


## The point of the reach test is that a throw at the target's own body is
## refused before it costs anything. A zero-length throw is degenerate and must
## never be treated as out of range.
func test_a_throw_at_your_own_feet_is_not_out_of_range() -> void:
	assert_true(
		THROW.within_ballistic_reach(Vector3.ZERO, Vector3.ZERO, SPEED, GRAVITY),
		"a degenerate zero-distance point must not read as unreachable")


## "the orb went wide" was printed for a graze and for an eighteen-metre miss
## alike. The gap is the whole of "am I getting better at this".
func test_a_miss_reports_how_near_it_came() -> void:
	var graze := THROW.miss_message("ground", 1.3, 1.2)
	assert_true(graze.contains("so close"), "a 0.1m gap must read as close, got: %s" % graze)

	var short_throw := THROW.miss_message("ground", 19.2, 1.2)
	assert_true(short_throw.contains("18.0"), "the gap must be stated, got: %s" % short_throw)
	assert_true(
		short_throw.contains("ground"),
		"a miss that ended on terrain must say so, got: %s" % short_throw)

	var sailed := THROW.miss_message("flight_time", 6.2, 1.2)
	assert_true(
		sailed.contains("sailed past"),
		"a miss that ran out of flight must read differently from one that landed, got: %s" % sailed)

	# Different misses must not produce the same sentence -- that identity was
	# the bug.
	assert_ne(graze, short_throw, "a graze and an 18m miss must not read alike")
	assert_ne(short_throw, sailed, "hitting the ground and sailing past must not read alike")


## No flight ever measured a closest approach: there is nothing honest to say,
## and the message must not invent a number.
func test_an_unmeasured_miss_says_nothing_it_cannot_know() -> void:
	var unknown := THROW.miss_message("unknown", INF, 1.2)
	assert_false(unknown.contains("m"), "an unmeasured miss must not state a distance")
	assert_eq(unknown, "the orb went wide", "and falls back to the plain sentence")
