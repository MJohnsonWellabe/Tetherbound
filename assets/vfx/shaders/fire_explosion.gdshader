shader_type spatial;
render_mode cull_disabled, depth_draw_never, diffuse_burley;

// Expanding flame billows: a noisy, broken silhouette and hot interior,
// rather than the generic solid impact spokes. Local presentation only.
uniform vec4 hot_colour : source_color = vec4(1.0, 0.94, 0.66, 1.0);
uniform vec4 flame_colour : source_color = vec4(1.0, 0.35, 0.035, 1.0);
uniform vec4 ember_colour : source_color = vec4(0.52, 0.075, 0.015, 1.0);
uniform float opacity = 0.95;
uniform float flow_speed = 3.2;
uniform float emission_strength = 0.45;
uniform float edge_breakup = 0.19;
uniform float porosity = 0.62;
uniform float curl_scale = 6.0;
uniform float heat_warp = 0.22;
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
    vec2 curl = vec2(noise(p * curl_scale + vec2(0.17 * time, -time)),
        noise(p * curl_scale + vec2(5.3, -0.73 * time)));
    float radius = length((p + (curl - vec2(0.5)) * clamp(heat_warp, 0.0, 0.3)) * vec2(1.0, 0.93));
    float edge = 0.63 + lobes + (n - 0.5) * edge_breakup + rising;
    float mask = 1.0 - smoothstep(edge - 0.11, edge + 0.025, radius);
    float curls = smoothstep(0.28, 0.78, n * 0.72 + fine * 0.28);
    float interior = clamp(1.0 - radius / max(edge, 0.1), 0.0, 1.0);
    float density = smoothstep(0.22, 0.65, n * 0.63 + fine * 0.37 + interior * 0.18);
    // Narrow hot folds inside advected pores give the burst layered flame
    // detail without adding generic polygon spokes or extra emitters.
    float folds = 1.0 - smoothstep(0.025, 0.14, abs(n * 0.72 + fine * 0.28 - 0.55));
    float heat = clamp(interior * 0.48 + curls * 0.42 + folds * 0.24, 0.0, 1.0);
    vec3 colour = mix(ember_colour.rgb, flame_colour.rgb, smoothstep(0.07, 0.40, heat));
    colour = mix(colour, hot_colour.rgb, smoothstep(0.60, 0.94, heat));
    ALBEDO = colour;
    // Curved view-space normals admit the same local world/light interaction
    // as the dust cards, while hot folds carry their own bounded emission.
    NORMAL = normalize(vec3(p.x * 0.5, -p.y * 0.5, sqrt(max(0.15, 1.0 - dot(p, p) * 0.5))));
    ROUGHNESS = 0.9;
    SPECULAR = 0.0;
    EMISSION = colour * emission_strength * (0.25 + smoothstep(0.28, 0.90, heat) * 0.75);
    ALPHA = mask * opacity * mix(1.0, density, clamp(porosity, 0.0, 1.0));
}
