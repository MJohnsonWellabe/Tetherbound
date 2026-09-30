shader_type spatial;
render_mode cull_disabled, depth_draw_never, diffuse_burley, specular_schlick_ggx;

// Adapted from installed project-authored Veilfall receiving water/foam math.
// No SCREEN_TEXTURE, depth texture, refraction or Forward+-only dependency.
uniform vec4 water_colour : source_color = vec4(0.10,0.48,0.71,1.0);
uniform vec4 foam_colour : source_color = vec4(0.82,0.94,0.97,1.0);
uniform float opacity = 0.76;
uniform float flow_speed = 3.0;
uniform bool wave = false;

void vertex() {
    float taper = sin(UV.y*3.141593);
    VERTEX.x += sin(UV.y*15.0-TIME*flow_speed)*0.02*taper;
    VERTEX.z += sin(UV.x*24.0+TIME*flow_speed)*0.015*taper;
}
void fragment() {
    float travel = UV.y*21.0-TIME*flow_speed;
    float ripple = sin(travel+sin(UV.x*41.0)*2.0)*0.5+0.5;
    float strands = smoothstep(0.28,0.77,ripple);
    float crest = wave ? smoothstep(0.62,0.88,UV.y) : 0.24;
    float foam = strands*(0.32+crest*0.68);
    ALBEDO = mix(water_colour.rgb,foam_colour.rgb,foam);
    EMISSION = foam_colour.rgb*foam*0.05;
    ROUGHNESS = 0.16+foam*0.46;
    SPECULAR = 0.72;
    ALPHA = opacity*mix(0.18,1.0,strands)*smoothstep(0.0,0.06,UV.y);
}
