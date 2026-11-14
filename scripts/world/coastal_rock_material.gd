extends RefCounted
## Presentation-only cliff layer over the actual Terrain3D shader. Retains its
## height/control sampling and the separately installed Veilfall treatment.
const MARKER := "// COASTAL-ROCK"
const DUNE_SHADOW_MARKER := "// COASTAL-DUNE-SHADOW-V1"
const UNIFORM_ANCHOR := "void vertex() {"
const VERTEX_ANCHOR := "VERTEX = (VIEW_MATRIX * vec4(v_vertex, 1.0)).xyz;"
const MATERIAL_ANCHOR := "mat.ao_strength *= weight_inv;"
const SHORE_CONFIG := "res://data/config/water_shore_presentation.json"
const DUNE_CONFIG := "res://data/config/water_dune_terrain.json"
const UNIFORMS := """
// COASTAL-ROCK: coherent projection over exposed rock and steep faces.
uniform sampler2D coast_albedo : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D coast_normal : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform float coast_strength = 0.0;
uniform float coast_scale = 0.18;
uniform float coast_normal_depth = 0.38;
uniform vec3 coast_tint : source_color = vec3(0.62, 0.65, 0.64);
uniform float coast_start_y = 0.68;
uniform float coast_full_y = 0.32;
uniform int coast_rock_texture_id = 2;
uniform vec2 coast_exclude_centre = vec2(200.0, 4140.0);
uniform float coast_exclude_radius = 430.0;
uniform bool coast_weathering_enabled = false;
uniform float coast_weathering_scale = 0.11;
uniform vec3 coast_moss_colour : source_color = vec3(0.32, 0.42, 0.24);
uniform float coast_moss_amount = 0.65;
uniform vec3 coast_sediment_colour : source_color = vec3(0.71, 0.61, 0.45);
uniform float coast_sediment_height_m = 4.8;
uniform float coast_sediment_texture_scale = 0.30;
uniform float coast_sediment_texture_strength = 1.20;
uniform vec3 coast_wet_colour : source_color = vec3(0.22, 0.29, 0.27);
uniform float coast_wet_height_m = 1.6;
uniform float coast_rock_detail = 0.45;
uniform bool coast_dunes_enabled = false;
uniform sampler2D coast_dune_albedo : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform vec3 coast_dune_sand_colour : source_color = vec3(0.78, 0.71, 0.59);
uniform vec3 coast_dune_wet_colour : source_color = vec3(0.51, 0.47, 0.40);
uniform float coast_dune_wet_height_m = 1.25;
uniform float coast_dune_wet_strength = 0.8;
uniform float coast_dune_patch_scale = 0.022;
uniform float coast_dune_ripple_scale = 16.0;
uniform float coast_dune_ripple_strength = 0.025;
uniform float coast_dune_texture_scale = 0.30;
uniform float coast_dune_texture_strength = 0.65;
uniform float coast_dune_normal_strength = 0.0;
uniform float coast_dune_face_shade_strength = 0.0;
uniform float coast_dune_face_shade_start_y = 0.98;
uniform float coast_dune_face_shade_full_y = 0.72;
uniform float coast_dune_shadow_push_m = 0.0;
uniform float coast_dune_bluff_start_y = 0.72;
uniform float coast_dune_bluff_full_y = 0.38;
uniform float coast_dune_painted_bluff_start_y = 0.90;
uniform float coast_dune_painted_bluff_full_y = 0.70;
// tb/cause-tidewake dunes (flag-off; 0 keeps the shipping sand exactly):
// wind-scoured runnels and faint cross-bedding on steep sand faces, and sparse
// low scrub/wrack stains on level sand, so dune walls read as formed sand and
// open sand stops reading as bare discs.
uniform float coast_dune_flank_strength = 0.0;
uniform float coast_dune_flank_scale = 0.35;
uniform float coast_dune_strata_strength = 0.0;
uniform float coast_dune_scrub_strength = 0.0;
uniform float coast_dune_scrub_scale = 0.07;
uniform vec3 coast_dune_scrub_colour : source_color = vec3(0.47, 0.46, 0.33);
// LANE-LAND-MT shore zones (flag-off; 0 keeps the shipping sand exactly). A
// false-colour capture showed the wet band is a hairline at the waterline and
// everything above it is one pale sand, so islands have no shore ecology.
// wet_wobble_m widens and wanders the damp edge; wrack is a broken dark
// strand line at the top of the damp sand; zone is sage and straw backdune
// turf in patches that close up with height on gentle ground.
uniform float coast_dune_wet_wobble_m = 0.4;
uniform float coast_dune_wrack_strength = 0.0;
uniform float coast_dune_wrack_height_m = 1.6;
uniform float coast_dune_wrack_width_m = 0.35;
uniform vec3 coast_dune_wrack_colour : source_color = vec3(0.27, 0.25, 0.18);
uniform float coast_dune_zone_strength = 0.0;
uniform float coast_dune_zone_start_m = 3.0;
uniform float coast_dune_zone_full_m = 8.0;
uniform float coast_dune_zone_scale = 0.035;
uniform vec3 coast_dune_zone_colour : source_color = vec3(0.40, 0.46, 0.27);
uniform vec3 coast_dune_zone_straw_colour : source_color = vec3(0.62, 0.58, 0.36);
// Round 2 (GPU G-land-mt-shorezones: hard triangular olive facets on the near
// sand). near_fade_m fades turf out toward the camera; slope_free drops the
// terrain-normal gate, which can step per triangle where normals are faceted;
// edge widens the patch border. Defaults keep round 1 exactly.
uniform float coast_dune_zone_near_fade_m = 0.0;
uniform float coast_dune_zone_slope_free = 0.0;
uniform float coast_dune_zone_edge = 0.12;
// LANE-LAND-MT damp hollows (flag-off; 0 keeps the shipping sand exactly).
// Judges on the Venn fight (G-land-mt-cragback, 3/3): "the dune is one flat
// pale mid-tone". Low sand gets broad, irregular damp patches in the wet
// tone, fading out by damp_top_m, so the ground has a light/dark structure.
uniform float coast_dune_damp_strength = 0.0;
uniform float coast_dune_damp_scale = 0.03;
uniform float coast_dune_damp_top_m = 6.0;

float coast_hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}
float coast_noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(coast_hash(i), coast_hash(i + vec2(1.0, 0.0)), f.x),
		mix(coast_hash(i + vec2(0.0, 1.0)), coast_hash(i + vec2(1.0)), f.x), f.y);
}
"""
const MATERIAL := """
	// COASTAL-ROCK. Evaluate derivatives outside the slope branch.
	vec3 coast_dx = dFdx(v_vertex);
	vec3 coast_dy = dFdy(v_vertex);
	vec3 coast_face = normalize(cross(coast_dy, coast_dx));
	vec4 coast_base = vec4(equal(ivec4(control >> uvec4(27u) & uvec4(31u)), ivec4(coast_rock_texture_id)));
	vec4 coast_over = vec4(equal(ivec4(control >> uvec4(22u) & uvec4(31u)), ivec4(coast_rock_texture_id)));
	vec4 coast_blend = vec4(control >> uvec4(14u) & uvec4(255u)) / 255.0;
	vec4 coast_paint = coast_base * (1.0 - coast_blend) + coast_over * coast_blend;
	float coast_painted = bilerp ? dot(coast_paint, weights) : coast_paint[3];
	float coast_weight = coast_strength * max(coast_painted, 1.0 - smoothstep(coast_full_y, coast_start_y, abs(coast_face.y)));
	coast_weight *= smoothstep(0.2, 1.6, v_vertex.y);
	coast_weight *= smoothstep(coast_exclude_radius, coast_exclude_radius + 30.0, length(v_vertex.xz - coast_exclude_centre));
	if (coast_weight > 0.001) {
		vec2 side = vec2(coast_face.x < 0.0 ? -1.0 : 1.0, coast_face.z < 0.0 ? -1.0 : 1.0);
		vec3 coast_weights = abs(coast_face);
		coast_weights /= max(coast_weights.x + coast_weights.y + coast_weights.z, 0.001);
		vec2 uv_x = vec2(-side.x * v_vertex.z, -v_vertex.y) * coast_scale;
		vec2 uv_z = vec2(side.y * v_vertex.x, -v_vertex.y) * coast_scale;
		vec2 uv_y = v_vertex.xz * coast_scale;
		vec2 dx_x = vec2(-side.x * coast_dx.z, -coast_dx.y) * coast_scale;
		vec2 dy_x = vec2(-side.x * coast_dy.z, -coast_dy.y) * coast_scale;
		vec2 dx_z = vec2(side.y * coast_dx.x, -coast_dx.y) * coast_scale;
		vec2 dy_z = vec2(side.y * coast_dy.x, -coast_dy.y) * coast_scale;
		vec2 dx_y = coast_dx.xz * coast_scale;
		vec2 dy_y = coast_dy.xz * coast_scale;
		vec3 rock = textureGrad(coast_albedo, uv_x, dx_x, dy_x).rgb * coast_weights.x
			+ textureGrad(coast_albedo, uv_y, dx_y, dy_y).rgb * coast_weights.y
			+ textureGrad(coast_albedo, uv_z, dx_z, dy_z).rgb * coast_weights.z;
		vec3 nx = textureGrad(coast_normal, uv_x, dx_x, dy_x).xyz * 2.0 - 1.0;
		vec3 nz = textureGrad(coast_normal, uv_z, dx_z, dy_z).xyz * 2.0 - 1.0;
		vec3 ny = textureGrad(coast_normal, uv_y, dx_y, dy_y).xyz * 2.0 - 1.0;
		// Keep broad rock planes quiet; the normal supplies small relief.
		float value = dot(rock, vec3(0.299, 0.587, 0.114));
		rock = mix(vec3(value), rock, 0.4);
		float warp = sin(v_vertex.x * 0.021 + v_vertex.z * 0.013) * 1.9;
		float bed = fract((v_vertex.y + warp) / 12.0);
		float ledge = smoothstep(0.02, 0.15, bed) * (1.0 - smoothstep(0.55, 0.98, bed));
		rock *= coast_tint * mix(0.90, 1.10, ledge);
		if (coast_weathering_enabled) {
			// Broad mineral planes, with irregular vegetation tongues at the
			// slope transition; the real surface and its silhouette stay intact.
			float patch = coast_noise(v_vertex.xz * coast_weathering_scale);
			float grain = coast_noise(v_vertex.xz * coast_weathering_scale * 3.7);
			// Weather the installed mineral texture without replacing its
			// small relief with a flat tint at the ordinary camera distance.
			rock *= mix(0.82, 1.0, coast_rock_detail);
			rock *= mix(0.78, 1.15, patch);
			float moss = smoothstep(0.48, 0.91, abs(coast_face.y) + (patch - 0.5) * 0.32);
			moss *= smoothstep(1.8, 5.0, v_vertex.y) * coast_moss_amount;
			rock = mix(rock, coast_moss_colour * mix(0.65, 1.05, grain), moss);
		}
		vec3 detail = vec3(0.0, nx.y, -side.x * nx.x) * coast_weights.x
			+ vec3(ny.x, 0.0, -ny.y) * coast_weights.y
			+ vec3(side.y * nz.x, nz.y, 0.0) * coast_weights.z;
		vec3 surface_normal = normalize(mat3(INV_VIEW_MATRIX) * NORMAL);
		detail -= surface_normal * dot(surface_normal, detail);
		float detail_z = dot(vec3(nx.z, ny.z, nz.z), coast_weights);
		vec3 detail_view = mat3(VIEW_MATRIX) * normalize(surface_normal * max(detail_z, 0.01) + detail);
		vec3 mapped = vec3(dot(detail_view, normalize(TANGENT)), dot(detail_view, normalize(NORMAL)), dot(detail_view, normalize(BINORMAL)));
		mat.albedo_height.rgb = mix(mat.albedo_height.rgb, rock, coast_weight);
		mat.normal_rough = mix(mat.normal_rough, vec4(mapped, 0.88), coast_weight);
		mat.normal_map_depth = mix(mat.normal_map_depth, coast_normal_depth, coast_weight);
	}
	if (coast_weathering_enabled) {
		// Texture-backed mineral sand and wet stains retain the actual shore
		// relief. Smooth height normals keep masks from exposing raster faces.
		float patch = coast_noise(v_vertex.xz * coast_weathering_scale);
		float grain = coast_noise(v_vertex.xz * coast_weathering_scale * 3.7);
		vec3 shore_normal = normalize(w_normal);
		vec3 shore_weights = abs(shore_normal);
		shore_weights /= max(dot(shore_weights, vec3(1.0)), 0.001);
		float shore_scale = coast_sediment_texture_scale;
		vec3 shore_tex = textureGrad(coast_dune_albedo, v_vertex.zy * shore_scale,
			coast_dx.zy * shore_scale, coast_dy.zy * shore_scale).rgb * shore_weights.x
			+ textureGrad(coast_dune_albedo, v_vertex.xz * shore_scale,
				coast_dx.xz * shore_scale, coast_dy.xz * shore_scale).rgb * shore_weights.y
			+ textureGrad(coast_dune_albedo, v_vertex.xy * shore_scale,
				coast_dx.xy * shore_scale, coast_dy.xy * shore_scale).rgb * shore_weights.z;
		float shore_grain = dot(shore_tex, vec3(0.299, 0.587, 0.114));
		float outside = smoothstep(coast_exclude_radius, coast_exclude_radius + 30.0, length(v_vertex.xz - coast_exclude_centre));
		float strand = 1.0 - smoothstep(coast_sediment_height_m * 0.35, coast_sediment_height_m, v_vertex.y + (patch - 0.5) * 2.8);
		strand *= smoothstep(0.25, 0.85, abs(shore_normal.y)) * outside;
		vec3 sediment = coast_sediment_colour * mix(0.70, 0.96, grain);
		sediment *= clamp(1.0 + (shore_grain - 0.70) * coast_sediment_texture_strength, 0.68, 1.22);
		mat.albedo_height.rgb = mix(mat.albedo_height.rgb, sediment, strand * 0.8);
		float wet = (1.0 - smoothstep(0.05, coast_wet_height_m, v_vertex.y + (patch - 0.5) * 0.6)) * outside;
		vec3 wet_surface = mat.albedo_height.rgb * coast_wet_colour / max(coast_sediment_colour, vec3(0.05));
		mat.albedo_height.rgb = mix(mat.albedo_height.rgb, wet_surface, wet * 0.65);
		mat.normal_rough.a = mix(mat.normal_rough.a, 0.55, wet);
	}
	if (coast_dunes_enabled) {
		// Owner-directed Great Lakes dune palette. This is surface colour and
		// roughness only: the baked heights, controls and collision stay intact.
		float outside = smoothstep(coast_exclude_radius, coast_exclude_radius + 30.0, length(v_vertex.xz - coast_exclude_centre));
		float patch = coast_noise(v_vertex.xz * coast_dune_patch_scale);
		// Use Terrain3D's interpolated height normal, not raster triangle
		// derivatives: slope tint must not outline every terrain triangle.
		vec3 dune_normal = normalize(w_normal);
		vec3 dune_weights = abs(dune_normal);
		dune_weights /= max(dot(dune_weights, vec3(1.0)), 0.001);
		float grain = coast_noise(v_vertex.zy * 3.4) * dune_weights.x
			+ coast_noise(v_vertex.xz * 3.4) * dune_weights.y
			+ coast_noise(v_vertex.xy * 3.4) * dune_weights.z;
		float phase = dot(v_vertex.xz, vec2(0.63, 0.77)) * coast_dune_ripple_scale + patch * 5.0;
		// Close, gentle ground only. Projecting periodic ripples down cliffs
		// produced long regular stripes instead of windblown sand.
		float ripple = sin(phase) * (1.0 - smoothstep(0.3, 0.9, fwidth(phase)))
			* smoothstep(0.8, 0.98, abs(dune_normal.y));
		vec3 sand = coast_dune_sand_colour * (mix(0.70, 0.88, patch) + (grain - 0.5) * 0.065 + ripple * coast_dune_ripple_strength);
		// Triplanar photographic grain gives the broad dune shoulders the
		// wind-cut texture visible in the owner's shore references. Use its
		// luminance so the chapter palette and wet-sand response remain authored.
		float dune_scale = coast_dune_texture_scale;
		float dune_tex = dot(texture(coast_dune_albedo, v_vertex.zy * dune_scale).rgb, vec3(0.299, 0.587, 0.114)) * dune_weights.x
			+ dot(texture(coast_dune_albedo, v_vertex.xz * dune_scale).rgb, vec3(0.299, 0.587, 0.114)) * dune_weights.y
			+ dot(texture(coast_dune_albedo, v_vertex.xy * dune_scale).rgb, vec3(0.299, 0.587, 0.114)) * dune_weights.z;
		sand *= clamp(1.0 + (dune_tex - 0.70) * coast_dune_texture_strength, 0.68, 1.22);
		// Long dune flanks need a broad value break at gameplay distance. Keep
		// level paths and crests bright while softly shading inclined sand.
		float face_shade = 1.0 - smoothstep(coast_dune_face_shade_full_y,
			coast_dune_face_shade_start_y, abs(dune_normal.y) + (patch - 0.5) * 0.06);
		sand *= 1.0 - face_shade * coast_dune_face_shade_strength;
		if (coast_dune_flank_strength > 0.0 || coast_dune_strata_strength > 0.0) {
			// Moderate dune flanks only: near-vertical walls (P2-074's passage
			// wall) turned the runnels into hard horizontal stripes on CPU.
			float steep = smoothstep(0.3, 0.5, abs(dune_normal.y)) * (1.0 - smoothstep(0.6, 0.9, abs(dune_normal.y)));
			vec2 across_dir = normalize(vec2(-dune_normal.z, dune_normal.x) + vec2(0.0001));
			float across = dot(v_vertex.xz, across_dir);
			float runnel = coast_noise(vec2(across * coast_dune_flank_scale, v_vertex.y * 0.04));
			sand *= 1.0 + (runnel - 0.5) * 2.0 * coast_dune_flank_strength * steep;
			float bed_warp = coast_noise(vec2(across * 0.05, v_vertex.y * 0.02)) * 3.0;
			float strata = smoothstep(0.55, 0.95, sin(v_vertex.y * 1.4 + bed_warp * 2.0) * 0.5 + 0.5);
			sand *= 1.0 - strata * coast_dune_strata_strength * steep;
		}
		if (coast_dune_scrub_strength > 0.0) {
			float level = smoothstep(0.9, 0.985, abs(dune_normal.y));
			float scrub = coast_noise(v_vertex.xz * coast_dune_scrub_scale) * coast_noise(v_vertex.xz * coast_dune_scrub_scale * 3.3 + vec2(7.1));
			scrub = smoothstep(0.26, 0.40, scrub + (grain - 0.5) * 0.12) * level;
			sand = mix(sand, coast_dune_scrub_colour * mix(0.82, 1.08, grain), scrub * coast_dune_scrub_strength);
		}
		if (coast_dune_damp_strength > 0.0) {
			float damp_n = coast_noise(v_vertex.xz * coast_dune_damp_scale + vec2(2.3, 7.7)) * 0.7
				+ coast_noise(v_vertex.xz * coast_dune_damp_scale * 2.9 + vec2(9.1, 4.4)) * 0.3;
			float damp = smoothstep(0.5, 0.68, damp_n + (grain - 0.5) * 0.08)
				* (1.0 - smoothstep(coast_dune_damp_top_m * 0.55, coast_dune_damp_top_m, v_vertex.y));
			sand = mix(sand, coast_dune_wet_colour * mix(0.94, 1.06, grain), damp * coast_dune_damp_strength);
		}
		if (coast_dune_zone_strength > 0.0) {
			float zone_n = coast_noise(v_vertex.xz * coast_dune_zone_scale) * 0.5
				+ coast_noise(v_vertex.xz * coast_dune_zone_scale * 3.1 + vec2(3.7, 9.2)) * 0.3
				+ coast_noise(v_vertex.xz * coast_dune_zone_scale * 11.0 + vec2(8.3, 2.1)) * 0.2;
			float zone_h = smoothstep(coast_dune_zone_start_m, coast_dune_zone_full_m, v_vertex.y + (zone_n - 0.5) * 4.0);
			float zone_gentle = mix(smoothstep(0.55, 0.85, abs(dune_normal.y)), 1.0, coast_dune_zone_slope_free);
			// Noise-led patches that close up with height: turf islands in
			// sand, never a lawn (a first try blanketed every dune green).
			float zone_cover = smoothstep(0.5, 0.5 + coast_dune_zone_edge, zone_n * 0.8 + zone_h * 0.2) * smoothstep(0.0, 0.35, zone_h) * zone_gentle;
			if (coast_dune_zone_near_fade_m > 0.0) {
				zone_cover *= smoothstep(coast_dune_zone_near_fade_m * 0.5, coast_dune_zone_near_fade_m,
					length(v_vertex - (INV_VIEW_MATRIX * vec4(0.0, 0.0, 0.0, 1.0)).xyz));
			}
			// Metre-scale sand flecks through the turf, so a patch underfoot is
			// tufted ground and not one flat green sheet.
			zone_cover *= mix(0.35, 1.0, smoothstep(0.3, 0.62, coast_noise(v_vertex.xz * 0.85 + vec2(4.4))));
			vec3 turf = mix(coast_dune_zone_straw_colour, coast_dune_zone_colour,
				coast_noise(v_vertex.xz * coast_dune_zone_scale * 7.3 + vec2(1.9))) * mix(0.8, 1.1, grain);
			// Keep the sand's own ripple and grain value under the turf.
			turf *= clamp(dot(sand, vec3(0.3333)) / max(dot(coast_dune_sand_colour, vec3(0.3333)) * 0.79, 0.01), 0.8, 1.2);
			sand = mix(sand, turf, zone_cover * coast_dune_zone_strength);
		}
		// Sand caps the gentle ground; required steep banks expose the
		// installed mineral material beneath it. This keeps those fixed
		// landforms from reading as vertical piles of uniformly pale sand.
		float bluff_patch = coast_noise(v_vertex.xz * 0.16 + vec2(v_vertex.y * 0.025));
		float bluff = 1.0 - smoothstep(coast_dune_bluff_full_y, coast_dune_bluff_start_y,
			abs(dune_normal.y) + (bluff_patch - 0.5) * 0.12);
		// The baked painted banks include 33-degree slopes: the purely
		// steep-face mask misses much of them. Retain the installed mineral
		// material through a broader, smoothly blended painted-rock mask.
		float painted_bluff = coast_painted * (1.0 - smoothstep(
			coast_dune_painted_bluff_full_y, coast_dune_painted_bluff_start_y,
			abs(dune_normal.y) + (bluff_patch - 0.5) * 0.08));
		bluff = max(bluff, painted_bluff) * smoothstep(1.3, 3.5, v_vertex.y);
		float dune_weight = outside * (1.0 - bluff);
		float wet_level = v_vertex.y + (patch - 0.5) * coast_dune_wet_wobble_m;
		float wet = 1.0 - smoothstep(0.15, coast_dune_wet_height_m, wet_level);
		sand = mix(sand, coast_dune_wet_colour * mix(0.92, 1.02, grain), wet * coast_dune_wet_strength);
		if (coast_dune_wrack_strength > 0.0) {
			float wrack_line = smoothstep(coast_dune_wrack_height_m - coast_dune_wrack_width_m, coast_dune_wrack_height_m, wet_level)
				* (1.0 - smoothstep(coast_dune_wrack_height_m, coast_dune_wrack_height_m + coast_dune_wrack_width_m, wet_level));
			float wrack_speck = smoothstep(0.42, 0.7, coast_noise(v_vertex.xz * 1.7))
				* smoothstep(0.3, 0.6, coast_noise(v_vertex.xz * 0.21 + vec2(5.3)));
			sand = mix(sand, coast_dune_wrack_colour * mix(0.8, 1.15, grain), wrack_line * wrack_speck * coast_dune_wrack_strength);
		}
		// At full mineral coverage every installed albedo/normal/roughness
		// value survives unchanged; do not turn the exposed bank beige again.
		mat.albedo_height.rgb = mix(mat.albedo_height.rgb, sand, dune_weight);
		// Fine relief follows the same wind ripples as the albedo. Fade before
		// it becomes subpixel; preserve the real slope and the Terrain3D TNB basis.
		float relief = coast_dune_normal_strength * cos(phase)
			* (1.0 - smoothstep(0.3, 0.9, fwidth(phase)))
			* smoothstep(0.8, 0.98, abs(dune_normal.y));
		vec3 wind = vec3(0.63, 0.0, 0.77);
		vec3 dune_detail = normalize(dune_normal - (wind - dune_normal * dot(wind, dune_normal)) * relief);
		vec3 dune_view = mat3(VIEW_MATRIX) * dune_detail;
		vec3 dune_mapped = vec3(dot(dune_view, normalize(TANGENT)), dot(dune_view, normalize(NORMAL)), dot(dune_view, normalize(BINORMAL)));
		// Disabled profile keeps the shipped flat tangent normal exactly.
		vec3 dune_response = coast_dune_normal_strength > 0.0 ? dune_mapped : vec3(0.0, 1.0, 0.0);
		mat.normal_rough.rgb = mix(mat.normal_rough.rgb, dune_response, dune_weight);
		mat.normal_rough.a = mix(mat.normal_rough.a, mix(0.94, 0.73, wet), dune_weight);
		mat.normal_map_depth = mix(mat.normal_map_depth, coast_dune_normal_strength > 0.0 ? 1.0 : 0.0, dune_weight);
	}
"""

