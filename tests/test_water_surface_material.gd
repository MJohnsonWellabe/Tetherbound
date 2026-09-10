extends "res://tests/test_case.gd"

const WATER_SURFACE := preload("res://scripts/world/water_surface.gd")
const WORLD_CONFIG_PATH := "res://data/config/water_world.json"
const VISUAL_CONFIG_PATH := "res://data/config/water_visual.json"


func _load_json(path: String) -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	assert_true(parsed is Dictionary, "%s must parse" % path)
	return parsed as Dictionary


func test_production_surface_binds_mature_fresnel_contract() -> void:
	var config := _load_json(WORLD_CONFIG_PATH)
	var visual := _load_json(VISUAL_CONFIG_PATH)
	var surface := WATER_SURFACE.new()
	surface.build(config, visual)
	var material := surface.material_override as ShaderMaterial
	assert_true(material != null, "WaterSurface build must bind a ShaderMaterial")
	var water: Dictionary = visual.water
	assert_eq(material.get_shader_parameter("fresnel_colour"), Color(str(water.fresnel_colour)))
	assert_almost_eq(float(material.get_shader_parameter("fresnel_power")), float(water.fresnel_power))
	assert_almost_eq(float(material.get_shader_parameter("fresnel_strength")), float(water.fresnel_strength))
	assert_almost_eq(float(material.get_shader_parameter("wave_uv_scale")), float(water.wave_uv_scale))
	assert_almost_eq(float(material.get_shader_parameter("roughness_value")), float(water.roughness), 0.0001,
		"Authored roughness maps to the shader's roughness_value uniform")
	surface.free()


func test_material_only_candidate_preserves_water_shape_contract() -> void:
	var visual := _load_json(VISUAL_CONFIG_PATH)
	var water: Dictionary = visual.water
	assert_almost_eq(float(water.depth_falloff), 3.0)
	assert_almost_eq(float(water.alpha_deep), 0.9)
	assert_almost_eq(float(water.alpha_shallow), 0.45)
	assert_almost_eq(float(water.foam_depth), 0.4)
	assert_almost_eq(float(water.wave_strength), 0.25)
