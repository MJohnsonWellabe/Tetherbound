shader_type spatial;

// STONE-FIELD. Loose stone, gravel and path grit, on the same camera-relative
// ring the grass carpet uses and storing nothing either.
//
// WHY THIS EXISTS, in a blind critic's own words about the build without it:
// asked directly whether stones, path edges and tree bases read as bedded into
// the ground or sitting on top of it, it answered *"No -- everything sits on
// top. This is the single most consistent failure in the set."* It measured the
// band-4 cobbles as "flat-topped slabs lying loose on sand with their entire
// edge exposed all the way round. Not one is partially buried... not one of
// them casts a contact shadow." And on the path itself: *"the road and the
// meadow share one texture, so the boundary is a density edge rather than a
// material edge, and it looks cut"*, with the surface at 1-3m *"a repeating
// mottled blob pattern with visible tiling and no grain, gravel, dirt clod, rut
// or footprint."*
//
// So this is the path's own surface, and the answer to both. It sits WHERE THE
// GRASS DOES NOT -- the same control map, read with the mask inverted -- so the
// two systems tile the ground between them without either being told where the
// other is.
//
// Three things it does that the scattered rocks do not:
//   LIES with the slope, by sampling height at one texel either side and
//     shearing toward downhill. A stone lying flat on a bank is the difference
//     between gravel and confetti.
//   SINKS, by a fraction of its own size, so its lower edge is under the
//     surface instead of standing proud of it all the way round.
//   DARKENS at the contact, so it reads as bedded even where the shadow map
//     has nothing to say at this size.
//
// Same renderer constraints as the grass field: no compute, no RenderingDevice,
// no subsurface scattering -- `D01` locks this project to GL Compatibility.

render_mode cull_back, depth_prepass_alpha, diffuse_lambert, specular_disabled;

// Terrain3D's own data, mirrored from the live material -- see
// `grass_field.gd::_bind_terrain`, which binds this material too.
uniform highp sampler2DArray _height_maps : repeat_disable;
uniform highp sampler2DArray _control_maps : repeat_disable;
uniform highp sampler2DArray _color_maps : source_color, filter_linear, repeat_disable;
uniform int _region_map[1024];
uniform float _region_size = 256.0;
uniform float _region_texel_size = 0.00390625;
uniform int _region_map_size = 32;
uniform float _vertex_density = 0.5;

uniform vec3 field_centre = vec3(0.0);
uniform float field_radius = 56.0;
uniform float fade_start = 42.0;

// Stone size, in metres, before per-instance jitter. Deliberately a wide range:
// the same critique found the existing rock scatter had "no scale variety and
// no clustering... every rock 1-2m, evenly spaced, same grey, same orientation
// family", and a gravel tier whose stones are all one size repeats that mistake
// at a smaller scale.
uniform float stone_size = 0.15;
uniform float size_jitter : hint_range(0.0, 1.0) = 0.7;
// How much of its own height a stone is buried. This is the whole "bedded"
// argument in one number.
uniform float sink : hint_range(0.0, 1.0) = 0.42;
// How hard a stone leans with the slope. 1.0 lies it flat against the gradient;
// 0 stands every stone bolt upright out of a bank.
uniform float slope_lie : hint_range(0.0, 2.0) = 1.0;

uniform float density_gain : hint_range(0.0, 1.0) = 0.55;
uniform float clump_scale = 0.16;
uniform float clump_contrast : hint_range(0.0, 1.0) = 0.6;

uniform vec3 tint_stone : source_color = vec3(0.55, 0.52, 0.47);
uniform float tint_jitter : hint_range(0.0, 1.0) = 0.28;
// How much of the terrain's own colour the stone takes. Less than the grass
// takes: a stone is its own material, it is not growing out of the ground.
uniform float ground_blend : hint_range(0.0, 1.0) = 0.35;
uniform float contact_darken : hint_range(0.0, 1.0) = 0.45;

// Where stone is ALLOWED, as a bitmask over terrain base texture id. The
// inverse of the grass field's `forbidden_base_mask`, and set from the same
// named list so the two cannot drift apart.
uniform int allowed_base_mask = 12;
// A small chance of a stone out on ordinary ground, so a meadow has field
// stones in it rather than a hard line where the path grit stops.
uniform float stray_chance : hint_range(0.0, 1.0) = 0.06;
// How thickly grit gathers at a ground-type boundary -- in practice, the worn
// edge of a route. Cubed in use, so it is tight to the edge rather than a broad
// halo.
uniform float verge_gain : hint_range(0.0, 1.0) = 0.55;

varying vec3 v_colour;
varying float v_contact;
varying float v_fade;

