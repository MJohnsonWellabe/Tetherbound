shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never;

uniform vec4 ion_colour : source_color = vec4(1.0, 0.82, 0.3, 1.0);
uniform float opacity : hint_range(0.0, 1.0) = 0.95;
uniform float pulse_strength : hint_range(0.0, 0.3) = 0.08;
uniform float core_width = 0.12;
uniform float corona_width = 0.72;
uniform float corona_opacity = 0.5;
uniform float emission_floor = 0.2;
uniform float emission_strength = 0.4;

void fragment() {
    float across = abs(UV.x * 2.0 - 1.0);
    float filament = sin(UV.y * 41.0 + sin(UV.y * 13.0) * 2.0 + TIME * 9.0) * 0.06;
    float width = clamp(core_width, 0.04, 0.5);
    float core = 1.0 - smoothstep(width / 6.0, width, abs(UV.x * 2.0 - 1.0 + filament));
    float edge = clamp(corona_width, 0.3, 0.96) + sin(UV.y * 21.0 + TIME * 4.0) * 0.12;
    float corona = pow(1.0 - smoothstep(0.0, edge, across), 1.55);
    float veins = pow(max(0.0, sin(UV.y * 57.0 + across * 13.0 - TIME * 11.0)), 6.0);
    vec3 colour = mix(ion_colour.rgb, vec3(1.0, 0.99, 0.91), core);
    float pulse = 1.0 - pulse_strength * (0.5 + 0.5 * sin(TIME * 17.0 + UV.y * 5.0));
    ALBEDO = colour;
    EMISSION = colour * (emission_floor + core * emission_strength);
    float sheath = clamp(corona_opacity, 0.0, 1.0);
    ALPHA = max(core, corona * (sheath + veins * (1.0 - sheath))) * opacity * pulse;
}
