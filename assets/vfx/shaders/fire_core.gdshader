shader_type spatial;
render_mode unshaded, cull_disabled;

uniform vec4 hot_colour : source_color = vec4(1.0, 0.96, 0.72, 1.0);
uniform vec4 flame_colour : source_color = vec4(1.0, 0.43, 0.025, 1.0);
varying vec3 core_position;

float hash(vec3 p) { return fract(sin(dot(p,vec3(127.1,311.7,74.7)))*43758.5453); }
float noise(vec3 p) {
    vec3 i=floor(p), f=fract(p);
    f=f*f*(3.0-2.0*f);
    return mix(mix(mix(hash(i),hash(i+vec3(1,0,0)),f.x),mix(hash(i+vec3(0,1,0)),hash(i+vec3(1,1,0)),f.x),f.y),
               mix(mix(hash(i+vec3(0,0,1)),hash(i+vec3(1,0,1)),f.x),mix(hash(i+vec3(0,1,1)),hash(i+vec3(1,1,1)),f.x),f.y),f.z);
}

void vertex() { core_position = VERTEX; }

void fragment() {
    // Uneven hot channels within a smooth physical core, not a uniform disc.
    float facing = max(0.0, dot(normalize(NORMAL), normalize(VIEW)));
    vec3 p=core_position*7.0+vec3(0.0,-TIME*2.7,TIME*0.3);
    float broad=noise(p)*0.62+noise(p*2.03+4.1)*0.28+noise(p*4.07-7.3)*0.10;
    float channels=smoothstep(0.55,0.83,broad);
    float heat=clamp(channels*0.82+facing*0.18,0.0,1.0);
    ALBEDO=mix(flame_colour.rgb*mix(0.65,1.1,broad),hot_colour.rgb,smoothstep(0.50,0.9,heat));
    EMISSION=ALBEDO*(0.13+channels*0.27);
}
