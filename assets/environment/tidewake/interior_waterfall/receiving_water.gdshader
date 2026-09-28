shader_type spatial;
render_mode cull_disabled, diffuse_burley, specular_schlick_ggx;
varying vec3 water_position;
void vertex() {
    water_position=VERTEX;
    VERTEX.y+=sin(VERTEX.x*3.8+TIME*2.0)*sin(VERTEX.z*4.4-TIME*2.8)*.027;
}
void fragment() {
    float wave=sin(water_position.x*4.4+sin(water_position.z*5.1-TIME*2.4)*1.7+TIME*1.6)*.5+.5;
    float cross_wave=sin(water_position.z*15.0+water_position.x*2.1-TIME*3.2)*.5+.5;
    float impact=1.0-smoothstep(.1,1.40,abs(water_position.z+2.10));
    float foam=smoothstep(.73,.96,wave*.55+cross_wave*.45)*(.30+impact*.70);
    ALBEDO=mix(vec3(.055,.18,.22),vec3(.66,.80,.82),foam);
    ROUGHNESS=.25+foam*.38;
    SPECULAR=.65;
}
