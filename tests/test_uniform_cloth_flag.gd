extends "res://tests/test_case.gd"

## F41#18: mid-value uniform cloth from a mesh-built garment mask, with a
## matching lower floor. Landed ON together (13 Nov 2026,
## G-below6-uniform-cloth-c673.md: row 5.95 -> 6.02 2/3, dialogue +0.18 3/3,
## officers +0.18 3/3).

const MODEL := preload("res://scripts/characters/character_model.gd")


func _cfg(path: String) -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string(path))


func test_cloth_ships_on_with_its_verdict_and_textures() -> void:
	var entry: Dictionary = (_cfg("res://data/config/character_body_flags.json").flags as Dictionary).get("below6_uniform_cloth", {})
	assert_true(bool(entry.get("enabled", false)), "the cloth ships ON")
	var why := str(entry.get("_why_on", ""))
	assert_true(why.contains("G-below6-uniform-cloth-c673") and why.contains("5.95") and why.contains("6.02"),
		"it cites its verdict and scores")
	var characters: Dictionary = entry.get("characters", {})
	assert_eq(characters.keys().size(), 3)
	for key: String in characters:
		var path := str((characters[key] as Dictionary).get("body_albedo_override", ""))
		assert_true(path.ends_with("_cloth2.png") and ResourceLoader.exists(path), "%s texture exists" % key)
		for field: String in characters[key]:
			assert_true(field in MODEL.BODY_FLAG_KEYS, "%s is a body-surface key" % field)


func test_matching_floor_ships_on_with_the_cloth() -> void:
	var cfg := _cfg("res://data/config/stormwood_character_presentation.json")
	var block: Dictionary = cfg.get("uniform_cloth_floor_1113", {})
	assert_true(bool(block.get("enabled", false)), "the lower floor ships ON with the cloth")
	assert_true(str(block.get("_why_on", "")).contains("G-below6-uniform-cloth-c673"), "it cites the same verdict")
	assert_true(float(block.get("emission_floor", 1.0)) < float((cfg.uniform as Dictionary).emission_floor))
