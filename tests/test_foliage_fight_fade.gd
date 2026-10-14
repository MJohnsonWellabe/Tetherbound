extends "res://tests/test_case.gd"
const FADE := preload("res://scripts/world/foliage_fight_fade.gd")


func test_standard_conversion_refuses_unimplemented_features() -> void:
	var source := StandardMaterial3D.new()
	assert_true(FADE.STANDARD.supported(source))
	source.emission_enabled = true
	assert_false(FADE.STANDARD.supported(source), "unknown active features must keep the original material")
	assert_eq(FADE.STANDARD.code(source), "")
	var mesh := BoxMesh.new()
	mesh.material = source
	var fade := FADE.new()
	var unchanged := fade.apply(mesh, "tree", "stormwood", {"enabled": true, "realms": ["stormwood"], "models": ["tree"]})
	assert_eq(unchanged.surface_get_material(0), source)
	assert_false(fade.has_materials())
	source.emission_enabled = false
	source.uv1_triplanar = true
	assert_false(FADE.STANDARD.supported(source))
	source.uv1_triplanar = false
	source.next_pass = StandardMaterial3D.new()
	assert_false(FADE.STANDARD.supported(source))
	assert_false(FADE.STANDARD.supported(ORMMaterial3D.new()))


func test_supported_foliage_conversion_retains_cutout_normal_and_near_fade() -> void:
	var source := StandardMaterial3D.new()
	source.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
	source.normal_enabled = true
	source.vertex_color_use_as_albedo = true
	source.distance_fade_mode = BaseMaterial3D.DISTANCE_FADE_PIXEL_DITHER
	source.distance_fade_min_distance = 3.0
	source.distance_fade_max_distance = 7.0
	var code := FADE.STANDARD.code(source)
	assert_false(code.is_empty())
	assert_true(code.contains("ALPHA_SCISSOR_THRESHOLD = alpha_scissor_threshold"))
	assert_true(code.contains("NORMAL_MAP = texture(texture_normal, UV).rgb"))
	assert_true(code.contains("NORMAL_MAP_DEPTH = normal_scale"))
	assert_true(code.contains("texel *= COLOR"))
	assert_true(code.contains("smoothstep(distance_fade_min, distance_fade_max, length(VERTEX))"))
	assert_false(FADE.inject(code).is_empty())


func test_gate_requires_both_realm_and_model() -> void:
	var cfg := {"enabled": true, "realms": ["stormwood"], "models": ["tree"]}
	assert_true(FADE.configured("stormwood", cfg), "arena target registration does not depend on loaded materials")
	assert_false(FADE.configured("meadows", cfg))
	assert_true(FADE.eligible("tree", "stormwood", cfg))
	assert_false(FADE.eligible("tree", "meadows", cfg))
	assert_false(FADE.eligible("rock", "stormwood", cfg))
	cfg.enabled = false
	assert_false(FADE.eligible("tree", "stormwood", cfg))


func test_shader_insertion_preserves_original_surface_code_and_rejects_unknown_layout() -> void:
	var original := "shader_type spatial;\nrender_mode cull_disabled;\nuniform sampler2D bark;\nvoid fragment() {\nNORMAL_MAP = texture(bark, UV).rgb;\nALPHA_SCISSOR_THRESHOLD = 0.2;\n}"
	var injected := FADE.inject(original)
	assert_true(injected.contains("NORMAL_MAP = texture(bark, UV).rgb;"))
	assert_true(injected.contains("ALPHA_SCISSOR_THRESHOLD = 0.2;"))
	assert_true(injected.contains("render_mode cull_disabled;"))
	assert_true(injected.find("render_mode cull_disabled;") < injected.find("uniform vec3 tb_fight_eye"))
	assert_eq(injected.count("void fragment()"), 1)
	assert_eq(FADE.inject(injected), "", "never wrap an already-wrapped source")
	assert_eq(FADE.inject("shader_type spatial;"), "")
	assert_eq(FADE.inject(original + "\nvoid fragment() {}"), "")
	assert_eq(FADE.inject(original.replace("spatial", "canvas_item")), "")


func test_arena_release_and_rebuild_do_not_leave_a_stale_fade() -> void:
	var fade := FADE.new()
	var material := ShaderMaterial.new()
	var shader := Shader.new()
	shader.code = FADE.inject("shader_type spatial;\nvoid fragment() { ALBEDO = vec3(1.0); }")
	material.shader = shader
	fade._materials.append(material)
	fade.target(1, Vector3(0, 0, 10))
	fade.target(2, Vector3(0, 0, 20))
	fade.update(Vector3.ZERO, 0.2)
	assert_eq(material.get_shader_parameter("tb_fight_target"), Vector3(0, 0, 10))
	assert_eq(material.get_shader_parameter("tb_fight_strength"), 1.0)
	fade.target(1, Vector3.INF)
	fade.update(Vector3.ZERO, 0.2)
	assert_eq(material.get_shader_parameter("tb_fight_target"), Vector3(0, 0, 20))
	assert_eq(material.get_shader_parameter("tb_fight_strength"), 1.0, "closing one fight must retain the other")
	fade.target(2, Vector3.INF)
	assert_eq(material.get_shader_parameter("tb_fight_strength"), 0.0)
	fade.target(3, Vector3(0, 0, 15))
	fade.update(Vector3.ZERO, 0.2)
	assert_eq(material.get_shader_parameter("tb_fight_strength"), 1.0)
	fade.clear()
	assert_eq(material.get_shader_parameter("tb_fight_strength"), 0.0, "retained old material is reset before rebuild")
	assert_false(fade.has_materials())
	assert_true(fade._owners.is_empty(), "a rebuilt scatter does not inherit earlier arena identities")

func test_target_registered_before_material_arrival_is_retained() -> void:
	var fade := FADE.new()
	fade.target(9, Vector3(0, 0, 10))
	fade.update(Vector3.ZERO, 0.2)
	assert_false(fade.has_materials())
	var material := ShaderMaterial.new()
	var shader := Shader.new()
	shader.code = FADE.inject("shader_type spatial; void fragment() { ALBEDO = vec3(1.0); }")
	material.shader = shader
	fade._materials.append(material)
	fade.update(Vector3.ZERO, 0.2)
	assert_eq(material.get_shader_parameter("tb_fight_target"), Vector3(0, 0, 10))
	assert_eq(material.get_shader_parameter("tb_fight_strength"), 1.0)
