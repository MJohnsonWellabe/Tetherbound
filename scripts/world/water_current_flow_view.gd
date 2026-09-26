extends MeshInstance3D

## Visible Tidewake currents (F13#5). The config promised
## "white_foam_and_driftwood_same_vector_as_physics" but nothing drew the
## currents, so a swimmer met an invisible push. This lays raised wave patches
## on the sea along every authored current polyline, with crests
## drifting along that current's effective physics flow vector. Dock closures,
## exact-route return reductions and liberation use the same state as the
## field; tide-race rings remain owned by water_gate_seal_view.gd. One mesh,
## one draw call, no particles. Tunables: water_veilfall.json::current_flow.
const SHADER := preload("res://shaders/water_current_flow.gdshader")
const FIELD := preload("res://scripts/world/water_current_field.gd")
const TRAVERSAL_PATH := "res://data/config/water_swimming.json"
const RESTORED_FLAG := "water_currents_restored"

var ribbon_count := 0
var _flags: RefCounted
var _game: Node
var _world_config: Dictionary
var _config: Dictionary
var _currents: Array
var _velocities: Array[Vector3] = []
var _full_strength := 6.0
var _calm_scale := 0.5
var _poll := 0.0
var _poll_seconds := 0.2
var _restored := false


func build(world_config: Dictionary, config: Dictionary, flags: RefCounted) -> void:
	add_to_group("progression_restore")
	_flags = flags
	_game = get_node_or_null("/root/Game") if is_inside_tree() else null
	_world_config = world_config.duplicate(true)
	_config = config.duplicate(true)
	var traversal: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(TRAVERSAL_PATH))
	_currents = configured_currents(world_config, traversal)
	_full_strength = maxf(0.01, float(config.get("full_strength_m_s", 6.0)))
	# Never clip an authored/closed velocity when encoding it into COLOR.b.
	for current: Dictionary in _currents:
		for key: String in ["strength_m_s", "closed_strength_m_s", "strength_after_unlock_m_s"]:
			_full_strength = maxf(_full_strength, float(current.get(key, 0.0)))
	_calm_scale = clampf(float(config.get("restored_calm_scale", 0.5)), 0.01, 1.0)
	_poll_seconds = maxf(0.05, float(config.get("poll_seconds", 0.2)))
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	extra_cull_margin = 1.0
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
	# With COLOR.b = metres-per-second / _full_strength, the shader's motion
	# must use that same scale, without a minimum speed overriding calm water.
	material.set_shader_parameter("min_speed_m_s", 0.0)
	_refresh(true)


func _process(delta: float) -> void:
	_poll -= delta
	if _poll <= 0.0:
		_poll = _poll_seconds
		_refresh(false)


func _refresh(force: bool) -> void:
	# A load/rejoin can replace the entire world flag store, not just revision.
	if is_instance_valid(_game):
		var world: Variant = _game.get("world")
		if world != null:
			_flags = world.get("flags") as RefCounted
	var active := _flag_snapshot()
	var restored := bool(active.get(RESTORED_FLAG, false))
	var next: Array[Vector3] = []
	for current: Dictionary in _currents:
		next.append(effective_flow(current, active))
	if next == _velocities and restored == _restored and not force:
		return
	_velocities = next
	_restored = restored
	_rebuild_ribbons()
	var material := material_override as ShaderMaterial
	var calm := _calm_scale if restored else 1.0
	# calm_scale still softens foam opacity after liberation. Compensate its
	# speed factor: each route's physics multiplier is already in its colour.
	material.set_shader_parameter("calm_scale", calm)
	material.set_shader_parameter("speed_scale", _full_strength / calm)


func restore_progression_from_game(game: Node) -> void:
	_game = game
	_refresh(false)


## Production binding is shared with the physics field; the source config is
## copied, including exact-route reductions, without changing optional routes.
static func configured_currents(world_config: Dictionary, traversal: Dictionary) -> Array:
	return FIELD.bind_return_shortcuts(FIELD.with_closed_gates(world_config, traversal)).get("currents", [])


## Pure visual adapter for a bound current row and a snapshot of world facts.
## This is the field's full-influence route velocity, before spatial edge
## blending/priority (and separate tide-race rings), not a new gameplay rule.
static func effective_flow(current: Dictionary, active_flags: Dictionary) -> Vector3:
	var direction: Array = current.get("flow_direction_xz", [0.0, 0.0])
	var velocity := Vector3(float(direction[0]), 0.0, float(direction[1])).normalized()
	var required := str(current.get("required_unlock_flag", ""))
	var closed := not required.is_empty() and not bool(active_flags.get(required, false))
	var strength := float(current.get("strength_m_s", 0.0))
	if closed:
		strength = float(current.get("closed_strength_m_s", strength))
	var reduction := str(current.get("reduction_unlock_flag", ""))
	if not reduction.is_empty() and bool(active_flags.get(reduction, false)):
		strength = float(current.get("strength_after_unlock_m_s", strength))
	velocity *= maxf(0.0, strength)
	if bool(active_flags.get(RESTORED_FLAG, false)):
		velocity *= clampf(float(current.get("post_liberation_strength_multiplier", 1.0)), 0.0, 1.0)
	return velocity


