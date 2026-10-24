shader_type spatial;
render_mode blend_mix, cull_disabled, depth_draw_never, diffuse_burley, specular_disabled, skip_vertex_transform;

// Tidewake current streaks (scripts/world/water_current_flow_view.gd). One
// ribbon per authored current, all in one mesh. The foam pattern is laid out
// in world space along the current's single physics flow vector, so the
// streaks drift exactly the way the swimmer is pushed. COLOR.rg = flow
// direction * 0.5 + 0.5, COLOR.b = relative strength, UV.x = across (0..1),
// UV.y = metres along the route, UV2.x = fraction along it, UV2.y = its
// length in metres (end fades).
uniform vec4 foam_colour : source_color = vec4(0.90, 0.97, 0.97, 1.0);
uniform float opacity = 0.5;
// A faint lane of disturbed water under the foam, so the current reads as a
// band of moving sea and not only as white dashes.
uniform vec4 lane_colour : source_color = vec4(0.72, 0.90, 0.88, 1.0);
uniform float lane_opacity = 0.14;
uniform float streak_width_m = 1.1;
uniform float streak_length_m = 9.0;
uniform float min_speed_m_s = 0.35;
uniform float speed_scale = 1.4;
uniform float calm_scale = 1.0;
// Per-restoration-state look (water_veilfall.json current_flow.state_shader,
// applied by water_current_flow_view.gd from `water_currents_restored`).
// streak_density: fraction of foam lanes that carry dashes at all.
// dash_fill: how much of a carrying lane is foam (longer, joined dashes).
// fleck_amount: broken whitecap chop between the lanes.
// brightness: foam and lane colour gain.
uniform float streak_density = 1.0;
uniform float dash_fill = 0.5;
uniform float fleck_amount = 0.5;
uniform float brightness = 1.0;
// F13#5 direction cue: foam comets on the flow lanes, a bright head
// downstream and a tail fading upstream, all drifting with the physics flow,
// so a still frame shows which way the current runs and two frames show them
// all moving the same way. 0 = off.
uniform float comet_opacity = 0.0;
// T2 7-inch device judge: comets and foam groups read as debris at handheld
// size. Chevrons are wake-like foam Vs whose apex points downstream, drifting
// with the physics flow; one still frame says which way. 0 = off.
uniform float chevron_opacity = 0.0;
// T2 channel read (coordinator r5): the whole lane takes a distinct tint and a
// dashed rim on both banks that drifts with the physics flow, so the channel
// stands apart from open sea at handheld size. Installed palette, no red.
// 0 opacity = off (the old look exactly).
uniform vec4 channel_tint_colour : source_color = vec4(0.23, 0.44, 0.58, 1.0);
uniform float channel_tint_opacity = 0.0;
uniform vec4 channel_edge_colour : source_color = vec4(0.82, 0.70, 0.49, 1.0);
uniform float channel_edge_opacity = 0.0;
// Rim width as a fraction of the half-ribbon, and its dash length in metres.
uniform float channel_edge_width = 0.08;
uniform float channel_edge_dash_m = 6.0;
uniform float chevron_spacing_m = 13.0;
uniform float chevron_width_m = 6.5;
uniform float chevron_thickness_m = 0.7;
uniform float chevron_density = 0.5;
// Along-flow length of each arm per metre across (higher = longer, narrower V,
// which still reads as converging lines at a grazing camera angle).
uniform float chevron_arm_slope = 0.75;
uniform float comet_length_m = 10.0;
uniform float comet_fill = 0.6;
// Ends fade over this many metres (0 = the old 12% of the route, which hid the
// first tens of metres of a long crossing from a player standing at its dock).
uniform float end_fade_m = 0.0;
uniform float fade_start_m = 180.0;
uniform float fade_end_m = 520.0;
uniform float depth_pull_fraction = 0.003;
// P2-066. A local flag keeps the original expression path intact when off.
uniform bool visual_groups_enabled = false;
uniform float visual_cell_width_m = 3.6;
uniform float visual_cell_length_m = 11.0;
uniform float visual_density = 0.62;
uniform float visual_breakup = 0.55;
uniform float visual_band_gain = 0.55;
// F39 standing-wave candidate. Broad asymmetric crests stay world anchored;
// small foam flows over them in the physics direction. No vertex displacement.
uniform bool visual_ridges_enabled = false;
uniform float visual_ridge_spacing_m = 23.0;
uniform float visual_ridge_width_m = 4.5;
uniform float visual_ridge_gain = 0.7;
// F13#5 tide-line candidate (close-1024). Natural current read: where the
// moving lane meets still sea, an irregular foam seam (continuous, wandering,
// varying width, broken only in long gaps) drifts with the flow along both
// banks, and the lane inside carries small choppy wavelet caps. 0 = off.
uniform float seam_opacity = 0.0;
uniform float seam_width_m = 1.3;
uniform float seam_wander_m = 3.5;
uniform float seam_gap = 0.25;
uniform float chop_cap_opacity = 0.0;
uniform float chop_cap_scale_m = 2.2;
uniform float chop_cap_density = 0.35;
// b6: each seam stretch is a foam tongue that brightens toward its downstream
// head and frays upstream, so a still frame says which way the water runs.
// Stretch length in metres (0 = untapered seams).
uniform float seam_taper_m = 0.0;
// b6: the lane tint fades over a wandering soft edge instead of the ribbon rim.
uniform bool soft_channel_tint = false;
varying vec3 v_world;
varying float v_distance;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise(vec2 p) {
	vec2 cell = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(cell), hash(cell + vec2(1.0, 0.0)), f.x),
		mix(hash(cell + vec2(0.0, 1.0)), hash(cell + vec2(1.0)), f.x), f.y);
}

