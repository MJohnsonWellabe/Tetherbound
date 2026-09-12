shader_type spatial;
render_mode cull_disabled, diffuse_burley;

// Preserve the Meshy atlas detail while pulling its pale grey-green scan into
// the warmer, darker Ironwood palette used by the authored Grove. The source
// atlas contains both foliage and bark, so the green-over-red relationship is
// used as a soft material mask rather than replacing the texture wholesale.
uniform sampler2D albedo_texture : source_color, filter_linear_mipmap_anisotropic;
uniform vec3 leaf_tint : source_color = vec3(0.46, 0.68, 0.40);
uniform vec3 bark_tint : source_color = vec3(0.62, 0.39, 0.24);
uniform float exposure = 0.72;
uniform vec3 lightning_colour : source_color = vec3(0.22, 0.76, 1.0);
uniform vec2 tree_centre_xz = vec2(-330.0, 5160.0);
uniform float lightning_energy = 5.2;

varying vec3 world_position;
varying vec3 world_normal;

void vertex() {
	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	world_normal = normalize(MODEL_NORMAL_MATRIX * NORMAL);
}

float hash_line(float value) {
	return fract(sin(value * 127.1) * 43758.5453);
}

float jagged_offset(float height, float seed) {
	float cell = floor(height / 4.2);
	float along = fract(height / 4.2);
	float from_offset = (hash_line(cell + seed) - 0.5) * 0.78;
	float to_offset = (hash_line(cell + 1.0 + seed) - 0.5) * 0.78;
	return mix(from_offset, to_offset, along);
}

float angle_distance(float from_angle, float to_angle) {
	float delta = from_angle - to_angle;
	return abs(atan(sin(delta), cos(delta)));
}

float lightning_channel(float angle, float height, float seed, float base_angle) {
	float target = base_angle + height * 0.004 + jagged_offset(height, seed);
	float main_line = 1.0 - smoothstep(0.020, 0.066, angle_distance(angle, target));
	float fork_cycle = mod(height + seed * 9.0, 38.0);
	float fork_window = step(7.0, fork_cycle) * (1.0 - step(22.0, fork_cycle));
	float fork_growth = clamp((fork_cycle - 7.0) / 15.0, 0.0, 1.0);
	float fork_target_a = target + (0.22 + seed * 0.055) * fork_growth;
	float fork_target_b = target - (0.18 + seed * 0.045) * fork_growth;
	float fork_line_a = (1.0 - smoothstep(0.012, 0.042,
		angle_distance(angle, fork_target_a))) * fork_window;
	float fork_line_b = (1.0 - smoothstep(0.010, 0.036,
		angle_distance(angle, fork_target_b))) * fork_window
		* step(0.38, fork_growth);
	return max(main_line, max(fork_line_a, fork_line_b));
}

void fragment() {
	vec4 source = texture(albedo_texture, UV);
	float leaf_mask = smoothstep(-0.015, 0.085, source.g - source.r);
	vec3 detailed = pow(max(source.rgb, vec3(0.001)), vec3(1.10));
	vec3 tint = mix(bark_tint, leaf_tint, leaf_mask);

	// Bind the electrical pattern to the actual Meshy surface so it wraps the
	// trunk and branches without any free-standing geometry crossing open air.
	vec2 radial = world_position.xz - tree_centre_xz;
	float angle = atan(radial.y, radial.x);
	float height = world_position.y;
	float main_vein = 0.0;
	for (int channel = 0; channel < 9; channel++) {
		float channel_step = float(channel);
		float seed = 1.0 + channel_step * 0.43;
		float base_angle = -2.8 + channel_step * 0.70;
		main_vein = max(main_vein,
			lightning_channel(angle, height, seed, base_angle));
	}
	// The atlas does not offer a clean bark island, so use the source colour as
	// a strict material classifier. More channels create prominence without
	// admitting grey-green leaf facets. The radial envelope retains the massive
	// trunk and principal crown wood while excluding the detached outer canopy.
	float bark_colour_mask = smoothstep(0.025, 0.095, source.r - source.g);
	float bark_face_mask = 1.0 - smoothstep(0.64, 0.92, abs(world_normal.y));
	float radial_mask = 1.0 - smoothstep(43.0, 55.0, length(radial));
	float bark_mask = bark_colour_mask * bark_face_mask * radial_mask;
	float vein = clamp(main_vein * bark_mask, 0.0, 1.0);
	float travelling_surge = pow(sin(TIME * 3.6 - height * 0.16) * 0.5 + 0.5, 7.0);
	float pulse = 0.82 + travelling_surge * 1.65;

	vec3 base_colour = detailed * tint * exposure * 2.0;
	float charred_edge = clamp(main_vein * bark_mask * 0.48, 0.0, 1.0);
	base_colour = mix(base_colour, base_colour * 0.28, charred_edge);
	ALBEDO = mix(base_colour, lightning_colour * 1.32, vein * 0.90);
	EMISSION = lightning_colour * vein * lightning_energy * pulse;
	ROUGHNESS = mix(0.92, 0.82, leaf_mask);
	METALLIC = 0.0;
}
