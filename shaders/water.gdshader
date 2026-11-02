shader_type spatial;
render_mode blend_mix, cull_disabled, specular_schlick_ggx;

// EV5 — the stylised water surface (bible §15). One material shared by the
// pond plane and the stream ribbon, both built by scripts/world/water.gd.
//
// The load-bearing trick: `terrain_height` is a texture of the BAKED
// heightfield over the water region, generated at build time by sampling the
// same playground_heightfield.gd the terrain itself was baked from. Water
// depth at any fragment is then just (surface y − sampled ground y), which
// buys per-pixel shallow-edge colour, a feathered waterline and a foam band
// with no depth-texture readback at all — the depth prepass approach is
// unreliable on the gl_compatibility renderer this project ships with, and
// per-vertex depth would quantise the shoreline to the mesh grid.
//
// Everything here is cheap by construction: two scrolling noise-normal
// samples, one heightmap sample, one foam-noise sample. No reflection probe,
// no refraction, no screen texture, no simulation — bible §15's own "do not
// build a physically expensive simulation" is the spec.

// World-rect the heightmap covers: xy = min corner (world XZ), zw = size.
uniform vec4 region;
// Terrain height, R channel, normalised over [height_min, height_max].
uniform sampler2D terrain_height;
uniform float height_min = -30.0;
uniform float height_max = -14.0;
// Realm surfaces may extend beyond their baked height rectangle. Disabled by
// default so existing users retain the original wrap behavior.
uniform bool outside_region_deep_water = false;

uniform vec4 deep_colour: source_color = vec4(0.11, 0.32, 0.38, 1.0);
uniform vec4 shallow_colour: source_color = vec4(0.48, 0.68, 0.58, 1.0);
// How many metres of depth it takes to reach the deep colour.
uniform float depth_falloff = 1.6;
// F39 P2-009: a middle band so open water is a gradient from shallow through
// a mid shelf to the deep colour, instead of one ramp that saturates and then
// reads as a hard navy band at the shelf edge. mid_depth_m <= 0 keeps the old
// two-colour ramp exactly. depth_band_break_m wanders the depth every colour
// ramp reads (the Tidewake offshore variant's included), so no ramp draws a
// straight contour over a flat seabed; 0 keeps the measured depth everywhere.
uniform vec4 mid_colour: source_color = vec4(0.11, 0.32, 0.38, 1.0);
uniform float mid_depth_m = 0.0;
uniform float depth_band_break_m = 0.0;
uniform float alpha_deep = 0.88;
uniform float alpha_shallow = 0.42;
// Fade alpha to zero over this many metres of depth right at the shoreline,
// so the waterline meets the bank as a soft lap rather than an aliased cut.
uniform float edge_feather = 0.10;

uniform vec4 foam_colour: source_color = vec4(0.92, 0.95, 0.93, 1.0);
// Water shallower than this can carry foam (the shore contact band).
uniform float foam_depth = 0.30;
uniform sampler2D foam_noise;
uniform float foam_scale = 0.14;
uniform float foam_speed = 0.03;
// T4 surf line: a narrow broken foam line right at the waterline, so a shore
// reads as surf instead of a hard sand/water cut. The breakup threshold keeps
// it in long irregular stretches (never the solid drawn ring blind round 1
// rejected). surf_strength 0 keeps the original contact foam exactly.
uniform float surf_strength = 0.0;
uniform float surf_depth_m = 0.35;
uniform float surf_breakup = 0.4;
// 0..1: how much the surf band's reach wanders along the shore (a broad
// world-space noise), so it never reads as one even drawn line.
uniform float surf_vary = 0.0;

uniform sampler2D wave_normal_a;
uniform sampler2D wave_normal_b;
// Metres per noise tile, as 1/scale.
uniform float wave_uv_scale = 0.09;
uniform float wave_speed = 0.016;
uniform float wave_strength = 0.35;