// COPIED VERBATIM from Terrain3D 1.0.2's generated shader, same as the grass
// field's copy and for the same reason -- see that file's note.
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

float height_at(vec2 world_xz) {
	ivec3 c = get_index_coord(world_xz * _vertex_density, 1);
	return c.z < 0 ? 0.0 : texelFetch(_height_maps, c, 0).r;
}

// ---------------------------------------------------------------------------
// STABLE RING. The block below is IDENTICAL in `grass_field.gdshader`,
// `stone_field.gdshader` and `cover_tier.gdshader`, the same way
// `get_index_coord` and `value_noise` already are, and it must stay identical:
// all three tiers ride one node, so a tier that decoded the lattice
// differently would drift off the ground the other two are standing on.
//
// WHAT IT IS FOR. The owner's 2026-08-28 playtest: "the grass rerenders like
// every step." The ring follows the camera by MOVING, every per-item property
// here is hashed on the item's WORLD position, so a move re-rolled the lot --
// which tufts survive, how tall, which way they lean. `snap` did not remove
// that, it made it periodic, one whole-field re-roll every 2 metres.
//
// So an instance's stored translation is no longer where it stands. It is
// the world LATTICE CELL it belongs to, plus a tag saying which of that cell's
// items it is and which layer it came from; `grass_field.gd::_fill_lattice`
// writes it and this reads it back. Where the item actually stands, its yaw
// and its fade rank are all hashed from the cell's INTEGER coordinates. The
// node may only sit on whole cells, so moving the ring hands cell C to a
// different instance and that instance draws exactly what the last one did.
// The field is a property of the ground now, not of the ring.
//
// The one thing that still changes with the camera is a layer's fade: the ring
// is nested lattices of different densities (the disc law's `centre_bias`
// gradient, which a single lattice cannot carry), and each one has to arrive
// smoothly rather than as a density ring following the player about. It
// arrives as HEIGHT, per item, dithered against a stable per-cell rank, so a
// fraction of one layer is mid-growth at any moment instead of all of it
// switching at once.
// ---------------------------------------------------------------------------

// The cell the field is quantised to, in metres, and always equal to the node's
// snap step -- `grass_field.gd::lattice_cell` is the single source of both.
uniform float lattice_cell = 2.0;
// How much of its own cell an item may wander. 1.0 fills the cell, which is
// what makes a lattice read as scatter rather than as rows; 0 would put every
// item dead centre and the grid would be plainly visible.
uniform float lattice_jitter : hint_range(0.0, 1.5) = 1.0;
// The width, in rank, of a layer's growth band. Small means each item grows in
// quickly but few are mid-growth at once; large means the reverse. This is the
// only knob that trades one kind of visible change for the other.
uniform float lod_dither : hint_range(0.02, 1.0) = 0.3;
// Per-layer fade radii, pushed in by `grass_field.gd::_apply_lattice`. An item
// finds its own row through the layer index in its tag.
uniform float layer_in[16];
uniform float layer_out[16];

// Sub-cell slots per axis. The x tag counts items within a cell, the y tag
// carries the layer index, and both are recovered from the instance's world
// coordinate -- so the step has to stay far above float32's resolution at
// world scale. 128 slots in a 2m cell is 15.6mm against a ~0.5mm mantissa step
// eight kilometres out.
const float LATTICE_SLOTS = 128.0;

// Integer bit-mix over the lattice. `hash12` above CANNOT be used here: its
// input would be a cell index in the thousands, and `fract(large * 0.1031)`
// keeps only the mantissa bits that survive the multiply -- eight or so at
// world scale, which reads as banding rather than as noise. This mixes the
// integer coordinates themselves, so a cell's value does not depend on how far
// from the origin the cell is.
uint lattice_bits(uvec3 v) {
	v = v * 1664525u + 1013904223u;
	v.x += v.y * v.z;
	v.y += v.z * v.x;
	v.z += v.x * v.y;
	v ^= v >> 16u;
	v.x += v.y * v.z;
	v.y += v.z * v.x;
	v.z += v.x * v.y;
	return v.x;
}

// `tag` is BOTH halves of the slot tag, and it has to be: a cell carries items
// from several nested layers at once, layer 0's item 5 and layer 3's item 5
// share a tag.x, and hashing on tag.x alone put them at the same hashed spot.
// They then rendered exactly on top of each other and the field came out at
// the base layer's density with every other layer invisible underneath it --
// a third of the meadow's grass, silently, and it looked like a density bug
// in the plan rather than a hash that could not tell two items apart.
float lattice_rand(ivec2 cid, ivec2 tag, uint salt) {
	uvec3 v = uvec3(uint(cid.x + 4194304), uint(cid.y + 4194304),
			uint(tag.x * 131 + tag.y) * 9781u + salt);
	return float(lattice_bits(v)) * (1.0 / 4294967296.0);
}

