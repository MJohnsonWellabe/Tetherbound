extends "res://tests/test_case.gd"

## Stage B Wave 4 lane 4.C. TWO ORBS, ONE OWNER.
##
## `docs/specs/MP_ENCOUNTER_PROTOCOL.md` §8. Two people throw at the same
## creature in the same second. Exactly one keeps it, the other is told why, and
## the loser's fight does not silently end.
##
## Deterministic and pure: no networking, no scene tree, no orb node, no `Game`.
## `catch_math.gd::resolve()` was already a pure function of six values and
## `orb.gd::closest_approach_ahead()` re-derives the seventh from launch
## parameters, so the whole race reduces to two integers calling one method on
## one `CatchArbiter` in the order this file chooses -- which is exactly the
## interleaving a real race produces once the host has serialised it, and the
## host serialising it is the design.
##
## The rolls below are chosen, not random: `roll` is the host's `_rng.randf()`
## and the caller passes it in, so a test can pin a certain success (0.0) or a
## certain failure (0.999) and assert on the OWNERSHIP rather than on the dice.

const CATCH_ARBITER := preload("res://scripts/net/catch_arbiter.gd")
const ENCOUNTER_HOST := preload("res://scripts/net/encounter_host.gd")

const PEER_A := 1
## Not an index: the ENet spike's finding 2 again.
const PEER_B := 1_369_099_083

const FIGHT := "1:1"

var arbiter: RefCounted = null


func before_each() -> void:
	arbiter = CATCH_ARBITER.new()


## A throw from 4 m away, straight at a creature the HOST holds at the origin.
## `roll` is the host's die; `orb_id` is the orb the thrower actually spent.
func _params(roll: float, orb_id: String = "orb_basic",
		target: Vector3 = Vector3.ZERO, launch: Vector3 = Vector3(0.0, 1.4, -4.0)) -> Dictionary:
	return {
		"kind": "wild",
		"phase": "active",
		"opponent_fainted": false,
		"species_id": "bramblebun",
		"hp_fraction": 0.2,
		"body_radius": 0.312,
		"target_position": target,
		"launch_point": launch,
		"direction": (target - launch).normalized(),
		"orb_id": orb_id,
		"roll": roll,
	}


# --- the race ------------------------------------------------------------------------

func test_two_simultaneous_attempts_leave_exactly_one_owner() -> void:
	# Same millisecond, same fight, same creature. Both throws are physically
	# perfect and both rolls would succeed; the only thing that decides it is
	# which one reached the host first.
	var first: Dictionary = arbiter.call("attempt", FIGHT, PEER_A, _params(0.0), 10_000)
	var second: Dictionary = arbiter.call("attempt", FIGHT, PEER_B, _params(0.0), 10_000)

	assert_true(bool(first.get("ok", false)), "the first attempt to reach the host commits")
	assert_false(bool(second.get("ok", true)),
		"the second attempt on the same creature must not also resolve")
	assert_eq(str(second.get("code", "")), "already_resolving")
	assert_false(str(second.get("reason", "")).is_empty(),
		"the loser is told why, rather than having their fight silently end")
	assert_true((second.get("delta", {}) as Dictionary).is_empty(),
		"a refused attempt decides nothing")

	# Exactly one owner, and it is the winner.
	assert_eq(int(arbiter.call("owner_of", FIGHT, 10_000)), PEER_A)
	assert_false((arbiter.call("decision_for", FIGHT, PEER_A) as Dictionary).is_empty(),
		"the winner holds the decision its own presentation will play")
	assert_true((arbiter.call("decision_for", FIGHT, PEER_B) as Dictionary).is_empty(),
		"the loser holds no decision at all")


func test_the_order_decides_it_and_nothing_else_does() -> void:
	# The mirror of the case above with the peers swapped. Neither being the
	# host (PEER_A is 1) nor throwing the better orb wins it: reaching the host
	# first does.
	var first: Dictionary = arbiter.call("attempt", FIGHT, PEER_B,
		_params(0.0, "orb_basic"), 10_000)
	var second: Dictionary = arbiter.call("attempt", FIGHT, PEER_A,
		_params(0.0, "orb_greater"), 10_000)

	assert_true(bool(first.get("ok", false)))
	assert_false(bool(second.get("ok", true)),
		"the host's own throw loses the race like anybody else's")
	assert_eq(int(arbiter.call("owner_of", FIGHT, 10_000)), PEER_B)


