extends "res://tests/test_case.gd"

# F05 heal before-state (coordinator ruling; SHARED-FILE GRANT on
# scripts/world/grass_field.gd + shaders/grass_field.gdshader): the grass-field
# drain hook must be ADDITIVE and OFF BY DEFAULT. These pin that the shader's
# drain uniforms default to nothing, that `drain_at()` returns 0 before it reads
# a disc when there are no discs or no amount, and that the two places it
# touches (the cull test and the colour) are identities at 0 -- so a field with
# drain_amount 0 draws exactly what it drew before the hook. The rendered
# identity (the same frame, pixel for pixel, with and without the hook fed at
# amount 0) is evidence in ralph/reports/MEADOWS-FINALE/heal/.

const GRASS := preload("res://scripts/world/grass_field.gd")
const SHADER_PATH := "res://shaders/grass_field.gdshader"


func _source() -> String:
	return FileAccess.get_file_as_string(SHADER_PATH)


func test_drain_uniforms_default_to_off() -> void:
	var src := _source()
	assert_true(src.contains("uniform int drain_count = 0;"), "no discs by default")
	assert_true(src.contains("uniform float drain_amount = 0.0;"), "no drain by default")


func test_drain_at_returns_zero_before_reading_any_disc_when_off() -> void:
	var src := _source()
	var at := src.find("float drain_at(vec2 world_xz)")
	assert_true(at >= 0, "drain_at exists")
	var body := src.substr(at, 260)
	var guard := body.find("if (drain_count <= 0 || drain_amount <= 0.0001) {")
	var early := body.find("return 0.0;")
	var loop := body.find("for (int i = 0; i < drain_count; i++)")
	assert_true(guard >= 0 and early > guard and loop > early, "the off case returns 0 before the disc loop")


func test_the_two_touch_points_are_identities_at_zero() -> void:
	var src := _source()
	# Cull: a hash in [0, 1) is never < 0.
	assert_true(src.contains("|| hash12(world_xz * 3.97) < v_drain * drain_thin;"), "cull term scales with v_drain")
	# Colour: mix(col, x, 0) == col; backlight: mix(tint_tip, x, 0) == tint_tip.
	assert_true(src.contains("col = mix(col, drain_tint * mix(0.75, 1.1, v_blade_t), v_drain);"), "colour lerps by v_drain")
	assert_true(src.contains("BACKLIGHT = mix(tint_tip, drain_tint, v_drain) * translucency * v_blade_t;"), "backlight lerps by v_drain")
	assert_eq(src.count("v_drain ="), 1, "v_drain is only ever drain_at()'s value")


func test_set_drain_pushes_the_nearest_discs_deterministically() -> void:
	var field: MultiMeshInstance3D = GRASS.new()
	var material := ShaderMaterial.new()
	material.shader = load(SHADER_PATH)
	field.set("_material", material)
	var discs: Array = []
	for i in 40:
		discs.append({"centre": Vector2(float(i) * 10.0, 0.0), "radius": 6.0, "inner": 2.0, "strength": 0.5})
	field.call("set_drain", discs, 0.0)
	assert_eq(int(material.get_shader_parameter("drain_count")), 32, "at most 32 discs pushed")
	assert_almost_eq(float(material.get_shader_parameter("drain_amount")), 0.0)
	var pushed: PackedVector3Array = material.get_shader_parameter("drain_disc")
	assert_almost_eq(pushed[0].x, 0.0, 0.0001, "nearest first from the origin")
	var again := ShaderMaterial.new()
	again.shader = material.shader
	field.set("_material", again)
	field.call("set_drain", discs, 0.0)
	assert_eq(again.get_shader_parameter("drain_disc"), pushed, "same discs, same order, every time")
	field.call("set_drain_amount", 3.0)
	assert_almost_eq(float(field.call("drain_amount")), 1.0, 0.0001, "amount clamps to 1")
	field.free()


func test_a_field_never_fed_has_no_drain() -> void:
	var field: MultiMeshInstance3D = GRASS.new()
	assert_almost_eq(float(field.call("drain_amount")), 0.0, 0.0001)
	field.free()
