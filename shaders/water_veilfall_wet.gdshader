shader_type spatial;
// falls.rebuild wet apron (F39#31): a wider ribbon under each fall that
// darkens the rock it lies on (multiply), so both sides of the water read as
// wet dark stone. UV.x is across 0..1, UV.y metres down the strand, UV2.y the
// metres left to the foot. Presentation only.
render_mode blend_mul, unshaded, cull_disabled, depth_draw_never, shadows_disabled;
uniform vec4 wet_colour : source_color = vec4(0.42, 0.45, 0.47, 1.0);
uniform float strength = 0.75;
uniform float lip_fade_m = 18.0;
uniform float foot_fade_m = 10.0;
uniform float fade_start_m = 900.0;
uniform float fade_end_m = 2200.0;
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
	float across = abs(UV.x - 0.5) * 2.0;
	// Ragged streaky edge: wet runnels reach further in some strands.
	float streak = noise(vec2(UV.x * 18.0, UV.y / 14.0)) * 0.6 + noise(vec2(UV.x * 47.0, UV.y / 5.0)) * 0.4;
	float edge = 1.0 - smoothstep(0.55 + streak * 0.25, 1.0, across);
	float ends = smoothstep(0.0, lip_fade_m, UV.y) * smoothstep(0.0, foot_fade_m, UV2.y);
	float far = 1.0 - smoothstep(fade_start_m, fade_end_m, v_distance);
	float k = clamp(strength * edge * ends * far * mix(0.75, 1.0, streak), 0.0, 1.0);
	ALBEDO = mix(vec3(1.0), wet_colour.rgb, k);
}
