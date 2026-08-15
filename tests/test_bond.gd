extends "res://tests/test_case.gd"

## R4.7 (GAME_DESIGN.md §12: "Bond and Best Creature").
##
## Two things this pins down that nothing tested before:
##
## 1. Bond's `attack_scale`/`defence_scale` config actually reaches a fight.
##    `PROGRESSION.bond_stat_scale` has been tested in isolation since D30
##    (see test_progression.gd) but nothing multiplied it into combat until
##    `creature_instance.effective_attack`/`effective_defence` — this file
##    proves those two actually apply it, not just that the underlying static
##    function does.
## 2. Best Creature (`autoload/party.gd`'s `_best`, and the species-specific
##    ability read through `creature_species.best_creature_ability`) is a
##    real, additive-only bonus: absent for a creature nobody has flagged,
##    and never a penalty for one that has been.

const PROGRESSION := preload("res://scripts/creatures/progression.gd")
const CREATURE := preload("res://scripts/creatures/creature_instance.gd")
const SPECIES := preload("res://scripts/creatures/creature_species.gd")
const PARTY := preload("res://autoload/party.gd")

const DEFINITION := {
	"display_name": "Terrapup", "type": "ground",
	"base_hp": 100.0, "base_attack": 20.0, "base_defence": 20.0,
}

const CFG := {
	"bond": {
		"max": 100,
		"thresholds": [10, 30, 55, 80, 100],
		"effects_per_node": {"attack_scale": 0.01, "defence_scale": 0.02},
	},
	"xp_award": {"rest_bonus": 5},
}

const SURVIVOR_ABILITY := {"id": "test_shell", "kind": "survivability", "value": 0.2}
const ENERGY_ABILITY := {"id": "test_spark", "kind": "energy", "value": 0.5}


func _creature() -> RefCounted:
	return CREATURE.from_species("terrapup", DEFINITION)


# --- effective_attack / effective_defence: bond actually reaches combat -----

func test_effective_attack_equals_plain_attack_at_zero_bond() -> void:
	var creature := _creature()
	assert_almost_eq(creature.effective_attack(CFG), creature.attack, 0.0001,
		"a freshly caught creature with no bond should fight at its plain stats")


func test_effective_attack_grows_with_bond_nodes() -> void:
	var creature := _creature()
	creature.bond = 55
	var nodes: int = creature.bond_nodes(CFG)
	assert_eq(nodes, 3, "sanity: 55 crosses the first three thresholds in CFG")
	assert_almost_eq(
		creature.effective_attack(CFG), creature.attack * (1.0 + 3.0 * 0.01), 0.0001
	)


func test_effective_defence_equals_plain_defence_at_zero_bond_and_no_ability() -> void:
	var creature := _creature()
	assert_almost_eq(creature.effective_defence(CFG), creature.defence, 0.0001)


func test_effective_defence_grows_with_bond_nodes() -> void:
	var creature := _creature()
	creature.bond = 100
	assert_almost_eq(
		creature.effective_defence(CFG), creature.defence * (1.0 + 5.0 * 0.02), 0.0001
	)


# --- Best Creature: additive only, never a penalty --------------------------

func test_survivability_ability_does_nothing_when_not_flagged_best() -> void:
	var creature := _creature()
	var plain: float = creature.effective_defence(CFG)
	var with_ability: float = creature.effective_defence(CFG, false, SURVIVOR_ABILITY)
	assert_almost_eq(with_ability, plain, 0.0001,
		"an ability a creature has not been flagged for must not apply")


func test_survivability_ability_boosts_defence_only_when_best() -> void:
	var creature := _creature()
	var plain: float = creature.effective_defence(CFG)
	var boosted: float = creature.effective_defence(CFG, true, SURVIVOR_ABILITY)
	assert_almost_eq(boosted, plain * 1.2, 0.0001)
	assert_true(boosted > plain, "the ability must only ever add, never subtract")


func test_energy_ability_does_not_touch_defence() -> void:
	var creature := _creature()
	var plain: float = creature.effective_defence(CFG)
	var with_energy_kind: float = creature.effective_defence(CFG, true, ENERGY_ABILITY)
	assert_almost_eq(with_energy_kind, plain, 0.0001,
		"a differently-kinded ability must not leak into the wrong stat")


func test_quick_energy_multiplier_is_one_by_default() -> void:
	var creature := _creature()
	assert_almost_eq(creature.quick_energy_multiplier(), 1.0, 0.0001)
	assert_almost_eq(creature.quick_energy_multiplier(true, SURVIVOR_ABILITY), 1.0, 0.0001,
		"a survivability ability must not also boost energy")


