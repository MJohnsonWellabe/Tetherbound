// Shared metre-based relief for the Stormwood look candidate. The original
// surface owns colour, alpha, emission and animation. No extra geometry pass.
uniform float sw_normal_strength = 0.0;
uniform float sw_detail_strength = 0.0;
uniform float sw_detail_frequency = 1.0;
uniform float sw_roughness_scale = 1.0;

void sw_surface_detail(inout vec3 albedo, inout vec3 normal, inout float roughness,
        vec3 world_at, mat3 world_to_view) {
    vec3 p = world_at * sw_detail_frequency;
    // Two broad, non-aligned bands; filter away sub-pixel relief in the distance.
    float footprint = max(length(dFdx(p)), length(dFdy(p)));
    float resolved = 1.0 - smoothstep(0.35, 1.2, footprint);
    vec3 a = vec3(0.73, 0.41, 0.59);
    vec3 b = vec3(-0.37, 1.13, 0.83);
    float relief = sin(dot(p, a)) * 0.62 + sin(dot(p, b)) * 0.38;
    vec3 slope = a * cos(dot(p, a)) * 0.62 + b * cos(dot(p, b)) * 0.38;
    vec3 view_slope = world_to_view * slope;
    vec3 tangent_slope = view_slope - normal * dot(normal, view_slope);
    normal = normalize(normal - tangent_slope * sw_normal_strength * resolved);
    albedo *= 1.0 + relief * sw_detail_strength * resolved;
    roughness = clamp(roughness * sw_roughness_scale, 0.0, 1.0);
}
