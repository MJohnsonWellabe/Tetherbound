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
	float side_edge=smoothstep(0.035,0.31,min(UV.x,1.0-UV.x)+edge_wander);
	// A trail is wear in the turf, not an opaque strip laid over it. Fade both
	// authored ends into the same world-space grass as the shoulder so route
	// sections can meet landings without exposing a transverse rectangle.
	// UV.y is authored as metres from the nearest end, so short doorstep wear
	// and long cliff roads feather over the same physical distance.
	float longitudinal=UV.y;
	float end_wander=sin(world_position.x*0.37-world_position.z*0.29)*0.35;
	float end_edge=smoothstep(0.0,2.2,longitudinal);
	end_edge*=smoothstep(0.0,1.5,longitudinal+end_wander);
	float edge=side_edge*end_edge;
	vec3 soil=texture(dirt_texture,world_position.xz*0.48).rgb*tint.rgb;
	vec3 grass=cloudreach_turf(world_position);
	ALBEDO=mix(grass,soil,edge);
	ROUGHNESS = 0.98;
}
