extends "res://scripts/vfx/astra_gate_effect_r3.gd"

## Reuse the guarded arrival/cancellation lifecycle, replace all aura drawing.
const POSED := preload("res://scripts/vfx/astra_whole_bounds_r4.gd")
const SOFT := preload("res://scripts/vfx/astra_soft_mote_r4.gdshader")
var _posed := POSED.new()
var _anchors := PackedVector3Array()

func bind_source(source: Node3D) -> bool:
	if source == null or not source.has_method("model_pivot"): return false
	var pivot := source.call("model_pivot") as Node3D
	if pivot == null: return false
	_pivot = weakref(pivot)
	return _posed.bind(pivot)

func _measure_whole_body() -> bool:
	_whole_bounds = _posed.measure()
	_bounds_valid = _whole_bounds.size.x > 0.0 and _whole_bounds.size.y > 0.0 and _whole_bounds.size.z > 0.0
	return _bounds_valid

func _ready() -> void:
	add_to_group("move_effect_presentation")
	top_level = true
	global_transform = Transform3D.IDENTITY
	var limit := maxi(0, int(_config.get("ordinary_particle_limit", 48)))
	var impact := mini(limit, int(_row.budget.impact))
	_lease = BUDGET.reserve(encounter_id(), impact, mini(int(_row.budget.trail), limit - impact), int(_config.get("encounter_particle_cap", 384)))
	var allocation := BUDGET.allocation(_lease)
	var sphere := SphereMesh.new()
	sphere.radius = 1.0
	sphere.height = 2.0
	sphere.radial_segments = 16
	sphere.rings = 8
	var material := ShaderMaterial.new()
	material.shader = SOFT
	material.set_shader_parameter("mote_colour", _colour)
	material.set_shader_parameter("opacity", float(tuning.aura_opacity) * _peer_opacity)
	_cloud = _particle_node(sphere, material, 0)
	_cloud.multimesh.use_custom_data = true
	_cloud.multimesh.instance_count = int(allocation.impact) + int(allocation.trail)
	_update_bodies(0.0)
	if _cancelled: return
	_play_launch()
	if _travel <= 0.0: call_deferred("_finish_presentation")
	elif _context.has("travel_seconds"):
		_presentation_clock = get_tree().create_timer(_travel, false)
		_presentation_clock.timeout.connect(_finish_presentation, CONNECT_ONE_SHOT)

func _update_bodies(_t: float) -> void:
	if _cancelled or _contact_retired: return
	if not _measure_whole_body():
		cancel_presentation()
		return
	if _cloud == null: return
	var points := _posed.anchors()
	if points.is_empty():
		cancel_presentation()
		return
	var pivot := _pivot.get_ref() as Node3D
	var count := _cloud.multimesh.instance_count
	# Choose actual surface samples nearest stratified whole-body positions.
	# Y strata include feet; Z strata include the tail. No ring or outline.
	_anchors.clear()
	var scale := pivot.global_basis.get_scale().abs()
	if scale[scale.min_axis_index()] <= 0.0:
		cancel_presentation()
		return
	var radius := minf(float(tuning.aura_radius_m), (_whole_bounds.size * scale)[(_whole_bounds.size * scale).min_axis_index()] * 0.2)
	var padding := Vector3.ONE * radius / scale
	for i in count:
		var wanted := _whole_bounds.position + _whole_bounds.size * Vector3(
			0.18 if i % 2 == 0 else 0.82, (float(i) + 0.5) / float(count), fposmod(float(i) * 0.618034, 1.0))
		var nearest := points[0]
		var distance := INF
		for point: Vector3 in points:
			var d := point.distance_squared_to(wanted)
			if d < distance:
				distance = d
				nearest = point
		var drift := Vector3(sin(_elapsed * 2.0 + i), sin(_elapsed * 2.5 + i * 1.7), cos(_elapsed * 2.0 + i)) * padding * 0.2
		var point := (nearest + drift).clamp(_whole_bounds.position + padding, _whole_bounds.end - padding)
		_anchors.append(point)
		_cloud.multimesh.set_instance_transform(i, Transform3D(Basis.IDENTITY.scaled(Vector3.ONE * radius), pivot.to_global(point)))
		_cloud.multimesh.set_instance_custom_data(i, Color(0.65 + 0.35 * sin(_elapsed * 2.0 + i) * sin(_elapsed * 2.0 + i), 0, 0, 0))
	_set_opacity(_cloud.material_override, float(tuning.aura_opacity) * _fade())

func diagnostic_receipt() -> Dictionary:
	_measure_whole_body()
	var receipt := _posed.receipt()
	receipt["candidate"] = "astra_final_aura"
	receipt["cancelled"] = _cancelled
	receipt["arrival_emitted"] = _arrival_emitted
	receipt["presentation_arrival_emitted"] = _presentation_arrival_emitted
	receipt["lease"] = BUDGET.allocation(_lease)
	receipt["particle_count"] = _cloud.multimesh.instance_count if is_instance_valid(_cloud) and _cloud.visible else 0
	receipt["held_opacity"] = _fade()
	receipt["anchors_inside_posed_bounds"] = _bounds_valid
	for point: Vector3 in _anchors:
		if not _whole_bounds.has_point(point): receipt["anchors_inside_posed_bounds"] = false
	return receipt
