shader_type spatial;

// GRASS-FIELD. A camera-relative grass carpet that stores no placements.
//
// WHY THIS EXISTS. `scripts/world/vegetation.gd` places every ground-cover
// instance as a stored transform, baked to `data/scatter/*.bin` and loaded at
// boot. `ralph/reports/WORLD_GRASS_2026-08-25.md` measured the ceiling that
// puts on the ground plane: a tuft covers ~0.33 m2, so the reference's
// continuous carpet needs ~1.5 tufts/m2, and the corridor is 16.8 km2 -- 25
// million placements against a 900,000 chapter ceiling. Roughly 40x out,
// however it is spent. Three blind rounds ranked "the player stands on a
// painting of grass with props stabbed into it" first, every time.
//
// This does not store anything. A fixed ring of blades follows the camera and
// each one is placed onto the terrain surface HERE, in the vertex shader, by
// sampling the same height data Terrain3D's own vertex shader samples. Cost is
// a function of the ring, not of the world, so it is the same at the village
// and eight kilometres down the corridor.
//
// THE REGION LOOKUP BELOW IS COPIED, NOT INVENTED. `get_index_coord` and the
// `texelFetch(_height_maps, ...)` that follows it are lifted verbatim from the
// shader Terrain3D 1.0.2 generates for its own terrain, read off the running
// material with `RenderingServer.shader_get_code()` --
// `tools/_probe_terrain3d_shader.gd` does that and writes the source out, and
// that tool exists precisely so this file is a copy rather than a rederivation.
// The addon ships here as a GDExtension binary with no C++ to consult, and
// getting this arithmetic subtly wrong does not error: it puts the grass a few
// metres under the ground and reads as "the shader does not work".
//
// NO COMPUTE, NO RENDERINGDEVICE, NO SSS. `docs/decisions/D01` locks this
// project to the GL Compatibility renderer -- the Ally freeze root-caused to a
// Forward+ stall -- and Godot lists compute shaders, subsurface scattering and
// RenderingDevice as unsupported there. Everything here is vertex maths, a
// texelFetch and an alpha scissor, all of which Compatibility has.

// `cull_disabled` because a blade is a single strip seen from both sides.
// `depth_prepass_alpha` + a scissor rather than `blend_mix`: overdraw from
// alpha-blended blades stacked in front of the camera is the real handheld
// risk here, and a scissor writes depth so the stack culls itself.
render_mode cull_disabled, depth_prepass_alpha, diffuse_lambert, specular_disabled;

// ---------------------------------------------------------------------------
// Terrain3D's own data. Every one of these is mirrored from the live terrain
// material each time the terrain streams -- see `grass_field.gd::_bind_terrain`
// -- rather than being configured here, so this cannot drift out of step with
// what the terrain is actually rendering.
// ---------------------------------------------------------------------------
uniform highp sampler2DArray _height_maps : repeat_disable;
uniform highp sampler2DArray _control_maps : repeat_disable;
uniform highp sampler2DArray _color_maps : source_color, filter_linear, repeat_disable;
uniform int _region_map[1024];
uniform float _region_size = 256.0;
uniform float _region_texel_size = 0.00390625;
uniform int _region_map_size = 32;
uniform float _vertex_density = 0.5;

