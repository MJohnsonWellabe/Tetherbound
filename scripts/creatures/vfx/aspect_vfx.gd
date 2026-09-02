extends Node3D

## T1-CREATURE-ART. Idle VFX for an Aspect variant: purple flame
## (Nightburrow), electric arcs (Stormtrail), rift motes (Riftfrill) or
## ember/smoke (Ashtusk), plus a glowing-eyes billboard shared by all four --
## docs/owner/TETHERBOUND_MEADOWS_CREATURE_EXPANSION.md names one of
## these on every one of the four boards, and Nightburrow's own sheet is
## explicit that this is pass/fail, not decorative: "the purple flame effect
## is important. Without emissive/VFX treatment, this variant is not
## successful."
##
## Built the same way alpha_aura.gd's ring already is, and for the same
## reasons that file's own header states (re-quoted here because a lane
## reading this file in isolation needs them, not just a pointer):
##   * GPUParticles3D is not trustworthy under the software (llvmpipe)
##     renderer this project's survey captures run under, so an effect built
##     from a real particle system cannot be judged from a rendered frame --
##     and a visual-affecting change that cannot be judged from a frame
##     cannot ship under docs/AGENT_WORKFLOW.md.
##   * Additive blending renders at a fraction of its nominal strength under
##     the Compatibility renderer -- BLEND_MODE_MIX only, same as alpha_aura.
##   * Camera-facing ImmediateMesh billboards, vertex-coloured fade to a
##     transparent rim, no texture, no allocation in the per-frame loop.
##
## `_disc()` below is deliberately a near-duplicate of alpha_aura.gd's own
## private helper rather than a shared static: both are small (~12 lines),
## alpha_aura.gd is proven in production, and this lane chose not to risk a
## refactor of code it does not own the test coverage for over saving one
## short function. Flagged in this lane's own handover as a live "reuse vs.
## risk" call rather than silently duplicated.

## JUDGE-5 2026-08-30 D19: at 8 segments a close-range disc's facets showed as
## a visible hexagon/octagon rather than a round glow ("visibly hexagonal
## rather than round" on Nightburrow's eye sprites specifically). Doubled --
## negligible cost (an unshaded, un-textured, screen-space-tiny triangle fan)
## for a silhouette that reads as a soft point light at any zoom level this
## project's cameras use.
const MOTE_SEGMENTS := 16

## Default eye-glow anchor as (lateral, height, forward) fractions of
## (radius, height, radius) -- see `_draw_eyes()`. Per-species override lives
## in that species' own PRESETS entry as `eye_anchor` (same three fractions),
## for a species whose head shape puts the default noticeably off the real
## eye -- Nightburrow needed one, see its own entry below.
const DEFAULT_EYE_ANCHOR := Vector3(0.28, 0.68, 0.88)

## Per-preset tuning, one entry per Aspect variant. `primary_*` is the
## dominant effect every board leads with (back flame / spine arcs / floating
## motes / rising embers); `paw_*` is the smaller, lower, subtler secondary
## group every board also names ("subtle purple particles around paws",
## "sparks around paws"); `eye_colour` feeds the shared eye-glow billboard.
const PRESETS := {
	"nightburrow": {
		"primary_colour": Color(0.62, 0.25, 0.95),
		"primary_count": 10,
		"rise_period": 1.6,
		"orbit_period": 0.0,
		"jitter": 0.0,
		"height_bias": 1.35,
		"radius_scale": 0.7,
		"size_scale": 0.2,
		"paw_colour": Color(0.62, 0.25, 0.95),
		"paw_count": 4,
		"eye_colour": Color(0.82, 0.55, 1.0),
		# JUDGE-5 2026-08-30 D19: the shared default anchor sat on this
		# species' forehead well above its real eyes -- "two pink glow
		# sprites... on the forehead... the animal's actual eyes are below
		# them" -- reading as a second, higher pair of eyes. Burrowback's
		# head is rounder and squatter than the other three species' (the
		## default was tuned mainly against the two longer-snouted canines/
		# boar), so its eyeline sits at a lower height fraction and closer to
		# the centreline than the shared default assumes. Lowered and pulled
		# in, checked by rendering this species specifically.
		"eye_anchor": Vector3(0.16, 0.46, 0.82),
	},
	"stormtrail": {
		"primary_colour": Color(0.55, 0.78, 1.0),
		"primary_count": 9,
		"rise_period": 0.55,
		"orbit_period": 0.0,
		"jitter": 1.0,
		"height_bias": 1.1,
		"radius_scale": 1.0,
		"size_scale": 0.12,
		"paw_colour": Color(1.0, 0.86, 0.35),
		"paw_count": 4,
		"eye_colour": Color(0.5, 0.85, 1.0),
	},
	"riftfrill": {
		"primary_colour": Color(0.68, 0.5, 1.0),
		"primary_count": 8,
		"rise_period": 3.4,
		"orbit_period": 9.0,
		"jitter": 0.0,
		"height_bias": 1.15,
		"radius_scale": 1.3,
		"size_scale": 0.16,
		"paw_colour": Color(0.68, 0.5, 1.0),
		"paw_count": 0,
		"eye_colour": Color(0.78, 0.6, 1.0),
	},
	"ashtusk": {
		"primary_colour": Color(1.0, 0.55, 0.18),
		"primary_count": 7,
		"rise_period": 2.4,
		"orbit_period": 0.0,
		"jitter": 0.0,
		"height_bias": 1.3,
		"radius_scale": 0.7,
		"size_scale": 0.15,
		"paw_colour": Color(0.55, 0.55, 0.55),
		"paw_count": 3,
		"eye_colour": Color(1.0, 0.6, 0.2),
		"tusk_colour": Color(1.0, 0.62, 0.16),
	},
}

