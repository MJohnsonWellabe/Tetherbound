shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never;

// Expanding flame billows: a noisy, broken silhouette and hot interior,
// rather than the generic solid impact spokes. Local presentation only.
uniform vec4 hot_colour : source_color = vec4(1.0, 0.94, 0.66, 1.0);
uniform vec4 flame_colour : source_color = vec4(1.0, 0.35, 0.035, 1.0);
uniform vec4 ember_colour : source_color = vec4(0.52, 0.075, 0.015, 1.0);
uniform float opacity = 0.95;
uniform float flow_speed = 3.2;
uniform float emission_strength = 0.45;
uniform float edge_breakup = 0.19;
varying float phase_seed;

float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float noise(vec2 p) {
    vec2 i = floor(p), f = fract(p);
    f = f * f * (3.0 - 2.0 * f);
    return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), f.x),
               mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0)), f.x), f.y);
}
float billows(vec2 p) {
    return noise(p) * 0.58 + noise(p * 2.07 + 5.2) * 0.28 + noise(p * 4.13 - 3.7) * 0.14;
}
void vertex() {
    phase_seed = INSTANCE_CUSTOM.x * 6.283185;
    vec3 scale = vec3(length(MODEL_MATRIX[0].xyz), length(MODEL_MATRIX[1].xyz), length(MODEL_MATRIX[2].xyz));
    MODELVIEW_MATRIX = VIEW_MATRIX * mat4(INV_VIEW_MATRIX[0] * scale.x,
        INV_VIEW_MATRIX[1] * scale.y, INV_VIEW_MATRIX[2] * scale.z, MODEL_MATRIX[3]);
}
void fragment() {
    vec2 p = vec2(UV.x * 2.0 - 1.0, 1.0 - UV.y * 2.0);
    float time = TIME * flow_speed + phase_seed;
    vec2 advected = p * 4.0 + vec2(0.2 * time, -time);
    float n = billows(advected);
    float fine = billows(advected * 1.8 + vec2(2.1, -0.5 * time));
    float angle = atan(p.y, p.x);
    float lobes = sin(angle * 5.0 + phase_seed) * 0.055 + sin(angle * 9.0 - 0.3 * time) * 0.035;
    // The upper edge stretches into short flickering tongues; the lower
    // edge stays rounded. No card edge survives outside the noisy flame.
    float rising = max(p.y, 0.0) * (n - 0.35) * 0.14;
    float radius = length(p * vec2(1.0, 0.93));
    float edge = 0.63 + lobes + (n - 0.5) * edge_breakup + rising;
    float mask = 1.0 - smoothstep(edge - 0.11, edge + 0.025, radius);
    float curls = smoothstep(0.28, 0.78, n * 0.72 + fine * 0.28);
    float heat = clamp((1.0 - radius / max(edge, 0.1)) * 0.72 + curls * 0.49, 0.0, 1.0);
    vec3 colour = mix(ember_colour.rgb, flame_colour.rgb, smoothstep(0.07, 0.40, heat));
    colour = mix(colour, hot_colour.rgb, smoothstep(0.60, 0.94, heat));
    ALBEDO = colour;
    EMISSION = colour * emission_strength * smoothstep(0.28, 0.90, heat);
    ALPHA = mask * opacity;
}
