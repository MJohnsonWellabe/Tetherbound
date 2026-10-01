shader_type spatial;
render_mode unshaded, cull_back, depth_draw_never;

uniform vec4 hot_colour : source_color = vec4(1.0, 0.96, 0.72, 1.0);
uniform vec4 flame_colour : source_color = vec4(1.0, 0.43, 0.025, 1.0);
uniform float opacity = 0.86;
uniform float flow_speed = 3.8;
uniform float surface_scale = 4.8;
uniform float deformation = 0.22;
uniform float edge_softness = 0.42;
uniform float emission_strength = 0.9;
varying vec3 core_direction;

float hash(vec3 p) { return fract(sin(dot(p,vec3(127.1,311.7,74.7)))*43758.5453); }
float noise(vec3 p) {
    vec3 i=floor(p), f=fract(p);
    f=f*f*(3.0-2.0*f);
    return mix(mix(mix(hash(i),hash(i+vec3(1,0,0)),f.x),mix(hash(i+vec3(0,1,0)),hash(i+vec3(1,1,0)),f.x),f.y),
               mix(mix(hash(i+vec3(0,0,1)),hash(i+vec3(1,0,1)),f.x),mix(hash(i+vec3(0,1,1)),hash(i+vec3(1,1,1)),f.x),f.y),f.z);
}

void vertex() {
    core_direction = normalize(VERTEX);
    vec3 flow = core_direction * surface_scale + vec3(0.0, -TIME * flow_speed, TIME * 0.37);
    // Only contract the authored sphere. The existing transit envelope still
    // encloses every vertex, including at the largest frozen mastery rank.
    float folds = noise(flow) * 0.7 + noise(flow * 2.03 + 4.1) * 0.3;
    VERTEX *= 1.0 - clamp(deformation, 0.0, 0.3) * (1.0 - folds);
}

void fragment() {
    // A dense hot interior dissolves into moving, porous flame at the edge.
    // Noise uses direction so mastery changes size rather than texture scale.
    float facing = max(0.0, dot(normalize(NORMAL), normalize(VIEW)));
    vec3 p=core_direction*surface_scale+vec3(0.0,-TIME*flow_speed,TIME*0.37);
    float broad=noise(p)*0.62+noise(p*2.03+4.1)*0.28+noise(p*4.07-7.3)*0.10;
    float channels=smoothstep(0.55,0.83,broad);
    float heat=clamp(channels*0.72+facing*0.36,0.0,1.0);
    ALBEDO=mix(flame_colour.rgb*mix(0.72,1.05,broad),hot_colour.rgb,smoothstep(0.32,0.8,heat));
    EMISSION=ALBEDO*emission_strength*(0.45+heat*0.55);
    float soft_edge=smoothstep(0.02,max(0.04,edge_softness),facing);
    float porous=smoothstep(0.2,0.62,broad+facing*0.38);
    ALPHA=opacity*soft_edge*porous;
}
