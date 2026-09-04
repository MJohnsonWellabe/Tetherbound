extends "res://tests/test_case.gd"

## W06-FINALE-0904 / CL-W7 (owner, 2026-09-04: "the dialogue at the end needs
## to be cut way down. it was paragraphs with the warden. then paragraphs on
## the legendary thing"). The budget, asserted on the REAL merged dialogue
## table rather than on the file's text, so a rewrite that reads long on a
## 1280x800 handheld fails here before a player reads it.
##
## Verified failable: run against the pre-cut stronghold.json (5,343 spoken
## characters, a 379-character Warden line) this file fails
## `test_every_stronghold_line_reads_in_one_glance`,
## `test_the_warden_challenge_is_short` and
## `test_the_whole_ending_is_under_budget`.
##
## The canon that must survive the cut (MEADOWS_PROGRESSION_SPEC sec33, prompt
## 69) is asserted alongside the budget, because a cut that hits the numbers
## by flattening the Warden into a generic boss is the failure the owner
## directive explicitly warned against.

const RUNNER := preload("res://scripts/story/dialogue_runner.gd")
const STRONGHOLD_PATH := "res://data/dialogue/stronghold.json"

const MAX_LINE_CHARS := 110
const MAX_CHALLENGE_CHARS := 350
const MAX_FILE_CHARS := 2000

const CONVERSATIONS := [
	"stronghold_duty_board",
	"stronghold_reveal",
	"stronghold_warden_challenge",
	"stronghold_warden_defeated",
	"stronghold_chamber",
	"stronghold_free_legendary",
	"stronghold_legendary_joins",
	"stronghold_machinery_fails",
]

## Speaker -> the portrait the 2026-09-04 portrait contract fixes for them.
const PORTRAITS := {
	"stronghold_warden_challenge": "res://assets/ui/portraits/warden.png",
	"stronghold_warden_defeated": "res://assets/ui/portraits/warden.png",
}


func _file() -> Dictionary:
	var file := FileAccess.open(STRONGHOLD_PATH, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	return parsed if parsed is Dictionary else {}


func _lines(id: String) -> Array[String]:
	var out: Array[String] = []
	var conversation: Dictionary = RUNNER.table().get(id, {}) as Dictionary
	for line: Variant in (conversation.get("lines", []) as Array):
		if line is Dictionary:
			out.append(str((line as Dictionary).get("text", "")))
		else:
			out.append(str(line))
	return out


func _chars(id: String) -> int:
	var total := 0
	for text: String in _lines(id):
		total += text.length()
	return total


func _flag_effects(id: String, flag: String) -> int:
	var found := 0
	var conversation: Dictionary = RUNNER.table().get(id, {}) as Dictionary
	for line: Variant in (conversation.get("lines", []) as Array):
		if not line is Dictionary:
			continue
		for effect: Variant in ((line as Dictionary).get("effects", []) as Array):
			var parts: Array = RUNNER.parse_effect(str(effect))
			if str(parts[0]) == "flag" and str(parts[1]) == flag:
				found += 1
	return found


func test_the_stronghold_file_is_the_table_this_measures() -> void:
	var doc := _file()
	assert_false(doc.is_empty(), "stronghold.json did not parse")
	var conversations: Dictionary = doc.get("conversations", {}) as Dictionary
	for id: String in CONVERSATIONS:
		assert_true(conversations.has(id), "stronghold.json has no '%s'" % id)
		assert_true(RUNNER.has(id), "the merged table has no '%s'" % id)
	assert_eq(conversations.size(), CONVERSATIONS.size(),
		"stronghold.json carries %d conversations; this budget measures %d" % [conversations.size(), CONVERSATIONS.size()])


func test_every_stronghold_line_reads_in_one_glance() -> void:
	for id: String in CONVERSATIONS:
		var lines := _lines(id)
		assert_true(lines.size() > 0, "'%s' has no lines" % id)
		for text: String in lines:
			assert_true(text.length() <= MAX_LINE_CHARS,
				"'%s' has a %d-character line (budget %d): \"%s\"" % [id, text.length(), MAX_LINE_CHARS, text])


func test_the_warden_challenge_is_short() -> void:
	var total := _chars("stronghold_warden_challenge")
	assert_true(total <= MAX_CHALLENGE_CHARS,
		"the Warden's pre-fight speech is %d characters; budget %d" % [total, MAX_CHALLENGE_CHARS])


func test_the_whole_ending_is_under_budget() -> void:
	var total := 0
	for id: String in CONVERSATIONS:
		total += _chars(id)
	assert_true(total <= MAX_FILE_CHARS,
		"the stronghold's spoken text is %d characters; budget %d" % [total, MAX_FILE_CHARS])


## Sec33's three beats, as lines: he believes separation prevents chaos, he
## confirms the readout rather than denying it, and he does not recant when
## he loses.
func test_the_warden_keeps_his_worldview_through_the_cut() -> void:
	var challenge := " ".join(_lines("stronghold_warden_challenge")).to_lower()
	assert_true(challenge.contains("disorder"),
		"the Warden no longer states that freedom without control becomes disorder")
	assert_true(challenge.contains("holding apart"),
		"the Warden no longer says what the barriers are holding apart")
	assert_true(challenge.contains("true") or challenge.contains("board"),
		"the Warden no longer confirms the readout; sec33 has him confirm it, not deny it")
	assert_false(challenge.contains("you cannot stop me"), "the Warden says the line sec28 rules out")
	var defeated := " ".join(_lines("stronghold_warden_defeated")).to_lower()
	assert_true(defeated.contains("warn") or defeated.contains("seams come down") or defeated.contains("seams"),
		"the beaten Warden no longer warns what freeing it costs")
	for recant: String in ["i was wrong", "you were right", "you are right", "forgive"]:
		assert_false(defeated.contains(recant),
			"the beaten Warden recants (\"%s\"); sec33 says he does not" % recant)


func test_the_flag_hooks_survive_the_cut() -> void:
	assert_eq(_flag_effects("stronghold_reveal", "learned_legendary_is_the_source"), 1,
		"the readout no longer sets 'learned_legendary_is_the_source' exactly once")
	assert_eq(_flag_effects("stronghold_free_legendary", "legendary_freed"), 1,
		"the freeing no longer sets 'legendary_freed' exactly once")
	var reveal := " ".join(_lines("stronghold_reveal")).to_lower()
	assert_true(reveal.contains("veridian") and reveal.contains("legendary"),
		"the readout no longer names what is in chamber five")


func test_the_warden_speaks_with_his_own_portrait() -> void:
	for id: String in PORTRAITS:
		var conversation: Dictionary = RUNNER.table().get(id, {}) as Dictionary
		assert_eq(str(conversation.get("portrait", "")), str(PORTRAITS[id]),
			"'%s' is drawn with '%s', not the Warden's own portrait" % [id, str(conversation.get("portrait", ""))])
