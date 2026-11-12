extends "res://tests/test_case.gd"

## F41#15 / F41#7 (LANE-BELOW6, 12 Nov 2026). GPU High G-below6-marrow: Captain
## Marrow's dialogue frames 4.55 -> 5.95 (+1.40), 3/3. Built through the real
## path, his body no longer emits its own texture or the Stormwood uniform
## floor, and wears the graded albedo. Other Stormwood uniforms keep their floor.

const CHARACTER_MODEL := preload("res://scripts/characters/character_model.gd")
const TRAINER_NPC := preload("res://scripts/world/trainer_npc.gd")
const PRESENTATION := preload("res://scripts/world/stormwood_character_presentation.gd")
const FLAGS_PATH := "res://data/config/character_body_flags.json"
const PRESENTATION_PATH := "res://data/config/stormwood_character_presentation.json"
const VERDICT := "G-below6-marrow.md"


func _marrow_config() -> Dictionary:
	var spec: Dictionary = PRESENTATION.decorate({"name": "Captain Marrow", "config_key": "captain_a",
		"role_id": "captain_marrow"}, "captain_marrow")
	return TRAINER_NPC.model_config(spec)


func test_both_flags_ship_on_and_cite_the_verdict() -> void:
	var flags: Variant = JSON.parse_string(FileAccess.get_file_as_string(FLAGS_PATH))
	var body: Dictionary = ((flags as Dictionary).get("flags", {}) as Dictionary).get("below6_marrow_self_lit_off", {})
	assert_true(bool(body.get("enabled", false)), "below6_marrow_self_lit_off ships ON (judged gain)")
	assert_true(str(body.get("_why_on", "")).contains(VERDICT), "it cites its GPU verdict")
	assert_true(str(body.get("_why_on", "")).contains("4.55 -> 5.95"), "and its judged score")
	var presentation: Variant = JSON.parse_string(FileAccess.get_file_as_string(PRESENTATION_PATH))
	var floor_block: Dictionary = (presentation as Dictionary).get("identity_floor_1112", {})
	assert_true(bool(floor_block.get("enabled", false)), "identity_floor_1112 ships ON (judged gain)")
	assert_true(str(floor_block.get("_why_on", "")).contains(VERDICT), "it cites its GPU verdict")


func test_marrow_is_built_without_self_emission_or_floor() -> void:
	var cfg := _marrow_config()
	assert_eq(float(cfg.get("emission_floor", -1.0)), 0.0, "Marrow's own emission floor is 0")
	assert_eq(cfg.get("body_emission_enabled", null), false, "the imported self-emission is rejected")
	assert_true(str(cfg.get("body_albedo_override", "")).ends_with("captain_a_lod0_texture_0_floor1.png"),
		"he wears the graded albedo")
	assert_true(ResourceLoader.exists(str(cfg.get("body_albedo_override", ""))), "the graded albedo exists")


func test_other_stormwood_uniforms_keep_their_floor() -> void:
	var nysa: Dictionary = PRESENTATION.decorate({"name": "Officer Nysa", "config_key": "officer_a",
		"role_id": "officer_nysa_deepwood_rod"}, "officer_nysa_deepwood_rod")
	assert_true(float(nysa.get("emission_floor", 0.0)) > 0.0, "an officer keeps the uniform floor")
