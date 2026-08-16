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


## SC12/SC13. `battle:<trainer_id>` is the fourth dialogue effect
## `sequence_director.gd::_drain_effects` knows, beside `beat:`/`give:`/`flag:`/
## `shop:`. Parsing is the same generic split as any other effect -- this just
## proves the id half survives whole, since a trainer id can itself contain an
## underscore (`trainer_mira`) and must not be chopped at the first one.
func test_a_battle_effect_splits_into_the_kind_and_the_trainer_id() -> void:
	assert_eq(RUNNER.parse_effect("battle:trainer_mira"), ["battle", "trainer_mira"])


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


## --- OF31/D39: Mira the merchant, Oskar the creature trader -------------------
##
## The same split OF30 drew: the WIRING (a `shop:` effect actually opening a
## panel with a real Game autoload under it) is proven in
## `tests/smoke_village_trade.gd`, because it is a Node reading `/root/Game` in
## `_process` and neither exists here. What is checked here is the data half —
## the conversations carry the right effects, spelled the way
## `sequence_director.gd::_queue_shop` parses them, and every vendor they name
## is really in data/config/trade.json.

const TRADE_DB := preload("res://scripts/trade/trade_db.gd")
const MIRA_FLAG := "mira_shop_open"
const OSKAR_FLAG := "oskar_trade_open"
const MIRA_INTRO := "village_mira_shop_intro"
const MIRA_SHOP := "village_mira_shop"
const OSKAR_INTRO := "village_oskar_trade_intro"
const OSKAR_SWAP := "village_oskar_trade"

## SC12/SC13. The three Band-1 trainer conversations, and the flags that gate
## challengeability.
const MIRA_CHALLENGE := "village_mira_challenge"
const MIRA_BEATEN := "village_mira_beaten"
const OSKAR_CHALLENGE := "village_oskar_challenge"
const OSKAR_BEATEN := "village_oskar_beaten"
const TAM_CHALLENGE := "village_tam_challenge"
const TAM_BEATEN := "village_tam_beaten"
const DEFEATED_MIRA := "defeated_mira"
const DEFEATED_OSKAR := "defeated_oskar"
const DEFEATED_TAM := "defeated_tam"


## `shop:<goods|creatures>:<vendor_id>`, the fourth dialogue effect. A typo in
## either half is a villager whose shop silently never opens.
func test_every_shop_effect_names_a_known_kind_and_a_real_vendor() -> void:
	var trade: RefCounted = TRADE_DB.new()
	var found := 0
	for id: String in RUNNER.table():
		for effect: String in _effects_of(id):
			var parts: Array = RUNNER.parse_effect(effect)
			if str(parts[0]) != "shop":
				continue
			found += 1
			var pieces: PackedStringArray = str(parts[1]).split(":")
			assert_eq(pieces.size(), 2,
				"'%s' has effect '%s'; it reads shop:<kind>:<vendor_id>" % [id, effect])
			if pieces.size() != 2:
				continue
			var kind := str(pieces[0])
			var vendor := str(pieces[1])
			assert_true(kind == "goods" or kind == "creatures",
				"'%s' asks for a '%s' shop; only goods and creatures exist" % [id, kind])
			if kind == "goods":
				assert_true((trade.vendor_ids() as Array).has(vendor),
					"'%s' opens vendor '%s', which trade.json does not define" % [id, vendor])
			else:
				assert_false(CREATURE_TRADE.trader(trade.config(), vendor).is_empty(),
					"'%s' opens creature trader '%s', which trade.json does not define" % [id, vendor])
	assert_true(found >= 6,
		"Mira and Oskar each open their screen from THREE branches now (SC13's beaten line carries it too); found %d" % found)


const CREATURE_TRADE := preload("res://scripts/trade/creature_trade.gd")
const TRAINERS := preload("res://scripts/world/trainer_npc.gd")


## Every one of Mira's and Oskar's branches that reaches the store/swap has to
## END there, or a greeting is a cul-de-sac that mentions a shop the player
## cannot reach. `village_mira_beaten`/`village_oskar_beaten` are SC13's
## additions and D39's rule made real: the store/swap survive their vendor
## becoming a trainer.
func test_both_of_miras_branches_open_the_store() -> void:
	for id in [MIRA_INTRO, MIRA_SHOP, MIRA_BEATEN]:
		assert_true(_effects_of(id).has("shop:goods:mira"),
			"'%s' never opens the store" % id)


