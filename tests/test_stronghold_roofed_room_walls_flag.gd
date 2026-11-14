extends "res://tests/test_case.gd"

## F38#28 candidate: less moss on the inside faces of roofed chamber walls.
## OFF until a GPU verdict; the shader term is a no-op at its defaults.


func test_flag_is_off() -> void:
	var cfg: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/stronghold.json"))
	var block: Dictionary = cfg["site"]["weathering"]["roofed_room_walls_1113"]
	assert_false(bool(block.get("enabled", true)))
	assert_between(float(block.get("moss_mul", -1.0)), 0.0, 1.0)


func test_shader_term_is_off_by_default() -> void:
	var shader: Shader = load("res://assets/environment/team_tether/hall/hall_stone.gdshader")
	var material := ShaderMaterial.new()
	material.shader = shader
	var source := shader.code
	assert_true(source.contains("uniform vec3 room_half = vec3(0.0);"), "no room footprint unless one is set")
	assert_true(source.contains("uniform float room_moss_mul : hint_range(0.0, 1.0) = 1.0;"), "moss unchanged unless scaled")
	assert_true(source.contains("step(0.001, room_half.x)"), "a zero footprint switches the term off")
