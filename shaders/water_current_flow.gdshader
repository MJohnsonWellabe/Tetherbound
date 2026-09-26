shader_type spatial;
render_mode blend_mix, cull_disabled, depth_draw_never, diffuse_burley, specular_disabled, skip_vertex_transform;

// Tidewake current streaks (scripts/world/water_current_flow_view.gd). One
// ribbon per authored current, all in one mesh. The foam pattern is laid out
// in world space along the current's single physics flow vector, so the
// streaks drift exactly the way the swimmer is pushed. COLOR.rg = flow
// direction * 0.5 + 0.5, COLOR.b = relative strength, UV.x = across (0..1),
// UV2.x = fraction along the route (end fades).
uniform vec4 foam_colour : source_color = vec4(0.90, 0.97, 0.97, 1.0);
uniform float opacity = 0.5;
uniform float streak_width_m = 1.1;
uniform float streak_length_m = 9.0;
uniform float min_speed_m_s = 0.35;
uniform float speed_scale = 1.4;
uniform float calm_scale = 1.0;
uniform float fade_start_m = 180.0;
uniform float fade_end_m = 520.0;
uniform float depth_pull_fraction = 0.003;
varying vec3 v_world;
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
	v_distance = length(v_world - INV_VIEW_MATRIX[3].xyz);
	vec3 view = (MODELVIEW_MATRIX * vec4(VERTEX, 1.0)).xyz;
	// Same projected position, slightly nearer: no z-fight with the sea plane.
	VERTEX = view * (1.0 - depth_pull_fraction);
	NORMAL = normalize((MODELVIEW_MATRIX * vec4(0.0, 1.0, 0.0, 0.0)).xyz);
}

void fragment() {
	// The ribbon may be seen from its back face; always light it as the sea top.
	NORMAL = normalize((VIEW_MATRIX * vec4(0.0, 1.0, 0.0, 0.0)).xyz);
	vec2 flow = normalize(COLOR.rg * 2.0 - 1.0 + vec2(0.0001));
	float strength = COLOR.b;
	float along = dot(v_world.xz, flow);
	float across_m = dot(v_world.xz, vec2(-flow.y, flow.x));
	float speed = max(min_speed_m_s, strength * speed_scale) * calm_scale;
	// Thin wandering foam lanes, broken into dashes that drift with the flow.
	float lane = across_m / streak_width_m + noise(vec2(along / 30.0, across_m / 20.0)) * 1.5;
	float line = smoothstep(0.72, 0.96, 1.0 - abs(fract(lane) * 2.0 - 1.0));
	float dash = smoothstep(0.4, 0.8, noise(vec2(floor(lane) * 3.1, (along - TIME * speed) / streak_length_m)));
	float fleck = smoothstep(0.8, 0.95, noise(vec2(across_m * 0.9, (along - TIME * speed) * 0.35)));
	float streak = max(line * dash, fleck * 0.5);
	float across = abs(UV.x - 0.5) * 2.0;
	float edge = 1.0 - smoothstep(0.55, 1.0, across);
	float ends = smoothstep(0.0, 0.12, UV2.x) * (1.0 - smoothstep(0.88, 1.0, UV2.x));
	float fade = 1.0 - smoothstep(fade_start_m, fade_end_m, v_distance);
	ALBEDO = foam_colour.rgb;
	ROUGHNESS = 0.7;
	ALPHA = opacity * streak * edge * ends * fade
		* mix(0.45, 1.0, strength) * mix(0.55, 1.0, calm_scale);
}
