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

func test_homecoming_requires_matching_personal_ending_receipts() -> void:
	var saved := {"ending": {"character_id": "owner", "outcome_id": "accepted",
		"home_return_receipt": "arrival", "starter_uid": "starter", "party_signature": "five",
		"chapter_choices": ["meadows:accepted"], "homecoming_seen": false, "regional_credits_seen": false}}
	assert_true(HANDOFF.compare_ending(saved, saved.duplicate(true)))
	assert_false(HANDOFF.compare_ending({}, saved), "legacy state is not an ending proof")
	assert_false(HANDOFF.compare_ending({"ending": {}}, {"ending": {}}))
	for key: String in saved.ending:
		var changed := saved.duplicate(true)
		changed.ending.erase(key)
		assert_false(HANDOFF.compare_ending(saved, changed), key)

func test_tidewake_portal_handoff_preserves_inventory_and_realm() -> void:
	var previous := {"uids": ["a"], "flags": ["earned"], "items": {"home_key": 1, "wood": 2}, "realm": "cloudreach"}
	var loaded := {"uids": ["a"], "flags": ["earned"], "inventory": {"wood": 2, "home_key": 1}, "realm": "cloudreach"}
	assert_true(HANDOFF.compare_route(previous, loaded).is_empty(), "different key names and dictionary order carry the same state")
	loaded.inventory.wood = 3
	assert_true(HANDOFF.compare_route(previous, loaded).has("inventory"))
	loaded.realm = "water"
	assert_true(HANDOFF.compare_route(previous, loaded).has("realm"))
	previous.erase("items")
	assert_true(HANDOFF.compare_route(previous, loaded).has("inventory"), "missing inventory cannot silently pass")

func test_stormwood_to_homestead_keeps_flags_and_inventory() -> void:
	var prior := {"uids": ["a"], "world_flags": ["saved"], "items": {"wood": 2}, "realm": "stormwood"}
	var loaded := {"uids": ["a"], "flags": ["saved"], "inventory": {"wood": 2}, "realm": "stormwood"}
	assert_true(HANDOFF.compare_route(prior, loaded).is_empty())
	loaded.flags = []
	assert_true(HANDOFF.compare_route(prior, loaded).has("flags"))

func test_cross_chapter_required_fields_allow_only_explicit_training_aliases() -> void:
	var chapter := {"uids": ["a"], "world_flags": ["saved"], "inventory": {"home_key": 1}, "realm": "cloudreach"}
	assert_true(HANDOFF.missing_route_fields(chapter, true).is_empty())
	assert_eq(HANDOFF.missing_route_fields(chapter), ["flags", "items"], "split Tidewake pieces retain canonical requirements")
	for field: String in ["uids", "world_flags", "inventory", "realm"]:
		var missing := chapter.duplicate(true)
		missing.erase(field)
		assert_false(HANDOFF.missing_route_fields(missing, true).is_empty(), field)
		missing[field] = null
		assert_false(HANDOFF.missing_route_fields(missing, true).is_empty(), field + " null")

func test_present_canonical_fields_cannot_hide_behind_matching_aliases() -> void:
	var previous := {"uids": ["a"], "flags": [], "world_flags": ["saved"], "items": {}, "inventory": {"home_key": 1}, "realm": "stormwood"}
	var loaded := {"uids": ["a"], "flags": ["saved"], "inventory": {"home_key": 1}, "realm": "stormwood"}
	assert_true(HANDOFF.missing_route_fields(previous, true).is_empty())
	assert_true(HANDOFF.compare_route(previous, loaded).has("flags"))
	assert_true(HANDOFF.compare_route(previous, loaded).has("inventory"), "conflicting aliases cannot conceal different saved stock")
	# A null canonical field must never be rescued by an alternate name.
	previous.flags = null
	assert_true(HANDOFF.missing_route_fields(previous, true).has("flags"))
