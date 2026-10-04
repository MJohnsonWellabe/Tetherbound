shader_type spatial;
render_mode cull_disabled, depth_draw_never, diffuse_burley, specular_schlick_ggx;

// Flowing water body for streams and rolling waves. Procedural value noise;
// no SCREEN_TEXTURE, depth texture, refraction or Forward+-only dependency.
// The earlier sine-stripe alpha punched regular see-through "teeth" into the
// surface; the body is now mostly opaque water with soft flowing streaks, a
// deep-to-light gradient and a fresnel rim, and a wave carries a broken
// white foam crest instead of a sawtooth.
uniform vec4 water_colour : source_color = vec4(0.10,0.48,0.71,1.0);
uniform vec4 foam_colour : source_color = vec4(0.82,0.94,0.97,1.0);
uniform float opacity = 0.76;
uniform float flow_speed = 3.0;
uniform bool wave = false;
// Splash jets: soft broken sides and a foaming, spray-torn tip.
uniform bool splash = false;

float hash(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    vec2 u = f * f * (3.0 - 2.0 * f);
    return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), u.x),
        mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), u.x), u.y);
}

float fbm(vec2 p) {
    float total = 0.0;
    float amplitude = 0.5;
    for (int i = 0; i < 4; i++) {
        total += noise(p) * amplitude;
        p *= 2.07;
        amplitude *= 0.5;
    }
    return total;
}

void vertex() {
    float taper = sin(UV.y*3.141593);
    VERTEX.x += sin(UV.y*15.0-TIME*flow_speed)*0.02*taper;
    VERTEX.z += sin(UV.x*24.0+TIME*flow_speed)*0.015*taper;
}

void fragment() {
    // Streaks flow along the body (UV.y) and are stretched so they read as
    // moving water, not as stripes.
    vec2 flow_uv = vec2(UV.x * 6.0, UV.y * 2.2 - TIME * flow_speed * 0.35);
    float streak = fbm(flow_uv * vec2(1.0, 3.0));
    float detail = fbm(flow_uv * 4.0 + vec2(TIME * 0.2, 0.0));
    float depth = wave ? smoothstep(0.0, 0.75, UV.y) : 0.5;
    vec3 deep = water_colour.rgb * 0.62;
    vec3 shallow = mix(water_colour.rgb, foam_colour.rgb, 0.28);
    vec3 body = mix(deep, shallow, depth * 0.8 + streak * 0.25);
    // Light flowing highlights.
    float glints = smoothstep(0.62, 0.86, detail) * 0.35;
    float foam = glints;
    if (wave) {
        // Broken crest: a noisy band near the curl's lip plus spray flecks.
        float crest_line = smoothstep(0.58, 0.8, UV.y + (fbm(vec2(UV.x * 9.0, TIME * 0.6)) - 0.5) * 0.18);
        float flecks = smoothstep(0.55, 0.78, fbm(vec2(UV.x * 18.0, UV.y * 10.0 - TIME * flow_speed * 0.5)));
        foam = max(foam, crest_line * (0.55 + 0.45 * flecks));
    } else {
        foam = max(foam, smoothstep(0.66, 0.9, streak) * 0.45);
    }
    float rim = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 2.5);
    ALBEDO = mix(body, foam_colour.rgb, clamp(foam, 0.0, 1.0));
    EMISSION = foam_colour.rgb * (foam * 0.08 + rim * 0.06);
    ROUGHNESS = 0.12 + foam * 0.5;
    SPECULAR = 0.72;
    // Mostly opaque body; the soft edge fades only at the very base and the
    // thin lip, plus a little transparency in the deep part for a water read.
    float edge = smoothstep(0.0, 0.08, UV.y) * (1.0 - smoothstep(0.96, 1.0, UV.y));
    if (splash) {
        float tear = fbm(vec2(UV.x * 7.0, UV.y * 5.0 - TIME * flow_speed * 0.4));
        float sides = smoothstep(0.0, 0.22, UV.x) * (1.0 - smoothstep(0.78, 1.0, UV.x));
        float tip = smoothstep(0.55, 1.0, UV.y);
        ALBEDO = mix(ALBEDO, foam_colour.rgb, clamp(tip * 0.85 + (1.0 - sides) * 0.35, 0.0, 1.0));
        EMISSION += foam_colour.rgb * tip * 0.12;
        // The lip tears into spray instead of ending on a clean edge.
        edge = smoothstep(0.0, 0.08, UV.y) * smoothstep(0.0, 0.35, sides + tear * 0.3 - 0.15)
            * (1.0 - smoothstep(0.72, 0.98, UV.y + (tear - 0.5) * 0.35));
    }
    ALPHA = opacity * edge * mix(0.86, 1.0, max(foam, rim));
}