func test_both_of_oskars_branches_open_the_swap() -> void:
	for id in [OSKAR_INTRO, OSKAR_SWAP, OSKAR_BEATEN]:
		assert_true(_effects_of(id).has("shop:creatures:oskar"),
			"'%s' never opens the swap screen" % id)


## `battle:<trainer_id>`, the fifth dialogue effect. A typo here is a
## challenge that reads fine and starts nothing.
func test_every_battle_effect_names_a_real_trainer() -> void:
	var found := 0
	for id: String in RUNNER.table():
		for effect: String in _effects_of(id):
			var parts: Array = RUNNER.parse_effect(effect)
			if str(parts[0]) != "battle":
				continue
			found += 1
			var trainer_id := str(parts[1])
			assert_false(TRAINERS.trainer(trainer_id).is_empty(),
				"'%s' opens a battle with '%s', which trainers.json does not define" % [id, trainer_id])
	assert_true(found >= 3, "Mira, Oskar and Tam each offer a battle; found %d" % found)


## The battle: effect has to sit on the LAST line of each challenge -- the
## same contract `trainer_npc.gd` relies on: the fight starts once the
## dialogue box has closed, not mid-conversation.
func test_the_battle_effect_is_the_challenges_last_word() -> void:
	for pair in [[MIRA_CHALLENGE, "trainer_mira"], [OSKAR_CHALLENGE, "trainer_oskar"], [TAM_CHALLENGE, "trainer_tam"]]:
		var id := str(pair[0])
		var trainer_id := str(pair[1])
		var lines: Array = (RUNNER.table().get(id, {}) as Dictionary).get("lines", [])
		assert_false(lines.is_empty(), "'%s' has no lines at all" % id)
		if lines.is_empty():
			continue
		var last: Variant = lines[lines.size() - 1]
		var effects: Array = []
		if last is Dictionary:
			if (last as Dictionary).has("effects"):
				effects = (last as Dictionary).get("effects", [])
			elif (last as Dictionary).has("effect"):
				effects = [(last as Dictionary).get("effect", "")]
		assert_true(effects.has("battle:%s" % trainer_id),
			"'%s' should end on battle:%s; its last line is %s" % [id, trainer_id, str(last)])


## Same rule D43 set for Tam's tools: the gift and the flag that records it are
## on ONE line, so a conversation cut short cannot bank one without the other.
func test_the_starting_coins_and_the_flag_that_records_them_are_the_same_line() -> void:
	var lines: Array = (RUNNER.table().get(MIRA_INTRO, {}) as Dictionary).get("lines", [])
	var found := false
	for raw: Variant in lines:
		if not raw is Dictionary:
			continue
		var effects: Array = ((raw as Dictionary).get("effects", []) as Array)
		var gives_coins := false
		for effect: Variant in effects:
			if str(effect).begins_with("give:coin:"):
				gives_coins = true
		if not gives_coins:
			continue
		found = true
		assert_true(effects.has("flag:%s" % MIRA_FLAG),
			"the line that hands over the coins must also set '%s'" % MIRA_FLAG)
	assert_true(found, "'%s' never hands over any coins" % MIRA_INTRO)


## A swap is not a purchase. Oskar must never hand out items, and above all must
## never hand out coins for a creature — the owner's answer was a straight swap.
## Covers his challenge and beaten lines too, not just the original two.
func test_oskar_never_gives_anything_away() -> void:
	for id in [OSKAR_INTRO, OSKAR_SWAP, OSKAR_CHALLENGE, OSKAR_BEATEN]:
		for effect: String in _effects_of(id):
			assert_false(effect.begins_with("give:"),
				"'%s' hands something over; Oskar trades creature for creature" % id)


