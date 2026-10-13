// Shared micro-relief for Tidewake's custom stone materials. Defaults are inert.
uniform bool tidewake_detail_enabled = false;
uniform sampler2D tidewake_detail_normal : hint_normal, filter_linear_mipmap, repeat_enable;
uniform float tidewake_detail_scale = 0.65;

vec3 tidewake_surface_normal(vec3 position_world, vec3 normal_world) {
	vec3 weights = pow(abs(normal_world), vec3(4.0));
	weights /= max(dot(weights, vec3(1.0)), 0.0001);
	vec2 nx = texture(tidewake_detail_normal, position_world.zy * tidewake_detail_scale).rg * 2.0 - 1.0;
	vec2 ny = texture(tidewake_detail_normal, position_world.xz * tidewake_detail_scale).rg * 2.0 - 1.0;
	vec2 nz = texture(tidewake_detail_normal, position_world.xy * tidewake_detail_scale).rg * 2.0 - 1.0;
	vec3 detail = vec3(0.0, nx.y, nx.x) * weights.x
		+ vec3(ny.x, 0.0, ny.y) * weights.y + vec3(nz.x, nz.y, 0.0) * weights.z;
	detail -= normal_world * dot(detail, normal_world);
	return normalize(normal_world + detail);
}
