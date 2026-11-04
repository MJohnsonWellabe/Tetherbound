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
	FOG = vec4(fog_colour, env_fog * keep);
}
