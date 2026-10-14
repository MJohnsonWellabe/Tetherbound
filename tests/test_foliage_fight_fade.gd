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


func test_stormwood_detail_contract_is_supported_without_erasing_other_features() -> void:
	var source := StandardMaterial3D.new()
	source.normal_enabled = true
	source.normal_scale = 0.7
	source.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
	source.distance_fade_mode = BaseMaterial3D.DISTANCE_FADE_PIXEL_DITHER
	source.detail_enabled = true
	source.detail_blend_mode = BaseMaterial3D.BLEND_MODE_MUL
	source.detail_uv_layer = BaseMaterial3D.DETAIL_UV_2
	source.uv2_triplanar = true
	source.uv2_world_triplanar = true
	source.uv2_scale = Vector3.ONE * 0.65
	assert_true(FADE.STANDARD.supported(source))
	var code := FADE.STANDARD.code(source)
	for required in ["texture_detail_albedo", "texture_detail_normal", "texture_detail_mask", "uv2_blend_sharpness", "MODEL_MATRIX", "NORMAL_MAP_DEPTH = normal_scale", "ALPHA_SCISSOR_THRESHOLD", "distance_fade_min"]:
		assert_true(code.contains(required), "missing combined material feature: " + required)
	source.emission_enabled = true
	assert_eq(FADE.STANDARD.code(source), "", "detail support must not permit unimplemented emission")
	source.emission_enabled = false
	source.detail_blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	assert_eq(FADE.STANDARD.code(source), "", "only the reviewed multiply detail mode is supported")
	source.detail_blend_mode = BaseMaterial3D.BLEND_MODE_MUL
	source.uv2_world_triplanar = false
	assert_eq(FADE.STANDARD.code(source), "")
	source.uv2_world_triplanar = true
	source.detail_uv_layer = BaseMaterial3D.DETAIL_UV_1
	assert_eq(FADE.STANDARD.code(source), "")


func test_gate_requires_both_realm_and_model() -> void:
	var cfg := {"enabled": true, "realms": ["stormwood"], "models": ["tree"]}
	assert_true(FADE.configured("stormwood", cfg), "arena target registration does not depend on loaded materials")
	assert_false(FADE.configured("meadows", cfg))
	assert_true(FADE.eligible("tree", "stormwood", cfg))
	assert_false(FADE.eligible("tree", "meadows", cfg))
	assert_false(FADE.eligible("rock", "stormwood", cfg))
	cfg.enabled = false
	assert_false(FADE.eligible("tree", "stormwood", cfg))


func test_production_retint_features_preserve_stock_shader_contract() -> void:
	var source := StandardMaterial3D.new()
	source.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
	source.roughness = 0.94
	var code := FADE.STANDARD.code(source)
	assert_true(code.contains("specular_disabled"))
	assert_false(code.contains("specular_schlick_ggx"))
	source.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
	source.alpha_antialiasing_mode = BaseMaterial3D.ALPHA_ANTIALIASING_ALPHA_TO_COVERAGE_AND_TO_ONE
	source.alpha_antialiasing_edge = 0.27
	source.backlight_enabled = true
	source.backlight = Color(0.28, 0.28, 0.28, 1.0)
	source.distance_fade_mode = BaseMaterial3D.DISTANCE_FADE_PIXEL_DITHER
	source.normal_enabled = true
	for with_detail in [false, true]:
		source.detail_enabled = with_detail
		if with_detail:
			source.detail_blend_mode = BaseMaterial3D.BLEND_MODE_MUL
			source.detail_uv_layer = BaseMaterial3D.DETAIL_UV_2
			source.uv2_triplanar = true
			source.uv2_world_triplanar = true
		code = FADE.STANDARD.code(source)
		assert_false(code.is_empty(), "production retint must compose with normal/near fade and optional look")
		for required in ["specular_disabled", "alpha_to_coverage_and_one", "uniform float alpha_antialiasing_edge", "uniform ivec2 albedo_texture_size", "ALPHA_TEXTURE_COORDINATE = UV * vec2(albedo_texture_size)", "ALPHA_ANTIALIASING_EDGE = alpha_antialiasing_edge", "ALPHA_SCISSOR_THRESHOLD = alpha_scissor_threshold", "BACKLIGHT = backlight.rgb + texture(texture_backlight, UV).rgb", "hint_default_black", "NORMAL_MAP_DEPTH = normal_scale", "distance_fade_min"]:
			assert_true(code.contains(required), "missing stock retint feature: " + required)
		assert_false(FADE.inject(code).is_empty())
	assert_eq(source.specular_mode, BaseMaterial3D.SPECULAR_DISABLED)
	assert_eq(source.alpha_antialiasing_edge, 0.27)
	assert_eq(source.backlight, Color(0.28, 0.28, 0.28, 1.0))


func test_retint_extension_keeps_unreviewed_modes_and_textured_backlight_original() -> void:
	var source := StandardMaterial3D.new()
	source.specular_mode = BaseMaterial3D.SPECULAR_TOON
	assert_eq(FADE.STANDARD.code(source), "")
	source.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
	source.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
	source.alpha_antialiasing_mode = BaseMaterial3D.ALPHA_ANTIALIASING_ALPHA_TO_COVERAGE
	assert_eq(FADE.STANDARD.code(source), "")
	source.alpha_antialiasing_mode = BaseMaterial3D.ALPHA_ANTIALIASING_ALPHA_TO_COVERAGE_AND_TO_ONE
	source.transparency = BaseMaterial3D.TRANSPARENCY_DISABLED
	assert_eq(FADE.STANDARD.code(source), "")
	source.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
	source.backlight_enabled = true
	source.backlight_texture = GradientTexture2D.new()
	assert_eq(FADE.STANDARD.code(source), "")
	var mesh := BoxMesh.new()
	mesh.material = source
	var fade := FADE.new()
	var guarded := fade.apply(mesh, "tree", "stormwood", {"enabled": true, "realms": ["stormwood"], "models": ["tree"]})
	assert_eq(guarded.surface_get_material(0), source, "do not silently drop unsupported transmission texture")
	assert_false(fade.has_materials())


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
