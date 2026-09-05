shader_type spatial;
render_mode diffuse_burley,specular_disabled;
#include "res://shaders/cloudreach_turf.gdshaderinc"
varying vec3 world_at;
void vertex(){world_at=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;}
void fragment(){ALBEDO=cloudreach_turf(world_at);ROUGHNESS=0.98;}
