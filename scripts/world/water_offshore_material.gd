extends RefCounted

## Water-only shader copy. Disabled installation returns the exact original
## material; Meadows ponds and streams keep their shared shader unchanged.
const CONFIG := "res://data/config/water_offshore_visual.json"
const COLOUR_ANCHOR := "vec3 colour = mix(deep_colour.rgb, shallow_colour.rgb, shallowness);"
const FRESNEL_ANCHOR := "colour = mix(colour, fresnel_colour.rgb, fresnel);"
const FOAM_FIRST_ANCHOR := "float n1 = texture(foam_noise, uv * foam_scale"
const FOAM_SECOND_ANCHOR := "float n2 = texture(foam_noise, uv * foam_scale"
const FOAM_COLOUR_ANCHOR := "colour = mix(colour, foam_colour.rgb, foam);"
const SHORE_UNIFORMS := """
uniform float shore_foam_breakup_m = 4.0;
uniform float shore_foam_breakup_scale = 0.025;
uniform float shore_foam_strength = 0.68;
uniform float shore_foam_patch_start = 0.35;
uniform float shore_foam_patch_full = 0.65;
"""
const SHORE_BREAKUP := """
	// Deform only the foam's noise coordinates. Physical depth, waterline,
	// wave normals and traversal/current fields keep their original inputs.
	vec2 shore_warp = vec2(texture(foam_noise, uv * shore_foam_breakup_scale).r,
		texture(foam_noise, uv * shore_foam_breakup_scale + vec2(0.31, 0.73)).r);
	vec2 shore_foam_uv = uv + (shore_warp * 2.0 - vec2(1.0)) * shore_foam_breakup_m;
"""
const UNIFORMS := """
uniform vec3 offshore_colour : source_color = vec3(0.10, 0.28, 0.34);
uniform float offshore_start = 5.0;
uniform float offshore_full = 32.0;
uniform float offshore_strength = 0.62;
uniform float offshore_variation_scale = 0.0035;
uniform float offshore_variation_strength = 0.08;
uniform float offshore_fresnel_multiplier = 0.52;
"""
const COLOUR := """
	// The near-shore ramp stays intact. Deep water gains a broad, low-contrast
	// value field rather than one saturated cyan fill across every crossing.
	float offshore = smoothstep(offshore_start, offshore_full, depth);
	float offshore_noise = texture(foam_noise, uv * offshore_variation_scale).r;
	vec3 offshore_tone = offshore_colour * (1.0 + (offshore_noise - 0.5) * offshore_variation_strength);
	colour = mix(colour, offshore_tone, offshore * offshore_strength);
"""


static func apply(source: ShaderMaterial, supplied: Dictionary = {}) -> ShaderMaterial:
	var settings := supplied
	if settings.is_empty():
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(CONFIG))
		settings = parsed if parsed is Dictionary else {}
	if not bool(settings.get("enabled", false)) or source == null or source.shader == null:
		return source
	var code := source.shader.code
	if not code.contains(COLOUR_ANCHOR) or not code.contains(FRESNEL_ANCHOR) \
			or not code.contains("void fragment() {"):
		push_error("Water offshore candidate: installed water shader anchors unavailable")
		return source
	var shader := Shader.new()
	shader.code = code.replace("void fragment() {", UNIFORMS + "\nvoid fragment() {") \
		.replace(COLOUR_ANCHOR, COLOUR_ANCHOR + "\n" + COLOUR) \
		.replace(FRESNEL_ANCHOR, "fresnel *= mix(1.0, offshore_fresnel_multiplier, offshore);\n\t" + FRESNEL_ANCHOR)
	var shore_enabled := bool(settings.get("shore_foam_enabled", false))
	var shore_breakup := float(settings.get("shore_foam_breakup_m", 4.0))
	var shore_scale := float(settings.get("shore_foam_breakup_scale", 0.025))
	var shore_strength := float(settings.get("shore_foam_strength", 0.68))
	var patch_start := float(settings.get("shore_foam_patch_start", 0.35))
	var patch_full := float(settings.get("shore_foam_patch_full", 0.65))
	if shore_enabled and (not is_finite(shore_breakup) or not is_finite(shore_scale) or not is_finite(shore_strength) \
			or not is_finite(patch_start) or not is_finite(patch_full) or patch_start < 0.0 or patch_full > 1.0 or patch_start >= patch_full):
		push_error("Water shore foam candidate: finite presentation settings required")
		shore_enabled = false
	if shore_enabled:
		if not code.contains(FOAM_FIRST_ANCHOR) or not code.contains(FOAM_SECOND_ANCHOR) or not code.contains(FOAM_COLOUR_ANCHOR):
			push_error("Water shore foam candidate: installed foam shader anchors unavailable")
			shore_enabled = false
		else:
			shader.code = shader.code.replace("void fragment() {", SHORE_UNIFORMS + "\nvoid fragment() {") \
				.replace(FOAM_FIRST_ANCHOR, SHORE_BREAKUP + "\n\tfloat n1 = texture(foam_noise, shore_foam_uv * foam_scale") \
				.replace(FOAM_SECOND_ANCHOR, "float n2 = texture(foam_noise, shore_foam_uv * foam_scale") \
				.replace(FOAM_COLOUR_ANCHOR, "float shore_patch = smoothstep(shore_foam_patch_start, shore_foam_patch_full, dot(shore_warp, vec2(0.65, 0.35)));\n\tfoam *= shore_foam_strength * shore_patch;\n\t" + FOAM_COLOUR_ANCHOR)
	var result := source.duplicate() as ShaderMaterial
	result.shader = shader
	result.set_shader_parameter("offshore_colour", Color(str(settings.get("deep_colour", "#194856"))))
	result.set_shader_parameter("offshore_start", float(settings.get("depth_start_m", 5.0)))
	result.set_shader_parameter("offshore_full", float(settings.get("depth_full_m", 32.0)))
	for key: String in ["strength", "variation_scale", "variation_strength", "fresnel_multiplier"]:
		if settings.has(key):
			result.set_shader_parameter("offshore_" + key, float(settings[key]))
	if shore_enabled:
		result.set_shader_parameter("shore_foam_breakup_m", maxf(0.0, shore_breakup))
		result.set_shader_parameter("shore_foam_breakup_scale", maxf(0.0001, shore_scale))
		result.set_shader_parameter("shore_foam_strength", clampf(shore_strength, 0.15, 1.0))
		result.set_shader_parameter("shore_foam_patch_start", patch_start)
		result.set_shader_parameter("shore_foam_patch_full", patch_full)
	return result