// ---------------------------------------------------------------------------
// The field itself.
// ---------------------------------------------------------------------------
// Where the ring is centred this frame, snapped, in world space. The blades
// live in the node's local space; this is what they are offset from.
uniform vec3 field_centre = vec3(0.0);
// Blades stop at `field_radius` and start thinning at `fade_start`. The fade
// is wide on purpose: a hard cutoff on the densest layer in the world is the
// bald ring three blind rounds named, and reintroducing it here would be the
// same defect with a new mechanism.
uniform float field_radius = 48.0;
uniform float fade_start = 30.0;
// EDGE SHORTENING. `v_fade` gates a fragment discard and the coverage hash
// gates a vertex cull, so before this the blades only THINNED toward the ring's
// edge -- at full height, right up to the last one. The carpet therefore
// STOPPED rather than ran out, and the owner's words on the result were that
// "the transition from real grass to paint is still very noticable". Pushing
// `field_radius` out moved that seam without removing it, twice. A blade that
// shortens as well as thins sinks into the terrain instead, and has nowhere
// visible to end.
//
// `edge_shorten_floor` is the height multiplier at the very edge and
// `edge_shorten_bias` is the curve: below 1.0 it holds full height through most
// of the fade and takes it off at the end, which matters because the fade is
// 30m wide and a linear multiply would dock a third of the height from blades
// well inside the ring, where they are the ones being looked at.
uniform float edge_shorten_floor : hint_range(0.0, 1.0) = 0.0;
uniform float edge_shorten_bias : hint_range(0.05, 4.0) = 0.4;

// Blade size. `height_near`/`height_far` grow the blade with distance so it
// stays a few pixels tall instead of shimmering away into noise -- the cheap
// half of what an impostor LOD does.
// A MULTIPLIER, not a width. The mesh is authored in metres (an 11mm blade
// half-width, 75mm of spread between the blades of a tuft); this scales both
// together so a tuft stays a tuft instead of collapsing into one wide leaf.
uniform float blade_width = 1.0;
uniform float height_near = 0.55;
uniform float height_far = 0.95;
uniform float height_jitter = 0.45;
// How far a blade leans from vertical, in metres of tip travel, before wind.
uniform float bend = 0.18;
// Per-blade value spread. One flat green over a whole field reads as a
// texture; this is the cheapest way to give it depth without a second tint.
uniform float shade_jitter : hint_range(0.0, 1.0) = 0.22;

// Coverage. `density_gain` scales the keep-chance; the two noise scales are
// what re-express the authored composition GROUND-LAYERS settled on (roughly
// 70% open grass / 15% path / 10% low accents / 5% special) as drifts and
// clearings rather than as a uniform lawn.
uniform float density_gain : hint_range(0.0, 1.0) = 0.82;
uniform float clump_scale = 0.035;
uniform float clump_contrast : hint_range(0.0, 1.0) = 0.55;

// Colour. `tint_base`/`tint_tip` are the base-to-tip gradient a blind critic
// named as missing from the scattered tufts ("flat two-tone polygon, no
// base-to-tip gradient, no translucency"); `ground_blend` mixes the terrain's
// own colour map into the base of every blade, which is the other half of that
// finding -- the razor line where a tuft meets the terrain.
uniform vec3 tint_base : source_color = vec3(0.208, 0.267, 0.106);
uniform vec3 tint_tip : source_color = vec3(0.514, 0.588, 0.239);
uniform float ground_blend : hint_range(0.0, 1.0) = 0.65;
uniform float translucency : hint_range(0.0, 1.0) = 0.35;

// Wind. Free here, and the reference frames are of moving grass.
uniform float wind_time = 0.0;
uniform float wind_strength = 0.10;
// GUST-WAVE. A travelling front on top of the ambient breeze. Without it the
// whole field leans together, which reads as a wobble; a front crossing the
// meadow reads as weather, and the owner's reference frames are of moving
// grass. `gust_speed` is metres per second of front travel, `gust_length` its
// wavelength in metres. Free -- one sine over a dot product the shader is
// already computing.
uniform float gust : hint_range(0.0, 1.0) = 0.0;
uniform float gust_speed = 7.0;
uniform float gust_length = 26.0;
uniform float wind_scale = 0.09;
uniform vec2 wind_dir = vec2(0.86, 0.51);

