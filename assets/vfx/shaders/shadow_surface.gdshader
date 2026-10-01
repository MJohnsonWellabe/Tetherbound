shader_type spatial;
render_mode cull_back, depth_draw_never, diffuse_burley;

// A moving dark interior with thin cool wisps on the original orb envelope.
// World lighting stays admitted; no new light or screen-space dependency.
uniform vec4 shadow_colour : source_color = vec4(0.15, 0.12, 0.23, 1.0);
uniform vec4 wisp_colour : source_color = vec4(0.57, 0.48, 0.72, 1.0);
uniform float opacity = 0.82;
uniform float flow_speed = 1.6;
uniform float surface_scale = 3.4;
uniform float porosity = 0.35;
uniform float emission_strength = 0.07;
varying vec3 orb_direction;

float hash(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise(vec2 p) {
    vec2 i = floor(p), f = fract(p);
    f = f * f * (3.0 - 2.0 * f);
    return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), f.x),
               mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0)), f.x), f.y);
}

void vertex() {
    orb_direction = normalize(VERTEX);
}

void fragment() {
    float facing = clamp(dot(normalize(NORMAL), normalize(VIEW)), 0.0, 1.0);
    vec2 field = orb_direction.xy * surface_scale +
                 vec2(orb_direction.z * 1.7 + TIME * flow_speed, -TIME * flow_speed * 0.53);
    float broad = noise(field);
    float fine = noise(field * 2.07 + vec2(4.3, -2.1));
    float density = broad * 0.7 + fine * 0.3;
    float folds = 1.0 - smoothstep(0.025, 0.11, abs(density - 0.53));
    float rim = pow(1.0 - facing, 2.1);
    float wisp = clamp(folds * 0.45 + rim * 0.55, 0.0, 1.0);
    ALBEDO = mix(shadow_colour.rgb, wisp_colour.rgb, wisp);
    ROUGHNESS = 0.65;
    SPECULAR = 0.18;
    EMISSION = wisp_colour.rgb * folds * clamp(emission_strength, 0.0, 0.2);
    float pores = smoothstep(0.2, 0.66, density + facing * 0.18);
    ALPHA = opacity * mix(1.0, pores, clamp(porosity, 0.0, 0.6)) * smoothstep(0.0, 0.18, facing);
}
