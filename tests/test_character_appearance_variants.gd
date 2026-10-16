extends "res://tests/test_case.gd"

const VARIANTS := preload("res://scripts/characters/appearance_variants.gd")
const CHARACTER := preload("res://scripts/characters/character_model.gd")
const PORTRAITS := preload("res://tools/_capture_portraits.gd")


func _settings() -> Dictionary:
	return {"enabled": true, "variants": {"fixture": {
		"expected_base_profile": "trader",
		"expected_model": "res://assets/characters/trader/trader_lod0.glb",
		# Positive records obey the production loadability contract. These are
		# existing textures; this explicit setting never enables a staged candidate.
		"body_albedo_override": "res://assets/characters/trader/trader_lod0_texture_0.png",
		"body_emission_override": "res://assets/characters/trader/trader_lod0_texture_0.png",
		"portrait": "res://assets/ui/portraits/mira.png",
		"model": "res://unwanted_model.glb", "height": 99,
		"palette": {"*": "#ff0000"}, "accessories": []}}}


func test_only_accepted_adair_is_enabled_and_other_records_preserve_base() -> void:
	var config := VARIANTS.load_config()
	assert_eq(config.get("enabled"), true)
	var records: Dictionary = config.get("variants", {})
	var staged := ["p2055_water_adair", "p2055_water_iona", "p2055_water_orsen",
		"p2055_water_otto", "p2055_water_trainer_fen", "p2055_water_trainer_evi"]
	assert_eq(records.size(), staged.size() + 6)
	var model_candidate: Dictionary = records.get("npc_identity_water_adair_v1", {})
	assert_eq(model_candidate.get("enabled"), true)
	var accepted_id := "npc_identity_water_adair_v1"
	var adair := CHARACTER.config_for("field_researcher", accepted_id)
	var expected_adair := CHARACTER.config_for("field_researcher").duplicate(true)
	expected_adair.model = "res://assets/characters/npc_identity/water_adair/adair_lod0.glb"
	expected_adair.portrait = "res://assets/ui/portraits/npc_identity_water_adair_v1.png"
	expected_adair.appearance_variant_id = accepted_id
	expected_adair.erase("body_albedo_override")
	expected_adair.erase("body_emission_override")
	assert_eq(adair, expected_adair)
	assert_eq(PORTRAITS.portrait_model_config(
		{"config_key": "field_researcher", "appearance_variant": accepted_id}), adair)
	assert_eq(records.get("npc_identity_water_iona_v1", {}).get("enabled"), false)
	assert_eq(CHARACTER.config_for("field_researcher", "npc_identity_water_iona_v1"),
		CHARACTER.config_for("field_researcher"))
	assert_eq(records.get("npc_identity_water_orsen_v1", {}).get("enabled"), false)
	assert_eq(CHARACTER.config_for("wandering_trainer", "npc_identity_water_orsen_v1"),
		CHARACTER.config_for("wandering_trainer"))
	assert_eq(records.get("npc_identity_water_otto_v1", {}).get("enabled"), false)
	assert_eq(CHARACTER.config_for("wandering_trainer", "npc_identity_water_otto_v1"),
		CHARACTER.config_for("wandering_trainer"))
	# Iona v2 and Otto v2 (Otto v4 mesh) are later OFF identity candidates.
	assert_eq(records.get("npc_identity_water_iona_v2", {}).get("enabled"), false)
	assert_eq(CHARACTER.config_for("field_researcher", "npc_identity_water_iona_v2"),
		CHARACTER.config_for("field_researcher"))
	assert_eq(records.get("npc_identity_water_otto_v2", {}).get("enabled"), false)
	assert_eq(CHARACTER.config_for("wandering_trainer", "npc_identity_water_otto_v2"),
		CHARACTER.config_for("wandering_trainer"))
	for id: String in staged:
		assert_true(records.has(id), id)
		var record: Dictionary = records.get(id, {})
		assert_eq(record.get("enabled"), false, id)
		assert_eq(record.get("review_status"),
			"cloth_derivative_authored_pending_matching_portrait_and_production_visual_review", id)
		assert_eq(record.get("portrait"), "res://assets/ui/portraits/%s.png" % id, id)
		var provenance: Dictionary = record.get("authoring_provenance", {})
		assert_eq(provenance.get("producer"), "res://tools/repaint_regional_character_textures.py", id)
		assert_eq(provenance.get("source_model"), record.get("expected_model"), id)
		for field: String in ["source_model_sha256", "source_texture_sha256", "cloth_mask_sha256", "derivative_sha256"]:
			assert_eq(str(provenance.get(field, "")).length(), 64, id + ":" + field)
	var base := CHARACTER.config_for("trader")
	assert_eq(CHARACTER.config_for("trader", "fixture"), base)
	assert_eq(VARIANTS.resolve(base, "trader", "fixture", {"enabled": true, "variants": {}}), base)
	# Every staged candidate must remain a base-only fallback in shipping config.
	for id: String in staged:
		var profile := str(records[id].get("expected_base_profile", ""))
		assert_eq(CHARACTER.config_for(profile, id), CHARACTER.config_for(profile), id)
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
	assert_eq(resolved.get("appearance_variant_id"), "fixture")
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
	# The former imaginary positive paths now exercise missing-resource rejection
	# independently: every other member of each body/portrait pair is loadable.
	var missing := {"portrait": "res://assets/ui/portraits/fixture_appearance.png",
		"body_albedo_override": "res://tests/fixture_cloth.png",
		"body_emission_override": "res://tests/fixture_emission.png"}
	for field: String in missing:
		var settings := _settings()
		settings.variants.fixture[field] = missing[field]
		assert_eq(VARIANTS.resolve(base, "trader", "fixture", settings), base, "missing " + field)
	for field: String in ["body_albedo_override", "body_emission_override"]:
		var settings := _settings()
		settings.variants.fixture[field] = "res://scripts/characters/character_model.gd"
		assert_eq(VARIANTS.resolve(base, "trader", "fixture", settings), base, "non-texture " + field)
	var disabled_record := _settings()
	disabled_record.variants.fixture.enabled = false
	assert_eq(VARIANTS.resolve(base, "trader", "fixture", disabled_record), base)
	assert_eq(PORTRAITS.portrait_model_config(
		{"config_key": "trader", "appearance_variant": "fixture"}, disabled_record), {})


