shader_type spatial;
render_mode cull_disabled, diffuse_burley, specular_schlick_ggx;

uniform vec4 ice_colour : source_color = vec4(0.41,0.73,0.84,1.0);
void fragment() {
    float facing = max(0.0,dot(normalize(NORMAL),normalize(VIEW)));
    float rim = pow(1.0-facing,2.3);
    float seams = pow(abs(sin(UV.x*19.0+UV.y*29.0)),18.0);
    ALBEDO = mix(ice_colour.rgb,vec3(0.86,0.98,1.0),rim*0.63+seams*0.12);
    ROUGHNESS = 0.13+seams*0.2;
    SPECULAR = 0.8;
    EMISSION = ALBEDO*rim*0.08;
}
