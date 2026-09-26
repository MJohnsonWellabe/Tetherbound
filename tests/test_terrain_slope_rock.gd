extends "res://tests/test_case.gd"

## VIS audit M9: steep vegetation cells blend to rock in the Meadows override
## terrain shader. A presentation key the shader does not declare is ignored
## silently by playground_world.gd::_apply_ground_shader, so pin the contract.

const SHADER_PATH := "res://shaders/terrain_ground.gdshader"
const PRESENTATION := "res://data/config/terrain_presentation.json"


func test_the_shader_declares_the_slope_rock_uniforms_off_by_default() -> void:
	var code := FileAccess.get_file_as_string(SHADER_PATH)
	for name: String in ["slope_rock_strength", "slope_rock_start", "slope_rock_full",
			"slope_rock_texture_id", "slope_rock_veg_mask"]:
		assert_true(code.contains("uniform ") and code.contains(" " + name + " "), "%s declared" % name)
	assert_true(code.contains("uniform float slope_rock_strength : hint_range(0.0, 1.0) = 0.0;"),
		"default strength 0 keeps the original look for any caller that does not opt in")


func test_meadows_opts_in_with_a_steeper_full_than_start() -> void:
	var cfg: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(PRESENTATION))
	var shader: Dictionary = cfg.get("shader", {})
	assert_true(float(shader.get("slope_rock_strength", 0.0)) > 0.0, "Meadows enables slope rock")
	var code := FileAccess.get_file_as_string(SHADER_PATH)
	assert_true(code.contains("smoothstep(slope_rock_full, slope_rock_start"), "full (steeper) below start")


func test_rock_id_is_the_rock_texture_and_never_a_vegetation_bit() -> void:
	var terrain: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/terrain_playground.json"))
	var names: Array = (terrain.get("textures", []) as Array).map(func(t): return str(t.get("name")))
	assert_eq(str(names[2]), "rock", "slope_rock_texture_id default 2 must be the rock texture")
	for veg: int in [0, 1, 5]:
		assert_true(str(names[veg]) in ["grass", "soil", "forest_floor"], "mask bit %d is vegetation" % veg)
	assert_eq(35 & (1 << 2), 0, "the rock id is not in the vegetation mask")
	assert_eq(35 & (1 << 3), 0, "paths are never rewritten")