func test_quick_energy_multiplier_applies_only_when_best_and_energy_kind() -> void:
	var creature := _creature()
	assert_almost_eq(creature.quick_energy_multiplier(false, ENERGY_ABILITY), 1.0, 0.0001,
		"not flagged best -- the ability must not apply")
	assert_almost_eq(creature.quick_energy_multiplier(true, ENERGY_ABILITY), 1.5, 0.0001)


func test_gain_energy_from_quick_multiplier_scales_the_flat_gain() -> void:
	var creature := _creature()
	creature.energy = 0.0
	creature.gain_energy_from_quick(1.0)
	var plain_gain: float = creature.energy
	creature.energy = 0.0
	creature.gain_energy_from_quick(1.5)
	assert_almost_eq(creature.energy, plain_gain * 1.5, 0.0001)


# --- creature_species.best_creature_ability: species data, not instance state

func test_best_creature_ability_reads_a_real_species() -> void:
	var ability := SPECIES.best_creature_ability("terrapup")
	assert_true(ability.get("kind") in ["survivability", "energy"],
		"every shipped species should carry a real ability kind")
	assert_true(float(ability.get("value")) > 0.0)


func test_best_creature_ability_is_a_no_op_for_an_unknown_species() -> void:
	var ability := SPECIES.best_creature_ability("not_a_real_species")
	assert_eq(ability.get("kind"), "", "an unknown species must read as no ability, not crash")
	assert_eq(ability.get("value"), 0.0)


func test_every_shipped_species_has_a_best_creature_ability() -> void:
	for species_id: String in SPECIES.table().keys():
		var ability := SPECIES.best_creature_ability(species_id)
		assert_true(str(ability.get("kind")) != "",
			"%s has no Best Creature ability" % species_id)


# --- progression.gd::rest_bond: the "time together"/"resting" bond source --

func test_rest_bond_reads_from_config() -> void:
	var cfg := {"bond": {"per_day_in_party": 2}}
	assert_eq(PROGRESSION.rest_bond(cfg), 2)


func test_rest_bond_defaults_to_zero_when_missing() -> void:
	assert_eq(PROGRESSION.rest_bond({}), 0)


func test_rest_bond_matches_the_shipped_config() -> void:
	var cfg := PROGRESSION.config()
	var expected := int(cfg.get("bond", {}).get("per_day_in_party", 0))
	assert_eq(PROGRESSION.rest_bond(cfg), expected)
	assert_true(expected > 0, "resting together is supposed to be a real bond source, not a no-op")


# --- autoload/party.gd: the Best Creature designation ------------------------

var party: RefCounted = null


func before_each() -> void:
	party = PARTY.new()


func _fill(count: int) -> void:
	for i in count:
		party.add(_creature())


func test_no_best_creature_by_default() -> void:
	_fill(3)
	assert_eq(party.best_index(), -1)
	assert_eq(party.best(), null)


func test_set_best_flags_the_slot() -> void:
	_fill(3)
	assert_true(party.set_best(1))
	assert_eq(party.best_index(), 1)
	assert_eq(party.best(), party.at(1))


func test_set_best_again_on_the_same_slot_clears_it() -> void:
	_fill(3)
	party.set_best(1)
	assert_true(party.set_best(1))
	assert_eq(party.best_index(), -1, "pressing the toggle twice should clear the title")


func test_set_best_on_a_fainted_creature_is_allowed() -> void:
	# Unlike set_active, Best Creature is a standing title, not "who fights
	# next" -- a hurt or benched creature can still hold it.
	_fill(2)
	var creature: RefCounted = party.at(0)
	creature.take_damage(creature.max_hp)
	assert_true(creature.fainted)
	assert_true(party.set_best(0))
	assert_eq(party.best_index(), 0)


func test_set_best_out_of_range_is_refused() -> void:
	_fill(2)
	assert_false(party.set_best(9))
	assert_eq(party.best_index(), -1)


func test_removing_the_best_creature_clears_the_flag() -> void:
	_fill(3)
	party.set_best(2)
	party.remove_at(2)
	assert_eq(party.best_index(), -1)


func test_removing_a_slot_before_the_best_creature_shifts_the_index() -> void:
	_fill(3)
	var best_creature: RefCounted = party.at(2)
	party.set_best(2)
	party.remove_at(0)
	assert_eq(party.best_index(), 1, "the flagged creature is now one slot earlier")
	assert_eq(party.best(), best_creature)


func test_reordering_carries_the_best_creature_with_it() -> void:
	_fill(4)
	party.set_best(2)
	var flagged: RefCounted = party.best()
	party.move(2, 0)
	assert_eq(party.best(), flagged, "the flagged creature must not change")
	assert_eq(party.best_index(), 0)


func test_clear_resets_the_best_creature() -> void:
	_fill(2)
	party.set_best(1)
	party.clear()
	assert_eq(party.best_index(), -1)
	assert_eq(party.best(), null)
