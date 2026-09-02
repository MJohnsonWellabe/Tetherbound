extends "res://tests/test_case.gd"

## The shape of the first fifteen minutes.
##
## Two kinds of check, and they are different in kind — the same split
## `test_dialogue_runner.gd` makes. One is the reader: order, lookup, the
## refusal to run off the end. The other is the DATA, and it is the half that
## earns its keep. Every failure mode this file guards is silent at run time: a
## beat renamed in opening.json, an effect the writer added to a line that no
## beat answers to, a conversation id with a typo in it. None of them crash.
## They produce a player standing in a meadow with nothing to do.
##
## `sequence_director.gd` itself is not tested here. Per docs/decisions/D02 the
## suite is pure logic only — it is a node that spawns creatures onto terrain and
## opens panels, and pretending a headless assertion covers that is how a green
## suite starts lying.

const BEATS := preload("res://scripts/story/opening_beats.gd")
const RUNNER := preload("res://scripts/story/dialogue_runner.gd")
## F3. `grandpa_conversations_when()`'s branches are read through the exact
## same reader village_npcs.json's `greeting_when` ladders use, so the ladder
## logic itself is covered by that file's own tests -- what belongs here is
## the DATA: every branch this file names has to exist, speak, and win in the
## right order.
const VILLAGE_NPCS := preload("res://scripts/world/village_npcs.gd")
const PROGRESSION_STATE := preload("res://autoload/progression_state.gd")


func test_the_beats_come_out_in_the_order_the_config_lists_them() -> void:
	var order := BEATS.order()
	assert_true(order.size() >= 5, "the opening is nine beats of prose and at least five states")
	assert_eq(order[0], BEATS.first(), "first() should be the head of the list")
	assert_eq(order[order.size() - 1], BEATS.FREE_PLAY, "the sequence ends in free play")


func test_comment_keys_are_not_beats() -> void:
	for beat: String in BEATS.order():
		assert_false(beat.begins_with("_"), "'%s' is a comment, not a beat" % beat)


func test_every_beat_the_state_machine_names_is_in_the_data() -> void:
	var missing: Array[String] = BEATS.missing_beats()
	assert_true(missing.is_empty(),
		"opening.json is missing beat(s) the director gates on: %s" % ", ".join(missing))


func test_next_runs_out_rather_than_looping() -> void:
	var order := BEATS.order()
	for i in order.size() - 1:
		assert_eq(BEATS.next(order[i]), order[i + 1])
	assert_eq(BEATS.next(order[order.size() - 1]), "", "there is nothing after free play")
	assert_eq(BEATS.next("no_such_beat"), "")


func test_at_or_after_locks_rather_than_opens_when_it_does_not_know() -> void:
	assert_true(BEATS.at_or_after(BEATS.ROAD, BEATS.CHOOSE))
	assert_true(BEATS.at_or_after(BEATS.CHOOSE, BEATS.CHOOSE), "at counts as at-or-after")
	assert_false(BEATS.at_or_after(BEATS.CHOOSE, BEATS.ROAD))
	assert_false(BEATS.at_or_after("no_such_beat", BEATS.CHOOSE), "an unknown beat stays locked")
	assert_false(BEATS.at_or_after(BEATS.CHOOSE, "no_such_beat"))


func test_the_opening_delivers_one_goal_at_a_time_before_qualification() -> void:
	assert_true(BEATS.index_of(BEATS.WAKE) < BEATS.index_of(BEATS.HOUSE),
		"you wake before you come downstairs")
	assert_true(BEATS.index_of(BEATS.HOUSE) < BEATS.index_of(BEATS.CHOOSE),
		"the briefing comes before the door opens on the starters")
	assert_true(BEATS.index_of(BEATS.CHOOSE) < BEATS.index_of(BEATS.NAMED))
	assert_true(BEATS.index_of(BEATS.NAMED) < BEATS.index_of(BEATS.RETURN_STARTER),
		"naming returns the player to Grandpa before the catch objective")
	assert_true(BEATS.index_of(BEATS.RETURN_STARTER) < BEATS.index_of(BEATS.WALK_OUT))
	assert_true(BEATS.index_of(BEATS.WALK_OUT) < BEATS.index_of(BEATS.ENCOUNTER))
	assert_true(BEATS.index_of(BEATS.ENCOUNTER) < BEATS.index_of(BEATS.ROAD))
	assert_true(BEATS.index_of(BEATS.ROAD) < BEATS.index_of(BEATS.VISIT_MIRA))
	assert_true(BEATS.index_of(BEATS.VISIT_MIRA) < BEATS.index_of(BEATS.RETURN_MIRA))
	assert_true(BEATS.index_of(BEATS.RETURN_MIRA) < BEATS.index_of(BEATS.TOURNAMENT_SIGNUP))
	assert_true(BEATS.index_of(BEATS.TOURNAMENT_SIGNUP) < BEATS.index_of(BEATS.QUALIFICATION))
	assert_true(BEATS.index_of(BEATS.ROAD) < BEATS.index_of(BEATS.FREE_PLAY))