func test_a_failed_first_attempt_still_owns_the_outcome() -> void:
	# The subtle half of "first committed attempt owns the OUTCOME": the winner
	# of the race is not the winner of the catch. A roll that breaks out still
	# spends the moment, and the second thrower is still refused -- otherwise
	# two players mashing produce two rolls on one creature and the cap on
	# attempts is however fast anybody can press.
	var first: Dictionary = arbiter.call("attempt", FIGHT, PEER_A, _params(0.999), 10_000)
	assert_true(bool(first.get("ok", false)))
	assert_false(bool((first.get("delta", {}) as Dictionary).get("caught", true)),
		"this roll breaks out")

	var second: Dictionary = arbiter.call("attempt", FIGHT, PEER_B, _params(0.0), 10_010)
	assert_false(bool(second.get("ok", true)),
		"the fight is still resolving somebody else's throw")
	assert_eq(str(second.get("code", "")), "already_resolving")


func test_the_same_peer_throwing_twice_gets_no_second_roll() -> void:
	assert_true(bool((arbiter.call("attempt", FIGHT, PEER_A, _params(0.999), 10_000)
		as Dictionary).get("ok", false)))
	var again: Dictionary = arbiter.call("attempt", FIGHT, PEER_A, _params(0.0), 10_010)
	assert_false(bool(again.get("ok", true)),
		"one player mashing must not buy itself a second roll")
	assert_eq(str(again.get("code", "")), "already_resolving")


func test_releasing_the_claim_frees_the_fight_for_the_next_throw() -> void:
	arbiter.call("attempt", FIGHT, PEER_A, _params(0.999), 10_000)
	# A LOSER cannot release the winner's claim. Asserted before the winner's
	# own release, because the ordering is the point: if a losing peer's
	# ordinary cleanup could cancel the claim, the race would reopen every time
	# somebody lost it.
	arbiter.call("release", FIGHT, PEER_B)
	assert_eq(int(arbiter.call("owner_of", FIGHT, 10_010)), PEER_A,
		"a peer that does not own the claim cannot release it")

	arbiter.call("release", FIGHT, PEER_A)
	assert_eq(int(arbiter.call("owner_of", FIGHT, 10_010)), 0)
	var next: Dictionary = arbiter.call("attempt", FIGHT, PEER_B, _params(0.0), 10_020)
	assert_true(bool(next.get("ok", false)),
		"once the wobble is over the creature can be thrown at again")


func test_a_claim_left_hanging_lapses_after_the_window() -> void:
	# The window is a BACKSTOP: a thrower who disconnected mid-wobble must not
	# wedge everybody else's fight forever.
	var window := int(ENCOUNTER_HOST.catch_arbitration_window_ms())
	arbiter.call("attempt", FIGHT, PEER_A, _params(0.999), 10_000)
	assert_eq(int(arbiter.call("owner_of", FIGHT, 10_000 + window - 1)), PEER_A,
		"inside the window the claim still stands")
	assert_eq(int(arbiter.call("owner_of", FIGHT, 10_000 + window)), 0,
		"past it the fight is free again")
	var later: Dictionary = arbiter.call("attempt", FIGHT, PEER_B,
		_params(0.0), 10_000 + window)
	assert_true(bool(later.get("ok", false)))
	assert_eq(int(arbiter.call("owner_of", FIGHT, 10_000 + window)), PEER_B)


func test_two_fights_arbitrate_independently() -> void:
	arbiter.call("attempt", FIGHT, PEER_A, _params(0.999), 10_000)
	var elsewhere: Dictionary = arbiter.call("attempt", "1:2", PEER_B, _params(0.0), 10_000)
	assert_true(bool(elsewhere.get("ok", false)),
		"a claim on one fight does not lock every other fight in the world")
	assert_eq(int(arbiter.call("owner_of", FIGHT, 10_000)), PEER_A)
	assert_eq(int(arbiter.call("owner_of", "1:2", 10_000)), PEER_B)


# --- §8's refusals that are not about the race ----------------------------------------

func test_a_trainers_creature_can_never_be_caught_even_if_the_ui_offers_it() -> void:
	# A CLAUDE.md hard rule, enforced at the host and not by hiding a button:
	# 4.C must not rely on the UI never offering it.
	var params := _params(0.0)
	params["kind"] = "trainer"
	var verdict: Dictionary = arbiter.call("attempt", FIGHT, PEER_A, params, 10_000)
	assert_false(bool(verdict.get("ok", true)))
	assert_eq(str(verdict.get("code", "")), "not_catchable")
	assert_eq(int(arbiter.call("owner_of", FIGHT, 10_000)), 0,
		"and a refused attempt claims nothing, so it cannot block a later wild fight")

	var boss := _params(0.0)
	boss["kind"] = "boss"
	assert_eq(str((arbiter.call("attempt", FIGHT, PEER_A, boss, 10_000)
		as Dictionary).get("code", "")), "not_catchable")


