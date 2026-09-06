shader_type spatial;

// OP-0905-09 CLEAN RESTART. The Burrow Warrens exterior was a boulder grid
// wearing one flat StandardMaterial3D tint no matter how steep or how high a
// piece of it stood -- ten dressing rounds (EXT-04..EXT-10,
// data/config/burrow_warrens.json's own `_why_*` trail) retuned that tint and
// never stopped reading as a rock pile. `burrow_warrens.gd::_build_bank()`
// replaces the whole grid with ONE procedural earth-bank mesh, and this is
// its material: a hand-rolled triplanar blend (same technique
// `warrens_boulder_stain.gdshader` already uses for this cave's own rock,
// written out by hand because a StandardMaterial3D's `uv1_triplanar` has no
// hook for a SECOND texture or a slope/height blend) between the meadow's
// own grass photo on gentle upper ground and the terrain's own wet-earth
// photo on the steep dug face and every low surface -- so the bank reads as
// a grassy hump continuous with the field it stands in, with dark dug earth
// showing only where a burrow would actually have exposed it. No new asset:
// both textures are the SAME files `terrain_playground.json` already paints
// on the meadow (`textures[].name == "grass"` / `"damp"`).
//
// `v_height_frac`, read from each vertex's own COLOR.r, is written by
// `_build_bank()` as that vertex's height fraction of the bank's own crest --
// the mesh's own build-time answer to "how high up this specific bank is
// this point", which a fragment shader has no other way to know without
// being told the bank's own scale. Slope comes from the WORLD normal
// directly (`world_vertex_coords` below), so it needs no such hint.
//
// `cull_disabled` rather than the boulder shader's `cull_back`: the bank is a
// single continuous heightfield-style mesh built from a plain vertex grid,
// and getting the winding of a several-thousand-triangle procedural mesh
// backwards would make the entire top surface invisible under `cull_back`
// with no clear failure signal short of a render. Disabled costs a little
// overdraw and buys certainty that the surface is visible either way.
render_mode cull_disabled, diffuse_lambert, specular_disabled, world_vertex_coords;

uniform sampler2D grass_albedo : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D earth_albedo : source_color, filter_linear_mipmap_anisotropic, repeat_enable;

// SECOND-PASS-0906, judge evidence "flat-shaded with no visible texture,
// the only high-detail element in the whole shot is the dead-branch crown".
// The first version of this shader sampled ALBEDO only -- every vertex
// normal came straight off `generate_normals()`'s own per-triangle average
// over a several-metre grid, so no surface DETAIL ever reached the
// fragment regardless of how sharp the installed photos are. Both normal
// maps are the SAME installed textures the flat versions already sample
// (`_bank_earth_material()`/terrain's own grass texture), triplanar-mapped
// exactly like the albedo above so grain direction never stretches.
// `source_color` deliberately omitted (these are data, not colour).
uniform sampler2D grass_normal : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D earth_normal : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform float normal_strength : hint_range(0.0, 2.0) = 1.1;

uniform vec3 grass_tint : source_color = vec3(1.0);
uniform vec3 earth_tint : source_color = vec3(1.0);
uniform float grass_uv_scale = 0.27;
uniform float earth_uv_scale = 0.25;
uniform float grass_roughness : hint_range(0.0, 1.0) = 0.95;
uniform float earth_roughness : hint_range(0.0, 1.0) = 0.97;

// SECOND-PASS-0906: low-frequency value noise so no two square metres of
// the dome read as the identical flat tone -- a cheap hash noise (no
// FastNoiseLite equivalent exists in shader code, and this is exactly the
// kind of broad, slow-varying variation a hash-and-interpolate gives
// without a texture lookup) at `noise_freq_m` (metres) modulating albedo by
// +/-`noise_amount` (0.12 == +/-12%, per the brief).
uniform float noise_freq_m : hint_range(0.005, 0.5) = 0.06;
uniform float noise_amount : hint_range(0.0, 0.5) = 0.12;

