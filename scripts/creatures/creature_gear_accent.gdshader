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
varying float body_y;

void vertex() {
    body_y = ((mesh_to_body * vec4(VERTEX, 1.0)).y - body_min_y) / max(body_height, 0.001);
}

void fragment() {
    float harness = 1.0 - smoothstep(band_width * 0.33, band_width * 0.5, abs(body_y - band_center));
    float charm = 1.0 - smoothstep(charm_band_width * 0.25, charm_band_width * 0.5, abs(body_y - charm_band_center));
    float h = harness * harness_color.a;
    float c = charm * charm_color.a;
    vec3 tint = mix(harness_color.rgb, charm_color.rgb, c);
    ALBEDO = tint;
    EMISSION = tint * emission_energy * max(h, c);
    ALPHA = max(h, c) * 0.78;
}