func test_an_orb_that_lands_on_a_creature_already_going_into_somebody_elses_orb() -> void:
	var params := _params(0.0)
	params["phase"] = "resolving"
	var verdict: Dictionary = arbiter.call("attempt", FIGHT, PEER_B, params, 10_000)
	assert_false(bool(verdict.get("ok", true)))
	assert_eq(str(verdict.get("code", "")), "wrong_phase")


func test_an_orb_landing_on_a_fainted_creature_catches_nothing() -> void:
	var params := _params(0.0)
	params["opponent_fainted"] = true
	assert_eq(str((arbiter.call("attempt", FIGHT, PEER_A, params, 10_000)
		as Dictionary).get("code", "")), "fainted")


func test_a_missing_field_is_malformed_rather_than_a_catch_at_chance_zero() -> void:
	# The trap: a missing key read through `get()` is null, `float(null)` is 0.0,
	# and a catch resolved at chance 0.0 reads as an honest failed throw --
	# which would quietly spend a player's orb on an intent the host never
	# understood. `has()` before `get()` is what stops that.
	for missing: String in ["kind", "phase", "target_position", "launch_point",
			"direction", "orb_id", "roll"]:
		var params := _params(0.0)
		params.erase(missing)
		var verdict: Dictionary = arbiter.call("attempt", FIGHT, PEER_A, params, 10_000)
		assert_eq(str(verdict.get("code", "")), "malformed",
			"an intent with no '%s' is malformed" % missing)
	assert_eq(int(arbiter.call("owner_of", FIGHT, 10_000)), 0,
		"and none of those seven refusals claimed the fight")


# --- §8 step 2: the HOST's position for the creature, never the thrower's -------------

func test_the_offset_is_measured_against_the_hosts_own_creature_position() -> void:
	# Identical launch parameters, two different HOST positions for the
	# creature. If the offset were taken from the thrower's report these two
	# would be the same number and aiming would be worth nothing across a
	# network; because the host re-derives it, the throw that the host says
	# passed a metre wide scores worse.
	var straight: Dictionary = arbiter.call("attempt", FIGHT, PEER_A,
		_params(0.5, "orb_basic", Vector3.ZERO), 10_000)
	var wide_arbiter: RefCounted = CATCH_ARBITER.new()
	var wide_params := _params(0.5, "orb_basic", Vector3.ZERO)
	# Same launch point and same direction -- only where the host holds the
	# creature moves.
	wide_params["target_position"] = Vector3(1.0, 0.0, 0.0)
	var wide: Dictionary = wide_arbiter.call("attempt", FIGHT, PEER_A, wide_params, 10_000)

	var straight_offset := float((straight.get("delta", {}) as Dictionary).get("offset", -1.0))
	var wide_offset := float((wide.get("delta", {}) as Dictionary).get("offset", -1.0))
	assert_almost_eq(straight_offset, 0.0, 0.001,
		"a throw aimed at where the host holds the creature passes through it")
	assert_true(wide_offset > straight_offset,
		"and the same throw at a creature the host holds elsewhere is a worse throw (%.3f vs %.3f)"
			% [wide_offset, straight_offset])
	assert_true(float((straight.get("delta", {}) as Dictionary).get("chance", 0.0))
		> float((wide.get("delta", {}) as Dictionary).get("chance", 0.0)),
		"which is the aiming skill surviving the trip through the host")


func test_the_orb_the_thrower_actually_spent_is_the_orb_that_is_priced() -> void:
	# R4.9's reason, restated across the wire: the satchel has already lost that
	# orb by the time this resolves, so re-querying "best available" would price
	# a greater-orb throw at the basic multiplier.
	var basic: Dictionary = arbiter.call("attempt", FIGHT, PEER_A,
		_params(0.5, "orb_basic"), 10_000)
	var greater_arbiter: RefCounted = CATCH_ARBITER.new()
	var greater: Dictionary = greater_arbiter.call("attempt", FIGHT, PEER_A,
		_params(0.5, "orb_greater"), 10_000)

	assert_eq(str((basic.get("delta", {}) as Dictionary).get("orb_id", "")), "orb_basic",
		"the decision names the orb it was priced with")
	assert_true(float((greater.get("delta", {}) as Dictionary).get("chance", 0.0))
		> float((basic.get("delta", {}) as Dictionary).get("chance", 0.0)),
		"and a better orb really is a better throw")
