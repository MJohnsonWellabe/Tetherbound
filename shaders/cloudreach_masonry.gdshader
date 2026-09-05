shader_type spatial;
render_mode diffuse_burley, specular_disabled;
uniform vec3 stone_color : source_color = vec3(0.39, 0.40, 0.35);
uniform float block_width = 2.1;
uniform float course_height = 0.85;
varying vec3 world_position;
varying vec3 world_normal;
void vertex() {
	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	world_normal = normalize(MODEL_NORMAL_MATRIX * NORMAL);
}
void fragment() {
	float horizontal = abs(world_normal.x) > abs(world_normal.z) ? world_position.z : world_position.x;
	float course = floor(world_position.y / course_height);
	vec2 cell = vec2(horizontal / block_width + mod(course, 2.0) * 0.5, world_position.y / course_height);
	vec2 edge = min(fract(cell), vec2(1.0) - fract(cell));
	float mortar = smoothstep(0.008, 0.033, min(edge.x, edge.y));
	float variation = fract(sin(dot(floor(cell), vec2(17.23, 81.41))) * 971.31);
	float grain = sin(world_position.x * 12.7 + sin(world_position.z * 14.1)) * sin(world_position.y * 13.3);
	float face = step(abs(world_normal.y), 0.6);
	ALBEDO = stone_color * (0.91 + variation * 0.17 + grain * 0.015) * mix(1.0, mix(0.66, 1.0, mortar), face);
	ROUGHNESS = 0.98;
}
