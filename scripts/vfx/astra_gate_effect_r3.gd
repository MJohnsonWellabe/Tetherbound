extends "res://scripts/vfx/move_effect.gd"

## Third approach: the passed water-jet drawing path for tether; bounded,
## additive particles over whole caster bounds for aura. No r1/r2 mutations.
const BODY_BOUNDS := preload("res://scripts/characters/render_bounds.gd")
const ROUND := preload("res://scripts/vfx/astra_effect_geometry.gd")
const EDGE := preload("res://scripts/vfx/astra_particle_edge_r3.gdshader")
var tuning: Dictionary = {}
var _kind := ""
var _pivot: WeakRef
var _whole_bounds := AABB()
var _bounds_valid := false
var _beam_core: MeshInstance3D
var _cloud: MultiMeshInstance3D
var _outline: MultiMeshInstance3D
var _cancelled := false
var _arrival_emitted := false
var _presentation_arrival_emitted := false

func bind_source(source: Node3D) -> bool:
	if source == null or not source.has_method("model_pivot"): return false
	var pivot := source.call("model_pivot") as Node3D
	if pivot == null: return false
	_pivot = weakref(pivot)
	return _measure_whole_body()

func _measure_whole_body() -> bool:
	_whole_bounds = AABB()
	_bounds_valid = false
	var pivot := _pivot.get_ref() as Node3D if _pivot != null else null
	if not is_instance_valid(pivot) or pivot.is_queued_for_deletion() or not pivot.is_inside_tree(): return false
	_whole_bounds = BODY_BOUNDS.measure(pivot)
	_bounds_valid = _whole_bounds.position.is_finite() and _whole_bounds.size.is_finite() \
		and _whole_bounds.size.x > 0.0 and _whole_bounds.size.y > 0.0 and _whole_bounds.size.z > 0.0
	if not _bounds_valid: _whole_bounds = AABB()
	return _bounds_valid

func configure(from: Vector3, to: Vector3, row: Dictionary, context: Dictionary,
		travel: float, config: Dictionary) -> void:
	_kind = str(row.archetype)
	var drawing := row.duplicate(true)
	if _kind == "catch_tether_beam":
		var document: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/vfx.json"))
		var donor: Dictionary = document.move_library.archetypes.water_jet
		for key: String in ["body", "trail", "impact"]: drawing[key] = donor[key].duplicate(true)
		# Reuse water geometry/materials without importing its action, mastery,
		# sound, particle budget, timing or long ground aftermath.
		drawing.impact.duration = row.impact.duration
		drawing.impact.stages = {"flash": tuning.contact_flash.duplicate(true)}
		drawing.impact.foam_colour = str(tuning.contact_colour)
		drawing.impact.mote_colour = str(tuning.contact_colour)
		drawing.impact.puff_colour = str(tuning.contact_colour)
		drawing.body.foam_colour = str(tuning.beam_foam_colour)
		drawing.body.layers = [] # The bright core is the soft ion layer below.
		drawing.trail.colour = str(tuning.beam_colour)
		drawing["launch"] = {}
	super.configure(from, to, drawing, context, travel, config)
	_colour = Color(str(tuning.get("beam_colour" if _kind == "catch_tether_beam" else "aura_colour", "7542ff")))

func _ready() -> void:
	if _kind == "catch_tether_beam":
		super._ready() # Actual passed water_stream + flowing-water + splash code.
		if _cancelled: return
		_beam_core = _mesh_node(ImmediateMesh.new(), _colour)
		_beam_core.material_override = _presentation_material(GEOMETRY.authored_material("ion_filament", tuning.beam_core, _colour))
		_cloud = _particle_node(GEOMETRY.shape("soft_foam", float(_params.size) * float(tuning.snout_mist_size_scale)),
			_presentation_material(GEOMETRY.authored_material("soft_foam", tuning.snout_mist, Color(str(tuning.beam_foam_colour)))),
			int(BUDGET.allocation(_lease).get("trail", 0)))
		_update_bodies(1.0 if _travel <= 0.0 else 0.0)
		_update_trail()
		return
	add_to_group("move_effect_presentation")
	top_level = true
	global_transform = Transform3D.IDENTITY
	var limit := maxi(0, int(_config.get("ordinary_particle_limit", 48)))
	var impact := mini(limit, int(_row.budget.impact))
	_lease = BUDGET.reserve(encounter_id(), impact, mini(int(_row.budget.trail), limit - impact), int(_config.get("encounter_particle_cap", 384)))
	var allocation := BUDGET.allocation(_lease)
	var count := int(allocation.impact) + int(allocation.trail)
	var radius := float(_params.size) * float(tuning.aura_particle_radius_scale)
	var glow := GEOMETRY.material(_colour, 0.95) as StandardMaterial3D
	glow.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	glow.emission_enabled = true
	glow.emission = _colour
	glow.emission_energy_multiplier = float(tuning.aura_emission)
	_cloud = _particle_node(ROUND.sphere(radius), _presentation_material(glow), count)
	var edge := ShaderMaterial.new()
	edge.shader = EDGE
	edge.set_shader_parameter("edge_colour", Color(str(tuning.aura_edge_colour)))
	edge.set_shader_parameter("opacity", float(tuning.aura_edge_opacity))
	_outline = _particle_node(ROUND.sphere(radius * 1.25), _presentation_material(edge), count)
	_update_bodies(0.0)
	if _cancelled: return
	_play_launch()
	if _travel <= 0.0:
		_build_impact()
		call_deferred("_finish_presentation")
	elif _context.has("travel_seconds"):
		_presentation_clock = get_tree().create_timer(_travel, false)
		_presentation_clock.timeout.connect(_finish_presentation, CONNECT_ONE_SHOT)

