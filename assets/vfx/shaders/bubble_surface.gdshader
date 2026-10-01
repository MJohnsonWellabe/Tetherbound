shader_type spatial;
render_mode cull_back, depth_draw_never, diffuse_burley, specular_schlick_ggx;

// Lit, translucent water film on the existing sphere. No screen texture,
// refraction or GPU particles; vertex positions and transit bounds unchanged.
uniform vec4 water_colour : source_color = vec4(0.46, 0.8, 0.91, 1.0);
uniform vec4 rim_colour : source_color = vec4(0.86, 0.98, 1.0, 1.0);
uniform float opacity = 0.72;
uniform float rim_power = 2.6;
uniform float film_strength = 0.1;
uniform float flow_speed = 0.7;
uniform float center_opacity = 0.045;
uniform float surface_roughness = 0.14;
varying vec3 sphere_direction;

void vertex() {
    sphere_direction = normalize(VERTEX);
}

void fragment() {
    float facing = clamp(dot(normalize(NORMAL), normalize(VIEW)), 0.0, 1.0);
    float rim = pow(1.0 - facing, max(0.5, rim_power));
    // Subtle traveling cool film bands give the bubble a water identity;
    // the center stays transparent so it cannot read as a solid energy orb.
    float thickness = dot(sphere_direction, vec3(1.7, 2.9, 0.8)) + TIME * flow_speed;
    vec3 film = vec3(0.72 + 0.12 * sin(thickness * 4.0),
                    0.83 + 0.10 * sin(thickness * 4.0 + 2.1),
                    0.94 + 0.06 * sin(thickness * 4.0 + 4.2));
    vec3 tint = mix(water_colour.rgb, rim_colour.rgb, rim);
    ALBEDO = mix(tint, film, clamp(film_strength, 0.0, 0.35) * rim);
    ROUGHNESS = clamp(surface_roughness, 0.08, 0.5);
    SPECULAR = 0.55;
    METALLIC = 0.0;
    EMISSION = rim_colour.rgb * rim * 0.035;
    ALPHA = opacity * mix(clamp(center_opacity, 0.0, 0.15), 0.82, rim);
}
