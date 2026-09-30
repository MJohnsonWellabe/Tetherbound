shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never;

// Soft procedural silhouettes, no sampled solid shell or copied texture.
uniform vec4 hot_colour : source_color = vec4(1.0, 0.95, 0.68, 1.0);
uniform vec4 flame_colour : source_color = vec4(1.0, 0.34, 0.025, 1.0);
uniform vec4 ember_colour : source_color = vec4(0.56, 0.07, 0.01, 1.0);
uniform float opacity : hint_range(0.0, 1.0) = 0.95;
uniform float flow_speed = 2.4;
uniform bool billboard = true;
uniform bool dust = false;
// 0 burning body, 1 continuous trail, 2 expanding burst, 3 ember.
uniform int effect_mode = 0;
varying float phase_seed;

float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float noise(vec2 p) {
    vec2 cell = floor(p);
    vec2 f = fract(p);
    f = f * f * (3.0 - 2.0 * f);
    return mix(mix(hash(cell), hash(cell + vec2(1.0, 0.0)), f.x),
               mix(hash(cell + vec2(0.0, 1.0)), hash(cell + vec2(1.0)), f.x), f.y);
}
float smoke(vec2 p) {
    return noise(p) * 0.57 + noise(p * 2.03 + 8.1) * 0.28 + noise(p * 4.09 - 3.7) * 0.15;
}

void vertex() {
    phase_seed = INSTANCE_CUSTOM.x * 6.283185;
    if (billboard) {
        vec3 scale = vec3(length(MODEL_MATRIX[0].xyz), length(MODEL_MATRIX[1].xyz), length(MODEL_MATRIX[2].xyz));
        MODELVIEW_MATRIX = VIEW_MATRIX * mat4(INV_VIEW_MATRIX[0] * scale.x,
            INV_VIEW_MATRIX[1] * scale.y, INV_VIEW_MATRIX[2] * scale.z, MODEL_MATRIX[3]);
    }
}

void fragment() {
    vec2 p = vec2(UV.x * 2.0 - 1.0, 1.0 - UV.y * 2.0);
    float time = TIME * flow_speed + phase_seed;
    float billow = smoke(p * 3.0 + vec2(0.23 * time, -time));
    float heat;
    float mask;
    if (effect_mode == 1) {
        // UV.y spans the entire ribbon; it does not restart per segment.
        float front = UV.y;
        float swirl = (smoke(vec2(front * 5.0 - time, p.x * 1.6)) - 0.5) * 0.28;
        float across = abs(p.x + swirl * (1.0 - front));
        float width = mix(0.16, 0.92, smoothstep(0.0, 1.0, front));
        mask = (1.0 - smoothstep(width * 0.18, width, across)) * smoothstep(0.0, 0.22, front);
        mask *= mix(0.32, 1.0, billow);
        heat = clamp(front * 0.68 + (1.0 - across) * 0.32 + (billow - 0.5) * 0.25, 0.0, 1.0);
    } else {
        float radius = length(p * vec2(1.0, effect_mode == 0 ? 0.91 : 1.0));
        float edge = 0.75 + (billow - 0.5) * (effect_mode == 3 ? 0.04 : 0.24);
        mask = 1.0 - smoothstep(edge * 0.30, edge, radius);
        heat = clamp(1.0 - radius * 0.90 + (billow - 0.5) * 0.48, 0.0, 1.0);
        if (effect_mode == 2) mask *= mix(0.5, 1.0, billow);
    }
    vec3 colour = mix(ember_colour.rgb, flame_colour.rgb, smoothstep(0.06, 0.62, heat));
    colour = mix(colour, hot_colour.rgb, smoothstep(0.63, 0.96, heat));
    if (dust) colour = flame_colour.rgb * mix(0.75, 1.07, billow);
    ALBEDO = colour;
    EMISSION = dust ? vec3(0.0) : colour * 0.20;
    ALPHA = clamp(mask * opacity, 0.0, 1.0);
}