// THIRD-PASS-0906, judge evidence "the bank ... reads as a tiled/striated
// material on a simple displaced shape". A second, much LOWER-frequency
// noise field than `noise_freq_m` above (1/macro_noise_freq_m is ~18-25m
// per the brief, an order of magnitude broader than the fine surface grain)
// that (a) modulates albedo value by +/-macro_noise_amount so no two
// ten-metre patches of the bank read as the identical flat tone, and (b)
// pushes the earth/grass blend toward bare dirt in the noise's own positive
// lobe -- irregular blotches of exposed earth breaking up the grassy top,
// masked by the SAME field rather than a second, disagreeing pattern.
// `macro_patch_strength` is how far a patch can push `earth_w`; 0 disables
// the patch half while leaving the albedo modulation intact.
uniform float macro_noise_freq_m : hint_range(0.01, 0.2) = 0.045;
uniform float macro_noise_amount : hint_range(0.0, 0.5) = 0.15;
uniform float macro_patch_strength : hint_range(0.0, 1.0) = 0.35;

// SECOND-PASS-0906: the dark "moist band" the brief asks for within 2m of
// every warren hole and the mouth. `_build_bank()` writes this per-vertex
// (COLOR.g, 0 far / 1 at the opening's own rim) because the shader has no
// other way to know where the holes are -- see `_build_bank()`'s own
// moisture pass.
uniform float moist_darken : hint_range(0.0, 1.0) = 0.35;
uniform vec3 moist_tint : source_color = vec3(0.55, 0.5, 0.45);

// ROUND-4-0906, JUDGE-round3.md "nothing shows directional throw of earth":
// the raw-spoil mask, written per-vertex into COLOR.b by
// `burrow_warrens.gd::_bank_spoil_at()` (the throw lobe of every secondary
// dig-mound, the fan out of the mouth, the fan below every warren hole).
// Where it is high the surface is forced to bare earth regardless of slope
// or height and darkened toward `spoil_tint`, so freshly displaced dirt
// reads as darker, un-grassed and directional against the settled bank.
uniform vec3 spoil_tint : source_color = vec3(0.48, 0.38, 0.28);
uniform float spoil_darken : hint_range(0.0, 1.0) = 0.55;

// ROUND-4-0906: the crest-fraction earth band below (`height_low_frac` /
// `height_high_frac`) put EVERYTHING in the bank's lowest metres in earth --
// including the grid's whole grade-level skirt, which two blind rounds read
// as a "pale flagstone patio" around the mound. 0 turns that band off and
// leaves earth to slope, moisture and spoil; 1 (the default) keeps the old
// behaviour for any other site using this shader.
uniform float height_blend_on : hint_range(0.0, 1.0) = 1.0;

// Slope blend: 0 degrees is flat ground, 90 is a vertical face. Below
// `slope_low_deg` the surface is grass regardless of height; above
// `slope_high_deg` it is earth regardless of height. Between the two, height
// decides (below), so a gentle upper shoulder still reads as grass even
// where the noise bump on it briefly steepens past `slope_low_deg`.
uniform float slope_low_deg = 32.0;
uniform float slope_high_deg = 48.0;

// Height blend, as a fraction of the bank's own crest (`v_height_frac`).
// Below `height_low_frac` (the foot of the bank, spoil fans, the ground the
// bank rises out of) the surface is earth; above `height_high_frac` it is
// grass; the true blend is whichever of the two masks (slope or height)
// calls for MORE earth at that point.
uniform float height_low_frac : hint_range(0.0, 1.0) = 0.12;
uniform float height_high_frac : hint_range(0.0, 1.0) = 0.30;

