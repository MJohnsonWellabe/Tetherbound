shader_type spatial;
// falls.rebuild base mist (F39#31): an open, flaring cone of mist rising from
// a plunge pool. Not camera-facing puffs (parked for this row): a lit shell
// whose alpha follows how squarely each part faces the camera, so the
// silhouette is soft and the middle reads as depth. UV.x around, UV.y height
// 0 (pool) to 1 (top). Presentation only.
render_mode blend_mix, cull_disabled, depth_draw_never, diffuse_lambert, specular_disabled, shadows_disabled;
uniform vec4 mist_colour : source_color = vec4(0.93, 0.96, 0.97, 1.0);
uniform float opacity = 0.55;
uniform float rise_speed = 0.06;
uniform float top_falloff = 1.6;
uniform float fade_start_m = 1100.0;
uniform float fade_end_m = 2600.0;
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
	float facing = abs(dot(normalize(NORMAL), normalize(VIEW)));
	float soft_side = pow(facing, 1.3);
	float billow = noise(vec2(UV.x * 11.0, UV.y * 3.0 - TIME * rise_speed)) * 0.65
		+ noise(vec2(UV.x * 29.0, UV.y * 7.0 - TIME * rise_speed * 1.7)) * 0.35;
	float height = pow(1.0 - UV.y, top_falloff) * smoothstep(0.0, 0.06, UV.y);
	float far = 1.0 - smoothstep(fade_start_m, fade_end_m, v_distance);
	ALBEDO = mist_colour.rgb;
	ROUGHNESS = 1.0;
	ALPHA = clamp(opacity * height * soft_side * mix(0.4, 1.0, billow) * far, 0.0, 1.0);
}
