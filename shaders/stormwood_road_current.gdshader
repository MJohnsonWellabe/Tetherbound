shader_type spatial;
// Stormwood road current (owner direction on WO-F09-04): yellow-gold charge
// running through cracks in the painted dirt lane, pulsing toward the Dynamo.
// Drawn on terrain-conforming ribbon chunks built by
// scripts/world/stormwood_road_current.gd. UV.x is metres along the route in
// the flow direction; UV.y runs -1..1 across the ribbon. Additive and unshaded:
// it only ever adds light to the dirt under it. Every number is a uniform set
// from data/config/stormwood_road_current.json.
render_mode blend_add, unshaded, cull_disabled, depth_draw_never, shadows_disabled, fog_disabled;

uniform vec4 colour_core : source_color = vec4(1.0, 0.957, 0.69, 1.0);
uniform vec4 colour_edge : source_color = vec4(1.0, 0.76, 0.1, 1.0);
uniform float core_energy = 1.6;
uniform float edge_energy = 0.55;
uniform float vein_scale = 1.0;
uniform float vein_width = 0.09;
uniform float vein_breakup = 0.42;
uniform float vein_lane_offset = 0.5;
uniform float vein_wander = 0.12;
// WO-F09-05 round 4: a pocket spur (UV2.x = 1; UV2.y = metres from its road
// junction) carries one thin crack in its pocket's own tint (vertex COLOR),
// dimmer than a road's, fading in from spur_start_m so it starts at the road
// edge rather than on the road.
uniform float spur_energy = 0.55;
uniform float spur_start_m = 3.0;
uniform float spur_fade_m = 1.5;
// Round 4 attempt 2: brighter and wider over its first spur_near_m, where it
// must read crossing the road's grass shoulder from a grazing road view.
uniform float spur_near_energy = 0.55;
uniform float spur_near_m = 35.0;
uniform float spur_near_width = 1.0;
uniform float spur_offset = 0.0;
uniform float flow_speed = 7.0;
uniform float pulse_spacing = 11.0;
uniform float pulse_sharpness = 6.0;
uniform float flicker = 0.35;
uniform float storm_intensity = 0.55;
uniform float depth_pull = 0.004;
// Evidence captures only: a non-negative value replaces TIME so a motion strip
// can be shot at exact 0.25 s steps under a slow software renderer.
uniform float clock_override = -1.0;
// Fades out to nothing at the chunks' visibility_range_end.
uniform float fade_end = 150.0;
uniform float fade_length = 25.0;

float hash11(float p) {
	p = fract(p * 0.1031);
	p *= p + 33.33;
	p *= p + p;
	return fract(p);
}

float hash21(vec2 p) {
	vec3 p3 = fract(vec3(p.xyx) * 0.1031);
	p3 += dot(p3, p3.yzx + 33.33);
	return fract((p3.x + p3.y) * p3.z);
}

float noise1(float x) {
	float i = floor(x);
	float f = fract(x);
	return mix(hash11(i), hash11(i + 1.0), f * f * (3.0 - 2.0 * f));
}

float noise2(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash21(i), hash21(i + vec2(1.0, 0.0)), u.x),
		mix(hash21(i + vec2(0.0, 1.0)), hash21(i + vec2(1.0, 1.0)), u.x), u.y);
}

// One meandering crack: its centre wanders across the lane along u with a
// fine jagged kink on top, and it is broken into runs where a slow noise
// drops below `vein_breakup`.
vec2 vein(float u, float v, float seed) {
	float s = u * 0.11 * vein_scale + seed * 17.0;
	// WO-F09-05 round 4 (blind judge: a yellow loop and a doubled, smeared
	// line on the road): each crack keeps to its own third of the lane
	// (vein_lane_offset apart) and wanders only vein_wander inside it, so two
	// cracks never cross into a loop or run side by side as a double line.
	float lane = (seed - 2.0) * vein_lane_offset;
	float centre = lane + (noise1(s) * 2.0 - 1.0) * vein_wander + (noise1(s * 3.7 + 5.0) * 2.0 - 1.0) * vein_wander * 0.3;
	float jag = (noise1(u * 1.9 * vein_scale + seed * 31.0) * 2.0 - 1.0) * 0.08
		+ (noise1(u * 5.3 * vein_scale + seed * 7.0) * 2.0 - 1.0) * 0.035;
	float d = abs(v - centre - jag);
	float width = vein_width * (0.55 + 0.9 * noise1(u * 0.8 + seed * 3.0));
	float line = 1.0 - smoothstep(width * 0.3, width, d);
	float glow = exp(-d * d / (width * width * 10.0)) * 0.3;
	float runs = smoothstep(vein_breakup - 0.08, vein_breakup + 0.08, noise1(u * 0.07 * vein_scale + seed * 53.0));
	return vec2((line + glow) * runs, d);
}

