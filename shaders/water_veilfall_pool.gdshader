shader_type spatial;
// falls.rebuild plunge pool (F39#31): a churned disc where a fall lands. UV is
// the disc position in -1..1; white churn at the centre, broken foam rings
// travelling outward, aerated pale water between them, a soft outer edge.
// Presentation only.
render_mode blend_mix, cull_disabled, depth_draw_never, diffuse_burley, specular_schlick_ggx, shadows_disabled;
uniform vec4 foam_colour : source_color = vec4(0.95, 0.98, 0.99, 1.0);
uniform vec4 aerated_colour : source_color = vec4(0.62, 0.80, 0.82, 1.0);
uniform float opacity = 0.92;
uniform float churn_radius = 0.38;
uniform float ring_count = 5.0;
uniform float ring_speed = 0.35;
uniform float ring_width = 0.22;
uniform float fade_start_m = 900.0;
uniform float fade_end_m = 2400.0;
varying float v_distance;

float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), u.x), mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), u.x), u.y);
}

void vertex() {
	v_distance = length((MODELVIEW_MATRIX * vec4(VERTEX, 1.0)).xyz);
}

void fragment() {
	float r = length(UV);
	float angle = atan(UV.y, UV.x) / 6.2832 + 0.5;
	// Wobble the radius so the rings are lobed, not compass circles.
	float wobble = (noise(vec2(angle * 9.0, TIME * 0.2)) - 0.5) * 0.12 + (noise(vec2(angle * 23.0, 3.1)) - 0.5) * 0.05;
	float rr = r + wobble;
	float phase = fract(rr * ring_count - TIME * ring_speed);
	float ring = smoothstep(0.0, ring_width * 0.5, phase) * (1.0 - smoothstep(ring_width * 0.5, ring_width, phase));
	// Break each ring into foam patches, thinning as it spreads.
	float patches = smoothstep(0.35, 0.75, noise(vec2(angle * 31.0, rr * 9.0 - TIME * 0.4)));
	ring *= patches * (1.0 - smoothstep(0.35, 1.0, rr));
	float churn = 1.0 - smoothstep(churn_radius * 0.55, churn_radius, rr + (noise(vec2(angle * 17.0, TIME * 1.3)) - 0.5) * 0.18);
	float foam = clamp(max(churn, ring), 0.0, 1.0);
	float edge = 1.0 - smoothstep(0.7, 1.0, rr);
	float far = 1.0 - smoothstep(fade_start_m, fade_end_m, v_distance);
	ALBEDO = mix(aerated_colour.rgb, foam_colour.rgb, foam);
	ROUGHNESS = 0.85;
	ALPHA = clamp(opacity * edge * far * mix(0.45, 1.0, foam), 0.0, 1.0);
}
