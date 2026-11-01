shader_type spatial;
// camfx.json `flame` (cameras-and-effects lane, 1 Nov): a camp fire flame drawn
// as a feathered, noise-licked teardrop on a Y-locked card, replacing the
// Bonfire's flat Fire cone. No texture and no particles, so it reads the same
// on Compatibility and Forward+. Colours stay orange/amber/pale gold (red is
// reserved for Team Tether).
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled, shadows_disabled, fog_disabled;

uniform vec4 core_colour : source_color = vec4(1.0, 0.94, 0.70, 1.0);
uniform vec4 mid_colour : source_color = vec4(1.0, 0.66, 0.20, 1.0);
uniform vec4 edge_colour : source_color = vec4(0.93, 0.40, 0.07, 1.0);
uniform float energy = 1.5;
uniform float alpha_scale = 1.0;
uniform float speed = 1.0;
uniform float seed = 0.0;
// Pushes the colour ramp toward the core (the inner card).
uniform float core_bias = 0.0;

void vertex() {
	// Face the camera around the world Y axis only, so the flame stays upright.
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(
		vec4(normalize(cross(vec3(0.0, 1.0, 0.0), INV_VIEW_MATRIX[2].xyz)), 0.0),
		vec4(0.0, 1.0, 0.0, 0.0),
		vec4(normalize(cross(INV_VIEW_MATRIX[0].xyz, vec3(0.0, 1.0, 0.0))), 0.0),
		MODEL_MATRIX[3]);
	MODELVIEW_MATRIX = MODELVIEW_MATRIX * mat4(
		vec4(length(MODEL_MATRIX[0].xyz), 0.0, 0.0, 0.0),
		vec4(0.0, length(MODEL_MATRIX[1].xyz), 0.0, 0.0),
		vec4(0.0, 0.0, length(MODEL_MATRIX[2].xyz), 0.0),
		vec4(0.0, 0.0, 0.0, 1.0));
	MODELVIEW_NORMAL_MATRIX = mat3(MODELVIEW_MATRIX);
}

float hash21(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float vnoise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash21(i), hash21(i + vec2(1.0, 0.0)), u.x),
		mix(hash21(i + vec2(0.0, 1.0)), hash21(i + vec2(1.0, 1.0)), u.x), u.y);
}

float fbm(vec2 p) {
	float v = 0.0;
	float a = 0.5;
	for (int k = 0; k < 4; k++) {
		v += a * vnoise(p);
		p = p * 2.03 + vec2(17.0, 9.0);
		a *= 0.5;
	}
	return v;
}

void fragment() {
	// h: 0 at the base, 1 at the tip. x: -1..1 across the card.
	float h = 1.0 - UV.y;
	float x = UV.x * 2.0 - 1.0;
	float t = TIME * speed + seed * 13.0;
	// Noise scrolls upward so licks climb the flame.
	vec2 q = vec2(UV.x * 2.6 + seed, h * 2.4 - t * 1.7);
	float n = fbm(q);
	float n2 = fbm(q * 1.8 + vec2(3.7, -t * 0.9));
	// Sway grows with height: the base sits on the logs, the tip dances.
	float xs = x + (n - 0.5) * 0.7 * h;
	// Teardrop: widest a quarter up, rounded base, pointed tip.
	float profile = sqrt(clamp(h * 4.0, 0.0, 1.0)) * pow(clamp(1.0 - h, 0.0, 1.0), 0.9);
	float width = 0.95 * profile;
	float field = width - abs(xs);
	// Licks: noise eats the upper flame into tongues.
	float density = field + (n2 - 0.5) * 0.55 * (0.25 + h);
	float alpha = smoothstep(0.0, 0.22, density);
	alpha *= smoothstep(0.0, 0.08, h);
	float heat = clamp(density * 2.2 * (1.15 - h * 0.7) + core_bias, 0.0, 1.0);
	vec3 colour = mix(edge_colour.rgb, mid_colour.rgb, smoothstep(0.05, 0.45, heat));
	colour = mix(colour, core_colour.rgb, smoothstep(0.55, 0.95, heat));
	// A quick flicker in brightness, not a strobe.
	float flicker = 0.9 + 0.1 * sin(t * 9.0 + n * 6.0);
	ALBEDO = colour * energy * flicker;
	ALPHA = clamp(alpha * alpha_scale, 0.0, 1.0);
}
