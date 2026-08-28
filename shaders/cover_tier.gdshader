shader_type spatial;

// COVER-TIER. The generic plant tier on the camera-relative ring: small bushes,
// flower drifts and forest litter all run through this one shader, differing
// only by mesh and config.
//
// WHY GENERIC. `grass_field.gdshader` and `stone_field.gdshader` each earned
// their own file -- grass carries per-blade bend and a tuft of tapered strips,
// stone lies with the slope and buries itself. Everything after them is the
// same shader with different numbers: something small, non-colliding and
// storable-nowhere, placed where the terrain says one kind of ground is, with a
// tint gradient from base to tip and a contact darken where it meets the
// ground. Writing that three times would be three places to fix one bug.
//
// WHAT MAY AND MAY NOT LIVE HERE, because it is the whole design rule and it is
// easy to get wrong: a tier is generated only if it (a) does not collide,
// (b) carries no persistent state, (c) is small enough that appearing at the
// ring's edge is invisible, and (d) exists in numbers too large to store.
// Grass, gravel, litter, flowers and DECORATIVE bushes pass all four. Trees and
// boulders fail (a), (b) and (c) -- they are landmarks, they stop the camera's
// SpringArm, and they must be in the same place when the player returns.
// HARVESTABLE bushes fail (b): `vegetation.json`'s `bushes` layer carries
// `harvest_item: fiber`, and harvesting needs an identity that survives, which a
// thing that does not exist until the camera nears it cannot have. So the
// harvestable bushes stay scattered and this tier is the understorey around
// them. `tests/test_grass_field.gd` enforces the collides/harvest half of that
// rule against `vegetation.json` directly.
//
// Same renderer constraints as the other two: no compute, no RenderingDevice,
// no subsurface scattering -- `D01` locks this project to GL Compatibility.

render_mode cull_disabled, depth_prepass_alpha, diffuse_lambert, specular_disabled;

// Terrain3D's own data, mirrored from the live material by
// `grass_field.gd::_bind_terrain`, which binds every tier's material.
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

uniform float item_size = 0.35;
uniform float size_jitter : hint_range(0.0, 1.0) = 0.5;
// Fraction of its own height the item is buried, so its base is under the
// surface rather than standing proud of it. The "bedded" argument, again.
uniform float sink : hint_range(0.0, 1.0) = 0.12;
// 1 lies the item flat against the terrain gradient (litter); 0 stands it
// upright out of a bank (a bush grows toward the sun, not the slope normal).
uniform float slope_lie : hint_range(0.0, 2.0) = 0.0;

// Coverage. `drift_scale` is the frequency of the clumping noise: LOW numbers
// are broad drifts, which is what a flower patch wants -- a blind pass measured
// the reference's pink drift running across ~40% of frame width against two
// isolated flower bushes in twelve of ours.
uniform float density_gain : hint_range(0.0, 1.0) = 0.35;
uniform float drift_scale = 0.06;
uniform float drift_contrast : hint_range(0.0, 1.0) = 0.85;

// NORMAL SOFTENING. How far each item's own normals are bent toward world up.
// Without it every leaf of one bush takes a wildly different lambert term and a
// blind pass read the result exactly: "identical quads sit side by side with one
// near-black and one bright green -- they do not share a lighting response...
// a heap of large untextured flat quads". A bush is a MASS and its leaves have
// to light like one. The grass tier does the same thing to its blades for the
// same reason, and on a renderer with no subsurface term available it is the
// only thing standing between opaque flat quads and something that reads as
// foliage.
uniform float normal_soften : hint_range(0.0, 1.0) = 0.6;

uniform vec3 tint_base : source_color = vec3(0.20, 0.26, 0.11);
uniform vec3 tint_tip : source_color = vec3(0.42, 0.50, 0.20);
uniform float tint_jitter : hint_range(0.0, 1.0) = 0.18;
uniform float ground_blend : hint_range(0.0, 1.0) = 0.4;
uniform float contact_darken : hint_range(0.0, 1.0) = 0.35;

// Wind. `sway` is metres of tip travel; 0 for litter, which does not move.
uniform float wind_time = 0.0;
uniform float sway : hint_range(0.0, 1.0) = 0.06;
uniform float wind_scale = 0.09;
uniform vec2 wind_dir = vec2(0.86, 0.51);
// GUST-WAVE. A travelling front rather than a uniform breathe: the whole field
// leaning together at once reads as a wobble, where a gust crossing it reads as
// weather. `gust_speed` is metres per second of front travel and `gust_length`
// its wavelength in metres.
uniform float gust : hint_range(0.0, 1.0) = 0.0;
uniform float gust_speed = 7.0;
uniform float gust_length = 26.0;

