shader_type spatial;
render_mode blend_mix, cull_back, diffuse_burley, specular_schlick_ggx, skip_vertex_transform;

// Far-only Meshy hero landmark (scripts/world/hero_landmarks_1101.gd, the
// Veilfall candidate). The painted Meshy albedo with the far-silhouette
// treatment of water_veilfall_silhouette.gdshader: the same island-centre
// depth pull, so it sits on top of the distant terrain LOD, and its own
// reduced FOG from the live environment fog (fog_colour / fog_density /
// fog_enabled are copied by VeilfallFarSilhouette.register_fogged). Bright
// near-white texels (the waterfalls) keep less fog and lift toward white so
// they read white against the blue distance.
uniform sampler2D albedo_tex : source_color, filter_linear_mipmap, repeat_enable;
uniform vec4 albedo_tint : source_color = vec4(1.0);
uniform float roughness_value = 0.85;
uniform vec3 fog_colour = vec3(0.38, 0.50, 0.60); // linear; set from the environment
uniform float fog_density = 0.00055;
uniform bool fog_enabled = true;
uniform float fog_keep_near = 0.9;
uniform float fog_keep_far = 0.6;
uniform float fog_keep_start_m = 1100.0;
uniform float fog_keep_end_m = 4000.0;
uniform float white_fog_keep = 0.45;
uniform float white_lift = 0.25;
uniform vec2 centre_xz = vec2(200.0, 4140.0);
uniform float depth_pull_fraction = 0.012;
uniform float depth_pull_max_m = 60.0;
uniform float presentation_pull_start_m = 900.0;
uniform float presentation_pull_end_m = 1100.0;
varying float v_distance;

void vertex() {
	vec3 world = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	v_distance = length(world - INV_VIEW_MATRIX[3].xyz);
	vec3 view = (MODELVIEW_MATRIX * vec4(VERTEX, 1.0)).xyz;
	float presentation_distance = length(INV_VIEW_MATRIX[3].xz - centre_xz);
	float far_geometry = smoothstep(presentation_pull_start_m,
		max(presentation_pull_end_m, presentation_pull_start_m + 1.0), presentation_distance);
	float pull = min(presentation_distance * depth_pull_fraction, depth_pull_max_m) * far_geometry;
	VERTEX = view * max(0.0, 1.0 - pull / max(presentation_distance, 0.001));
	NORMAL = normalize((MODELVIEW_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

void fragment() {
	vec3 colour = texture(albedo_tex, UV).rgb * albedo_tint.rgb;
	float luma = dot(colour, vec3(0.299, 0.587, 0.114));
	float chroma = max(colour.r, max(colour.g, colour.b)) - min(colour.r, min(colour.g, colour.b));
	float white = smoothstep(0.55, 0.8, luma) * (1.0 - smoothstep(0.12, 0.25, chroma));
	ALBEDO = mix(colour, vec3(1.0), white * white_lift);
	ROUGHNESS = roughness_value;
	SPECULAR = 0.25;
	float far_t = smoothstep(fog_keep_start_m, fog_keep_end_m, v_distance);
	float env_fog = fog_enabled ? 1.0 - exp(-fog_density * v_distance) : 0.0;
	float keep = mix(fog_keep_near, fog_keep_far, far_t) * mix(1.0, white_fog_keep, white);
	FOG = vec4(fog_colour, env_fog * keep);
}
