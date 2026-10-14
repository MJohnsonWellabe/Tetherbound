// Shared, metre-scaled surface gradient. Defaults keep shipped shading intact.
// Uses the already sampled material value; no new asset, UV seam or sampler.
uniform float surface_detail_strength : hint_range(0.0, 0.15) = 0.0;
uniform float surface_detail_fade_m = 0.8;
vec3 cloudreach_detail_normal(vec3 at, vec3 normal_world, float height_value) {
	vec3 n = normalize(normal_world);
	vec3 dx = dFdx(at);
	vec3 dy = dFdy(at);
	vec3 rx = cross(dy, n);
	vec3 ry = cross(n, dx);
	float determinant = dot(dx, rx);
	vec3 gradient = sign(determinant) * (dFdx(height_value) * rx + dFdy(height_value) * ry)
		/ max(abs(determinant), 0.000001);
	float fade = 1.0 - smoothstep(surface_detail_fade_m * 0.25,
		surface_detail_fade_m, max(length(dx), length(dy)));
	return normalize(n - gradient * surface_detail_strength * fade);
}
