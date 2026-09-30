shader_type spatial;
render_mode cull_disabled;

uniform vec4 stone_colour : source_color = vec4(0.36, 0.30, 0.23, 1.0);
uniform vec4 mineral_colour : source_color = vec4(0.63, 0.56, 0.42, 1.0);
uniform float grain_scale = 19.0;
uniform sampler2D surface_texture : source_color, filter_linear_mipmap, repeat_enable;
uniform bool authored_surface = false;
uniform float surface_scale = 1.35;
uniform float texture_blend = 0.52;
uniform float surface_roughness = 0.88;
varying vec3 stone_position;
varying vec3 stone_direction;
varying vec3 stone_normal;

void vertex() {
    stone_position = VERTEX;
    stone_direction = normalize(VERTEX);
    stone_normal = NORMAL;
}

void fragment() {
    float grain = sin(stone_position.x * grain_scale + sin(stone_position.z * 31.0))
                * sin(stone_position.y * 29.0 + stone_position.z * grain_scale);
    float seams = smoothstep(0.72, 0.95, abs(sin(stone_position.y * 9.0
                  + stone_position.x * 5.0 + sin(stone_position.z * 7.0))));
    ALBEDO = mix(stone_colour.rgb * (0.86 + grain * 0.11), mineral_colour.rgb, seams * 0.31);
    ROUGHNESS = 0.98;
    SPECULAR = 0.12;
    if (authored_surface) {
        // Reuse the installed stylised scree surface on the existing facets.
        // Local normalized coordinates keep its scale stable across mastery;
        // triplanar projection needs no UV seam or new mesh/import writer.
        vec3 weights = pow(abs(stone_normal), vec3(4.0));
        weights /= max(0.001, weights.x + weights.y + weights.z);
        vec3 p = stone_direction * surface_scale;
        vec3 surface = texture(surface_texture, p.yz).rgb * weights.x
                     + texture(surface_texture, p.xz).rgb * weights.y
                     + texture(surface_texture, p.xy).rgb * weights.z;
        float mineral = smoothstep(0.36, 0.6, dot(surface, vec3(0.299, 0.587, 0.114)));
        vec3 tinted = mix(stone_colour.rgb, mineral_colour.rgb, mineral * 0.28);
        ALBEDO = mix(tinted, surface, clamp(texture_blend, 0.0, 1.0));
        ROUGHNESS = clamp(surface_roughness, 0.5, 1.0);
        SPECULAR = 0.19;
    }
}
