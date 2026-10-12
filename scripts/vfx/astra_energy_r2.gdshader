shader_type spatial;
render_mode unshaded, cull_back, depth_draw_never;

// Round, depth-tested volumes. The soft silhouette works in Compatibility
// without a bloom pass; the outer shell is a material layer, not a particle.
uniform vec4 energy_colour : source_color = vec4(0.21, 0.75, 1.0, 1.0);
uniform float opacity = 1.0;
uniform float shell_width = 0.0;
uniform bool halo = false;

void vertex() {
    VERTEX += NORMAL * shell_width;
}

void fragment() {
    float facing = clamp(abs(dot(normalize(NORMAL), normalize(VIEW))), 0.0, 1.0);
    float feather = smoothstep(0.0, 0.65, facing);
    float current = 0.5 + 0.5 * sin(UV.y * 39.0 - TIME * 8.0 + sin(UV.y * 17.0 + TIME * 3.0));
    float core = pow(facing, 5.0) * (0.30 + current * 0.18);
    vec3 colour = mix(energy_colour.rgb, vec3(0.88, 0.98, 1.0), core);
    ALBEDO = colour;
    EMISSION = colour * (halo ? 0.18 : 0.45);
    ALPHA = opacity * feather * (halo ? 0.65 : (0.88 + current * 0.12));
}
