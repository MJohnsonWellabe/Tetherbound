// One world-space turf family across crowns, path edges and worn yards.
#include "res://shaders/cloudreach_detail.gdshaderinc"
uniform sampler2D grass_texture : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform vec4 grass_tint : source_color = vec4(0.55,0.66,0.40,1.0);
uniform float grass_scale = 0.65;
// tb/vis-water-sky group 2 (flag-off, 0 = shipped turf): broad dry and lush
// patches so a crown reads as clustered ground, not one even lawn. The same
// field thins the grass tufts on the dry patches (cloudreach_look.gd), so
// the colour and the blades agree. data/config/cloudreach_ground_cluster.json.
uniform float turf_patch_strength = 0.0;
uniform float turf_patch_freq = 0.035;
uniform vec4 turf_dry_tint : source_color = vec4(0.80,0.76,0.50,1.0);
uniform vec4 turf_lush_tint : source_color = vec4(0.42,0.56,0.32,1.0);
uniform vec2 turf_dry_band = vec2(0.35,0.6);
uniform vec2 turf_lush_band = vec2(0.3,0.55);
float cloudreach_turf_patch(vec2 xz) {
	vec2 p = xz * turf_patch_freq;
	float a = sin(p.x + sin(p.y * 1.37) * 1.7) * sin(p.y * 0.91 + sin(p.x * 1.13) * 1.3);
	float b = sin(p.x * 2.31 + 1.9 + sin(p.y * 2.7) * 1.1) * sin(p.y * 2.07 + 0.7 + sin(p.x * 1.9) * 1.2);
	return a * 0.72 + b * 0.28;
}
vec3 cloudreach_turf(vec3 at) {
	vec3 fine=texture(grass_texture,at.xz*grass_scale).rgb;
	vec3 turned=texture(grass_texture,mat2(vec2(0.8,0.6),vec2(-0.6,0.8))*at.xz*grass_scale*0.71).rgb;
	vec3 texture_value=mix(fine,turned,0.35);
	// Keep installed texture detail but suppress large lumpy camouflage patches.
	texture_value=mix(vec3(0.51),texture_value,0.52);
	float broad=sin(at.x*0.029+sin(at.z*0.041))*0.045;
	vec3 tint = grass_tint.rgb;
	if (turf_patch_strength > 0.0) {
		float field = cloudreach_turf_patch(at.xz);
		float dry = smoothstep(turf_dry_band.x, turf_dry_band.y, field);
		float lush = smoothstep(turf_lush_band.x, turf_lush_band.y, -field);
		tint = mix(tint, turf_dry_tint.rgb, dry * turf_patch_strength);
		tint = mix(tint, turf_lush_tint.rgb, lush * turf_patch_strength);
	}
	return texture_value*tint*(1.0+broad);
}
