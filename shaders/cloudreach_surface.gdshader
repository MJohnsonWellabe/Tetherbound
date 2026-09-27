shader_type spatial;
render_mode diffuse_burley, specular_disabled;
#include "res://shaders/cloudreach_turf.gdshaderinc"
#include "res://shaders/cloudreach_rock.gdshaderinc"
uniform float grass_slope_cos = 0.829038;
uniform float rock_slope_cos = 0.559193;
uniform float edge_breakup = 0.055;
varying vec3 world_at;
varying vec3 surface_normal;
void vertex() {
	world_at = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	surface_normal = normalize(MODEL_NORMAL_MATRIX * NORMAL);
}
void fragment() {
	vec3 n = normalize(surface_normal);
	// Interpolated lighting normals can make a vertical cut's upper edge
	// appear flat. Material coverage follows the actual triangle slope.
	vec3 face = normalize(cross(dFdx(world_at), dFdy(world_at)));
	float up = abs(face.y);
	if (up >= grass_slope_cos + edge_breakup) {
		// Most of the realm is gentle turf: avoid six unused rock samples.
		ALBEDO = cloudreach_turf(world_at);
		ROUGHNESS = 0.98;
	} else {
		float breakup = noise3(world_at * 0.42) * edge_breakup;
		float turf = smoothstep(rock_slope_cos, grass_slope_cos, up + breakup);
		vec3 rock_albedo;
		vec3 rock_normal_world;
		cloudreach_rock(world_at, n, rock_albedo, rock_normal_world);
		ALBEDO = mix(rock_albedo, cloudreach_turf(world_at), turf);
		NORMAL = normalize((VIEW_MATRIX * vec4(normalize(mix(rock_normal_world, n, turf)), 0.0)).xyz);
		ROUGHNESS = mix(0.96, 0.98, turf);
	}
}
