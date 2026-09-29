extends "res://tests/test_case.gd"

const VARIANTS := preload("res://scripts/characters/appearance_variants.gd")
const CHARACTER := preload("res://scripts/characters/character_model.gd")
const PORTRAITS := preload("res://tools/_capture_portraits.gd")


func _settings() -> Dictionary:
	return {"enabled": true, "variants": {"fixture": {
		"expected_base_profile": "trader",
		"expected_model": "res://assets/characters/trader/trader_lod0.glb",
		"body_albedo_override": "res://tests/fixture_cloth.png",
		"body_emission_override": "res://tests/fixture_emission.png",
		"portrait": "res://assets/ui/portraits/fixture_appearance.png",
		"model": "res://unwanted_model.glb", "height": 99,
		"palette": {"*": "#ff0000"}, "accessories": []}}}


func test_default_disabled_and_empty_records_preserve_base() -> void:
	var config := VARIANTS.load_config()
	assert_false(bool(config.get("enabled", true)))
	assert_eq(config.get("variants"), {})
	var base := CHARACTER.config_for("trader")
	assert_eq(CHARACTER.config_for("trader", "fixture"), base)
	var settings := _settings()
	settings.enabled = false
	assert_eq(VARIANTS.resolve(base, "trader", "fixture", settings), base)
	assert_eq(VARIANTS.resolve(base, "trader", "missing", _settings()), base)


func test_matching_variant_preserves_rank_and_does_not_mutate_sources() -> void:
	var base := CHARACTER.config_for("trader")
	base.palette = {"*": "#ffffff"}
	base.accessories = [{"name": "rank_badge"}]
	var before := base.duplicate(true)
	var settings := _settings()
	var settings_before := settings.duplicate(true)
	var resolved := VARIANTS.resolve(base, "trader", "fixture", settings)
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
	var fallback := VARIANTS.resolve(base, "trader", "fixture", settings)
	fallback.accessories[0].name = "changed_disabled_copy"
	assert_eq(base, before)


func test_mismatches_and_incomplete_records_fail_without_partial_appearance() -> void:
	var base := CHARACTER.config_for("trader")
	assert_eq(VARIANTS.resolve(base, "courier", "fixture", _settings()), base)
	for field: String in ["expected_model", "portrait", "body_albedo_override"]:
		var settings := _settings()
		settings.variants.fixture[field] = ""
		assert_eq(VARIANTS.resolve(base, "trader", "fixture", settings), base, field)
	var escaped := _settings()
	escaped.variants.fixture.portrait = "res://assets/ui/portraits/../trader.png"
	assert_eq(VARIANTS.resolve(base, "trader", "fixture", escaped), base)
	var duplicate := _settings()
	duplicate.variants.other_identity = duplicate.variants.fixture.duplicate(true)
	assert_eq(VARIANTS.resolve(base, "trader", "fixture", duplicate), base)


func test_portrait_job_uses_exact_runtime_variant_and_refuses_disabled_variant() -> void:
	var settings := _settings()
	var runtime := CHARACTER.config_for("trader", "fixture", settings)
	var portrait := PORTRAITS.portrait_model_config(
		{"file": "unused_legacy_name", "config_key": "trader", "appearance_variant": "fixture"}, settings)
	assert_eq(portrait, runtime)
	assert_eq(portrait.portrait, settings.variants.fixture.portrait)
	settings.enabled = false
	assert_eq(PORTRAITS.portrait_model_config(
		{"config_key": "trader", "appearance_variant": "fixture"}, settings), {})
	assert_eq(PORTRAITS.portrait_model_config({"config_key": "trader"}, settings),
		CHARACTER.config_for("trader"))


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
