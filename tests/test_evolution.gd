extends "res://tests/test_case.gd"

## R4.6: the evolution SYSTEM (scripts/creatures/evolution.gd), not the static
## species.json links `tests/test_evolution_links.gd` already pins.
##
## Uses a hand-built `evolution` config (test_progression.gd's own reasoning:
## the shipped numbers in data/config/progression.json are TUNABLE per
## CLAUDE.md, and a test pinning them would fail on every retune), but reads
## the REAL Mudsnout/Tuskroot link off the real species.json — that link
## itself is what `test_evolution_links.gd` guards, so this file only needs
## to prove the SYSTEM built on top of it, not re-derive the link's own
## correctness.

const EVOLUTION := preload("res://scripts/creatures/evolution.gd")
const SPECIES := preload("res://scripts/creatures/creature_species.gd")
const CREATURE := preload("res://scripts/creatures/creature_instance.gd")

const CFG_NO_ITEM := {
	"evolution": {"mudsnout": {"level": 15, "bond": 55, "item_id": ""}},
}
const CFG_WITH_ITEM := {
	"evolution": {"mudsnout": {"level": 15, "bond": 55, "item_id": "heartstone"}},
}


## A minimal stand-in for autoload/inventory.gd -- evolution.gd only ever
## calls `count(id)` and `remove(id, n)` on whatever it is handed, so a real
## Inventory (which needs a real ItemDB to construct) is more than this needs.
class FakeInventory:
	var counts: Dictionary = {}

	func count(id: String) -> int:
		return int(counts.get(id, 0))

	func remove(id: String, n: int) -> bool:
		if int(counts.get(id, 0)) < n:
			return false
		counts[id] = int(counts.get(id, 0)) - n
		return true


func _mudsnout(level: int, bond: int) -> RefCounted:
	var creature: RefCounted = SPECIES.spawn("mudsnout")
	creature.set("level", level)
	creature.set("bond", bond)
	return creature


func test_a_species_with_no_evolution_link_reports_ineligible() -> void:
	var creature: RefCounted = SPECIES.spawn("bramblebun")
	var result := EVOLUTION.check(creature, CFG_NO_ITEM)
	assert_false(bool(result.get("eligible")))
	assert_eq(str(result.get("target")), "")


func test_requirements_names_the_real_species_json_target() -> void:
	var req := EVOLUTION.requirements("mudsnout", CFG_NO_ITEM)
	assert_eq(str(req.get("target")), "tuskroot")
	assert_eq(int(req.get("level")), 15)
	assert_eq(int(req.get("bond")), 55)


func test_not_eligible_below_the_level_requirement() -> void:
	var creature := _mudsnout(10, 100)
	var result := EVOLUTION.check(creature, CFG_NO_ITEM)
	assert_false(bool(result.get("eligible")))
	assert_true(str(result.get("reason")).contains("level"),
		"refusal should explain the level gate: '%s'" % str(result.get("reason")))


func test_not_eligible_below_the_bond_requirement() -> void:
	var creature := _mudsnout(20, 10)
	var result := EVOLUTION.check(creature, CFG_NO_ITEM)
	assert_false(bool(result.get("eligible")))


func test_eligible_once_level_and_bond_are_both_met_with_no_item_required() -> void:
	var creature := _mudsnout(15, 55)
	var result := EVOLUTION.check(creature, CFG_NO_ITEM)
	assert_true(bool(result.get("eligible")))
	assert_eq(str(result.get("target")), "tuskroot")


func test_item_gate_refuses_without_the_item_and_spends_nothing() -> void:
	var creature := _mudsnout(15, 55)
	var inventory := FakeInventory.new()
	var result := EVOLUTION.check(creature, CFG_WITH_ITEM, inventory)
	assert_false(bool(result.get("eligible")))
	assert_false(EVOLUTION.evolve(creature, CFG_WITH_ITEM, inventory))
	assert_eq(creature.get("species_id"), "mudsnout", "a refused evolve must change nothing")


func test_item_gate_passes_and_consumes_exactly_one_with_the_item_in_hand() -> void:
	var creature := _mudsnout(15, 55)
	var inventory := FakeInventory.new()
	inventory.counts["heartstone"] = 2
	assert_true(bool(EVOLUTION.check(creature, CFG_WITH_ITEM, inventory).get("eligible")))
	assert_true(EVOLUTION.evolve(creature, CFG_WITH_ITEM, inventory))
	assert_eq(inventory.count("heartstone"), 1, "evolve must consume exactly one catalyst item")


func test_evolve_refuses_and_changes_nothing_when_not_eligible() -> void:
	var creature := _mudsnout(3, 0)
	var before_species: String = creature.get("species_id")
	assert_false(EVOLUTION.evolve(creature, CFG_NO_ITEM))
	assert_eq(creature.get("species_id"), before_species)


## The core promise: species/stats change, everything the player earned does
## not.
func test_evolve_changes_species_and_stats_but_preserves_what_the_player_earned() -> void:
	var creature := _mudsnout(20, 60)
	creature.set("nickname", "Snorty")
	creature.set("xp", 42)
	creature.set("iv_hp", 0.81)
	creature.set("trait_primary", "sturdy")
	creature.set("move_quick", "root_nibble")

	var hp_fraction_before: float = creature.call("hp_fraction")

	assert_true(EVOLUTION.evolve(creature, CFG_NO_ITEM))

	assert_eq(creature.get("species_id"), "tuskroot")
	assert_eq(creature.get("display_name"), str(SPECIES.definition("tuskroot").get("display_name")))
	assert_eq(float(creature.get("base_hp")), float(SPECIES.definition("tuskroot").get("base_hp")))

	# Earned state, untouched.
	assert_eq(creature.get("nickname"), "Snorty")
	assert_eq(int(creature.get("level")), 20)
	assert_eq(int(creature.get("xp")), 42)
	assert_eq(int(creature.get("bond")), 60)
	assert_eq(float(creature.get("iv_hp")), 0.81)
	assert_eq(creature.get("trait_primary"), "sturdy")
	assert_eq(creature.get("move_quick"), "root_nibble")

	# D17/D30: the hp FRACTION survives the transition, the same as any
	# level-up -- a Mudsnout mid-fight does not get topped up (or dropped)
	# by evolving.
	assert_almost_eq(float(creature.call("hp_fraction")), hp_fraction_before, 0.001,
		"hp fraction should survive an evolution the same way it survives a level-up")
