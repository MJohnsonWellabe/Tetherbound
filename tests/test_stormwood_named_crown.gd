extends "res://tests/test_case.gd"

const CHAPTER := preload("res://scripts/world/stormwood_chapter.gd")
const PEOPLE := preload("res://scripts/world/village_npcs.gd")
const PROGRESSION := preload("res://autoload/progression_state.gd")
const CHAPTER_LOGIC := preload("res://scripts/world/realm_chapter_progression.gd")


func _chapter_data() -> Dictionary:
	var parsed: Variant = JSON.parse_string(
		FileAccess.get_file_as_string("res://data/config/stormwood_chapter.json"))
	return parsed as Dictionary if parsed is Dictionary else {}


func _wen_actor() -> Dictionary:
	var parsed: Variant = JSON.parse_string(
		FileAccess.get_file_as_string("res://data/config/stormwood_npcs.json"))
	if not parsed is Dictionary:
		return {}
	for raw: Variant in (parsed as Dictionary).get("characters", []):
		if raw is Dictionary and str((raw as Dictionary).get("id", "")) == "archivist_wen":
			return raw as Dictionary
	return {}


func test_wen_refuses_the_truth_until_the_crown_guardian_is_durably_clear() -> void:
	var flags := PROGRESSION.new()
	var spec := CHAPTER.npc_spec(_wen_actor())
	flags.set_flag("stormwood:crown_reached")
	assert_eq(PEOPLE.greeting_for(spec, flags), CHAPTER.WEN_REFUSAL_CONVERSATION)
	var refusal := CHAPTER.wen_refusal_conversation()
	assert_true((refusal.get("lines", []) as Array).size() >= 2)
	assert_true(JSON.stringify(refusal).to_lower().contains("guardian"))
	flags.set_flag(CHAPTER.CROWN_GUARDIAN_CLEAR_FLAG)
	assert_eq(PEOPLE.greeting_for(spec, flags), "stormwood_archivist_wen_in_progress")


func test_guardian_then_wen_truth_then_rootgate_is_the_only_accepted_sequence() -> void:
	var flags := PROGRESSION.new()
	var chapter := _chapter_data()
	flags.set_flag("stormwood:act_i_complete")
	flags.set_flag("stormwood:crown_reached")

	var early_truth := CHAPTER_LOGIC.dispatch(flags, chapter, "dialogue:wen_truth")
	assert_false(bool(early_truth.accepted))
	assert_false(flags.has("stormwood:engine_truth_learned"))
	var early_rootgate := CHAPTER_LOGIC.dispatch(flags, chapter, "heartstone:rootgate")
	assert_false(bool(early_rootgate.accepted))
	assert_false(flags.has("stormwood:rootgate_released"))

	flags.set_flag(CHAPTER.CROWN_GUARDIAN_CLEAR_FLAG)
	var still_early_rootgate := CHAPTER_LOGIC.dispatch(flags, chapter, "heartstone:rootgate")
	assert_false(bool(still_early_rootgate.accepted))
	assert_false(flags.has("stormwood:rootgate_released"))

	var truth := CHAPTER_LOGIC.dispatch(flags, chapter, "dialogue:wen_truth")
	assert_true(bool(truth.accepted))
	assert_true(flags.has("stormwood:engine_truth_learned"))
	var rootgate := CHAPTER_LOGIC.dispatch(flags, chapter, "heartstone:rootgate")
	assert_true(bool(rootgate.accepted))
	assert_true(flags.has("stormwood:rootgate_released"))
	assert_true(flags.has("stormwood:act_ii_complete"))


func test_crown_prerequisite_metadata_names_the_same_guardian_flag_as_the_encounter() -> void:
	var chapter := _chapter_data()
	var persistent: Dictionary = chapter.get("persistent_flags", {})
	assert_true((persistent.get("main", []) as Array).has(CHAPTER.CROWN_GUARDIAN_CLEAR_FLAG))
	var objectives := {}
	for act: Dictionary in chapter.get("acts", []):
		for objective: Dictionary in act.get("objectives", []):
			objectives[str(objective.get("flag_id", ""))] = objective
	for id: String in ["stormwood:engine_truth_learned", "stormwood:rootgate_released"]:
		assert_true(objectives.has(id))
		assert_true((objectives[id].get("requires_flags", []) as Array).has(
			CHAPTER.CROWN_GUARDIAN_CLEAR_FLAG))
