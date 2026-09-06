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

uniform vec3 grass_tint : source_color = vec3(1.0);
uniform vec3 earth_tint : source_color = vec3(1.0);
uniform float grass_uv_scale = 0.27;
uniform float earth_uv_scale = 0.25;
uniform float grass_roughness : hint_range(0.0, 1.0) = 0.95;
uniform float earth_roughness : hint_range(0.0, 1.0) = 0.97;

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

varying float v_height_frac;

void vertex() {
	v_height_frac = COLOR.r;
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

void fragment() {
	vec3 world_pos = VERTEX;
	vec3 world_normal = normalize(NORMAL);
	vec3 blend = abs(world_normal);
	blend /= (blend.x + blend.y + blend.z + 0.0001);

	float slope_deg = degrees(acos(clamp(world_normal.y, -1.0, 1.0)));
	float earth_by_slope = smoothstep(slope_low_deg, slope_high_deg, slope_deg);
	float earth_by_height = 1.0 - smoothstep(height_low_frac, height_high_frac, v_height_frac);
	float earth_w = clamp(max(earth_by_slope, earth_by_height), 0.0, 1.0);

	vec3 grass_c = triplanar(grass_albedo, world_pos, blend, grass_uv_scale) * grass_tint;
	vec3 earth_c = triplanar(earth_albedo, world_pos, blend, earth_uv_scale) * earth_tint;

	ALBEDO = mix(grass_c, earth_c, earth_w);
	ROUGHNESS = mix(grass_roughness, earth_roughness, earth_w);
}
