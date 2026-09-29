extends RefCounted

## Water-only shader copy. Disabled installation returns the exact original
## material; Meadows ponds and streams keep their shared shader unchanged.
const CONFIG := "res://data/config/water_offshore_visual.json"
const COLOUR_ANCHOR := "vec3 colour = mix(deep_colour.rgb, shallow_colour.rgb, shallowness);"
const FRESNEL_ANCHOR := "colour = mix(colour, fresnel_colour.rgb, fresnel);"
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
	var result := source.duplicate() as ShaderMaterial
	result.shader = shader
	result.set_shader_parameter("offshore_colour", Color(str(settings.get("deep_colour", "#194856"))))
	result.set_shader_parameter("offshore_start", float(settings.get("depth_start_m", 5.0)))
	result.set_shader_parameter("offshore_full", float(settings.get("depth_full_m", 32.0)))
	for key: String in ["strength", "variation_scale", "variation_strength", "fresnel_multiplier"]:
		if settings.has(key):
			result.set_shader_parameter("offshore_" + key, float(settings[key]))
	return result
