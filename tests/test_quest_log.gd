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


## --- SF34: the captains' 2/3 count (spec §16) --------------------------------

const CAPTAIN_FLAGS := ["defeated_captain_field", "defeated_captain_ridge",
	"defeated_captain_riverwatch"]


func _captain_line() -> String:
	for entry: Dictionary in log_reader.main_entries(progression):
		if str(entry.get("label", "")).find("captains") != -1:
			return str(entry.get("label", ""))
	return ""


func test_the_captains_objective_shows_a_count_and_starts_at_zero_of_three() -> void:
	var line: String = _captain_line()
	assert_false(line.is_empty(), "objectives.json has no Upper Meadows captains entry")
	assert_true(line.ends_with("0/3"), "the captains line should start at 0/3; got '%s'" % line)


## The exact line spec §16 gives as its example.
func test_beating_two_captains_reads_two_of_three() -> void:
	progression.set_flag(CAPTAIN_FLAGS[0])
	progression.set_flag(CAPTAIN_FLAGS[1])
	assert_true(_captain_line().ends_with("2/3"), "got '%s'" % _captain_line())


func test_the_count_reaches_three_of_three_before_the_objective_is_done() -> void:
	for flag: String in CAPTAIN_FLAGS:
		progression.set_flag(flag)
	var line: String = _captain_line()
	assert_true(line.ends_with("3/3"), "got '%s'" % line)
	# Winning three fights is not the objective -- opening the gate is.
	for entry: Dictionary in log_reader.main_entries(progression):
		if str(entry.get("label", "")) == line:
			assert_false(bool(entry.get("done", true)),
				"the captains objective read done before the Hall approach was opened")


func test_the_captains_objective_is_done_only_once_the_hall_approach_opens() -> void:
	for flag: String in CAPTAIN_FLAGS:
		progression.set_flag(flag)
	progression.set_flag("hall_approach_open")
	var found_done := false
	for entry: Dictionary in log_reader.main_entries(progression):
		if str(entry.get("label", "")).find("captains") != -1:
			found_done = bool(entry.get("done", false))
	assert_true(found_done, "opening the Hall approach did not close the captains objective")


## The HUD's one tracked line and the quest-log row are the same string,
## counter included -- the count is computed in one place for exactly this
## reason.
func test_the_tracked_line_carries_the_same_count_as_the_log_row() -> void:
	progression.set_flag("road_gate_open")
	progression.set_flag(CAPTAIN_FLAGS[0])
	assert_eq(log_reader.tracked_text(progression), _captain_line())
	assert_true(log_reader.tracked_text(progression).ends_with("1/3"))


## An entry with no `count_flags` must be untouched by the feature -- no
## trailing " 0/0", no change of any kind.
func test_an_uncounted_objective_still_renders_as_a_plain_label() -> void:
	var line: String = log_reader.tracked_text(progression)
	assert_false(line.is_empty())
	assert_false(line.ends_with("/0"), "an uncounted objective grew a counter: '%s'" % line)


func test_two_readers_never_disagree_about_the_same_flag_state() -> void:
	# The HUD line and the quest-log tab must never show a different verdict
	# on the same objective -- both are this one class, asked twice.
	var reader_a := QUEST_LOG.new()
	var reader_b := QUEST_LOG.new()
	progression.set_flag("road_gate_open")
	assert_eq(reader_a.tracked_text(progression), reader_b.tracked_text(progression))


## --- CHAPTER_OBJECTIVES_CHECKS (prompt 68) ----------------------------------
##
## The chain went from two entries to twelve, which turns a class of typo that
## used to be harmless into a chapter-stopper. Every entry here is DONE only
## when its own `flag_id` is set, and the tracked line is the first entry that
## is not done -- so an entry naming a flag NOTHING IN THE GAME EVER SETS does
## not fail loudly, it silently becomes the permanent tracked objective and
## every beat behind it is unreachable in the HUD for the rest of the chapter.
## `road_gate_opne` would do it. These tests are the cheap check against that.

const TRAINERS_FOR_OBJECTIVES := preload("res://scripts/world/trainer_npc.gd")
const OBJECTIVES_PATH := "res://data/progression/objectives.json"

## Flags set by the world rather than by beating somebody: each is named by a
## script or config that ships, and the comment says which, so a reader can
## check the claim without grepping.
const WORLD_FLAGS := {
	"road_gate_open": "scripts/world/playground_world.gd's road gate, opened via key_pickup.gd",
	"south_bridge_open": "scripts/world/south_bridge.gd",
	"mill_crossing_restored": "scripts/world/mill_crossing.gd (MILL_FLAG)",
	"warrens_cleared": "scripts/world/burrow_warrens.gd",
	"captive_rescued": "data/dialogue/relay.json (flag:captive_rescued)",
	"relay_disabled": "scripts/world/tether_relay.gd (console flag)",
	"hall_approach_open": "scripts/world/playground_world.gd (SIGIL_GATE_FLAG)",
	"legendary_freed": "scripts/world/stronghold_climax.gd",
}