uniform vec4 fresnel_colour: source_color = vec4(0.73, 0.78, 0.81, 1.0);
uniform float fresnel_power = 4.0;
uniform float fresnel_strength = 0.65;
uniform float roughness_value = 0.12;

// EV5-remainder — the flowing-water variant. The stream ribbon writes its
// own course parameterisation into UV2 (x = metres ALONG the course, y =
// signed metres across it), so the flow direction at every fragment is the
// ribbon's own tangent — the parameterisation is the flow map, no texture
// asset needed. With flow_enabled the wave normals scroll downstream in
// that space instead of drifting in world space; ripples are stretched
// along the flow axis by flow_stretch (< 1 elongates), which is most of
// what visually separates running water from a breeze-rippled pond.
// The pond plane never sets UV2 and never enables this.
// tb/cause-tidewake (F39 sea): three cheap, flag-off sea treatments. All
// strengths default to 0, which keeps every existing water surface exactly.
// Distance haze: open water fades toward a pale sky-family colour with range,
// so the far sea reads as air and depth instead of one flat navy value.
uniform vec4 haze_colour: source_color = vec4(0.66, 0.78, 0.82, 1.0);
uniform float haze_strength = 0.0;
uniform float haze_start_m = 60.0;
uniform float haze_full_m = 700.0;
// Wind slicks: long, soft, smoother streaks drifting with the wind over deep
// water (one stretched noise sample), so the sea shows flow and glints along
// streaks instead of a uniform field. Never a lane, dash or band.
uniform vec4 slick_colour: source_color = vec4(0.36, 0.62, 0.70, 1.0);
uniform float slick_strength = 0.0;
uniform float slick_scale = 0.006;
uniform vec2 slick_dir = vec2(0.63, 0.77);
uniform float slick_calm = 0.7;
// Whitecaps: rare small broken foam flecks on deeper water, faded with range.
uniform float cap_strength = 0.0;
uniform float cap_scale = 0.05;
uniform float cap_threshold = 0.42;
uniform float cap_far_m = 160.0;

uniform bool flow_enabled = false;
// Metres of course per second the ripple pattern travels. TUNABLE (water.json).
uniform float flow_speed = 1.1;
uniform float flow_stretch = 0.6;

varying vec3 world_pos;
varying vec2 course_uv;

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	course_uv = UV2;
}

