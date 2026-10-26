shader_type spatial;
// Stormheart hero interior: the lightning core column's body. A deep blue
// core with bright branching filaments drifting slowly up (0.5 m/s, no
// flashing). `energy` scales the filaments; it drops when the storm ends.
render_mode unshaded, cull_back, shadows_disabled;

uniform vec4 body_colour : source_color = vec4(0.16, 0.33, 0.58, 1.0);
uniform vec4 glow_colour : source_color = vec4(0.82, 0.93, 1.0, 1.0);
uniform float energy = 1.0;
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
	float rise = height_m * 0.06 - TIME * drift_m_per_s * 0.06;
	// Thin wandering strands: a ridge of warped noise along the column.
	float warp = noise(vec2(UV.x * 6.0, rise * 0.7)) * 2.0;
	float ridge = 1.0 - abs(noise(vec2(UV.x * 14.0 + warp, rise)) * 2.0 - 1.0);
	float strand = smoothstep(0.72, 0.95, ridge);
	float facing = abs(dot(normalize(NORMAL), normalize(VIEW)));
	vec3 body = body_colour.rgb * (0.55 + 0.45 * facing);
	ALBEDO = mix(body, glow_colour.rgb, clamp(strand * energy, 0.0, 1.0));
}
