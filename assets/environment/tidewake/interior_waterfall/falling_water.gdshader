shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_disabled, diffuse_burley, specular_schlick_ggx;

// UV V runs from the crest down to impact. Positive speed travels downward.
uniform vec4 deep_colour : source_color = vec4(0.25, 0.48, 0.59, 1.0);
uniform vec4 foam_colour : source_color = vec4(0.78, 0.89, 0.91, 1.0);
uniform float opacity = 0.94;
uniform float flow_speed = 3.8;
uniform float foam_bias = 0.0;
uniform float motion = 0.035;
varying vec3 local_position;

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
	local_position = VERTEX;
	float bend = sin(UV.y * 3.141593);
	VERTEX.z += sin(UV.y * 32.0 - TIME * 7.5 + VERTEX.x * 1.7) * motion * bend;
	VERTEX.x += sin(UV.y * 18.0 - TIME * 5.0 + VERTEX.x * 2.3) * motion * 0.45 * bend;
}
void fragment() {
	float x = local_position.x;
	float flow = UV.y * 9.0 - TIME * flow_speed;
	float streak = noise(vec2(x * 2.3, flow * 0.72));
	float fine = noise(vec2(x * 17.0, flow * 2.5));
	float broken = noise(vec2(x * 9.0, flow * 6.0));
	float whitewater = smoothstep(0.30, 0.76, streak * 0.82 + fine * 0.18 + foam_bias);
	float lip = (1.0 - smoothstep(0.09, 0.19, UV.y)) * smoothstep(0.0, 0.06, UV.y);
	float impact = smoothstep(0.90, 1.0, UV.y);
	float broad = noise(vec2(x * 1.35, flow * 0.43));
	float foam = clamp(0.10 + whitewater * 0.48 + broad * 0.19 + lip * 0.50 + impact * broken * 0.48, 0.0, 1.0);
	ALBEDO = mix(deep_colour.rgb, foam_colour.rgb, foam);
	ROUGHNESS = mix(0.26, 0.72, foam);
	SPECULAR = 0.65;
	float edge = smoothstep(0.0, 0.055, UV.x) * smoothstep(0.0, 0.055, 1.0 - UV.x);
	ALPHA = edge * opacity * (0.85 + streak * 0.15);
}
