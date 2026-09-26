extends MeshInstance3D

## Visible Tidewake currents (F13#5). The config promised
## "white_foam_and_driftwood_same_vector_as_physics" but nothing drew the
## currents, so a swimmer met an invisible push. This lays one thin foam
## ribbon on the sea along every authored current polyline, with streaks
## drifting along that current's single physics flow vector
## (water_current_field.gd uses the same vector). Brighter and faster for
## stronger currents; calmer once `water_currents_restored` is set. Given the
## live field, strengths are the ones physics uses (closed-gate and earned
## shortcut rows), and the mesh is rebuilt when a flag changes one. One mesh,
## one draw call, no particles. Tunables: water_veilfall.json::current_flow.
const SHADER := preload("res://shaders/water_current_flow.gdshader")
const RESTORED_FLAG := "water_currents_restored"
const POLL_SECONDS := 1.0

var ribbon_count := 0
var _flags: RefCounted
var _calm_scale := 0.5
var _poll := 0.0
var _restored := false
var _field: RefCounted
var _world_config: Dictionary = {}
var _config: Dictionary = {}
var _strengths: PackedFloat32Array = PackedFloat32Array()


## `field` is the world's live water_current_field.gd. Without one (tests,
## tools) the authored `strength_m_s` of every world current is drawn.
func build(world_config: Dictionary, config: Dictionary, flags: RefCounted, field: RefCounted = null) -> void:
	_flags = flags
	_field = field
	_world_config = world_config
	_config = config
	_calm_scale = float(config.get("restored_calm_scale", 0.5))
	_strengths = _current_strengths()
	_build_mesh()
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var material := ShaderMaterial.new()
	material.shader = SHADER
	# The sea is also transparent; draw the foam after it.
	material.render_priority = 2
	for key: String in config.get("shader", {}):
		if key.begins_with("_"):
			continue
		var value: Variant = config.shader[key]
		material.set_shader_parameter(key, Color(str(value)) if value is String else value)
	material_override = material
	_refresh(true)


func _currents() -> Array:
	return _field.call("live_currents") if _field != null else _world_config.get("currents", [])


func _current_strengths() -> PackedFloat32Array:
	var out := PackedFloat32Array()
	for current: Dictionary in _currents():
		out.append(float(_field.call("effective_strength", current)) if _field != null
			else float(current.get("strength_m_s", 0.0)))
	return out


func _build_mesh() -> void:
	var sea := float(_world_config.get("terrain", {}).get("sea_level_m", 0.0)) + float(_config.get("lift_m", 0.05))
	var width_scale := float(_config.get("width_scale", 0.7))
	var full_strength := maxf(0.01, float(_config.get("full_strength_m_s", 1.8)))
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	ribbon_count = 0
	var currents := _currents()
	for index in currents.size():
		var current: Dictionary = currents[index]
		var points: Array = current.get("polyline", [])
		var direction: Array = current.get("flow_direction_xz", [0.0, 0.0])
		var flow := Vector2(float(direction[0]), float(direction[1])).normalized()
		if points.size() < 2 or flow == Vector2.ZERO:
			continue
		var strength := clampf(_strengths[index] / full_strength, 0.0, 1.0)
		var colour := Color(flow.x * 0.5 + 0.5, flow.y * 0.5 + 0.5, strength, 1.0)
		_ribbon(surface, _densify(points, float(_config.get("segment_m", 12.0))),
			float(current.get("width_m", 18.0)) * width_scale * 0.5, sea, colour)
		ribbon_count += 1
	mesh = surface.commit()


func _process(delta: float) -> void:
	_poll -= delta
	if _poll <= 0.0:
		_poll = POLL_SECONDS
		_refresh(false)
		if _field != null:
			var strengths := _current_strengths()
			if strengths != _strengths:
				_strengths = strengths
				_build_mesh()


func _refresh(force: bool) -> void:
	var restored: bool = _flags != null and bool(_flags.has(RESTORED_FLAG))
	if restored == _restored and not force:
		return
	_restored = restored
	(material_override as ShaderMaterial).set_shader_parameter("calm_scale", _calm_scale if restored else 1.0)


func _densify(points: Array, segment: float) -> PackedVector2Array:
	var out := PackedVector2Array()
	for index in points.size():
		var b := Vector2(float(points[index][0]), float(points[index][2]))
		if index > 0:
			var a := out[out.size() - 1]
			var pieces := maxi(1, ceili(a.distance_to(b) / maxf(1.0, segment)))
			for piece in range(1, pieces):
				out.append(a.lerp(b, float(piece) / float(pieces)))
		out.append(b)
	return out


func _ribbon(surface: SurfaceTool, line: PackedVector2Array, half: float, y: float, colour: Color) -> void:
	var total := 0.0
	for index in range(1, line.size()):
		total += line[index].distance_to(line[index - 1])
	var travelled := 0.0
	var rows: Array = []
	for index in line.size():
		if index > 0:
			travelled += line[index].distance_to(line[index - 1])
		var tangent := (line[mini(index + 1, line.size() - 1)] - line[maxi(index - 1, 0)]).normalized()
		var side := Vector2(-tangent.y, tangent.x) * half
		var along := travelled / maxf(total, 0.001)
		rows.append([
			{"at": Vector3(line[index].x - side.x, y, line[index].y - side.y), "uv": Vector2(0.0, travelled), "uv2": Vector2(along, 0.0)},
			{"at": Vector3(line[index].x + side.x, y, line[index].y + side.y), "uv": Vector2(1.0, travelled), "uv2": Vector2(along, 0.0)},
		])
	for index in range(1, rows.size()):
		var a: Array = rows[index - 1]
		var b: Array = rows[index]
		for corner: Dictionary in [a[0], a[1], b[1], a[0], b[1], b[0]]:
			surface.set_color(colour)
			surface.set_normal(Vector3.UP)
			surface.set_uv(corner.uv)
			surface.set_uv2(corner.uv2)
			surface.add_vertex(corner.at)