// ---------------------------------------------------------------------------
// WARRENS-ART-0906 round 5 -- OWNER, 2026-09-06: "the placed rocks on the
// exterior don't look right. it seems like you can do something more like what
// we're doing on cloudreach cliffs with the cliffs to make this look better
// rather than using plastic prop assets."
//
// Both blind rounds had already found the same thing from the pictures alone:
//
//   round 1: "the rock set. Flat hard-edged facet slabs with a painted-on moss
//            band ... needs rock forms with real strata and a moss treatment
//            that grows rather than stripes."
//   round 2: "the boulders are flat-shaded low-poly slabs with hard facets and
//            visible triangle edges, while the knoll they sit on is a smooth
//            high-resolution blob with a noise texture. Two incompatible rock
//            treatments, adjacent, in the same shot."
//
// The answer is not more props. This bank is already a procedural surface with
// a shader on it, so the rock goes IN the surface: where the mound is steep
// enough to be a cut face rather than a settled slope, it draws stone with
// sedimentary banding, mossy ledges and crevice shadow -- the same three moves
// `shaders/cloudreach_cliff.gdshader` makes, sharing that shader's own Rock030
// texture and the grey-green granite palette the owner picked for Cloudreach
// (option A), so the two biomes' stone is one material language and this
// site's own knoll and boulders stop being two.
//
// `rock_strength` 0 disables the whole layer and this file is then
// byte-identical to before it, which is what every key below is defaulted for.
uniform sampler2D rock_albedo : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D rock_normal_map : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform float rock_strength : hint_range(0.0, 1.0) = 0.0;
uniform float rock_uv_scale = 0.055;
uniform vec3 stone_light : source_color = vec3(0.54, 0.56, 0.51);
uniform vec3 stone_dark : source_color = vec3(0.27, 0.29, 0.27);
// Where stone takes over from earth. A settled grass slope is never rock; the
// dug face beside the mouth, the throat's own cut and the steepest flanks are.
uniform float rock_slope_low_deg = 46.0;
uniform float rock_slope_high_deg = 62.0;
// Sedimentary banding, world-space so it reads across the whole mass however
// the procedural mesh is tessellated. Soft edges, never a hard floor(), or it
// is a barcode rather than a stratum.
uniform float strata_period_m : hint_range(1.0, 30.0) = 6.0;
uniform float strata_strength : hint_range(0.0, 0.3) = 0.05;
uniform vec3 strata_ochre_tint : source_color = vec3(0.36, 0.41, 0.35);
uniform float strata_ochre_strength : hint_range(0.0, 1.0) = 0.18;
// Near-horizontal ledges pick up moss; steep faces are untouched.
uniform vec3 ledge_moss_tint : source_color = vec3(0.30, 0.42, 0.21);
uniform float ledge_moss_strength : hint_range(0.0, 1.0) = 0.55;
uniform float ledge_lighten : hint_range(0.0, 0.5) = 0.1;
uniform float ledge_normal_threshold : hint_range(0.0, 1.0) = 0.55;
// Crevice darkening on the steep faces between ledges, so the cut face is not
// one flat mid-tone.
uniform float crevice_strength : hint_range(0.0, 1.0) = 0.45;
uniform float crevice_scale = 0.09;

varying float v_height_frac;
// SECOND-PASS-0906: the moisture mask `_build_bank()` writes to COLOR.g.
varying float v_moist;
// ROUND-4-0906: the raw-spoil mask `_build_bank()` writes to COLOR.b.
varying float v_spoil;
// WARRENS-ART-0906: baked contact occlusion, COLOR.a. The Compatibility
// renderer has no SSAO and no light volumes (`burrow_warrens.json`'s own
// `_comment_w07_room` says so), so nothing in the engine darkens the inside
// of a concave form -- and the mouth's earth collar is exactly that: the rim
// of a hole, whose inner face should sit in the hole's own shadow and which
// instead rendered as the BRIGHTEST thing at the entrance, a cream ring
// around a black opening (60m approach frame, first render of this pass).
// `_build_brow_earth_ring()` writes a ramp here, dark at the rim and 1.0 at
// the outer edge where the collar dies into the mound.
//
// This is a no-op for every surface that existed before it. `_build_bank()`
// and `_build_bank_cap()` both write their vertex colour through
// `_bank_add_vertex()`, whose `Color(frac, moist, spoil)` leaves alpha at
// Godot's own default of 1.0, so `v_occlusion` is 1.0 across the whole mound
// and the multiply below changes nothing there.
varying float v_occlusion;

void vertex() {
	v_height_frac = COLOR.r;
	v_moist = COLOR.g;
	v_spoil = COLOR.b;
	v_occlusion = COLOR.a;
}

// Cheap triplanar: three axis-projected samples of the same installed photo,
// blended by how much the world normal faces each axis -- the identical
// technique `warrens_boulder_stain.gdshader::triplanar()` already uses for
// this cave's own rock, so nothing on this outcrop stretches regardless of
// how steep the procedural mesh gets.
vec3 triplanar(sampler2D tex, vec3 world_pos, vec3 blend, float scale) {
	vec3 xc = texture(tex, world_pos.yz * scale).rgb;
	vec3 yc = texture(tex, world_pos.xz * scale).rgb;
	vec3 zc = texture(tex, world_pos.xy * scale).rgb;
	return xc * blend.x + yc * blend.y + zc * blend.z;
}

