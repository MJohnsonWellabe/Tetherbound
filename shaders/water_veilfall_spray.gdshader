shader_type spatial;
render_mode blend_mix, cull_disabled, depth_draw_never, diffuse_lambert, specular_disabled, skip_vertex_transform;

// Camera-facing spray puffs at the Veilfall plunge points
// (scripts/world/water_veilfall_falls.gd). One mesh of a few quads, no
// particles. VERTEX is the puff centre; UV2 is the corner in -1..1; COLOR.a
// is the size / 100 m and COLOR.r a per-puff phase. Same minimum angular
// size and depth pull as the fall columns so the mist reads at 4 km.
uniform vec4 mist_colour : source_color = vec4(0.95, 0.98, 1.0, 1.0);
uniform float opacity = 0.62;
uniform float drift_speed = 0.05;
uniform float min_angular_size = 0.016;
uniform float depth_pull_fraction = 0.004;
uniform float depth_pull_max_m = 30.0;
uniform float night_lift = 0.06;
varying float v_distance;
// Own fog (copied from the live WorldEnvironment by water_veilfall_silhouette.gd):
// the same colour at a reduced amount so the white water survives 4 km of haze.
uniform vec3 fog_colour = vec3(0.38, 0.50, 0.60); // linear; set from the environment
uniform float fog_density = 0.00055;
uniform bool fog_enabled = true;
uniform float fog_keep = 0.4;

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
	vec3 centre = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	vec3 camera = INV_VIEW_MATRIX[3].xyz;
	float distance_m = length(centre - camera);
	v_distance = distance_m;
	float size_m = max(COLOR.a * 100.0, distance_m * min_angular_size);
	vec3 view = (VIEW_MATRIX * vec4(centre, 1.0)).xyz;
	// Wider than tall: mist spreads across the plunge pool.
	view.xy += UV2 * vec2(size_m, size_m * 0.62);
	float pull = min(distance_m * depth_pull_fraction, depth_pull_max_m);
	VERTEX = view * max(0.0, 1.0 - pull / max(distance_m, 0.001));
	// Half toward the sky so the puff takes daylight like a cloud, not a card.
	NORMAL = normalize(vec3(0.0, 0.0, 1.0) + (VIEW_MATRIX * vec4(0.0, 1.0, 0.0, 0.0)).xyz);
}

void fragment() {
	// Two-sided: undo the engine's back-face normal flip so both sides light alike.
	if (!FRONT_FACING) {
		NORMAL = -NORMAL;
	}
	vec2 p = UV2;
	float phase = COLOR.r * 10.0;
	float radial = 1.0 - smoothstep(0.35, 1.0, length(p));
	float billow = noise(p * 2.2 + vec2(phase, phase * 0.7 - TIME * drift_speed))
		* 0.6 + noise(p * 4.7 + vec2(-phase, TIME * drift_speed * 1.7)) * 0.4;
	ALBEDO = mist_colour.rgb;
	EMISSION = mist_colour.rgb * night_lift;
	ALPHA = opacity * radial * smoothstep(0.2, 0.75, billow + radial * 0.35);
	FOG = vec4(fog_colour, fog_enabled ? (1.0 - exp(-fog_density * v_distance)) * fog_keep : 0.0);
}