func _flag_snapshot() -> Dictionary:
	var active := {RESTORED_FLAG: _flags != null and bool(_flags.has(RESTORED_FLAG))}
	for current: Dictionary in _currents:
		var required := str(current.get("required_unlock_flag", ""))
		if not required.is_empty():
			# Like the field, a flag-less analytical fixture uses authored flow.
			active[required] = _flags == null or bool(_flags.has(required))
		var reduction := str(current.get("reduction_unlock_flag", ""))
		if not reduction.is_empty():
			active[reduction] = _flags != null and bool(_flags.has(reduction))
	return active


func _rebuild_ribbons() -> void:
	var sea := float(_world_config.get("terrain", {}).get("sea_level_m", 0.0)) + float(_config.get("lift_m", 0.05))
	var width_scale := float(_config.get("width_scale", 0.7))
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var vertex_offset := 0
	var across_segments := maxi(1, int(_config.get("across_segments", 8)))
	ribbon_count = 0
	for index in _currents.size():
		var current: Dictionary = _currents[index]
		var points: Array = current.get("polyline", [])
		var velocity := _velocities[index]
		if points.size() < 2 or velocity == Vector3.ZERO:
			continue
		var flow := Vector2(velocity.x, velocity.z).normalized()
		var strength := clampf(velocity.length() / _full_strength, 0.0, 1.0)
		var colour := Color(flow.x * 0.5 + 0.5, flow.y * 0.5 + 0.5, strength, 1.0)
		var half := float(current.get("width_m", 18.0)) * width_scale * 0.5
		var rows := _joined_rows(points, half, float(_config.get("segment_m", 12.0)))
		var added := _ribbon(surface, rows, sea, colour, across_segments, vertex_offset)
		vertex_offset += added
		if added > 0:
			ribbon_count += 1
	mesh = surface.commit() if ribbon_count > 0 else null


func _joined_rows(points: Array, half: float, segment: float) -> Array[Dictionary]:
	var corners := PackedVector2Array()
	for raw: Array in points:
		var point := Vector2(float(raw[0]), float(raw[2]))
		if corners.is_empty() or not point.is_equal_approx(corners[corners.size() - 1]):
			corners.append(point)
	var rows: Array[Dictionary] = []
	if corners.size() < 2:
		return rows
	# Intersect the two authored offset edges at each corner before subdivision.
	# Recomputing tangents from dense one-metre neighbours turns a wide inside
	# edge back on itself. An authored miter keeps each straight edge at exactly
	# `half` from its route segment, independent of tessellation density.
	var sides := PackedVector2Array()
	for index in corners.size():
		var incoming := (corners[index] - corners[index - 1]).normalized() if index > 0 \
			else (corners[1] - corners[0]).normalized()
		var outgoing := (corners[index + 1] - corners[index]).normalized() if index + 1 < corners.size() \
			else incoming
		var incoming_side := Vector2(-incoming.y, incoming.x)
		var outgoing_side := Vector2(-outgoing.y, outgoing.x)
		var bisector := (incoming_side + outgoing_side).normalized()
		sides.append(bisector * half / maxf(0.001, bisector.dot(outgoing_side)))
	rows.append({"at": corners[0], "side": sides[0], "travelled": 0.0})
	var travelled := 0.0
	for index in range(1, corners.size()):
		var length := corners[index - 1].distance_to(corners[index])
		var pieces := maxi(1, ceili(length / maxf(1.0, segment)))
		for piece in range(1, pieces + 1):
			var fraction := float(piece) / float(pieces)
			rows.append({"at": corners[index - 1].lerp(corners[index], fraction),
				"side": sides[index - 1].lerp(sides[index], fraction),
				"travelled": travelled + length * fraction})
		travelled += length
	return rows


func _ribbon(surface: SurfaceTool, rows: Array[Dictionary], y: float,
		colour: Color, across_segments: int, first_vertex: int) -> int:
	if rows.size() < 2:
		return 0
	var total := float(rows[rows.size() - 1].travelled)
	var row_width := across_segments + 1
	for row: Dictionary in rows:
		var centre: Vector2 = row.at
		var side: Vector2 = row.side
		var travelled := float(row.travelled)
		var along := travelled / maxf(total, 0.001)
		# Interior vertices provide wave displacement across the strip while
		# retaining the joined boundary edges and authored centre trajectory.
		for column in row_width:
			var across := float(column) / float(across_segments)
			var point := centre + side * (across * 2.0 - 1.0)
			surface.set_color(colour)
			surface.set_normal(Vector3.UP)
			surface.set_uv(Vector2(across, travelled))
			surface.set_uv2(Vector2(along, 0.0))
			surface.add_vertex(Vector3(point.x, y, point.y))
	for row in range(1, rows.size()):
		var a := first_vertex + (row - 1) * row_width
		var b := first_vertex + row * row_width
		for column in across_segments:
			for vertex: int in [a + column, a + column + 1, b + column + 1,
					a + column, b + column + 1, b + column]:
				surface.add_index(vertex)
	return rows.size() * row_width