func test_every_conversation_a_beat_names_really_exists() -> void:
	for beat: String in BEATS.order():
		var id := BEATS.conversation_for(beat)
		if id == "":
			continue
		assert_true(RUNNER.has(id), "beat '%s' names conversation '%s', which is not in opening.json" % [beat, id])
	assert_eq(BEATS.named_conversation(), "",
		"naming should return naturally to Grandpa instead of opening another automatic dialogue")


func test_he_has_nothing_scripted_left_once_the_sequence_is_over() -> void:
	assert_eq(BEATS.conversation_for(BEATS.FREE_PLAY), "",
		"free play is where the scripting stops; a conversation here would repeat his send-off forever")


## F3 (audit F-2026-08-31.md's F3): Grandpa went silent from tournament
## sign-up onward with no reaction to any mid-chapter milestone. Every branch
## the ladder can reach has to actually exist and speak, the same guard
## `test_dialogue_runner.gd::test_every_conversation_a_villager_can_open_really_exists`
## keeps on every villager's `greeting_when`.
func test_every_conversation_grandpas_ladder_names_really_exists() -> void:
	var branches := BEATS.grandpa_conversations_when()
	assert_false(branches.is_empty(), "F3's mid-chapter ladder should not be empty")
	for raw: Variant in branches:
		assert_true(raw is Dictionary, "a grandpa_conversations_when entry is not an object")
		var branch := raw as Dictionary
		var id := str(branch.get("conversation", ""))
		assert_ne(id, "", "a grandpa_conversations_when branch names no conversation")
		assert_true(RUNNER.has(id),
			"grandpa_conversations_when names '%s', which is not in any dialogue file" % id)
		var probe: RefCounted = RUNNER.new()
		assert_true(probe.start(id), "conversation '%s' would not start" % id)
		assert_true(int(probe.line().get("count", 0)) > 0, "'%s' has no lines" % id)


## The ladder is written latest-milestone-first (F3's own `_why` fields say
## so) precisely so that first-match-wins gives the right answer once several
## of these flags are true at once, which is the ordinary end-of-chapter case:
## nothing unsets `tournament_won` once the Warden falls. Walked through the
## exact reader `sequence_director.gd::_grandpa_conversation_id()` uses, with
## `conversation_for(FREE_PLAY)` (empty) standing in for his "greeting".
func test_grandpas_ladder_lets_the_latest_milestone_outrank_the_rest() -> void:
	var progression: RefCounted = PROGRESSION_STATE.new()
	var spec := {
		"greeting": BEATS.conversation_for(BEATS.FREE_PLAY),
		"greeting_when": BEATS.grandpa_conversations_when(),
	}
	assert_eq(VILLAGE_NPCS.greeting_for(spec, progression), "",
		"no milestone reached yet -- free play's own conversation is empty and nothing should fill it")

	progression.set_flag("tournament_won")
	assert_eq(VILLAGE_NPCS.greeting_for(spec, progression), "grandpa_tournament_won")

	progression.set_flag("south_bridge_open")
	assert_eq(VILLAGE_NPCS.greeting_for(spec, progression), "grandpa_south_bridge",
		"a later milestone should outrank an earlier one that is still set")

	progression.set_flag("captive_rescued")
	assert_eq(VILLAGE_NPCS.greeting_for(spec, progression), "grandpa_relay_rescue")

	progression.set_flag("hall_approach_open")
	assert_eq(VILLAGE_NPCS.greeting_for(spec, progression), "grandpa_hall_approach")

	progression.set_flag("legendary_freed")
	assert_eq(VILLAGE_NPCS.greeting_for(spec, progression), "grandpa_freed",
		"the ending should outrank every earlier milestone, all of which are still true by then")


## The one that catches a writer, not a programmer: a line gains
## `"effect": "beat:something"` and nothing answers to it, so the conversation
## plays, ends, and the sequence quietly stalls.
func test_every_beat_effect_the_dialogue_emits_is_mapped_to_a_beat() -> void:
	var emitted := _beat_effects_in_the_dialogue()
	assert_false(emitted.is_empty(), "the opening dialogue should drive the beats")
	for effect: String in emitted:
		var target := BEATS.beat_for_effect(effect)
		assert_ne(target, "", "dialogue emits 'beat:%s' and opening.json maps nothing to it" % effect)
		assert_true(BEATS.has(target), "'beat:%s' points at '%s', which is not a beat" % [effect, target])


## And the same join from the other end: a mapping that points nowhere.
func test_no_effect_points_at_a_beat_that_does_not_exist() -> void:
	var broken: Array[String] = BEATS.broken_effects()
	assert_true(broken.is_empty(), "effect(s) mapped to a missing beat: %s" % ", ".join(broken))