// LEAF-CUT. The instrument the bushes needed and four rounds missed. They
// failed as five big crossed panels, then twenty quads, then forty-four small
// leaves, then softened normals and a lifted base tint -- each helped, none
// fixed it, because the defect was never size, count, tint or lighting. Every
// leaf was an opaque QUAD, and a rectangle does not read as a leaf however it
// is lit. A blind critic's words on the last version: "a heap of large
// untextured flat quads in three flat greens, hard-edged".
//
// So the quad is only the leaf's bounding box and this carves the outline out
// of it in the fragment stage, procedurally, against the leaf-local coordinate
// `grass_field.gd::_bush_mesh` writes into UV2. It costs NO ASSET, which is the
// point: `CLAUDE.md` forbids new Meadows art, and the previous round filed
// "needs a bush asset that is not loose quads" as an art gap. It is not an art
// gap. `depth_prepass_alpha` and `ALPHA_SCISSOR_THRESHOLD` were already
// declared for exactly this; `ALPHA` was simply pinned at 1.0.
//
// 0 disables it and the tier renders as solid quads again -- correct for the
// flower, whose petals are already shaped by their own geometry and whose
// silhouette is settled.
uniform float leaf_cut : hint_range(0.0, 1.0) = 0.0;
// How deep the edge notches bite. Enough to break the outline, not so much that
// the leaf becomes a comb.
uniform float leaf_serrate : hint_range(0.0, 0.6) = 0.22;
uniform float leaf_teeth = 5.0;
// PER-LEAF SHADING, and the defect it answers is NOT the one `leaf_cut` fixes.
// With the outline cut, a blind pass stopped calling the bushes "a heap of flat
// quads" and started calling them "flat clipart: two or three flat fill colours,
// hard vector edges, zero shading gradient", naming the reference's own ground
// cover as "a shaded volume that darkens toward its base" and saying plainly
// that "the difference is not resolution or budget -- it is that the
// reference's cards are shaded and yours are not".
//
// The cause is that `v_t` runs up the whole BUSH, so every leaf in one ring
// takes the same albedo and a ring becomes a band of one flat fill. A leaf is a
// shaded volume in miniature: dark where it attaches to the stem, lit at the
// tip, and no two on one plant quite the same. `leaf_root_darken` is the first
// of those and `leaf_tint_jitter` the second, and both read the SAME UV2 the
// mask already fetches -- this costs nothing that is not already in registers.
//
// Deliberately albedo rather than normals: `normal_soften` above exists because
// an earlier round had one leaf near-black beside one bright green, and undoing
// it to get a gradient would buy this defect back at the price of that one.
uniform float leaf_root_darken : hint_range(0.0, 1.0) = 0.45;
uniform float leaf_tint_jitter : hint_range(0.0, 1.0) = 0.22;

// WOOD. `grass_field.gd::_bush_mesh` marks trunk and branch vertices with
// UV2.y = 2.0; every leaf seed is in [0, 1), so the flag cannot collide with
// one. Wood must escape two things the leaves want: the outline cut, which
// would eat a twig from both ends, and the leaf tint gradient, because a
// branch is not a small green leaf.
//
// The branches exist because the owner looked at the cut-leaf version and said
// the bushes "can't just be random leaves in the air. there needs to be some
// sort of stick connecting the leaves". Correct, and not a tuning note: the
// old mesh placed leaves on concentric rings so no leaf's stem end touched
// anything at all.
uniform vec3 tint_wood : source_color = vec3(0.28, 0.22, 0.13);

uniform int allowed_base_mask = 3;

varying float v_t;
varying vec3 v_colour;
varying float v_fade;
varying float v_wood;

