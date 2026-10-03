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
// Texture tiles per metre of rock so a boulder gets real detail instead of
// one stretched tile; 0 keeps the older size-independent mapping.
uniform float texture_tiles_per_m = 1.6;
varying vec3 stone_position;
varying vec3 stone_direction;
varying vec3 stone_normal;

void vertex() {
    stone_position = VERTEX;
    stone_direction = normalize(VERTEX);
    stone_normal = NORMAL;
}

void fragment() {
    // Grain and seams follow the normalized direction, so pebbles and
    // boulders share one scale-invariant pattern instead of a boulder
    // collecting dozens of fine stripes from raw object-space position.
    vec3 g = stone_direction * 2.4;
    float grain = sin(g.x * grain_scale * 0.35 + sin(g.z * 5.0))
                * sin(g.y * 5.3 + g.z * grain_scale * 0.35);
    float seams = smoothstep(0.72, 0.95, abs(sin(g.y * 2.2
                  + g.x * 1.3 + sin(g.z * 1.7))));
    ALBEDO = mix(stone_colour.rgb * (0.86 + grain * 0.11), mineral_colour.rgb, seams * 0.31);
    ROUGHNESS = 0.98;
    SPECULAR = 0.12;
    if (authored_surface) {
        // Reuse the installed stylised scree surface on the existing facets.
        // Local normalized coordinates keep its scale stable across mastery;
        // triplanar projection needs no UV seam or new mesh/import writer.
        vec3 weights = pow(abs(stone_normal), vec3(4.0));
        weights /= max(0.001, weights.x + weights.y + weights.z);
        float radius = max(0.01, length(stone_position));
        vec3 p = texture_tiles_per_m > 0.0
            ? stone_direction * max(surface_scale, radius * texture_tiles_per_m)
            : stone_direction * surface_scale;
        vec3 surface = texture(surface_texture, p.yz).rgb * weights.x
                     + texture(surface_texture, p.xz).rgb * weights.y
                     + texture(surface_texture, p.xy).rgb * weights.z;
        float luma = dot(surface, vec3(0.299, 0.587, 0.114));
        float mineral = smoothstep(0.36, 0.6, luma);
        vec3 tinted = mix(stone_colour.rgb, mineral_colour.rgb, mineral * 0.28);
        // Detail is multiplied into the earthy tint (dark crevices, lit
        // ridges) instead of mixed toward the pale scree, which washed the
        // whole body out to grey-white under the Meadows sun.
        vec3 detailed = tinted * mix(1.0, 0.45 + luma * 1.25, clamp(texture_blend, 0.0, 1.0));
        float crevice = smoothstep(0.55, 0.95, abs(grain)) * seams;
        ALBEDO = detailed * (1.0 - crevice * 0.35);
        ROUGHNESS = clamp(surface_roughness, 0.5, 1.0);
        SPECULAR = 0.19;
    }
}
