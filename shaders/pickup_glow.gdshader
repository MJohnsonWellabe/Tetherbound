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
// 1. **It is the ITEM that glows.** Two owner directives on 2026-08-30 shaped
//    this: *"glow on the actual item, not floating in the air above it"* and
//    *"don't make it take over the items actual geometry or design. just add
//    the glow to them."* So the mark is centred on the prop's own body, and it
//    is pushed BEHIND that body along the view axis -- the item is opaque and
//    writes depth, so it occludes the middle of its own glow and only the halo
//    escapes around its silhouette. The object is drawn whole, with light
//    coming out from behind it, instead of being replaced by a bright disc.
//
//    Grass is beaten by RADIUS rather than by altitude. `grass_field.json`'s
//    blades stand 0.40-0.62m with 0.38 jitter -- about 0.86m at the tallest --
//    and a halo centred low on the prop still reaches above that, while
//    reaching up OUT OF the object rather than hovering over it. The depth test
//    stays honest either way: terrain, trees and buildings occlude this exactly
//    as they should.
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

uniform float core_power = 1.4;
uniform float core_inner = 0.28;
uniform float rim_gain = 0.35;
// Metres the billboard is pushed away from the camera, so the item occludes the
// middle of its own glow. See the note at the push itself.
uniform float behind = 0.35;
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
		// OWNER DIRECTIVE, 2026-08-30: the glow must not take over the item's own
		// geometry or design.
		//
		// A camera-facing quad centred on the object paints over the front of it,
		// so the player sees a bright disc where the object used to be -- the
		// object stops being visible at exactly the moment it is meant to be
		// noticed. Pushing the quad BEHIND the object along the view axis fixes
		// that with the depth test rather than with opacity: the item is opaque
		// and writes depth, so it occludes the middle of the glow and only the
		// halo escapes around its silhouette. The item is drawn intact, with
		// light coming out from behind it.
		// `behind` is a small constant margin; INSTANCE_CUSTOM.y carries HALF THE
		// PROP'S OWN CROWN, so a 20cm TM orb is cleared by 10cm and a
		// two-metre deadwood pile by a metre. A single fixed push cannot do
		// both: sized for the log it puts a small find's whole glow underground,
		// and sized for the find it paints over the log.
		VERTEX.z -= behind + INSTANCE_CUSTOM.y;
	} else {
		VERTEX *= scale * alive;
	}
}

void fragment() {
	// QuadMesh UVs run 0..1; a radial profile from the middle.
	vec2 d = UV - vec2(0.5);
	float r = clamp(length(d) * 2.0, 0.0, 1.0);

	// A disc with a real body, not a point with a long tail.
	//
	// The first version was `pow(1.0 - r, core_power)` alone, and the isolated
	// render (`tools/_probe_pickup_glow_isolated.gd`) showed exactly what is
	// wrong with that: at `core_power` around 2 the visible core is the middle
	// fifth of the quad and everything outside it is below the noise floor of a
	// bright daylit meadow. The quad's authored radius stopped predicting how
	// big the glow READS, so tuning it was guesswork.
	//
	// `core_inner` is the fraction of the radius held at full strength before
	// the falloff starts, so the disc has a body whose size is the radius that
	// was authored, and `core_power` only shapes how softly it ends.
	float core = pow(1.0 - smoothstep(core_inner, 1.0, r), core_power);
	// A faint wider halo under it, so the shape dies into the grass rather than
	// ending on a disc boundary.
	float halo = pow(max(1.0 - r, 0.0), 1.1) * rim_gain;
	float a = (core + halo) * v_fade * strength * COLOR.a;
	ALBEDO = COLOR.rgb * a;
	ALPHA = 1.0;
}
