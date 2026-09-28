shader_type spatial;
render_mode cull_disabled;
// Recolour only the installed civilian awning/banner fabric. Preserve the
// source weave, shading and normal detail without retaining Team Tether red.
uniform sampler2D source_albedo : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D source_normal : hint_normal, filter_linear_mipmap, repeat_enable;
uniform vec4 cloth_colour : source_color = vec4(0.34, 0.61, 0.68, 1.0);
void fragment() {
	vec3 source = texture(source_albedo, UV).rgb;
	float value = clamp(dot(source, vec3(0.2126, 0.7152, 0.0722)) * 2.1, 0.06, 1.0);
	ALBEDO = cloth_colour.rgb * value;
	NORMAL_MAP = texture(source_normal, UV).rgb;
	ROUGHNESS = 0.93;
	METALLIC = 0.0;
}