func _particle_node(mesh: Mesh, material: Material, count: int) -> MultiMeshInstance3D:
	var node := MultiMeshInstance3D.new()
	var multi := MultiMesh.new()
	multi.transform_format = MultiMesh.TRANSFORM_3D
	multi.mesh = mesh
	multi.instance_count = count
	node.multimesh = multi
	node.material_override = material
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	node.set_meta(&"detail_cull_skip", true)
	add_child(node)
	return node

func _fade() -> float:
	if not _arrived: return 1.0
	var u := clampf((_elapsed - _travel) / maxf(_lifetime_after_contact(), 0.001), 0.0, 1.0)
	return 1.0 - smoothstep(float(tuning.fade_start_fraction), 1.0, u)

func _process(delta: float) -> void:
	super._process(delta)
	if _cancelled or _contact_retired or is_queued_for_deletion(): return
	if _kind == "buff_aura": _update_bodies(1.0)
	else:
		for body: MeshInstance3D in _bodies:
			body.visible = true
			_set_opacity(body.material_override, float(_row.body.opacity) * _fade())
		_set_opacity(_beam_core.material_override, _fade())
		_set_opacity(_cloud.material_override, float(tuning.snout_mist.opacity) * _fade())

func _update_bodies(t: float) -> void:
	if _cancelled or _contact_retired: return
	if _kind == "catch_tether_beam":
		super._update_bodies(t)
		for body: MeshInstance3D in _bodies:
			body.scale.x = float(tuning.beam_width_scale)
			body.scale.z = float(tuning.beam_width_scale)
		if _beam_core == null: return
		var end := _impact_visual_origin({"visual_anchor": "contact_surface"})
		var points: Array[Vector3] = [_from, _from.lerp(end, t)]
		var camera := get_viewport().get_camera_3d()
		var eye := camera.global_position if camera != null else _from + Vector3(0, 5, 14)
		_beam_core.mesh = GEOMETRY.flowing_ribbon(points, float(_params.size) * float(tuning.beam_core_width_scale), eye)
		return
	if not _measure_whole_body():
		cancel_presentation(); return
	if _cloud == null: return
	var pivot := _pivot.get_ref() as Node3D
	var allocation := BUDGET.allocation(_lease)
	var count := mini(_cloud.multimesh.instance_count, int(allocation.impact) + int(allocation.trail))
	_cloud.multimesh.visible_instance_count = count
	_outline.multimesh.visible_instance_count = count
	var centre := _whole_bounds.get_center()
	var half := _whole_bounds.size * 0.5 * float(tuning.aura_padding)
	for i in count:
		var phase := fposmod(float(i) * 0.618034 + _elapsed * float(tuning.aura_rise_speed), 1.0)
		var point := Vector3(sin(float(i) * 2.39996), phase * 2.0 - 1.0, cos(float(i) * 1.73205))
		# Alternate both side faces and interior volume, spanning feet through
		# head and tail, instead of another ring around a named torso bone.
		if i % 3 == 0: point.x = -1.0 if i % 2 == 0 else 1.0
		elif i % 3 == 1: point.z = -1.0 if i % 2 == 0 else 1.0
		var position := pivot.to_global(centre + point * half)
		var ground: Vector3 = _context.get("source_ground", _from)
		position.y = maxf(position.y, ground.y + float(_params.size) * float(tuning.aura_particle_radius_scale))
		var scale := (0.8 + 0.2 * sin(float(i) * 1.7 + _elapsed * 3.0)) * (float(tuning.aura_contact_scale) if _arrived else 1.0)
		var pose := Transform3D(Basis.IDENTITY.scaled(Vector3.ONE * scale), position)
		_cloud.multimesh.set_instance_transform(i, pose)
		_outline.multimesh.set_instance_transform(i, pose)
	_set_opacity(_cloud.material_override, 0.95 * _fade())
	_set_opacity(_outline.material_override, float(tuning.aura_edge_opacity) * _fade())

