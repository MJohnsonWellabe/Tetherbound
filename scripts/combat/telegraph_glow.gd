extends Node3D

## The wind-up's own visual event, independent of the "! incoming" banner text.
##
## `R9.4-remainder-9-combat`: a blind critic covering the HUD text found the
## wind-up frame indistinguishable from ordinary standing — `combat_hud.gd`'s
## own comment already admits why, a placeholder creature has nothing built to
## show a charge-up. This is that something: a pulsing warning crest at the
## creature's feet for the exact length of the telegraph beat, so the read
## survives even with the banner covered.
##
## Same lessons `impact_flash.gd` already paid for: mesh-based rather than
## GPUParticles3D (particle behaviour is not trustworthy under the software
## renderer the survey captures with), MIX blend rather than ADD (additive
## renders at a fraction of its strength under the Compatibility renderer),
## and driven by the physics clock so the same beat looks the same in every
## survey run.

const SEGMENTS := 24
const PULSE_PERIOD := 0.32
## The glow fades to nothing in the last stretch of the beat rather than being
## cut off mid-pulse the instant the strike lands — an abrupt disappearance
## reads as a rendering glitch, not as "the warning is over."
const FADE_TAIL := 0.12
## N07-VFX-POLISH (D87): the ring is a mark on the ground at the foe's feet,
## and it is depth-tested again (see `_material`), so it needs to sit a hair
## above the terrain it marks or the terrain wins the depth test along the
## whole ring. `global_position` is the creature's origin, which
## `creature_body.gd::_fit` puts at the feet.
const GROUND_LIFT := 0.08

var _follow_body: Node3D = null
var _state_active: Callable
var _life: float = 0.0
var _duration: float = 0.55
var _radius: float = 1.1
## Follows combat.json `telegraph.colour`. N07-VFX-POLISH (D87): magenta -- a
## colour the meadow and the reward layer do not use -- not the red the
## reserved Team Tether oxblood band sits in, and not the reward gold a blind
## round read as "a dropped coin".
var _colour: Color = Color("#ff40e6")

## F14#0 (Tidecoil, #356 grant 5860240387): a world that reports water depth
## (`water_depth_at(position)`, the Water realm) gets the ring on the water
## SURFACE, not on the seabed under it: a code-blind judge found 0 of 4
## Tidecoil wind-ups showed any ground mark, because the opaque surface hid it.
## Null means the current scene, resolved when the ring is drawn; tests set it.
var water_depth_source: Object = null

var _ring: MeshInstance3D = null
var _ring_mesh: ImmediateMesh = null
## Heights belong to one mesh rebuild, never to a later pulse or moved body.
var _ground_seen: Dictionary = {}
var _drawn: Array = []
var _draw_origin := Vector3.ZERO
var _draw_has_ground := false
var _draw_water: Object = null
var _draw_has_water := false


## `at` is the creature's feet, not its centre — this is a ring on the ground,
## not a billboard on the body.
static func begin(parent: Node, at: Vector3, colour: Color, radius: float, duration: float) -> Node3D:
	var glow := new()
	glow._colour = colour
	glow._radius = radius
	glow._duration = duration
	parent.add_child(glow)
	# Same guard `vfx_burst.gd::spawn` carries: a unit fixture hosts the ring
	# under a bare Node3D with no tree, where `global_position` has no meaning.
	if glow.is_inside_tree():
		glow.global_position = at + Vector3.UP * GROUND_LIFT
	else:
		glow.position = at + Vector3.UP * GROUND_LIFT
	return glow


func _ready() -> void:
	_ring_mesh = ImmediateMesh.new()
	_ring = MeshInstance3D.new()
	_ring.mesh = _ring_mesh
	_ring.material_override = _material()
	_ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var reach := _radius * 2.5
	# Tall enough for a ring lifted from a creature's feet on the seabed to the
	# water surface above it (see `_ground_vertex`).
	_ring.custom_aabb = AABB(Vector3(-reach, -0.2, -reach), Vector3(reach * 2.0, reach + 6.0, reach * 2.0))
	add_child(_ring)