// Same triplanar blend, over a tangent-space normal map instead of albedo --
// each axis sample is re-expanded from [0,1] to [-1,1] and swizzled back
// into world space before blending, the standard triplanar-normal trick.
vec3 triplanar_normal(sampler2D tex, vec3 world_pos, vec3 blend, float scale, vec3 world_normal) {
	// Each axis sample is a tangent-space normal for that projection plane;
	// swizzled into world axes (x-projection's tangent plane is world YZ, so
	// its sample's xy maps to world zy, and so on) before blending.
	vec3 xs = texture(tex, world_pos.yz * scale).rgb * 2.0 - 1.0;
	vec3 ys = texture(tex, world_pos.xz * scale).rgb * 2.0 - 1.0;
	vec3 zs = texture(tex, world_pos.xy * scale).rgb * 2.0 - 1.0;
	vec3 nx = vec3(0.0, xs.y, xs.x);
	vec3 ny = vec3(ys.x, 0.0, ys.y);
	vec3 nz = vec3(zs.x, zs.y, 0.0);
	vec3 n = nx * blend.x + ny * blend.y + nz * blend.z + world_normal;
	return normalize(n);
}

// SECOND-PASS-0906: cheap hash-based value noise (no texture lookup, no
// FastNoiseLite equivalent in shader code) for the low-frequency surface
// variation the brief asks for. Smoothed with a bilinear lerp between four
// integer-lattice hash values so it reads as broad relief, not static.
float hash2(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123);
}

// WARRENS-ART-0906: the same cheap 3D noise `cloudreach_cliff.gdshader` uses,
// for the strata bend and the crevice field. Kept identical to that file's so
// the two biomes' stone breaks up the same way.
float noise3(vec3 p) {
	return sin(p.x * 0.83 + sin(p.z * 0.67)) * 0.5 + sin(p.z * 0.49 + p.y * 0.37) * 0.5;
}

float value_noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	float a = hash2(i);
	float b = hash2(i + vec2(1.0, 0.0));
	float c = hash2(i + vec2(0.0, 1.0));
	float d = hash2(i + vec2(1.0, 1.0));
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
}