func test_portrait_job_uses_exact_runtime_variant_and_refuses_disabled_variant() -> void:
	var settings := _settings()
	var runtime := CHARACTER.config_for("trader", "fixture", settings)
	var portrait := PORTRAITS.portrait_model_config(
		{"file": "unused_legacy_name", "config_key": "trader", "appearance_variant": "fixture"}, settings)
	assert_eq(runtime.get("appearance_variant_id"), "fixture")
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
	assert_eq(portrait.get("appearance_variant_id"), "fixture")
	assert_eq(portrait.palette, base.palette)
	assert_eq(portrait.accessories, base.accessories)
	assert_eq(portrait.emission_floor, base.emission_floor)
	assert_eq(portrait, CHARACTER.with_appearance_variant(base, "officer_b", "fixture", settings))


func _model_settings() -> Dictionary:
	var record: Dictionary = VARIANTS.load_config().variants.npc_identity_water_adair_v1.duplicate(true)
	record.enabled = true
	# Test-only existing plate isolates resolver checks from the accepted plate.
	# The shipping test above binds Adair's actual model and portrait.
	record.portrait = "res://assets/ui/portraits/mira.png"
	return {"enabled": true, "variants": {"npc_identity_water_adair_v1": record}}


func test_model_pair_preserves_identity_dressing_and_clears_only_old_atlas_overrides() -> void:
	var base := CHARACTER.config_for("field_researcher")
	base.palette = {"*": "#ffffff"}
	base.accessories = [{"name": "rank_badge"}]
	base.body_albedo_override = "res://assets/characters/field_researcher/field_researcher_lod0_texture_0.png"
	base.body_emission_override = base.body_albedo_override
	var before := base.duplicate(true)
	var settings := _model_settings()
	var settings_before := settings.duplicate(true)
	var id := "npc_identity_water_adair_v1"
	var resolved := VARIANTS.resolve(base, "field_researcher", id, settings)
	assert_eq(resolved.get("appearance_variant_id"), id)
	assert_eq(resolved.model, settings.variants[id].body_model_override)
	assert_eq(resolved.portrait, settings.variants[id].portrait)
	for key: String in ["height", "clips", "animation_libraries", "palette", "accessories", "body_emission_enabled"]:
		assert_eq(resolved.get(key), base.get(key), key)
	assert_false(resolved.has("body_albedo_override"))
	assert_false(resolved.has("body_emission_override"))
	resolved.palette["*"] = "#000000"
	resolved.accessories[0].name = "changed_copy"
	assert_eq(base, before)
	assert_eq(settings, settings_before)
	# Both gates, original profile/model and complete pair remain mandatory.
	for field: String in ["expected_model", "portrait", "body_model_override"]:
		var invalid := _model_settings()
		invalid.variants[id][field] = ""
		assert_eq(VARIANTS.resolve(base, "field_researcher", id, invalid), base, field)
	for path: String in ["res://assets/characters/npc_identity/missing.glb",
			"res://scripts/characters/appearance_variants.gd",
			"res://assets/characters/npc_identity/../field_researcher/field_researcher_lod0.glb"]:
		var invalid := _model_settings()
		invalid.variants[id].body_model_override = path
		assert_eq(VARIANTS.resolve(base, "field_researcher", id, invalid), base, path)
	var mixed_atlas := _model_settings()
	mixed_atlas.variants[id].body_albedo_override = base.body_albedo_override
	assert_eq(VARIANTS.resolve(base, "field_researcher", id, mixed_atlas), base)
	assert_eq(VARIANTS.resolve(base, "wandering_trainer", id, _model_settings()), base)
	var disabled := _model_settings()
	disabled.variants[id].enabled = false
	assert_eq(VARIANTS.resolve(base, "field_researcher", id, disabled), base)
	disabled = _model_settings()
	disabled.enabled = false
	assert_eq(VARIANTS.resolve(base, "field_researcher", id, disabled), base)