// Charge travelling toward +u: a comet with its bright head leading and a
// long tail behind, each vein on its own phase so no pulse crosses the lane
// as a straight band.
float pulse_at(float u, float seed) {
	float t = clock_override >= 0.0 ? clock_override : TIME;
	float phase = (u - t * flow_speed) / max(pulse_spacing, 0.5) + seed * 0.37;
	float f = fract(phase);
	return pow(f, pulse_sharpness) * (1.0 - smoothstep(0.86, 1.0, f));
}

void vertex() {
	// Depth bias only: slide the vertex toward the camera along its own view
	// ray, so the far, coarser Terrain3D mesh cannot swallow the ribbon.
	vec4 view = MODELVIEW_MATRIX * vec4(VERTEX, 1.0);
	view.xyz *= (1.0 - depth_pull);
	POSITION = PROJECTION_MATRIX * view;
}

void fragment() {
	float u = UV.x;
	float v = UV.y;
	float feather = 1.0 - smoothstep(0.55, 0.98, abs(v));
	float distance_fade_all = 1.0 - smoothstep(fade_end - fade_length, fade_end, length(VERTEX));
	if (UV2.x > 0.5) {
		float spur_s = u * 0.11 * vein_scale;
		// Round 5 (judge: the crack glowed through under the stepping stones):
		// the crack runs along one edge of the ribbon (spur_offset) and the
		// stones along the other (stormwood_pockets.json spur_trail.offset_m).
		float spur_centre = spur_offset + (noise1(spur_s + 3.0) * 2.0 - 1.0) * 0.12;
		float spur_d = abs(v - spur_centre - (noise1(u * 1.9 * vein_scale) * 2.0 - 1.0) * 0.06);
		float near = 1.0 - smoothstep(spur_near_m * 0.5, spur_near_m, UV2.y);
		float spur_w = vein_width * 1.6 * mix(1.0, spur_near_width, near);
		float spur_line = 1.0 - smoothstep(spur_w * 0.3, spur_w, spur_d);
		float spur_glow = exp(-spur_d * spur_d / (spur_w * spur_w * 10.0)) * 0.3;
		float spur_charge = (spur_line + spur_glow) * (0.5 + 1.2 * pulse_at(u - spur_d * 6.0, 1.0));
		float spur_in = smoothstep(spur_start_m, spur_start_m + spur_fade_m, UV2.y);
		ALBEDO = COLOR.rgb * mix(spur_energy, spur_near_energy, near) * spur_charge * feather * storm_intensity * distance_fade_all * spur_in;
	} else {
	// Three cracks plus a fine ridged web of hairline cracks between them.
	float charge = 0.0;
	for (int i = 1; i <= 3; i++) {
		float seed = float(i);
		vec2 crack = vein(u, v, seed);
		// Sampling the pulse slightly behind at the crack's edges gives each
		// charge a pointed head instead of a flat front across the crack.
		float pulse = pulse_at(u - crack.y * 6.0, seed);
		charge = max(charge, crack.x * (1.0 - 0.2 * (seed - 1.0)) * (0.45 + 1.6 * pulse));
	}
	float web = 1.0 - abs(noise2(vec2(u * 0.9, v * 2.4) * vein_scale) * 2.0 - 1.0);
	web = pow(web, 9.0) * 0.5 * smoothstep(0.45, 0.6, noise2(vec2(u * 0.23, v + 7.0)));
	charge += web * (0.35 + 0.8 * pulse_at(u, 4.0));
	float crackle = 1.0 - flicker * step(0.72, hash21(vec2(floor(u * 0.5), floor((clock_override >= 0.0 ? clock_override : TIME) * 14.0))));
	charge *= crackle;
	float core = smoothstep(0.75, 1.5, charge);
	vec3 light = colour_edge.rgb * edge_energy * charge + colour_core.rgb * core_energy * core;
	ALBEDO = light * feather * storm_intensity * distance_fade_all;
	}
}
