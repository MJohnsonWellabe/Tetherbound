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
const BOND_MILESTONES := preload("res://scripts/creatures/bond_milestones.gd")
const FEED := preload("res://scripts/creatures/progression_feed.gd")

const DEFINITION := {
	"display_name": "Terrapup", "type": "ground",
	"base_hp": 100.0, "base_attack": 20.0, "base_defence": 20.0,
}

## `bond.effects_per_node`/`traits.unlock_bond_nodes` still live in
## progression.json's own shape (unchanged by OWNER-0901-BOND-MILESTONES:
## they describe what a node BUYS, not how it is earned) — this is that
## config, hand-built the same reason every other progression test builds
## its own rather than reading the shipped, tunable file.
##
## `milestones` is folded into the SAME dict rather than kept separate: one
## config object plays both roles here, since `bond_nodes(cfg)` honours any
## cfg carrying a top-level `milestones` key instead of falling back to the
## real shipped ladder (data/config/bond_milestones.json), and
## `effective_attack`/`effective_defence`/`revealed_trait_secondary` all pass
## the ONE cfg they were given straight into `bond_nodes()` internally.
## Three short, round-numbered tasks, reusing real instance fields
## (`landmarks_visited_together`, `rest_nights_together`) so a test can drive
## them by simply setting properties on the creature.
const CFG := {
	"bond": {
		"effects_per_node": {"attack_scale": 0.01, "defence_scale": 0.02},
	},
	"xp_award": {"rest_bonus": 5},
	"milestones": [
		{"task": "battles_fought", "target": 2, "name": "wild creatures defeated together"},
		{"task": "landmarks_visited_together", "target": 1, "name": "landmarks discovered together"},
		{"task": "rest_nights_together", "target": 3, "name": "nights rested together"},
	],
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
	# All three of CFG's milestones met, in order: 2 wild wins, 1 landmark,
	# 3 nights rested -- tier 3 of 3.
	creature.battles_fought = 2
	creature.landmarks_visited_together = 1
	creature.rest_nights_together = 3
	var nodes: int = creature.bond_nodes(CFG)
	assert_eq(nodes, 3, "sanity: all three of CFG's milestones are met")
	assert_almost_eq(
		creature.effective_attack(CFG), creature.attack * (1.0 + 3.0 * 0.01), 0.0001
	)


func test_effective_defence_equals_plain_defence_at_zero_bond_and_no_ability() -> void:
	var creature := _creature()
	assert_almost_eq(creature.effective_defence(CFG), creature.defence, 0.0001)


func test_effective_defence_grows_with_bond_nodes() -> void:
	var creature := _creature()
	# All three of CFG's milestones met -- tier 3 of 3, CFG's own maximum.
	creature.battles_fought = 2
	creature.landmarks_visited_together = 1
	creature.rest_nights_together = 3
	assert_almost_eq(
		creature.effective_defence(CFG), creature.defence * (1.0 + 3.0 * 0.02), 0.0001
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


# --- bond_milestones.gd: bond as a ladder of tasks (OWNER-0901, D76) --------
##
## Owner playtest 2026-09-01: "I don't understand bond. It just goes up. It
## needs to be a task." D76 (2026-09-04): the ladder is UNORDERED -- a node is
## earned when ANY task completes, so every one of the five actions reads the
## moment it lands, and the "next" the UI points at is the incomplete task
## closest to done. These pin that rule: a tier only moves when a task is
## truly complete, any task counts, and nothing exceeds the ladder.

func test_tier_is_zero_for_a_fresh_creature() -> void:
	var creature := _creature()
	assert_eq(BOND_MILESTONES.tier(creature, CFG), 0)


func test_tier_advances_only_once_a_task_is_fully_met() -> void:
	var creature := _creature()
	creature.battles_fought = 1
	assert_eq(BOND_MILESTONES.tier(creature, CFG), 0, "1 of 2 required wins should not advance the tier")
	creature.battles_fought = 2
	assert_eq(BOND_MILESTONES.tier(creature, CFG), 1, "meeting the target should advance exactly one tier")


func test_a_later_task_alone_earns_a_node_d74() -> void:
	var creature := _creature()
	# CFG's SECOND milestone (landmarks) met while its first (battles) is not.
	creature.landmarks_visited_together = 1
	assert_eq(BOND_MILESTONES.tier(creature, CFG), 1,
		"D76: a completed task is a node whatever its position in the list -- "
		+ "under the old ordered rule this read 0 and the landmark was invisible")


func test_tier_counts_every_completed_task_in_any_order() -> void:
	var creature := _creature()
	creature.rest_nights_together = 3
	assert_eq(BOND_MILESTONES.tier(creature, CFG), 1)
	creature.battles_fought = 2
	assert_eq(BOND_MILESTONES.tier(creature, CFG), 2)
	creature.landmarks_visited_together = 1
	assert_eq(BOND_MILESTONES.tier(creature, CFG), 3, "every milestone in CFG's ladder is now met")


func test_tier_never_exceeds_the_ladder_length() -> void:
	var creature := _creature()
	creature.battles_fought = 999
	creature.landmarks_visited_together = 999
	creature.rest_nights_together = 999
	assert_eq(BOND_MILESTONES.tier(creature, CFG), 3, "CFG only has three milestones to complete")


func test_current_names_the_incomplete_task_closest_to_done() -> void:
	var creature := _creature()
	assert_eq(str(BOND_MILESTONES.current(creature, CFG).get("task", "")), "battles_fought",
		"all at zero: list order breaks the tie")
	creature.rest_nights_together = 2  # 2/3 = 0.67, ahead of battles 0/2
	assert_eq(str(BOND_MILESTONES.current(creature, CFG).get("task", "")), "rest_nights_together")
	creature.battles_fought = 2  # done; rest is still the nearest incomplete
	assert_eq(str(BOND_MILESTONES.current(creature, CFG).get("task", "")), "rest_nights_together")


func test_progress_text_names_the_nearest_task() -> void:
	var creature := _creature()
	assert_eq(BOND_MILESTONES.progress_text(creature, CFG), "0/2 wild creatures defeated together")
	creature.battles_fought = 2
	assert_eq(BOND_MILESTONES.progress_text(creature, CFG), "0/1 landmarks discovered together")


func test_progress_text_reports_fully_bonded_once_every_milestone_is_done() -> void:
	var creature := _creature()
	creature.battles_fought = 2
	creature.landmarks_visited_together = 1
	creature.rest_nights_together = 3
	assert_eq(BOND_MILESTONES.progress_text(creature, CFG), "Fully bonded")


func test_task_rows_mark_done_and_exactly_one_next() -> void:
	var creature := _creature()
	creature.battles_fought = 2
	creature.rest_nights_together = 1
	var rows := BOND_MILESTONES.task_rows(creature, CFG)
	assert_eq(rows.size(), 3, "one row per task, every task, not only the current one")
	var next_count := 0
	for row: Variant in rows:
		var r := row as Dictionary
		if bool(r.get("next", false)):
			next_count += 1
	assert_eq(next_count, 1)
	assert_true(bool((rows[0] as Dictionary).get("done", false)), "battles 2/2 is done")
	assert_false(bool((rows[0] as Dictionary).get("next", true)), "a done row is never next")
	assert_true(bool((rows[2] as Dictionary).get("next", false)), "rest 1/3 is the nearest incomplete")
	assert_eq(int((rows[2] as Dictionary).get("remaining", 0)), 2)
	assert_eq(BOND_MILESTONES.remaining_text(rows[2]), "2 more nights")
	assert_eq(BOND_MILESTONES.remaining_text(rows[0]), "", "a done row has nothing left to say")


func test_evolution_gate_reads_any_three_nodes() -> void:
	# progression.json: mudsnout needs bond_tier 3. Under D76 that is any three.
	var cfg := PROGRESSION.config()
	var needed := int(cfg.get("evolution", {}).get("mudsnout", {}).get("bond_tier", 0))
	assert_eq(needed, 3, "sanity: the shipped gate is three nodes")
	var creature := _creature()
	creature.species_id = "mudsnout"
	creature.landmarks_visited_together = 99
	creature.rest_nights_together = 99
	creature.feeds_together = 99
	assert_eq(creature.bond_nodes(), 3, "three completed tasks, none of them the first, is tier 3")


# --- the feed's bond events (PROGRESSION-VISIBLE, prompt 73 §4) --------------

func test_bond_near_fires_at_the_configured_remaining_count_and_not_before() -> void:
	FEED.clear()
	var creature := _creature()
	var threshold := int(FEED.near_threshold("battles_fought"))
	assert_true(threshold > 0, "sanity: progression_feedback.json has a near threshold for battles")
	var target := 0
	for entry: Variant in BOND_MILESTONES.milestones(BOND_MILESTONES.config()):
		if str((entry as Dictionary).get("task", "")) == "battles_fought":
			target = int((entry as Dictionary).get("target", 0))
	for i in target - threshold - 1:
		BOND_MILESTONES.credit_battle(creature)
	assert_eq(_feed_kind("bond_near").size(), 0,
		"%d short of %d is not yet near (threshold %d)" % [target - creature.battles_fought, target, threshold])
	BOND_MILESTONES.credit_battle(creature)
	assert_eq(_feed_kind("bond_near").size(), 1, "exactly the threshold short: near fires")
	assert_eq(int((_feed_kind("bond_near")[0] as Dictionary).get("remaining", -1)), threshold)


func test_bond_milestone_carries_the_correct_benefit_text() -> void:
	FEED.clear()
	var creature := _creature()
	creature.species_id = "mudsnout"
	# Two nodes already held; the third completes Mudsnout's evolution tier.
	creature.landmarks_visited_together = 99
	creature.rest_nights_together = 99
	var target := 0
	for entry: Variant in BOND_MILESTONES.milestones(BOND_MILESTONES.config()):
		if str((entry as Dictionary).get("task", "")) == "feeds_together":
			target = int((entry as Dictionary).get("target", 0))
	for i in target:
		BOND_MILESTONES.credit_feed(creature)
	var milestones := _feed_kind("bond_milestone")
	assert_eq(milestones.size(), 1)
	var event: Dictionary = milestones[0]
	assert_eq(int(event.get("node", 0)), 3)
	var benefit := str(event.get("benefit", ""))
	assert_true(benefit.contains("+1% attack and defence"), benefit)
	assert_true(benefit.contains("now +3%"), "the cumulative bonus is named: " + benefit)
	assert_true(benefit.contains("unlocks evolution"),
		"node 3 is Mudsnout's evolution tier and the milestone must say so: " + benefit)
	assert_false(benefit.contains("second trait"), "the trait comes at node 5, not 3: " + benefit)


func test_the_fifth_node_says_it_reveals_the_second_trait() -> void:
	var creature := _creature()
	var text := BOND_MILESTONES.benefit_text(5, creature, PROGRESSION.config())
	assert_true(text.contains("reveals second trait"), text)
	assert_false(text.contains("unlocks evolution"), "terrapup does not evolve: " + text)


func test_next_benefit_text_is_empty_once_fully_bonded() -> void:
	var creature := _creature()
	assert_true(BOND_MILESTONES.next_benefit_text(creature, CFG, PROGRESSION.config()).contains("+1%"))
	creature.battles_fought = 2
	creature.landmarks_visited_together = 1
	creature.rest_nights_together = 3
	assert_eq(BOND_MILESTONES.next_benefit_text(creature, CFG, PROGRESSION.config()), "")


func _feed_kind(kind: String) -> Array:
	var out: Array = []
	for event: Variant in FEED.events():
		if str((event as Dictionary).get("kind", "")) == kind:
			out.append(event)
	return out


# --- crediting helpers: the four tasks with no pre-existing counter --------

func test_credit_landmark_visit_accumulates() -> void:
	var creature := _creature()
	BOND_MILESTONES.credit_landmark_visit(creature)
	BOND_MILESTONES.credit_landmark_visit(creature)
	assert_eq(int(creature.get("landmarks_visited_together")), 2)


func test_credit_distance_accumulates_and_ignores_non_positive() -> void:
	var creature := _creature()
	BOND_MILESTONES.credit_distance(creature, 12.5)
	BOND_MILESTONES.credit_distance(creature, 3.5)
	BOND_MILESTONES.credit_distance(creature, -100.0)
	BOND_MILESTONES.credit_distance(creature, 0.0)
	assert_almost_eq(float(creature.get("distance_m_together")), 16.0, 0.0001)


func test_credit_rest_night_accumulates() -> void:
	var creature := _creature()
	BOND_MILESTONES.credit_rest_night(creature)
	assert_eq(int(creature.get("rest_nights_together")), 1)


func test_credit_feed_accumulates() -> void:
	var creature := _creature()
	BOND_MILESTONES.credit_feed(creature)
	BOND_MILESTONES.credit_feed(creature)
	BOND_MILESTONES.credit_feed(creature)
	assert_eq(int(creature.get("feeds_together")), 3)


# --- the shipped ladder itself -----------------------------------------------

func test_shipped_ladder_matches_the_owners_own_first_milestone() -> void:
	var list := BOND_MILESTONES.milestones(BOND_MILESTONES.config())
	assert_true(list.size() > 0, "bond_milestones.json shipped no milestones")
	var first := list[0] as Dictionary
	assert_eq(str(first.get("task", "")), "battles_fought")
	assert_eq(int(first.get("target", 0)), 50,
		"OWNER-0901: 'defeat 50 wild creatures together' is the owner's own exact number")


func test_shipped_ladder_has_five_milestones_matching_the_stat_scale_and_trait_unlock() -> void:
	var cfg := PROGRESSION.config()
	var list := BOND_MILESTONES.milestones(BOND_MILESTONES.config())
	assert_eq(list.size(), 5, "the milestone ladder should still produce the same 0-5 tier "
		+ "progression.json's traits.unlock_bond_nodes and bond.effects_per_node assume")
	var unlock_required := int(cfg.get("traits", {}).get("unlock_bond_nodes", 5))
	assert_eq(unlock_required, list.size(),
		"the second-trait unlock should require every milestone, i.e. 'fully bonded'")


## Every task must be a real, ever-growing field on a fresh instance, and
## every target must be reachable in principle (positive) -- a milestone with
## a target of 0 or a task naming no field would silently complete itself.
func test_every_shipped_milestone_names_a_real_field_with_a_positive_target() -> void:
	var creature := _creature()
	for entry: Variant in BOND_MILESTONES.milestones(BOND_MILESTONES.config()):
		var m := entry as Dictionary
		var task := str(m.get("task", ""))
		assert_true(creature.has_method("get") and typeof(creature.get(task)) != TYPE_NIL,
			"milestone task '%s' names no field on creature_instance.gd" % task)
		assert_true(int(m.get("target", 0)) > 0, "milestone task '%s' has no positive target" % task)


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
