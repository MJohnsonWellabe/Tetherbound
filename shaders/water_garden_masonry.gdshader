shader_type spatial;
render_mode cull_disabled, diffuse_burley, specular_schlick_ggx;
#include "res://shaders/tidewake_detail.gdshaderinc"

// Installed masonry over the unchanged accepted retaining triangles. Shared
// floor/connector faces below BOTH solid tops are internal, not exposed walls.
uniform sampler2D stone_texture : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D rough_texture : hint_default_white, filter_linear_mipmap, repeat_enable;
uniform vec4 tint : source_color = vec4(1.0);
uniform float repeats_per_m = 0.32;
uniform bool connector_wall = false;
uniform vec2 garden_origin;
uniform vec4 floor_bands[3]; // inner radius, outer radius, top y, unused
uniform vec4 ramp_a[3]; // xyz, half width
uniform vec4 ramp_b[3];
uniform vec2 angles_rad;
varying vec3 world_at;

void vertex() {
	world_at = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	if (connector_wall) {
		vec2 polar = world_at.xz - garden_origin;
		float angle = atan(polar.y, polar.x);
		float radius = length(polar);
		for (int i = 0; i < 3; i++) {
			if (angle > angles_rad.x && angle < angles_rad.y && radius > floor_bands[i].x && radius < floor_bands[i].y && world_at.y < floor_bands[i].z - 0.015) discard;
		}
	} else {
		for (int i = 0; i < 3; i++) {
			vec2 delta = ramp_b[i].xz - ramp_a[i].xz;
			float t = dot(world_at.xz - ramp_a[i].xz, delta) / dot(delta, delta);
			float across = length(world_at.xz - (ramp_a[i].xz + delta * clamp(t, 0.0, 1.0)));
			if (t >= 0.0 && t <= 1.0 && across < ramp_a[i].w + 0.003 && world_at.y < mix(ramp_a[i].y, ramp_b[i].y, t) - 0.015) discard;
		}
	}
	// Geometric face normal prevents smoothing across narrow wall ends from
	// collapsing their triplanar projection into a plain grey fin.
	vec3 geometric = normalize(cross(dFdx(VERTEX), dFdy(VERTEX)));
	if (dot(geometric, VIEW) < 0.0) geometric = -geometric;
	NORMAL = geometric;
	vec3 world_normal = normalize((INV_VIEW_MATRIX * vec4(geometric, 0.0)).xyz);
	vec3 weights = pow(abs(world_normal), vec3(8.0));
	weights /= max(dot(weights, vec3(1.0)), 0.0001);
	vec2 ux = world_at.zy * repeats_per_m;
	vec2 uy = world_at.xz * repeats_per_m;
	vec2 uz = world_at.xy * repeats_per_m;
	ALBEDO = tint.rgb * (texture(stone_texture, ux).rgb * weights.x + texture(stone_texture, uy).rgb * weights.y + texture(stone_texture, uz).rgb * weights.z);
	ROUGHNESS = clamp(texture(rough_texture, ux).r * weights.x + texture(rough_texture, uy).r * weights.y + texture(rough_texture, uz).r * weights.z, 0.8, 1.0);
	SPECULAR = 0.25;
	if (tidewake_detail_enabled) {
		NORMAL = normalize(mat3(VIEW_MATRIX) * tidewake_surface_normal(world_at, world_normal));
	}
}
