extends "res://tests/test_case.gd"

## Frame-matrix M1, frame 29: the arena paving's radial joints were unbounded,
## so the joint at -90 deg ran down the SummitArenaApproach's centre line
## (x = arena origin x) as a seam through the cobble courtyard.

const SHADER_PATH := "res://shaders/cloudreach_arena_paving.gdshader"
const PRESENTATION_PATH := "res://scripts/world/cloudreach_summit_presentation.gd"


func test_radial_joints_stop_at_the_arena_deck() -> void:
	var shader := load(SHADER_PATH) as Shader
	assert_true(shader != null)
	var has_uniform := false
	for uniform: Dictionary in shader.get_shader_uniform_list():
		if str(uniform.get("name", "")) == "joint_outer_radius":
			has_uniform = true
	assert_true(has_uniform, "paving shader exposes the joint radius bound")
	var source := FileAccess.get_file_as_string(SHADER_PATH)
	assert_true(source.contains("joint*=1.0-smoothstep(joint_outer_radius-1.0,joint_outer_radius,r)"),
		"joints are masked outside the round deck")
	var presentation := FileAccess.get_file_as_string(PRESENTATION_PATH)
	assert_true(presentation.contains(
		"set_shader_parameter(\"joint_outer_radius\",float(config.arena_radius_m)+0.5)"),
		"the bound follows the authored arena radius")

