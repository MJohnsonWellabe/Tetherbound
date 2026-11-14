shader_type spatial;
render_mode blend_mix, cull_back, diffuse_burley, specular_disabled;

// Meadows ridge backdrop (F38#24 / P2-014, data/config/meadows_ridge_vl.json,
// OFF until judged). The Blender ridge ring's baked albedo, lit by the scene
// sun, with a REDUCED share of the live environment fog so the ridge keeps its
// form at 1.5-1.9 km instead of flattening into one sky-coloured silhouette.
// fog_colour / fog_density / fog_enabled are copied from the WorldEnvironment
// by scripts/world/meadows_ridge_vl.gd, so the haze still follows the hour.
uniform sampler2D albedo_tex : source_color, filter_linear_mipmap_anisotropic, repeat_disable;
uniform vec4 albedo_tint : source_color = vec4(1.0);
uniform vec3 fog_colour = vec3(0.38, 0.50, 0.60); // linear; set from the environment
uniform float fog_density = 0.00055;
uniform bool fog_enabled = true;
uniform float fog_keep = 0.6;        // share of the environment fog this ridge takes
uniform float base_fog_keep = 0.95;  // at and below base_fade_top_m the ridge melts into the haze
uniform float base_fade_top_m = 60.0;
uniform float base_y_world = -40.0;
// Warm-hour haze (LANE-LAND-MT, OFF at the defaults): at golden hour the
// environment fog is tan, and a 1.7 km ridge wearing 60% of it reads as a
// flat tan sheet. warm_haze_mix moves the ridge's own haze toward
// warm_haze_colour (a cool dusk blue-violet) by how warm the fog is, and
// warm_keep_scale thins it, so the range stays a cool silhouette with form
// against the warm sky. Blue day and night fog have no warmth: unchanged.
uniform vec3 warm_haze_colour = vec3(0.30, 0.33, 0.46);
uniform float warm_haze_mix = 0.0;
uniform float warm_keep_scale = 1.0;
uniform float warm_gain = 3.0;
varying float v_distance;
varying float v_height;

void vertex() {
	vec3 world = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	v_distance = length(world - INV_VIEW_MATRIX[3].xyz);
	v_height = world.y - base_y_world;
}

void fragment() {
	ALBEDO = texture(albedo_tex, UV).rgb * albedo_tint.rgb;
	ROUGHNESS = 1.0;
	float env_fog = fog_enabled ? 1.0 - exp(-fog_density * v_distance) : 0.0;
	float keep = mix(base_fog_keep, fog_keep, smoothstep(0.0, max(base_fade_top_m, 1.0), v_height));
	float warmth = clamp((fog_colour.r - fog_colour.b) / max(fog_colour.r, 0.001) * warm_gain, 0.0, 1.0);
	vec3 haze = mix(fog_colour, warm_haze_colour * dot(fog_colour, vec3(0.3333)) / max(dot(warm_haze_colour, vec3(0.3333)), 0.001),
		warm_haze_mix * warmth);
	FOG = vec4(haze, env_fog * keep * mix(1.0, warm_keep_scale, warmth));
}