// COPIED VERBATIM from Terrain3D 1.0.2's generated shader, same as the other
// two tiers and for the same reason -- see `grass_field.gdshader`'s note.
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
	bool on_ground = ((allowed_base_mask >> base_id) & 1) == 1;

	float drift = mix(1.0, value_noise(world_xz * drift_scale), drift_contrast);
	bool culled = off_map || hole || !on_ground || v_fade <= 0.001
			|| item_presence <= 0.002
			|| hash12(world_xz * 4.41) > drift * density_gain;

	// NOT an early `return`: Godot rejects `return` inside `vertex()` and the
	// failure is silent -- the shader does not compile, a default material is
	// substituted, and the raw mesh renders at every instance. Paid for once
	// already on `stone_field.gdshader`.
	v_wood = UV2.y > 1.5 ? 1.0 : 0.0;

	if (culled) {
		VERTEX = vec3(0.0);
		v_t = 0.0;
		v_colour = vec3(0.0);
	} else {
		// `item_presence` is in the SIZE, so a bush whose layer is arriving
		// grows rather than appearing.
		float size = item_size * (1.0 + (hash12(world_xz * 6.13) - 0.5) * 2.0 * size_jitter)
				* item_presence;
		v_t = UV.y;

		vec3 local = VERTEX * size;

		// Lie with the slope, for anything that should follow the ground rather
		// than grow out of it. Gradient from one texel either side, the same
		// way the stone tier does it.
		if (slope_lie > 0.001) {
			float step_m = 1.0 / _vertex_density;
			float hx = height_at(world_xz + vec2(step_m, 0.0)) - height_at(world_xz - vec2(step_m, 0.0));
			float hz = height_at(world_xz + vec2(0.0, step_m)) - height_at(world_xz - vec2(0.0, step_m));
			local.xz += (vec2(-hx, -hz) / (2.0 * step_m)) * local.y * slope_lie;
		}

		// Wind, with an optional travelling gust front on top. `gust` projects
		// the item's own position onto the wind direction, so the front sweeps
		// ACROSS the field instead of every item leaning at once.
		if (sway > 0.001) {
			float breeze = (value_noise(world_xz * wind_scale + wind_dir * wind_time) - 0.5) * 2.0;
			float front = 0.0;
			if (gust > 0.001) {
				float along = dot(world_xz, normalize(wind_dir));
				front = sin((along - wind_time * gust_speed) * 6.2831853 / gust_length);
				front = max(front, 0.0) * gust;
			}
			local.xz += wind_dir * (breeze * sway + front * sway * 2.0) * v_t * v_t;
		}

		// The yaw the instance basis used to carry, and the offset onto this
		// item's own hashed spot in its cell.
		local.xz = lattice_yaw(local.xz, item_yaw) + lattice_shift;
		VERTEX = local;
		VERTEX.y += ground_h - size * sink;

		vec3 own = mix(tint_base, tint_tip, smoothstep(0.0, 0.85, v_t));
		own = mix(own, tint_wood, v_wood);
		own *= 1.0 + (hash12(world_xz * 2.29) - 0.5) * 2.0 * tint_jitter;
		// The base takes the terrain's own colour so growth comes OUT of the
		// ground. The colour map is a near-white MULTIPLIER, not a colour --
		// mixing toward it washes everything out, which cost a render cycle on
		// the grass tier before anyone read `terrain_playground.json`'s values.
		v_colour = own * mix(vec3(1.0), ground_col, ground_blend * (1.0 - v_t));

		NORMAL = normalize(mix(NORMAL, vec3(0.0, 1.0, 0.0), normal_soften));
		NORMAL.xz = lattice_yaw(NORMAL.xz, item_yaw);
	}
}

// Half-width of the leaf at `v` along its own length: nothing at the stem end,
// broadest a little under halfway, closing to a point at the tip. 1.99
// normalises the peak of v^0.45 * (1-v)^0.55 to 1.0, so the outline uses the
// full width of the quad where it is widest rather than wasting it.
float leaf_profile(float v, float u, float seed) {
	float p = 1.99 * pow(clamp(v, 0.0, 1.0), 0.45) * pow(clamp(1.0 - v, 0.0, 1.0), 0.55);
	// The two edges run at different phases, so the outline is not a mirror of
	// itself -- a perfectly symmetric leaf still reads as a manufactured shape,
	// which is the failure this whole function exists to fix.
	float side = u < 0.0 ? 0.0 : 0.5;
	p *= 1.0 - leaf_serrate * (0.5 + 0.5 * sin((v * leaf_teeth + seed + side) * 6.2831853));
	return p;
}

void fragment() {
	if (v_fade <= 0.001) {
		discard;
	}
	ALPHA = 1.0;
	ALPHA_SCISSOR_THRESHOLD = 0.5;
	// Contact darken along the BUSH: its underside is in its own shade.
	float shade = 1.0 - (1.0 - smoothstep(0.0, 0.35, v_t)) * contact_darken;
	if (leaf_cut > 0.001 && v_wood < 0.5) {
		// UV.x is the leaf's own width; UV.y is NOT its length -- that runs up
		// the whole bush and the tint gradient reads it. UV2 carries the
		// leaf-local length and this leaf's own seed.
		float u = (UV.x - 0.5) * 2.0;
		float mask = leaf_profile(UV2.x, u, UV2.y) - abs(u);
		// Ramped rather than stepped so the scissor cuts on the outline itself
		// (mask crosses zero exactly there) instead of on a quantised edge.
		ALPHA = mix(1.0, clamp(0.5 + mask * 4.0, 0.0, 1.0), leaf_cut);
		// And the same gradient again one scale down, along each leaf.
		shade *= mix(1.0 - leaf_root_darken, 1.0, smoothstep(0.0, 0.55, UV2.x));
		// Decorrelated from the seed the outline uses, so a leaf that happens
		// to be cut narrow is not also always the dark one.
		shade *= 1.0 + (fract(UV2.y * 7.31) - 0.5) * 2.0 * leaf_tint_jitter;
	}
	ALBEDO = v_colour * shade;
	ROUGHNESS = 0.95;
}