void fragment() {
	vec3 world_pos = VERTEX;
	vec3 world_normal = normalize(NORMAL);
	vec3 blend = abs(world_normal);
	blend /= (blend.x + blend.y + blend.z + 0.0001);

	float slope_deg = degrees(acos(clamp(world_normal.y, -1.0, 1.0)));
	float earth_by_slope = smoothstep(slope_low_deg, slope_high_deg, slope_deg);
	float earth_by_height = (1.0 - smoothstep(height_low_frac, height_high_frac, v_height_frac)) * height_blend_on;
	float earth_w = clamp(max(earth_by_slope, earth_by_height), 0.0, 1.0);

	vec3 grass_c = triplanar(grass_albedo, world_pos, blend, grass_uv_scale) * grass_tint;
	vec3 earth_c = triplanar(earth_albedo, world_pos, blend, earth_uv_scale) * earth_tint;

	// Low-frequency relief: one noise sample per axis-projection scale (the
	// earth's own, since that is the surface the brief names) shared by both
	// materials so a blended pixel does not show a seam between two
	// independent noise fields.
	float n = value_noise(world_pos.xz * noise_freq_m) * 2.0 - 1.0;
	float shade = 1.0 + n * noise_amount;
	grass_c *= shade;
	earth_c *= shade;

	// THIRD-PASS-0906: the macro field (see its own header above). `patch`
	// only ever RAISES earth_w (max(), never lowers it) -- the dug face stays
	// fully earth regardless of what the macro noise says there, and only the
	// grassy top (where earth_w started low) can gain a bare patch.
	float macro_n = value_noise(world_pos.xz * macro_noise_freq_m) * 2.0 - 1.0;
	float macro_shade = 1.0 + macro_n * macro_noise_amount;
	grass_c *= macro_shade;
	earth_c *= macro_shade;
	float patch = smoothstep(0.15, 0.55, macro_n) * macro_patch_strength;
	earth_w = clamp(max(earth_w, patch), 0.0, 1.0);

	// The moist band around every opening: darkens AND cools toward
	// `moist_tint` so a hole's own rim reads as freshly turned, wet ground
	// rather than the same dry dirt as the rest of the face.
	float moist = clamp(v_moist, 0.0, 1.0);
	earth_c = mix(earth_c, earth_c * moist_tint, moist * moist_darken);

	// ROUND-4-0906: raw spoil -- forced bare (max(), never lowers earth_w)
	// and darkened toward `spoil_tint`, see the uniform's own comment.
	float spoil = clamp(v_spoil, 0.0, 1.0);
	earth_w = clamp(max(earth_w, spoil), 0.0, 1.0);
	earth_c = mix(earth_c, earth_c * spoil_tint, spoil * spoil_darken);

	vec3 albedo = mix(grass_c, earth_c, earth_w);

	// The geology layer (see the `rock_*` uniforms' own header). Slope alone
	// decides it: a settled grass shoulder is never stone, the dug face and
	// the steepest flanks always are, and `rock_strength` scales the whole
	// thing so a site can dial it back to nothing.
	float rock_w = smoothstep(rock_slope_low_deg, rock_slope_high_deg, slope_deg) * rock_strength;
	if (rock_w > 0.001) {
		vec3 rock_tex = triplanar(rock_albedo, world_pos, blend, rock_uv_scale);
		float bend = noise3(world_pos * 0.027) * 8.0;
		float macro = clamp(noise3(world_pos * 0.016) * 0.5 + 0.5, 0.0, 1.0);
		float face = abs(sin(world_pos.x * 0.019 - world_pos.z * 0.024 + bend * 0.04));
		vec3 stone = mix(stone_dark, stone_light, 0.30 + macro * 0.45 + face * 0.15);

		float strata_units = world_pos.y / max(strata_period_m, 0.1);
		float strata_band = floor(strata_units);
		float strata_frac = fract(strata_units);
		float band_edge = smoothstep(0.0, 0.14, strata_frac) * (1.0 - smoothstep(0.86, 1.0, strata_frac));
		float strata_parity = mod(strata_band, 2.0);
		stone *= 1.0 + mix(-strata_strength, strata_strength, strata_parity) * band_edge;
		float ochre_band = 1.0 - smoothstep(0.0, 1.0, mod(strata_band, 3.0));
		stone = mix(stone, strata_ochre_tint, strata_ochre_strength * band_edge * ochre_band);

		float ledge_mask = smoothstep(ledge_normal_threshold, ledge_normal_threshold + 0.25, world_normal.y);
		vec3 ledge_colour = mix(stone * (1.0 + ledge_lighten), ledge_moss_tint, ledge_moss_strength);
		stone = mix(stone, ledge_colour, ledge_mask * clamp(0.55 + macro * 0.5, 0.0, 1.0));

		float steepness = 1.0 - ledge_mask;
		float crevice_noise = noise3(world_pos * crevice_scale) * 0.5 + 0.5;
		float crevice = (1.0 - smoothstep(0.05, 0.6, crevice_noise)) * steepness;
		stone *= mix(1.0, 1.0 - crevice_strength, crevice);

		albedo = mix(albedo, stone * mix(vec3(0.82), rock_tex * 1.28, 0.52), rock_w);
	}

	// Baked contact occlusion, see `v_occlusion` above. 1.0 everywhere the
	// mesh does not author it, so this line is free for the mound itself.
	albedo *= clamp(v_occlusion, 0.0, 1.0);
	ALBEDO = albedo;
	ROUGHNESS = mix(mix(grass_roughness, earth_roughness, earth_w), 0.96, rock_w);

	// NORMAL_MAP (Godot's tangent-space slot) needs real per-vertex TANGENT
	// data to build its TBN basis, and this mesh has none --
	// `_build_bank()`'s SurfaceTool only ever calls `generate_normals()`, so
	// feeding NORMAL_MAP here would light off a garbage basis. Everything in
	// this shader is already WORLD space (`world_vertex_coords` above, see
	// this file's own header), so `triplanar_normal()` builds its perturbed
	// normal in world space too and this writes NORMAL directly -- the same
	// space the slope test above already reads it in, no tangent basis
	// required. `normal_strength` (0-2) is how far the shading normal leans
	// toward the sampled detail versus the mesh's own smooth normal.
	vec3 grass_n = triplanar_normal(grass_normal, world_pos, blend, grass_uv_scale, world_normal);
	vec3 earth_n = triplanar_normal(earth_normal, world_pos, blend, earth_uv_scale, world_normal);
	vec3 blended_n = normalize(mix(grass_n, earth_n, earth_w));
	// Where the geology layer wins, so does its own relief -- a strata face
	// with the meadow's soil normals on it is the mismatch this layer exists
	// to remove.
	if (rock_w > 0.001) {
		vec3 rock_n = triplanar_normal(rock_normal_map, world_pos, blend, rock_uv_scale, world_normal);
		blended_n = normalize(mix(blended_n, rock_n, rock_w));
	}
	NORMAL = normalize(mix(world_normal, blended_n, clamp(normal_strength, 0.0, 1.0)));
}
