// F38 surface family: metre-scale detail under the installed albedo/normal.
// Uniforms are local and OFF by default; other realms retain their shaders.
uniform bool meadows_finish_enabled = false;
uniform float meadows_detail_scale = 2.0;
uniform float meadows_detail_strength = 0.08;
uniform float meadows_normal_strength = 0.18;
uniform float meadows_detail_distance = 35.0;
uniform bool meadows_rim_enabled = false;
uniform float meadows_rim_strength = 0.16;
uniform float meadows_rim_tint = 0.7;

// Native material rim uses the actual lights and surface roughness. It does
// not write emission, replace baked AO, or add a glow in an unlit scene.
// Initialize both outputs explicitly: shader out values have no read default.
void meadows_rim(out float rim, out float tint) {
	rim = 0.0;
	tint = 0.0;
	if (!meadows_finish_enabled || !meadows_rim_enabled) { return; }
	rim = clamp(meadows_rim_strength, 0.0, 1.0);
	tint = clamp(meadows_rim_tint, 0.0, 1.0);
}

float meadows_grain(vec3 p) {
	// Smooth crossed grain, filtered below before it becomes sub-pixel noise.
	return sin(p.x * 2.7 + sin(p.z * 1.3)) * sin(p.z * 3.1 + p.y * 2.3)
		* sin(p.y * 2.1 + p.x * 1.7);
}

void meadows_surface(inout vec3 albedo, inout float roughness,
		inout vec3 normal, vec3 view_position, mat4 inverse_view) {
	if (!meadows_finish_enabled) { return; }
	vec3 p = (inverse_view * vec4(view_position, 1.0)).xyz * meadows_detail_scale;
	float footprint = max(length(dFdx(p)), length(dFdy(p)));
	float fade = (1.0 - smoothstep(0.15, 0.7, footprint))
		* (1.0 - smoothstep(meadows_detail_distance * 0.5, meadows_detail_distance, length(view_position)));
	float height = meadows_grain(p) * fade;
	albedo *= 1.0 - (height * 0.5 + 0.5) * meadows_detail_strength * fade;
	roughness = clamp(roughness + height * 0.035, 0.0, 1.0);
	// Surface gradient in view space; works on banks, trunks and the terrain
	// without assuming a tangent or rotating every normal toward the sky.
	vec3 dx = dFdx(view_position);
	vec3 dy = dFdy(view_position);
	vec3 r1 = cross(dy, normal);
	vec3 r2 = cross(normal, dx);
	float determinant = dot(dx, r1);
	vec3 gradient = sign(determinant) * (dFdx(height) * r1 + dFdy(height) * r2);
	if (abs(determinant) > 0.0000001) {
		normal = normalize(abs(determinant) * normal - meadows_normal_strength * 0.035 * gradient);
	}
}
