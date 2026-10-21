shader_type spatial;
render_mode blend_mix, depth_draw_never, cull_back, diffuse_burley, specular_schlick_ggx;

uniform sampler2D source_albedo : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D source_normal : hint_normal, filter_linear_mipmap, repeat_enable;
uniform sampler2D source_emission : source_color, filter_linear_mipmap, repeat_enable;
uniform vec2 source_uv_scale = vec2(1.0);
uniform vec2 source_uv_offset = vec2(0.0);
uniform vec4 source_tint : source_color = vec4(1.0);
uniform bool has_emission_texture = false;
uniform float emission_gain = 0.0;
uniform bool has_normal = false;
uniform float normal_strength = 1.0;
uniform float surface_roughness = 0.8;
uniform float surface_metallic = 0.0;
uniform float rim_amount = 0.0;
uniform float repaint_strength = 0.0;
uniform vec2 body_source_hue = vec2(0.0, 1.0);
uniform float body_source_saturation = 0.0;
uniform float base_value_scale = 1.0;
uniform float body_hue = 0.5;
uniform float body_saturation = 0.3;
uniform float body_value_floor = 0.0;
uniform float body_value_scale = 1.0;
uniform vec2 accent_source_hue = vec2(0.0, 1.0);
uniform float accent_source_value = 0.5;
uniform float accent_source_saturation = 0.3;
uniform float accent_hue = 0.5;
uniform float accent_saturation = 0.5;
uniform float accent_value = 0.8;
uniform float accent_energy = 0.0;
// P2-030/P2-018 shiny fallback: rotate the source hue instead of a flat tint,
// so pattern, value and features survive. Grey regions take shift_grey_hue.
uniform bool shift_enabled = false;
uniform float shift_hue = 0.5;
uniform float shift_grey_hue = 0.12;
uniform float shift_saturation_scale = 1.0;
uniform float shift_saturation_floor = 0.0;
uniform float shift_value_scale = 1.0;
uniform float shift_value_floor = 0.0;
// Value band kept as dark painted features. Near-black coats lower it so a
// shiny repaint is not masked out entirely.
uniform vec2 feature_value = vec2(0.055, 0.18);
// Self-lit floor for repaints over near-black coats, whose emission mask is dark.
uniform float emission_floor = 0.0;

vec3 to_hsv(vec3 c) {
    vec4 k = vec4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
    vec4 p = mix(vec4(c.bg, k.wz), vec4(c.gb, k.xy), step(c.b, c.g));
    vec4 q = mix(vec4(p.xyw, c.r), vec4(c.r, p.yzx), step(p.x, c.r));
    float d = q.x - min(q.w, q.y);
    return vec3(abs(q.z + (q.w - q.y) / (6.0 * d + 0.00001)), d / (q.x + 0.00001), q.x);
}

vec3 from_hsv(vec3 c) {
    vec3 p = abs(fract(c.xxx + vec3(0.0, 2.0 / 3.0, 1.0 / 3.0)) * 6.0 - 3.0);
    return c.z * mix(vec3(1.0), clamp(p - 1.0, 0.0, 1.0), c.y);
}

// Red and oxblood belong to Team Tether; hot magenta was the old fallback.
float shiny_safe_hue(float h) {
    h = fract(h);
    if (h >= 0.86) return 0.78;
    if (h < 0.045) return 0.075;
    return h;
}

void fragment() {
    vec2 uv = UV * source_uv_scale + source_uv_offset;
    vec4 source = texture(source_albedo, uv);
    vec3 hsv = to_hsv(source.rgb);
    // Retain the texture's darkest eyes, nose, mouth and scale/feather lines.
    float features = smoothstep(feature_value.x, feature_value.y, hsv.z);
    float hue_mask = smoothstep(accent_source_hue.x - 0.025, accent_source_hue.x, hsv.x)
        * (1.0 - smoothstep(accent_source_hue.y, accent_source_hue.y + 0.025, hsv.x));
    float accent = hue_mask * smoothstep(accent_source_saturation - 0.08, accent_source_saturation + 0.08, hsv.y)
        * smoothstep(accent_source_value - 0.12, accent_source_value + 0.08, hsv.z);
    float body_value = clamp(max(body_value_floor, hsv.z * body_value_scale), 0.0, 0.86);
    vec3 body = from_hsv(vec3(body_hue, body_saturation, body_value));
    float body_mask = smoothstep(body_source_hue.x - 0.025, body_source_hue.x, hsv.x)
        * (1.0 - smoothstep(body_source_hue.y, body_source_hue.y + 0.025, hsv.x))
        * smoothstep(body_source_saturation - 0.04, body_source_saturation, hsv.y);
    vec3 base = mix(source.rgb * base_value_scale, body, repaint_strength * body_mask);
    if (shift_enabled) {
        float grey = 1.0 - smoothstep(0.08, 0.2, hsv.y);
        float saturation = clamp(max(hsv.y * shift_saturation_scale, shift_saturation_floor), 0.0, 0.85);
        float value = clamp(max(hsv.z * shift_value_scale, shift_value_floor * features), 0.0, 0.9);
        // Blend in colour space: blending hues would pass through unrelated ones.
        vec3 shifted = from_hsv(vec3(shiny_safe_hue(hsv.x + shift_hue), saturation, value));
        vec3 greyed = from_hsv(vec3(shiny_safe_hue(shift_grey_hue), saturation, value));
        base = mix(shifted, greyed, grey);
    }
    base *= source_tint.rgb;
    // The authored UV regions select charged seams/tips, never a moving world mask.
    vec3 charged = from_hsv(vec3(accent_hue, accent_saturation, mix(hsv.z, accent_value, 0.8)));
    ALBEDO = mix(base, charged, accent);
    vec3 emission_sample = texture(source_emission, uv).rgb;
    float emission_mask = has_emission_texture ? max(max(max(emission_sample.r, emission_sample.g), emission_sample.b), emission_floor * features) : 1.0;
    // The existing night floor already carries painted value in its texture.
    // Recolour that light without multiplying the same dark value twice.
    float painted_value = max(max(ALBEDO.r, ALBEDO.g), ALBEDO.b);
    vec3 emission_colour = has_emission_texture ? ALBEDO / max(painted_value, 0.0001) : ALBEDO;
    EMISSION = emission_colour * emission_mask * emission_gain + charged * accent * accent_energy;
    ROUGHNESS = surface_roughness;
    METALLIC = surface_metallic;
    RIM = rim_amount;
    if (has_normal) {
        NORMAL_MAP = texture(source_normal, uv).rgb;
        NORMAL_MAP_DEPTH = normal_strength;
    }
    ALPHA = features * source.a * source_tint.a;
}
