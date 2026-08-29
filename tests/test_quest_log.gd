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
	progression.set_flag("opening:beat:road")
	var before: String = log_reader.tracked_text(progression)
	progression.set_flag("road_gate_open")
	var after: String = log_reader.tracked_text(progression)
	assert_ne(after, before, "completing road_gate_open did not change the tracked line")


func test_main_entries_report_done_only_once_their_flag_is_set() -> void:
	var before: Array = log_reader.main_entries(progression)
	var road_gate_entry: Dictionary = {}
	for entry: Dictionary in before:
		if str(entry.get("label", "")).find("village gate") != -1:
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
## Set every main-chain flag that comes BEFORE the captains objective, so the
## captains entry is the tracked line.
##
## Derived from the data, not a hardcoded list. This test used to set
## `road_gate_open` alone, which was enough while the chain had two entries and
## the captains objective was the second -- CHAPTER-OBJECTIVES made it the
## ninth of twelve, and the tracked line became the first of the seven new
## beats in between. Walking the file until the captains row is reached keeps
## the test aimed at what it is actually about (that the HUD line and the log
## row agree about a COUNT) rather than at the chain's length.
func _complete_everything_before_the_captains() -> void:
	for raw: Variant in (_objectives().get("main", []) as Array):
		var entry: Dictionary = raw as Dictionary
		if str(entry.get("label", "")).find("captains") != -1:
			return
		progression.set_flag(str(entry.get("flag_id", "")))


func test_the_tracked_line_carries_the_same_count_as_the_log_row() -> void:
	_complete_everything_before_the_captains()
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
	"legendary_settled": "scripts/world/stronghold_climax.gd::_settle() (either answer to the roster decision)",
	"meadows_acknowledged": "data/dialogue/meadows_freed.json (flag:meadows_acknowledged, on every post-victory conversation's first line)",
	# opening ladder / tournament build-up. None of these are trainer defeat
	# flags, so `_trainer_defeat_flags()` can never see them -- real writers,
	# just not that kind.
	"opening:beat:road": "scripts/story/sequence_director.gd (_set_beat(BEATS.ROAD), OPENING_BEAT_PREFIX + \"road\")",
	# TUTORIAL-CHAIN (OP23-04). Two new rungs and one new count; every one of
	# them is written by something that ships, which is exactly what this
	# registry is for.
	"tam_tools_given": "data/dialogue/village.json's `village_tam_tools` (flag:tam_tools_given, same line as its three give: effects)",
	"creature_bed_built_2": "scripts/build/home_progress.gd::maybe_set_creature_beds() (second placed bed)",
	"creature_bed_built_3": "scripts/build/home_progress.gd::maybe_set_creature_beds() (third placed bed)",
	"tournament_team_fed": "scripts/world/tournament.gd::_write_entry_flags() via team_fed() -- VOLATILE, written true AND false",
	"tournament_team_ready": "scripts/world/tournament.gd::_write_entry_flags() (RG19)",
	"tournament_training_ready": "scripts/world/tournament.gd::_write_entry_flags() (RG19)",
	"home_materials_gathered": "scripts/build/home_progress.gd",
	"home_built": "scripts/build/home_progress.gd",
	"creature_bed_built": "scripts/build/creature_bed.gd (CREATURE_BED_FLAG)",
	"player_slept_at_home": "scripts/build/camp.gd::_on_rest()",
	"tournament_entered": "data/dialogue/bands/band1_lower_meadows.json's tournament_halda_signup (flag:tournament_entered)",
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
	# Was 3 (a placeholder `beat_the_village_trainers` counted Mira/Tam/Oskar
	# as an unordered trio). TOURNAMENT-2 replaced it with the real bracket --
	# sequential `tournament_enter`/`tournament_win` objectives, since a
	# three-round bracket has a fixed order, not a "beat these three in any
	# order" count. That is a legitimate design change, not a regression: the
	# floor tracks what should exist now, `defeat_the_captains` and
	# `fight_through_the_hall`.
	assert_true(counted >= 2,
		"expected at least two counted objectives, found %d" % counted)


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


## --- GATE-E: the finale's own tail (prompt 68's last two lines) --------------
##
## The chain used to stop at `legendary_freed`, which is the moment the machine
## dies -- one flag short of the two beats prompt 68 names after it (resolve the
## roster decision, then see what the region makes of it). A chapter whose HUD
## goes blank at the machine tells the player the game is over while its last
## decision is still open and its whole payoff is still unwalked. These check
## the tail exists, is ordered, and terminates.

