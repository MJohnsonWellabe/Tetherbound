shader_type spatial;
// Ashfoot m51: a woven storm-blue rug in place of the flat beige box. Warp and
// weft bands, a darker border, and fibre noise; matte. UV spans the rug.
render_mode cull_back;

uniform vec4 base_colour : source_color = vec4(0.22, 0.27, 0.36, 1.0);
uniform vec4 band_colour : source_color = vec4(0.62, 0.52, 0.34, 1.0);
uniform vec4 border_colour : source_color = vec4(0.13, 0.15, 0.2, 1.0);
uniform vec2 size_m = vec2(1.0, 1.4);
uniform float bands = 5.0;

float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }

void fragment() {
	vec2 m = UV * size_m;
	float border = step(min(min(m.x, size_m.x - m.x), min(m.y, size_m.y - m.y)), 0.09);
	float band = smoothstep(0.42, 0.5, abs(fract(UV.y * bands) - 0.5));
	float weave = 0.5 + 0.5 * sin(m.x * 220.0) * sin(m.y * 220.0);
	float fibre = hash(floor(m * 160.0));
	vec3 colour = mix(base_colour.rgb, band_colour.rgb, band * 0.85);
	colour = mix(colour, border_colour.rgb, border);
	colour *= 0.82 + 0.12 * weave + 0.1 * fibre;
	ALBEDO = colour;
	ROUGHNESS = 0.95;
}
