shader_type spatial;
render_mode diffuse_burley, specular_disabled;

uniform sampler2D stone_colour : source_color, filter_linear_mipmap_anisotropic;
uniform vec4 distance_colour : source_color = vec4(0.54, 0.63, 0.70, 1.0);
uniform float aerial_blend : hint_range(0.0, 1.0) = 0.0;

void fragment() {
	ALBEDO = mix(texture(stone_colour, UV).rgb, distance_colour.rgb, aerial_blend);
	ROUGHNESS = 0.94;
}
