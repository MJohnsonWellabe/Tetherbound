shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_back;

uniform vec4 harness_color : source_color = vec4(0.0);
uniform vec4 charm_color : source_color = vec4(0.0);
uniform mat4 mesh_to_body;
uniform float body_min_y = 0.0;
uniform float body_height = 1.0;
uniform float band_center = 0.56;
uniform float band_width = 0.12;
uniform float charm_band_center = 0.78;
uniform float charm_band_width = 0.045;
uniform float emission_energy = 0.7;
uniform float harness_glow = 1.0;
uniform float charm_glow = 1.0;
varying float body_y;

void vertex() {
    body_y = ((mesh_to_body * vec4(VERTEX, 1.0)).y - body_min_y) / max(body_height, 0.001);
}

void fragment() {
    // A narrow trim: a crisp strap with a brighter core line, not a tinted slab.
    float dh = abs(body_y - band_center);
    float dc = abs(body_y - charm_band_center);
    float harness = 1.0 - smoothstep(band_width * 0.42, band_width * 0.5, dh);
    float charm = 1.0 - smoothstep(charm_band_width * 0.42, charm_band_width * 0.5, dc);
    float h_core = 1.0 - smoothstep(0.0, band_width * 0.18, dh);
    float c_core = 1.0 - smoothstep(0.0, charm_band_width * 0.2, dc);
    float h = harness * harness_color.a;
    float c = charm * charm_color.a;
    vec3 tint = mix(harness_color.rgb, charm_color.rgb, step(h, c));
    float glow = mix(harness_glow, charm_glow, step(h, c));
    float core = max(h_core * h, c_core * c);
    ALBEDO = mix(tint * 0.85, vec3(1.0), core * 0.35);
    EMISSION = tint * emission_energy * glow * (0.6 + core);
    ALPHA = max(h, c) * 0.96;
}
