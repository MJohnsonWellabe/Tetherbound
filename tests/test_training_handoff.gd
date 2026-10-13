extends "res://tests/test_case.gd"
const HANDOFF := preload("res://tools/earned_saves/training_handoff.gd")

func _state() -> Dictionary:
	return {"training": {"version": 1, "party": [{"uid": "same-owned-creature",
		"species": "terrapup", "level": 30, "xp": 1800, "cap_level": 40,
		"breakthroughs": [1, 2, 3], "evolution_choices": {}}],
		"master_wins": ["master_t3"], "feast_recipes": ["feast_t3"]}}

func test_saved_training_survives_json_number_conversion() -> void:
	var state := _state()
	var disk: Dictionary = JSON.parse_string(JSON.stringify(state))
	assert_true(HANDOFF.compare(disk, state).matches)

func test_same_uid_does_not_hide_generated_levels_or_caps() -> void:
	for field: String in ["level", "xp", "cap_level", "breakthroughs", "evolution_choices"]:
		var loaded := _state()
		loaded.training.party[0][field] = [1,2,3,4] if field == "breakthroughs" else ({"4":"stay"} if field == "evolution_choices" else 999)
		assert_false(HANDOFF.compare(_state(), loaded).matches, field)

func test_missing_or_fabricated_master_recipe_does_not_match() -> void:
	for field: String in ["master_wins", "feast_recipes"]:
		var loaded := _state()
		loaded.training[field] = []
		assert_false(HANDOFF.compare(_state(), loaded).matches, field)

func test_legacy_seam_is_not_progression_proof() -> void:
	var legacy := HANDOFF.compare({}, _state())
	assert_false(legacy.checked)
	assert_false(legacy.matches)
	assert_false(HANDOFF.compare(_state(), {}).matches)
