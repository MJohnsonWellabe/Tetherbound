shader_type spatial;
// Living flame body: a sphere whose surface is pushed out by animated
// procedural noise into licking tongues, white-hot core to orange rim,
// with a soft fresnel edge so it reads as fire rather than a solid ball.
render_mode blend_premul_alpha, unshaded, depth_draw_never, cull_back, shadows_disabled, fog_disabled;

uniform vec4 hot : source_color = vec4(1.0, 0.95, 0.7, 1.0);
uniform vec4 rim : source_color = vec4(1.0, 0.45, 0.08, 1.0);
uniform float lick = 0.45;
uniform float opacity = 1.0;
varying float tongue;

float hash(vec3 p) { return fract(sin(dot(p, vec3(127.1, 311.7, 74.7))) * 43758.5453); }
float noise(vec3 p) {
	vec3 i = floor(p); vec3 f = fract(p); f = f * f * (3.0 - 2.0 * f);
	return mix(mix(mix(hash(i), hash(i + vec3(1,0,0)), f.x), mix(hash(i + vec3(0,1,0)), hash(i + vec3(1,1,0)), f.x), f.y),
		mix(mix(hash(i + vec3(0,0,1)), hash(i + vec3(1,0,1)), f.x), mix(hash(i + vec3(0,1,1)), hash(i + vec3(1,1,1)), f.x), f.y), f.z);
}

void vertex() {
	vec3 n = normalize(VERTEX);
	float t = TIME * 3.0;
	tongue = noise(n * 3.0 + vec3(0.0, -t, 0.0)) * 0.7 + noise(n * 6.0 + vec3(t, -t * 1.6, 0.0)) * 0.3;
	// Tongues lick upward: the top of the ball stretches more.
	VERTEX += n * tongue * lick * (0.6 + max(n.y, 0.0));
}

void fragment() {
	float facing = clamp(dot(normalize(NORMAL), normalize(VIEW)), 0.0, 1.0);
	float core = smoothstep(0.25, 0.95, facing) * (1.0 - tongue * 0.5);
	vec3 colour = mix(rim.rgb, hot.rgb, core);
	float a = smoothstep(0.0, 0.45, facing) * opacity;
	ALBEDO = colour * a * 1.3;
	ALPHA = a * 0.85;
}
