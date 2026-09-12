shader_type spatial;
render_mode blend_mix, depth_prepass_alpha, cull_back, diffuse_burley, specular_disabled;

uniform vec4 cloud_lit : source_color = vec4(0.89, 0.93, 0.95, 1.0);
uniform vec4 cloud_base : source_color = vec4(0.50, 0.58, 0.66, 1.0);
varying float local_height;

void vertex() {
	local_height = VERTEX.y;
}

void fragment() {
	float upward = clamp(NORMAL.y * 0.5 + 0.5, 0.0, 1.0);
	float facing = abs(dot(normalize(NORMAL), normalize(VIEW)));
	float soft_edge = smoothstep(0.03, 0.34, facing);
	float underside = 1.0 - smoothstep(-0.55, 0.18, local_height);
	ALBEDO = mix(cloud_lit.rgb, cloud_base.rgb,
		clamp(underside * 0.78 + (1.0 - upward) * 0.22, 0.0, 1.0));
	ROUGHNESS = 1.0;
	ALPHA = mix(0.18, 0.92, soft_edge);
}
