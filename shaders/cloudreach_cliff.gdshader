shader_type spatial;
render_mode diffuse_burley, specular_disabled;
#include "res://shaders/cloudreach_rock.gdshaderinc"
varying vec3 world_position;
varying vec3 world_normal;
void vertex() {
	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	world_normal = normalize(MODEL_NORMAL_MATRIX * NORMAL);
}
void fragment() {
	vec3 rock_albedo;
	vec3 rock_normal_world;
	cloudreach_rock(world_position, world_normal, rock_albedo, rock_normal_world);
	ALBEDO = rock_albedo;
	NORMAL = normalize((VIEW_MATRIX * vec4(rock_normal_world, 0.0)).xyz);
	ROUGHNESS = 0.96;
}
