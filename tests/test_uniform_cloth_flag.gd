extends "res://tests/test_case.gd"

## F41#18 candidate: mid-value uniform cloth from a mesh-built garment mask,
## with a matching lower floor. Both OFF until a GPU verdict.

const MODEL := preload("res://scripts/characters/character_model.gd")


func test_cloth_flag_is_off_and_its_textures_exist() -> void:
	var doc: Dictionary = JSON.parse_string(
			FileAccess.get_file_as_string("res://data/config/character_body_flags.json"))
	var entry: Dictionary = (doc.flags as Dictionary).get("below6_uniform_cloth", {})
	assert_false(bool(entry.get("enabled", true)))
	var characters: Dictionary = entry.get("characters", {})
	assert_eq(characters.keys().size(), 3)
	for key: String in characters:
		var path := str((characters[key] as Dictionary).get("body_albedo_override", ""))
		assert_true(path.ends_with("_cloth2.png") and ResourceLoader.exists(path), "%s texture exists" % key)
		for field: String in characters[key]:
			assert_true(field in MODEL.BODY_FLAG_KEYS, "%s is a body-surface key" % field)


func test_matching_floor_is_off() -> void:
	var cfg: Dictionary = JSON.parse_string(
			FileAccess.get_file_as_string("res://data/config/stormwood_character_presentation.json"))
	var block: Dictionary = cfg.get("uniform_cloth_floor_1113", {})
	assert_false(bool(block.get("enabled", true)))
	assert_true(float(block.get("emission_floor", 1.0)) < float((cfg.uniform as Dictionary).emission_floor))