func _material() -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.blend_mode = BaseMaterial3D.BLEND_MODE_MIX
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.roughness = 0.85
	material.emission_enabled = true
	material.emission = _colour
	material.emission_energy_multiplier = 0.12
	material.vertex_color_use_as_albedo = true
	# R9.4-remainder-9-combat-2: tried the same fix `impact_flash.gd`'s own
	# `no_depth_test` comment documents (this ring spawns "at the creature's
	# feet", overlapping its mesh footprint the same way the impact burst
	# does, while the arena boundary and target marker -- the codebase's
	# other `no_depth_test = false` ground/near effects -- both sit apart
	# from any creature mesh and never hit this). A first off-axis capture
	# (`04-enemy-winds-up-offaxis.png`, run 1) showed a fully visible,
	# unoccluded wild creature with NO ring at its feet at all, at a moment the
	# HUD's own "! incoming" text confirms the wind-up was active -- looked
	# like the same depth-loses-to-the-creature symptom.
	#
	# It was NOT. Set to true and RE-RENDERED to check (not asserted): a
	# second full survey, same unoccluded framing, still shows no ring at
	# all. Left true anyway -- it is still the correct value by the same
	# reasoning that fixed `impact_flash.gd`, and reverting it would not make
	# the ring appear or disappear either way -- but the real cause of "no
	# ring ever draws" is still open. Worth checking next: whether
	# `telegraph_started` is actually reaching `_on_enemy_telegraph`
	# (combat_manager.gd) at all for this creature/attack, before touching
	# this file's own drawing code again.
	#
	# N07-VFX-POLISH (D87), 2026-09-05: RE-RENDERED with the ring drawing, and
	# `true` turned out to be the defect W09's blind judge reported as "a dull
	# oxblood torus across the creature's chest" on the FRIENDLY creature. The
	# ring is at the foe's feet; the foe stands beyond the ally from the combat
	# camera; without a depth test the ring is painted straight through the
	# ally's back (before-frames `05-telegraph` / `06-telegraph-behind`,
	# `ralph/reports/N07-VFX-POLISH-0905/`). A mark on the ground is exactly
	# the case `alpha_aura.gd` and W09's round-3 level-up rings keep depth
	# testing for: the far half passes behind the creature it belongs to, and
	# the near half does not draw over a body standing in front. `GROUND_LIFT`
	# keeps the terrain from winning the test. The `impact_flash.gd` argument
	# (a burst BETWEEN two intersecting bodies) never applied to a ground ring.
	material.no_depth_test = false
	# F14#0 (Tidecoil): over water the ring shares the transparent pass with
	# the sea surface, which sorts by origin; the ring's origin is at the
	# creature's feet on the seabed, so the sea drew over it. Drawn after the
	# default priority, still depth-tested against bodies.
	material.render_priority = 1
	return material


## A combat beat owns its lifetime, including interruptions and body hitstop.
func follow_state(body: Node3D, active: Callable) -> void:
	_follow_body = body
	_state_active = active
	if is_instance_valid(body) and body.has_method("body_radius"):
		# The inner edge (72% of radius) must clear the live footprint.
		_radius = maxf(_radius, float(body.call("body_radius")) * 1.5)
	if _ring != null:
		var reach := _radius * 2.5
		_ring.custom_aabb = AABB(Vector3.ONE * -reach, Vector3.ONE * reach * 2.0)


func _physics_process(delta: float) -> void:
	if _state_active.is_valid():
		if not is_instance_valid(_follow_body) or not bool(_state_active.call()):
			queue_free()
			return
		if is_inside_tree():
			global_position = _follow_body.global_position + Vector3.UP * GROUND_LIFT
		else:
			position = _follow_body.position + Vector3.UP * GROUND_LIFT
	_life += delta
	if not _state_active.is_valid() and _life >= _duration:
		queue_free()
		return

	var phase: float = fmod(_life, PULSE_PERIOD) / PULSE_PERIOD
	var eased: float = 1.0 - pow(1.0 - phase, 2.0)
	var tail: float = 1.0 if _state_active.is_valid() else clampf((_duration - _life) / FADE_TAIL, 0.0, 1.0)
	if _state_active.is_valid():
		# Pulse outside the body, never shrink into an invisible disc beneath it.
		_draw_ring(_radius * (1.0 + eased * 0.2), (0.55 + (1.0 - eased) * 0.45) * tail)
	else:
		_draw_ring(_radius * (0.35 + eased * 0.65), (1.0 - eased) * tail)


