shader_type spatial;
render_mode cull_disabled, diffuse_burley, specular_schlick_ggx;

// Restricted to the installed opaque Mushroom_Laetiporus atlas material.
// Original UVs, triangles and normals are retained; no floating cue geometry.
uniform sampler2D source_texture : source_color, filter_linear_mipmap, repeat_enable;
uniform vec4 source_tint : source_color = vec4(1.0);
uniform bool use_vertex_colour = false;
uniform vec4 cap_shadow : source_color;
uniform vec4 cap_light : source_color;
uniform vec4 gill_shadow : source_color;
uniform vec4 gill_light : source_color;
uniform vec4 rim_colour : source_color;
uniform float rim_energy = 0.12;
uniform float cap_roughness = 0.58;
uniform float gill_roughness = 0.85;
uniform float cap_normal_low = -0.05;
uniform float cap_normal_high = 0.35;
uniform float rim_value_low = 0.63;
uniform float rim_value_high = 0.82;
uniform float rim_saturation_max = 0.32;
varying float cap_facing;

void vertex() {
    // The installed model's local Y is up. Cap/gill separation follows the
    // surface, independent of the player's view or the world light direction.
    cap_facing = smoothstep(cap_normal_low, cap_normal_high, NORMAL.y);
}

void fragment() {
    vec3 source = texture(source_texture, UV).rgb * source_tint.rgb;
    if (use_vertex_colour) {
        source *= COLOR.rgb;
    }
    float value = max(source.r, max(source.g, source.b));
    float least = min(source.r, min(source.g, source.b));
    float saturation = (value - least) / max(value, 0.001);
    float grain = clamp(dot(source, vec3(0.2126, 0.7152, 0.0722)), 0.0, 1.0);
    vec3 cap = mix(cap_shadow.rgb, cap_light.rgb, grain);
    vec3 gills = mix(gill_shadow.rgb, gill_light.rgb, grain);
    ALBEDO = mix(gills, cap, cap_facing);
    ROUGHNESS = mix(gill_roughness, cap_roughness, cap_facing);
    // Only the atlas's pale rim can emit, and only on cap-facing surfaces.
    // No pulse, light node, bloom sheet or broad emissive mushroom body.
    float rim = smoothstep(rim_value_low, rim_value_high, value)
        * (1.0 - smoothstep(rim_saturation_max, rim_saturation_max + 0.08, saturation));
    EMISSION = rim_colour.rgb * rim_energy * rim * cap_facing;
}