var _preset: Dictionary = {}
var _radius: float = 0.6
var _height: float = 1.0
var _life: float = 0.0

var _mesh: ImmediateMesh = null
var _instance: MeshInstance3D = null
var _eye_mesh: ImmediateMesh = null
var _eye_instance: MeshInstance3D = null


## `radius`/`height` are the creature's own gameplay body size (same PW2
## numbers the collider and the alpha aura use), so the effect grows with the
## individual it belongs to. Returns null for an id with no preset rather than
## building an empty effect silently.
static func attach(body: Node3D, variant_id: String, radius: float, height: float) -> Node3D:
	if not PRESETS.has(variant_id):
		push_warning("aspect_vfx: no preset for '%s'" % variant_id)
		return null
	var vfx := new()
	vfx.name = "AspectVfx_%s" % variant_id
	vfx._preset = PRESETS[variant_id]
	vfx._radius = maxf(radius, 0.15)
	vfx._height = maxf(height, 0.3)
	body.add_child(vfx)
	return vfx


func _ready() -> void:
	_mesh = ImmediateMesh.new()
	_instance = MeshInstance3D.new()
	_instance.mesh = _mesh
	_instance.material_override = _material(false)
	_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var reach: float = maxf(_radius * 3.0, _height * 1.8)
	_instance.custom_aabb = AABB(Vector3.ONE * -reach, Vector3.ONE * reach * 2.0)
	add_child(_instance)

	# Eyes get their OWN mesh/material, depth-test disabled -- see
	# `_draw_eyes()`'s header for why: the anchor is a body-proportion
	# estimate, not a per-species-measured eye socket, so on a real GLB
	# model (as opposed to the capsule placeholder this anchor was
	# originally written for) it can sit fractionally inside the head's own
	# opaque geometry, which silently loses the depth test against the
	# model's own fur/scale surface. A depth-tested billboard that loses that
	# test is not dim, it is INVISIBLE, and that failure mode is
	# indistinguishable from "the effect never fired" in a rendered frame --
	# which is exactly what JUDGE-4 2026-08-30 found: eye colour absent in
	# every one of the four variants' close-ups, confirmed not merely
	# mis-tuned because the primary/paw groups (anchored well clear of the
	# body) render correctly on the same creatures. Two small always-visible
	# discs at the head cannot double-draw through a wall the way a depth-
	# tested effect could, so the tradeoff this makes -- guaranteed visible,
	# at the cost of never being occluded -- is the right one for a cue this
	# small and this close to the model's own silhouette.
	_eye_mesh = ImmediateMesh.new()
	_eye_instance = MeshInstance3D.new()
	_eye_instance.mesh = _eye_mesh
	_eye_instance.material_override = _material(true)
	_eye_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_eye_instance.custom_aabb = AABB(Vector3.ONE * -reach, Vector3.ONE * reach * 2.0)
	add_child(_eye_instance)


func _material(no_depth_test: bool) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.blend_mode = BaseMaterial3D.BLEND_MODE_MIX
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.disable_receive_shadows = true
	material.vertex_color_use_as_albedo = true
	# Depth-tested for the primary/paw groups, same call alpha_aura.gd makes
	# and for the same reason: this effect sits ON and AROUND the animal's
	# own silhouette, so a mote passing behind a limb should be correctly
	# hidden rather than drawn through it. The eye-glow material (see
	# `_ready()`'s comment) is the one exception, passed `true`.
	material.no_depth_test = no_depth_test
	return material


