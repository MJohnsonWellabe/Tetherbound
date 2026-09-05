extends "res://tests/test_case.gd"

## W10-TRAINER-RULES. The three rules the owner set on 2026-09-04
## (`docs/owner/OWNER_DIRECTIVES_2026-09-04-B.md`, amendments A-1/A-2/A-4):
##
##   1. a beaten trainer stops advertising a fight (`prompt_for`)
##   2. you cannot walk out of a trainer fight; a wild one you still can
##      (`combat_manager.gd::can_flee`/`try_flee`)
##   3. a trainer under whose level condition you fall refuses IN CHARACTER,
##      and the fight never starts (`below_challenge_level`)
##
## Each of these is silent when it breaks. The prompt one was live for the whole
## project and nothing noticed: `_prompt_for()` was unconditional, so every
## beaten trainer in the chapter went on offering "Challenge <name>" for a fight
## `can_challenge()` had already decided to refuse -- a visible prompt the
## button refuses, which `interactable.gd`'s own header calls worse than no
## prompt at all. The flee one fails the same way: a trainer fight you can quit
## simply plays as it always did, and the only instrument that notices is a
## person playing the chapter.
##
## Per docs/decisions/D02 this file is logic only -- standing a trainer on
## Terrain3D and beating them is `tests/smoke_trainer_battle.gd`'s job, and it
## checks the same three rules against a real world.

const TRAINERS := preload("res://scripts/world/trainer_npc.gd")
const COMBAT := preload("res://scripts/combat/combat_manager.gd")
const PROGRESSION_STATE := preload("res://autoload/progression_state.gd")
const PARTY := preload("res://autoload/party.gd")
const SPECIES := preload("res://scripts/creatures/creature_species.gd")
const PROGRESSION := preload("res://scripts/creatures/progression.gd")
const RUNNER := preload("res://scripts/story/dialogue_runner.gd")

## A trainer row shaped like the real table's, with no level condition -- the
## shape every shipped row has today.
const _SPEC := {
	"id": "test_trainer",
	"name": "Bryn",
	"defeat_flag": "test_trainer_beaten",
	"challenge": "trainer_practice_challenge",
	"defeated": "trainer_practice_defeated",
	"team": [{"species": "terrapup", "level": 5}],
}


func _party_at_levels(levels: Array) -> RefCounted:
	var party: RefCounted = PARTY.new()
	for level: Variant in levels:
		var creature: RefCounted = SPECIES.spawn("terrapup")
		creature.set_level(int(level), PROGRESSION.config())
		party.add(creature)
	return party


# --- CL-W5(a): the Challenge button stops advertising a fight -----------------

func test_an_unbeaten_trainer_still_offers_the_challenge() -> void:
	var progression: RefCounted = PROGRESSION_STATE.new()
	assert_eq(TRAINERS.prompt_for(_SPEC, progression), "Challenge Bryn",
		"an unbeaten trainer must still offer their fight")


func test_a_beaten_trainer_stops_offering_the_challenge() -> void:
	var progression: RefCounted = PROGRESSION_STATE.new()
	progression.call("set_flag", "test_trainer_beaten")
	var prompt: String = TRAINERS.prompt_for(_SPEC, progression)
	assert_false(prompt.to_lower().contains("challenge"),
		"a beaten trainer still advertises a fight the button will refuse (got '%s')" % prompt)
	assert_true(prompt.contains("Bryn"),
		"the beaten prompt lost the trainer's name (got '%s')" % prompt)


func test_a_beaten_trainer_still_offers_something() -> void:
	# Not silence: amendment A-2 is "just talk to or whatever", not "the prompt
	# disappears". They are a person you beat, not a used-up switch.
	var progression: RefCounted = PROGRESSION_STATE.new()
	progression.call("set_flag", "test_trainer_beaten")
	assert_ne(TRAINERS.prompt_for(_SPEC, progression), "",
		"a beaten trainer offers nothing at all; the body reads as broken scenery")