func test_off_model_portrait_authoring_uses_runtime_body_and_checks_provenance() -> void:
	var id := "npc_identity_water_adair_v1"
	var spec := {"config_key": "field_researcher", "appearance_variant": id, "author_appearance": true}
	var settings := VARIANTS.load_config().duplicate(true)
	settings.enabled = false
	settings.variants[id].enabled = false
	var authored := PORTRAITS.authoring_portrait_model_config(spec, settings)
	assert_false(authored.is_empty())
	var runtime := VARIANTS.resolve(CHARACTER.config_for("field_researcher"), "field_researcher", id, _model_settings())
	# Only the test's stand-in plate differs; every model/dressing input matches.
	authored.erase("portrait")
	runtime.erase("portrait")
	assert_eq(authored, runtime)
	for field: String in ["source_model_sha256", "candidate_model_sha256", "reference_sha256", "producer_sha256"]:
		var invalid := settings.duplicate(true)
		invalid.variants[id].authoring_provenance[field] = "incorrect"
		assert_eq(PORTRAITS.authoring_portrait_model_config(spec, invalid), {}, field)
	var wrong_producer := settings.duplicate(true)
	wrong_producer.variants[id].authoring_provenance.producer = "res://tools/repaint_regional_character_textures.py"
	assert_eq(PORTRAITS.authoring_portrait_model_config(spec, wrong_producer), {})
	var duplicate := settings.duplicate(true)
	duplicate.variants.p2055_water_iona.portrait = duplicate.variants[id].portrait
	assert_eq(PORTRAITS.authoring_portrait_model_config(spec, duplicate), {})
	var wrong_destination := settings.duplicate(true)
	wrong_destination.variants[id].portrait = "res://assets/ui/portraits/maren.png"
	assert_eq(PORTRAITS.authoring_portrait_model_config(spec, wrong_destination), {})
	settings.enabled = true
	assert_eq(PORTRAITS.authoring_portrait_model_config(spec, settings), {})