// CLEARINGS. Where the bush tier gathers, the grass gives way: fewer blades and
// shorter ones, because a bush shades out what grows beneath it. Without this
// the two tiers simply occupy the same ground and blades pass straight through
// leaves, which reads as two systems drawn over each other rather than as one
// meadow.
//
// The three shape numbers are THE BUSH TIER'S OWN drift field, pushed in by
// `grass_field.gd` from the same `cover_tiers` entry the bushes are built from.
// Copying them by hand would be one edit away from thinning the grass somewhere
// the bushes are not. `clearing_strength` 0 disables the whole thing, which is
// what the config ships as if no tier claims clearings.
uniform float clearing_scale = 0.05;
uniform float clearing_contrast : hint_range(0.0, 1.0) = 0.88;
uniform float clearing_strength : hint_range(0.0, 1.0) = 0.0;
// Only the STRONGEST part of the bush drift clears. The drift runs roughly
// 0.12-1.0 and bushes themselves only take a fraction of it, so clearing
// everywhere the field is merely above average would thin a third of the meadow
// for the sake of a tenth of it.
uniform float clearing_floor : hint_range(0.0, 1.0) = 0.78;
uniform float clearing_shorten : hint_range(0.0, 1.0) = 0.45;

// Which terrain textures grass refuses to grow on, as a bitmask over base
// texture id. `terrain_playground.json`'s texture list is
// 0 grass, 1 soil/verge, 2 rock, 3 path, 4 damp, 5 forest floor -- so the
// default refuses rock and path. Set from config, not hardcoded here.
uniform int forbidden_base_mask = 12;

varying float v_blade_t;
varying vec3 v_ground_colour;
varying float v_fade;
varying float v_shade;

// ---------------------------------------------------------------------------
// COPIED VERBATIM from Terrain3D 1.0.2's generated shader. Do not "clean up".
// The `search` loop walks to a neighbouring region when a lookup lands exactly
// on a region seam; dropping it puts a seam of floating or sunken blades along
// every 256-texel boundary in the world.
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

// Cheap value noise. Two octaves is enough for "drifts with clearings between
// them"; this is not trying to be a terrain generator.
float hash12(vec2 p) {
	vec3 p3 = fract(vec3(p.xyx) * 0.1031);
	p3 += dot(p3, p3.yzx + 33.33);
	return fract((p3.x + p3.y) * p3.z);
}

// The domain is rotated before sampling. An axis-aligned value-noise lattice
// puts its features on horizontal and vertical lines, and over a whole ground
// plane that reads as ranks -- a blind critic named "distinct horizontal
// stripes, bands of blades separated by strips of bare ground" as the loudest
// procedural signature in the set. A 31-degree rotation costs two multiplies
// and takes the lattice off the world axes.
const mat2 NOISE_ROT = mat2(vec2(0.857, 0.515), vec2(-0.515, 0.857));

float value_noise(vec2 q) {
	vec2 p = NOISE_ROT * q;
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash12(i), hash12(i + vec2(1.0, 0.0)), f.x),
			mix(hash12(i + vec2(0.0, 1.0)), hash12(i + vec2(1.0, 1.0)), f.x), f.y);
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

