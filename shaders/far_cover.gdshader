shader_type spatial;

// FAR-COVER. The cheap ground-cover tier BEYOND the grass ring, and nothing
// else.
//
// WHY THIS EXISTS. `grass_field.gdshader`'s ring reaches `field_radius` 72m and
// fades from `fade_start` 42m. Past that the meadow is painted terrain with the
// surviving scatter blobs on it, and from the `03-rise-overlook` viewpoint the
// world visibly ends at a readable line. `data/config/grass_field.json`'s
// `_comment_ring` records what the last two answers to that cost: the ring has
// already been pushed 40 -> 56 -> 72m, the last step a 43% vertex increase on
// the most expensive tier in the game, UNMEASURED on the device, and the owner
// has since said the grass already feels expensive on the Ally. So the ring
// does not move again. This is the other instrument: a ground-colour blend that
// carries the meadow's cover READ out to the haze without carrying a single
// blade of its geometry.
//
// WHAT IT IS. ONE sheet -- one MultiMesh-free MeshInstance3D, one draw -- of
// terrain-following quads on a `far_cell` grid, blended over the terrain it
// sits on. It is not blades, not billboards and not instances: it tints and
// mottles the ground the way a kilometre of cover tints and mottles it when it
// is too far away to resolve into anything. At the distances it is visible,
// that is all real grass would be doing anyway.
//
// WHY A SINGLE SHEET RATHER THAN INSTANCED CARDS. Flat cards were the other
// half of the owner's brief and they lose on three counts here. A card lies
// flat while the ground under it does not, so on a slope it either cuts in or
// floats; a sheet samples the height at every one of its own vertices and
// follows. Cards overlap, and overlapping semi-transparent quads inside one
// MultiMesh have no sort order, so they double-darken in a pattern that moves.
// And a sheet has no tiling to hide: the mottle is one continuous world-space
// noise field, so there is no card boundary anywhere for the eye to find.
//
// TWO EDGES, AND BOTH HAVE TO BE INVISIBLE. The near edge is the whole point
// -- it must overlap the grass ring's own 42-72m fade so the two hand over
// inside each other rather than meeting -- and the far edge is the trap: a
// sheet that simply stopped would trade one hard line for two. So the fade out
// is four times as wide as the fade in, it happens where the ground is a few
// pixels tall and already carrying aerial perspective, and the drift noise
// breaks the boundary up before it gets there.
//
// NOT SHADOW-FREE AND NOT UNLIT, deliberately. An unshaded wash lifts every
// shadowed valley toward mid-green by its own alpha, which reads as fog sitting
// in the hollows. This is lit by the same sun with a normal read off the same
// height data, so a shadowed hillside stays a shadowed hillside and only its
// hue and mottle change.
//
// COST, honestly. One instance, one material, `(2N+1)^2` vertices and about
// `pi*R^2/cell^2` quads -- for the shipped numbers that is tens of thousands of
// triangles against the grass tier's fourteen million, and the fill is a single
// blended layer over ground the frame was already drawing. UNMEASURED ON THE
// DEVICE, like everything else here: `PERF-ROG-GPU` records that no container
// in this project can measure GPU cost, and it still cannot.

// `cull_disabled` because a sheet seen from below (standing in a dip looking
// up at ground that rises past the eye) must not vanish. `depth_draw_never`
// because it is a blended overlay and must not occlude anything, including
// itself. `blend_mix` over the terrain, not over the sky: the depth TEST is
// still on, so hills, trees, buildings and the grass ring all occlude it.
render_mode blend_mix, depth_draw_never, cull_disabled, diffuse_lambert,
		specular_disabled;

// ---------------------------------------------------------------------------
// Terrain3D's own data, mirrored from the live terrain material by
// `grass_field.gd::_bind_terrain` exactly as the other three field shaders
// take it. Configured nowhere: the arithmetic below reproduces Terrain3D's own
// lookup, and a region size that disagreed by one would put the sheet on the
// wrong ground without erroring.
// ---------------------------------------------------------------------------
uniform highp sampler2DArray _height_maps : repeat_disable;
uniform highp sampler2DArray _control_maps : repeat_disable;
uniform highp sampler2DArray _color_maps : source_color, filter_linear, repeat_disable;
uniform int _region_map[1024];
uniform float _region_size = 256.0;
uniform float _region_texel_size = 0.00390625;
uniform int _region_map_size = 32;
uniform float _vertex_density = 0.5;

// Where the eye is, unquantised, written every frame. Every fade below is
// measured from THIS and not from the node, for the same reason the grass tier
// separates the two: the node hops in whole cells and a distance that hops is
// an alpha that hops.
uniform vec3 field_centre = vec3(0.0);

