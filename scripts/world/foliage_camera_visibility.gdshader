shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_disabled, diffuse_burley, specular_disabled, alpha_to_coverage_and_one;

// Restricted to the installed nature family's two-sided cutout leaf surfaces.
uniform sampler2D leaf_texture : source_color, filter_linear_mipmap, repeat_enable;
uniform vec4 leaf_tint : source_color = vec4(1.0);
uniform vec4 leaf_backlight : source_color = vec4(0.0);
uniform bool use_vertex_tint = false;
uniform float leaf_roughness = 0.94;
uniform float alpha_cutoff = 0.2;
uniform float alpha_edge = 0.3;
uniform vec3 bounds_center;
uniform vec3 bounds_half_size;
uniform float clear_distance = 5.8;
uniform float opaque_distance = 8.0;
uniform vec4 trainer_rect = vec4(0.455, 0.49, 0.545, 0.73);
uniform float edge_feather = 0.025;
varying float blocks_trainer;

void vertex() {
    // MODELVIEW_MATRIX includes each MultiMesh instance's transform. A view-space
    // AABB projects conservatively around its silhouette, never a batch origin.
    vec3 center = (MODELVIEW_MATRIX * vec4(bounds_center, 1.0)).xyz;
    mat3 basis = mat3(MODELVIEW_MATRIX);
    vec3 extent = abs(basis[0]) * bounds_half_size.x + abs(basis[1]) * bounds_half_size.y + abs(basis[2]) * bounds_half_size.z;
    blocks_trainer = 0.0;
    // Almost all landscape instances are beyond the transition. Skip their
    // eight-corner projection using a conservative bounding sphere.
    // Preserve the source cutout in shadow maps; their matrices describe the
    // light, so applying a gameplay-camera rectangle there would be incorrect.
    if (!IN_SHADOW_PASS && length(center) - length(extent) <= opaque_distance) {
    vec2 lo = vec2(2.0);
    vec2 hi = vec2(-1.0);
    for (int corner = 0; corner < 8; corner++) {
        vec3 sign_corner = vec3((corner & 1) == 0 ? -1.0 : 1.0, (corner & 2) == 0 ? -1.0 : 1.0, (corner & 4) == 0 ? -1.0 : 1.0);
        vec3 point = center + extent * sign_corner;
        point.z = min(point.z, -0.05);
        vec4 clip = PROJECTION_MATRIX * vec4(point, 1.0);
        vec2 screen = clip.xy / clip.w * vec2(0.5, -0.5) + vec2(0.5);
        lo = min(lo, screen);
        hi = max(hi, screen);
    }
    vec2 overlap = min(hi, trainer_rect.zw) - max(lo, trainer_rect.xy);
    blocks_trainer = smoothstep(0.0, edge_feather, min(overlap.x, overlap.y));
    }
}

void fragment() {
    vec4 leaf = texture(leaf_texture, UV) * leaf_tint;
    if (use_vertex_tint) { leaf *= COLOR; }
    ALBEDO = leaf.rgb;
    ALPHA = leaf.a;
    ALPHA_SCISSOR_THRESHOLD = alpha_cutoff;
    ALPHA_ANTIALIASING_EDGE = alpha_edge;
    ALPHA_TEXTURE_COORDINATE = UV * vec2(textureSize(leaf_texture, 0));
    ROUGHNESS = leaf_roughness;
    BACKLIGHT = leaf_backlight.rgb;
    if (blocks_trainer > 0.0) {
    float visibility = mix(1.0, smoothstep(clear_distance, opaque_distance, length(VERTEX)), blocks_trainer);
    // Stable spatial threshold; no time noise or transparent sorting.
    float threshold = fract(52.9829189 * fract(dot(floor(FRAGCOORD.xy), vec2(0.06711056, 0.00583715))));
    if (visibility < threshold) { discard; }
    }
}
