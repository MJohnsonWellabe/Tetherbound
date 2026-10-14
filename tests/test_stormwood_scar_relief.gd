extends "res://tests/test_case.gd"

const FIELD := preload("res://scripts/world/stormwood_glass_field.gd")


func test_scar_relief_stays_off_without_changing_existing_scars() -> void:
	var field := FIELD.new()
	field.config = JSON.parse_string(FileAccess.get_file_as_string(FIELD.CONFIG_PATH))
	assert_false(bool(field.config.scar_relief_candidate.enabled))
	assert_true(bool(field.config.scorched_scars), "existing scar presentation retained")
	var material: ShaderMaterial = field.call("_fused_material")
	assert_eq(float(material.get_shader_parameter("sw_normal_strength")), 0.0)
	assert_eq(float(material.get_shader_parameter("sw_detail_strength")), 0.0)
	assert_eq(float(material.get_shader_parameter("sw_roughness_scale")), 1.0)
	field.free()


func test_relief_uses_shared_detail_without_recolour_or_roughness_change() -> void:
	var field := FIELD.new()
	field.config = JSON.parse_string(FileAccess.get_file_as_string(FIELD.CONFIG_PATH))
	field.config.scar_relief_candidate.enabled = true
	var material: ShaderMaterial = field.call("_fused_material")
	assert_eq(material.shader, FIELD.SCAR_SHADER)
	assert_eq(float(material.get_shader_parameter("sw_normal_strength")), float(field.config.scar_relief_candidate.normal_strength))
	assert_eq(float(material.get_shader_parameter("sw_detail_frequency")), float(field.config.scar_relief_candidate.detail_frequency))
	assert_eq(float(material.get_shader_parameter("sw_detail_strength")), 0.0)
	assert_eq(float(material.get_shader_parameter("sw_roughness_scale")), 1.0)
	assert_eq(field.get_child_count(), 0, "material preparation adds no geometry or collision")
	field.free()