// The sheet's own grid step, in metres. Also the step the surface normal is
// differenced over, so one number decides how closely the sheet follows the
// ground and how smooth its shading is.
uniform float far_cell = 6.0;
// The four radii. `fade_in_start`/`fade_in_end` bring the sheet up INSIDE the
// grass ring's own fade so the two overlap; `fade_out_start`/`far_radius` take
// it away again over a band wide enough that its own edge is not a second seam.
uniform float fade_in_start = 52.0;
uniform float fade_in_end = 84.0;
uniform float fade_out_start = 320.0;
uniform float far_radius = 640.0;
// Peak opacity. The single knob for how much of the meadow's colour the far
// ground takes; at 1.0 the terrain's own albedo is gone under it, which reads
// as paint of a different colour rather than as cover.
uniform float strength : hint_range(0.0, 1.0) = 0.55;
// Metres the sheet is held above the sampled height. It exists because the
// sheet's grid is coarser than the terrain's own 2m vertex spacing, so between
// its samples the true surface can rise above it and the depth test would eat
// the sheet in patches. Small enough to be sub-pixel at the ranges this is
// visible from.
uniform float lift = 0.35;

// Colour. Same shape as the grass tier's: a two-tone tint MULTIPLIED by the
// terrain's own colour map rather than mixed toward it -- that map is a
// near-white multiplier over the terrain albedo, so mixing toward it washes
// the tint out, and the grass shader's own comment records that failure.
uniform vec3 tint_base : source_color = vec3(0.208, 0.267, 0.106);
uniform vec3 tint_tip : source_color = vec3(0.400, 0.502, 0.227);
uniform float ground_blend : hint_range(0.0, 1.0) = 0.55;

// Drifts. `drift_scale`/`drift_contrast` are the GRASS TIER'S OWN
// `clump_scale`/`clump_contrast`, pushed in by `grass_field.gd` from the same
// config keys, so the far ground's open patches are a continuation of the near
// field's open patches in the same world-space noise field rather than a
// second pattern that happens to look similar. This is most of why the
// hand-over does not read as a line.
uniform float drift_scale = 0.11;
uniform float drift_contrast : hint_range(0.0, 1.0) = 0.78;
// Mottle. A second, finer noise that moves the tint between base and tip. It is
// what replaces the near field's per-tuft shade jitter at a scale the eye can
// still see from an overlook -- without it the far ground is one flat fill,
// which is the defect being fixed wearing a different colour.
uniform float mottle_scale = 0.34;
uniform float mottle_strength : hint_range(0.0, 1.0) = 0.7;

// Which terrain textures the sheet refuses, as a bitmask over base texture id,
// set from `grass_field.json`'s `forbidden_ground` by name. Refusing `path` is
// load bearing: the routes are the chapter's wayfinding and a green wash over
// them at distance would erase exactly the lines a player navigates by.
uniform int forbidden_base_mask = 12;

// BUILT GROUND, the same list the other three tiers take -- see the note in
// `grass_field.gd`. A wash over a farmhouse floor is the same defect as grass
// through it. `built_count` is zero across almost the whole corridor.
uniform vec3 built[24];
uniform int built_count = 0;
uniform vec3 built_bounds = vec3(0.0);

varying float v_alpha;
varying vec3 v_ground_colour;
varying float v_mottle;

// ---------------------------------------------------------------------------
// COPIED VERBATIM from Terrain3D 1.0.2's generated shader, exactly as
// `grass_field.gdshader`, `stone_field.gdshader` and `cover_tier.gdshader`
// carry it. Do not "clean up" -- the `search` loop walks to a neighbouring
// region when a lookup lands on a region seam, and dropping it puts a seam of
// wrong ground along every 256-texel boundary in the world.
// ---------------------------------------------------------------------------
ivec3 get_index_coord(const vec2 uv, const int search) {
	vec2 r_uv = round(uv);
	vec2 o_uv = mod(r_uv, _region_size);
	ivec2 pos;
	int bounds, layer_index = -1;
	for (int i = -1; i < clamp(search, 0, 2); i++) {
		if ((layer_index == -1) || i < 0) {
			r_uv -= i == -1 ? vec2(0.0) : vec2(float(o_uv.x <= o_uv.y), float(o_uv.y <= o_uv.x));
			pos = ivec2(floor((r_uv) * _region_texel_size)) + (_region_map_size / 2);
			bounds = int(uint(pos.x | pos.y) < uint(_region_map_size));
			layer_index = (_region_map[pos.y * _region_map_size + pos.x] * bounds - 1);
		}
	}
	return ivec3(ivec2(mod(r_uv, _region_size)), layer_index);
}

// The same value noise the other three field shaders use, rotated off the world
// axes for the same reason: an axis-aligned value-noise lattice puts its
// features on horizontal and vertical lines, which a blind critic read as
// "distinct horizontal stripes" across the ground plane. It must stay identical
// to the grass tier's, because the drift field below is meant to BE the grass
// tier's drift field and not merely resemble it.
float hash12(vec2 p) {
	vec3 p3 = fract(vec3(p.xyx) * 0.1031);
	p3 += dot(p3, p3.yzx + 33.33);
	return fract((p3.x + p3.y) * p3.z);
}

const mat2 NOISE_ROT = mat2(vec2(0.857, 0.515), vec2(-0.515, 0.857));

