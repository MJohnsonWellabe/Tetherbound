shader_type spatial;
render_mode cull_disabled, depth_draw_never, diffuse_burley;

uniform vec4 dust_colour : source_color = vec4(0.58,0.46,0.30,1.0);
uniform float opacity = 0.45;
uniform bool billboard = true;
uniform bool trail = false;
uniform float flow_speed = 1.7;
varying float phase_seed;

float hash(vec2 p) { return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453); }
float noise(vec2 p) {
    vec2 i=floor(p), f=fract(p);
    f=f*f*(3.0-2.0*f);
    return mix(mix(hash(i),hash(i+vec2(1,0)),f.x),mix(hash(i+vec2(0,1)),hash(i+vec2(1)),f.x),f.y);
}
float grain(vec2 p) { return noise(p)*0.58+noise(p*2.03+7.1)*0.28+noise(p*4.07-3.4)*0.14; }
void vertex() {
    phase_seed=INSTANCE_CUSTOM.x*6.283185;
    if (billboard) {
        vec3 s=vec3(length(MODEL_MATRIX[0].xyz),length(MODEL_MATRIX[1].xyz),length(MODEL_MATRIX[2].xyz));
        MODELVIEW_MATRIX=VIEW_MATRIX*mat4(INV_VIEW_MATRIX[0]*s.x,INV_VIEW_MATRIX[1]*s.y,INV_VIEW_MATRIX[2]*s.z,MODEL_MATRIX[3]);
    }
}
void fragment() {
    vec2 p=(UV-vec2(0.5))*2.0;
    float time=TIME*flow_speed+phase_seed;
    float broad=grain(p*3.2+vec2(time*0.15,-time*0.35));
    float fine=grain(p*13.0+vec2(-time*0.2,time*0.4));
    float mask;
    if (trail) {
        float center=(broad-0.5)*0.18;
        float width=mix(0.10,0.72,smoothstep(0.0,1.0,UV.y));
        mask=(1.0-smoothstep(width*0.25,width,abs(p.x+center)))*smoothstep(0.0,0.28,UV.y);
        mask*=smoothstep(0.24,0.71,broad*0.75+fine*0.25);
    } else {
        float edge=0.63+(broad-0.5)*0.42;
        float radius=length(p*vec2(1.0,0.88));
        mask=(1.0-smoothstep(edge*0.48,edge,radius))*smoothstep(0.18,0.64,broad);
        mask*=mix(0.52,1.0,fine);
    }
    ALBEDO=dust_colour.rgb*mix(0.70,1.16,broad*0.75+fine*0.25);
    // Rounded view-space normals let local world light shape these wisps.
    NORMAL=normalize(vec3(p.x*0.55,-p.y*0.55,sqrt(max(0.12,1.0-dot(p,p)*0.5))));
    ROUGHNESS=1.0;
    SPECULAR=0.0;
    ALPHA=mask*opacity;
}
