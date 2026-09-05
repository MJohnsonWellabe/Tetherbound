extends Node3D

## The predicted arc of the orb, drawn while aiming.
##
## The reticle promised where the throw would GO, but the orb flies a parabola
## (speed 17, gravity 14 in catching.json) and lands well below the crosshair
## at any range — the single biggest reason the owner's playtest called the
## mechanic bad. This draws the truth: the exact flight path a release RIGHT
## NOW would take, plus a disc where it ends.
##
## The arc must share `throw_aim.gd`'s own numbers or it becomes a second
## implementation that drifts — so `update_arc()` takes the origin, direction
## and speed that `_release()` would use, computed by the same code
## (`_launch_direction`), and integrates the same closed-form parabola `orb.gd`
## steps through. If the preview and the orb ever disagree, one of them
## changed alone.
##
## Ground is asked of the world (`ground_height_at`, docs/decisions/D09) —
## never a raycast, which lies about Terrain3D roughly a quarter of the time.

const SAMPLES := 32

## Dashed-arc restyle (spec §10.3): the same SAMPLES-point trajectory, drawn
## as short luminous segments with gaps rather than one continuous line, so
## the arc reads as a THROWN thing rather than a ruled line drawn on the
## world. `DASH_COVERAGE` is the fraction of each [i, i+1) sample interval
## that is actually drawn — 0.6 leaves a visible gap between dashes without
## the arc reading as broken into disconnected pieces at this many samples.
const DASH_COVERAGE := 0.72

## OWNER DIRECTIVE 2026-08-28 §2a.1: "the cone of visibility of where the ball
## is going needs to be way more obvious." The owner played the shipped build
## and named this as the reason catching feels bad -- ahead of odds, physics and
## the catch UI.
##
## Four things were making this arc unreadable, and they compounded:
##
## 1. It was drawn with `PRIMITIVE_LINES`, which is ONE PIXEL WIDE. At the
##    project's 1920 authored canvas that is 0.05% of screen width, over a
##    grass field measured at 65% blade coverage in front of the target.
## 2. It faded to `FADE_FAR_ALPHA` 0.25 along its length -- so it was at its
##    LEAST visible at the landing point, which is the one part the player is
##    actually reading.
## 3. `no_depth_test = false` meant grass blades drew over it. The same blades
##    that hide the creature were hiding the aim.
## 4. The landing marker was a 0.34m ring lying FLAT in grass that stands
##    0.25-0.86m tall, so the indicator for where the orb lands was inside the
##    thing obscuring it.
##
## Fixed as a ribbon of real world-space width that widens toward the landing
## point (which is what makes it read as a cone rather than a wire), holds its
## alpha to the end, draws over the grass, and plants a marker that stands UP
## out of the field instead of lying in it.

## The ribbon's width is ANGULAR, not a fixed world-space size.
##
## A first pass used fixed metres (0.045 near, 0.16 far) and the render was
## unusable: the near end of the arc leaves the trainer's hand less than a metre
## from the aim camera, so a 0.09m band there subtended about ten degrees and
## drew a teal slab across the middle of the screen, over the player's own
## creature. World-space width is the wrong unit for something whose entire job
## is to be legible on screen.
##
## So the half-width is a constant ANGLE from the eye, clamped at both ends: it
## cannot bloom in the player's face, and it cannot thin back to the one-pixel
## wire this replaces at the far end of a long throw.
##
## 0.010 rad is about 0.6 degrees of half-width, so the ribbon reads at roughly
## 1.2 degrees across -- comfortably wider than the ~0.05 degrees a one-pixel
## line gave at this canvas, and narrow enough that it does not become the thing
## it is drawn over. TUNABLE by feel; the clamps are what stop it misbehaving at
## either extreme of range.
const RIBBON_ANGULAR_HALF := 0.010
const RIBBON_HALF_MIN := 0.018
const RIBBON_HALF_MAX := 0.115
## The cone: the far end draws this much wider than the near end, on top of the
## angular width above. This is what makes it read as a cone rather than a
## constant-width tape, and it is honest -- the far end is where a moving target
## and the release timing put the real spread.
const RIBBON_FAR_FLARE := 2.4
## Metres of the arc closest to the EYE that are not drawn at all. The first
## stretch leaves the hand right under the camera, where even an angular width
## is a smear across the view, and it carries no information the player needs --
## they know where their own hand is.
const RIBBON_NEAR_SKIP := 1.6
## Alpha along the ribbon. Near-transparent at the hand so it does not sit on
## the trainer, full at the landing end -- the exact inverse of the fade this
## replaces.
const FADE_NEAR_ALPHA := 0.55
const FADE_FAR_ALPHA := 1.0
## A darker casing drawn under the ribbon, slightly wider. Grass runs both light
## (sunlit tips, luminance ~0.46) and dark (shadowed bases, ~0.24), so a single
## bright ribbon disappears against one or the other wherever it crosses. An
## outline separates it from both.
## The casing's extra width is a MULTIPLE of the ribbon's own half-width rather
## than a fixed margin, for the same reason the width itself is angular: a fixed
## 0.055m outline is invisible at range and a slab up close.
const CASING_EXTRA_HALF := 0.55
const CASING_COLOUR := Color(0.03, 0.06, 0.07, 0.85)

