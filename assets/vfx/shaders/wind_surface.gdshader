shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never;

// Camera-independent air streaks on the existing crescent vertices. This
// introduces no vertex displacement, screen sampling, collision or particles.
uniform vec4 air_colour : source_color = vec4(0.75, 0.91, 0.92, 1.0);
uniform vec4 crest_colour : source_color = vec4(0.95, 1.0, 0.98, 1.0);
uniform float opacity = 0.72;
uniform float flow_speed = 3.1;
uniform float strand_frequency = 5.0;
uniform float breakup = 0.38;
uniform float emission_strength = 0.04;
varying vec3 air_position;

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
    air_position = VERTEX;
}

void fragment() {
    vec2 direction = normalize(air_position.xz + vec2(0.00001));
    float angle = atan(direction.y, direction.x);
    float flow = TIME * flow_speed;
    // Directional coordinates keep strand density stable through mastery.
    float field = noise(direction * strand_frequency + vec2(flow, -flow * 0.43));
    float detail = noise(direction * strand_frequency * 2.07 + vec2(-flow * 0.31, flow));
    float strand = smoothstep(0.26, 0.7, field * 0.68 + detail * 0.32);
    float crest = pow(0.5 + 0.5 * sin(angle * 4.0 - flow), 3.0);
    ALBEDO = mix(air_colour.rgb, crest_colour.rgb, strand * 0.65 + crest * 0.25);
    EMISSION = ALBEDO * clamp(emission_strength, 0.0, 0.15) * strand;
    ALPHA = opacity * mix(1.0, strand, clamp(breakup, 0.0, 0.8));
}
