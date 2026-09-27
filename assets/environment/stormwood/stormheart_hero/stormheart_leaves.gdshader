shader_type spatial;
render_mode cull_disabled, diffuse_burley, specular_schlick_ggx;
uniform sampler2D leaf_atlas : source_color, filter_linear_mipmap_anisotropic;
uniform vec4 leaf_colour : source_color = vec4(0.43, 0.56, 0.27, 1.0);
void fragment() {
    vec4 source = texture(leaf_atlas, UV);
    ALBEDO = leaf_colour.rgb * mix(0.82, 1.12, source.r);
    ALPHA = source.a;
    ALPHA_SCISSOR_THRESHOLD = 0.2;
    ROUGHNESS = 0.91;
    SPECULAR = 0.18;
}
