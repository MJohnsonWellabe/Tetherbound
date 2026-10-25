shader_type spatial;
// Stormheart hero interior: the soft sheath around the lightning core column.
// Additive and unshaded, a soft halo with slow vertical
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
	// A soft halo: brightest through the middle, gone at the silhouette, so
	// it reads as glow around the core rather than a glass tube.
	float facing = abs(dot(normalize(NORMAL), normalize(VIEW)));
	float halo = pow(facing, 2.5);
	float filaments = noise(vec2(UV.x * 18.0, height_m * 0.05 - TIME * drift_m_per_s * 0.05));
	ALBEDO = glow_colour.rgb * energy * halo * (0.8 + 0.4 * filaments);
}
