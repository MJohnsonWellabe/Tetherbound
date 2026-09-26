shader_type spatial;
render_mode blend_mix, cull_disabled, depth_draw_never, diffuse_burley, specular_schlick_ggx, skip_vertex_transform;

// Veilfall fall columns (scripts/world/water_veilfall_falls.gd). Ribbons are
// draped on the mountain face. Two vertex tricks keep a 4 km read without
// more geometry: the ribbon widens to a minimum angular width, and its
// view-space position is pulled a small fraction toward the camera, which
// leaves the projected shape unchanged but keeps distant terrain LOD from
// swallowing it. COLOR.rgb carries the horizontal lateral direction and
// COLOR.g half the column opacity, COLOR.a the authored width / 100 m. UV.x is across (0..1); UV.y is metres
// from the lip.
uniform vec4 foam_colour : source_color = vec4(0.96, 0.99, 1.0, 1.0);
uniform vec4 shade_colour : source_color = vec4(0.70, 0.84, 0.88, 1.0);
uniform float flow_speed = 7.0;
uniform float opacity = 0.94;
uniform float edge_feather = 0.16;
uniform float min_angular_width = 0.012;
uniform float depth_pull_fraction = 0.004;
uniform float depth_pull_max_m = 30.0;
uniform float detail_fade_start_m = 500.0;
uniform float detail_fade_end_m = 1600.0;
uniform float night_lift = 0.06;
// Own fog (copied from the live WorldEnvironment by water_veilfall_silhouette.gd):
// the same colour at a reduced amount so the white water survives 4 km of haze.
uniform vec3 fog_colour = vec3(0.38, 0.50, 0.60); // linear; set from the environment
uniform float fog_density = 0.00055;
uniform bool fog_enabled = true;
uniform float fog_keep = 0.4;
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
	vec3 world = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	vec3 camera = INV_VIEW_MATRIX[3].xyz;
	float distance_m = length(world - camera);
	float width_m = COLOR.a * 100.0;
	float wanted = max(width_m, distance_m * min_angular_width);
	vec3 lateral = COLOR.rgb * 2.0 - 1.0;
	world += lateral * (UV.x - 0.5) * (wanted - width_m);
	v_distance = distance_m;
	vec3 view = (VIEW_MATRIX * vec4(world, 1.0)).xyz;
	float pull = min(distance_m * depth_pull_fraction, depth_pull_max_m);
	VERTEX = view * max(0.0, 1.0 - pull / max(distance_m, 0.001));
	NORMAL = normalize((MODELVIEW_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

void fragment() {
	// Two-sided: undo the engine's back-face normal flip so both sides light alike.
	if (!FRONT_FACING) {
		NORMAL = -NORMAL;
	}
	float detail = 1.0 - smoothstep(detail_fade_start_m, detail_fade_end_m, v_distance);
	float strength = COLOR.g * 2.0;
	vec2 flowing = vec2(UV.x * 14.0, (UV.y - TIME * flow_speed) / 9.0);
	float broad = noise(flowing);
	float fine = noise(flowing * vec2(2.6, 3.1) + vec2(4.2, 1.3));
	float stream = smoothstep(0.2, 0.8, broad * 0.7 + fine * 0.3);
	// Far away the fine flow is sub-pixel; large slow bands of spray and thinner
	// strands keep the column from reading as a painted stripe.
	float far_band = noise(vec2(UV.x * 3.0, UV.y / 45.0 - TIME * 0.05));
	float body = mix(smoothstep(0.1, 0.7, far_band + 0.25), stream, detail);
	float across = abs(UV.x - 0.5) * 2.0;
	float core = 1.0 - smoothstep(0.2, 1.0, across);
	float ragged = smoothstep(0.1, 0.55, body * 0.6 + core * 0.7);
	// The column's outline wanders down its length instead of a ruled edge.
	float wander = 0.55 + 0.45 * noise(vec2(UV.x > 0.5 ? 3.0 : 7.0, UV.y / 22.0 - TIME * 0.08));
	float edge = 1.0 - smoothstep(wander - edge_feather, wander, across);
	float lip = smoothstep(0.0, 10.0, UV.y);
	vec3 colour = mix(shade_colour.rgb, foam_colour.rgb, mix(0.55 + 0.45 * far_band, stream, detail));
	ALBEDO = colour;
	EMISSION = colour * night_lift;
	ROUGHNESS = 0.55;
	SPECULAR = 0.3;
	ALPHA = opacity * strength * edge * lip * ragged;
	FOG = vec4(fog_colour, fog_enabled ? (1.0 - exp(-fog_density * v_distance)) * fog_keep : 0.0);
}