func test_no_trainer_prompt_can_be_mistaken_for_grandpa_or_a_starter() -> void:
	# The trap amendment A-2 names by hand: `tests/smoke_opening.gd` finds
	# Grandpa and the three starters by the substrings "talk" and "choose", so
	# the obvious wording for the beaten prompt ("Talk to %s") would make every
	# trainer in the world look like a starter to the opening smoke.
	var progression: RefCounted = PROGRESSION_STATE.new()
	for entry: Variant in TRAINERS.trainers():
		var spec: Dictionary = entry
		for beaten: bool in [false, true]:
			if beaten:
				progression.call("set_flag", str(spec.get("defeat_flag", "")))
			var prompt: String = TRAINERS.prompt_for(spec, progression).to_lower()
			assert_false(prompt.contains("talk"),
				"trainer '%s' offers '%s'; smoke_opening.gd finds the starters by \"talk\"" % [
					str(spec.get("id", "")), prompt])
			assert_false(prompt.contains("choose"),
				"trainer '%s' offers '%s'; smoke_opening.gd finds the starters by \"choose\"" % [
					str(spec.get("id", "")), prompt])


# --- CL-W5(b): you cannot walk out of a trainer fight -------------------------

## A real `CombatManager`, not stood in a world: `begin()` needs a player, a
## wild body and a deployed ally on real ground, which is
## `tests/smoke_trainer_battle.gd`'s job and not this file's (D02). What is
## under test here is the DECISION -- whose creature is on the other side of
## the arena, and what the disengage button does about it -- and that decision
## reads exactly one field, the same `_enemy_owned` `begin()` sets from
## `encounter_director.gd::begin_trainer_battle()` and the same one that
## already refuses a catch on somebody else's creature.
func _manager(opponent_owned: bool) -> Node:
	var manager: Node = COMBAT.new()
	manager.set("_enemy_owned", opponent_owned)
	return manager


func test_a_wild_fight_can_still_be_left() -> void:
	var manager := _manager(false)
	assert_true(bool(manager.call("can_flee")),
		"a wild fight must stay leavable; amendment A-1 keeps that exit on purpose")
	assert_eq(str(manager.call("flee_refusal")), "",
		"a wild fight refuses the disengage button it is supposed to honour")
	assert_true(bool(manager.call("try_flee")),
		"the disengage button did not end a wild fight")
	assert_eq(int(manager.get("state")), int(COMBAT.State.RESOLVING),
		"leaving a wild fight did not put the fight into RESOLVING")
	manager.free()


func test_a_trainer_fight_cannot_be_left() -> void:
	var manager := _manager(true)
	assert_false(bool(manager.call("can_flee")),
		"a trainer fight is leavable; the owner's rule is that it is a commitment")
	assert_false(bool(manager.call("try_flee")),
		"the disengage button ended a trainer fight")
	assert_eq(int(manager.get("state")), int(COMBAT.State.INACTIVE),
		"a refused disengage still moved the fight out of the state it was in")
	manager.free()


func test_a_refused_disengage_says_why() -> void:
	# A dead button with no explanation reads as a broken build -- a blind
	# playtest reached exactly that verdict about three combat buttons once
	# already, which is why `_refuse_combat_input()` exists at all.
	var manager := _manager(true)
	var said := str(manager.call("flee_refusal"))
	assert_ne(said, "",
		"a refused disengage says nothing; the button reads as broken rather than closed")
	assert_eq(said, COMBAT.FLEE_REFUSED_MESSAGE)
	assert_true(said.to_lower().contains("walk away"),
		"the refusal does not say what it is refusing (got '%s')" % said)
	manager.free()


# --- CL-W4: the level gate, and what it measures ------------------------------

func test_a_row_with_no_level_condition_gates_nothing() -> void:
	# Every shipped row today. A gate that appeared by default would lock the
	# whole chapter behind a number nobody authored.
	assert_eq(TRAINERS.required_level(_SPEC), 0,
		"a trainer with no min_level reports one")
	assert_false(TRAINERS.below_challenge_level(_SPEC, _party_at_levels([1])),
		"a level-1 party is refused by a trainer that names no level")


