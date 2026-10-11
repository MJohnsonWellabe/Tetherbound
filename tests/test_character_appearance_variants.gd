extends "res://tests/test_case.gd"

const VARIANTS := preload("res://scripts/characters/appearance_variants.gd")
const CHARACTER := preload("res://scripts/characters/character_model.gd")
const PORTRAITS := preload("res://tools/_capture_portraits.gd")


func _settings() -> Dictionary:
	return {"enabled": true, "variants": {"fixture": {
		"expected_base_profile": "field_researcher",
		"expected_model": "res://assets/characters/field_researcher/field_researcher_lod0.glb",
		"body_albedo_override": "res://assets/characters/field_researcher/field_researcher_lod0_texture_0.png",
		"body_emission_override": "res://assets/characters/field_researcher/field_researcher_lod0_texture_0.png",
		"portrait": "res://assets/ui/portraits/maren.png",
		"model": "res://unwanted_model.glb", "height": 99,
		"palette": {"*": "#ff0000"}, "accessories": []}}}


func test_default_disabled_and_staged_records_preserve_base() -> void:
	var config := VARIANTS.load_config()
	assert_false(bool(config.get("enabled", true)))
	var records: Dictionary = config.get("variants", {})
	var ids := ["p2055_water_adair", "p2055_water_iona", "p2055_water_orsen", "p2055_water_otto",
		"p2055_water_trainer_fen", "p2055_water_trainer_evi"]
	assert_eq(records.size(), ids.size())
	for id: String in ids:
		assert_true(records.has(id))
		var record: Dictionary = records.get(id, {})
		assert_false(bool(record.get("enabled", true)))
		var profile := str(record.get("expected_base_profile", ""))
		var original := CHARACTER.config_for(profile)
		assert_false(original.is_empty())
		assert_eq(VARIANTS.resolve(original, profile, id, config), original)
		var global_on := config.duplicate(true)
		global_on.enabled = true
		assert_eq(VARIANTS.resolve(original, profile, id, global_on), original)
	var base := CHARACTER.config_for("field_researcher")
	assert_eq(CHARACTER.config_for("field_researcher", "fixture"), base)
	var settings := _settings()
	settings.enabled = false
	assert_eq(VARIANTS.resolve(base, "field_researcher", "fixture", settings), base)
	assert_eq(VARIANTS.resolve(base, "field_researcher", "missing", _settings()), base)


func test_matching_variant_preserves_rank_and_does_not_mutate_sources() -> void:
	var base := CHARACTER.config_for("field_researcher")
	base.palette = {"*": "#ffffff"}
	base.accessories = [{"name": "rank_badge"}]
	var before := base.duplicate(true)
	var settings := _settings()
	var settings_before := settings.duplicate(true)
	var resolved := VARIANTS.resolve(base, "field_researcher", "fixture", settings)
	assert_eq(resolved.model, base.model)
	assert_eq(resolved.height, base.height)
	assert_eq(resolved.palette, base.palette)
	assert_eq(resolved.accessories, base.accessories)
	assert_eq(resolved.body_albedo_override, settings.variants.fixture.body_albedo_override)
	assert_eq(resolved.body_emission_override, settings.variants.fixture.body_emission_override)
	assert_eq(resolved.portrait, settings.variants.fixture.portrait)
	resolved.palette["*"] = "#000000"
	resolved.accessories[0].name = "changed"
	assert_eq(base, before)
	assert_eq(settings, settings_before)
	settings.enabled = false
	var fallback := VARIANTS.resolve(base, "field_researcher", "fixture", settings)
	fallback.accessories[0].name = "changed_disabled_copy"
	assert_eq(base, before)


func test_mismatches_and_incomplete_records_fail_without_partial_appearance() -> void:
	var base := CHARACTER.config_for("field_researcher")
	assert_eq(VARIANTS.resolve(base, "courier", "fixture", _settings()), base)
	for field: String in ["expected_model", "portrait", "body_albedo_override"]:
		var settings := _settings()
		settings.variants.fixture[field] = ""
		assert_eq(VARIANTS.resolve(base, "field_researcher", "fixture", settings), base, field)
	for field: String in ["body_albedo_override", "body_emission_override", "portrait"]:
		var missing := _settings()
		missing.variants.fixture[field] = "res://assets/ui/portraits/absent_appearance_fixture.png"
		assert_eq(VARIANTS.resolve(base, "field_researcher", "fixture", missing), base, field + " missing asset")
		var wrong_type := _settings()
		wrong_type.variants.fixture[field] = 42
		assert_eq(VARIANTS.resolve(base, "field_researcher", "fixture", wrong_type), base, field + " wrong type")
	var non_texture := _settings()
	non_texture.variants.fixture.body_albedo_override = "res://data/config/character_appearance_variants.json"
	assert_eq(VARIANTS.resolve(base, "field_researcher", "fixture", non_texture), base)
	var escaped := _settings()
	escaped.variants.fixture.portrait = "res://assets/ui/portraits/../trader.png"
	assert_eq(VARIANTS.resolve(base, "field_researcher", "fixture", escaped), base)
	var duplicate := _settings()
	duplicate.variants.other_identity = duplicate.variants.fixture.duplicate(true)
	assert_eq(VARIANTS.resolve(base, "field_researcher", "fixture", duplicate), base)


func test_portrait_job_uses_exact_runtime_variant_and_refuses_disabled_variant() -> void:
	var settings := _settings()
	var runtime := CHARACTER.config_for("field_researcher", "fixture", settings)
	var portrait := PORTRAITS.portrait_model_config(
		{"file": "unused_legacy_name", "config_key": "field_researcher", "appearance_variant": "fixture"}, settings)
	assert_eq(portrait, runtime)
	assert_eq(portrait.portrait, settings.variants.fixture.portrait)
	settings.enabled = false
	assert_eq(PORTRAITS.portrait_model_config(
		{"config_key": "field_researcher", "appearance_variant": "fixture"}, settings), {})
	assert_eq(PORTRAITS.portrait_model_config({"config_key": "field_researcher"}, settings),
		CHARACTER.config_for("field_researcher"))


func test_ranked_portrait_keeps_the_existing_rank_palette_and_badges() -> void:
	var spec := {"rank": "officer", "base": "officer_b"}
	var base := PORTRAITS.portrait_model_config(spec)
	var settings := _settings()
	settings.variants.fixture.expected_base_profile = "officer_b"
	settings.variants.fixture.expected_model = base.model
	spec.appearance_variant = "fixture"
	var portrait := PORTRAITS.portrait_model_config(spec, settings)
	assert_eq(portrait.palette, base.palette)
	assert_eq(portrait.accessories, base.accessories)
	assert_eq(portrait.emission_floor, base.emission_floor)
	assert_eq(portrait, CHARACTER.with_appearance_variant(base, "officer_b", "fixture", settings))