const FINALE_TAIL := ["legendary_freed", "legendary_settled", "meadows_acknowledged"]
const FREED_DIALOGUE := "res://data/dialogue/meadows_freed.json"
const ACKNOWLEDGED_FLAG := "meadows_acknowledged"


func _complete_main_up_to(flag_id: String) -> void:
	for raw: Variant in (_objectives().get("main", []) as Array):
		var entry: Dictionary = raw as Dictionary
		if str(entry.get("flag_id", "")) == flag_id:
			return
		progression.set_flag(str(entry.get("flag_id", "")))


func test_the_chain_does_not_end_at_the_machine() -> void:
	var flags: Array[String] = []
	for raw: Variant in (_objectives().get("main", []) as Array):
		flags.append(str((raw as Dictionary).get("flag_id", "")))
	for flag: String in FINALE_TAIL:
		assert_true(flags.has(flag),
			"the finale chain has no objective waiting on '%s'" % flag)
	assert_eq(flags.slice(flags.size() - FINALE_TAIL.size()), FINALE_TAIL,
		"the chapter's last three objectives are not the machine, the roster decision and the walk home, in that order")


func test_freeing_the_legendary_tracks_the_roster_decision_next() -> void:
	_complete_main_up_to("legendary_freed")
	progression.set_flag("legendary_freed")
	var line: String = log_reader.tracked_text(progression)
	assert_false(line.is_empty(),
		"the HUD goes blank the moment the machine dies; the roster decision is still open")
	assert_true(line.to_lower().contains("walks with you"),
		"the beat after the machine is not the roster decision; got '%s'" % line)


## The point of `legendary_settled` rather than `legendary_joined`: a player who
## keeps their five and lets the legendary go has ANSWERED the decision, and the
## chain has to move on for them exactly as it does for the player who kept it.
func test_the_roster_beat_closes_on_the_decision_not_on_the_join() -> void:
	_complete_main_up_to("legendary_settled")
	progression.set_flag("legendary_settled")
	var line: String = log_reader.tracked_text(progression)
	assert_false(line.to_lower().contains("walks with you"),
		"the roster objective is still tracked after the decision was made; got '%s'" % line)
	assert_true(line.to_lower().contains("changed"),
		"the walk home is not the beat after the roster decision; got '%s'" % line)
	# And it must NOT be waiting on the join, which only one of the two legal
	# answers ever sets.
	assert_false(progression.has("legendary_joined"),
		"this test set the join flag by accident; it is meant to prove the chain does not need it")


func test_hearing_the_meadows_ends_the_chain() -> void:
	for flag: String in FINALE_TAIL:
		_complete_main_up_to(flag)
		progression.set_flag(flag)
	assert_eq(log_reader.tracked_text(progression), "",
		"the chapter is over and the HUD is still tracking something")


## The acknowledgment beat is only completable if the words actually carry the
## flag. Five speakers, and the flag is on each one's FIRST line so a player who
## walks off part-way has still had the beat.
func test_every_post_victory_conversation_sets_the_acknowledgment_flag() -> void:
	var file := FileAccess.open(FREED_DIALOGUE, FileAccess.READ)
	assert_true(file != null, "%s is missing" % FREED_DIALOGUE)
	if file == null:
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	assert_true(parsed is Dictionary, "%s is not a JSON object" % FREED_DIALOGUE)
	var conversations: Dictionary = (parsed as Dictionary).get("conversations", {})
	assert_true(conversations.size() >= 4,
		"only %d post-victory conversations; the acknowledgment has almost nowhere to happen"
			% conversations.size())
	for id: String in conversations:
		var lines: Array = (conversations[id] as Dictionary).get("lines", [])
		assert_false(lines.is_empty(), "post-victory conversation '%s' has no lines" % id)
		var first: Variant = lines[0]
		var effects: Array = []
		if first is Dictionary:
			effects = ((first as Dictionary).get("effects", []) as Array).duplicate()
			if str((first as Dictionary).get("effect", "")) != "":
				effects.append(str((first as Dictionary)["effect"]))
		assert_true(effects.has("flag:%s" % ACKNOWLEDGED_FLAG),
			("post-victory conversation '%s' does not set '%s' on its first line; a player who hears "
			+ "only that speaker can never close the chapter's last objective") % [id, ACKNOWLEDGED_FLAG])


