shader_type spatial;
render_mode cull_disabled, diffuse_burley, specular_schlick_ggx;

// Exposed longitudinal fracture grain uses the installed wood family. UVs
// measure the cap's real thickness/height, so its radial width never collapses.
uniform sampler2D wood_atlas : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform vec4 wood_tint : source_color = vec4(0.659, 0.6, 0.482, 1.0);

void fragment() {
	vec2 grain = UV;
	grain.x += sin(UV.y * 2.1 + sin(UV.y * 0.61)) * 0.035;
	vec2 atlas_uv = vec2(fract(grain.y), 0.025 + fract(grain.x) * 0.24);
	vec3 wood = texture(wood_atlas, atlas_uv).rgb;
	float split = sin(grain.x * 63.0 + sin(grain.y * 4.7) * 0.8);
	float broken = smoothstep(0.7, 0.95, split) * smoothstep(-0.15, 0.7, sin(grain.y * 3.1 + grain.x * 7.3));
	float weather = 0.9 + 0.1 * sin(UV.y * 0.73 + UV.x * 1.7);
	ALBEDO = wood * wood_tint.rgb * weather * (1.0 - broken * 0.3);
	ROUGHNESS = 0.94;
	SPECULAR = 0.18;
}
