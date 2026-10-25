shader_type spatial;
// Stormheart hero interior: the soft sheath around the lightning core column.
// Additive and unshaded, brightest at the silhouette, with slow vertical
// filaments drifting up. Presentation only; no flashing (a slow 0.5 m/s
// drift and a 25 % filament depth).
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, shadows_disabled, fog_disabled;

uniform vec4 glow_colour : source_color = vec4(0.66, 0.86, 1.0, 1.0);
uniform float energy = 1.2;
uniform float drift_m_per_s = 0.5;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), u.x),
		mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), u.x), u.y);
}

varying float height_m;

void vertex() {
	height_m = VERTEX.y;
}

void fragment() {
	float facing = abs(dot(normalize(NORMAL), normalize(VIEW)));
	float rim = pow(1.0 - facing, 1.6);
	float filaments = noise(vec2(UV.x * 28.0, height_m * 0.08 - TIME * drift_m_per_s * 0.08));
	float strand = smoothstep(0.55, 0.9, filaments);
	float body = 0.18 + 0.82 * rim;
	ALBEDO = glow_colour.rgb * energy * (body * (0.75 + 0.25 * strand) + 0.35 * strand * rim);
}
