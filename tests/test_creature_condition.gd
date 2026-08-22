extends "res://tests/test_case.gd"

## RG19-spec / D68 — rested, fed and happy.
##
## The owner's entry rule for the village tournament, in his own words: "They
## have to be well rested, well fed, and happy." Every failure here is one a
## player would meet as a gate that lies — a team the marshal refuses for a
## reason that is not true, or lets in when it should not.
##
## Pure logic, no scene tree, the same split `test_bond.gd` and
## `test_progression_state.gd` draw.

const CONDITION := preload("res://scripts/creatures/creature_condition.gd")
const SPECIES := preload("res://scripts/creatures/creature_species.gd")

var creature: RefCounted = null
var cfg: Dictionary = {}


func before_each() -> void:
	creature = SPECIES.spawn("bramblebun")
	cfg = CONDITION.config()
	CONDITION.start(creature, cfg)


## A creature that has just been caught is not automatically tournament-ready.
## If it were, the gate would never teach anything.
func test_a_fresh_creature_starts_short_of_ready() -> void:
	assert_false(CONDITION.is_rested(creature, cfg), "a just-caught creature has not slept in a bed")
	assert_false(bool(CONDITION.summary(creature, cfg).get("ready", false)),
		"a just-caught creature is already tournament-ready; the gate teaches nothing")


func test_the_starting_values_come_from_the_config() -> void:
	assert_almost_eq(float(creature.get("nourishment")),
		float(cfg.get("nourishment", {}).get("start", 70.0)), 0.001)
	assert_almost_eq(float(creature.get("happiness")),
		float(cfg.get("happiness", {}).get("start", 55.0)), 0.001)


## D29's rule, extended to creatures: hunger is LIGHT. It never damages, never
## kills, and never removes a creature from the party.
func test_starving_a_creature_never_hurts_it() -> void:
	var hp_before := float(creature.get("hp"))
	CONDITION.tick(creature, cfg, 60.0 * 60.0 * 4.0)
	assert_almost_eq(float(creature.get("nourishment")), 0.0, 0.001)
	assert_almost_eq(float(creature.get("hp")), hp_before, 0.001,
		"hunger took HP; D29 says food is a buff and starvation is not a mechanic")
	assert_false(bool(creature.get("fainted")), "hunger fainted a creature")


func test_nourishment_drains_over_real_time() -> void:
	var before := float(creature.get("nourishment"))
	CONDITION.tick(creature, cfg, 60.0)
	var drain := float(cfg.get("nourishment", {}).get("drain_per_minute", 1.1))
	assert_almost_eq(float(creature.get("nourishment")), before - drain, 0.001)


## A creature asleep in a bed is not going hungry in it.
func test_a_resting_creature_does_not_starve_in_its_bed() -> void:
	creature.set("resting", true)
	var before := float(creature.get("nourishment"))
	CONDITION.tick(creature, cfg, 60.0 * 30.0)
	assert_almost_eq(float(creature.get("nourishment")), before, 0.001)


func test_feeding_restores_the_meter_and_lifts_the_mood() -> void:
	creature.set("nourishment", 10.0)
	var mood_before := float(creature.get("happiness"))
	var fed: Dictionary = CONDITION.feed(creature, cfg, {"nourishment": 35.0, "happiness": 8.0})
	assert_true(bool(fed.get("accepted", false)), "the creature refused food while nearly empty")
	assert_almost_eq(float(creature.get("nourishment")), 45.0, 0.001)
	assert_true(float(creature.get("happiness")) > mood_before, "being fed did not improve the mood")


## A full creature refuses, so the backpack does not spend a berry on nothing.
func test_a_full_creature_refuses_plain_food() -> void:
	creature.set("nourishment", float(cfg.get("nourishment", {}).get("max", 100.0)))
	var fed: Dictionary = CONDITION.feed(creature, cfg, {"nourishment": 35.0, "happiness": 0.0})
	assert_false(bool(fed.get("accepted", false)), "a full creature ate a berry it did not need")


func test_feeding_cannot_push_past_the_maximum() -> void:
	var maximum := float(cfg.get("nourishment", {}).get("max", 100.0))
	creature.set("nourishment", maximum - 1.0)
	CONDITION.feed(creature, cfg, {"nourishment": 500.0})
	assert_almost_eq(float(creature.get("nourishment")), maximum, 0.001)


## The three states are three different verbs. Feeding a creature does not
## make it rested, and resting it does not make it fed.
func test_the_three_states_are_earned_separately() -> void:
	creature.set("nourishment", float(cfg.get("nourishment", {}).get("max", 100.0)))
	creature.set("happiness", float(cfg.get("happiness", {}).get("max", 100.0)))
	assert_true(CONDITION.is_fed(creature, cfg))
	assert_true(CONDITION.is_happy(creature, cfg))
	assert_false(CONDITION.is_rested(creature, cfg),
		"a fed and happy creature counted as rested without ever seeing a bed")

	CONDITION.note_rest_completed(creature, cfg)
	assert_true(CONDITION.is_rested(creature, cfg))
	assert_true(bool(CONDITION.summary(creature, cfg).get("ready", false)))


