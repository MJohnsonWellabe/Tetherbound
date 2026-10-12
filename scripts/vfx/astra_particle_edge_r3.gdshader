shader_type spatial;
render_mode unshaded, cull_back, depth_draw_never;
// Dark silhouette around an additive particle keeps it legible on pale fur.
uniform vec4 edge_colour : source_color = vec4(0.14, 0.06, 0.31, 1.0);
uniform float opacity = 0.95;
void fragment() {
    float rim = 1.0 - clamp(dot(normalize(NORMAL), normalize(VIEW)), 0.0, 1.0);
    ALBEDO = edge_colour.rgb;
    ALPHA = opacity * smoothstep(0.22, 0.78, rim);
}