// Groups stay strictly inside their cells; changing the cell hash therefore
// happens only in empty water. All coordinates advect together, so neither
// the silhouette nor its broken edges flicker/reseed as time advances.
float foam_group(vec2 moving) {
	vec2 cell_size = vec2(max(visual_cell_width_m, 1.0), max(visual_cell_length_m, 4.0));
	vec2 cell = floor(moving / cell_size);
	vec2 local = fract(moving / cell_size);
	float selected = step(hash(cell + vec2(13.1, 47.3)), clamp(visual_density * streak_density, 0.0, 1.0));
	float centre_x = mix(0.25, 0.75, hash(cell + vec2(5.9, 71.2)));
	float head = mix(0.70, 0.90, hash(cell + vec2(83.4, 2.6)));
	float length_fraction = mix(0.22, 0.56, hash(cell + vec2(17.8, 29.1)));
	// Restoration shortens each group as well as thinning the selected cells.
	// Keep its downstream head fixed; only the upstream tail retreats. The
	// multiplier never exceeds one, preserving the original cell containment.
	length_fraction *= mix(0.25, 1.0, clamp(dash_fill, 0.0, 1.0));
	float phase = (local.y - (head - length_fraction)) / length_fraction;
	// At larger along coordinates the downstream head is fuller/brighter;
	// the upstream tail narrows and fades. Translation follows physics flow.
	float body = smoothstep(0.0, 0.78, phase) * (1.0 - smoothstep(0.86, 1.0, phase));
	float half_width = mix(0.07, 0.14, hash(cell + vec2(61.0, 11.7)))
		* mix(0.28, 1.0, clamp(phase, 0.0, 1.0));
	float wander = (noise(moving * vec2(0.4, 0.65)) - 0.5) * 0.045;
	float cross_shape = 1.0 - smoothstep(half_width * 0.35, half_width,
		abs(local.x - centre_x + wander));
	float erosion = smoothstep(0.25, 0.72, noise(moving * vec2(1.6, 0.95) + vec2(31.0)));
	return selected * body * cross_shape * mix(1.0, erosion, clamp(visual_breakup, 0.0, 1.0));
}

void vertex() {
	v_world = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	v_distance = length(v_world - INV_VIEW_MATRIX[3].xyz);
	vec3 view = (MODELVIEW_MATRIX * vec4(VERTEX, 1.0)).xyz;
	// Same projected position, slightly nearer: no z-fight with the sea plane.
	VERTEX = view * (1.0 - depth_pull_fraction);
	NORMAL = normalize((MODELVIEW_MATRIX * vec4(0.0, 1.0, 0.0, 0.0)).xyz);
}