func _physics_process(delta: float) -> void:
	_life += delta
	var camera := get_viewport().get_camera_3d()
	if camera == null:
		return
	var basis := camera.global_transform.basis
	var right: Vector3 = basis.x
	var up: Vector3 = basis.y

	_mesh.clear_surfaces()
	_mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	_draw_primary(right, up)
	_draw_paws(right, up)
	_mesh.surface_end()

	# Eyes and tusks share the depth-test-disabled mesh -- see `_ready()`'s
	# comment on `_eye_instance` for why both need it: both anchors are body-
	# proportion estimates rather than a per-species-measured feature, so on
	# a real model either can land fractionally inside the head's own opaque
	# geometry and lose the depth test silently.
	_eye_mesh.clear_surfaces()
	_eye_mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	_draw_eyes(right, up)
	_draw_tusks(right, up)
	_eye_mesh.surface_end()


func _draw_primary(right: Vector3, up: Vector3) -> void:
	var count: int = int(_preset.get("primary_count", 8))
	var rise_period: float = maxf(float(_preset.get("rise_period", 2.0)), 0.05)
	var orbit_period: float = float(_preset.get("orbit_period", 0.0))
	var jitter: float = float(_preset.get("jitter", 0.0))
	var colour: Color = _preset.get("primary_colour", Color.WHITE)
	var height_bias: float = float(_preset.get("height_bias", 0.8))
	var radius_scale: float = float(_preset.get("radius_scale", 0.5))
	var size_scale: float = float(_preset.get("size_scale", 0.14))

	for index in count:
		var offset: float = float(index) / float(maxi(count, 1))
		var rise: float = fmod(_life / rise_period + offset, 1.0)
		# No orbit period (Nightburrow, Stormtrail, Ashtusk): motes climb
		# staggered around the centreline rather than sweeping round it, which
		# reads as "on the animal's back" rather than "circling the animal".
		# Riftfrill's is the one variant that DOES orbit -- a slow drifting
		# ring of motes, same shape as alpha_aura.gd's, matching its board's
		# "gentle psychic/rift distortion... floating motes" rather than a
		# flame or a spark.
		var angle: float = TAU * (offset + _life / orbit_period) if orbit_period > 0.01 \
			else TAU * offset
		var fade: float = sin(rise * PI)
		var jitter_offset: float = 0.0
		if jitter > 0.0:
			# Stormtrail: sparks flash on and off rather than smoothly rising --
			# a fast per-mote pseudo-random flicker, so the group reads as
			# electricity crackling rather than as a candle flame. Cheap
			# sine-hash rather than an RNG object: this runs every physics
			# frame for every mote and has no state to seed.
			var hash_in: float = sin(offset * 91.7 + _life * 23.0) * 43758.5453
			var flicker: float = absf(fmod(hash_in, 1.0))
			fade *= 1.0 if flicker > (1.0 - jitter * 0.55) else flicker * 0.25
			jitter_offset = (flicker - 0.5) * radius_scale * _radius * 0.7
		if fade <= 0.02:
			continue
		var swell: float = 1.0 - 0.3 * rise
		var ring_radius: float = _radius * radius_scale * swell
		var centre := Vector3(
			cos(angle) * ring_radius + jitter_offset,
			_height * (height_bias * rise + 0.05),
			sin(angle) * ring_radius * 0.6)
		var size: float = _radius * size_scale * (0.6 + 0.4 * fade)
		var draw_colour := Color(colour.r, colour.g, colour.b, fade * 0.75)
		_disc(_mesh, centre, right * size, up * size, draw_colour)


func _draw_paws(right: Vector3, up: Vector3) -> void:
	var count: int = int(_preset.get("paw_count", 0))
	if count <= 0:
		return
	var colour: Color = _preset.get("paw_colour", Color.WHITE)
	# Four feet, roughly a quadruped's stance either side of the centreline,
	# fore and aft. Subtler and lower than the primary group on purpose --
	# every board that names paw particles calls them "subtle".
	var stances := [
		Vector2(0.45, 0.55), Vector2(-0.45, 0.55),
		Vector2(0.45, -0.55), Vector2(-0.45, -0.55),
	]
	for index in count:
		var stance: Vector2 = stances[index % stances.size()]
		var offset: float = float(index) / float(maxi(count, 1))
		var rise: float = fmod(_life / 1.4 + offset, 1.0)
		var fade: float = sin(rise * PI)
		if fade <= 0.02:
			continue
		var centre := Vector3(
			stance.x * _radius,
			_height * 0.06 + _height * 0.14 * rise,
			stance.y * _radius)
		var size: float = _radius * 0.09 * (0.6 + 0.4 * fade)
		var draw_colour := Color(colour.r, colour.g, colour.b, fade * 0.5)
		_disc(_mesh, centre, right * size, up * size, draw_colour)