## The landing indicator: a small ring plus a centre dot, restyled from the
## old flat disc — a disc reads as a coin sitting in the grass, a ring+dot
## reads as an impact point.
## The landing indicator. Grown, and given a vertical element: a ring lying in
## grass that stands up to 0.86m tall is inside the thing hiding it, so the ring
## is joined by a stalk that clears the field and a bead at the top of it. The
## ring still says WHERE; the stalk is what you actually catch sight of.
const MARKER_RING_RADIUS := 0.52
const MARKER_RING_TUBE := 0.055
const MARKER_DOT_RADIUS := 0.10
## Tall enough to clear `grass_field.json`'s own tuft range (height_far 0.62 x
## (1 + jitter 0.38) = 0.86m at its tallest) with margin.
const MARKER_STALK_HEIGHT := 1.15
const MARKER_STALK_RADIUS := 0.028
const MARKER_BEAD_RADIUS := 0.085

var _line: MeshInstance3D = null
var _line_mesh: ImmediateMesh = null
var _marker: Node3D = null
var _marker_ring: MeshInstance3D = null
var _marker_dot: MeshInstance3D = null
var _marker_stalk: MeshInstance3D = null
var _marker_bead: MeshInstance3D = null
var _casing: MeshInstance3D = null
var _casing_mesh: ImmediateMesh = null

## Whether the arc drawn this frame actually reaches the creature. See
## `update_arc()`; read by `throw_aim.gd::aim_report()`.
var trajectory_hits_target := false
## Metres off the target's centre the previewed flight passes. Valid only while
## `trajectory_hits_target`; INF otherwise.
var trajectory_offset := INF

const ORB := preload("res://scripts/combat/orb.gd")

var _gravity: float = 14.0
var _max_flight: float = 4.0
## OF19: was a bare `0.42` literal at the hit-test below, which quietly
## drifted out of sync with `catching.json`'s own `throw.radius` the moment
## that got widened — the preview would keep promising the OLD, narrower hit
## zone while `orb.gd` was actually using the new, wider one. Read the same
## key `orb.gd` does so the preview never again lies about what counts as
## a hit.
var _orb_radius: float = 0.42

## Colour states: aimed at the creature vs landing on dirt. `_ready()` pulls
## the actual values from `UITokens` (`TEAL_SOFT` on-target, `TEXT_SECONDARY`
## on-ground) with each one's own alpha layered on — a `const` can't call
## into another class's statics, so these start as the same values `UITokens`
## currently holds and are refreshed once at `_ready()` in case that ever
## drifts.
var ON_TARGET := Color(0.451, 0.902, 0.867, 0.9)
var ON_GROUND := Color(0.722, 0.773, 0.769, 0.55)