func test_only_named_actors_are_bound_to_their_model_candidates() -> void:
	var cast: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/water_characters.json"))
	var bound: Array[String] = []
	var iona_bound: Array[String] = []
	var orsen_bound: Array[String] = []
	var otto_bound: Array[String] = []
	for actor: Dictionary in cast.npcs + cast.trainers:
		if str(actor.get("appearance_variant_id", "")) == "npc_identity_water_adair_v1":
			bound.append(str(actor.id))
		if str(actor.get("appearance_variant_id", "")) == "npc_identity_water_iona_v2":
			iona_bound.append(str(actor.id))
		if str(actor.get("appearance_variant_id", "")) == "npc_identity_water_orsen_v1":
			orsen_bound.append(str(actor.id))
		if str(actor.get("appearance_variant_id", "")) == "npc_identity_water_otto_v2":
			otto_bound.append(str(actor.id))
		if str(actor.id) == "water_otto":
			assert_eq(actor.body_profile, "wandering_trainer")
			assert_eq(actor.model, "res://assets/characters/wandering_trainer/wandering_trainer_lod0.glb")
			assert_eq(actor.portrait, "res://assets/ui/portraits/wandering_trainer.png")
		if str(actor.id) == "water_orsen":
			assert_eq(actor.body_profile, "wandering_trainer")
			assert_eq(actor.model, "res://assets/characters/wandering_trainer/wandering_trainer_lod0.glb")
			assert_eq(actor.portrait, "res://assets/ui/portraits/wandering_trainer.png")
		if str(actor.id) == "water_iona":
			assert_eq(actor.appearance_variant_id, "npc_identity_water_iona_v2")
			assert_eq(actor.body_profile, "field_researcher")
			assert_eq(actor.model, "res://assets/characters/field_researcher/field_researcher_lod0.glb")
			assert_eq(actor.portrait, "res://assets/ui/portraits/maren.png")
	assert_eq(bound, ["water_adair"])
	assert_eq(iona_bound, ["water_iona"])
	assert_eq(orsen_bound, ["water_orsen"])
	assert_eq(otto_bound, ["water_otto"])