const DUNE_SHADOW_DEPTH := """
	// COASTAL-DUNE-SHADOW-V1
	// Compatibility computes shadow coordinates before fragment lighting.
	// Bias only this terrain's caster depth: visible vertices and other
	// objects' contact-shadow lookups retain their original positions.
	if (coast_dunes_enabled && IN_SHADOW_PASS) {
		float dune_shadow_outside = smoothstep(coast_exclude_radius, coast_exclude_radius + 30.0,
			length(v_vertex.xz - coast_exclude_centre));
		VERTEX.z -= clamp(coast_dune_shadow_push_m, 0.0, 0.10) * dune_shadow_outside;
	}
"""


static func install(terrain: Object, config: Dictionary, excluded: Dictionary) -> Dictionary:
	var receipt := {"installed": false, "reason": "disabled"}
	if terrain == null or not bool(config.get("enabled", false)):
		return receipt
	var material: Object = terrain.get("material")
	var current: Shader = material.call("get_shader_override")
	if not bool(material.call("is_shader_override_enabled")) or current == null:
		material.call("enable_shader_override", true)
		current = material.call("get_shader_override")
	var code := current.code if current != null else ""
	if code.contains(MARKER) and not code.contains(DUNE_SHADOW_MARKER):
		receipt.reason = "older coastal override lacks the dune shadow injection; rebuild terrain material"
		push_warning(str(receipt.reason))
		return receipt
	if not code.contains(MARKER):
		if not code.contains(UNIFORM_ANCHOR) or not code.contains(MATERIAL_ANCHOR) or not code.contains(VERTEX_ANCHOR):
			receipt.reason = "Terrain3D material anchors unavailable"
			push_warning(str(receipt.reason))
			return receipt
		var shader := Shader.new()
		shader.code = code.replace(UNIFORM_ANCHOR, UNIFORMS + UNIFORM_ANCHOR) \
			.replace(VERTEX_ANCHOR, VERTEX_ANCHOR + DUNE_SHADOW_DEPTH) \
			.replace(MATERIAL_ANCHOR, MATERIAL_ANCHOR + "\n" + MATERIAL)
		material.call("enable_shader_override", false)
		material.call("set_shader_override", shader)
		material.call("enable_shader_override", true)
	material.call("set_shader_param", "coast_albedo", load("res://assets/environment/terrain/Rock030_Color.jpg"))
	material.call("set_shader_param", "coast_normal", load("res://assets/environment/terrain/Rock030_NormalGL.jpg"))
	for key: String in ["strength", "scale", "normal_depth", "start_y", "full_y"]:
		if config.has(key):
			material.call("set_shader_param", "coast_" + key, float(config[key]))
	if config.has("tint"):
		material.call("set_shader_param", "coast_tint", Color(str(config.tint)))
	var centre: Array = excluded.get("centre_xz", [200.0, 4140.0])
	material.call("set_shader_param", "coast_exclude_centre", Vector2(float(centre[0]), float(centre[1])))
	material.call("set_shader_param", "coast_exclude_radius", float(excluded.get("radius_m", 430.0)))
	var shore: Variant = JSON.parse_string(FileAccess.get_file_as_string(SHORE_CONFIG))
	if shore is Dictionary:
		material.call("set_shader_param", "coast_weathering_enabled", bool(shore.get("enabled", false)))
		for key: String in shore:
			if key.begins_with("_") or key == "enabled":
				continue
			var value: Variant = shore[key]
			material.call("set_shader_param", "coast_" + key, Color(str(value)) if key.ends_with("colour") else float(value))
	var dune: Variant = JSON.parse_string(FileAccess.get_file_as_string(DUNE_CONFIG))
	if dune is Dictionary:
		dune = preload("res://scripts/world/tidewake_look_profile.gd").overlay(dune, "dunes")
		material.call("set_shader_param", "coast_dunes_enabled", bool(dune.get("enabled", false)))
		material.call("set_shader_param", "coast_dune_albedo", load("res://assets/environment/terrain/tidewake_dune_sand_v1.png"))
		for key: String in ["sand_colour", "wet_colour", "wet_height_m", "wet_strength", "patch_scale", "ripple_scale", "ripple_strength", "texture_scale", "texture_strength", "normal_strength", "face_shade_strength", "face_shade_start_y", "face_shade_full_y", "shadow_push_m", "bluff_start_y", "bluff_full_y", "painted_bluff_start_y", "painted_bluff_full_y",
				"flank_strength", "flank_scale", "strata_strength", "scrub_strength", "scrub_scale", "scrub_colour",
				"wet_wobble_m", "wrack_strength", "wrack_height_m", "wrack_width_m", "wrack_colour",
				"zone_strength", "zone_start_m", "zone_full_m", "zone_scale", "zone_colour", "zone_straw_colour",
				"zone_near_fade_m", "zone_slope_free", "zone_edge",
				"damp_strength", "damp_scale", "damp_top_m"]:
			if dune.has(key):
				var value: Variant = dune[key]
				material.call("set_shader_param", "coast_dune_" + key, Color(str(value)) if key.ends_with("colour") else float(value))
	var installed: Shader = material.call("get_shader_override")
	receipt.installed = installed != null and installed.code.contains(MARKER) \
		and installed.code.contains(DUNE_SHADOW_MARKER)
	receipt.reason = "installed" if receipt.installed else "override was regenerated"
	return receipt