## A night in a bed is what "well rested" means, and it wears off.
func test_rest_lapses_after_the_configured_time_awake() -> void:
	CONDITION.note_rest_completed(creature, cfg)
	assert_true(CONDITION.is_rested(creature, cfg))
	var minutes := float(cfg.get("rest", {}).get("stays_rested_minutes", 45.0))
	CONDITION.tick(creature, cfg, minutes * 60.0 - 1.0)
	assert_true(CONDITION.is_rested(creature, cfg), "rest lapsed early")
	CONDITION.tick(creature, cfg, 2.0)
	assert_false(CONDITION.is_rested(creature, cfg), "rest never lapsed")


## Being knocked out is the one case where calling a creature rested is a lie.
func test_fainting_costs_the_rest_and_the_mood() -> void:
	CONDITION.note_rest_completed(creature, cfg)
	var mood := float(creature.get("happiness"))
	CONDITION.note_faint(creature, cfg)
	assert_false(CONDITION.is_rested(creature, cfg), "a creature knocked out still counted as rested")
	assert_true(float(creature.get("happiness")) < mood, "being knocked out cost no mood at all")


func test_a_fainted_creature_is_never_ready() -> void:
	creature.set("nourishment", 100.0)
	creature.set("happiness", 100.0)
	CONDITION.note_rest_completed(creature, cfg)
	creature.set("fainted", true)
	var state := CONDITION.summary(creature, cfg)
	assert_false(bool(state.get("ready", false)), "a fainted creature was allowed into the tournament")
	assert_true((state.get("reasons", []) as Array).has("needs reviving"))


## Winning together is the happiness source ordinary tournament preparation
## produces, so preparing for the tournament makes the team fit for it.
func test_winning_fights_raises_the_mood() -> void:
	var before := float(creature.get("happiness"))
	CONDITION.note_victory(creature, cfg)
	assert_true(float(creature.get("happiness")) > before)


func test_a_fainted_creature_takes_no_credit_for_the_win() -> void:
	creature.set("fainted", true)
	var before := float(creature.get("happiness"))
	CONDITION.note_victory(creature, cfg)
	assert_almost_eq(float(creature.get("happiness")), before, 0.001)


## Hunger drags the mood down as well, which is what makes an ignored team
## slide out of readiness rather than sitting there forever.
func test_hunger_drags_the_mood_down_faster() -> void:
	var fed_copy: RefCounted = SPECIES.spawn("bramblebun")
	CONDITION.start(fed_copy, cfg)
	fed_copy.set("nourishment", float(cfg.get("nourishment", {}).get("max", 100.0)))
	creature.set("nourishment", 0.0)

	CONDITION.tick(creature, cfg, 60.0 * 10.0)
	CONDITION.tick(fed_copy, cfg, 60.0 * 10.0)
	assert_true(float(creature.get("happiness")) < float(fed_copy.get("happiness")),
		"a starving creature stayed as happy as a fed one")


## The player has to be able to READ the gate, not just fail it.
func test_the_summary_names_what_to_go_and_fix() -> void:
	creature.set("nourishment", 0.0)
	creature.set("happiness", 0.0)
	var reasons: Array = CONDITION.summary(creature, cfg).get("reasons", [])
	assert_eq(reasons.size(), 3, "a tired, starving, miserable creature listed %s" % str(reasons))
	assert_true(CONDITION.label(creature, cfg).contains("Hungry"))
	assert_true(CONDITION.label(creature, cfg).contains("Tired"))


func test_the_label_reads_as_ready_when_it_is() -> void:
	creature.set("nourishment", 100.0)
	creature.set("happiness", 100.0)
	CONDITION.note_rest_completed(creature, cfg)
	assert_eq(CONDITION.label(creature, cfg), "Rested · Fed · Happy")


## Nothing here may be interpreted anywhere else: every threshold this file
## checks has to come from the config, so a tuning pass is a data edit.
func test_every_threshold_is_data() -> void:
	for key: String in ["fed_at", "hungry_below"]:
		assert_true((cfg.get("nourishment", {}) as Dictionary).has(key),
			"creature_condition.json has no nourishment.%s" % key)
	assert_true((cfg.get("happiness", {}) as Dictionary).has("happy_at"),
		"creature_condition.json has no happiness.happy_at")
	assert_true((cfg.get("rest", {}) as Dictionary).has("stays_rested_minutes"),
		"creature_condition.json has no rest.stays_rested_minutes")