float lattice_rand(ivec2 cid, int tag, uint salt) {
	uvec3 v = uvec3(uint(cid.x + 4194304), uint(cid.y + 4194304),
			uint(tag) * 9781u + salt);
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

	vec2 lattice_jit = vec2(lattice_rand(cid, tag.x, 11u),
			lattice_rand(cid, tag.x, 29u)) - 0.5;
	vec2 world_xz = (vec2(cid) + 0.5) * lattice_cell
			+ lattice_jit * lattice_cell * lattice_jitter;
	// What the geometry has to be shifted by to stand there instead of on the
	// cell tag, in the instance's own space -- the basis is identity now.
	vec2 lattice_shift = world_xz - anchor;
	float item_yaw = lattice_rand(cid, tag.x, 53u) * 6.2831853;
	float item_rank = lattice_rand(cid, tag.x, 71u);

	// Per-BLADE seed. UV2.x is which blade of the tuft this vertex belongs to
	// (see grass_field.gd::_tuft_mesh). Hashing on the tuft position alone
	// gives every blade in a tuft the same height and the same lean, which is
	// the "comb" read; offsetting the hash domain by the blade id breaks them
	// apart at no cost. Coverage and shade stay per-TUFT on purpose -- a tuft
	// should live or die as a unit, or the drifts dissolve into static.
	vec2 blade_seed = world_xz + vec2(UV2.x * 37.13, UV2.x * 91.71);

	// `field_centre` is the EYE, written unquantised every frame, while the
	// node hops in whole cells. Every fade below is therefore continuous;
	// reading the ring's own position here is what used to make them step.
	float dist = length(world_xz - field_centre.xz);
	v_fade = 1.0 - smoothstep(fade_start, field_radius, dist);
	// LAYER GROWTH. Dithered against the item's own stable rank so a fraction
	// of the layer is mid-growth at any moment rather than the whole ring
	// switching together. `* (1.0 - lod_dither)` keeps the top of the rank
	// range reachable, so a fully-present layer really is fully present.
	float item_thr = item_rank * (1.0 - lod_dither);
	float item_presence = smoothstep(item_thr, item_thr + lod_dither,
			lattice_layer_want(lattice_layer, dist));

	// Terrain height, by Terrain3D's own lookup.
	ivec3 coord = get_index_coord(world_xz * _vertex_density, 1);
	float ground_h = 0.0;
	uint control = 0u;
	vec3 ground_col = vec3(0.35, 0.40, 0.20);
	bool off_map = coord.z < 0;
	if (!off_map) {
		ground_h = texelFetch(_height_maps, coord, 0).r;
		control = floatBitsToUint(texelFetch(_control_maps, coord, 0)).r;
		ground_col = texelFetch(_color_maps, coord, 0).rgb;
	}
	v_ground_colour = ground_col;

	// What the terrain says is underfoot. Base texture id lives in the top five
	// bits; this is the same decode the generated shader's fragment stage does.
	int base_id = int(control >> 27u & 0x1Fu);
	bool hole = bool(control >> 2u & 0x1u);
	bool forbidden = ((forbidden_base_mask >> base_id) & 1) == 1;

	// Coverage: two octaves of noise decide whether this blade exists at all,
	// so the field reads as drifts with open ground between them rather than a
	// uniform lawn. `hash12` on the blade's own position is the per-blade roll.
	float drift = value_noise(world_xz * clump_scale);
	drift = mix(1.0, drift, clump_contrast);
	// The bush tier's drift, evaluated with the bush tier's own numbers. Same
	// `value_noise` and the same `mix(1.0, ...)` shape `cover_tier.gdshader`
	// uses, so this is the identical field and not an approximation of it.
	float clearing = 0.0;
	if (clearing_strength > 0.001) {
		float bush_drift = mix(1.0, value_noise(world_xz * clearing_scale), clearing_contrast);
		clearing = smoothstep(clearing_floor, 1.0, bush_drift) * clearing_strength;
	}
	float keep = drift * density_gain * (1.0 - clearing);
	bool culled = off_map || hole || forbidden || v_fade <= 0.001
			|| item_presence <= 0.002
			|| hash12(world_xz * 7.31) > keep;

	v_shade = 1.0 + (hash12(world_xz * 2.17) - 0.5) * 2.0 * shade_jitter;

	if (culled) {
		// Collapse to a point. The cheapest cull available in a vertex shader,
		// and it costs no branch in the fragment stage.
		VERTEX = vec3(0.0);
		v_blade_t = 0.0;
	} else {
		// UV.y runs 0 at the blade's base to 1 at its tip; the mesh is built
		// that way in grass_field.gd.
		float t = UV.y;
		v_blade_t = t;

		float h = mix(height_near, height_far, smoothstep(0.0, field_radius, dist));
		h *= 1.0 + (hash12(blade_seed * 3.77) - 0.5) * 2.0 * height_jitter;
		// Shorter under a bush as well as sparser. Thinning alone leaves the
		// survivors at full height, still standing through the leaves.
		h *= 1.0 - clearing * clearing_shorten;
		// And shorter at the ring's edge, for the same reason at a different
		// scale -- see `edge_shorten_floor` above.
		h *= mix(edge_shorten_floor, 1.0, pow(v_fade, edge_shorten_bias));
		// And shorter while its lattice layer is still arriving, which is the
		// only reason a blade's height changes as the player walks now.
		h *= item_presence;

		// Bend. A blade of grass is not a spike: it leans, and each one leans a
		// different way. Without the per-blade term the whole field renders as
		// parallel vertical strokes, which reads as a rice paddy rather than a
		// meadow. `t * t` so the base stays planted and the tip does the
		// travelling.
		float wind = value_noise(world_xz * wind_scale + wind_dir * wind_time);
		float lean = (wind - 0.5) * 2.0 * wind_strength;
		// The front, projected onto the wind direction so it sweeps ACROSS the
		// field rather than everything leaning at once. Half-wave rectified:
		// grass is pushed over by a gust and springs back, it is not blown
		// backwards between them.
		if (gust > 0.001) {
			float along = dot(world_xz, normalize(wind_dir));
			float front = sin((along - wind_time * gust_speed) * 6.2831853 / gust_length);
			lean += max(front, 0.0) * gust * wind_strength * 2.0;
		}
		float own_bend = (hash12(blade_seed * 11.13) - 0.5) * 2.0 * bend;
		float own_dir = hash12(blade_seed * 5.91) * 6.2831853;
		vec2 bend_dir = vec2(sin(own_dir), cos(own_dir));
		// The mesh carries x in [-0.5, 0.5] scaled by its own taper and y in
		// [0, 1]; width and height are applied here so one mesh serves every
		// blade size in the field.
		vec3 local = VERTEX;
		local.x *= blade_width;
		local.z *= blade_width;
		local.y = t * h;
		local.xz += (wind_dir * lean + bend_dir * own_bend) * t * t * h;

		// Yaw, then stand it on its hashed spot rather than on its cell tag.
		// Both were the instance transform's job before and are the shader's
		// now, for the same reason: anything carried by the instance travels
		// with the instance when the ring steps.
		local.xz = lattice_yaw(local.xz, item_yaw) + lattice_shift;
		VERTEX = local;
		// The blade's own normal faces up-ish, which keeps a field of them from
		// flickering as they turn edge-on to the sun.
		NORMAL = normalize(vec3(NORMAL.x * 0.35, 1.0, NORMAL.z * 0.35));
		NORMAL.xz = lattice_yaw(NORMAL.xz, item_yaw);
	}

	// Finally: sit the whole blade on the ground. Done after the local build so
	// the height applies to base and tip alike.
	VERTEX.y += ground_h;
}

