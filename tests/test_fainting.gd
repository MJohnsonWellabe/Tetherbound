extends "res://tests/test_case.gd"

## R4.8: fainting and home recovery (GAME_DESIGN.md, M6).
##
## Scope per docs/decisions/D02 -- pure logic only. `home_recovery.gd::rest()`
## is the new mechanism (what a creature_bed actually does); the fainted-
## state invariants below are pre-existing behaviour (`party.gd::set_active`/
## `all_fainted`) that this item's own brief depends on ("unavailable
## state") -- tested here as the documented baseline a creature_bed's
## revival exists to recover FROM, not as new code.
##
## OF32/D40 added the `heal()`/`revive()` split below: a potion no longer
## un-faints (it refuses outright), and only a dedicated `revive()` call
## clears `fainted` outside of rest. `heal_fully()` (rest, home_recovery,
## creature beds) is explicitly unchanged by D40 and gets its own direct
## assertion here rather than relying only on `test_rest_revives_a_fainted_
## creature` above to imply it.

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


# --- OF32/D40: heal() refuses the fainted, revive() is the only un-fainter -

func test_heal_refuses_a_fainted_creature() -> void:
	var terrapup: RefCounted = SPECIES.spawn("terrapup")
	terrapup.call("take_damage", terrapup.max_hp * 10.0)
	assert_true(bool(terrapup.get("fainted")))

	var restored: float = terrapup.call("heal", 9999.0)

	assert_almost_eq(restored, 0.0, 0.001, "a potion must restore nothing on a fainted creature")
	assert_true(bool(terrapup.get("fainted")), "heal() must not clear fainted -- D40")
	assert_almost_eq(float(terrapup.get("hp")), 0.0, 0.001, "hp must stay untouched by a refused heal")


func test_heal_still_tops_up_a_creature_that_is_only_hurt() -> void:
	var terrapup: RefCounted = SPECIES.spawn("terrapup")
	terrapup.call("take_damage", terrapup.max_hp * 0.5)
	assert_false(bool(terrapup.get("fainted")))

	var restored: float = terrapup.call("heal", 9999.0)

	assert_true(restored > 0.0, "a potion should still heal a standing, hurt creature")
	assert_almost_eq(float(terrapup.get("hp")), float(terrapup.get("max_hp")), 0.001)


func test_revive_only_acts_on_a_fainted_creature() -> void:
	var terrapup: RefCounted = SPECIES.spawn("terrapup")
	assert_false(bool(terrapup.get("fainted")))
	var before_hp: float = terrapup.get("hp")

	var restored: float = terrapup.call("revive", 0.5)

	assert_almost_eq(restored, 0.0, 0.001, "a Revive must refuse a creature that is not fainted")
	assert_almost_eq(float(terrapup.get("hp")), before_hp, 0.001, "hp must be untouched by a refused revive")


func test_revive_restores_half_and_clears_fainted() -> void:
	var terrapup: RefCounted = SPECIES.spawn("terrapup")
	terrapup.call("take_damage", terrapup.max_hp * 10.0)
	assert_true(bool(terrapup.get("fainted")))

	var restored: float = terrapup.call("revive", 0.5)

	assert_false(bool(terrapup.get("fainted")), "revive() must clear fainted")
	assert_almost_eq(float(terrapup.get("hp")), float(terrapup.get("max_hp")) * 0.5, 0.001)
	assert_almost_eq(restored, float(terrapup.get("max_hp")) * 0.5, 0.001, "revive() should return the amount restored")


func test_heal_fully_still_unfaints_this_is_rest_not_a_potion() -> void:
	var terrapup: RefCounted = SPECIES.spawn("terrapup")
	terrapup.call("take_damage", terrapup.max_hp * 10.0)
	assert_true(bool(terrapup.get("fainted")))

	terrapup.call("heal_fully")

	assert_false(bool(terrapup.get("fainted")), "heal_fully() (rest/creature beds) must be unaffected by D40")
	assert_almost_eq(float(terrapup.get("hp")), float(terrapup.get("max_hp")), 0.001)


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
