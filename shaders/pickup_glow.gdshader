shader_type spatial;
render_mode blend_add, unshaded, cull_disabled, depth_draw_never, shadows_disabled, fog_disabled;

// PICKUP-GLOW. The one visual affordance every world pickup shares, and the
// only thing that answers OP-0830-3.
//
// OWNER PLAYTEST, 2026-08-30: *"all items in the grass like tms, potions, orbs
// whatever should glow so they're visible."* Not one item type -- every one of
// them, which is why this is a shader on a shared MultiMesh rather than a
// treatment bolted onto `key_pickup.gd`, `tm_pickup.gd`,
// `item_cache_pickup.gd`, `harvest_node.gd` and `death_satchel.gd` five
// separate times, each drifting from the others.
//
// ## The three constraints this shape comes from
//
// 1. **It has to survive the grass that is SHIPPING, not the grass today.**
//    The ground lane is raising density on `ralph/T1-GROUND-3` and the field's
//    own blades stand 0.40-0.62m with 0.38 jitter, so roughly 0.86m at the
//    tallest. Brightness does not beat opaque geometry: a glow at ankle height
//    is behind a blade whatever its emission is. **Height is what beats grass**
//    -- the mote rides above the canopy, so the depth test stays ON (this is
//    occluded by terrain, trees and buildings exactly as it should be) and it
//    still reads over the carpet. That is the whole reason `mote_height` in
//    `data/config/pickup_glow.json` is the load-bearing number here and
//    emission is not.
//
// 2. **No per-pickup light.** `item_cache_pickup.gd` and `tm_pickup.gd` each
//    carried their own `OmniLight3D`, and the world holds well over a hundred
//    pickups; OP-0830-6 is an open ROG performance defect and the lane order
//    for this work rules a light-each out by name. Two MultiMeshes -- motes and
//    ground auras -- draw every pickup glow in the world in two draws, and the
//    vertex shader collapses an instance to zero size outside its visible band
//    so a far or already-taken pickup costs no fill at all.
//
// 3. **Not a loot beam.** Tetherbound is a stylised adventure game. This says
//    "something is here" from across a meadow and then gets out of the way as
//    you arrive: `near_fade_*` takes the mote down to a fraction of itself in
//    the last couple of metres, where the player can see the object and the
//    glow would only be sitting on top of it.
//
// ## Distance compensation
//
// A fixed-size world quad is a dinner plate at 2m and a sub-pixel speck at 40m,
// which is exactly backwards -- the far case is the one the owner reported. So
// the quad is scaled by view distance toward a constant SCREEN size, clamped at
// both ends: `screen_min_scale` stops it shrinking to nothing up close and
// `screen_max_scale` stops it becoming a billboard the size of a tree at range.

// Per-instance tint arrives as MultiMesh COLOR; alpha carries the instance's
// own strength so one pickup can be dimmer than another without a second
// material.
uniform float reference_distance = 12.0;
uniform float screen_min_scale = 0.55;
uniform float screen_max_scale = 2.6;

uniform float far_fade_start = 34.0;
uniform float far_fade_end = 46.0;
uniform float near_fade_end = 1.6;
uniform float near_fade_start = 4.0;
uniform float near_floor = 0.35;

uniform float pulse_hz = 0.55;
uniform float pulse_depth = 0.18;

uniform float core_power = 2.6;
uniform float rim_gain = 0.35;
uniform float strength = 1.0;

// 0 = camera-facing mote, 1 = flat ground aura (the instance transform already
// lays that quad down, so it must NOT be re-oriented to the camera).
uniform float billboard = 1.0;

varying float v_fade;

void vertex() {
	// The instance's world origin, before any billboarding -- distance and fade
	// are properties of where the pickup IS, not of where its quad's corners
	// ended up.
	vec3 origin_view = (VIEW_MATRIX * vec4(MODEL_MATRIX[3].xyz, 1.0)).xyz;
	float dist = length(origin_view);

	// Constant-screen-size scaling, clamped at both ends. See the header.
	float scale = clamp(dist / max(reference_distance, 0.01), screen_min_scale, screen_max_scale);

	// Arrive from nothing rather than popping, and step down (never out) in the
	// last couple of metres so the glow does not sit on top of an object the
	// player is already looking straight at.
	float far_fade = 1.0 - smoothstep(far_fade_start, far_fade_end, dist);
	float near_fade = mix(near_floor, 1.0, smoothstep(near_fade_end, near_fade_start, dist));
	v_fade = far_fade * near_fade;

	// A slow breath, phase-offset per instance (MultiMesh custom data .x) so a
	// cluster of pickups does not pulse in lockstep and read as a UI element.
	float phase = INSTANCE_CUSTOM.x * 6.2831853;
	float pulse = 1.0 + pulse_depth * sin(TIME * pulse_hz * 6.2831853 + phase);
	v_fade *= pulse;

	// Collapsed to a point when out of band, so an instance nobody can see
	// rasterises nothing at all. This is the whole reason one MultiMesh for the
	// entire world is affordable. (Written as a multiplier rather than an early
	// `return`, which Godot forbids in `vertex()`.)
	float alive = step(0.001, v_fade);

	if (billboard > 0.5) {
		// Standard camera-facing basis, keeping the instance's translation.
		MODELVIEW_MATRIX = VIEW_MATRIX * mat4(
			INV_VIEW_MATRIX[0], INV_VIEW_MATRIX[1], INV_VIEW_MATRIX[2], MODEL_MATRIX[3]);
		// The instance transform's own scale is lost with the basis above, so
		// it comes back through the vertex. `.x` of the instance basis carries
		// the authored radius.
		float authored = length(MODEL_MATRIX[0].xyz);
		VERTEX *= authored * scale * alive;
	} else {
		VERTEX *= scale * alive;
	}
}

void fragment() {
	// QuadMesh UVs run 0..1; a radial falloff from the middle.
	vec2 d = UV - vec2(0.5);
	float r = clamp(length(d) * 2.0, 0.0, 1.0);
	float falloff = pow(max(1.0 - r, 0.0), core_power);
	// A faint wider halo under the core, so the shape has an edge that dies in
	// the grass instead of a hard disc boundary.
	float halo = pow(max(1.0 - r, 0.0), 1.1) * rim_gain;
	float a = (falloff + halo) * v_fade * strength * COLOR.a;
	ALBEDO = COLOR.rgb * a;
	ALPHA = 1.0;
}
