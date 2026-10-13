shader_type spatial;
render_mode diffuse_burley, specular_disabled;
#include "res://shaders/cloudreach_rock.gdshaderinc"

uniform bool shared_surface_enabled = false;
varying vec3 world_at;
varying vec3 surface_normal;

uniform sampler2D stone_colour : source_color, filter_linear_mipmap_anisotropic;
uniform vec4 stone_tint : source_color = vec4(1.0);
uniform vec4 distance_colour : source_color = vec4(0.54, 0.63, 0.70, 1.0);
uniform float aerial_blend : hint_range(0.0, 1.0) = 0.0;

void vertex() {
	world_at = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	surface_normal = normalize(MODEL_NORMAL_MATRIX * NORMAL);
}

void fragment() {
	ALBEDO = mix(texture(stone_colour, UV).rgb * stone_tint.rgb, distance_colour.rgb, aerial_blend);
	if (shared_surface_enabled) {
		vec3 stone_albedo;
		vec3 stone_normal;
		float footprint = max(length(dFdx(world_at)), length(dFdy(world_at)));
		cloudreach_rock(world_at, normalize(surface_normal), footprint, stone_albedo, stone_normal);
		// WorldLook fog owns distance colour. Mixing pale blue into albedo here
		// painted the same daylight haze onto moonlit and shadowed spires.
		ALBEDO = stone_albedo;
		NORMAL = normalize((VIEW_MATRIX * vec4(stone_normal, 0.0)).xyz);
	}
	ROUGHNESS = 0.94;
}
