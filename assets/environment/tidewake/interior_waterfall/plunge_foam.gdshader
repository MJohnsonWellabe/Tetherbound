shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_disabled, diffuse_burley;

uniform vec4 foam_colour : source_color = vec4(0.78, 0.88, 0.90, 1.0);
uniform float opacity = 0.86;
uniform float motion = 0.08;

void vertex() {
	VERTEX.y += sin(TIME * 6.0 + VERTEX.x * 9.0 + UV.y * 8.0) * motion * sin(UV.y * 3.141593);
	VERTEX.y = max(VERTEX.y, -5.97);
}
void fragment() {
	float travel = UV.y * 21.0 - TIME * 4.0;
	float ripple = sin(travel + sin(UV.x * 41.0) * 2.0) * 0.5 + 0.5;
	float cut = smoothstep(0.12, 0.62, ripple);
	float edges = smoothstep(0.0, 0.12, UV.x) * smoothstep(0.0, 0.12, 1.0 - UV.x);
	ALBEDO = foam_colour.rgb * (0.78 + 0.22 * ripple);
	EMISSION = foam_colour.rgb * 0.10;
	ROUGHNESS = 0.7;
	ALPHA = edges * opacity * (0.32 + cut * 0.68) * smoothstep(0.0, 0.12, 1.0 - UV.y);
}
