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
## (`_aim_direction`), and integrates the same closed-form parabola `orb.gd`
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
const DASH_COVERAGE := 0.6
const FADE_NEAR_ALPHA := 1.0
const FADE_FAR_ALPHA := 0.25

## The landing indicator: a small ring plus a centre dot, restyled from the
## old flat disc — a disc reads as a coin sitting in the grass, a ring+dot
## reads as an impact point.
const MARKER_RING_RADIUS := 0.34
const MARKER_RING_TUBE := 0.035
const MARKER_DOT_RADIUS := 0.08

var _line: MeshInstance3D = null
var _line_mesh: ImmediateMesh = null
var _marker: Node3D = null
var _marker_ring: MeshInstance3D = null
var _marker_dot: MeshInstance3D = null

var _gravity: float = 14.0
var _max_flight: float = 4.0

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

	ON_TARGET = Color(UITokens.TEAL_SOFT, 0.9)
	ON_GROUND = Color(UITokens.TEXT_SECONDARY, 0.55)

	_line_mesh = ImmediateMesh.new()
	_line = MeshInstance3D.new()
	_line.mesh = _line_mesh
	_line.material_override = _unshaded()
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
	_marker_ring.material_override = _unshaded()
	_marker.add_child(_marker_ring)

	_marker_dot = MeshInstance3D.new()
	var dot := SphereMesh.new()
	dot.radius = MARKER_DOT_RADIUS
	dot.height = MARKER_DOT_RADIUS * 2.0
	_marker_dot.mesh = dot
	_marker_dot.material_override = _unshaded()
	_marker.add_child(_marker_dot)

	visible = false


func _unshaded() -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.vertex_color_use_as_albedo = true
	material.no_depth_test = false
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
		if target_centre != Vector3.INF and p.distance_to(target_centre) <= target_radius + 0.42:
			hit_target = true
			break
		var ground := _ground_height(p)
		if not is_nan(ground) and p.y <= ground + 0.02 and i > 0:
			end.y = ground + 0.02
			break

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
	var total: int = maxi(points.size() - 1, 1)
	_line_mesh.surface_begin(Mesh.PRIMITIVE_LINES)
	for i in points.size() - 1:
		var dash_end: Vector3 = points[i].lerp(points[i + 1], DASH_COVERAGE)
		var near_alpha: float = lerp(FADE_NEAR_ALPHA, FADE_FAR_ALPHA, float(i) / float(total))
		var far_alpha: float = lerp(FADE_NEAR_ALPHA, FADE_FAR_ALPHA, float(i + 1) / float(total))
		var near_colour := colour
		near_colour.a = colour.a * near_alpha
		var far_colour := colour
		far_colour.a = colour.a * far_alpha
		_line_mesh.surface_set_color(near_colour)
		_line_mesh.surface_add_vertex(points[i])
		_line_mesh.surface_set_color(far_colour)
		_line_mesh.surface_add_vertex(dash_end)
	_line_mesh.surface_end()

	_marker.visible = not hit_target
	_marker.global_position = end
	(_marker_ring.material_override as StandardMaterial3D).albedo_color = colour
	(_marker_dot.material_override as StandardMaterial3D).albedo_color = colour
	(_line.material_override as StandardMaterial3D).albedo_color = Color(1.0, 1.0, 1.0, 1.0)


func hide_arc() -> void:
	visible = false
	if _line_mesh != null:
		_line_mesh.clear_surfaces()


## The world root offers ground_height_at; walk up until something answers.
func _ground_height(at: Vector3) -> float:
	var node: Node = get_parent()
	while node != null:
		if node.has_method("ground_height_at"):
			return float(node.call("ground_height_at", at.x, at.z))
		node = node.get_parent()
	return NAN