func test_dialogue_effects_hand_the_player_to_the_next_single_goal() -> void:
	assert_eq(BEATS.beat_for_effect("starter_choice"), BEATS.CHOOSE)
	assert_eq(BEATS.beat_for_effect("first_encounter"), BEATS.WALK_OUT)
	assert_eq(BEATS.beat_for_effect("visit_mira"), BEATS.VISIT_MIRA)
	assert_eq(BEATS.beat_for_effect("tournament_signup"), BEATS.TOURNAMENT_SIGNUP)
	assert_eq(BEATS.beat_for_effect("no_such_moment"), "")


func test_existing_village_and_tournament_facts_advance_the_saved_opening() -> void:
	assert_eq(BEATS.advance_flag_for(BEATS.VISIT_MIRA), "opening:mira_visited")
	assert_eq(BEATS.advance_flag_for(BEATS.TOURNAMENT_SIGNUP), "opening:tournament_registered")
	assert_eq(BEATS.advance_flag_for(BEATS.RETURN_MIRA), "",
		"Grandpa's required return must not be skipped by a flat flag")


func test_the_fade_is_a_real_duration() -> void:
	var fade := BEATS.fade()
	assert_true(float(fade.get("seconds", 0.0)) > 0.0, "beat 1 fades in; zero seconds is a cut")
	assert_true(float(fade.get("hold_seconds", -1.0)) >= 0.0)


func test_three_starters_stand_in_a_row_at_the_configured_spacing() -> void:
	var cfg := BEATS.starters()
	var species: Array = cfg.get("species", [])
	assert_eq(species.size(), 3, "GAME_DESIGN 3: three starters, ground/water/air")

	var offsets := BEATS.starter_offsets(Vector3(0.0, 0.0, 1.0))
	assert_eq(offsets.size(), 3)
	var spread := float(cfg.get("spread", 3.5))
	for i in offsets.size() - 1:
		assert_almost_eq(offsets[i].distance_to(offsets[i + 1]), spread, 0.001,
			"neighbours should be exactly the configured spread apart")
	# Centred on him, so the middle one is straight ahead.
	assert_almost_eq(offsets[1].x, 0.0, 0.001)
	assert_almost_eq(offsets[1].z, float(cfg.get("forward", 4.5)), 0.001)


func test_the_starter_row_turns_with_the_facing_it_is_given() -> void:
	var forward := BEATS.starter_offsets(Vector3(0.0, 0.0, 1.0))
	var sideways := BEATS.starter_offsets(Vector3(1.0, 0.0, 0.0))
	for i in forward.size():
		assert_almost_eq(forward[i].length(), sideways[i].length(), 0.001,
			"rotating the row should not move anyone nearer or further")
	assert_true(forward[0].distance_to(sideways[0]) > 0.1, "the row should actually have turned")


func test_a_facing_of_nothing_still_produces_a_row() -> void:
	var offsets := BEATS.starter_offsets(Vector3.ZERO)
	assert_eq(offsets.size(), 3, "a degenerate facing must not leave the starters on top of each other")
	assert_true(offsets[0].distance_to(offsets[1]) > 0.1)


func test_the_tutorial_creature_is_the_one_with_the_best_catch_rate_and_a_failure_bound() -> void:
	# The high base rate makes the first attempt honestly likely. The explicit
	# bound is what actually enforces docs/specs/OPENING_SEQUENCE.md's stronger
	# promise that the tutorial catch cannot fail twice.
	var encounter := BEATS.encounter()
	var id := str(encounter.get("species", ""))
	assert_ne(id, "", "beat 6 needs a creature to walk out to")
	assert_eq(int(encounter.get("max_catch_failures", -1)), 1,
		"the tutorial may break out once, but a second landed legal throw must catch")
	var species := preload("res://scripts/creatures/creature_species.gd")
	assert_true(species.has(id), "the opening's wild creature '%s' is not in species.json" % id)
	var best := species.catch_rate(id)
	for other: String in species.table():
		assert_true(species.catch_rate(other) <= best,
			"'%s' is easier to catch than the tutorial creature '%s'" % [other, id])


func _beat_effects_in_the_dialogue() -> Array[String]:
	var out: Array[String] = []
	for id: String in RUNNER.table():
		var conversation: Dictionary = RUNNER.table()[id]
		for raw: Variant in conversation.get("lines", []) as Array:
			if not raw is Dictionary:
				continue
			var line: Dictionary = raw
			var effects: Array = (line.get("effects", []) as Array).duplicate()
			if str(line.get("effect", "")) != "":
				effects.append(str(line["effect"]))
			for effect: Variant in effects:
				var parts: Array = RUNNER.parse_effect(str(effect))
				if str(parts[0]) == "beat" and not out.has(str(parts[1])):
					out.append(str(parts[1]))
	return out
