shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_back;

// A second surface over the installed stone keeps its painted rock and
// normals intact. Object-space veins stay attached when the model is scaled.
uniform vec3 bound_min;
uniform vec3 bound_size = vec3(1.0);
uniform vec4 charge_colour : source_color = vec4(0.60, 0.87, 0.80, 1.0);
uniform float charge_energy = 1.1;
uniform float vein_scale = 4.6;
uniform float vein_width = 0.035;
uniform float pulse_depth = 0.12;
uniform float pulse_speed = 0.7;
varying vec3 stone_position;

vec3 cell_point(vec3 cell) {
    return fract(sin(vec3(dot(cell, vec3(127.1, 311.7, 74.7)),
        dot(cell, vec3(269.5, 183.3, 246.1)),
        dot(cell, vec3(113.5, 271.9, 124.6)))) * 43758.5453);
}

void vertex() {
    stone_position = (VERTEX - bound_min) / max(bound_size, vec3(0.001));
    VERTEX += NORMAL * 0.001;
}

void fragment() {
    vec3 p = stone_position * vein_scale;
    vec3 cell = floor(p);
    vec3 offset = fract(p);
    float first = 10.0;
    float second = 10.0;
    for (int x = -1; x <= 1; x++) {
        for (int y = -1; y <= 1; y++) {
            for (int z = -1; z <= 1; z++) {
                vec3 neighbour = vec3(float(x), float(y), float(z));
                vec3 delta = neighbour + cell_point(cell + neighbour) - offset;
                float distance_squared = dot(delta, delta);
                if (distance_squared < first) {
                    second = first;
                    first = distance_squared;
                } else {
                    second = min(second, distance_squared);
                }
            }
        }
    }
    float vein = 1.0 - smoothstep(vein_width * 0.3, vein_width, second - first);
    float pulse = 1.0 - pulse_depth + pulse_depth * (0.5 + 0.5 * sin(TIME * pulse_speed));
    ALBEDO = charge_colour.rgb * charge_energy * pulse;
    ALPHA = vein;
}
