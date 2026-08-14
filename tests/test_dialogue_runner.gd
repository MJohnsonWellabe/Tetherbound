extends "res://tests/test_case.gd"

## The conversation state machine, and the actual text it will speak.
##
## Two things are being checked and they are different in kind. One is the
## machine: start, one line at a time, effects handed back, close. The other is
## the DATA — every conversation the opening names has to exist, have lines, and
## point at a portrait that is really on disk, because a typo in a conversation
## id is a beat that silently never plays.

const RUNNER := preload("res://scripts/story/dialogue_runner.gd")
const ITEM_DB := preload("res://autoload/item_db.gd")

var _runner: RefCounted = null


func before_each() -> void:
	_runner = RUNNER.new()


func test_nothing_is_running_before_it_starts() -> void:
	assert_false(_runner.is_active())
	assert_true(_runner.line().is_empty(), "no conversation, no line to draw")


func test_a_conversation_plays_one_line_at_a_time() -> void:
	assert_true(_runner.start("grandpa_house"))
	var count := int(_runner.line().get("count", 0))
	assert_true(count >= 2, "the intro should be more than one line")

	var seen: Array[String] = []
	for i in count:
		assert_true(_runner.is_active(), "conversation ended early at line %d" % i)
		var line: Dictionary = _runner.line()
		assert_eq(int(line.get("index")), i, "lines should come in order")
		assert_ne(str(line.get("text")), "", "line %d is blank" % i)
		seen.append(str(line.get("text")))
		_runner.advance()

	assert_false(_runner.is_active(), "advancing past the last line should close it")
	assert_eq(seen.size(), count)


func test_the_last_line_says_it_is_the_last() -> void:
	_runner.start("grandpa_waiting")
	var count := int(_runner.line().get("count", 0))
	for i in count - 1:
		assert_false(bool(_runner.line().get("is_last")), "line %d is not the last" % i)
		_runner.advance()
	assert_true(bool(_runner.line().get("is_last")), "the last line should know it")


func test_an_unknown_conversation_refuses_rather_than_opening_an_empty_box() -> void:
	assert_false(_runner.start("no_such_conversation"))
	assert_false(_runner.is_active())


func test_effects_are_handed_back_rather_than_executed() -> void:
	_runner.start("grandpa_house")
	var effects: Array[String] = []
	while _runner.is_active():
		effects.append_array(_runner.drain_effects())
		_runner.advance()
	effects.append_array(_runner.drain_effects())
	assert_true(
		effects.has("beat:starter_choice"),
		"the intro has to unlock the starter choice; got %s" % str(effects)
	)


func test_draining_effects_empties_them() -> void:
	_runner.start("grandpa_house")
	while _runner.is_active():
		_runner.drain_effects()
		_runner.advance()
	assert_eq(_runner.drain_effects().size(), 0, "a drained effect must not fire twice")


func test_an_effect_splits_into_a_kind_and_a_value() -> void:
	assert_eq(RUNNER.parse_effect("beat:starter_choice"), ["beat", "starter_choice"])
	assert_eq(RUNNER.parse_effect("bare"), ["bare", ""])


## The first time the game says a word the player wrote.
func test_the_creatures_name_is_substituted_into_the_line() -> void:
	_runner.set_value("name", "Biscuit")
	_runner.start("grandpa_named")
	assert_true(
		str(_runner.line().get("text")).begins_with("Biscuit"),
		"got '%s'" % str(_runner.line().get("text"))
	)


func test_closing_early_ends_it_cleanly() -> void:
	_runner.start("grandpa_house")
	_runner.close()
	assert_false(_runner.is_active())
	assert_true(_runner.line().is_empty())
	# Closing an already-closed runner must be a no-op rather than a second
	# `finished`, or a beat advances twice.
	_runner.close()


## --- the data, not the machine ----------------------------------------------

## Every conversation the sequence director names, checked here rather than
## discovered by a player walking up to Grandpa and getting nothing.
func test_every_conversation_the_opening_needs_exists_and_speaks() -> void:
	var needed := [
		"grandpa_house",
		"grandpa_waiting",
		"grandpa_named",
		"grandpa_encounter_hint",
		"grandpa_road",
	]
	for id: String in needed:
		assert_true(RUNNER.has(id), "conversation '%s' is missing from opening.json" % id)
		var probe: RefCounted = RUNNER.new()
		assert_true(probe.start(id), "conversation '%s' would not start" % id)
		assert_true(int(probe.line().get("count", 0)) > 0, "'%s' has no lines" % id)


func test_every_conversation_has_a_speaker_and_a_portrait_that_is_really_there() -> void:
	for id: String in RUNNER.table():
		var probe: RefCounted = RUNNER.new()
		probe.start(id)
		var line: Dictionary = probe.line()
		assert_ne(str(line.get("speaker")), "", "'%s' has no speaker name" % id)
		var portrait := str(line.get("portrait"))
		assert_ne(portrait, "", "'%s' has no portrait" % id)
		assert_true(
			ResourceLoader.exists(portrait),
			"'%s' points at a portrait that is not on disk: %s" % [id, portrait]
		)


## The naming beat is mandatory, so a line that greets the creature by name must
## actually contain the placeholder. Without this the substitution silently
## does nothing and Grandpa says "$name" out loud.
func test_the_naming_line_actually_contains_the_placeholder() -> void:
	var raw: Dictionary = RUNNER.table().get("grandpa_named", {})
	var joined := ""
	for entry: Variant in (raw.get("lines", []) as Array):
		joined += str(entry) if not entry is Dictionary else str((entry as Dictionary).get("text", ""))
	assert_true(joined.contains("$name"), "grandpa_named never uses the name the player typed")


## Grandpa's briefing hands over the pack through `give:item_id:count` effects.
## An effect naming an item that data/items/items.json does not define is silent
## at run time: the line speaks the gift and the satchel gains a grey unknown
## slot, or nothing at all.
func test_every_give_effect_names_a_real_item_and_a_real_count() -> void:
	var db: RefCounted = ITEM_DB.new()
	var found := 0
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
				found += 1
				var pieces: PackedStringArray = str(parts[1]).split(":")
				var item := pieces[0]
				assert_true(db.has(item),
					"'%s' gives '%s', which is not in items.json" % [id, item])
				assert_true(pieces.size() == 2 and int(pieces[1]) > 0,
					"'%s' gives '%s' without a positive count" % [id, str(parts[1])])
	assert_true(found >= 3, "the briefing should hand over the pack in give: lines; found %d" % found)
