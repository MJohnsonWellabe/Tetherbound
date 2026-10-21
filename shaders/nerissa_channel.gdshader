shader_type spatial;
render_mode blend_mix, cull_disabled, depth_draw_never, unshaded;

// Captain Nerissa's side-channel sweep (BOSSES §4.11), presentation only.
// UV.x crosses the lane (inner_u marks the edge toward the ring centre, the
// way out), UV.y runs along it. Announce: shimmering water with chevrons
// streaming toward the safe edge and a bright safe-edge line that quickens as
// the tell runs out. Active: a raised, foaming surge rolling down the lane.
// Drain: the water sinks and fades.
uniform vec4 water_colour : source_color = vec4(0.50, 0.84, 1.0, 1.0);
uniform vec4 foam_colour : source_color = vec4(0.91, 0.98, 1.0, 1.0);
uniform float alpha = 0.35;
uniform float foam = 0.0;
uniform float progress = 0.0;
uniform float inner_u = 1.0;
uniform float chevrons = 1.0;
uniform float surge_height_m = 0.0;
uniform float lane_length_m = 24.0;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), f.x),
		mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0)), f.x), f.y);
}

void vertex() {
	float across = abs(UV.x - inner_u);
	float body = smoothstep(0.0, 0.25, across) * smoothstep(0.0, 0.12, 1.0 - across);
	float roll = 0.55 + 0.45 * sin(UV.y * lane_length_m * 1.047 - TIME * 10.0);
	VERTEX.y += surge_height_m * body * roll;
}

void fragment() {
	// 0 at the safe (inner) edge, 1 at the wall side.
	float across = abs(UV.x - inner_u);
	float along = UV.y * lane_length_m;
	vec2 flowing = vec2(across * 6.0, along * 0.35 - TIME * (0.6 + foam * 2.4));
	float broad = noise(flowing);
	float fine = noise(flowing * vec2(2.3, 1.8) + vec2(3.1, -TIME * 0.5));
	float streak = smoothstep(0.55, 0.88, fine * 0.6 + broad * 0.4);
	// Chevrons point to the safe edge and stream toward it.
	float speed = 0.8 + progress * 1.6;
	float chev = fract((across * 6.0 + abs(fract(along / 3.0) - 0.5) * 2.2) + TIME * speed);
	float chev_band = smoothstep(0.0, 0.08, chev) * (1.0 - smoothstep(0.22, 0.32, chev));
	chev_band *= chevrons * smoothstep(0.08, 0.2, across);
	// The safe edge: a bright line that pulses faster as the tell runs out.
	float pulse = 0.6 + 0.4 * sin(TIME * (5.0 + progress * 10.0));
	float edge_line = (1.0 - smoothstep(0.0, 0.05, across)) * chevrons * pulse;
	float outer_fade = smoothstep(0.0, 0.08, 1.0 - across);
	float end_fade = smoothstep(0.0, 0.06, UV.y) * smoothstep(0.0, 0.06, 1.0 - UV.y);
	// Active: rolling wave crests travel down the lane with foam on their
	// fronts; the water between them stays blue and see-through.
	float crest_phase = fract(UV.y * lane_length_m / 6.0 - TIME * 1.6);
	float crest = foam * smoothstep(0.78, 0.95, crest_phase) * (1.0 - smoothstep(0.95, 1.0, crest_phase));
	float whiten = clamp(streak * (0.3 + foam * 0.35) + chev_band * 0.7 + edge_line + crest * 0.85, 0.0, 1.0);
	vec3 deep = water_colour.rgb * mix(0.75, 1.1, broad);
	ALBEDO = mix(deep, foam_colour.rgb, whiten);
	float a = alpha * (0.7 + 0.3 * broad) + chev_band * 0.35 * alpha + edge_line * 0.6 + crest * 0.3;
	ALPHA = clamp(a, 0.0, 0.95) * outer_fade * end_fade;
}
