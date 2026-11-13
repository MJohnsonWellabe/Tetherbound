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
	# Read from the source: a headless run has no renderer to ask for defaults.
	var source := FileAccess.get_file_as_string("res://shaders/human_water_contact.gdshader")
	assert_true(source.contains("uniform float soft_churn = 0.0;"), "the shader exposes soft_churn, off by default")
	assert_true(source.contains("mix(churn * broken_foam,"), "and at 0 the churn is the spoked one that ships")
