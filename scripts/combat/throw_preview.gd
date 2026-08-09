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

var _line: MeshInstance3D = null
var _line_mesh: ImmediateMesh = null
var _marker: MeshInstance3D = null

var _gravity: float = 14.0
var _max_flight: float = 4.0

## Colour states: aimed at the creature vs landing on dirt.
const ON_TARGET := Color(0.55, 1.0, 0.55, 0.85)
const ON_GROUND := Color(1.0, 1.0, 1.0, 0.55)


func _ready() -> void:
	var cfg_file := FileAccess.open("res://data/config/catching.json", FileAccess.READ)
	if cfg_file != null:
		var parsed: Variant = JSON.parse_string(cfg_file.get_as_text())
		if parsed is Dictionary:
			var throw: Dictionary = (parsed as Dictionary).get("throw", {})
			_gravity = float(throw.get("gravity", _gravity))
			_max_flight = float(throw.get("max_flight_time", _max_flight))

	_line_mesh = ImmediateMesh.new()
	_line = MeshInstance3D.new()
	_line.mesh = _line_mesh
	_line.material_override = _unshaded()
	# The arc is world-space geometry; this node must not drag it around.
	_line.top_level = true
	add_child(_line)

	_marker = MeshInstance3D.new()
	var disc := CylinderMesh.new()
	disc.top_radius = 0.35
	disc.bottom_radius = 0.35
	disc.height = 0.04
	_marker.mesh = disc
	_marker.material_override = _unshaded()
	_marker.top_level = true
	add_child(_marker)
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
	_line_mesh.clear_surfaces()
	_line_mesh.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)
	for p in points:
		_line_mesh.surface_set_color(colour)
		_line_mesh.surface_add_vertex(p)
	_line_mesh.surface_end()

	_marker.visible = not hit_target
	_marker.global_position = end
	(_marker.material_override as StandardMaterial3D).albedo_color = colour
	(_line.material_override as StandardMaterial3D).albedo_color = colour


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