func _ready() -> void:
	var cfg_file := FileAccess.open("res://data/config/catching.json", FileAccess.READ)
	if cfg_file != null:
		var parsed: Variant = JSON.parse_string(cfg_file.get_as_text())
		if parsed is Dictionary:
			var throw: Dictionary = (parsed as Dictionary).get("throw", {})
			_gravity = float(throw.get("gravity", _gravity))
			_max_flight = float(throw.get("max_flight_time", _max_flight))
			_orb_radius = float(throw.get("radius", _orb_radius))

	ON_TARGET = Color(UITokens.TEAL_SOFT, 0.9)
	ON_GROUND = Color(UITokens.TEXT_SECONDARY, 0.55)

	# Casing first so it draws under the ribbon (same render priority band,
	# added earlier, and its material is written with a lower priority below).
	_casing_mesh = ImmediateMesh.new()
	_casing = MeshInstance3D.new()
	_casing.mesh = _casing_mesh
	_casing.material_override = _overlay(-1)
	_casing.top_level = true
	add_child(_casing)

	_line_mesh = ImmediateMesh.new()
	_line = MeshInstance3D.new()
	_line.mesh = _line_mesh
	_line.material_override = _overlay(0)
	# The arc is world-space geometry; this node must not drag it around.
	_line.top_level = true
	add_child(_line)

	# The landing indicator: a thin ring plus a small centre dot, grouped
	# under one top-level `Node3D` so `update_arc()` only has to reposition
	# one transform for both pieces.
	_marker = Node3D.new()
	_marker.top_level = true
	add_child(_marker)

	_marker_ring = MeshInstance3D.new()
	var ring := TorusMesh.new()
	ring.inner_radius = MARKER_RING_RADIUS - MARKER_RING_TUBE
	ring.outer_radius = MARKER_RING_RADIUS + MARKER_RING_TUBE
	_marker_ring.mesh = ring
	_marker_ring.material_override = _overlay(0)
	_marker.add_child(_marker_ring)

	_marker_dot = MeshInstance3D.new()
	var dot := SphereMesh.new()
	dot.radius = MARKER_DOT_RADIUS
	dot.height = MARKER_DOT_RADIUS * 2.0
	_marker_dot.mesh = dot
	_marker_dot.material_override = _overlay(0)
	_marker.add_child(_marker_dot)

	# The vertical half of the landing indicator -- see MARKER_STALK_HEIGHT.
	_marker_stalk = MeshInstance3D.new()
	var stalk := CylinderMesh.new()
	stalk.top_radius = MARKER_STALK_RADIUS
	stalk.bottom_radius = MARKER_STALK_RADIUS
	stalk.height = MARKER_STALK_HEIGHT
	_marker_stalk.mesh = stalk
	_marker_stalk.position = Vector3(0.0, MARKER_STALK_HEIGHT * 0.5, 0.0)
	_marker_stalk.material_override = _overlay(0)
	_marker.add_child(_marker_stalk)

	_marker_bead = MeshInstance3D.new()
	var bead := SphereMesh.new()
	bead.radius = MARKER_BEAD_RADIUS
	bead.height = MARKER_BEAD_RADIUS * 2.0
	_marker_bead.mesh = bead
	_marker_bead.position = Vector3(0.0, MARKER_STALK_HEIGHT, 0.0)
	_marker_bead.material_override = _overlay(0)
	_marker.add_child(_marker_bead)

	visible = false


## The aim indicator draws OVER the world rather than inside it.
##
## `no_depth_test` was false, which is correct for world geometry and wrong for
## an aiming aid: the grass field measured 65% blade coverage in front of a
## creature at throwing range, and every one of those blades was drawing over
## the arc telling the player where their orb was going. The grass is frozen by
## owner directive and must not be thinned, so the aid goes in front of it
## instead. This is the same call every over-the-shoulder aim indicator makes,
## and it is scoped to this node -- nothing else in the fight becomes
## see-through.
##
## `priority` orders the casing under the ribbon; both are unshaded so the
## indicator reads the same in shadow as in sun, which matters here because the
## thing it is drawn over runs from luminance 0.24 to 0.46 within one frame.
func _overlay(priority: int) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.vertex_color_use_as_albedo = true
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.no_depth_test = true
	material.render_priority = priority
	return material


