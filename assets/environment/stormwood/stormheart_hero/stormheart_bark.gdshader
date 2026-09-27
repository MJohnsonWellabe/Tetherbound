shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx, cull_disabled;
uniform sampler2D source_atlas : source_color, filter_linear_mipmap_anisotropic;
uniform sampler2D bark_detail : source_color, repeat_enable, filter_linear_mipmap_anisotropic;
varying vec3 tree_position;
varying vec3 tree_normal;
void vertex() {
    tree_position = VERTEX;
    tree_normal = NORMAL;
}
vec3 bark_at(vec3 p, vec3 weights) {
    return texture(bark_detail, p.zy / vec2(10.0, 22.0)).rgb * weights.x
         + texture(bark_detail, p.xz / vec2(10.0, 22.0)).rgb * weights.y
         + texture(bark_detail, p.xy / vec2(10.0, 22.0)).rgb * weights.z;
}
void fragment() {
    vec3 atlas = texture(source_atlas, UV).rgb;
    vec3 weights = pow(abs(normalize(tree_normal)), vec3(5.0));
    weights /= max(dot(weights, vec3(1.0)), 0.001);
    vec3 detail = bark_at(tree_position, weights);
    float relief = dot(detail, vec3(0.299, 0.587, 0.114));
    // Keep the reference UV atlas as the primary colour and large-form source.
    // Installed-family ridges supply metre-scale grain without stretching UVs.
    float grain = clamp(relief * 3.2, 0.48, 1.4);
    ALBEDO = atlas * vec3(0.88, 0.80, 0.68) * mix(1.0, grain, 0.32);
    ROUGHNESS = clamp(0.96 - relief * 0.23, 0.79, 0.96);
    SPECULAR = 0.18;
    vec3 dpdx = dFdx(VERTEX);
    vec3 dpdy = dFdy(VERTEX);
    vec3 r1 = cross(dpdy, NORMAL);
    vec3 r2 = cross(NORMAL, dpdx);
    float determinant = dot(dpdx, r1);
    vec3 gradient = (r1 * dFdx(relief) + r2 * dFdy(relief)) / max(abs(determinant), 0.000001);
    NORMAL = normalize(NORMAL - sign(determinant) * gradient * 0.35);
}
