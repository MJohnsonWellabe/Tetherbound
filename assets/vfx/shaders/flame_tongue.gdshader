shader_type spatial;
render_mode cull_disabled, depth_draw_never, diffuse_burley;

uniform sampler2D flame_texture : source_color, filter_linear_mipmap, repeat_disable;
uniform float opacity = 0.9;
uniform float flow_speed = 3.2;
uniform float emission_strength = 0.45;
uniform bool billboard = false;
uniform float sprite_angle = 0.0;
uniform vec4 flame_colour : source_color = vec4(1.0);
uniform vec4 hot_colour : source_color = vec4(1.0, 0.94, 0.66, 1.0);
uniform bool trail = false;
uniform float breakup_strength = 0.0;
varying float phase;

float flame_hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float flame_noise(vec2 p) {
    vec2 i = floor(p), f = fract(p);
    f = f * f * (3.0 - 2.0 * f);
    return mix(mix(flame_hash(i), flame_hash(i + vec2(1.0, 0.0)), f.x),
               mix(flame_hash(i + vec2(0.0, 1.0)), flame_hash(i + vec2(1.0, 1.0)), f.x), f.y);
}

void vertex() {
    phase = INSTANCE_CUSTOM.x * 6.283185;
    float bend = sin(TIME * flow_speed + VERTEX.y * 3.0 + phase);
    VERTEX.x += bend * 0.025 * abs(VERTEX.y);
    if (billboard) {
        float c = cos(sprite_angle), s = sin(sprite_angle);
        VERTEX.xy = mat2(vec2(c,s),vec2(-s,c)) * VERTEX.xy;
        vec3 scale = vec3(length(MODEL_MATRIX[0].xyz),length(MODEL_MATRIX[1].xyz),length(MODEL_MATRIX[2].xyz));
        MODELVIEW_MATRIX = VIEW_MATRIX * mat4(INV_VIEW_MATRIX[0]*scale.x,INV_VIEW_MATRIX[1]*scale.y,INV_VIEW_MATRIX[2]*scale.z,MODEL_MATRIX[3]);
    }
}

void fragment() {
    vec4 painted = texture(flame_texture, UV);
    ALBEDO = mix(painted.rgb, painted.rgb * flame_colour.rgb, 0.2);
    float alpha = painted.a;
    if (breakup_strength > 0.0) {
        float clock = TIME * flow_speed + phase;
        vec2 flow = vec2(UV.x * 5.5 + sin(UV.y * 11.0 - clock * 0.7) * 0.6, UV.y * 8.0 - clock);
        float curls = flame_noise(flow) * 0.68 + flame_noise(flow * 2.03 + 7.4) * 0.32;
        float dissolve = smoothstep(0.23, 0.68, curls);
        alpha *= mix(1.0, dissolve, clamp(breakup_strength, 0.0, 1.0));
        if (trail) {
            // Ribbon UV runs from the oldest sample (0) to the body (1).
            // Wisps taper and dissolve along that existing continuous path;
            // neither the trail leases nor its geometry/history grow.
            float center = UV.x - 0.5 + sin(UV.y * 12.0 - clock * 0.85) * 0.06;
            float width = mix(0.12, 0.39, UV.y);
            float feather = (1.0 - smoothstep(width * 0.38, width, abs(center))) * smoothstep(0.0, 0.18, UV.y);
            float wisp = feather * dissolve;
            alpha = mix(alpha, clamp(alpha * 0.5 + wisp * 0.55, 0.0, 1.0), clamp(breakup_strength, 0.0, 1.0));
            vec3 heat = mix(flame_colour.rgb, hot_colour.rgb, smoothstep(0.46, 0.83, curls) * smoothstep(0.12, 0.9, UV.y));
            ALBEDO = mix(heat, ALBEDO, painted.a * 0.55);
        }
    }
    EMISSION = (breakup_strength > 0.0 ? ALBEDO : painted.rgb) * emission_strength;
    ROUGHNESS = 0.75;
    SPECULAR = 0.0;
    ALPHA = alpha * opacity;
}
