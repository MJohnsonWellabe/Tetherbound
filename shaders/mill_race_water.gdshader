shader_type spatial;
render_mode blend_mix, cull_disabled, depth_prepass_alpha, diffuse_burley, specular_schlick_ggx;

// Broken, lit mill-race water. UV.x crosses the race and UV.y follows it from
// headpond through wheel discharge to the river, so the two moving noise bands
// produce irregular streams without relying on a capture-only texture.
uniform vec4 deep_colour : source_color = vec4(0.10, 0.42, 0.48, 1.0);
uniform vec4 foam_colour : source_color = vec4(0.72, 0.88, 0.82, 1.0);
uniform float flow_speed = 0.58;

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

void fragment() {
	vec2 flowing = vec2(UV.x * 13.0, UV.y * 2.6 - TIME * flow_speed);
	float broad = noise(flowing);
	float fine = noise(flowing * vec2(2.4, 1.7) + vec2(5.3, -TIME * 0.33));
	float stream = smoothstep(0.20, 0.82, broad * 0.68 + fine * 0.32);
	float edge = smoothstep(0.0, 0.15, UV.x) * smoothstep(0.0, 0.15, 1.0 - UV.x);
	float streak = smoothstep(0.62, 0.90, fine);
	ALBEDO = mix(deep_colour.rgb, foam_colour.rgb, streak * 0.62);
	ROUGHNESS = 0.26;
	SPECULAR = 0.56;
	ALPHA = mix(0.34, 0.76, stream) * edge;
}
