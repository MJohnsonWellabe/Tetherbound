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
uniform float wind_scale = 0.09;
uniform vec2 wind_dir = vec2(0.86, 0.51);

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

void vertex() {
	// MODEL_MATRIX for a MultiMesh is node * instance, so column 3 is this
	// blade's own world origin. The node is kept unrotated and at y=0 by
	// `grass_field.gd`, so this is the blade's ground position in XZ and 0 in Y.
	vec3 base = MODEL_MATRIX[3].xyz;
	vec2 world_xz = base.xz;
	// Per-BLADE seed. UV2.x is which blade of the tuft this vertex belongs to
	// (see grass_field.gd::_tuft_mesh). Hashing on the instance origin alone
	// gives every blade in a tuft the same height and the same lean, which is
	// the "comb" read; offsetting the hash domain by the blade id breaks them
	// apart at no cost. Coverage and shade stay per-TUFT on purpose -- a tuft
	// should live or die as a unit, or the drifts dissolve into static.
	vec2 blade_seed = world_xz + vec2(UV2.x * 37.13, UV2.x * 91.71);

	float dist = length(world_xz - field_centre.xz);
	v_fade = 1.0 - smoothstep(fade_start, field_radius, dist);

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
	float keep = drift * density_gain;
	bool culled = off_map || hole || forbidden || v_fade <= 0.001
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

		// Bend. A blade of grass is not a spike: it leans, and each one leans a
		// different way. Without the per-blade term the whole field renders as
		// parallel vertical strokes, which reads as a rice paddy rather than a
		// meadow. `t * t` so the base stays planted and the tip does the
		// travelling.
		float wind = value_noise(world_xz * wind_scale + wind_dir * wind_time);
		float lean = (wind - 0.5) * 2.0 * wind_strength;
		float own_bend = (hash12(blade_seed * 11.13) - 0.5) * 2.0 * bend;
		float own_dir = hash12(blade_seed * 5.91) * 6.2831853;
		vec2 bend_dir = vec2(sin(own_dir), cos(own_dir));
		// The mesh carries x in [-0.5, 0.5] scaled by its own taper and y in
		// [0, 1]; width and height are applied here so one mesh serves every
		// blade size in the field.
		// The mesh now carries its own per-blade length, splay and curve (see
		// grass_field.gd::_tuft_mesh, and the blind critique that forced it).
		// So the shader SCALES that geometry rather than rebuilding it: an
		// earlier version overwrote local.y with `t * h`, which flattened every
		// blade in a tuft back to the same length and is exactly the "mown
		// ceiling" a critic measured. Width is scaled independently so the
		// blade's aspect ratio is tunable without touching its shape.
		vec3 local = VERTEX;
		local.x *= blade_width;
		local.z *= blade_width;
		local.y *= h;
		local.xz += (wind_dir * lean + bend_dir * own_bend) * t * t * h;
		// `t` is still UV.y (0 at the base, 1 at the tip) and drives the wind and
		// the per-blade lean above; the blade's own baked arc is already in
		// local.xz and is not recomputed here.

		VERTEX = local;
		// The blade's own normal faces up-ish, which keeps a field of them from
		// flickering as they turn edge-on to the sun.
		NORMAL = normalize(vec3(NORMAL.x * 0.35, 1.0, NORMAL.z * 0.35));
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
