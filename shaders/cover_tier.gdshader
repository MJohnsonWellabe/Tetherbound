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

uniform int allowed_base_mask = 3;

varying float v_t;
varying vec3 v_colour;
varying float v_fade;

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
	bool on_ground = ((allowed_base_mask >> base_id) & 1) == 1;

	float drift = mix(1.0, value_noise(world_xz * drift_scale), drift_contrast);
	bool culled = off_map || hole || !on_ground || v_fade <= 0.001
			|| hash12(world_xz * 4.41) > drift * density_gain;

	// NOT an early `return`: Godot rejects `return` inside `vertex()` and the
	// failure is silent -- the shader does not compile, a default material is
	// substituted, and the raw mesh renders at every instance. Paid for once
	// already on `stone_field.gdshader`.
	if (culled) {
		VERTEX = vec3(0.0);
		v_t = 0.0;
		v_colour = vec3(0.0);
	} else {
		float size = item_size * (1.0 + (hash12(world_xz * 6.13) - 0.5) * 2.0 * size_jitter);
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

		VERTEX = local;
		VERTEX.y += ground_h - size * sink;

		vec3 own = mix(tint_base, tint_tip, smoothstep(0.0, 0.85, v_t));
		own *= 1.0 + (hash12(world_xz * 2.29) - 0.5) * 2.0 * tint_jitter;
		// The base takes the terrain's own colour so growth comes OUT of the
		// ground. The colour map is a near-white MULTIPLIER, not a colour --
		// mixing toward it washes everything out, which cost a render cycle on
		// the grass tier before anyone read `terrain_playground.json`'s values.
		v_colour = own * mix(vec3(1.0), ground_col, ground_blend * (1.0 - v_t));
	}
}

void fragment() {
	if (v_fade <= 0.001) {
		discard;
	}
	ALBEDO = v_colour * (1.0 - (1.0 - smoothstep(0.0, 0.35, v_t)) * contact_darken);
	ROUGHNESS = 0.95;
	ALPHA = 1.0;
	ALPHA_SCISSOR_THRESHOLD = 0.5;
}