## --- TUTORIAL-CHAIN (OP23-04): the guided one-step-at-a-time chain ----------
##
## The owner's report is that the opening "teaches nothing" and that the first
## thing it asks for ("Find a way through the village gate") makes no sense.
## The directive is a chain that names the NEXT thing to do, one step at a
## time, "walking you through every tournament prerequisite until all are
## cleared -- never fronting the full list."
##
## Three properties carry that, and each is checkable:
##   1. the log shows what is done plus the ONE current rung, never more;
##   2. every rung of the opening ladder names a concrete action AND a
##      controller verb;
##   3. the ladder actually covers the real tournament prerequisites, in an
##      order where the two that EXPIRE (rest, food) are the last two before
##      sign-up.
##
## Verified to fail against pre-TUTORIAL-CHAIN `main`: `guided_entries` did not
## exist (a parse error on every test below), and with the old data every hint
## check found no `how` key on any entry.

const TOURNAMENT_CONFIG := "res://data/config/tournament.json"
## Where the guided ladder starts and stops -- the opening's own rungs, the
## ones OP23-04's "until tournament entry" names. Read as flag ids rather than
## labels so a rewording cannot silently drop a rung out of these checks.
const LADDER_FIRST := "opening:beat:road"
const LADDER_LAST := "south_bridge_open"


func _main_data() -> Array:
	return _objectives().get("main", []) as Array


## The ladder as authored, one dictionary per rung, first through last.
func _ladder() -> Array:
	var out: Array = []
	var inside := false
	for raw: Variant in _main_data():
		var entry: Dictionary = raw as Dictionary
		if str(entry.get("flag_id", "")) == LADDER_FIRST:
			inside = true
		if inside:
			out.append(entry)
		if str(entry.get("flag_id", "")) == LADDER_LAST:
			break
	return out


func _flag_order() -> Array[String]:
	var out: Array[String] = []
	for raw: Variant in _main_data():
		out.append(str((raw as Dictionary).get("flag_id", "")))
	return out


func _entry_config() -> Dictionary:
	var file := FileAccess.open(TOURNAMENT_CONFIG, FileAccess.READ)
	assert_true(file != null, "%s is missing" % TOURNAMENT_CONFIG)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	return ((parsed as Dictionary).get("entry", {}) as Dictionary) if parsed is Dictionary else {}


func test_a_fresh_save_is_shown_exactly_one_objective() -> void:
	var guided: Array = log_reader.guided_entries(progression)
	assert_eq(guided.size(), 1,
		"a fresh save should be shown one step, not %d; the whole point of "
			% guided.size() + "OP23-04 is that the full list is never fronted")
	assert_false(bool((guided[0] as Dictionary).get("done", true)),
		"the one step a fresh save is shown already reads done")
	# And the full chain is still there underneath -- this is a presentation
	# rule, not a deletion.
	assert_true(log_reader.main_entries(progression).size() > guided.size(),
		"main_entries() shrank to the guided view; the authored chain must stay whole")


func test_the_guided_view_grows_by_exactly_one_row_per_completed_step() -> void:
	var expected := 1
	for flag: String in _flag_order():
		var guided: Array = log_reader.guided_entries(progression)
		assert_eq(guided.size(), expected,
			"after %d completed steps the log should show %d rows, showed %d"
				% [expected - 1, expected, guided.size()])
		progression.set_flag(flag)
		expected += 1
	# The last flag of the chain is set: everything is done and nothing is open.
	var finished: Array = log_reader.guided_entries(progression)
	assert_eq(finished.size(), _flag_order().size(),
		"a finished chapter should show its whole walked history")
	for raw: Variant in finished:
		assert_true(bool((raw as Dictionary).get("done", false)),
			"'%s' reads open in a finished chapter" % str((raw as Dictionary).get("label", "")))


func test_the_open_row_is_always_the_last_one_and_current_index_says_so() -> void:
	for flag: String in _flag_order():
		var guided: Array = log_reader.guided_entries(progression)
		var current: int = log_reader.current_index(progression)
		assert_eq(current, guided.size() - 1,
			"the open rung must be the last row shown; got index %d of %d"
				% [current, guided.size()])
		# Every row before it is done, or the "one step at a time" promise is
		# broken in the other direction: a skipped step left behind.
		for i in guided.size() - 1:
			assert_true(bool((guided[i] as Dictionary).get("done", false)),
				"row %d is shown open behind the current rung" % i)
		progression.set_flag(flag)
	assert_eq(log_reader.current_index(progression), -1,
		"a finished chapter still reports an open rung")