float value_noise(vec2 q) {
	vec2 p = NOISE_ROT * q;
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash12(i), hash12(i + vec2(1.0, 0.0)), f.x),
			mix(hash12(i + vec2(0.0, 1.0)), hash12(i + vec2(1.0, 1.0)), f.x), f.y);
}

bool on_built_ground(vec2 world_xz) {
	if (built_count <= 0) {
		return false;
	}
	vec2 to_bounds = world_xz - built_bounds.xy;
	if (dot(to_bounds, to_bounds) > built_bounds.z * built_bounds.z) {
		return false;
	}
	for (int i = 0; i < built_count; i++) {
		vec2 d = world_xz - built[i].xy;
		if (dot(d, d) < built[i].z * built[i].z) {
			return true;
		}
	}
	return false;
}

// Terrain height at a world point. `fallback` is what an off-map lookup
// returns: the neighbour samples pass the centre's own height, so the corridor's
// outer boundary produces a flat normal rather than a cliff-sized false
// gradient on the last row of vertices.
float ground_height(vec2 world_xz, float fallback) {
	ivec3 coord = get_index_coord(world_xz * _vertex_density, 1);
	return coord.z < 0 ? fallback : texelFetch(_height_maps, coord, 0).r;
}

void vertex() {
	// The node carries no rotation and no scale, so this is the sheet vertex's
	// world position. It is on a fixed world grid -- see the FAR LATTICE note
	// in `grass_field.gd` for why the node's own offset is compensated for
	// rather than left to drag the sampling points around.
	vec2 world_xz = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xz;

	// The centre lookup, done ONCE and reused for all three maps. Height,
	// control and colour all live at the same texel; three separate
	// `get_index_coord` calls would run its seam-walking loop three times for
	// the same answer.
	ivec3 coord = get_index_coord(world_xz * _vertex_density, 1);
	bool off_map = coord.z < 0;
	float ground_h = 0.0;
	uint control = 0u;
	vec3 ground_col = vec3(0.35, 0.40, 0.20);
	if (!off_map) {
		ground_h = texelFetch(_height_maps, coord, 0).r;
		control = floatBitsToUint(texelFetch(_control_maps, coord, 0)).r;
		ground_col = texelFetch(_color_maps, coord, 0).rgb;
	}
	v_ground_colour = ground_col;

	// The surface normal, differenced over the sheet's own grid step. Central
	// differences rather than forward, so the shading does not lean one way on
	// every slope. Four extra texelFetches on a vertex already doing three, on
	// a mesh of tens of thousands -- the alternative is a flat UP normal, which
	// lights the sheet differently from the hillside underneath it and shows up
	// as a pale ghost on every slope facing away from the sun.
	float hx0 = ground_height(world_xz - vec2(far_cell, 0.0), ground_h);
	float hx1 = ground_height(world_xz + vec2(far_cell, 0.0), ground_h);
	float hz0 = ground_height(world_xz - vec2(0.0, far_cell), ground_h);
	float hz1 = ground_height(world_xz + vec2(0.0, far_cell), ground_h);
	NORMAL = normalize(vec3(hx0 - hx1, 2.0 * far_cell, hz0 - hz1));

	// What the terrain says is underfoot, decoded the way the generated shader
	// decodes it: base texture id in the top five bits, hole flag at bit 2.
	int base_id = int(control >> 27u & 0x1Fu);
	bool hole = bool(control >> 2u & 0x1u);
	bool forbidden = ((forbidden_base_mask >> base_id) & 1) == 1;

	float dist = length(world_xz - field_centre.xz);
	// IN over the grass ring's own fade, OUT over a band four times as wide.
	// The asymmetry is the whole edge argument: the near hand-over happens
	// where there is still real grass to hide behind, the far one has only its
	// own slowness and the haze.
	float ramp = smoothstep(fade_in_start, fade_in_end, dist)
			* (1.0 - smoothstep(fade_out_start, far_radius, dist));

	// The grass tier's own drift field, evaluated with the grass tier's own
	// numbers, so the far ground's open patches continue the near field's.
	float drift = mix(1.0, value_noise(world_xz * drift_scale), drift_contrast);
	v_mottle = value_noise(world_xz * mottle_scale);

	v_alpha = strength * ramp * drift;
	if (off_map || hole || forbidden || on_built_ground(world_xz)) {
		v_alpha = 0.0;
	}

	// Sit the sheet on the ground it sampled. `lift` is why the depth test does
	// not eat it between samples; see the uniform's own note.
	VERTEX.y = ground_h + lift;
}

void fragment() {
	if (v_alpha <= 0.002) {
		discard;
	}
	// Multiplied by the terrain's colour map, not mixed toward it. That map is
	// a near-white multiplier over the terrain's albedo (`terrain_playground
	// .json`'s own entries are #f7f8f2, #fbfbf6), so mixing toward it washes
	// the tint out -- the grass shader carries the same note against the same
	// mistake.
	vec3 tint = mix(tint_base, tint_tip, mix(0.5, v_mottle, mottle_strength));
	ALBEDO = tint * mix(vec3(1.0), v_ground_colour, ground_blend);
	ALPHA = v_alpha;
	ROUGHNESS = 1.0;
}