// A layer is fully present inside `layer_in` and gone by `layer_out`. Guarded
// because `smoothstep` with two equal edges is a divide by zero, and an unset
// uniform array is all zeros.
float lattice_layer_want(int layer, float dist) {
	float near_r = layer_in[layer];
	float far_r = max(layer_out[layer], near_r + 0.001);
	return 1.0 - smoothstep(near_r, far_r, dist);
}

// Per-item yaw, applied here rather than carried in the instance basis. A yaw
// stored on the instance travels with the instance, so every item would spin
// on the spot each time the ring stepped a cell -- the same defect as the
// coverage re-roll, wearing a different hat.
vec2 lattice_yaw(vec2 v, float yaw) {
	float s = sin(yaw);
	float c = cos(yaw);
	return vec2(v.x * c + v.y * s, v.y * c - v.x * s);
}

// ---------------------------------------------------------------------------
// BUILT GROUND. Where something is standing, so nothing grows.
//
// The owner's 2026-08-28 report: "grass grows through indoor buildings now".
// `forbidden_ground` above is a terrain TEXTURE mask and a texture name cannot
// know that a farmhouse is standing on the grass it names, so the field grew
// through Grandpa's floor and his rug. `scatter_rules.gd` has gated every
// BAKED placement on a footprint list since that same defect was found in the
// scatter; `grass_field.gd::authored_footprints` reads that same list, adds
// whatever the player has built since, and pushes the nearest few here.
//
// `built_count` is ZERO across almost the whole corridor -- seven authored
// footprints in 16.8 km2 -- so the loop below is skipped outright nearly
// everywhere, and `built_bounds` rejects the rest of the ring in one test
// wherever it is not. Each entry is (x, z, radius) in world metres.
// ---------------------------------------------------------------------------
uniform vec3 built[24];
uniform int built_count = 0;
uniform vec3 built_bounds = vec3(0.0);

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

