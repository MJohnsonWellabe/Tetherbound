shader_type spatial;
render_mode cull_back, diffuse_burley, specular_schlick_ggx;

// Original local-space wet slate treatment. No external texture pixels.
varying vec3 stone_position;
float hash(vec3 p) { return fract(sin(dot(p, vec3(127.1,311.7,74.7)))*43758.5453); }
float noise(vec3 p) {
    vec3 i=floor(p), f=fract(p); f=f*f*(3.0-2.0*f);
    return mix(mix(mix(hash(i),hash(i+vec3(1,0,0)),f.x),mix(hash(i+vec3(0,1,0)),hash(i+vec3(1,1,0)),f.x),f.y),
        mix(mix(hash(i+vec3(0,0,1)),hash(i+vec3(1,0,1)),f.x),mix(hash(i+vec3(0,1,1)),hash(i+vec3(1,1,1)),f.x),f.y),f.z);
}
void vertex() { stone_position=VERTEX; }
void fragment() {
    float broad=noise(stone_position*2.2);
    float grain=noise(stone_position*36.0);
    float course=floor(stone_position.x/1.98);
    float block=hash(vec3(course,floor(stone_position.y*1.3),floor(stone_position.z)));
    float wet=0.55+0.35*noise(stone_position*vec3(4.0,0.55,3.0));
    vec3 slate=mix(vec3(.105,.139,.148),vec3(.225,.267,.269),broad*.65+grain*.12+block*.23);
    ALBEDO=slate*(1.0-wet*.18);
    ROUGHNESS=.34+grain*.18;
    SPECULAR=.65;
}
