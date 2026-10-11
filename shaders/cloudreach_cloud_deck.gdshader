shader_type spatial;
render_mode blend_mix, depth_draw_never, cull_disabled, diffuse_burley, specular_disabled;

// Soft cloud body under the plateau. Original procedural material, using the
// approved Sky Aviary board for broad billows and cool shaded valleys.
uniform vec4 cloud_lit : source_color = vec4(0.83, 0.88, 0.91, 1.0);
uniform vec4 cloud_base : source_color = vec4(0.40, 0.50, 0.60, 1.0);
varying vec2 world_xz;

float hash_cloud(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}
float cloud_noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash_cloud(i), hash_cloud(i + vec2(1.0, 0.0)), f.x),
		mix(hash_cloud(i + vec2(0.0, 1.0)), hash_cloud(i + vec2(1.0)), f.x), f.y);
}
float cloud_density(vec2 p) {
	return cloud_noise(p) * 0.58 + cloud_noise(p * 2.07 + 8.3) * 0.28
		+ cloud_noise(p * 4.31 - 3.7) * 0.14;
}
void vertex() {
	world_xz = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xz;
}
void fragment() {
	vec2 p = world_xz / 190.0;
	float body = smoothstep(0.23, 0.76, cloud_density(p));
	float shoulder = cloud_density(p + vec2(-0.19, 0.16));
	float shade = clamp(body * 0.80 + (body - shoulder) * 0.75 + 0.12, 0.0, 1.0);
	ALBEDO = mix(cloud_base.rgb, cloud_lit.rgb, shade);
	// The height mesh is a density support, not an opaque floor. Fade its
	// actual grazing silhouette before replacing the lighting normal below:
	// otherwise terrain clamps expose long, straight triangular cloud walls.
	float facing = abs(dot(normalize(NORMAL), normalize(VIEW)));
	float grazing = smoothstep(0.025, 0.24, facing);
	vec2 edge_distance = min(UV, vec2(1.0) - UV);
	float perimeter = smoothstep(0.0, 0.055, min(edge_distance.x, edge_distance.y));
	float density = smoothstep(0.16, 0.68, cloud_density(p + vec2(0.37, -0.23)));
	ALPHA = perimeter * grazing * mix(0.20, 0.88, density);
	// Height-grid triangles must not become giant flat-shaded facets. The
	// visual deck stays below routes; cloud form is the broad density field.
	NORMAL = normalize((VIEW_MATRIX * vec4(0.0, 1.0, 0.0, 0.0)).xyz);
	ROUGHNESS = 1.0;
}
