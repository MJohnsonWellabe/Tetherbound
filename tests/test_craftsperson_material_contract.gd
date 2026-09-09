extends "res://tests/test_case.gd"

const CHARACTER_MODEL := preload("res://scripts/characters/character_model.gd")
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


func test_opt_out_is_craftsperson_only_and_absent_keeps_source_behavior() -> void:
	var source_cfg := CHARACTER_MODEL.config_for("craftsperson").duplicate(true)
	source_cfg.erase("body_albedo_override")
	source_cfg.erase("body_emission_enabled")
	var source_model := _build(source_cfg)
	var source_material := source_model.call("body_material") as BaseMaterial3D
	assert_true(source_material != null and source_material.emission_enabled,
		"without the explicit opt-out, the imported craftsperson material remains emissive")
	source_model.free()

	var control_cfg := CHARACTER_MODEL.config_for("trader")
	assert_false(control_cfg.has("body_emission_enabled"),
		"the neighbouring generated cast remains outside this correction")
	var control_model := _build(control_cfg)
	var control_material := control_model.call("body_material") as BaseMaterial3D
	assert_true(control_material != null and control_material.emission_enabled,
		"an absent key preserves the generated cast's current source emission behavior")
	control_model.free()