## The dual-role rule from the other side: the merchant's own branches resolve
## in the right order and her plain greeting is still there underneath.
##
## SC12/SC13 inserted two branches between the intro and the original standing
## shop branch: once the shop is open, greeting Mira now offers her Band-1
## challenge (repeatedly, for as long as she is unbeaten) rather than
## reopening the shop directly -- and once she is beaten, `village_mira_beaten`
## takes over as the permanent steady state, itself carrying the same
## `shop:goods:mira` effect (proven separately by
## `test_both_of_miras_branches_open_the_store`), so the store never actually
## becomes unreachable.
func test_the_merchants_branches_resolve_in_order() -> void:
	var mira := _villager("Mira")
	assert_false(mira.is_empty(), "village_npcs.json has no villager named Mira")
	var progression: RefCounted = PROGRESSION_STATE.new()
	assert_eq(VILLAGE_NPCS.greeting_for(mira, progression), MIRA_INTRO,
		"a fresh save should get the shop-opening conversation")
	progression.set_flag(MIRA_FLAG)
	assert_eq(VILLAGE_NPCS.greeting_for(mira, progression), MIRA_CHALLENGE,
		"once the shop is open and she is unbeaten, greeting her should offer the Band-1 challenge")
	progression.set_flag(DEFEATED_MIRA)
	assert_eq(VILLAGE_NPCS.greeting_for(mira, progression), MIRA_BEATEN,
		"once she is beaten, greeting her should open her permanent steady state")
	assert_eq(str(mira.get("greeting", "")), "village_mira",
		"NP3's Meadow Keeper line must survive her becoming a merchant and a trainer")


## Same shape as Mira's, for Oskar's swap-offer/challenge/beaten branches.
func test_the_creature_traders_branches_resolve_in_order() -> void:
	var oskar := _villager("Oskar")
	assert_false(oskar.is_empty(), "village_npcs.json has no villager named Oskar")
	var progression: RefCounted = PROGRESSION_STATE.new()
	assert_eq(VILLAGE_NPCS.greeting_for(oskar, progression), OSKAR_INTRO)
	progression.set_flag(OSKAR_FLAG)
	assert_eq(VILLAGE_NPCS.greeting_for(oskar, progression), OSKAR_CHALLENGE,
		"once the swap is open and he is unbeaten, greeting him should offer the Band-1 challenge")
	progression.set_flag(DEFEATED_OSKAR)
	assert_eq(VILLAGE_NPCS.greeting_for(oskar, progression), OSKAR_BEATEN,
		"once he is beaten, greeting him should open his permanent steady state")
	assert_eq(str(oskar.get("greeting", "")), "village_oskar",
		"NP3's Bridgehand line must survive him becoming a trader and a trainer")


## Tam has no standing vendor branch to carry forward -- both of his gifts are
## one-time and spent before he is even challengeable -- so his own real
## branches are checked end to end here: tools, then the orb recipe, then
## (once BOTH are spent) the challenge repeatedly until beaten, then his
## flavour-only beaten line forever after.
func test_the_smiths_branches_resolve_in_order_including_the_challenge() -> void:
	var tam := _villager("Tam")
	assert_false(tam.is_empty(), "village_npcs.json has no villager named Tam")
	var progression: RefCounted = PROGRESSION_STATE.new()
	assert_eq(VILLAGE_NPCS.greeting_for(tam, progression), TOOLS_CONVERSATION)
	progression.set_flag(TOOLS_FLAG)
	assert_eq(VILLAGE_NPCS.greeting_for(tam, progression), ORBS_CONVERSATION)
	progression.set_flag(RECIPE_FLAG)
	assert_eq(VILLAGE_NPCS.greeting_for(tam, progression), TAM_CHALLENGE,
		"once both gifts are spent and he is unbeaten, greeting him should offer the Band-1 challenge")
	progression.set_flag(DEFEATED_TAM)
	assert_eq(VILLAGE_NPCS.greeting_for(tam, progression), TAM_BEATEN,
		"once he is beaten, greeting him should open his permanent (flavour-only) steady state")
	assert_eq(str(tam.get("greeting", "")), "village_tam",
		"NP3's Field Scout line must survive him becoming a smith and a trainer")


