shader_type spatial;
render_mode diffuse_burley, specular_disabled;

uniform sampler2D rock_texture : source_color, filter_linear_mipmap, repeat_enable;
uniform vec4 stone_tint : source_color = vec4(0.64, 0.67, 0.59, 1.0);
uniform vec4 moss_tint : source_color = vec4(0.25, 0.32, 0.16, 1.0);
uniform float texture_scale = 0.65;
uniform float moss_amount = 0.16;
uniform float streak_strength = 0.10;
uniform float base_y = 0.0;
varying vec3 world_at;
varying vec3 world_normal;

void vertex() {
	world_at = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	world_normal = normalize(MODEL_NORMAL_MATRIX * NORMAL);
}

void fragment() {
	vec3 weights = pow(abs(world_normal), vec3(6.0));
	weights /= max(dot(weights, vec3(1.0)), 0.001);
	vec3 p = world_at * texture_scale;
	vec3 grain = texture(rock_texture, p.zy).rgb * weights.x
		+ texture(rock_texture, p.xz).rgb * weights.y
		+ texture(rock_texture, p.xy).rgb * weights.z;
	float value = dot(grain, vec3(0.30, 0.59, 0.11));
	float pockets = 0.5 + 0.5 * sin(world_at.x * 0.39 + sin(world_at.z * 0.53) * 1.7);
	float damp = 1.0 - smoothstep(0.0, 4.0, world_at.y - base_y);
	float moss = moss_amount * pockets * (damp + max(world_normal.y, 0.0) * 0.7);
	float streak = pow(0.5 + 0.5 * sin(world_at.x * 3.1 + world_at.z * 2.7), 5.0);
	vec3 stone = stone_tint.rgb * mix(0.74, 1.12, value) * COLOR.rgb;
	stone *= 1.0 - streak * streak_strength * (1.0 - abs(world_normal.y));
	ALBEDO = mix(stone, moss_tint.rgb, clamp(moss, 0.0, 0.45));
	ROUGHNESS = 0.92;
}
