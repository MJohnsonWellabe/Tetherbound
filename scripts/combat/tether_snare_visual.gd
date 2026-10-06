extends Node3D

## A read-only line and loop on the existing opponent body. No collision,
## status, catch, damage or save consumer is attached to these meshes.
const COMMANDS := preload("res://scripts/combat/tether_commands.gd")
var _sequence := -1
var _scope: Array = []
var _remaining_s := 0.0
var _trainer: Node3D
var _loop: MeshInstance3D
var _line: MeshInstance3D
var _line_mesh: CylinderMesh
var _settings: Dictionary = {}

func apply_view(view: Dictionary, sequence: int, target_uid: String, generation: int,
		trainer: Node3D, radius: float) -> bool:
	if sequence < 0 or target_uid.is_empty() or generation < 1: return false
	if _scope != [target_uid, generation]:
		clear_presentation()
		_sequence = -1
		_scope = [target_uid, generation]
	if sequence <= _sequence: return false
	_sequence = sequence
	if view.is_empty():
		clear_presentation()
		return true
	if view.get("target_uid") != target_uid or view.get("target_generation") != generation \
		or not COMMANDS._number(view.get("remaining_s"), 0.001, float(COMMANDS.config().commands.snare.duration_s)) \
		or not is_finite(radius) or radius <= 0.0:
		clear_presentation()
		return false
	_remaining_s = float(view.remaining_s)
	_trainer = trainer
	_settings = COMMANDS.config().get("snare_visual", {})
	if _loop == null: _build_meshes(radius)
	visible = true
	set_process(true)
	_draw_line()
	return true

func clear_presentation() -> void:
	_remaining_s = 0.0
	_trainer = null
	visible = false
	set_process(false)

func _build_meshes(radius: float) -> void:
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = Color(str(_settings.get("colour", "#e8cf87")))
	var width := clampf(float(_settings.get("loop_width_m", 0.06)), 0.01, 0.2)
	var loop_mesh := TorusMesh.new()
	loop_mesh.inner_radius = radius
	loop_mesh.outer_radius = radius + width
	loop_mesh.rings = clampi(int(_settings.get("loop_segments", 32)), 12, 64)
	loop_mesh.ring_segments = 6
	_loop = MeshInstance3D.new()
	_loop.mesh = loop_mesh
	_loop.material_override = material
	_loop.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_loop.position.y = radius * float(_settings.get("target_height_fraction", 0.4))
	add_child(_loop)
	_line_mesh = CylinderMesh.new()
	_line_mesh.top_radius = clampf(float(_settings.get("line_radius_m", 0.035)), 0.01, 0.1)
	_line_mesh.bottom_radius = _line_mesh.top_radius
	_line_mesh.radial_segments = 6
	_line_mesh.rings = 1
	_line = MeshInstance3D.new()
	_line.mesh = _line_mesh
	_line.material_override = material
	_line.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_line)

func _process(delta: float) -> void:
	_remaining_s = maxf(0.0, _remaining_s - delta)
	if _remaining_s <= 0.0 or not COMMANDS.enabled() or not COMMANDS.enabled("ui_enabled"):
		clear_presentation()
		return
	_draw_line()

func _draw_line() -> void:
	if _line == null: return
	_line.visible = is_instance_valid(_trainer) and _trainer.is_inside_tree() and is_inside_tree()
	if not _line.visible: return
	var start := to_local(_trainer.global_position + Vector3.UP * float(_settings.get("trainer_anchor_height_m", 1.2)))
	var finish := _loop.position
	var offset := finish - start
	if not offset.is_finite() or offset.length_squared() < 0.0001:
		_line.visible = false
		return
	_line_mesh.height = offset.length()
	_line.position = (start + finish) * 0.5
	_line.quaternion = Quaternion(Vector3.UP, offset.normalized())
