shader_type spatial;
render_mode blend_mix, depth_prepass_alpha, cull_disabled;

varying vec3 scar_position;

float scar_hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float scar_noise(vec2 p) {
	vec2 cell = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(scar_hash(cell), scar_hash(cell + vec2(1.0, 0.0)), f.x),
		mix(scar_hash(cell + vec2(0.0, 1.0)), scar_hash(cell + vec2(1.0)), f.x), f.y);
}

void vertex() {
	scar_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec2 p = scar_position.xz;
	float grain = scar_noise(p * 8.0);
	float folds = scar_noise(p * 1.7 + vec2(scar_noise(p * 0.4)) * 2.0);
	float glass = smoothstep(0.50, 0.76, folds) * (0.45 + grain * 0.55);
	vec3 charcoal = COLOR.rgb * (0.85 + grain * 0.65) + vec3(0.018, 0.021, 0.018);
	ALBEDO = mix(charcoal, vec3(0.075, 0.19, 0.19), glass * 0.65);
	ROUGHNESS = mix(0.91, 0.30, glass);
	METALLIC = glass * 0.32;
	SPECULAR = mix(0.2, 0.6, glass);
	ALPHA = COLOR.a * mix(0.78, 1.0, grain);
}
