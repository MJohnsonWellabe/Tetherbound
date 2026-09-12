extends "res://tests/test_case.gd"

## OWNER-0912 Tier 1 #3: Tobin's South Bridge approach line is a route-specific,
## persisted one-shot, and it explicitly names both parts of the requested
## preparation lesson. Production traversal still decides whether players see
## and hear him naturally on the authored leg.

const VILLAGE_NPCS := preload("res://scripts/world/village_npcs.gd")
const PROGRESSION_STATE := preload("res://autoload/progression_state.gd")
const VILLAGERS_PATH := "res://data/config/village_npcs.json"
const DIALOGUE_PATH := "res://data/dialogue/bands/band1_lower_meadows.json"
const PROMPT_ID := "village_south_bridge_team_prompt"
const HEARD_FLAG := "south_bridge_team_prompt_heard"


func _read(path: String) -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	assert_true(parsed is Dictionary, "%s must parse" % path)
	return parsed as Dictionary if parsed is Dictionary else {}


func _tobin() -> Dictionary:
	for raw: Variant in (_read(VILLAGERS_PATH).get("villagers", []) as Array):
		var spec := raw as Dictionary
		if str(spec.get("name", "")) == "Tobin":
			return spec
	return {}


func _prompt() -> Dictionary:
	return (_read(DIALOGUE_PATH).get("conversations", {}) as Dictionary).get(PROMPT_ID, {}) as Dictionary


func test_prompt_is_only_on_the_live_village_to_bridge_leg() -> void:
	var tobin := _tobin()
	assert_false(tobin.is_empty(), "Tobin is not placed on the South Bridge approach")
	var progression: RefCounted = PROGRESSION_STATE.new()
	assert_ne(VILLAGE_NPCS.greeting_for(tobin, progression), PROMPT_ID,
		"the route lesson fired before the player opened the village road")
	progression.set_flag("road_gate_open")
	assert_eq(VILLAGE_NPCS.greeting_for(tobin, progression), PROMPT_ID,
		"the route lesson is missing on the live road-to-bridge leg")
	progression.set_flag("south_bridge_open")
	assert_ne(VILLAGE_NPCS.greeting_for(tobin, progression), PROMPT_ID,
		"advice about preparing for the bridge survives after it is open")


func test_prompt_says_level_and_bond_then_records_one_hearing() -> void:
	var joined := ""
	var effects: Array[String] = []
	for raw: Variant in (_prompt().get("lines", []) as Array):
		if raw is Dictionary:
			var line := raw as Dictionary
			joined += " " + str(line.get("text", ""))
			if line.has("effect"):
				effects.append(str(line.get("effect", "")))
			for effect: Variant in (line.get("effects", []) as Array):
				effects.append(str(effect))
		else:
			joined += " " + str(raw)
	var words := joined.to_lower()
	assert_true(words.contains("level"), "the South Bridge prompt never tells the player to level")
	assert_true(words.contains("bond"), "the South Bridge prompt never tells the player to bond")
	assert_eq(effects.count("flag:%s" % HEARD_FLAG), 1,
		"the route lesson must persist exactly once")


func test_heard_flag_returns_tobin_to_his_ordinary_greeting() -> void:
	var tobin := _tobin()
	var progression: RefCounted = PROGRESSION_STATE.new()
	progression.set_flag("road_gate_open")
	progression.set_flag(HEARD_FLAG)
	assert_eq(VILLAGE_NPCS.greeting_for(tobin, progression), "village_lost_traveler",
		"a spent route lesson should leave Tobin's ordinary conversation intact")


func test_both_new_once_flags_are_personal_character_state() -> void:
	assert_eq(PROGRESSION_STATE.scope_of(HEARD_FLAG), PROGRESSION_STATE.SCOPE_PLAYER)
	assert_eq(PROGRESSION_STATE.scope_of("nessa_overlook_gift_taken"),
		PROGRESSION_STATE.SCOPE_PLAYER)
