shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;

// Opaque mineral with authored facet planes: no screen reads, transparent sort,
// bloom, depth textures or Forward+-only features. Glow is internal colour.
uniform vec4 deep_blue : source_color = vec4(0.06, 0.20, 0.40, 1.0);
uniform vec4 facet_blue : source_color = vec4(0.30, 0.62, 0.80, 1.0);
uniform vec4 heart_white : source_color = vec4(0.70, 0.94, 1.0, 1.0);
uniform float glow_strength : hint_range(0.0, 2.0) = 1.0;
uniform float edge_strength : hint_range(0.0, 1.0) = 0.24;
varying vec3 mineral_position;

void vertex() {
    mineral_position = VERTEX;
}

void fragment() {
    float tone = clamp(COLOR.r, 0.15, 0.9);
    float edge_distance = min(min(UV.x, 1.0 - UV.x), min(UV.y, 1.0 - UV.y));
    float edge = 1.0 - smoothstep(0.004, 0.022, edge_distance);
    vec3 core_delta = (mineral_position - vec3(0.0, 4.8, 0.0)) / vec3(1.9, 3.5, 2.0);
    float core = exp(-dot(core_delta, core_delta));
    float internal_plane = pow(max(0.0, 1.0 - abs(UV.x - 0.46) * 1.8), 5.0);
    float facing = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 3.0);
    vec3 body = mix(deep_blue.rgb, facet_blue.rgb, tone);
    ALBEDO = mix(body, heart_white.rgb, core * 0.45 + edge * 0.10);
    METALLIC = 0.16;
    ROUGHNESS = 0.31;
    SPECULAR = 0.65;
    EMISSION = glow_strength * (heart_white.rgb * core * (0.38 + internal_plane * 0.65)
        + facet_blue.rgb * (edge * edge_strength + facing * 0.16));
}