func _ground_vertex(offset: Vector3) -> Vector3:
	var key := Vector2(offset.x, offset.z)
	if _ground_seen.has(key):
		offset.y = float(_ground_seen[key])
		return offset
	var origin := _draw_origin
	if _draw_has_ground:
		var height := float(_follow_body.call("_ground_height", origin.x + offset.x, origin.z + offset.z))
		if is_finite(height):
			height += _water_depth(Vector3(origin.x + offset.x, height, origin.z + offset.z))
			offset.y = height + GROUND_LIFT - origin.y
	else:
		# No ground query: the ring stays at the feet, lifted to any water
		# surface above them.
		offset.y += _water_depth(origin - Vector3.UP * GROUND_LIFT + Vector3(offset.x, 0.0, offset.z))
	_ground_seen[key] = offset.y
	return offset


func _water_depth(at: Vector3) -> float:
	if not _draw_has_water:
		return 0.0
	var depth := float(_draw_water.call("water_depth_at", at))
	return depth if is_finite(depth) and depth > 0.0 else 0.0


## A raised, lit crest has the same inner/outer ground footprint and pulse.
## Both skirts meet the sampled terrain/water; only the middle rises. Colour
## and opacity taper across the section instead of painting a flat annulus.
func _draw_ring(radius: float, alpha: float) -> void:
	var origin := global_position if is_inside_tree() else position
	var water: Object = water_depth_source
	if water == null and is_inside_tree():
		water = get_tree().current_scene
	var inputs := [origin, radius, alpha, _colour, _follow_body, water]
	# These APIs can change their heights without changing object identity.
	# Only a ring with no ground/water query has an unchanged aim for certain.
	var queries_ground := is_instance_valid(_follow_body) and _follow_body.has_method("_ground_height")
	var queries_water := is_instance_valid(water) and water.has_method("water_depth_at")
	if not queries_ground and not queries_water and inputs == _drawn:
		return
	_drawn = inputs
	# This rebuild is synchronous: resolve these once, not for every vertex.
	_draw_origin = origin
	_draw_has_ground = queries_ground
	_draw_water = water
	_draw_has_water = queries_water
	_ground_seen.clear()
	var inner := radius * 0.72
	_ring_mesh.clear_surfaces()
	_ring_mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	var foot := _colour.darkened(0.35)
	foot.a = alpha * 0.2
	var crest := _colour.lightened(0.3)
	crest.a = alpha
	var previous: Array[Vector3] = []
	for i in SEGMENTS + 1:
		var angle: float = TAU * float(i) / float(SEGMENTS)
		var direction := Vector3(cos(angle), 0.0, sin(angle))
		var section: Array[Vector3] = [_ground_vertex(direction * inner),
			_ground_vertex(direction * lerpf(inner, radius, 0.5)) + Vector3.UP * (radius - inner) * 0.5,
			_ground_vertex(direction * radius)]
		if not previous.is_empty():
			_crest_triangle(previous[0], section[0], section[1], foot, foot, crest)
			_crest_triangle(previous[0], section[1], previous[1], foot, crest, crest)
			_crest_triangle(previous[1], section[1], section[2], crest, crest, foot)
			_crest_triangle(previous[1], section[2], previous[2], crest, foot, foot)
		previous = section
	_ring_mesh.surface_end()


func _crest_triangle(a: Vector3, b: Vector3, c: Vector3, ca: Color, cb: Color, cc: Color) -> void:
	var normal := (b - a).cross(c - a).normalized()
	if normal.y < 0.0: normal = -normal
	if normal.is_zero_approx(): normal = Vector3.UP
	_ring_mesh.surface_set_normal(normal)
	_ring_mesh.surface_set_color(ca)
	_ring_mesh.surface_add_vertex(a)
	_ring_mesh.surface_set_color(cb)
	_ring_mesh.surface_add_vertex(b)
	_ring_mesh.surface_set_color(cc)
	_ring_mesh.surface_add_vertex(c)
