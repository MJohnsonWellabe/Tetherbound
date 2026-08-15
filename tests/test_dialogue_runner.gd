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


## --- OF30: Tam the blacksmith -----------------------------------------------
##
## Owner-reported: "Make one of the villagers a blacksmith who will give you a
## torch, an axe for trees and a pickaxe for stones. Then he'll give you the
## recipe for basic orbs."
##
## The brief's first instruction was to PROVE that a village conversation's
## `give:` effects already reach the satchel before building any plumbing for
## it, and they do: `sequence_director.gd::_drain_effects()` drains the one
## shared dialogue panel every frame without asking whose conversation is in
## it, and `village_npcs.gd` opens village lines on that same panel. That end
## of it is proven in `tests/smoke_village_smith.gd`, which is where it has to
## live — the drain is a Node reading `/root/Game` in `_process`, and neither
## the tree nor the autoloads exist for the whole life of `tests/run_tests.gd`
## (see `tests/test_party_seam.gd`'s own note on `Engine.get_main_loop()`).
##
## What is checked here is the half that CAN be checked in milliseconds and is
## the half that rots: the conversations carry the right effects, spelled the
## way the director's parser reads them, and the branch selector hands out the
## one-time conversation exactly once.

const VILLAGE_NPCS := preload("res://scripts/world/village_npcs.gd")
const PROGRESSION_STATE := preload("res://autoload/progression_state.gd")

const TOOLS_CONVERSATION := "village_tam_tools"
const ORBS_CONVERSATION := "village_tam_orbs"
const TOOLS_FLAG := "tam_tools_given"
const RECIPE_FLAG := "recipe_orb_basic"


## Every effect in a conversation, in order, flattened across `effect` and
## `effects` the same way `dialogue_runner._collect_effects()` flattens them.
func _effects_of(id: String) -> Array[String]:
	var probe: RefCounted = RUNNER.new()
	var out: Array[String] = []
	if not probe.start(id):
		return out
	while probe.is_active():
		out.append_array(probe.drain_effects())
		probe.advance()
	out.append_array(probe.drain_effects())
	return out


func test_the_smith_hands_over_an_axe_and_a_pickaxe_and_says_so_once() -> void:
	var effects := _effects_of(TOOLS_CONVERSATION)
	assert_true(effects.has("give:axe:1"), "Tam should give an axe; got %s" % str(effects))
	assert_true(effects.has("give:pickaxe:1"), "Tam should give a pickaxe; got %s" % str(effects))
	assert_eq(effects.count("give:axe:1"), 1, "one axe, once")
	assert_eq(effects.count("give:pickaxe:1"), 1, "one pickaxe, once")


## Every tool the meadow's tool-gated resources need — wood wants an axe, stone
## a pickaxe, fiber a knife (items.json's `gathered_with`). A handover that gave
## some other set would read fine and gate nothing; a handover that gave only
## SOME of them would be worse than nothing, because owning the wrong tool pays
## zero where bare hands paid half. See village.json's `_comment_of30_knife`,
## and `test_harvest.gd` for the yields themselves.
func test_the_tools_he_gives_are_the_ones_the_meadow_actually_gates_on() -> void:
	var db: RefCounted = ITEM_DB.new()
	var given: Array[String] = []
	for effect: String in _effects_of(TOOLS_CONVERSATION):
		var parts: Array = RUNNER.parse_effect(effect)
		if str(parts[0]) == "give":
			given.append(str(parts[1]).split(":")[0])
	for resource in ["wood", "stone", "fiber"]:
		var tool_id: String = str(db.gathered_with(resource))
		assert_true(given.has(tool_id),
			"'%s' is gathered with '%s' and Tam never hands one over" % [resource, tool_id])
		assert_eq(db.kind(tool_id), "tool", "'%s' should be a tool" % tool_id)


## The gift and the flag that records it must be on the SAME line, or a
## conversation that ends early banks one without the other.
func test_the_gift_and_the_flag_that_records_it_are_the_same_line() -> void:
	var lines: Array = (RUNNER.table().get(TOOLS_CONVERSATION, {}) as Dictionary).get("lines", [])
	var found := false
	for raw: Variant in lines:
		if not raw is Dictionary:
			continue
		var effects: Array = ((raw as Dictionary).get("effects", []) as Array)
		if effects.has("give:axe:1"):
			found = true
			assert_true(effects.has("flag:%s" % TOOLS_FLAG),
				"the line that gives the axe must also set '%s'" % TOOLS_FLAG)
	assert_true(found, "no line in '%s' gives the axe at all" % TOOLS_CONVERSATION)


func test_the_follow_up_conversation_writes_the_orb_recipe_flag() -> void:
	assert_true(_effects_of(ORBS_CONVERSATION).has("flag:%s" % RECIPE_FLAG),
		"'%s' should set '%s'" % [ORBS_CONVERSATION, RECIPE_FLAG])


## OF24 owns the visible carried torch; OF30 owns the words that hand it over.
## There is deliberately no torch ITEM, so a `give:torch` here would name
## something items.json does not define and vanish.
func test_the_torch_is_handed_over_in_words_and_not_as_an_item() -> void:
	var joined := ""
	for raw: Variant in ((RUNNER.table().get(TOOLS_CONVERSATION, {}) as Dictionary).get("lines", []) as Array):
		joined += str(raw) if not raw is Dictionary else str((raw as Dictionary).get("text", ""))
	assert_true(joined.to_lower().contains("torch"),
		"Tam's handover never mentions the torch the owner asked for")
	for effect: String in _effects_of(TOOLS_CONVERSATION):
		assert_false(effect.begins_with("give:torch"),
			"there is no torch item; OF24 owns the carried torch itself")