func test_iona_authoring_is_exact_hash_bound_and_shipping_fallback_remains_installed() -> void:
	var id := "npc_identity_water_iona_v1"
	var shipping_settings := VARIANTS.load_config()
	var settings := shipping_settings.duplicate(true)
	# Authoring remains an explicit OFF-only fixture; shipping stays untouched.
	settings.enabled = false
	var spec := {"config_key": "field_researcher", "appearance_variant": id, "author_appearance": true}
	var authored := PORTRAITS.authoring_portrait_model_config(spec, settings)
	assert_false(authored.is_empty())
	assert_eq(authored.get("model"), "res://assets/characters/npc_identity/water_iona/iona_lod0.glb")
	assert_eq(authored.get("portrait"), "res://assets/ui/portraits/npc_identity_water_iona_v1.png")
	var base := CHARACTER.config_for("field_researcher")
	assert_eq(VARIANTS.resolve(base, "field_researcher", id, shipping_settings), base)
	var runtime_settings := settings.duplicate(true)
	runtime_settings.enabled = true
	runtime_settings.variants[id].enabled = true
	# A test-only stand-in verifies the complete runtime pair before production authoring.
	runtime_settings.variants[id].portrait = "res://assets/ui/portraits/mira.png"
	var runtime := VARIANTS.resolve(base, "field_researcher", id, runtime_settings)
	authored.erase("portrait")
	runtime.erase("portrait")
	assert_eq(authored, runtime)
	for field: String in ["source_model_sha256", "candidate_model_sha256", "reference_sha256",
			"producer_sha256", "reference_prompt_sha256_lf", "generation_task_id", "rig_task_id"]:
		var invalid := settings.duplicate(true)
		invalid.variants[id].authoring_provenance[field] = "incorrect"
		assert_eq(PORTRAITS.authoring_portrait_model_config(spec, invalid), {}, field)
	var cross_actor := settings.duplicate(true)
	cross_actor.variants[id].body_model_override = cross_actor.variants.npc_identity_water_adair_v1.body_model_override
	cross_actor.variants[id].authoring_provenance = cross_actor.variants.npc_identity_water_adair_v1.authoring_provenance.duplicate(true)
	assert_eq(PORTRAITS.authoring_portrait_model_config(spec, cross_actor), {})
	var wrong_destination := settings.duplicate(true)
	wrong_destination.variants[id].portrait = "res://assets/ui/portraits/maren.png"
	assert_eq(PORTRAITS.authoring_portrait_model_config(spec, wrong_destination), {})
	var wrong_profile := spec.duplicate(true)
	wrong_profile.config_key = "wandering_trainer"
	assert_eq(PORTRAITS.authoring_portrait_model_config(wrong_profile, settings), {})
	var enabled := settings.duplicate(true)
	enabled.variants[id].enabled = true
	assert_eq(PORTRAITS.authoring_portrait_model_config(spec, enabled), {})
	enabled = settings.duplicate(true)
	enabled.enabled = true
	assert_eq(PORTRAITS.authoring_portrait_model_config(spec, enabled), {})


func test_orsen_authoring_requires_wandering_trainer_and_exact_retarget_provenance() -> void:
	var id := "npc_identity_water_orsen_v1"
	var shipping_settings := VARIANTS.load_config()
	var settings := shipping_settings.duplicate(true)
	# Authoring remains an explicit OFF-only fixture; shipping stays untouched.
	settings.enabled = false
	var spec := {"config_key": "wandering_trainer", "appearance_variant": id, "author_appearance": true}
	var authored := PORTRAITS.authoring_portrait_model_config(spec, settings)
	assert_false(authored.is_empty())
	assert_eq(authored.get("model"), "res://assets/characters/npc_identity/water_orsen/orsen_lod0.glb")
	assert_eq(authored.get("portrait"), "res://assets/ui/portraits/npc_identity_water_orsen_v1.png")
	var base := CHARACTER.config_for("wandering_trainer")
	assert_eq(VARIANTS.resolve(base, "wandering_trainer", id, shipping_settings), base)
	var wrong_profile := spec.duplicate(true)
	wrong_profile.config_key = "field_researcher"
	assert_eq(PORTRAITS.authoring_portrait_model_config(wrong_profile, settings), {})
	for field: String in ["source_model_sha256", "candidate_model_sha256", "reference_sha256",
			"producer_sha256", "reference_prompt_sha256_lf", "generation_task_id", "rig_task_id",
			"reference", "reference_prompt", "producer"]:
		var invalid := settings.duplicate(true)
		invalid.variants[id].authoring_provenance[field] = "incorrect"
		assert_eq(PORTRAITS.authoring_portrait_model_config(spec, invalid), {}, field)
	for field: String in ["producer", "producer_sha256_lf", "recipe", "recipe_sha256",
			"input_model_sha256", "output_model_sha256"]:
		var invalid := settings.duplicate(true)
		invalid.variants[id].authoring_provenance.postprocessing[field] = "incorrect"
		assert_eq(PORTRAITS.authoring_portrait_model_config(spec, invalid), {}, field)
	var duplicate := settings.duplicate(true)
	duplicate.variants.p2055_water_orsen.portrait = duplicate.variants[id].portrait
	assert_eq(PORTRAITS.authoring_portrait_model_config(spec, duplicate), {})
	var protected_destination := settings.duplicate(true)
	# Body profiles have no portrait key; this installed plate is protected by PORTRAITS.
	protected_destination.variants[id].portrait = "res://assets/ui/portraits/wandering_trainer.png"
	assert_true(ResourceLoader.exists(protected_destination.variants[id].portrait))
	assert_eq(PORTRAITS.authoring_portrait_model_config(spec, protected_destination), {})
	var enabled := settings.duplicate(true)
	enabled.variants[id].enabled = true
	assert_eq(PORTRAITS.authoring_portrait_model_config(spec, enabled), {})
	enabled = settings.duplicate(true)
	enabled.enabled = true
	assert_eq(PORTRAITS.authoring_portrait_model_config(spec, enabled), {})


