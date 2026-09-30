shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_opaque;

uniform vec4 hot_colour : source_color = vec4(1.0, 0.94, 0.65, 1.0);
uniform vec4 flame_colour : source_color = vec4(1.0, 0.33, 0.025, 1.0);
uniform vec4 ember_colour : source_color = vec4(0.45, 0.055, 0.012, 1.0);
uniform float opacity : hint_range(0.0, 1.0) = 1.0;
uniform float turbulence = 0.075;
uniform float flow_speed = 2.4;
varying vec3 flame_position;

float field(vec3 p) {
    return sin(p.x * 7.1 + sin(p.z * 4.3)) * sin(p.y * 6.7 + p.z * 2.1)
         + 0.42 * sin(p.x * 15.3 - p.y * 10.9 + p.z * 8.7);
}

void vertex() {
    flame_position = VERTEX;
    float tongues = field(VERTEX * 2.0 + vec3(0.0, -TIME * flow_speed, TIME * 0.35));
    VERTEX += NORMAL * tongues * turbulence;
}

void fragment() {
    float heat = clamp(0.52 + field(flame_position * 2.4 + vec3(0.0, -TIME * flow_speed, 0.0)) * 0.30, 0.0, 1.0);
    vec3 colour = mix(ember_colour.rgb, flame_colour.rgb, smoothstep(0.03, 0.56, heat));
    colour = mix(colour, hot_colour.rgb, smoothstep(0.58, 0.93, heat));
    ALBEDO = colour;
    EMISSION = colour * 0.30;
    ALPHA = opacity;
}
