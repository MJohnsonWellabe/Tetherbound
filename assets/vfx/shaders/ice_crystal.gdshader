shader_type spatial;
render_mode cull_disabled, diffuse_burley, specular_schlick_ggx;

// Existing triangular prism faces and their authored tip/ring UVs define
// the frosted edges. No periodic stripes, new geometry, refraction or light.
uniform vec4 ice_colour : source_color = vec4(0.41, 0.73, 0.84, 1.0);
uniform vec4 frost_colour : source_color = vec4(0.84, 0.94, 0.96, 1.0);
uniform float edge_width = 0.055;
uniform float frost_strength = 0.36;
uniform float facet_variation = 0.16;
uniform float surface_roughness = 0.22;
uniform float specular_strength = 0.55;
uniform float emission_strength = 0.015;
varying vec3 facet_direction;

void vertex() {
    facet_direction = NORMAL;
}

void fragment() {
    // Current ice_crystal geometry puts the widest ring at UV.y=.3 and
    // shared upper/lower tip at (UV.x=.5, UV.y=1/0), respectively.
    float half_width = UV.y >= 0.3 ? (1.0 - UV.y) / 1.4 : UV.y / 0.6;
    float edge_distance = max(0.0, half_width - abs(UV.x - 0.5));
    float edge = 1.0 - smoothstep(0.0, max(0.001, edge_width), edge_distance);
    float shoulder = 1.0 - smoothstep(0.0, max(0.001, edge_width) * 0.55, abs(UV.y - 0.3));
    float frost = clamp((edge * 0.8 + shoulder * 0.2) * frost_strength, 0.0, 0.65);
    vec3 direction = normalize(facet_direction);
    float facet = clamp(direction.x * 0.4 + direction.z * 0.6, -1.0, 1.0);
    vec3 base = ice_colour.rgb * (1.0 + facet * clamp(facet_variation, 0.0, 0.25));
    ALBEDO = mix(base, frost_colour.rgb, frost);
    ROUGHNESS = clamp(surface_roughness + frost * 0.3, 0.08, 0.7);
    SPECULAR = clamp(specular_strength, 0.0, 0.8);
    EMISSION = frost_colour.rgb * frost * clamp(emission_strength, 0.0, 0.08);
}