void fragment() {
	// The ribbon may be seen from its back face; always light it as the sea top.
	NORMAL = normalize((VIEW_MATRIX * vec4(0.0, 1.0, 0.0, 0.0)).xyz);
	vec2 flow = normalize(COLOR.rg * 2.0 - 1.0 + vec2(0.0001));
	float strength = COLOR.b;
	float along = dot(v_world.xz, flow);
	float across_m = dot(v_world.xz, vec2(-flow.y, flow.x));
	float speed = max(min_speed_m_s, strength * speed_scale) * calm_scale;
	float streak = 0.0;
	float comet = 0.0;
	if (visual_groups_enabled) {
		vec2 moving = vec2(across_m, along - TIME * speed);
		float group = foam_group(moving);
		float chop = smoothstep(0.78, 0.94, noise(moving * vec2(0.7, 0.9)))
			* smoothstep(0.48, 0.76, noise(moving * 0.16 + vec2(7.0)));
		streak = group * 0.38 + chop * fleck_amount * 0.22;
		comet = group * comet_opacity;
	} else {
		// Thin wandering foam lanes, broken into dashes that drift with the flow.
		float lane = across_m / streak_width_m + noise(vec2(along / 30.0, across_m / 20.0)) * 1.5;
		float girth = noise(vec2(floor(lane) * 1.7, along / 18.0));
		float line = smoothstep(0.78 - girth * 0.22, 0.97, 1.0 - abs(fract(lane) * 2.0 - 1.0));
		float carried = step(hash(vec2(floor(lane), 7.31)), streak_density);
		float dash = smoothstep(0.65 - 0.35 * dash_fill, 0.9 - 0.2 * dash_fill,
			noise(vec2(floor(lane) * 3.1, (along - TIME * speed) / streak_length_m)));
		float fleck_cut = 0.97 - 0.22 * fleck_amount;
		float fleck = smoothstep(fleck_cut, fleck_cut + 0.08,
			noise(vec2(across_m * 0.9, (along - TIME * speed) * 0.35))) * min(1.0, fleck_amount * 1.5);
		streak = max(line * dash * carried, fleck * 0.6);
		if (comet_opacity > 0.0) {
			// Per lane, one comet every comet_length_m (some skipped): its body
			// ramps up along the flow and cuts off at the head.
			float lane_id = floor(lane);
			float phase = fract((along - TIME * speed) / comet_length_m + hash(vec2(lane_id, 1.37)));
			float body = smoothstep(0.0, 0.8, phase) * (1.0 - smoothstep(0.9, 0.97, phase));
			float profile = 1.0 - abs(fract(lane) * 2.0 - 1.0);
			float taper = smoothstep(0.9 - 0.35 * phase, 0.98, profile);
			float kept = step(hash(vec2(lane_id, floor((along - TIME * speed) / comet_length_m + hash(vec2(lane_id, 1.37))))), comet_fill);
			comet = body * taper * kept * comet_opacity;
		}
	}
	float chevron = 0.0;
	if (chevron_opacity > 0.0) {
		// One chevron per spacing along the ribbon, centred on the ribbon
		// (UV.x 0..1 across it) so both arms always show inside the band.
		float spacing_c = max(chevron_spacing_m, 4.0);
		float moving_along = along - TIME * speed;
		float ccell = floor(moving_along / spacing_c);
		float ly = (fract(moving_along / spacing_c) - 0.5) * spacing_c;
		float kept_c = step(hash(vec2(ccell, 3.3)), chevron_density);
		float half_w = max(chevron_width_m, 1.0) * 0.5;
		float x = abs(UV.x - 0.5) * 2.0 * half_w;
		vec2 lc = vec2(x, ly);
		// Apex at the downstream end (+along); the arms trail back upstream.
		float arm = abs(lc.y - (half_w * 0.6 * chevron_arm_slope / 0.75 - x * chevron_arm_slope));
		float stroke = 1.0 - smoothstep(chevron_thickness_m * 0.45, chevron_thickness_m, arm);
		float span = 1.0 - smoothstep(half_w * 0.75, half_w, x);
		chevron = kept_c * stroke * span * chevron_opacity;
	}
	float across = abs(UV.x - 0.5) * 2.0;
	float edge = 1.0 - smoothstep(0.55, 1.0, across);
	if (visual_groups_enabled) {
		float edge_noise = noise(vec2(across_m / 8.0, (along - TIME * speed) / 11.0));
		edge = 1.0 - smoothstep(0.35 + edge_noise * 0.2, 0.75 + edge_noise * 0.25, across);
	}
	float ends = smoothstep(0.0, 0.12, UV2.x) * (1.0 - smoothstep(0.88, 1.0, UV2.x));
	if (end_fade_m > 0.0 && UV2.y > 0.0) {
		ends = smoothstep(0.0, end_fade_m, UV.y) * (1.0 - smoothstep(UV2.y - end_fade_m, UV2.y, UV.y));
	}
	float fade = 1.0 - smoothstep(fade_start_m, fade_end_m, v_distance);
	float mask = edge * ends * fade * mix(0.55, 1.0, calm_scale);
	// The comets say which way, not how hard: they are not dimmed by strength.
	float foam = clamp(max(max(opacity * streak * mix(0.45, 1.0, strength), opacity * comet), chevron), 0.0, 1.0);
	float ridge_shadow = 0.0;
	if (visual_groups_enabled && visual_ridges_enabled) {
		// Adjacent cross-flow patches offset each other, avoiding ruler-straight
		// guide lanes. A gentle upstream ramp terminates at a sharp downstream
		// lip. The same flow basis is encoded by the production field.
		float spacing = max(visual_ridge_spacing_m, 8.0);
		float bend = noise(vec2(across_m / 22.0, 3.7)) * spacing * 0.55;
		float phase_m = mod(along + bend, spacing);
		float width = clamp(visual_ridge_width_m, 1.0, spacing * 0.45);
		float ramp = smoothstep(0.0, width * 0.8, phase_m);
		float lip = 1.0 - smoothstep(width * 0.8, width, phase_m);
		float patches = smoothstep(0.18, 0.65, noise(vec2(across_m / 13.0, floor((along + bend) / spacing))));
		// The replicated restored look controls both amplitude and chop: crests
		// settle when restored, including load/reconnect, without a new receipt.
		float gain = visual_ridge_gain * fleck_amount * calm_scale * patches;
		foam = clamp(foam + opacity * ramp * lip * gain, 0.0, 1.0);
		ridge_shadow = smoothstep(width, width + 0.35, phase_m)
			* (1.0 - smoothstep(width + 0.35, width * 1.8, phase_m)) * gain * 0.3;
	}
	float seam_a = 0.0;
	if (seam_opacity > 0.0 || chop_cap_opacity > 0.0) {
		float moving_s = along - TIME * speed;
		// Distance in metres from each bank, along a slowly wandering line.
		float wander = (noise(vec2(moving_s / 37.0, 1.3)) - 0.5) * 2.0 * seam_wander_m
			+ (noise(vec2(moving_s / 9.0, 5.1)) - 0.5) * seam_wander_m * 0.35;
		float ribbon_half = max(fwidth(across_m) / max(fwidth(UV.x), 1e-5) * 0.5, 1.0);
		float from_edge = (1.0 - across) * ribbon_half - 0.18 * ribbon_half + wander * sign(UV.x - 0.5);
		float girth = seam_width_m * mix(0.45, 1.25, noise(vec2(moving_s / 6.0, UV.x * 3.0)));
		float seam = 1.0 - smoothstep(girth * 0.4, girth, abs(from_edge));
		// Lacy bubble texture inside the seam, and long gaps where it breaks.
		float lace = smoothstep(0.3, 0.75, noise(vec2(across_m * 1.7, moving_s * 0.9)));
		float keep = smoothstep(seam_gap - 0.08, seam_gap + 0.08, noise(vec2(moving_s / 28.0, UV.x * 7.0 + 2.0)));
		seam *= mix(0.55, 1.0, lace) * keep;
		if (seam_taper_m > 0.0) {
			float side_seed = step(0.5, UV.x) * 17.3;
			float stretch = moving_s / seam_taper_m + hash(vec2(side_seed, 4.1));
			float stretch_id = floor(stretch);
			float tongue = fract(stretch);
			float head = smoothstep(0.05, 0.8, tongue) * (1.0 - smoothstep(0.88, 0.97, tongue));
			seam *= head * mix(0.6, 1.0, hash(vec2(stretch_id, side_seed + 2.0)));
		}
		// Wavelet caps: small crescent whitecaps, denser toward the lane core.
		vec2 cap_uv = vec2(across_m, moving_s * 1.6) / max(chop_cap_scale_m, 0.5);
		vec2 cap_cell = floor(cap_uv);
		// Each cap is jittered, sized and faded per cell so the field never
		// reads as a regular grid of arcs.
		vec2 cap_jitter = vec2(hash(cap_cell + vec2(1.7, 3.3)), hash(cap_cell + vec2(8.1, 2.9))) - 0.5;
		float cap_size = mix(0.55, 1.0, hash(cap_cell + vec2(6.6, 0.4)));
		vec2 cap_local = (fract(cap_uv) - 0.5 - cap_jitter * 0.45) / cap_size;
		float cap_on = step(hash(cap_cell + vec2(4.2, 9.1)), chop_cap_density * (1.0 - across));
		float crescent = 1.0 - smoothstep(0.04, 0.12, abs(cap_local.y + cap_local.x * cap_local.x * 1.2 - 0.05));
		crescent *= 1.0 - smoothstep(0.25, 0.42, abs(cap_local.x));
		crescent *= mix(0.35, 1.0, lace) * mix(0.4, 1.0, hash(cap_cell + vec2(2.2, 7.7)));
		float cap = cap_on * crescent * chop_cap_opacity;
		foam = clamp(max(foam, cap), 0.0, 1.0);
		seam_a = clamp(seam * seam_opacity, 0.0, 1.0) * ends * fade;
	}
	float band = lane_opacity * mix(0.5, 1.0, strength)
		* (0.6 + 0.4 * noise(vec2(across_m / 6.0, (along - TIME * speed * 0.5) / 25.0)));
	if (visual_groups_enabled) {
		band *= visual_band_gain * smoothstep(0.18, 0.75,
			noise(vec2(across_m / 9.0, (along - TIME * speed) / 17.0)));
	}
	float alpha = foam + band * (1.0 - foam);
	vec3 premult = brightness * (foam_colour.rgb * foam + lane_colour.rgb * band * (1.0 - foam)) * mask;
	alpha *= mask;
	// The tide-line seam sits on the banks, outside the soft foam edge mask.
	premult = premult * (1.0 - seam_a) + brightness * foam_colour.rgb * seam_a;
	alpha = alpha + seam_a * (1.0 - alpha);
	if (channel_tint_opacity > 0.0 || channel_edge_opacity > 0.0) {
		// Under the foam: the dashed rim, then the channel tint. Not dimmed by
		// the soft foam edge mask, so the bank line sits at the ribbon's edge.
		float rim_w = clamp(channel_edge_width, 0.01, 0.3);
		float rim = 1.0 - smoothstep(rim_w * 0.35, rim_w * 0.6, abs(across - (1.0 - rim_w)));
		rim *= step(0.4, fract((along - TIME * speed) / max(channel_edge_dash_m, 1.0)));
		float inside = 1.0 - smoothstep(1.0 - rim_w * 0.4, 1.0, across);
		if (soft_channel_tint) {
			float tint_edge = noise(vec2(across_m / 7.0, (along - TIME * speed * 0.6) / 21.0));
			inside = (1.0 - smoothstep(0.45 + tint_edge * 0.25, 0.92, across))
				* mix(0.7, 1.0, noise(vec2(across_m / 4.0, (along - TIME * speed) / 9.0)));
		}
		float base = ends * fade;
		float rim_a = rim * channel_edge_opacity * base;
		float tint_a = inside * channel_tint_opacity * base * mix(0.6, 1.0, calm_scale);
		vec3 under = channel_edge_colour.rgb * rim_a + channel_tint_colour.rgb * tint_a * (1.0 - rim_a);
		float under_a = rim_a + tint_a * (1.0 - rim_a);
		premult += under * (1.0 - alpha);
		alpha += under_a * (1.0 - alpha);
	}
	ALBEDO = premult / max(alpha, 0.001);
	ALBEDO *= 1.0 - ridge_shadow;
	ROUGHNESS = 0.7;
	ALPHA = alpha;
}