func _update_trail() -> void:
	if _kind != "catch_tether_beam": return
	# The same admitted trail slots become snout mist; inherited ribbons stay
	# hidden so there is no double spend or surviving hairline after contact.
	for trail: MeshInstance3D in _trails: trail.visible = false
	if _cloud == null or _cancelled or _contact_retired: return
	var count := mini(_cloud.multimesh.instance_count, int(BUDGET.allocation(_lease).get("trail", 0)))
	_cloud.multimesh.visible_instance_count = count
	var direction := (_to - _from).normalized()
	var side := direction.cross(Vector3.UP).normalized()
	for i in count:
		var f := fposmod(float(i) * 0.618034 + _elapsed * 1.8, 1.0)
		var angle := float(i) * 2.39996
		var point := _from + direction * float(_params.size) * (0.5 + f * 3.0) \
			+ (side * cos(angle) + Vector3.UP * sin(angle)) * float(_params.size) * (0.5 + f)
		_cloud.multimesh.set_instance_transform(i, Transform3D(Basis.IDENTITY.scaled(Vector3.ONE * (0.7 + f * 0.6)), point))

func _build_impact() -> void:
	if _cancelled or _contact_retired or is_queued_for_deletion(): return
	if _kind == "catch_tether_beam": super._build_impact()
	else:
		# The same admitted cloud brightens at contact and remains through the
		# impact shutter; no target burst is substituted for a self buff.
		_update_bodies(1.0)

func _update_impact(u: float, delta: float) -> void:
	if _cancelled or _contact_retired: return
	if _kind == "catch_tether_beam": super._update_impact(u, delta)

func _retire_contact_drawing() -> void:
	super._retire_contact_drawing()
	if is_instance_valid(_beam_core): _beam_core.visible = false
	if is_instance_valid(_cloud): _cloud.visible = false
	if is_instance_valid(_outline): _outline.visible = false

func _finish_presentation() -> void:
	if _cancelled or _arrived or is_queued_for_deletion(): return
	_elapsed = _travel
	_update_bodies(1.0)
	if _cancelled or is_queued_for_deletion(): return
	_arrived = true
	if _impact == null: _build_impact()
	if _cancelled or is_queued_for_deletion(): return
	_update_signature_shapes()
	_play_impact()
	_arrival_emitted = true
	arrived.emit()
	if _cancelled or is_queued_for_deletion(): return
	_presentation_arrival_emitted = true
	presentation_arrived.emit(_context)

func cancel_presentation() -> void:
	if _cancelled: return
	_cancelled = true
	_retire_contact_drawing()
	if is_instance_valid(_impact): _impact.free()
	_impact = null
	for stage: Dictionary in _stages:
		if is_instance_valid(stage.node): (stage.node as Node3D).visible = false
	super.cancel_presentation()

func diagnostic_receipt() -> Dictionary:
	var receipt := {"candidate": "astra_r3", "archetype": _kind,
		"cancelled": _cancelled, "arrival_emitted": _arrival_emitted,
		"presentation_arrival_emitted": _presentation_arrival_emitted,
		"elapsed": _elapsed, "travel_seconds": _travel, "contact_retired": _contact_retired,
		"lease": BUDGET.allocation(_lease), "held_opacity": _fade(),
		"particle_count": _cloud.multimesh.visible_instance_count if is_instance_valid(_cloud) and _cloud.visible else 0}
	if _kind == "buff_aura":
		_measure_whole_body()
		var bounds := {"valid": _bounds_valid, "method": "whole_render_bounds_midpoint",
			"position": _vector(_whole_bounds.position), "size": _vector(_whole_bounds.size)}
		if _bounds_valid:
			var pivot := _pivot.get_ref() as Node3D
			bounds["world_midpoint"] = _vector(pivot.to_global(_whole_bounds.get_center()))
			bounds["pivot_world_scale"] = _vector(pivot.global_basis.get_scale())
		receipt["whole_body_bounds"] = bounds
	else: receipt["renderer_donor"] = "water_jet body/trail/impact profiles; move_effect.gd and fluid_effect_geometry.gd unchanged"
	return receipt

static func _vector(value: Vector3) -> Array:
	return [value.x, value.y, value.z]