void fragment() {
	if (v_blade_t <= 0.0 && v_fade <= 0.001) {
		discard;
	}
	// The base of the blade takes the terrain's own colour, so growth appears
	// to come OUT of the ground instead of standing on a picture of it. That is
	// the "razor line where a tuft meets the terrain" three blind rounds named.
	// The terrain's colour map is a MULTIPLIER over its albedo textures, not a
	// colour -- `terrain_playground.json`'s own entries are near-white
	// (#f7f8f2, #fbfbf6). Mixing TOWARD it, which is what this did first,
	// washed every blade base out to near-white and made the whole field read
	// pale and plasticky. Multiplying by it is the same thing the terrain
	// shader does, and it picks up the ground's own variation without
	// destroying the tint.
	vec3 root = tint_base * mix(vec3(1.0), v_ground_colour, ground_blend);
	vec3 col = mix(root, tint_tip, smoothstep(0.0, 0.85, v_blade_t));
	ALBEDO = col * v_shade;
	ROUGHNESS = 0.95;
	// Cheap stand-in for the light that passes through a blade. Compatibility
	// has no subsurface scattering, so this lifts the tip toward the tint
	// rather than pretending to be transmission.
	BACKLIGHT = tint_tip * translucency * v_blade_t;
	ALPHA = 1.0;
	ALPHA_SCISSOR_THRESHOLD = 0.5;
}