func test_no_shipped_trainer_carries_a_level_condition_yet() -> void:
	# docs/FINISH_THE_MEADOWS.md's stated dependency: wild density lands before
	# a level gate goes on the route, or the gate is the wall D-0904B-4 says it
	# must not be. This is the mechanism, deliberately not yet turned on.
	for entry: Variant in TRAINERS.trainers():
		var spec: Dictionary = entry
		assert_eq(TRAINERS.required_level(spec), 0,
			"trainer '%s' carries a level gate; density lands first (D79)" % str(spec.get("id", "")))


func test_a_level_condition_refuses_a_party_below_it() -> void:
	var gated := _SPEC.duplicate(true)
	gated["min_level"] = 10
	assert_eq(TRAINERS.required_level(gated), 10)
	assert_true(TRAINERS.below_challenge_level(gated, _party_at_levels([4, 6, 9])),
		"a party topping out at 9 was accepted by a trainer who wants 10")
	assert_false(TRAINERS.below_challenge_level(gated, _party_at_levels([4, 6, 10])),
		"a party with a level-10 creature was refused by a trainer who wants 10")


func test_the_gate_reads_the_highest_creature_not_the_first_or_the_average() -> void:
	# D79. Ordered lowest-last and lowest-first so a first-slot or last-slot
	# reading fails, and with an average of 4 against a requirement of 8 so an
	# averaging reading fails too.
	var gated := _SPEC.duplicate(true)
	gated["min_level"] = 8
	assert_false(TRAINERS.below_challenge_level(gated, _party_at_levels([1, 1, 1, 1, 8])),
		"a level-8 creature in the last slot did not satisfy the gate")
	assert_false(TRAINERS.below_challenge_level(gated, _party_at_levels([8, 1, 1, 1, 1])),
		"a level-8 creature in the first slot did not satisfy the gate")
	assert_eq(TRAINERS.party_high_level(_party_at_levels([1, 1, 1, 1, 8])), 8,
		"the gate is not reading the party's highest level")


func test_challenge_level_is_accepted_as_an_alias() -> void:
	var gated := _SPEC.duplicate(true)
	gated["challenge_level"] = 12
	assert_eq(TRAINERS.required_level(gated), 12,
		"a row authored with `challenge_level` silently gates nothing")


func test_a_scene_with_no_party_invents_no_gate() -> void:
	var gated := _SPEC.duplicate(true)
	gated["min_level"] = 10
	assert_false(TRAINERS.below_challenge_level(gated, null),
		"a scene with no Game autoload invented a level gate out of nothing")


func test_the_too_low_line_exists_and_says_what_the_owner_asked_for() -> void:
	assert_true(RUNNER.has(TRAINERS.TOO_LOW_CONVERSATION),
		"the level gate refuses through a conversation no dialogue file defines")
	var lines: Array = RUNNER.table().get(TRAINERS.TOO_LOW_CONVERSATION, {}).get("lines", [])
	assert_false(lines.is_empty(), "the too-low conversation has no lines")
	assert_true(str(lines[0]).contains("too low level"),
		"the taunt lost the owner's own wording")
	var joined := " ".join(lines)
	assert_true(joined.contains("$level"),
		"the taunt names no level, so the refusal hands the player nothing to do about it")


func test_the_too_low_line_is_not_the_already_beaten_line() -> void:
	# The dark-features T1 collapse, in the shape CL-W4 warns about: a too-low
	# player told "you already beat me" is told something false about a fight
	# they have never had.
	for entry: Variant in TRAINERS.trainers():
		var spec: Dictionary = entry
		assert_ne(TRAINERS.TOO_LOW_CONVERSATION, str(spec.get("defeated", "")),
			"trainer '%s' would answer a too-low player with their defeated line" % str(spec.get("id", "")))
