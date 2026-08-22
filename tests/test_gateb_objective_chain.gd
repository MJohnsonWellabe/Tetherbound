extends "res://tests/test_case.gd"

## GATEB-OBJECTIVES (68-CHAPTER/17-RG18) -- walks the whole opening-through-
## South-Bridge main chain one flag at a time and checks the tracked line
## advances exactly as far as the flags set so far, never further and never
## less. Verified to fail against the pre-GATEB two-entry chain: with only
## `open_road_gate`/`defeat_the_captains` in data, setting `opening:beat:road`
## does nothing (that flag did not exist in the old chain at all) and the
## ladder flags below have no entry to advance past, so `_CHAIN`'s ninth and
## tenth checks (`tournament_won`, `south_bridge_open`) would find the tracked
## line already reading the captains' line instead of moving further -- this
## test would not pass unmodified against that shape, which is the point.

const PROGRESSION_STATE := preload("res://autoload/progression_state.gd")
const QUEST_LOG := preload("res://scripts/world/quest_log.gd")

## (flag to set, a substring expected in the label BEFORE that flag is set --
## i.e. what the tracked line reads while this step is still outstanding).
## In objectives.json's own file order.
const CHAIN := [
	["opening:beat:road", "first wild creature"],
	["road_gate_open", "village gate"],
	["tournament_team_ready", "tournament"],
	["tournament_training_ready", "Train with"],
	["home_materials_gathered", "Gather wood"],
	["home_built", "small home"],
	["creature_bed_built", "Creature Bed"],
	["player_slept_at_home", "Sleep until"],
	["tournament_entered", "Enter the village tournament"],
	["tournament_won", "Win the village tournament"],
	["south_bridge_open", "South Bridge"],
]

var progression: RefCounted = null
var log_reader: RefCounted = null


func before_each() -> void:
	progression = PROGRESSION_STATE.new()
	log_reader = QUEST_LOG.new()


func test_each_flag_in_order_advances_the_tracked_objective_to_the_next_beat() -> void:
	for step: Array in CHAIN:
		var flag: String = step[0]
		var expect_substr: String = step[1]
		var before: String = log_reader.tracked_text(progression)
		assert_true(before.find(expect_substr) != -1,
			"expected '%s' to still be outstanding (line was '%s') before setting %s" %
			[expect_substr, before, flag])

		progression.set_flag(flag)
		var after: String = log_reader.tracked_text(progression)
		assert_ne(after, before,
			"setting '%s' did not move the tracked objective off '%s'" % [flag, before])


func test_exactly_one_main_objective_is_tracked_at_a_time() -> void:
	# The HUD's one line is always a single string, never a list -- this is
	# really a type check on tracked_text(), but it is the property the
	# design rule ("at most one concise tracked major objective") depends on.
	for step: Array in CHAIN:
		var text: String = log_reader.tracked_text(progression)
		assert_true(typeof(text) == TYPE_STRING and text.find("\n") == -1,
			"tracked_text must be one line, got '%s'" % text)
		progression.set_flag(step[0])


func test_completing_the_whole_chain_reaches_the_south_bridge_handoff_then_the_captains() -> void:
	for step: Array in CHAIN:
		progression.set_flag(step[0])
	# Everything through south_bridge_open is done; the next -- and only
	# remaining -- undone main entry is the pre-existing captains beat, which
	# GATEB-OBJECTIVES must not disturb.
	var text: String = log_reader.tracked_text(progression)
	assert_true(text.find("captains") != -1,
		"after the whole opening ladder, the tracked line should be the captains objective; got '%s'" % text)


func test_the_chain_fails_without_any_flags_set_reflecting_an_incomplete_opening() -> void:
	# Sanity check on the assertions themselves (ralph/conventions.md: an
	# assertion that cannot fail is not a test) -- a fresh game must NOT
	# already read as the South Bridge handoff.
	var text: String = log_reader.tracked_text(progression)
	assert_true(text.find("South Bridge") == -1,
		"a fresh game should not start already tracking the South Bridge handoff")
