extends "res://tests/test_case.gd"

## F39#5 / F39#14 (LANE-BELOW6, 13 Nov 2026): `soft_churn_1112` is a declared,
## presentation-only switch for the swimmer's wake foam, and the shader keeps the
## spoked churn at its default.


func test_flag_is_declared_with_scope() -> void:
	var parsed: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/human_water_contact_visual.json"))
	var cfg: Dictionary = parsed.get("soft_churn_1112", {})
	assert_false(cfg.is_empty(), "soft_churn_1112 is declared")
	assert_true(str(cfg.get("scope", "")).begins_with("presentation"))
	assert_true(cfg.has("enabled"))


func test_shader_default_keeps_the_old_churn() -> void:
	var shader: Shader = load("res://shaders/human_water_contact.gdshader")
	var material := ShaderMaterial.new()
	material.shader = shader
	var found := false
	for uniform: Dictionary in shader.get_shader_uniform_list():
		if str(uniform.get("name", "")) == "soft_churn":
			found = true
	assert_true(found, "the shader exposes soft_churn")
	assert_eq(float(RenderingServer.shader_get_parameter_default(shader.get_rid(), "soft_churn")), 0.0, "and it defaults to off")
