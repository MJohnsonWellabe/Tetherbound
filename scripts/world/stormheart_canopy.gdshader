shader_type spatial;
render_mode cull_disabled, diffuse_burley, specular_schlick_ggx;

// Recolour the installed TwistedTree leaves without substituting their UV mask.
// This adapts the rejected hero candidate's material technique, not its mesh.
uniform sampler2D leaf_atlas : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform vec4 leaf_colour : source_color = vec4(0.459, 0.573, 0.302, 1.0);
uniform float alpha_cutoff : hint_range(0.0, 1.0) = 0.2;
uniform float leaf_roughness : hint_range(0.0, 1.0) = 0.91;
uniform float wind_amplitude_m = 0.16;
uniform float wind_speed = 0.85;

void vertex() {
    // World-space phase keeps adjacent installed leaf clusters in the same
    // gust. Convert the displacement back to local space so the very large
    // hero-tree scale cannot multiply a small leaf flutter into metres.
    vec3 world = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
    float wave = sin(dot(world.xz, vec2(0.038, 0.061)) + TIME * wind_speed);
    float flutter = sin(dot(world, vec3(0.7, 0.39, 0.53)) + TIME * wind_speed * 3.0);
    vec3 bend = vec3(0.82, 0.1, 0.57) * (wave + flutter * 0.22) * wind_amplitude_m;
    VERTEX += (inverse(MODEL_MATRIX) * vec4(bend, 0.0)).xyz;
}

void fragment() {
    vec4 source = texture(leaf_atlas, UV);
    ALBEDO = leaf_colour.rgb * mix(0.82, 1.12, source.r);
    ALPHA = source.a;
    ALPHA_SCISSOR_THRESHOLD = alpha_cutoff;
    ROUGHNESS = leaf_roughness;
    SPECULAR = 0.18;
}
