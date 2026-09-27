extends "res://tests/test_case.gd"

const CHARACTER_MODEL := preload("res://scripts/characters/character_model.gd")
const NPC_RANKS := preload("res://scripts/characters/npc_ranks.gd")
const MODEL_PATH := "res://assets/characters/craftsperson/craftsperson_lod0.glb"
const MODEL_SHA256 := "0bab2df02cd1df0a6a504430e1806f9eb2469df0ddc4707c2545854765e5f73d"
const CLEAN_ALBEDO := "res://assets/characters/craftsperson/craftsperson_cloth_clean.png"


func _build(cfg: Dictionary) -> Node3D:
	var model := Node3D.new()
	model.set_script(CHARACTER_MODEL)
	model.call("build_from_config", cfg)
	return model


func test_craftsperson_keeps_held_albedo_and_rejects_full_body_emission() -> void:
	var cfg := CHARACTER_MODEL.config_for("craftsperson")
	assert_eq(str(cfg.get("model", "")), MODEL_PATH)
	assert_almost_eq(float(cfg.get("height", 0.0)), 1.78)
	assert_eq(str(cfg.get("body_albedo_override", "")), CLEAN_ALBEDO)
	assert_true(cfg.has("body_emission_enabled") and not bool(cfg.body_emission_enabled))
	assert_eq(FileAccess.get_sha256(ProjectSettings.globalize_path(MODEL_PATH)), MODEL_SHA256,
		"the material correction must not rewrite the installed rig")
	var model := _build(cfg)
	var material := model.call("body_material") as BaseMaterial3D
	assert_true(material != null, "production craftsperson must build a body material")
	if material != null:
		assert_true(material.albedo_texture != null and material.albedo_texture.resource_path == CLEAN_ALBEDO,
			"the held garment derivative remains the production albedo")
		assert_false(material.emission_enabled,
			"the craftsperson must not emit its complete diffuse atlas at full strength")
	model.free()


func test_explicit_opt_out_keeps_absent_source_behavior_and_cache_isolated() -> void:
	var source_cfg := CHARACTER_MODEL.config_for("craftsperson").duplicate(true)
	source_cfg.erase("body_albedo_override")
	source_cfg.erase("body_emission_enabled")
	var source_model := _build(source_cfg)
	var source_material := source_model.call("body_material") as BaseMaterial3D
	assert_true(source_material != null and source_material.emission_enabled,
		"without the explicit opt-out, the imported craftsperson material remains emissive")
	source_model.free()

	var opted_model := _build(CHARACTER_MODEL.config_for("craftsperson"))
	var opted_material := opted_model.call("body_material") as BaseMaterial3D
	assert_false(opted_material.emission_enabled)
	assert_true(opted_material.emission_texture == null,
		"an explicit rejection removes the imported diffuse emission channel")
	assert_ne(opted_material, source_material, "opted and unopted bodies cannot share a cached material")
	var source_again := _build(source_cfg)
	var material_again := source_again.call("body_material") as BaseMaterial3D
	assert_true(material_again == source_material, "unchanged source configuration retains cache reuse")
	assert_true(material_again.emission_enabled and material_again.emission_texture != null,
		"building an opted-out material never mutates the cached source variant")
	source_again.free()
	opted_model.free()


func test_generated_face_representatives_remove_emission_without_repainting_albedo() -> void:
	for id: String in ["sera", "officer_a", "officer_b", "lost_traveler"]:
		var cfg := CHARACTER_MODEL.config_for(id)
		assert_true(cfg.has("body_emission_enabled") and not bool(cfg.body_emission_enabled), id)
		var source_cfg := cfg.duplicate(true)
		source_cfg.erase("body_emission_enabled")
		var source_model := _build(source_cfg)
		var source_material := source_model.call("body_material") as BaseMaterial3D
		var model := _build(cfg)
		var material := model.call("body_material") as BaseMaterial3D
		assert_true(source_material.emission_enabled and source_material.emission_texture != null,
			"control retains the real imported full-atlas emission for " + id)
		assert_false(material.emission_enabled, "the production body stops emitting its atlas: " + id)
		assert_true(material.emission_texture == null, "a later floor cannot revive that atlas: " + id)
		assert_true(material.albedo_texture == source_material.albedo_texture,
			"the original painted identity remains unchanged: " + id)
		assert_eq(material.albedo_color, source_material.albedo_color, "body tint remains unchanged: " + id)
		assert_ne(material, source_material, "source and opted cache entries remain distinct: " + id)
		model.free()
		source_model.free()


func test_ranked_opt_out_keeps_only_authored_floor_and_separates_floor_cache_entries() -> void:
	var base_cfg := CHARACTER_MODEL.config_for("officer_a")
	var base_model := _build(base_cfg)
	var base_material := base_model.call("body_material") as BaseMaterial3D
	var cfg := NPC_RANKS.config_for("captain", "officer_a")
	var floor := float(cfg.emission_floor)
	var tint := Color(str(cfg.palette.get("*", "#ffffff")))
	var ranked_model := _build(cfg)
	var material := ranked_model.call("body_material") as BaseMaterial3D
	assert_false(base_material.emission_enabled, "unranked opted body has no artificial floor")
	assert_ne(material, base_material, "same-model, same-tint ranked body cannot reuse the unranked material")
	assert_true(material.emission_enabled, "the explicit rank floor still enables emission")
	assert_true(material.emission_texture == null, "rank floor never restores the rejected diffuse atlas")
	assert_eq(material.emission_operator, BaseMaterial3D.EMISSION_OP_ADD)
	assert_eq(material.emission, tint * floor, "rank tint and authored floor strength are retained")
	assert_true(material.albedo_texture == base_material.albedo_texture)
	var repeated := _build(cfg)
	assert_true(repeated.call("body_material") == material, "identical ranked variants still share materials")
	var other_cfg := cfg.duplicate(true)
	other_cfg.emission_floor = floor * 0.5
	var other_model := _build(other_cfg)
	var other_material := other_model.call("body_material") as BaseMaterial3D
	assert_ne(other_material, material, "different authored floor strengths require distinct cache entries")
	assert_eq(other_material.emission, tint * (floor * 0.5))
	assert_eq(material.emission, tint * floor, "another floor variant does not mutate the first")
	assert_false(base_material.emission_enabled, "ranked construction never alters the unranked variant")
	other_model.free()
	repeated.free()
	ranked_model.free()
	base_model.free()