## The tracked HUD line and the guided log's open row are the same step. Two
## readers of one file that disagree about where the player is would be the
## OP23-04 defect in a new place.
func test_the_hud_line_and_the_guided_logs_open_row_are_the_same_step() -> void:
	for flag: String in _flag_order():
		var current: int = log_reader.current_index(progression)
		var row: Dictionary = log_reader.guided_entries(progression)[current] as Dictionary
		assert_eq(log_reader.tracked_text(progression), str(row.get("label", "")))
		assert_eq(log_reader.tracked_hint(progression), str(row.get("how", "")))
		progression.set_flag(flag)


## --- the hints ---------------------------------------------------------------

func test_every_opening_rung_names_a_concrete_action_and_a_controller_verb() -> void:
	var ladder := _ladder()
	assert_true(ladder.size() >= 10,
		"only %d rungs between the first catch and the bridge; the opening ladder shrank"
			% ladder.size())
	var with_a_button := 0
	for entry: Dictionary in ladder:
		var how := str(entry.get("how", ""))
		assert_false(how.is_empty(),
			("rung '%s' has no `how` line. OP23-04's directive is that each step names "
			+ "the concrete action -- a label alone is the thing the owner reported as "
			+ "teaching nothing") % str(entry.get("id", "")))
		if how.find("{") != -1:
			with_a_button += 1
	# Not every rung CAN name a button (winning a tournament is not a
	# keypress), but most of them are a thing you press something to do.
	assert_true(with_a_button >= 6,
		"only %d of %d opening rungs name a controller verb at all"
			% [with_a_button, ladder.size()])


## The one rule that keeps the hints honest: a button is named by its ACTION
## id, resolved live off the InputMap, never typed in as a letter. A rebind in
## Settings must not be able to turn a hint into a lie.
func test_hints_name_input_actions_not_hardcoded_buttons() -> void:
	for entry: Dictionary in _ladder():
		var how := str(entry.get("how", ""))
		var at := how.find("{")
		while at != -1:
			var close := how.find("}", at)
			assert_true(close != -1, "rung '%s' has an unclosed `{` in its `how`"
				% str(entry.get("id", "")))
			if close == -1:
				return
			var action := how.substr(at + 1, close - at - 1)
			assert_true(InputMap.has_action(action),
				("rung '%s' names `{%s}`, which is not an action in project.godot. "
				+ "The hint would print the raw id at the player.")
					% [str(entry.get("id", "")), action])
			at = how.find("{", close)


func test_a_resolved_hint_replaces_every_placeholder_with_a_real_button() -> void:
	var resolved := str(log_reader.hint_text({"how": "Press {interact} then {inventory}."}))
	assert_true(resolved.find("{") == -1 and resolved.find("}") == -1,
		"a placeholder survived resolution: '%s'" % resolved)
	assert_ne(resolved, "Press then .", "the placeholders resolved to nothing at all")
	# The bound name, whatever the live device is -- not the action id.
	assert_true(resolved.find("interact") == -1,
		"the raw action id leaked into a resolved hint: '%s'" % resolved)


func test_an_entry_with_no_how_line_resolves_to_an_empty_hint_not_a_blank_line() -> void:
	assert_eq(log_reader.hint_text({"label": "Something."}), "")
	# The late chapter authors no hints today; that must read as "draw
	# nothing", never as an empty row under the objective.
	for raw: Variant in _main_data():
		var entry: Dictionary = raw as Dictionary
		var how := str(entry.get("how", ""))
		if how.is_empty():
			continue
		assert_ne(how.strip_edges(), "",
			"rung '%s' authors a whitespace-only `how`" % str(entry.get("id", "")))


## FIRST-HOUR-FUN-REBUILD. One Creature Bed is the compact mandatory care
## lesson; additional beds are useful, but never a five-bed qualifier.
func test_the_bed_rung_requires_one_real_player_built_creature_bed() -> void:
	var bed_entry: Dictionary = {}
	for raw: Variant in _main_data():
		var entry: Dictionary = raw as Dictionary
		if str(entry.get("id", "")) == "tournament_build_creature_beds":
			bed_entry = entry
			break
	assert_false(bed_entry.is_empty(), "objectives.json has no creature-bed care rung")
	assert_eq(str(bed_entry.get("flag_id", "")), "creature_bed_built",
		"one placed Creature Bed should complete the care-rung proof")
	assert_false(bed_entry.has("count_flags"),
		"the compact first-hour care lesson must not require one bed per tournament entrant")


func test_the_bed_rung_finishes_when_the_first_creature_bed_is_built() -> void:
	progression.set_flag("creature_bed_built")
	for entry: Dictionary in log_reader.main_entries(progression):
		if str(entry.get("label", "")).find("Creature Bed") != -1:
			assert_true(bool(entry.get("done", false)),
				"the compact care rung should finish when the first player-built Creature Bed is placed")


