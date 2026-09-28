shader_type spatial;
render_mode cull_disabled, diffuse_burley, specular_schlick_ggx;

// Recolour the installed TwistedTree leaves without substituting their UV mask.
// This adapts the rejected hero candidate's material technique, not its mesh.
uniform sampler2D leaf_atlas : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform vec4 leaf_colour : source_color = vec4(0.459, 0.573, 0.302, 1.0);
uniform float alpha_cutoff : hint_range(0.0, 1.0) = 0.2;
uniform float leaf_roughness : hint_range(0.0, 1.0) = 0.91;

void fragment() {
    vec4 source = texture(leaf_atlas, UV);
    ALBEDO = leaf_colour.rgb * mix(0.82, 1.12, source.r);
    ALPHA = source.a;
    ALPHA_SCISSOR_THRESHOLD = alpha_cutoff;
    ROUGHNESS = leaf_roughness;
    SPECULAR = 0.18;
}
