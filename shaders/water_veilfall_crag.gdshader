shader_type spatial;
render_mode blend_mix, cull_disabled, diffuse_burley, specular_schlick_ggx;
#include "res://shaders/tidewake_detail.gdshaderinc"

// Veilfall kitbash crag (scripts/world/water_veilfall_crag_kitbash.gd). One
// material for every instanced installed rock piece and the inset core.
// World-space triplanar Rock030 grain, then three zones: dark wet stone in the
// falls gorge and at the sea foot, mid wet-grey body, pale weathered crown.
// Moss/grass only where a ledge faces the sky. Writes its own FOG at a reduced
// amount (fog colour/density copied from the live WorldEnvironment by the far
// silhouette's register_fogged) so the crag keeps a value at 1-4 km.
uniform sampler2D rock_albedo : source_color, filter_linear_mipmap, repeat_enable;
uniform float grain_scale_m = 9.0;
uniform float grain_strength = 0.55;
uniform vec3 body_colour : source_color = vec3(0.36, 0.37, 0.36);
uniform vec3 wet_colour : source_color = vec3(0.13, 0.15, 0.16);
uniform vec3 crown_colour : source_color = vec3(0.62, 0.62, 0.58);
uniform vec3 moss_colour : source_color = vec3(0.30, 0.38, 0.22);
uniform float crown_start_y = 380.0;
uniform float crown_end_y = 640.0;
uniform float foot_wet_y = 40.0;
uniform vec2 centre_xz = vec2(200.0, 4140.0);
uniform vec2 across_xz = vec2(0.841, 0.541);
uniform vec2 outward_xz = vec2(0.541, -0.841);
uniform float falls_across_m = -100.0;
uniform float falls_wet_half_m = 75.0;
uniform float falls_wet_min_outward_m = 120.0;
uniform float moss_normal_lo = 0.62;
uniform float moss_normal_hi = 0.86;
uniform float moss_amount = 0.75;
uniform float strata_period_m = 14.0;
uniform float strata_strength = 0.12;
uniform float crevice_darken = 1.0;
uniform float wet_specular = 0.55;
uniform float roughness_dry = 0.88;
uniform float roughness_wet = 0.42;
uniform vec3 fog_colour = vec3(0.38, 0.50, 0.60); // linear; set from the environment
uniform float fog_density = 0.00055;
uniform bool fog_enabled = true;
uniform float fog_keep_near = 1.0;
uniform float fog_keep_far = 0.55;
uniform float fog_keep_start_m = 900.0;
uniform float fog_keep_end_m = 3600.0;
// Core/skin only (identity model transform): lift with camera distance so the
// thin rock skin stays above Terrain3D's coarser distant LOD. Zero near.
uniform float far_lift_m = 0.0;
uniform float far_lift_start_m = 250.0;
uniform float far_lift_end_m = 1400.0;

void vertex() {
	if (far_lift_m > 0.0) {
		vec3 world_v = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
		float d = length(world_v - CAMERA_POSITION_WORLD);
		// COLOR.r: per-vertex lift weight (meshes without colours read 1).
		VERTEX.y += far_lift_m * COLOR.r * smoothstep(far_lift_start_m, far_lift_end_m, d);
	}
}

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise(vec2 p) {
	vec2 cell = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(cell), hash(cell + vec2(1.0, 0.0)), f.x),
		mix(hash(cell + vec2(0.0, 1.0)), hash(cell + vec2(1.0)), f.x), f.y);
}

vec3 triplanar(vec3 p, vec3 n) {
	vec3 w = pow(abs(n), vec3(4.0));
	w /= max(w.x + w.y + w.z, 0.0001);
	vec3 x = texture(rock_albedo, p.zy / grain_scale_m).rgb;
	vec3 y = texture(rock_albedo, p.xz / grain_scale_m).rgb;
	vec3 z = texture(rock_albedo, p.xy / grain_scale_m).rgb;
	return x * w.x + y * w.y + z * w.z;
}

void fragment() {
	vec3 world = (INV_VIEW_MATRIX * vec4(VERTEX, 1.0)).xyz;
	vec3 n = normalize((INV_VIEW_MATRIX * vec4(NORMAL, 0.0)).xyz);
	float distance_m = length(VERTEX);
	vec2 local = world.xz - centre_xz;
	float across = dot(local, across_xz);
	float outward = dot(local, outward_xz);
	vec3 grain = triplanar(world, n);
	float luma = dot(grain, vec3(0.333));
	float big = noise(world.xz / 70.0 + world.y / 90.0);
	float strata = sin(world.y / strata_period_m * 6.2831 + big * 4.0) * 0.5 + 0.5;
	// Weathered crown, darker wet body and gorge.
	float crown = smoothstep(crown_start_y, crown_end_y, world.y + (big - 0.5) * 90.0);
	vec3 base = mix(body_colour, crown_colour, crown);
	float gorge = (1.0 - smoothstep(falls_wet_half_m * 0.45, falls_wet_half_m, abs(across - falls_across_m)))
		* smoothstep(falls_wet_min_outward_m - 30.0, falls_wet_min_outward_m, outward);
	float foot = 1.0 - smoothstep(foot_wet_y * 0.4, foot_wet_y + 20.0, world.y);
	float wet = clamp(max(gorge, foot) * (0.75 + big * 0.35), 0.0, 1.0);
	base = mix(base, wet_colour, wet);
	base *= mix(1.0 - strata_strength, 1.0 + strata_strength, strata);
	vec3 albedo = base * mix(1.0 - grain_strength, 1.0 + grain_strength, luma * 1.6 - 0.3);
	float ledge = smoothstep(moss_normal_lo, moss_normal_hi, n.y) * smoothstep(0.35, 0.65, noise(world.xz / 22.0));
	albedo = mix(albedo, moss_colour * mix(0.8, 1.15, luma), ledge * moss_amount * (1.0 - crown * 0.6) * (1.0 - foot));
	ALBEDO = albedo * crevice_darken;
	ROUGHNESS = mix(roughness_dry, roughness_wet, wet);
	SPECULAR = mix(0.3, wet_specular, wet);
	if (tidewake_detail_enabled) {
		NORMAL = normalize(mat3(VIEW_MATRIX) * tidewake_surface_normal(world, n));
	}
	float far_t = smoothstep(fog_keep_start_m, fog_keep_end_m, distance_m);
	float env_fog = fog_enabled ? 1.0 - exp(-fog_density * distance_m) : 0.0;
	FOG = vec4(fog_colour, env_fog * mix(fog_keep_near, fog_keep_far, far_t));
}
