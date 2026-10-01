shader_type spatial;
render_mode cull_disabled, depth_draw_never, diffuse_burley;

// Installed scree albedo on the existing eruption facets/chips. The texture
// is reused unchanged; local triplanar direction stays stable through mastery.
// No displacement, emission, screen sampling, light or collision is added.
uniform sampler2D surface_texture : source_color, filter_linear_mipmap, repeat_enable;
uniform vec4 stone_colour : source_color = vec4(0.44, 0.39, 0.32, 1.0);
uniform vec4 mineral_colour : source_color = vec4(0.70, 0.65, 0.54, 1.0);
uniform float surface_scale = 1.2;
uniform float texture_blend = 0.42;
uniform float surface_roughness = 0.90;
uniform float opacity = 1.0;
varying vec3 stone_direction;
varying vec3 stone_normal;

void vertex() {
    stone_direction = normalize(VERTEX);
    stone_normal = NORMAL;
}

void fragment() {
    vec3 weights = pow(abs(stone_normal), vec3(4.0));
    weights /= max(0.001, weights.x + weights.y + weights.z);
    vec3 p = stone_direction * surface_scale;
    vec3 surface = texture(surface_texture, p.yz).rgb * weights.x
                 + texture(surface_texture, p.xz).rgb * weights.y
                 + texture(surface_texture, p.xy).rgb * weights.z;
    float mineral = smoothstep(0.36, 0.60, dot(surface, vec3(0.299, 0.587, 0.114)));
    vec3 tinted = mix(stone_colour.rgb, mineral_colour.rgb, mineral * 0.30);
    ALBEDO = mix(tinted, surface, clamp(texture_blend, 0.0, 1.0));
    ROUGHNESS = clamp(surface_roughness, 0.5, 1.0);
    SPECULAR = 0.16;
    ALPHA = clamp(opacity, 0.0, 1.0);
}
