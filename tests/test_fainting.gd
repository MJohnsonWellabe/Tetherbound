extends "res://tests/test_case.gd"

## R4.8: fainting and home recovery (GAME_DESIGN.md, M6).
##
## Scope per docs/decisions/D02 -- pure logic only. `home_recovery.gd::rest()`
## is the new mechanism (what a creature_bed actually does); the fainted-
## state invariants below are pre-existing behaviour (`party.gd::set_active`/
## `all_fainted`) that this item's own brief depends on ("unavailable
## state") -- tested here as the documented baseline a creature_bed's
## revival exists to recover FROM, not as new code.

const SPECIES := preload("res://scripts/creatures/creature_species.gd")
const PROGRESSION := preload("res://scripts/creatures/progression.gd")
const HOME_RECOVERY := preload("res://scripts/creatures/home_recovery.gd")
const PARTY := preload("res://autoload/party.gd")

var cfg: Dictionary = {}


func before_each() -> void:
	cfg = PROGRESSION.config()


# --- home_recovery.rest() ----------------------------------------------------

func test_rest_revives_a_fainted_creature() -> void:
	var terrapup: RefCounted = SPECIES.spawn("terrapup")
	terrapup.call("take_damage", terrapup.max_hp * 10.0)
	assert_true(bool(terrapup.get("fainted")))

	HOME_RECOVERY.rest(terrapup, cfg)

	assert_false(bool(terrapup.get("fainted")))
	assert_almost_eq(float(terrapup.get("hp")), float(terrapup.get("max_hp")), 0.001)


func test_rest_tops_up_a_creature_that_was_only_hurt() -> void:
	var terrapup: RefCounted = SPECIES.spawn("terrapup")
	terrapup.call("take_damage", terrapup.max_hp * 0.5)
	assert_false(bool(terrapup.get("fainted")))

	HOME_RECOVERY.rest(terrapup, cfg)

	assert_almost_eq(float(terrapup.get("hp")), float(terrapup.get("max_hp")), 0.001)


func test_rest_resets_energy_the_same_way_heal_fully_does() -> void:
	var terrapup: RefCounted = SPECIES.spawn("terrapup")
	terrapup.set("energy", 87.0)

	HOME_RECOVERY.rest(terrapup, cfg)

	assert_almost_eq(float(terrapup.get("energy")), 0.0, 0.001)


func test_rest_grants_the_same_rest_bonus_xp_camp_gives() -> void:
	var terrapup: RefCounted = SPECIES.spawn("terrapup")
	var reference: RefCounted = SPECIES.spawn("terrapup")
	var expected_bonus := PROGRESSION.rest_xp(cfg)
	assert_true(expected_bonus > 0, "progression.json's xp_award.rest_bonus should be positive")
	reference.call("gain_xp", expected_bonus, cfg)

	HOME_RECOVERY.rest(terrapup, cfg)

	assert_eq(int(terrapup.get("xp")), int(reference.get("xp")))
	assert_eq(int(terrapup.get("level")), int(reference.get("level")))


func test_rest_on_a_null_creature_does_nothing_and_does_not_crash() -> void:
	HOME_RECOVERY.rest(null, cfg)
	assert_true(true, "reaching this line means rest() degraded gracefully")


# --- the fainted-state baseline a creature_bed's revival recovers from ------

func test_a_fainted_creature_refuses_to_become_the_active_one() -> void:
	var party: RefCounted = PARTY.new()
	var terrapup: RefCounted = SPECIES.spawn("terrapup")
	var ripplet: RefCounted = SPECIES.spawn("ripplet")
	party.call("add", terrapup)
	party.call("add", ripplet)
	terrapup.call("take_damage", terrapup.max_hp * 10.0)

	assert_false(bool(party.call("set_active", 0)))
	assert_eq(int(party.call("active_index")), 0, "a refused set_active must not move the active slot")

	HOME_RECOVERY.rest(terrapup, cfg)
	assert_true(bool(party.call("set_active", 0)), "reviving the creature un-blocks set_active")


func test_all_fainted_is_false_with_a_healthy_member_and_true_once_all_are_down() -> void:
	var party: RefCounted = PARTY.new()
	var terrapup: RefCounted = SPECIES.spawn("terrapup")
	var ripplet: RefCounted = SPECIES.spawn("ripplet")
	party.call("add", terrapup)
	party.call("add", ripplet)

	assert_false(bool(party.call("all_fainted")))

	terrapup.call("take_damage", terrapup.max_hp * 10.0)
	assert_false(bool(party.call("all_fainted")), "one healthy member is enough to keep this false")

	ripplet.call("take_damage", ripplet.max_hp * 10.0)
	assert_true(bool(party.call("all_fainted")))

	HOME_RECOVERY.rest(terrapup, cfg)
	assert_false(bool(party.call("all_fainted")), "resting one member should clear the all-fainted state")