## Redraw for this frame's aim. `target` is what the throw is locked to, for
## the end-of-arc test and the marker colour.
func update_arc(origin: Vector3, direction: Vector3, speed: float, target: Node3D) -> void:
	visible = true
	var velocity := direction.normalized() * speed

	var target_centre := Vector3.INF
	var target_radius := 0.5
	if target != null and is_instance_valid(target) and target.has_method("centre"):
		target_centre = target.call("centre")
		if target.has_method("body_radius"):
			target_radius = float(target.call("body_radius"))

	var points: Array[Vector3] = []
	var end := origin
	var hit_target := false
	var step := _max_flight / float(SAMPLES)
	for i in SAMPLES + 1:
		var t := step * float(i)
		var p := origin + velocity * t + Vector3.DOWN * (0.5 * _gravity * t * t)
		points.append(p)
		end = p
		if target_centre != Vector3.INF and p.distance_to(target_centre) <= target_radius + _orb_radius:
			hit_target = true
			break
		var ground := _ground_height(p)
		if not is_nan(ground) and p.y <= ground + 0.02 and i > 0:
			end.y = ground + 0.02
			break

	# Published so the HUD's own on-target readout can agree with the picture.
	# The arc and the capture reticle were answering two different questions --
	# "does the predicted flight reach the body" here, "is the screen-centre ray
	# inside k x body_radius" there -- and a render caught them disagreeing on
	# screen: the cone visibly ended ON the creature under a caption reading
	# NOT ON TARGET. Whatever the assist gate needs internally, the thing the
	# player is told must match the thing the player is shown.
	trajectory_hits_target = hit_target
	# How close that flight passes the body's centre, on the same terms
	# `orb.gd` will score the real strike: the closest approach of the
	# trajectory, not the distance at whichever sample first entered the
	# forgiveness sphere. So the percentage the reticle shows before the throw
	# is the percentage the throw resolves at.
	trajectory_offset = INF
	if hit_target and target_centre != Vector3.INF and points.size() >= 2:
		var closest := INF
		for i in points.size() - 1:
			closest = minf(closest, ORB.closest_approach(points[i], points[i + 1], target_centre))
		trajectory_offset = closest
	var colour := ON_TARGET if hit_target else ON_GROUND

	# Dashes, not a continuous line (spec §10.3): each [i, i+1) sample
	# interval draws only its first `DASH_COVERAGE` fraction, leaving a gap,
	# and its own two vertex colours fade from near-full alpha at the
	# thrower's end toward `FADE_FAR_ALPHA` at the far end of the arc —
	# baked into the vertex colours themselves (material stays plain white)
	# so `PRIMITIVE_LINES`' per-segment vertices can each carry a different
	# alpha, which `PRIMITIVE_LINE_STRIP`'s single shared material colour
	# could not.
	_line_mesh.clear_surfaces()
	_casing_mesh.clear_surfaces()
	# At point-blank range the orb origin can already overlap the target's
	# generous hit radius, so the honest preview is a single point. ImmediateMesh
	# rejects a surface with no vertices; leave the line empty and let the
	# on-target reticle communicate the immediate hit instead.
	if points.size() >= 2:
		var camera := get_viewport().get_camera_3d()
		var eye := camera.global_position if camera != null else origin
		_build_ribbon(_casing_mesh, points, eye, CASING_EXTRA_HALF, CASING_COLOUR, true)
		_build_ribbon(_line_mesh, points, eye, 0.0, colour, false)

	_marker.visible = not hit_target
	_marker.global_position = end
	for piece: MeshInstance3D in [_marker_ring, _marker_dot, _marker_stalk, _marker_bead]:
		(piece.material_override as StandardMaterial3D).albedo_color = colour
	(_line.material_override as StandardMaterial3D).albedo_color = Color(1.0, 1.0, 1.0, 1.0)
	(_casing.material_override as StandardMaterial3D).albedo_color = Color(1.0, 1.0, 1.0, 1.0)