## Shared by every variant: two small bright discs near the head. The BODY's
## own local +Z is always gameplay forward regardless of which way a given
## mesh's raw UVs point -- `creature_body._build_model()` applies each
## species' own `model_yaw` correction before this node is ever attached,
## the same fact combat's `facing()` already depends on -- so no per-species
## FORWARD correction is needed here. The anchor originally borrowed
## `creature_body._build_capsule()`'s own placeholder-snout position
## verbatim (`Vector3(0.0, _height * 0.82, _radius * 0.9)`), reasoning that
## since that formula places a believable head on the FALLBACK capsule, it
## would place a believable eye on a real model too. It does not: a real
## GLB's head proportions do not match a capsule-and-cone placeholder's, and
## rendering all four species side by side at this anchor (T1-VARIANTS-2
## 2026-08-30) showed it sitting between the ears above the eyeline on the
## canine and boar models. Retuned by rendering each of the four in turn
## (lower, and a touch further forward) until the disc landed on or just
## above the eye on every one of them at that pass's render checks -- but
## JUDGE-5's blind pass caught what those checks missed on Nightburrow
## specifically: "two pink glow sprites... on the forehead... the animal's
## actual eyes are below them", reading as a second, higher pair of eyes
## (D19). One shared constant could not fit both the two longer-snouted
## canine/boar models AND a shorter, rounder badger head, so `eye_anchor` is
## now an optional per-species override in PRESETS (`DEFAULT_EYE_ANCHOR`
## when absent) -- Nightburrow's own entry documents its retune.
func _draw_eyes(right: Vector3, up: Vector3) -> void:
	var colour: Color = _preset.get("eye_colour", Color.WHITE)
	var pulse: float = 0.85 + 0.15 * sin(_life * 3.0)
	var size: float = _radius * 0.09
	var anchor: Vector3 = _preset.get("eye_anchor", DEFAULT_EYE_ANCHOR)
	for side in [-1.0, 1.0]:
		var centre := Vector3(side * _radius * anchor.x, _height * anchor.y, _radius * anchor.z)
		var draw_colour := Color(colour.r, colour.g, colour.b, pulse)
		_disc(_eye_mesh, centre, right * size, up * size, draw_colour)


## T1-VARIANTS 2026-08-30 (JUDGE-3 5b/5d): "Ashtusk's own 'ember-glowing
## tusks' specifically did not read at all... make them read." The texture
## layer alone (data/creatures/aspect_variants.json's `tusks` glow) cannot be
## guaranteed to land precisely on the two tusks -- there is no per-vertex
## tusk mask without new geometry, only a colour/anatomy heuristic, and this
## project's own boards are covered in similarly pale grey stone armour that
## competes with it. A small fixed billboard pair, anchored just below and
## forward of the shared eye anchor (mouth/tusk height on a quadruped's own
## head, same reasoning `_draw_eyes()` already gives for why no per-species
## tuning is needed here), guarantees the read regardless of texture
## precision. Only variants with a `tusk_colour` in their preset draw this --
## today that is Ashtusk alone.
func _draw_tusks(right: Vector3, up: Vector3) -> void:
	if not _preset.has("tusk_colour"):
		return
	var colour: Color = _preset.get("tusk_colour", Color.WHITE)
	var pulse: float = 0.7 + 0.3 * sin(_life * 2.2 + 1.4)
	var size: float = _radius * 0.07
	for side in [-1.0, 1.0]:
		var centre := Vector3(side * _radius * 0.4, _height * 0.58, _radius * 0.95)
		var draw_colour := Color(colour.r, colour.g, colour.b, pulse)
		_disc(_eye_mesh, centre, right * size, up * size, draw_colour)


## A soft mote: an opaque centre fanned out to a fully transparent rim. Same
## technique as alpha_aura.gd's own `_disc()` -- see this file's header for
## why it is duplicated here rather than shared. Takes an explicit target
## mesh (rather than always writing `_mesh`) so the eye/tusk billboards can
## land on their own depth-test-disabled surface -- see `_ready()`.
func _disc(target: ImmediateMesh, centre: Vector3, right: Vector3, up: Vector3, colour: Color) -> void:
	var rim := Color(colour.r, colour.g, colour.b, 0.0)
	for i in MOTE_SEGMENTS:
		var a0: float = TAU * float(i) / float(MOTE_SEGMENTS)
		var a1: float = TAU * float(i + 1) / float(MOTE_SEGMENTS)
		target.surface_set_color(colour)
		target.surface_add_vertex(centre)
		target.surface_set_color(rim)
		target.surface_add_vertex(centre + right * cos(a0) + up * sin(a0))
		target.surface_set_color(rim)
		target.surface_add_vertex(centre + right * cos(a1) + up * sin(a1))
