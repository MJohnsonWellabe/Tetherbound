shader_type spatial;
render_mode blend_mix, cull_disabled, diffuse_burley, specular_schlick_ggx, skip_vertex_transform;

// Veilfall far silhouette (scripts/world/water_veilfall_silhouette.gd). A
// coarse copy of the mountain drawn only beyond the terrain handoff distance.
// It is pulled slightly toward the camera (projection unchanged) so it sits on
// top of the distant terrain LOD, and it writes its own FOG: the environment
// fog colour at a reduced amount, so at 1.5-4 km the mountain keeps a dark,
// toned value against the pale horizon instead of fogging into the sky.
// fog_colour / fog_density are copied from the live WorldEnvironment.
uniform vec3 rock_colour : source_color = vec3(0.17, 0.20, 0.21);
uniform vec3 streak_colour : source_color = vec3(0.10, 0.12, 0.13);
uniform vec3 grass_colour : source_color = vec3(0.28, 0.36, 0.22);
uniform float slope_lo = 0.55;
uniform float slope_hi = 0.86;
uniform vec2 centre_xz = vec2(200.0, 4140.0);
uniform float streak_width_m = 7.0;
uniform float streak_length_m = 60.0;
uniform float roughness_value = 0.7;
uniform vec3 fog_colour = vec3(0.38, 0.50, 0.60); // linear; set from the environment
uniform float fog_density = 0.00055;
uniform bool fog_enabled = true;
uniform float fog_keep_near = 1.0;
uniform float fog_keep_far = 0.5;
uniform float fog_keep_start_m = 1100.0;
uniform float fog_keep_end_m = 3200.0;
// Far tone: the silhouette settles into a darker shade of the live fog colour,
// so it follows day, golden and night and always sits below the horizon value.
uniform float tone_darken = 0.62;
uniform float tone_amount = 0.72;
uniform float tone_lit_keep = 0.5;
uniform float depth_pull_fraction = 0.012;
uniform float depth_pull_max_m = 60.0;
varying vec3 v_world;
varying vec3 v_normal;
varying float v_distance;

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

void vertex() {
	v_world = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	v_normal = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
	v_distance = length(v_world - INV_VIEW_MATRIX[3].xyz);
	vec3 view = (MODELVIEW_MATRIX * vec4(VERTEX, 1.0)).xyz;
	float pull = min(v_distance * depth_pull_fraction, depth_pull_max_m);
	VERTEX = view * max(0.0, 1.0 - pull / max(v_distance, 0.001));
	NORMAL = normalize((MODELVIEW_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

void fragment() {
	vec2 facing = abs(normalize(v_world.xz - centre_xz + vec2(0.001)));
	float wx = facing.y / (facing.x + facing.y);
	float n = mix(noise(vec2(v_world.z / streak_width_m, v_world.y / streak_length_m + 17.0)),
		noise(vec2(v_world.x / streak_width_m, v_world.y / streak_length_m)), wx);
	float rock = 1.0 - smoothstep(slope_lo, slope_hi, v_normal.y);
	float n2 = mix(noise(vec2(v_world.z / (streak_width_m * 0.4), v_world.y / (streak_length_m * 0.5))),
		noise(vec2(v_world.x / (streak_width_m * 0.4), v_world.y / (streak_length_m * 0.5) + 5.0)), wx);
	vec3 wet = mix(rock_colour, streak_colour, smoothstep(0.35, 0.75, n * 0.65 + n2 * 0.35));
	// Ledge moss where the face eases, and a darker, wetter foot.
	float ledge = smoothstep(0.62, 0.8, n2) * smoothstep(0.35, 0.7, v_normal.y);
	wet = mix(wet, grass_colour, ledge * 0.6);
	float far_t = smoothstep(fog_keep_start_m, fog_keep_end_m, v_distance);
	// Far away the lit surface only carries shape; the tone below carries value.
	ALBEDO = mix(grass_colour, wet, rock) * mix(0.72, 1.08, smoothstep(0.0, 520.0, v_world.y))
		* mix(1.0, tone_lit_keep, far_t);
	ROUGHNESS = roughness_value;
	SPECULAR = 0.25;
	float env_fog = fog_enabled ? 1.0 - exp(-fog_density * v_distance) : 0.0;
	float keep = mix(fog_keep_near, fog_keep_far, far_t);
	FOG = vec4(fog_colour * mix(1.0, tone_darken, far_t), max(env_fog * keep, tone_amount * far_t));
}
