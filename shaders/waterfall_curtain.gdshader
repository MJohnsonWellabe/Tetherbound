shader_type spatial;
render_mode blend_mix, cull_disabled, diffuse_burley, specular_schlick_ggx;

// A lit falling curtain: no emission or screen-colour overlay. UV flow is
// stretched vertically, with broken streams and feathered outer edges.
uniform vec4 water_colour : source_color = vec4(0.72, 0.89, 0.87, 1.0);
uniform float opacity_min = 0.28;
uniform float opacity_max = 0.70;
uniform float flow_speed = 0.32;
uniform float edge_feather = 0.08;
uniform float ground_feather_m = 2.0;
uniform float albedo_min = 0.40;
uniform float albedo_max = 0.68;
uniform sampler2D ground_heights : filter_linear, repeat_disable;
uniform vec2 ground_span;
varying vec3 world_position;

void vertex() {
	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise(vec2 p) {
	vec2 cell = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(cell), hash(cell + vec2(1.0, 0.0)), f.x),
		mix(hash(cell + vec2(0.0, 1.0)), hash(cell + vec2(1.0)), f.x), f.y);
}

void fragment() {
	vec2 flowing = vec2(UV.x * 23.0, UV.y * 9.0 - TIME * flow_speed);
	float broad = noise(flowing);
	float fine = noise(flowing * vec2(2.7, 1.9) + vec2(8.4, -TIME * flow_speed));
	float stream = smoothstep(0.18, 0.85, broad * 0.72 + fine * 0.28);
	float edge = smoothstep(0.0, edge_feather, UV.x)
		* smoothstep(0.0, edge_feather, 1.0 - UV.x)
		* smoothstep(0.0, 0.025, UV.y)
		* smoothstep(0.0, 0.025, 1.0 - UV.y);
	// Sample centers map exactly to the 64 world-space terrain samples.
	float across = clamp((world_position.x - ground_span.x) / max(ground_span.y - ground_span.x, 0.001), 0.0, 1.0);
	float ground_y = texture(ground_heights, vec2((across * 63.0 + 0.5) / 64.0, 0.5)).r;
	float contact = smoothstep(0.0, max(ground_feather_m, 0.001), world_position.y - ground_y);
	ALBEDO = water_colour.rgb * mix(albedo_min, albedo_max, stream);
	ROUGHNESS = 0.38;
	SPECULAR = 0.35;
	ALPHA = mix(opacity_min, opacity_max, stream) * edge * contact;
}
