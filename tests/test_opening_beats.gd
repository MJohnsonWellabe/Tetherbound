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


func test_the_choice_comes_before_the_name_and_the_fight_before_the_road() -> void:
	assert_true(BEATS.index_of(BEATS.CHOOSE) < BEATS.index_of(BEATS.NAMED))
	assert_true(BEATS.index_of(BEATS.NAMED) < BEATS.index_of(BEATS.WALK_OUT))
	assert_true(BEATS.index_of(BEATS.WALK_OUT) < BEATS.index_of(BEATS.ENCOUNTER))
	assert_true(BEATS.index_of(BEATS.ENCOUNTER) < BEATS.index_of(BEATS.ROAD))
	assert_true(BEATS.index_of(BEATS.ROAD) < BEATS.index_of(BEATS.FREE_PLAY))


func test_every_conversation_a_beat_names_really_exists() -> void:
	for beat: String in BEATS.order():
		var id := BEATS.conversation_for(beat)
		if id == "":
			continue
		assert_true(RUNNER.has(id), "beat '%s' names conversation '%s', which is not in opening.json" % [beat, id])
	var named := BEATS.named_conversation()
	assert_ne(named, "", "the reply to the naming is a beat of its own and has to exist")
	assert_true(RUNNER.has(named), "named_conversation '%s' is not a conversation" % named)


func test_he_has_nothing_scripted_left_once_the_sequence_is_over() -> void:
	assert_eq(BEATS.conversation_for(BEATS.FREE_PLAY), "",
		"free play is where the scripting stops; a conversation here would repeat his send-off forever")


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


func test_the_intro_hands_over_to_the_choice_and_the_naming_to_the_encounter() -> void:
	assert_eq(BEATS.beat_for_effect("starter_choice"), BEATS.CHOOSE)
	assert_eq(BEATS.beat_for_effect("first_encounter"), BEATS.WALK_OUT)
	assert_eq(BEATS.beat_for_effect("free_play"), BEATS.FREE_PLAY)
	assert_eq(BEATS.beat_for_effect("no_such_moment"), "")


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


func test_the_tutorial_creature_is_the_one_with_the_best_catch_rate() -> void:
	# docs/OPENING_SEQUENCE.md: chosen so the tutorial catch cannot fail twice.
	var id := str(BEATS.encounter().get("species", ""))
	assert_ne(id, "", "beat 6 needs a creature to walk out to")
	var species := preload("res://scripts/pals/pal_species.gd")
	assert_true(species.has(id), "the opening's wild creature '%s' is not in species.json" % id)
	var best := species.catch_rate(id)
	for other: String in species.table():
		assert_true(species.catch_rate(other) <= best,
			"'%s' is easier to catch than the tutorial creature '%s'" % [other, id])


func test_every_gift_in_the_dialogue_is_a_real_item() -> void:
	# `give:orb_basic:15` grants through the real inventory, and an id typo'd
	# here is a gift Grandpa announces and never hands over — silent at run
	# time beyond a push_error nobody watches. items.json is the authority.
	var items_file := FileAccess.open("res://data/items/items.json", FileAccess.READ)
	assert_true(items_file != null, "items.json should open")
	var items: Dictionary = (JSON.parse_string(items_file.get_as_text()) as Dictionary).get("items", {})

	var gifts := 0
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
				if str(parts[0]) != "give":
					continue
				gifts += 1
				var rest: PackedStringArray = str(parts[1]).split(":")
				assert_eq(rest.size(), 2, "'%s' should read give:<item_id>:<count>" % effect)
				assert_true(items.has(str(rest[0])),
					"'%s' gives '%s', which items.json does not define" % [effect, rest[0]])
				assert_true(str(rest[1]).is_valid_int() and int(str(rest[1])) > 0,
					"'%s' should give a positive whole number" % effect)
	# Zero gifts is legal for THIS test (the dialogue rewrite lands separately);
	# the smoke test asserts the opening actually grants the orbs.


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
