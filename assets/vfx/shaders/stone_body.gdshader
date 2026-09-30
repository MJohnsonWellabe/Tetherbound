shader_type spatial;
render_mode cull_disabled;

uniform vec4 stone_colour : source_color = vec4(0.36, 0.30, 0.23, 1.0);
uniform vec4 mineral_colour : source_color = vec4(0.63, 0.56, 0.42, 1.0);
uniform float grain_scale = 19.0;
varying vec3 stone_position;

void vertex() { stone_position = VERTEX; }

void fragment() {
    float grain = sin(stone_position.x * grain_scale + sin(stone_position.z * 31.0))
                * sin(stone_position.y * 29.0 + stone_position.z * grain_scale);
    float seams = smoothstep(0.72, 0.95, abs(sin(stone_position.y * 9.0
                  + stone_position.x * 5.0 + sin(stone_position.z * 7.0))));
    ALBEDO = mix(stone_colour.rgb * (0.86 + grain * 0.11), mineral_colour.rgb, seams * 0.31);
    ROUGHNESS = 0.98;
    SPECULAR = 0.12;
}