## The arc as a camera-facing RIBBON rather than a one-pixel line.
##
## Each dash becomes a quad whose width runs perpendicular to both the flight
## direction and the direction to the eye, so the ribbon keeps its apparent
## width from any angle instead of vanishing edge-on when the player aims along
## the camera axis -- which is the throw they make most often.
##
## `extra_half` widens it for the dark casing; `flat_colour` draws the casing at
## one colour instead of the ribbon's alpha ramp, because an outline that fades
## stops being an outline.
func _build_ribbon(mesh: ImmediateMesh, points: Array[Vector3], eye: Vector3,
		extra_half: float, colour: Color, flat_colour: bool) -> void:
	var total: int = points.size() - 1
	if total < 1:
		return
	# A near-eye or collinear trajectory can contain multiple points while
	# producing no ribbon triangles. Begin only once there is a visible dash.
	var begun := false
	for i in total:
		var a: Vector3 = points[i]
		var b: Vector3 = a.lerp(points[i + 1], DASH_COVERAGE)
		var along := b - a
		if along.length_squared() < 0.000001:
			continue
		var near_t := float(i) / float(total)
		var far_t := float(i + 1) / float(total)
		# Skipped near the eye -- see RIBBON_NEAR_SKIP.
		if a.distance_to(eye) < RIBBON_NEAR_SKIP:
			continue
		var half_a := _ribbon_half(a, eye, near_t) * (1.0 + extra_half)
		var half_b := _ribbon_half(b, eye, far_t) * (1.0 + extra_half)
		var side_a := along.cross(a - eye).normalized()
		var side_b := along.cross(b - eye).normalized()
		if side_a.length_squared() < 0.5 or side_b.length_squared() < 0.5:
			continue
		var near_colour := colour
		var far_colour := colour
		if not flat_colour:
			near_colour.a = colour.a * lerpf(FADE_NEAR_ALPHA, FADE_FAR_ALPHA, near_t)
			far_colour.a = colour.a * lerpf(FADE_NEAR_ALPHA, FADE_FAR_ALPHA, far_t)
		var a0 := a - side_a * half_a
		var a1 := a + side_a * half_a
		var b0 := b - side_b * half_b
		var b1 := b + side_b * half_b
		if not begun:
			mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
			begun = true
		for vertex: Array in [[a0, near_colour], [b0, far_colour], [b1, far_colour],
				[a0, near_colour], [b1, far_colour], [a1, near_colour]]:
			mesh.surface_set_color(vertex[1])
			mesh.surface_add_vertex(vertex[0])
	if begun:
		mesh.surface_end()


## Half-width at one point on the arc: a constant angle from the eye, flared
## toward the landing end, clamped so it can neither bloom up close nor thin
## back to a wire at range. See `RIBBON_ANGULAR_HALF`.
func _ribbon_half(point: Vector3, eye: Vector3, t: float) -> float:
	var distance := maxf(point.distance_to(eye), 0.01)
	var flare := lerpf(1.0, RIBBON_FAR_FLARE, clampf(t, 0.0, 1.0))
	return clampf(distance * RIBBON_ANGULAR_HALF * flare, RIBBON_HALF_MIN, RIBBON_HALF_MAX)


func hide_arc() -> void:
	visible = false
	trajectory_hits_target = false
	trajectory_offset = INF
	if _line_mesh != null:
		_line_mesh.clear_surfaces()
	if _casing_mesh != null:
		_casing_mesh.clear_surfaces()


## The world root offers ground_height_at; walk up until something answers.
func _ground_height(at: Vector3) -> float:
	var node: Node = get_parent()
	while node != null:
		# Stacked realms must terminate against the floor near the flying orb,
		# not an unrelated deck hundreds of metres above its trajectory.
		if node.has_method("ground_height_near"):
			return float(node.call("ground_height_near", at))
		if node.has_method("ground_height_at"):
			return float(node.call("ground_height_at", at.x, at.z))
		node = node.get_parent()
	return NAN
