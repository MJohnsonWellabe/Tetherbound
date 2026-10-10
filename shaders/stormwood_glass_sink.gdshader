shader_type spatial;
render_mode cull_disabled;

uniform vec2 basin_centre;
uniform float inner_radius = 238.0;
uniform float outer_radius = 718.0;
uniform vec4 glass_colour : source_color = vec4(0.141, 0.235, 0.251, 1.0);
uniform vec4 facet_colour : source_color = vec4(0.275, 0.384, 0.4, 1.0);
uniform vec4 seam_colour : source_color = vec4(0.451, 0.565, 0.502, 1.0);
uniform float fracture_scale = 0.085;
uniform float seam_width = 0.022;
uniform float roughness = 0.31;
uniform float metallic = 0.18;
varying vec3 surface_position;

vec2 fracture_point(vec2 cell) {
    return fract(sin(vec2(dot(cell, vec2(127.1, 311.7)),
        dot(cell, vec2(269.5, 183.3)))) * 43758.5453);
}

void vertex() {
    surface_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
    vec2 point = surface_position.xz;
    float radius = length(point - basin_centre);
    float edge_noise = sin(point.x * 0.21) * sin(point.y * 0.17);
    // Irregular feathered margins leave the island's living ground intact.
    if (radius < inner_radius + 2.5 + edge_noise * 2.0 ||
        radius > outer_radius - 3.0 + edge_noise * 2.0) {
        discard;
    }
    vec2 p = point * fracture_scale;
    vec2 cell = floor(p);
    vec2 offset = fract(p);
    float first = 10.0;
    float second = 10.0;
    vec2 nearest_cell = cell;
    for (int x = -1; x <= 1; x++) {
        for (int y = -1; y <= 1; y++) {
            vec2 neighbour = vec2(float(x), float(y));
            vec2 delta = neighbour + fracture_point(cell + neighbour) - offset;
            float d = dot(delta, delta);
            if (d < first) {
                second = first;
                first = d;
                nearest_cell = cell + neighbour;
            } else {
                second = min(second, d);
            }
        }
    }
    float edge = sqrt(second) - sqrt(first);
    float line = 1.0 - smoothstep(seam_width, seam_width + max(fwidth(edge), 0.005), edge);
    vec2 grain = fracture_point(nearest_cell);
    float facet = 0.25 + grain.x * 0.6;
    float cloud = sin(point.x * 0.006 + sin(point.y * 0.012)) * 0.5 + 0.5;
    vec3 body = mix(glass_colour.rgb, facet_colour.rgb, facet * 0.65 + cloud * 0.12);
    ALBEDO = mix(body, seam_colour.rgb, line * 0.48);
    ROUGHNESS = clamp(roughness + grain.y * 0.18 + line * 0.22, 0.1, 0.9);
    METALLIC = metallic;
    SPECULAR = 0.55;
    // Static facets catch the real sky and lightning; they do not emit light.
}
