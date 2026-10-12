shader_type spatial;
render_mode cull_disabled;
uniform vec4 blade_colour : source_color = vec4(0.7, 0.9, 0.8, 1.0);
uniform float opacity = 1.0;
void fragment() {
    float facing = abs(dot(normalize(NORMAL), normalize(VIEW)));
    ALBEDO = mix(blade_colour.rgb * 0.18, blade_colour.rgb, smoothstep(0.0, 0.75, facing));
    EMISSION = blade_colour.rgb * facing * 0.18;
    ROUGHNESS = 0.28;
    METALLIC = 0.1;
    ALPHA = opacity;
}
