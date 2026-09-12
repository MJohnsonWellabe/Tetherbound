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

void fragment() {
	vec4 source = texture(albedo_texture, UV);
	float leaf_mask = smoothstep(-0.015, 0.085, source.g - source.r);
	vec3 detailed = pow(max(source.rgb, vec3(0.001)), vec3(1.10));
	vec3 tint = mix(bark_tint, leaf_tint, leaf_mask);
	ALBEDO = detailed * tint * exposure * 2.0;
	ROUGHNESS = mix(0.92, 0.82, leaf_mask);
	METALLIC = 0.0;
}
