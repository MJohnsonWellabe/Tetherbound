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

uniform vec4 deep_colour: source_color = vec4(0.11, 0.32, 0.38, 1.0);
uniform vec4 shallow_colour: source_color = vec4(0.48, 0.68, 0.58, 1.0);
// How many metres of depth it takes to reach the deep colour.
uniform float depth_falloff = 1.6;
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

	float ground = height_min + texture(terrain_height, (uv - region.xy) / region.zw).r * (height_max - height_min);
	float depth = max(world_pos.y - ground, 0.0);

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

	// View-angle blend toward the sky family — a flat look-down shows the
	// water's own colour, a grazing look across shows the sky's, which is
	// most of what makes a still surface read as reflective without any
	// actual reflection being rendered.
	float facing = clamp(dot(normalize(NORMAL), normalize(VIEW)), 0.0, 1.0);
	float fresnel = pow(1.0 - facing, fresnel_power) * fresnel_strength;
	colour = mix(colour, fresnel_colour.rgb, fresnel);

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
	NORMAL_MAP_DEPTH = mix(wave_strength * mix(0.15, 1.0, calm), 0.05, foam);
	ROUGHNESS = mix(roughness_value, 0.6, foam);
	// 0.5 restored (round 1 cut it to 0.35 chasing a milky wash whose real
	// cause was the near-white fresnel colour): blind round 1 called the
	// missing sun response directly — "a stylised pond without a sparkle
	// track is not stylised, it is unfinished" — and the glint has to come
	// from somewhere. Low roughness plus the wave normals is that somewhere.
	SPECULAR = 0.5;
	METALLIC = 0.0;
}
