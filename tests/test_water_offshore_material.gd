extends "res://tests/test_case.gd"

const OFFSHORE := preload("res://scripts/world/water_offshore_material.gd")


func test_default_off_retains_the_exact_shared_material() -> void:
	var source := ShaderMaterial.new()
	source.shader = load("res://shaders/water.gdshader")
	assert_true(OFFSHORE.apply(source) == source)
	assert_true(OFFSHORE.apply(null) == null)


func test_candidate_copies_material_and_retains_depth_and_foam_inputs() -> void:
	var source := ShaderMaterial.new()
	source.shader = load("res://shaders/water.gdshader")
	var original := source.shader.code
	var height := GradientTexture2D.new()
	source.set_shader_parameter("terrain_height", height)
	source.set_shader_parameter("depth_falloff", 3.0)
	source.set_shader_parameter("alpha_deep", 1.0)
	source.set_shader_parameter("foam_depth", 0.4)
	var result := OFFSHORE.apply(source, {"enabled": true, "deep_colour": "#194856",
		"depth_start_m": 5.0, "depth_full_m": 32.0, "strength": 0.62})
	assert_true(result != source)
	assert_true(result.shader != source.shader)
	assert_eq(source.shader.code, original)
	assert_true(result.get_shader_parameter("terrain_height") == height)
	for key: String in ["depth_falloff", "alpha_deep", "foam_depth"]:
		assert_eq(result.get_shader_parameter(key), source.get_shader_parameter(key))
	assert_almost_eq(float(result.get_shader_parameter("offshore_start")), 5.0)
	assert_almost_eq(float(result.get_shader_parameter("offshore_full")), 32.0)
	assert_almost_eq(float(result.get_shader_parameter("offshore_strength")), 0.62)
