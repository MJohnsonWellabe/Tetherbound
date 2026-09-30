shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never;

uniform vec4 ion_colour : source_color = vec4(1.0, 0.82, 0.3, 1.0);
uniform float opacity : hint_range(0.0, 1.0) = 0.95;
uniform float pulse_strength : hint_range(0.0, 0.3) = 0.08;

void fragment() {
    float across = abs(UV.x * 2.0 - 1.0);
    float filament = sin(UV.y * 41.0 + sin(UV.y * 13.0) * 2.0 + TIME * 9.0) * 0.06;
    float core = 1.0 - smoothstep(0.02, 0.12, abs(UV.x * 2.0 - 1.0 + filament));
    float edge = 0.72 + sin(UV.y * 21.0 + TIME * 4.0) * 0.12;
    float corona = pow(1.0 - smoothstep(0.0, edge, across), 1.55);
    float veins = pow(max(0.0, sin(UV.y * 57.0 + across * 13.0 - TIME * 11.0)), 6.0);
    vec3 colour = mix(ion_colour.rgb, vec3(1.0, 0.99, 0.91), core);
    float pulse = 1.0 - pulse_strength * (0.5 + 0.5 * sin(TIME * 17.0 + UV.y * 5.0));
    ALBEDO = colour;
    EMISSION = colour * (0.2 + core * 0.4);
    ALPHA = max(core, corona * (0.5 + veins * 0.5)) * opacity * pulse;
}
