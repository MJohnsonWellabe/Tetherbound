extends "res://tests/test_case.gd"

## Owner playtest 2026-09-12: a tree at the Ironwood Grove's colossal scale
## needs a storyline. These source contracts keep that story on the existing
## Juno -> Halder -> captain-sigil path without exposing the Hall's final reveal.
## A production walk still decides whether the tree, dialogue cadence and quest
## handoff read together in the live world.

const TRAINERS_PATH := "res://data/dialogue/trainers.json"
const OBJECTIVES_PATH := "res://data/progression/objectives.json"
const PRESENTATION_PATH := "res://data/config/ironwood_grove_presentation.json"

const STORY_DIALOGUE: Array[String] = [
	"pasture_drover_juno_challenge",
	"pasture_drover_juno_defeated",
	"captain_field_challenge",
	"captain_field_defeated",
]

const STRONGHOLD_ONLY_WORDS: Array[String] = [
	"legendary",
	"veridian",
	"living power",
	"power source",
]


func _read(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	assert_true(file != null, "%s could not be opened" % path)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	assert_true(parsed is Dictionary, "%s is not a JSON object" % path)
	return parsed as Dictionary if parsed is Dictionary else {}


func _conversation(id: String) -> Dictionary:
	return (_read(TRAINERS_PATH).get("conversations", {}) as Dictionary).get(id, {}) as Dictionary


func _plain_lines(id: String) -> Array[String]:
	var out: Array[String] = []
	for raw: Variant in (_conversation(id).get("lines", []) as Array):
		if raw is Dictionary:
			out.append(str((raw as Dictionary).get("text", "")))
		else:
			out.append(str(raw))
	return out


func _joined_lines(id: String) -> String:
	return " ".join(_plain_lines(id)).to_lower()


func _local_objective(id: String) -> Dictionary:
	for raw: Variant in (_read(OBJECTIVES_PATH).get("local", []) as Array):
		var entry := raw as Dictionary
		if str(entry.get("id", "")) == id:
			return entry
	return {}


func _main_objective(id: String) -> Dictionary:
	for raw: Variant in (_read(OBJECTIVES_PATH).get("main", []) as Array):
		var entry := raw as Dictionary
		if str(entry.get("id", "")) == id:
			return entry
	return {}


func test_the_colossal_landmark_has_a_named_story_subject() -> void:
	var hero_tree := _read(PRESENTATION_PATH).get("hero_tree", {}) as Dictionary
	assert_true(float(hero_tree.get("height_m", 0.0)) >= 150.0,
		"the story contract should remain attached to the colossal grove landmark")
	assert_true(_joined_lines("pasture_drover_juno_challenge").contains("first ironwood"),
		"Juno no longer names the tree the player just passed")
	assert_true(_joined_lines("pasture_drover_juno_challenge").contains("windfall"),
		"the ancient tree no longer has a reason to be the grove's mother tree")


func test_juno_opens_the_question_and_halder_answers_it() -> void:
	var juno_after := _joined_lines("pasture_drover_juno_defeated")
	assert_true(juno_after.contains("blue scars"))
	assert_true(juno_after.contains("halder"))
	var halder_before := _joined_lines("captain_field_challenge")
	var halder_after := _joined_lines("captain_field_defeated")
	assert_true(halder_before.contains("first ironwood"))
	assert_true(halder_before.contains("roots"))
	assert_true(halder_before.contains("buried line"))
	assert_true(halder_after.contains("old crown"))
	assert_true(halder_after.contains("pasture"))


func test_the_story_uses_existing_progression_facts_only() -> void:
	var objective := _local_objective("band4_first_ironwood")
	assert_false(objective.is_empty(), "the First Ironwood local request is missing")
	assert_eq(str(objective.get("revealed_by", "")), "defeated_pasture_drover_juno")
	assert_eq(str(objective.get("flag_id", "")), "defeated_captain_field")
	assert_eq(str(objective.get("scope", "")), "world")
	assert_true(str(objective.get("label", "")).contains("Captain Halder"))
	assert_true(str(objective.get("label", "")).contains("First Ironwood"))


func test_the_main_route_uses_the_landmark_between_oreth_and_vess() -> void:
	var how := str(_main_objective("defeat_the_captains").get("how", ""))
	assert_true(how.contains("Oreth"))
	assert_true(how.contains("First Ironwood"))
	assert_true(how.contains("Halder"))
	assert_true(how.contains("Vess"))
	assert_true(how.find("Oreth") < how.find("First Ironwood"))
	assert_true(how.find("First Ironwood") < how.find("Halder"))
	assert_true(how.find("Halder") < how.find("Vess"))


func test_the_early_tree_story_keeps_the_stronghold_reveal_closed() -> void:
	for id: String in STORY_DIALOGUE:
		var lines := _plain_lines(id)
		assert_true(lines.size() >= 2 and lines.size() <= 3,
			"%s breaks the trainer dialogue's two-or-three-line budget" % id)
		var joined := " ".join(lines).to_lower()
		for forbidden: String in STRONGHOLD_ONLY_WORDS:
			assert_false(joined.contains(forbidden),
				"%s spends the stronghold-only '%s' reveal early" % [id, forbidden])
		for line: String in lines:
			assert_true(line.length() <= 110,
				"%s has a dialogue line too long for the existing trainer cadence" % id)