func _villager(who: String) -> Dictionary:
	var file := FileAccess.open("res://data/config/village_npcs.json", FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return {}
	for entry: Variant in ((parsed as Dictionary).get("villagers", []) as Array):
		if entry is Dictionary and str((entry as Dictionary).get("name", "")) == who:
			return entry as Dictionary
	return {}


## --- SE27: freeing the captive, and what she is allowed to know --------------
##
## The same split every section above keeps: the WIRING (a real world, a real
## fight, a real satchel) is `tests/smoke_relay.gd`. What is checked here is
## the data — the rescue conversation grants the Gear once and only once, the
## gate that makes "once" true is spelled correctly, and the testimony stops
## exactly where spec §32 says it stops.

const RELAY_SITE_PATH := "res://data/config/relay_site.json"
const RELAY_DIALOGUE_PATH := "res://data/dialogue/relay.json"
const CAPTAIN_FLAG := "relay_captain_defeated"
const RESCUE_FLAG := "captive_rescued"
const GEAR_ID := "mill_bridge_gear"
const RESCUE_CONVERSATION := "relay_captive_freed"
const HELD_CONVERSATION := "relay_captive_held"

## §32's rung, made testable. The captive knows the Rifts are ARTIFICIAL and
## that power flows toward the stronghold; she does NOT know what is at the far
## end of it, and nothing she says may name the thing that is. These are the
## words that would give it away — the concept, the species, and the phrase the
## stronghold's own reveal uses ("living power source").
const FORBIDDEN_WORDS := [
	"legendary",
	"veridian",
	"stag",
	"living power",
	"power source",
]


func _relay_site() -> Dictionary:
	var file := FileAccess.open(RELAY_SITE_PATH, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	return parsed as Dictionary if parsed is Dictionary else {}


func _captive_spec() -> Dictionary:
	for entry: Variant in (_relay_site().get("people", []) as Array):
		if entry is Dictionary and not (entry as Dictionary).get("greeting_when", []).is_empty():
			return entry as Dictionary
	return {}


## Every line of a conversation as plain text, effects stripped.
func _spoken_text(id: String) -> String:
	var conversation: Dictionary = RUNNER.table().get(id, {})
	var out := ""
	for line: Variant in (conversation.get("lines", []) as Array):
		if typeof(line) == TYPE_STRING:
			out += str(line) + "\n"
		elif typeof(line) == TYPE_DICTIONARY:
			out += str((line as Dictionary).get("text", "")) + "\n"
	return out


func test_the_relay_dialogue_file_is_merged_onto_the_table() -> void:
	assert_true(RUNNER.has(HELD_CONVERSATION),
		"'%s' is not in the dialogue table; data/dialogue/relay.json is not being loaded" % HELD_CONVERSATION)
	assert_true(RUNNER.has(RESCUE_CONVERSATION),
		"'%s' is not in the dialogue table" % RESCUE_CONVERSATION)


## The rescue hands over the Gear, and the flag that closes the branch is set
## on the SAME line -- the rule OF30 wrote for Tam's tools and for the same
## reason: a conversation cut short must not bank the gift without the flag or
## the flag without the gift.
func test_the_rescue_grants_the_gear_and_records_it_on_one_line() -> void:
	var gives := 0
	var conversation: Dictionary = RUNNER.table().get(RESCUE_CONVERSATION, {})
	for line: Variant in (conversation.get("lines", []) as Array):
		if typeof(line) != TYPE_DICTIONARY:
			continue
		var effects: Array = (line as Dictionary).get("effects", [])
		var gave_gear := false
		var set_flag := false
		for effect: Variant in effects:
			var parts: Array = RUNNER.parse_effect(str(effect))
			if str(parts[0]) == "give" and str(parts[1]).begins_with(GEAR_ID):
				gave_gear = true
				gives += 1
			if str(parts[0]) == "flag" and str(parts[1]) == RESCUE_FLAG:
				set_flag = true
		if gave_gear:
			assert_true(set_flag,
				"the line that hands over the %s does not also set '%s'; the gift could be banked without being recorded" % [
					GEAR_ID, RESCUE_FLAG])
	assert_eq(gives, 1,
		"the rescue conversation grants the %s %d times; it must be exactly once" % [GEAR_ID, gives])


## "Once" is not a property of the conversation, it is a property of the gate
## in front of it. `relay_captive_held` is what she says until the captain
## falls; the rescue branch requires his flag AND the absence of her own, so
## the moment the gift lands the branch that gave it stops matching.
func test_the_rescue_is_gated_shut_before_and_after() -> void:
	var spec := _captive_spec()
	assert_false(spec.is_empty(), "relay_site.json has no captive with a gated greeting")

	var progression: RefCounted = PROGRESSION_STATE.new()
	assert_eq(VILLAGE_NPCS.greeting_for(spec, progression), HELD_CONVERSATION,
		"on a fresh save the captive should be held, not rescuable")

	progression.set_flag(CAPTAIN_FLAG)
	assert_eq(VILLAGE_NPCS.greeting_for(spec, progression), RESCUE_CONVERSATION,
		"beating the relay captain does not open the rescue")

	progression.set_flag(RESCUE_FLAG)
	assert_ne(VILLAGE_NPCS.greeting_for(spec, progression), RESCUE_CONVERSATION,
		"the rescue conversation can be opened a second time; the Gear would be granted twice")


## SE27's other half of the same flag: she stops standing at the relay and
## starts standing in the village. Both placements read the one flag, and
## neither is true at the same time as the other.
func test_the_captive_and_the_villager_are_never_both_standing() -> void:
	var captive := _captive_spec()
	var villager := _named_villager("Sela")
	assert_false(villager.is_empty(), "village_npcs.json has no entry named 'Sela'")

	var progression: RefCounted = PROGRESSION_STATE.new()
	assert_true(VILLAGE_NPCS.placement_holds(captive, progression),
		"the captive is not at the relay on a fresh save")
	assert_false(VILLAGE_NPCS.placement_holds(villager, progression),
		"the rescued villager stands in the square before there has been a rescue")

	progression.set_flag(RESCUE_FLAG)
	assert_false(VILLAGE_NPCS.placement_holds(captive, progression),
		"the captive is still at the relay after being freed")
	assert_true(VILLAGE_NPCS.placement_holds(villager, progression),
		"the rescued villager never turns up in the village")


## A villager with no `place_when` at all is always placed -- the shape has to
## be additive or every NPC written before SE27 vanishes.
func test_an_entry_with_no_placement_gate_is_always_placed() -> void:
	var progression: RefCounted = PROGRESSION_STATE.new()
	assert_true(VILLAGE_NPCS.placement_holds({"name": "Tam"}, progression))
	assert_true(VILLAGE_NPCS.placement_holds({"name": "Tam", "place_when": []}, progression))


## SG46 / §14: she is in the village AND she is saying something new. The
## `greeting` itself is untouched (D39), so this is about the branch above it.
func test_the_rescued_villager_says_something_new() -> void:
	var villager := _named_villager("Sela")
	var progression: RefCounted = PROGRESSION_STATE.new()
	progression.set_flag(RESCUE_FLAG)
	var after := VILLAGE_NPCS.greeting_for(villager, progression)
	assert_ne(after, str(villager.get("greeting", "")),
		"the rescued villager opens the same conversation she did before the rescue")
	assert_true(RUNNER.has(after), "she would open '%s', which no dialogue file defines" % after)


## §32, and the reason this file exists at all. Asserted over the WORDS rather
## than trusted to a comment: the captive knows the separation is made and
## which way the power flows, and does not know what is making it.
func test_the_captive_never_names_the_legendary() -> void:
	var suspect := ""
	for id: String in [HELD_CONVERSATION, RESCUE_CONVERSATION, "village_rescued_ranger_home"]:
		suspect += _spoken_text(id)
	assert_ne(suspect.strip_edges(), "", "no captive dialogue was found to check")
	var lowered := suspect.to_lower()
	for word: String in FORBIDDEN_WORDS:
		assert_false(lowered.contains(word),
			"the captive says '%s'; spec §32 puts that reveal at the stronghold, not here" % word)


## And the positive half of the same rung -- she DOES have to say the three
## things the spec lists, or the rescue is a fetch quest with a cutscene.
func test_the_captive_gives_the_testimony_the_spec_asks_for() -> void:
	var said := _spoken_text(RESCUE_CONVERSATION).to_lower()
	assert_true(said.contains("cut") or said.contains("made"),
		"the captive never says the seams are made rather than natural")
	assert_true(said.contains("held") or said.contains("maintain"),
		"the captive never says the separation is being actively maintained")
	assert_true(said.contains("stronghold"),
		"the captive never says which way the power flows")


## SE30 widens the captive's own rule to the WHOLE cast. §32 puts the
## legendary's reveal inside the stronghold and nowhere earlier, and by this
## point the Meadows has four dialogue files and roughly thirty
## conversations -- villagers, the blacksmith, the merchant, three village
## trainers, four Team Tether personnel and the captive. Trusting thirty
## conversations to a comment is exactly how a spoiler gets written by the
## eleventh person to touch the files. Every conversation any of them can
## open before the stronghold is checked here, so a future line naming the
## legendary fails the build rather than the chapter.
##
## The stronghold's own dialogue (SG40's reveal, R8.3's Warden) is where
## those words belong. If a file is added for them it must be named in
## STRONGHOLD_FILES below, which is the ONE place the exemption lives.
const DIALOGUE_FILES := [
	"res://data/dialogue/village.json",
	"res://data/dialogue/relay.json",
	"res://data/dialogue/trainers.json",
	"res://data/dialogue/opening.json",
]

## Dialogue that is allowed to name it, because it happens at or after the
## reveal. Empty until SG40/R8.3 land.
const STRONGHOLD_FILES: Array[String] = []


func test_no_dialogue_before_the_stronghold_names_the_legendary() -> void:
	var checked := 0
	for path: String in DIALOGUE_FILES:
		if STRONGHOLD_FILES.has(path):
			continue
		var spoken := _all_spoken_in(path)
		assert_ne(spoken.strip_edges(), "", "no spoken lines found in %s" % path)
		checked += 1
		var lowered := spoken.to_lower()
		for word: String in FORBIDDEN_WORDS:
			assert_false(lowered.contains(word),
				"a character in %s says '%s'; §32 puts that reveal in the stronghold, and this is read before it"
					% [path, word])
	assert_true(checked >= 4, "expected to scan every pre-stronghold dialogue file, scanned %d" % checked)


## Every SPOKEN line in a dialogue file, and only the spoken lines. The
## `_comment` fields in these files discuss the rule itself ("the captive
## never names the legendary"), so a whole-file text scan flags the very
## comment that documents the rule — caught by running exactly that scan
## before this helper existed.
func _all_spoken_in(path: String) -> String:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return ""
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not (parsed is Dictionary):
		return ""
	var root: Dictionary = parsed
	var conversations: Dictionary = root.get("conversations", root)
	var spoken := ""
	for id: String in conversations.keys():
		if id.begins_with("_"):
			continue
		var entry: Variant = conversations[id]
		if not (entry is Dictionary):
			continue
		for line: Variant in (entry as Dictionary).get("lines", []):
			# A line is either the spoken string itself or a dictionary
			# carrying it alongside effects; both shapes ship today.
			if line is String:
				spoken += " " + (line as String)
			elif line is Dictionary:
				spoken += " " + str((line as Dictionary).get("text", ""))
	return spoken


## The other half of SE30: the ladder's LOWER rungs have to actually be
## spoken, or the reveal has nothing to climb from. D41 made the drain canon
## and SD16/SE23 painted it into the world; before SE30 not one villager
## mentioned it, so a player could cross a hundred metres of dying ground and
## never hear a soul admit it existed.
func test_the_villagers_report_the_dying_ground_without_explaining_it() -> void:
	var spoken := ""
	for id: String in ["village_mira", "village_tam", "village_oskar", "village_quarry_foreman"]:
		spoken += _spoken_text(id)
	var lowered := spoken.to_lower()
	var symptoms := 0
	for phrase: String in ["grey and thin", "dead flat", "gone bad", "waist high", "bare", "won't take"]:
		if lowered.contains(phrase):
			symptoms += 1
	assert_true(symptoms >= 3,
		"the villagers barely mention the drained ground (%d symptom phrases); D41's rung is not laid in" % symptoms)
	# ...and none of them explains it. Knowing WHY is the captive's rung.
	for phrase: String in ["draining", "drains the", "siphon", "pulling power"]:
		assert_false(lowered.contains(phrase),
			"a villager says '%s' -- they report the symptom, they do not know the cause (§32)" % phrase)


func _named_villager(who: String) -> Dictionary:
	var file := FileAccess.open("res://data/config/village_npcs.json", FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		return {}
	for entry: Variant in ((parsed as Dictionary).get("villagers", []) as Array):
		if entry is Dictionary and str((entry as Dictionary).get("name", "")) == who:
			return entry as Dictionary
	return {}
