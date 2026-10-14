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
// F08#3 (r8 root cause): the imported limestone read as smooth ice. World-space
// strata bands and a second, finer sample of the same texture give it rock
// layering and grain; both default off so existing callers keep their look.
uniform float limestone_strata_strength : hint_range(0.0, 1.0) = 0.0;
uniform float limestone_strata_period_m = 3.2;
uniform float limestone_detail_strength : hint_range(0.0, 1.0) = 0.0;
uniform float limestone_detail_scale = 7.0;

void vertex() {
	world_at = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	surface_normal = normalize(MODEL_NORMAL_MATRIX * NORMAL);
}

void fragment() {
	if (shared_surface_enabled) {
		vec3 stone_albedo;
		vec3 stone_normal;
		float footprint = max(length(dFdx(world_at)), length(dFdy(world_at)));
		cloudreach_rock(world_at, normalize(surface_normal), footprint, stone_albedo, stone_normal);
		// WorldLook fog owns distance colour. Mixing pale blue into albedo here
		// painted the same daylight haze onto moonlit and shadowed spires.
		ALBEDO = stone_albedo;
		NORMAL = normalize((VIEW_MATRIX * vec4(stone_normal, 0.0)).xyz);
	} else {
		vec3 rock = texture(stone_colour, UV).rgb * stone_tint.rgb;
		float band = 0.5 + 0.5 * sin(world_at.y * 6.2831853 / max(limestone_strata_period_m, 0.1)
			+ 1.7 * sin(world_at.x * 0.21 + world_at.z * 0.17));
		rock *= 1.0 - limestone_strata_strength * 0.35 * smoothstep(0.55, 0.95, band);
		float grain = dot(texture(stone_colour, UV * limestone_detail_scale).rgb, vec3(0.333));
		rock *= mix(1.0, 0.65 + 0.7 * grain, limestone_detail_strength);
		ALBEDO = mix(rock, distance_colour.rgb, aerial_blend);
	}
	ROUGHNESS = 0.94;
}
