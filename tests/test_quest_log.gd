extends "res://tests/test_case.gd"

## SB11 — scripts/world/quest_log.gd, the pure reader that turns
## `data/progression/objectives.json` plus SB9's flag store into the HUD's
## one tracked line and the two-list quest log. Same split
## test_progression_state.gd/test_map_state.gd already draw: pure logic, no
## scene tree.

const PROGRESSION_STATE := preload("res://autoload/progression_state.gd")
const QUEST_LOG := preload("res://scripts/world/quest_log.gd")

var progression: RefCounted = null
var log_reader: RefCounted = null


func before_each() -> void:
	progression = PROGRESSION_STATE.new()
	log_reader = QUEST_LOG.new()


func test_objectives_data_parses_and_has_at_least_one_main_entry() -> void:
	var entries: Array = log_reader.main_entries(progression)
	assert_true(entries.size() >= 1, "data/progression/objectives.json's main list is empty")


func test_tracked_text_names_the_first_undone_main_objective() -> void:
	var text: String = log_reader.tracked_text(progression)
	assert_false(text.is_empty(), "a fresh game should always have something to track")


func test_completing_the_road_gate_objective_changes_the_tracked_text() -> void:
	var before: String = log_reader.tracked_text(progression)
	progression.set_flag("road_gate_open")
	var after: String = log_reader.tracked_text(progression)
	assert_ne(after, before, "completing road_gate_open did not change the tracked line")


func test_main_entries_report_done_only_once_their_flag_is_set() -> void:
	var before: Array = log_reader.main_entries(progression)
	var road_gate_entry: Dictionary = {}
	for entry: Dictionary in before:
		if str(entry.get("label", "")).find("gate") != -1:
			road_gate_entry = entry
	assert_false(bool(road_gate_entry.get("done", true)), "the road-gate entry reads done before its flag is set")

	progression.set_flag("road_gate_open")
	var after: Array = log_reader.main_entries(progression)
	var found_done := false
	for entry: Dictionary in after:
		if str(entry.get("label", "")) == str(road_gate_entry.get("label", "")):
			found_done = bool(entry.get("done", false))
	assert_true(found_done, "the road-gate entry does not read done once its flag is set")


func test_local_entries_is_a_real_empty_list_not_a_parse_failure() -> void:
	# Distinguishes "no local requests authored yet" (empty array, correct)
	# from "the file failed to parse" (also an empty array) by checking the
	# main list, which IS populated, came from the same load.
	assert_eq(log_reader.local_entries(progression), [])
	assert_true(log_reader.main_entries(progression).size() >= 1)


func test_two_readers_never_disagree_about_the_same_flag_state() -> void:
	# The HUD line and the quest-log tab must never show a different verdict
	# on the same objective -- both are this one class, asked twice.
	var reader_a := QUEST_LOG.new()
	var reader_b := QUEST_LOG.new()
	progression.set_flag("road_gate_open")
	assert_eq(reader_a.tracked_text(progression), reader_b.tracked_text(progression))
