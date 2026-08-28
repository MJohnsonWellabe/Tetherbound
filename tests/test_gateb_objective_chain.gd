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
## TUTORIAL-CHAIN (OP23-04) re-authored the ladder and this list with it: two
## new rungs (Tam's tools, feeding the team) and the bed rung now completing on
## the THIRD bed rather than the first, per the owner's 2026-08-23 directives.
## The rungs either side of them are unchanged, wording included, so this stays
## a diff of the ladder rather than a rewrite of the check.
##
## `creature_bed_built` and `creature_bed_built_2` are deliberately NOT rows
## here: they fill the rung's 1/3 counter without completing it, which
## `tests/test_quest_log.gd::test_the_bed_rung_reads_a_count_and_is_done_only_
## on_the_last_bed` is the check for. A row here means "this flag moves the
## tracked line", and those two do not -- that is the point of the count.
const CHAIN := [
	["opening:beat:road", "first wild creature"],
	["road_gate_open", "village gate"],
	["tam_tools_given", "Tam"],
	["tournament_team_ready", "tournament"],
	["tournament_training_ready", "Train with"],
	["home_materials_gathered", "Gather materials"],
	["home_built", "campsite"],
	["creature_bed_built_3", "Creature Bed"],
	["player_slept_at_home", "Sleep until"],
	["tournament_team_fed", "Feed your team"],
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


func test_completing_the_whole_chain_reaches_the_south_bridge_handoff_then_the_next_beat() -> void:
	for step: Array in CHAIN:
		progression.set_flag(step[0])
	# Everything through south_bridge_open is done; the tracked line should
	# move on to whatever `data/progression/objectives.json` names as the
	# very next main entry after `south_bridge_open` -- Gate C/D1's own call,
	# not this file's. Read straight from data rather than hardcoding a label
	# (ralph/conventions.md: assert the rule, derive the value) so this test
	# does not go stale the next time a beat is inserted between the bridge
	# and the captains, the way `clear_the_burrow_warrens` etc. already were.
	var file := FileAccess.open("res://data/progression/objectives.json", FileAccess.READ)
	assert_true(file != null, "data/progression/objectives.json is missing")
	var parsed: Variant = JSON.parse_string(file.get_as_text()) if file != null else null
	assert_true(parsed is Dictionary, "data/progression/objectives.json is not a JSON object")
	var main: Array = (parsed as Dictionary).get("main", []) as Array if parsed is Dictionary else []
	var bridge_index := -1
	for i in main.size():
		if str((main[i] as Dictionary).get("flag_id", "")) == "south_bridge_open":
			bridge_index = i
			break
	assert_true(bridge_index != -1 and bridge_index + 1 < main.size(),
		"south_bridge_open is not in objectives.json's main chain, or has nothing after it")
	var next_label := str((main[bridge_index + 1] as Dictionary).get("label", ""))
	assert_ne(next_label, "", "the main entry after south_bridge_open has no label")

	var text: String = log_reader.tracked_text(progression)
	assert_true(text.find(next_label) != -1,
		"after the whole opening ladder, the tracked line should be '%s' (the next main entry after south_bridge_open); got '%s'" % [next_label, text])


func test_the_chain_fails_without_any_flags_set_reflecting_an_incomplete_opening() -> void:
	# Sanity check on the assertions themselves (ralph/conventions.md: an
	# assertion that cannot fail is not a test) -- a fresh game must NOT
	# already read as the South Bridge handoff.
	var text: String = log_reader.tracked_text(progression)
	assert_true(text.find("South Bridge") == -1,
		"a fresh game should not start already tracking the South Bridge handoff")
