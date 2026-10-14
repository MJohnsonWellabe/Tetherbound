extends RefCounted

## Godot 4.7 does not bind Material.get_shader_rid() to scripts. This bounded
## StandardMaterial converter uses public properties and the engine's uniform
## names. Shader semantics audited against 4.7-stable scene/resources/material.cpp:
## https://github.com/godotengine/godot/blob/4.7-stable/scene/resources/material.cpp
## Refuse every non-default storage property we do not explicitly implement.
## This is not a general replacement for the editor's native converter.
const SUPPORTED := [
	"resource_name", "resource_path", "resource_scene_unique_id", "resource_local_to_scene", "render_priority",
	"albedo_color", "albedo_texture", "metallic", "metallic_specular",
	"metallic_texture", "metallic_texture_channel", "roughness", "roughness_texture", "roughness_texture_channel",
	"normal_enabled", "normal_scale", "normal_texture", "uv1_scale", "uv1_offset",
	"vertex_color_use_as_albedo", "vertex_color_is_srgb", "texture_filter", "texture_repeat",
	"cull_mode", "shading_mode", "transparency", "alpha_scissor_threshold",
	"distance_fade_mode", "distance_fade_min_distance", "distance_fade_max_distance",
]
const FILTERS := ["filter_nearest", "filter_linear", "filter_nearest_mipmap", "filter_linear_mipmap",
	"filter_nearest_mipmap_anisotropic", "filter_linear_mipmap_anisotropic"]
const CHANNELS := ["vec4(1.0,0.0,0.0,0.0)", "vec4(0.0,1.0,0.0,0.0)",
	"vec4(0.0,0.0,1.0,0.0)", "vec4(0.0,0.0,0.0,1.0)", "vec4(0.333333,0.333333,0.333333,0.0)"]
static var _defaults: StandardMaterial3D


static func supported(source: BaseMaterial3D) -> bool:
	if not source is StandardMaterial3D or source.next_pass != null or source.get_script() != null:
		return false
	if source.shading_mode not in [BaseMaterial3D.SHADING_MODE_PER_PIXEL, BaseMaterial3D.SHADING_MODE_UNSHADED] \
		or source.transparency not in [BaseMaterial3D.TRANSPARENCY_DISABLED, BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR] \
		or source.distance_fade_mode not in [BaseMaterial3D.DISTANCE_FADE_DISABLED, BaseMaterial3D.DISTANCE_FADE_PIXEL_DITHER]:
		return false
	if _defaults == null: _defaults = StandardMaterial3D.new()
	for property: Dictionary in source.get_property_list():
		var key := str(property.name)
		if (int(property.usage) & PROPERTY_USAGE_STORAGE) == 0 or key in SUPPORTED or key.begins_with("metadata/"):
			continue
		if source.get(key) != _defaults.get(key):
			return false
	return true


static func code(source: BaseMaterial3D) -> String:
	if not supported(source): return ""
	var filtering: String = FILTERS[int(source.texture_filter)] + (", repeat_enable" if source.texture_repeat else ", repeat_disable")
	var culling: String = ["cull_back", "cull_front", "cull_disabled"][int(source.cull_mode)]
	var result := "shader_type spatial;\nrender_mode blend_mix, depth_draw_opaque, diffuse_burley, specular_schlick_ggx, " + culling
	if source.shading_mode == BaseMaterial3D.SHADING_MODE_UNSHADED: result += ", unshaded"
	result += ";\n"
	result += "uniform vec4 albedo : source_color;\nuniform sampler2D texture_albedo : source_color, " + filtering + ";\n"
	result += "uniform sampler2D texture_metallic : hint_default_white, " + filtering + ";\n"
	result += "uniform sampler2D texture_roughness : hint_roughness_" + ["r", "g", "b", "a", "gray"][int(source.roughness_texture_channel)] + ", " + filtering + ";\n"
	result += "uniform float metallic;\nuniform float specular;\nuniform float roughness;\nuniform vec4 metallic_texture_channel;\n"
	result += "uniform vec3 uv1_scale;\nuniform vec3 uv1_offset;\n"
	if source.normal_enabled:
		result += "uniform sampler2D texture_normal : hint_roughness_normal, " + filtering + ";\nuniform float normal_scale;\n"
	if source.transparency == BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR:
		result += "uniform float alpha_scissor_threshold;\n"
	if source.distance_fade_mode == BaseMaterial3D.DISTANCE_FADE_PIXEL_DITHER:
		result += "uniform float distance_fade_min;\nuniform float distance_fade_max;\n"
	result += "void vertex() {\nUV = UV * uv1_scale.xy + uv1_offset.xy;\n"
	if source.vertex_color_is_srgb:
		result += "if (!OUTPUT_IS_SRGB) { COLOR.rgb = mix(pow((COLOR.rgb + vec3(0.055)) / 1.055, vec3(2.4)), COLOR.rgb / 12.92, lessThan(COLOR.rgb, vec3(0.04045))); }\n"
	result += "}\nvoid fragment() {\nvec4 texel = texture(texture_albedo, UV);\n"
	if source.vertex_color_use_as_albedo: result += "texel *= COLOR;\n"
	result += "ALBEDO = albedo.rgb * texel.rgb;\nMETALLIC = metallic * dot(texture(texture_metallic, UV), metallic_texture_channel);\nSPECULAR = specular;\n"
	result += "ROUGHNESS = roughness * dot(texture(texture_roughness, UV), " + CHANNELS[int(source.roughness_texture_channel)] + ");\n"
	if source.normal_enabled:
		result += "NORMAL_MAP = texture(texture_normal, UV).rgb;\nNORMAL_MAP_DEPTH = normal_scale;\n"
	if source.transparency == BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR:
		result += "ALPHA = albedo.a * texel.a;\nALPHA_SCISSOR_THRESHOLD = alpha_scissor_threshold;\n"
	if source.distance_fade_mode == BaseMaterial3D.DISTANCE_FADE_PIXEL_DITHER:
		result += "float near_fade = clamp(smoothstep(distance_fade_min, distance_fade_max, length(VERTEX)), 0.0, 1.0);\n"
		result += "float noise = fract(52.9829189 * fract(dot(FRAGCOORD.xy, vec2(0.06711056, 0.00583715))));\nif (near_fade < 0.001 || near_fade < noise) { discard; }\n"
	return result + "}\n"
