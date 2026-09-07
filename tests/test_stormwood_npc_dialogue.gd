extends "res://tests/test_case.gd"

const NAMES := ["rodkeeper_hesk", "stormreader_tamsin", "cook_marl", "courier_pim", "trainer_ivo", "grunt_lieutenant_dace", "warden_elect_bryn", "trader_oswin", "tether_lieutenant_varga", "keeper_ondra", "archivist_wen", "elder_maud", "trader_fenn", "caretaker_lio", "ace_trainer_rook", "defector_sable", "officer_kestrel", "captain_marrow", "crown_caretaker_neri"]

func _load(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	var parsed: Variant = JSON.parse_string(file.get_as_text()) if file != null else null
	return parsed if parsed is Dictionary else {}

func test_registry_has_contract_cast_and_two_crown_residents() -> void:
	var registry := _load("res://data/config/stormwood_npcs.json")
	var chars: Array = registry.get("characters", [])
	assert_eq(chars.size(), 19)
	var ids := {}
	var crown := 0
	for entry in chars:
		ids[entry.get("id", "")] = true
		assert_true(FileAccess.file_exists(ProjectSettings.globalize_path(entry.get("portrait", ""))))
		if entry.get("region_id", "") == "hollow_crown": crown += 1
	for id in NAMES: assert_true(ids.has(id), "missing NPC %s" % id)
	assert_true(crown >= 2)

func test_every_named_npc_has_three_states_and_flag_bindings() -> void:
	var dialogue := _load("res://data/dialogue/stormwood.json")
	var conversations: Dictionary = dialogue.get("conversations", {})
	for id in NAMES:
		for state in ["arrival", "in_progress", "post_storm"]:
			var key := "stormwood_%s_%s" % [id, state]
			assert_true(conversations.has(key), "missing %s" % key)
			var entry: Dictionary = conversations.get(key, {})
			assert_eq(entry.get("state", ""), state)
			assert_true(entry.get("lines", []).size() >= 2)
			assert_true(entry.has("requires_flags"))

func test_dialogue_avoids_relic_names_and_keeps_flags_reported() -> void:
	var dialogue := _load("res://data/dialogue/stormwood.json")
	var text := JSON.stringify(dialogue.get("conversations", {})).to_lower()
	assert_false(text.contains("wings of cloudreach"))
	assert_false(text.contains("spark of the stormwood"))
	assert_true(dialogue.get("unbound_flags", []).size() >= 3)