void vertex() {
	// STABLE RING. Which world cell is this instance standing in, and which of
	// that cell's items is it? The stored translation is a cell plus an
	// identity tag; everything about where the item really stands comes out of
	// the cell's integer coordinates, which is what makes it stay put when the
	// ring moves. See the STABLE RING note above.
	vec2 anchor = MODEL_MATRIX[3].xz;
	vec2 cell_f = floor(anchor / lattice_cell);
	ivec2 cid = ivec2(cell_f);
	ivec2 tag = ivec2(floor((anchor - cell_f * lattice_cell) / lattice_cell
			* LATTICE_SLOTS + 0.5));
	int lattice_layer = clamp(tag.y - 1, 0, 15);

	vec2 lattice_jit = vec2(lattice_rand(cid, tag, 11u),
			lattice_rand(cid, tag, 29u)) - 0.5;
	vec2 world_xz = (vec2(cid) + 0.5) * lattice_cell
			+ lattice_jit * lattice_cell * lattice_jitter;
	// What the geometry has to be shifted by to stand there instead of on the
	// cell tag, in the instance's own space -- the basis is identity now.
	vec2 lattice_shift = world_xz - anchor;
	float item_yaw = lattice_rand(cid, tag, 53u) * 6.2831853;
	float item_rank = lattice_rand(cid, tag, 71u);

	float dist = length(world_xz - field_centre.xz);
	v_fade = 1.0 - smoothstep(fade_start, field_radius, dist);
	// LAYER GROWTH. Dithered against the item's own stable rank so a fraction
	// of the layer is mid-growth at any moment rather than the whole ring
	// switching together. `* (1.0 - lod_dither)` keeps the top of the rank
	// range reachable, so a fully-present layer really is fully present.
	float item_thr = item_rank * (1.0 - lod_dither);
	float item_presence = smoothstep(item_thr, item_thr + lod_dither,
			lattice_layer_want(lattice_layer, dist));

	ivec3 coord = get_index_coord(world_xz * _vertex_density, 1);
	bool off_map = coord.z < 0;
	float ground_h = 0.0;
	uint control = 0u;
	vec3 ground_col = vec3(0.5);
	if (!off_map) {
		ground_h = texelFetch(_height_maps, coord, 0).r;
		control = floatBitsToUint(texelFetch(_control_maps, coord, 0)).r;
		ground_col = texelFetch(_color_maps, coord, 0).rgb;
	}
	int base_id = int(control >> 27u & 0x1Fu);
	bool hole = bool(control >> 2u & 0x1u);
	bool on_stone_ground = ((allowed_base_mask >> base_id) & 1) == 1;

	// Coverage. Stone is dense on its own ground and rare off it -- the strays
	// are what stop the gravel ending on the same hard line the grass mask was
	// criticised for.
	float drift = mix(1.0, value_noise(world_xz * clump_scale), clump_contrast);
	// The verge. Terrain3D's control word carries the blend between a cell's
	// base and overlay texture in bits 14-21, so a value in the MIDDLE of that
	// range means this cell is on a boundary between two ground types -- which,
	// beside a route, is the edge of the path. Grit concentrated there is what
	// turns "the grass simply stops" into a worn edge: a blind pass called the
	// boundary "a density edge rather than a material edge, and it looks cut",
	// and this is the material edge it was missing. Costs nothing -- the
	// control word is already fetched.
	float blend = float(control >> 14u & 0xFFu) * 0.003921568627450;
	float verge = 1.0 - abs(blend - 0.5) * 2.0;
	float keep = on_stone_ground
			? drift * density_gain
			: max(stray_chance, verge * verge * verge_gain);
	bool culled = off_map || hole || v_fade <= 0.001
			|| item_presence <= 0.002
			|| on_built_ground(world_xz)
			|| hash12(world_xz * 3.19) > keep;

	// NOT an early `return`. Godot's shading language rejects `return` inside
	// `vertex()` outright -- "Using 'return' in the 'vertex' processor function
	// is incorrect" -- and the failure is silent at run time in the worst way:
	// the shader does not compile, Godot substitutes a default material, and
	// the raw untransformed mesh renders at every instance as a dome of white
	// shards filling the sky. It looked exactly like a broken height lookup and
	// cost two render cycles chasing one. The grass field's own cull is an
	// if/else for the same reason; keep this one that way too.
	if (culled) {
		VERTEX = vec3(0.0);
		v_colour = vec3(0.0);
		v_contact = 0.0;
	} else {

	// `item_presence` is in the SIZE rather than in a second cull, so a stone
	// whose layer is arriving grows out of the ground instead of appearing.
	float size = stone_size * (1.0 + (hash12(world_xz * 5.77) - 0.5) * 2.0 * size_jitter)
			* item_presence;

	// Lie the stone against the slope by SHEARING it toward downhill, rather
	// than by building a world-space basis and writing VERTEX from it. The
	// basis version was the first attempt and it was wrong: VERTEX here is
	// instance-local and Godot still applies MODEL_MATRIX afterwards, so a
	// world-oriented basis gets rotated a second time by the instance's own
	// yaw. A shear composes with that rotation instead of fighting it, keeps
	// the per-instance yaw that gives the field its variety, and needs no
	// orthonormal frame to go wrong.
	//
	// The gradient is real, not guessed: height at one texel either side, which
	// is `1 / _vertex_density` metres. Two extra fetches, on a layer with a
	// fraction of the grass tier's instances.
	float step_m = 1.0 / _vertex_density;
	float hx = height_at(world_xz + vec2(step_m, 0.0)) - height_at(world_xz - vec2(step_m, 0.0));
	float hz = height_at(world_xz + vec2(0.0, step_m)) - height_at(world_xz - vec2(0.0, step_m));
	vec2 downhill = vec2(-hx, -hz) / (2.0 * step_m);

	vec3 local = VERTEX * size;
	local.xz += downhill * local.y * slope_lie;
	// The yaw the instance basis used to carry, and the offset onto the stone's
	// own hashed spot in its cell. In this order so the shear still composes
	// with the yaw exactly the way it did when Godot applied it.
	local.xz = lattice_yaw(local.xz, item_yaw) + lattice_shift;
	NORMAL.xz = lattice_yaw(NORMAL.xz, item_yaw);
	VERTEX = local;
	// Bury it. The mesh's y is 0 at the stone's base, so subtracting a fraction
	// of its own size puts the lower edge under the surface instead of standing
	// proud of it all the way round -- which is the whole "bedded" argument.
	VERTEX.y += ground_h - size * sink;

	// v_contact is 1 at the buried waterline and 0 at the crown; the fragment
	// stage darkens toward the ground with it, which is the occlusion a stone
	// this small will never get from the shadow map.
	v_contact = 1.0 - clamp(local.y / max(size * 0.42, 0.0001), 0.0, 1.0);

	vec3 stone = tint_stone * (1.0 + (hash12(world_xz * 2.71) - 0.5) * 2.0 * tint_jitter);
	v_colour = stone * mix(vec3(1.0), ground_col, ground_blend);
	}
}

void fragment() {
	if (v_fade <= 0.001) {
		discard;
	}
	ALBEDO = v_colour * (1.0 - v_contact * contact_darken);
	ROUGHNESS = 0.9;
	ALPHA = 1.0;
	ALPHA_SCISSOR_THRESHOLD = 0.5;
}