void fragment() {
	vec2 uv = world_pos.xz;

	vec2 height_uv = (uv - region.xy) / region.zw;
	float ground = height_min;
	if (!outside_region_deep_water || (all(greaterThanEqual(height_uv, vec2(0.0))) && all(lessThanEqual(height_uv, vec2(1.0))))) {
		ground = height_min + texture(terrain_height, (uv - region.xy) / region.zw).r * (height_max - height_min);
	}
	float depth = max(world_pos.y - ground, 0.0);
	if (depth_band_break_m > 0.0) {
		// P2-009: a flat seabed turns every depth ramp into a straight contour
		// across the frame. One broad world-space wander (about 40 m) plus a
		// finer one bend it into a coastline. World space, so it does not swim
		// with the camera; faded out in the first metre so the waterline, its
		// foam band and the alpha feather stay exactly where the ground says.
		float band_ramp = smoothstep(0.4, 1.5, depth);
		float broad = texture(foam_noise, uv * 0.025 + vec2(0.17)).r - 0.5;
		float fine = texture(foam_noise, uv * 0.09 + vec2(0.63)).r - 0.5;
		depth = max(0.0, depth + (broad * 1.6 + fine * 0.6) * depth_band_break_m * band_ramp);
	}

	// Two noise-normal layers scrolling in different directions; their sum
	// stops either one's drift reading as a conveyor belt. In flow mode both
	// layers instead run DOWNSTREAM in the ribbon's own course space, at
	// incommensurate rates so they decorrelate without ever disagreeing
	// about the direction of travel.
	vec3 n_a;
	vec3 n_b;
	if (flow_enabled) {
		vec2 fa = vec2(course_uv.y, (course_uv.x - TIME * flow_speed) * flow_stretch) * wave_uv_scale;
		vec2 fb = vec2(course_uv.y * 1.7, (course_uv.x - TIME * flow_speed * 1.35) * flow_stretch * 1.7) * wave_uv_scale;
		n_a = texture(wave_normal_a, fa).rgb;
		n_b = texture(wave_normal_b, fb).rgb;
	} else {
		vec2 wuv = uv * wave_uv_scale;
		n_a = texture(wave_normal_a, wuv + vec2(TIME, TIME * 0.6) * wave_speed).rgb;
		n_b = texture(wave_normal_b, wuv * 1.7 - vec2(TIME * 0.8, TIME * -0.5) * wave_speed).rgb;
	}
	vec3 wave = normalize((n_a + n_b) - vec3(1.0));

	// The wave noise dithers the depth ramp a whisker: an analytically clean
	// gradient over a smooth basin renders as visible mach bands at 8 bits
	// (blind round 2 named the banding), and the same noise that ripples the
	// normals is exactly the right thing to break it up with.
	float shallowness = 1.0 - smoothstep(0.0, depth_falloff, depth);
	shallowness = clamp(shallowness + (n_a.g - 0.5) * 0.05, 0.0, 1.0);
	vec3 colour = mix(deep_colour.rgb, shallow_colour.rgb, shallowness);
	if (mid_depth_m > 0.0) {
		// A third stop on the shelf, as a band that rises out of the shallow
		// colour and falls back into the deep one. Written as a mix INTO the
		// existing colour, never a replacement: the Tidewake offshore variant
		// injects its own deep tone on the line above, and overwriting here
		// would throw that away.
		float up = smoothstep(0.0, mid_depth_m, depth);
		float down = 1.0 - smoothstep(mid_depth_m, max(depth_falloff, mid_depth_m + 0.5), depth);
		colour = mix(colour, mid_colour.rgb, clamp(up * down, 0.0, 1.0));
	}

	// View-angle blend toward the sky family — a flat look-down shows the
	// water's own colour, a grazing look across shows the sky's, which is
	// most of what makes a still surface read as reflective without any
	// actual reflection being rendered.
	float facing = clamp(dot(normalize(NORMAL), normalize(VIEW)), 0.0, 1.0);
	float fresnel = pow(1.0 - facing, fresnel_power) * fresnel_strength;
	colour = mix(colour, fresnel_colour.rgb, fresnel);
	float view_dist = length(world_pos - CAMERA_POSITION_WORLD);
	float slick = 0.0;
	if (slick_strength > 0.0) {
		vec2 sd = normalize(slick_dir);
		vec2 sp = vec2(dot(uv, sd), dot(uv, vec2(-sd.y, sd.x)));
		float s_long = texture(foam_noise, vec2(sp.x * slick_scale * 0.16 - TIME * 0.002, sp.y * slick_scale)).r;
		float s_patch = texture(foam_noise, uv * slick_scale * 0.37 + vec2(0.37, 0.11)).r;
		slick = smoothstep(0.5, 0.68, s_long * 0.72 + s_patch * 0.28) * smoothstep(1.5, 4.5, depth);
		colour = mix(colour, slick_colour.rgb, slick * slick_strength);
	}
	if (haze_strength > 0.0) {
		colour = mix(colour, haze_colour.rgb, smoothstep(haze_start_m, haze_full_m, view_dist) * haze_strength);
	}

	// Foam only where the water actually touches something: the depth band
	// hugging the shoreline (and any rock shallow enough to enter it),
	// broken by scrolling noise into separate laps. The first version let
	// full contact carry foam on its own (contact * 0.5 already cleared the
	// smoothstep floor), which rendered a solid white ring around the whole
	// pond — the exact "drawn outline" the bible's "only at meaningful
	// contact points" forbids. Now the noise term is REQUIRED: contact alone
	// tops out below the threshold, so foam appears only where the noise
	// peaks happen to cross the shoreline, in patches that drift.
	// Two samples of the same noise at incommensurate scales, multiplied
	// into one field: a single seamless 256px tile put its peaks at regular
	// intervals along the shoreline and the foam rendered as a bead chain
	// of identical dots (blind round 1). The product of two scales has no
	// visible period at shoreline lengths.
	float contact = 1.0 - smoothstep(foam_depth * 0.35, foam_depth, depth);
	float n1 = texture(foam_noise, uv * foam_scale + vec2(TIME * foam_speed, TIME * -foam_speed * 0.7)).r;
	float n2 = texture(foam_noise, uv * foam_scale * 0.37 + vec2(0.41) + vec2(-TIME, TIME * 0.8) * foam_speed * 0.6).r;
	float noise = n1 * 0.55 + n2 * 0.45;
	float foam = smoothstep(0.6, 0.78, noise * 0.55 + contact * 0.4) * contact;
	if (surf_strength > 0.0) {
		float surf_reach = surf_depth_m;
		if (surf_vary > 0.0) {
			float wander = texture(foam_noise, uv * 0.018 + vec2(0.71, 0.29)).r;
			surf_reach *= mix(1.0, mix(0.25, 1.6, wander), surf_vary);
		}
		float surf_band = (1.0 - smoothstep(surf_reach * 0.4, surf_reach, depth)) * smoothstep(0.0, 0.04, depth);
		float surf_noise = n2 * 0.6 + n1 * 0.4;
		foam = max(foam, surf_band * smoothstep(surf_breakup, surf_breakup + 0.12, surf_noise) * surf_strength);
	}
	if (cap_strength > 0.0) {
		float c1 = texture(foam_noise, uv * cap_scale + vec2(TIME * 0.011, TIME * 0.006)).r;
		float c2 = texture(foam_noise, uv * cap_scale * 0.41 + vec2(0.53, 0.19) - vec2(TIME * 0.004)).r;
		float cap = smoothstep(cap_threshold, cap_threshold + 0.05, c1 * c2)
			* smoothstep(2.5, 7.0, depth) * (1.0 - smoothstep(cap_far_m * 0.4, cap_far_m, view_dist));
		foam = max(foam, cap * cap_strength);
	}
	colour = mix(colour, foam_colour.rgb, foam);

	float alpha = mix(alpha_deep, alpha_shallow, shallowness);
	alpha = max(alpha, foam * 0.85);
	// The exact waterline: fade out over the last few centimetres of depth.
	alpha *= smoothstep(0.0, edge_feather, depth);

	ALBEDO = colour;
	ALPHA = alpha;
	NORMAL_MAP = wave * 0.5 + vec3(0.5);
	// Ripple strength falls off with distance (full inside ~15m, calm past
	// ~70m): at range the noise normals scatter the sun's sheen across the
	// whole surface, which a blind critic read as "flat cyan fill" — the
	// glint has to stay a glint, and far water should read calm anyway.
	float calm = 1.0 - smoothstep(15.0, 70.0, length(world_pos - CAMERA_POSITION_WORLD));
	NORMAL_MAP_DEPTH = mix(wave_strength * mix(0.15, 1.0, calm) * (1.0 - slick * slick_calm), 0.05, foam);
	ROUGHNESS = mix(roughness_value * (1.0 - slick * slick_calm * 0.5), 0.6, foam);
	// 0.5 restored (round 1 cut it to 0.35 chasing a milky wash whose real
	// cause was the near-white fresnel colour): blind round 1 called the
	// missing sun response directly — "a stylised pond without a sparkle
	// track is not stylised, it is unfinished" — and the glint has to come
	// from somewhere. Low roughness plus the wave normals is that somewhere.
	SPECULAR = 0.5;
	METALLIC = 0.0;
}
