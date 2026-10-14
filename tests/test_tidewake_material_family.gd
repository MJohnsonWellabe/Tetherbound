extends "res://tests/test_case.gd"

const FAMILY := preload("res://scripts/world/tidewake_material_family.gd")
const PROFILE := preload("res://scripts/world/tidewake_look_profile.gd")


func test_disabled_family_returns_original_material() -> void:
	var source := StandardMaterial3D.new()
	assert_eq(FAMILY.standard(source, "stone", {"enabled": false}), source)
	assert_false(source.detail_enabled)


func test_detail_preserves_texture_alpha_and_base_normal_on_local_copy() -> void:
	var profile := PROFILE.settings()
	profile.enabled = true
	var source := StandardMaterial3D.new()
	source.albedo_color = Color("7b9279")
	source.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
	source.normal_enabled = true
	source.normal_texture = GradientTexture2D.new()
	source.albedo_texture = GradientTexture2D.new()
	var result := FAMILY.standard(source, "foliage", profile)
	assert_ne(result, source)
	assert_eq(result.albedo_texture, source.albedo_texture)
	assert_eq(result.normal_texture, source.normal_texture)
	assert_eq(result.albedo_color, source.albedo_color)
	assert_eq(result.transparency, source.transparency)
	assert_eq(result.detail_blend_mode, BaseMaterial3D.BLEND_MODE_MUL)
	assert_true(result.detail_enabled)
	assert_true(result.uv2_world_triplanar)
	assert_false(source.detail_enabled, "shared imported material is unchanged")


func test_lantern_emission_and_metals_keep_their_authored_response() -> void:
	var profile := PROFILE.settings()
	profile.enabled = true
	var source := StandardMaterial3D.new()
	source.emission_enabled = true
	assert_eq(FAMILY.standard(source, "timber", profile), source)
	source.emission_enabled = false
	source.metallic = 0.8
	assert_eq(FAMILY.standard(source, "stone", profile), source)
