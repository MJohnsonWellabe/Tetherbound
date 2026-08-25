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

void vertex() {
	vec3 base = MODEL_MATRIX[3].xyz;
	vec2 world_xz = base.xz;
	float dist = length(world_xz - field_centre.xz);
	v_fade = 1.0 - smoothstep(fade_start, field_radius, dist);

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
	float keep = on_stone_ground ? drift * density_gain : stray_chance;
	bool culled = off_map || hole || v_fade <= 0.001
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

	float size = stone_size * (1.0 + (hash12(world_xz * 5.77) - 0.5) * 2.0 * size_jitter);

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
