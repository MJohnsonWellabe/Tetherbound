shader_type spatial;
render_mode blend_mix, depth_draw_never, cull_disabled, unshaded;

uniform vec4 mist_colour : source_color = vec4(0.64, 0.78, 0.83, 1.0);
uniform float opacity = 0.53;
varying float phase;

void vertex() {
	phase = VERTEX.x * 2.71;
	VERTEX.x += sin(TIME * 0.68 + phase) * 0.07;
	VERTEX.y += sin(TIME * 0.92 + phase) * 0.045;
}
void fragment() {
	vec2 p = (UV - vec2(0.5)) * 2.0;
	float edge = 1.0 - smoothstep(0.10, 1.0, dot(p, p));
	float rolling = sin(UV.x * 17.0 + TIME * 0.86 + phase) * sin(UV.y * 11.0 - TIME * 0.62);
	ALBEDO = mist_colour.rgb;
	ROUGHNESS = 1.0;
	ALPHA = opacity * edge * (0.65 + rolling * 0.35);
}
