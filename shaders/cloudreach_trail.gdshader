shader_type spatial;
render_mode diffuse_burley, specular_disabled;
uniform sampler2D dirt_texture : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
#include "res://shaders/cloudreach_turf.gdshaderinc"
uniform vec4 tint : source_color = vec4(0.61,0.50,0.37,1.0);
varying vec3 world_position;
float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1,311.7))) * 43758.5453); }
void vertex() { world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz; }
void fragment() {
	float edge_wander=sin(world_position.x*0.71+sin(world_position.z*0.39))*0.06;
	float edge=smoothstep(0.035,0.31,min(UV.x,1.0-UV.x)+edge_wander);
	vec3 soil=texture(dirt_texture,world_position.xz*0.48).rgb*tint.rgb;
	vec3 grass=cloudreach_turf(world_position);
	ALBEDO=mix(grass,soil,edge);
	ROUGHNESS = 0.98;
}