func _objectives() -> Dictionary:
	var file := FileAccess.open(OBJECTIVES_PATH, FileAccess.READ)
	assert_true(file != null, "%s is missing" % OBJECTIVES_PATH)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	assert_true(parsed is Dictionary, "%s is not a JSON object" % OBJECTIVES_PATH)
	return parsed if parsed is Dictionary else {}


func _trainer_defeat_flags() -> Dictionary:
	var out: Dictionary = {}
	for entry: Variant in TRAINERS_FOR_OBJECTIVES.trainers():
		var flag := str((entry as Dictionary).get("defeat_flag", ""))
		if flag != "":
			out[flag] = str((entry as Dictionary).get("id", ""))
	return out


## The one that matters: every flag the chain waits on is a flag something
## actually sets -- a trainer's own defeat_flag, or a named world flag above.
func test_every_objective_waits_on_a_flag_something_actually_sets() -> void:
	var beaten := _trainer_defeat_flags()
	assert_false(beaten.is_empty(),
		"no trainer defeat flags were read; this check would pass vacuously")
	var checked := 0
	for raw: Variant in (_objectives().get("main", []) as Array):
		var entry: Dictionary = raw as Dictionary
		var flag := str(entry.get("flag_id", ""))
		assert_ne(flag, "", "a main objective names no flag_id at all")
		checked += 1
		assert_true(beaten.has(flag) or WORLD_FLAGS.has(flag),
			("main objective '%s' waits on flag '%s', which no trainer sets and which is not a known world "
			+ "flag; it would become the permanent tracked objective and strand every beat behind it")
			% [str(entry.get("id", "")), flag])
	assert_true(checked >= 10,
		"only %d main objectives were checked; the chain shrank back toward its two-entry state" % checked)


## Same rule for the n/3 counters. A miscounted objective is milder than a
## stranded one -- it still completes -- but "2/3" that can only ever reach 2/3
## tells the player to go and find a fight that does not exist.
func test_every_counted_objective_counts_real_defeat_flags() -> void:
	var beaten := _trainer_defeat_flags()
	var counted := 0
	for raw: Variant in (_objectives().get("main", []) as Array):
		var entry: Dictionary = raw as Dictionary
		var flags: Array = entry.get("count_flags", []) as Array
		if flags.is_empty():
			continue
		counted += 1
		for flag: Variant in flags:
			assert_true(beaten.has(str(flag)) or WORLD_FLAGS.has(str(flag)),
				"objective '%s' counts '%s', which nothing sets; its counter could never fill"
					% [str(entry.get("id", "")), str(flag)])
		# Deliberately NOT asserting that an entry's own flag is among the ones
		# it counts. `defeat_the_captains` counts the three captains and
		# completes on `hall_approach_open`, because beating them and then
		# carrying their Sigils to the gate are two different acts -- its
		# counter is meant to read 3/3 while the objective is still open, and
		# test_the_count_reaches_three_of_three_before_the_objective_is_done
		# above exists to pin exactly that.
	assert_true(counted >= 3,
		"expected at least three counted objectives, found %d" % counted)


## No two entries may wait on the same flag: the second is done the instant the
## first is, so it can never be tracked and reads as a beat the player skipped.
func test_no_two_objectives_wait_on_the_same_flag() -> void:
	var seen: Array[String] = []
	for raw: Variant in (_objectives().get("main", []) as Array):
		var flag := str((raw as Dictionary).get("flag_id", ""))
		assert_false(seen.has(flag),
			"two main objectives both complete on '%s'; the later one can never be tracked" % flag)
		seen.append(flag)


## Setting every flag in order must leave nothing tracked. Catches a chain that
## can be walked start to finish and still claims the player has work left.
func test_completing_the_whole_chain_leaves_nothing_tracked() -> void:
	for raw: Variant in (_objectives().get("main", []) as Array):
		progression.set_flag(str((raw as Dictionary).get("flag_id", "")))
	for raw: Variant in log_reader.main_entries(progression):
		assert_true(bool((raw as Dictionary).get("done", false)),
			"'%s' still reads not-done after every objective flag was set"
				% str((raw as Dictionary).get("label", "")))
	assert_eq(log_reader.tracked_text(progression), "",
		"the chapter's objectives are all complete and something is still tracked")
