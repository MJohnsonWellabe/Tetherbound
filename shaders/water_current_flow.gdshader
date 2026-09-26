shader_type spatial;
render_mode blend_mix, cull_disabled, depth_draw_never, diffuse_burley, specular_disabled, skip_vertex_transform;

// Tidewake current crests (scripts/world/water_current_flow_view.gd). One
// joined grid per authored current, all in one mesh. The foam pattern is laid out
// in world space along the current's single physics flow vector, so the
// streaks drift exactly the way the swimmer is pushed. COLOR.rg = flow
// direction * 0.5 + 0.5, COLOR.b = relative strength, UV.x = across (0..1),
// UV2.x = fraction along the route (end fades).
uniform vec4 foam_colour : source_color = vec4(0.90, 0.97, 0.97, 1.0);
uniform float opacity = 0.5;
// Wet wave faces carry colour only beneath individual crests. The calm sea
// remains visible between them, rather than colouring a continuous lane.
uniform vec4 lane_colour : source_color = vec4(0.72, 0.90, 0.88, 1.0);
uniform float lane_opacity = 0.14;
uniform float streak_width_m = 1.1;
uniform float streak_length_m = 7.0;
uniform float wave_height_m = 0.65;
uniform float min_speed_m_s = 0.35;
uniform float speed_scale = 1.4;
uniform float calm_scale = 1.0;
uniform float fade_start_m = 180.0;
uniform float fade_end_m = 520.0;
uniform float depth_pull_fraction = 0.003;
varying vec3 v_world;
varying float v_distance;
varying float v_wave;
varying float v_packet;

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
	vec2 flow = normalize(COLOR.rg * 2.0 - 1.0 + vec2(0.0001));
	vec2 side = vec2(-flow.y, flow.x);
	float speed = max(min_speed_m_s, COLOR.b * speed_scale) * calm_scale;
	float moving = dot(v_world.xz, flow) - TIME * speed;
	float across_m = dot(v_world.xz, side);
	float turn = sin(across_m * 0.47) * 0.9 + sin(across_m * 0.19 + moving * 0.08) * 1.6;
	float phase = (moving + turn) / streak_length_m * 6.283185;
	float rounded = 0.5 + 0.5 * sin(phase);
	v_wave = pow(rounded, 2.5);
	v_packet = smoothstep(0.25, 0.70, noise(vec2(across_m * 0.13, moving * 0.085)));
	float edge = 1.0 - smoothstep(0.5, 1.0, abs(UV.x * 2.0 - 1.0));
	float ends = smoothstep(0.0, 0.12, UV2.x) * (1.0 - smoothstep(0.88, 1.0, UV2.x));
	float energy = smoothstep(0.20, 0.85, COLOR.b);
	float amplitude = wave_height_m * energy * edge * ends * v_packet;
	v_world.y += v_wave * amplitude;
	float slope = 1.25 * pow(rounded, 1.5) * cos(phase) * 6.283185 / streak_length_m * amplitude;
	vec3 wave_normal = normalize(vec3(-flow.x * slope, 1.0, -flow.y * slope));
	vec3 view = (VIEW_MATRIX * vec4(v_world, 1.0)).xyz;
	// Same projected position, slightly nearer: no z-fight with the sea plane.
	VERTEX = view * (1.0 - depth_pull_fraction);
	NORMAL = normalize((VIEW_MATRIX * vec4(wave_normal, 0.0)).xyz);
}

void fragment() {
	vec2 flow = normalize(COLOR.rg * 2.0 - 1.0 + vec2(0.0001));
	float strength = COLOR.b;
	float along = dot(v_world.xz, flow);
	float across_m = dot(v_world.xz, vec2(-flow.y, flow.x));
	float speed = max(min_speed_m_s, strength * speed_scale) * calm_scale;
	// Foam sits on raised, curved crests; the darker wet face gives the current
	// volume against the calm sea instead of drawing a route stripe over it.
	float moving = along - TIME * speed;
	float breakup = smoothstep(0.20, 0.72, noise(vec2(across_m / streak_width_m, moving * 0.65)));
	float foam_cap = smoothstep(0.48, 0.90, v_wave) * breakup * v_packet;
	float fleck = smoothstep(0.75, 0.93, noise(vec2(across_m * 1.6, moving * 1.2)));
	float streak = max(foam_cap, fleck * v_wave * v_packet * 0.55);
	float across = abs(UV.x - 0.5) * 2.0;
	float edge = 1.0 - smoothstep(0.55, 1.0, across);
	float ends = smoothstep(0.0, 0.12, UV2.x) * (1.0 - smoothstep(0.88, 1.0, UV2.x));
	float fade = 1.0 - smoothstep(fade_start_m, fade_end_m, v_distance);
	float mask = edge * ends * fade * mix(0.55, 1.0, calm_scale);
	float foam = clamp(opacity * streak * mix(0.12, 1.0, strength), 0.0, 1.0);
	float band = lane_opacity * smoothstep(0.12, 0.9, strength) * pow(v_wave, 0.8) * v_packet;
	float alpha = foam + band * (1.0 - foam);
	ALBEDO = (foam_colour.rgb * foam + lane_colour.rgb * band * (1.0 - foam)) / max(alpha, 0.001);
	ROUGHNESS = mix(0.3, 0.85, foam);
	ALPHA = alpha * mask;
}