## Every `flag:` effect anywhere in the dialogue table has to be a usable flag
## id. An empty one is a silent no-op at the director.
func test_every_flag_effect_names_a_flag() -> void:
	var found := 0
	for id: String in RUNNER.table():
		for effect: String in _effects_of(id):
			var parts: Array = RUNNER.parse_effect(effect)
			if str(parts[0]) != "flag":
				continue
			found += 1
			assert_ne(str(parts[1]), "", "'%s' has a flag: effect with no flag id" % id)
			assert_false(str(parts[1]).contains(":"),
				"'%s' writes flag '%s'; a flag id is one word, not a payload" % [id, str(parts[1])])
	assert_true(found >= 2, "OF30 adds two flag: effects; found %d" % found)


## --- village_npcs.greeting_for(): which conversation, and how many times ------

const TAM := {
	"name": "Tam",
	"greeting": "village_tam",
	"greeting_when": [
		{"unless_flag": TOOLS_FLAG, "conversation": TOOLS_CONVERSATION},
		{"unless_flag": RECIPE_FLAG, "conversation": ORBS_CONVERSATION},
	],
}


func test_a_villager_with_no_branches_always_says_the_same_thing() -> void:
	var progression: RefCounted = PROGRESSION_STATE.new()
	var mira := {"greeting": "village_mira"}
	assert_eq(VILLAGE_NPCS.greeting_for(mira, progression), "village_mira")


func test_the_one_time_gift_is_offered_once_and_then_never_again() -> void:
	var progression: RefCounted = PROGRESSION_STATE.new()
	assert_eq(VILLAGE_NPCS.greeting_for(TAM, progression), TOOLS_CONVERSATION,
		"a fresh save should be offered the tools")

	# What the conversation itself does on the line that gives them.
	progression.set_flag(TOOLS_FLAG)
	assert_ne(VILLAGE_NPCS.greeting_for(TAM, progression), TOOLS_CONVERSATION,
		"the tool handover must never be offered twice")


func test_the_branches_are_walked_in_order_and_then_fall_through() -> void:
	var progression: RefCounted = PROGRESSION_STATE.new()
	assert_eq(VILLAGE_NPCS.greeting_for(TAM, progression), TOOLS_CONVERSATION)
	progression.set_flag(TOOLS_FLAG)
	assert_eq(VILLAGE_NPCS.greeting_for(TAM, progression), ORBS_CONVERSATION)
	progression.set_flag(RECIPE_FLAG)
	assert_eq(VILLAGE_NPCS.greeting_for(TAM, progression), "village_tam",
		"with both branches spent Tam is a villager again, not a mute")


## The dual-role rule (D39): SC12 adds his battle offer as a NEW entry and the
## vendor branches survive. Written as a test rather than a comment because
## "additive" is a promise about a data shape, and this is the shape.
func test_a_later_role_can_be_appended_without_disturbing_the_earlier_ones() -> void:
	var extended: Dictionary = TAM.duplicate(true)
	(extended["greeting_when"] as Array).append(
		{"if_flag": RECIPE_FLAG, "conversation": "village_tam_battle"}
	)
	var progression: RefCounted = PROGRESSION_STATE.new()
	assert_eq(VILLAGE_NPCS.greeting_for(extended, progression), TOOLS_CONVERSATION)
	progression.set_flag(TOOLS_FLAG)
	assert_eq(VILLAGE_NPCS.greeting_for(extended, progression), ORBS_CONVERSATION)
	progression.set_flag(RECIPE_FLAG)
	assert_eq(VILLAGE_NPCS.greeting_for(extended, progression), "village_tam_battle")


func test_a_branch_may_require_several_flags_at_once() -> void:
	var spec := {
		"greeting": "village_tam",
		"greeting_when": [{"if_flag": [TOOLS_FLAG, RECIPE_FLAG], "conversation": "village_tam_both"}],
	}
	var progression: RefCounted = PROGRESSION_STATE.new()
	progression.set_flag(TOOLS_FLAG)
	assert_eq(VILLAGE_NPCS.greeting_for(spec, progression), "village_tam",
		"one of two required flags is not enough")
	progression.set_flag(RECIPE_FLAG)
	assert_eq(VILLAGE_NPCS.greeting_for(spec, progression), "village_tam_both")


## No flag store, no way to know what has already happened. Falling back to the
## plain greeting loses a conversation; guessing the other way hands out a
## one-time gift on every greeting forever.
func test_with_no_flag_store_the_plain_greeting_wins() -> void:
	assert_eq(VILLAGE_NPCS.greeting_for(TAM, null), "village_tam")


func test_every_conversation_a_villager_can_open_really_exists() -> void:
	var file := FileAccess.open("res://data/config/village_npcs.json", FileAccess.READ)
	assert_true(file != null, "village_npcs.json is missing")
	if file == null:
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	for entry: Variant in ((parsed as Dictionary).get("villagers", []) as Array):
		var spec := entry as Dictionary
		var who := str(spec.get("name", "?"))
		var ids: Array[String] = [str(spec.get("greeting", ""))]
		for raw: Variant in (spec.get("greeting_when", []) as Array):
			ids.append(str((raw as Dictionary).get("conversation", "")))
		for id: String in ids:
			assert_ne(id, "", "%s has a branch naming no conversation" % who)
			assert_true(RUNNER.has(id), "%s would open '%s', which no dialogue file defines" % [who, id])
