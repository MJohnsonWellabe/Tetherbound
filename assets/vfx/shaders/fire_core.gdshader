shader_type spatial;
render_mode unshaded, cull_disabled;

uniform vec4 hot_colour : source_color = vec4(1.0, 0.96, 0.72, 1.0);
uniform vec4 flame_colour : source_color = vec4(1.0, 0.43, 0.025, 1.0);
varying vec3 core_position;

void vertex() { core_position = VERTEX; }

void fragment() {
    // Smooth physical burning core; flames live in separate soft envelopes.
    float facing = max(0.0, dot(normalize(NORMAL), normalize(VIEW)));
    float flow = sin(core_position.y * 5.0 - TIME * 5.0 + sin(core_position.x * 4.0)) * 0.06;
    float heat = clamp(pow(facing, 0.45) + flow, 0.0, 1.0);
    ALBEDO = mix(flame_colour.rgb, hot_colour.rgb, smoothstep(0.12, 0.92, heat));
    EMISSION = ALBEDO * 0.25;
}