func test_otto_authoring_requires_wandering_trainer_and_exact_retarget_provenance() -> void:
	var id := "npc_identity_water_otto_v1"
	var shipping_settings := VARIANTS.load_config()
	var settings := shipping_settings.duplicate(true)
	# Authoring remains an explicit OFF-only fixture; shipping stays untouched.
	settings.enabled = false
	var spec := {"config_key": "wandering_trainer", "appearance_variant": id, "author_appearance": true}
	var authored := PORTRAITS.authoring_portrait_model_config(spec, settings)
	assert_false(authored.is_empty())
	assert_eq(authored.get("model"), "res://assets/characters/npc_identity/water_otto/otto_lod0.glb")
	assert_eq(authored.get("portrait"), "res://assets/ui/portraits/npc_identity_water_otto_v1.png")
	var base := CHARACTER.config_for("wandering_trainer")
	assert_eq(VARIANTS.resolve(base, "wandering_trainer", id, shipping_settings), base)
	var wrong_profile := spec.duplicate(true)
	wrong_profile.config_key = "field_researcher"
	assert_eq(PORTRAITS.authoring_portrait_model_config(wrong_profile, settings), {})
	for field: String in ["source_model_sha256", "candidate_model_sha256", "reference_sha256",
			"producer_sha256", "reference_prompt_sha256_lf", "generation_task_id", "rig_task_id",
			"reference", "reference_prompt", "producer"]:
		var invalid := settings.duplicate(true)
		invalid.variants[id].authoring_provenance[field] = "incorrect"
		assert_eq(PORTRAITS.authoring_portrait_model_config(spec, invalid), {}, field)
	for field: String in ["producer", "producer_sha256_lf", "recipe", "recipe_sha256",
			"input_model_sha256", "output_model_sha256"]:
		var invalid := settings.duplicate(true)
		invalid.variants[id].authoring_provenance.postprocessing[field] = "incorrect"
		assert_eq(PORTRAITS.authoring_portrait_model_config(spec, invalid), {}, field)
	var duplicate := settings.duplicate(true)
	duplicate.variants.p2055_water_otto.portrait = duplicate.variants[id].portrait
	assert_eq(PORTRAITS.authoring_portrait_model_config(spec, duplicate), {})
	var protected_destination := settings.duplicate(true)
	# Body profiles have no portrait key; this installed plate is protected by PORTRAITS.
	protected_destination.variants[id].portrait = "res://assets/ui/portraits/wandering_trainer.png"
	assert_true(ResourceLoader.exists(protected_destination.variants[id].portrait))
	assert_eq(PORTRAITS.authoring_portrait_model_config(spec, protected_destination), {})
	var enabled := settings.duplicate(true)
	enabled.variants[id].enabled = true
	assert_eq(PORTRAITS.authoring_portrait_model_config(spec, enabled), {})
	enabled = settings.duplicate(true)
	enabled.enabled = true
	assert_eq(PORTRAITS.authoring_portrait_model_config(spec, enabled), {})