## "Keep the satiety drain rate; teach it... an explicit 'feed your team' step
## before tournament sign-up." Both halves: the rung exists, and it is
## ordered where the directive puts it.
func test_a_feed_your_team_rung_stands_between_the_sleep_and_the_sign_up() -> void:
	var order := _flag_order()
	var sleep := order.find("player_slept_at_home")
	var fed := order.find("tournament_team_fed")
	var enter := order.find("tournament_entered")
	assert_true(fed != -1,
		"there is no 'feed your team' rung. Owner directive 2026-08-23 section 2 "
			+ "adds one before sign-up so a hungry team is a taught ritual, not a trap.")
	assert_true(sleep < fed and fed < enter,
		("the feed rung is at %d, between sleep (%d) and sign-up (%d) it is not. "
		+ "Rest and food both EXPIRE -- teaching them anywhere but immediately "
		+ "before the marshal sends a prepared team to her an hour stale.")
			% [fed, sleep, enter])
	var label := ""
	for raw: Variant in _main_data():
		if str((raw as Dictionary).get("flag_id", "")) == "tournament_team_fed":
			label = str((raw as Dictionary).get("label", ""))
	assert_true(label.to_lower().find("feed") != -1,
		"the feed rung does not say 'feed' in words the player reads: '%s'" % label)


## The rung the owner reported by name: "find a way through the village gate"
## as the first thing the game asks of you, which "makes no sense". It must
## still be about the gate -- and it must now say what to do.
func test_the_gate_rung_gives_an_instruction_rather_than_a_riddle() -> void:
	var entry: Dictionary = {}
	for raw: Variant in _main_data():
		if str((raw as Dictionary).get("flag_id", "")) == "road_gate_open":
			entry = raw as Dictionary
	assert_false(entry.is_empty(), "the road-gate rung is gone entirely")
	var label := str(entry.get("label", ""))
	assert_true(label.find("Find a way") == -1,
		"the gate rung still reads as a riddle: '%s'" % label)
	assert_true(str(entry.get("how", "")).to_lower().find("key") != -1,
		"the gate rung's hint does not mention the key lying beside it, which is the "
			+ "one fact that turns this beat from a puzzle into an instruction")


## The rung the ladder was missing: the tools everything below it needs.
func test_the_ladder_hands_over_tools_before_it_asks_for_gathering() -> void:
	var order := _flag_order()
	var tools := order.find("tam_tools_given")
	var gather := order.find("home_materials_gathered")
	assert_true(tools != -1,
		"nothing in the chain sends the player to Tam for an axe, a pickaxe and a knife, "
			+ "and every rung below gathering needs them (item_db.harvest_yield(): "
			+ "WRONG tool yields nothing at all)")
	assert_true(tools < gather,
		"the chain asks for wood and stone (%d) before it hands over the tools (%d)"
			% [gather, tools])


## Out-of-order completion. `objectives.json`'s own comment already promised
## this is safe -- "an entry whose flag is already set is simply done, and the
## tracked line moves to the first one that is not" -- and the guided view has
## to keep that promise while ALSO not showing a beat the player has not
## reached. Both, together: the tracked line still steps over the early
## completion when it gets there, and the log does not spoil it in the
## meantime.
func test_finishing_a_later_beat_early_neither_strands_nor_spoils_the_chain() -> void:
	# Two rungs ahead of where a fresh save stands.
	progression.set_flag("tam_tools_given")
	var guided: Array = log_reader.guided_entries(progression)
	assert_eq(guided.size(), 1,
		"completing a later beat early put %d rows in the log; the player has still "
			% guided.size() + "only reached the first")
	for raw: Variant in guided:
		assert_eq(str((raw as Dictionary).get("label", "")).find("Tam"), -1,
			"a beat the player has not reached is being shown because its flag happens to be set")

	# And when they do get there, it is already done and the line steps over it.
	progression.set_flag("opening:beat:road")
	progression.set_flag("road_gate_open")
	assert_true(log_reader.tracked_text(progression).find("Tam") == -1,
		"the tracked line went back to a beat that was already finished")
	var after: Array = log_reader.guided_entries(progression)
	var saw_tam_done := false
	for raw: Variant in after:
		var entry := raw as Dictionary
		if str(entry.get("label", "")).find("Tam") != -1:
			saw_tam_done = bool(entry.get("done", false))
	assert_true(saw_tam_done,
		"the early-completed beat is not shown as done once the player reaches it")
