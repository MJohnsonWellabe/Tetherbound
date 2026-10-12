extends "res://scripts/vfx/move_effect.gd"

## Four-example candidate. Inherits the existing presentation-only arrival,
## receipt/audio ownership, cancellation and lease-release contract. All new
## drawing is CPU-built depth-tested volume on both rendering backends.
const VOLUME := preload("res://scripts/vfx/astra_effect_geometry.gd")
const BOUNDS := preload("res://scripts/characters/render_bounds.gd")
const BUBBLE := preload("res://assets/vfx/shaders/bubble_surface.gdshader")

var tuning: Dictionary = {}
var _kind := ""
var _source_pivot: WeakRef
var _source_bounds := AABB()
var _wake: Array[MeshInstance3D] = []
var _lobes: MultiMeshInstance3D
var _contact_core: MeshInstance3D
var _directions: Array[Vector3] = []

## Called before add_child. This reference is local drawing state only;
## it is never added to a host receipt, save, RPC or the frozen action.
func bind_source(source: Node3D) -> bool:
	if source == null or not source.has_method("model_pivot"): return false
	var pivot := source.call("model_pivot") as Node3D
	if pivot == null: return false
	_source_bounds = BOUNDS.measure(pivot)
	if not _source_bounds.size.is_finite() or _source_bounds.size.x <= 0.0 \
			or _source_bounds.size.y <= 0.0 or _source_bounds.size.z <= 0.0: return false
	_source_pivot = weakref(pivot)
	return true

func _ready() -> void:
	add_to_group("move_effect_presentation")
	top_level = true
	global_transform = Transform3D.IDENTITY
	_kind = str(_row.archetype)
	var budget: Dictionary = _row.budget
	var limit := maxi(0, int(_config.get("ordinary_particle_limit", 48)))
	var impact := mini(int(budget.get("impact", 0)), limit)
	_lease = BUDGET.reserve(encounter_id(), impact,
		mini(int(budget.get("trail", 0)), maxi(0, limit - impact)), int(_config.get("encounter_particle_cap", 384)))
	for i in int(_params.count):
		var body := _mesh_node(VOLUME.sphere(float(_params.size)), _colour)
		# Replacement materials retain the inherited presentation opacity at
		# birth. Later fades use authored alpha, never the already-scaled alpha.
		body.material_override = _presentation_material(VOLUME.surface(_colour))
		if _kind == "bubble_volley":
			var film := ShaderMaterial.new()
			film.shader = BUBBLE
			film.set_shader_parameter("water_colour", _colour)
			film.set_shader_parameter("rim_colour", _colour.lerp(Color.WHITE, 0.85))
			film.set_shader_parameter("opacity", 1.0)
			film.set_shader_parameter("center_opacity", 0.15)
			film.set_shader_parameter("rim_power", float(tuning.get("bubble_rim_power", 0.65)))
			body.material_override = _presentation_material(film)
		_bodies.append(body)
		var wake := _mesh_node(ArrayMesh.new(), _colour)
		wake.material_override = _presentation_material(VOLUME.surface(_colour.lerp(Color.WHITE, 0.45), 0.75))
		_wake.append(wake)
	_update_bodies(0.0)
	_update_trail()
	_play_launch()
	if _travel <= 0.0:
		_update_bodies(1.0)
		_build_impact()
		call_deferred("_finish_presentation")
	elif _context.has("travel_seconds"):
		_presentation_clock = get_tree().create_timer(_travel, false)
		_presentation_clock.timeout.connect(_finish_presentation, CONNECT_ONE_SHOT)

func _process(delta: float) -> void:
	super._process(delta)
	if _kind == "buff_aura" and not _contact_retired:
		# Keep the same measured torso attachment while the caster moves or
		# its model pivot plays an attack. Never orbit around the muzzle point.
		_update_bodies(clampf(_elapsed / maxf(_travel, 0.00001), 0.0, 1.0))
		if _impact != null: _impact.position = _contact_position()
	if _arrived:
		var fade := 1.0 - clampf((_elapsed - _travel) / maxf(_lifetime_after_contact(), 0.001), 0.0, 1.0)
		if _kind == "slash_trail":
			for body: MeshInstance3D in _bodies:
				body.visible = not _contact_retired and fade > 0.0
				_set_opacity(body.material_override, fade)
		for wake: MeshInstance3D in _wake:
			wake.visible = _kind != "buff_aura" and not _contact_retired and fade > 0.0 \
				and int(BUDGET.allocation(_lease).get("trail", 0)) >= _wake.size() * 2
			_set_opacity(wake.material_override, 0.75 * fade)

func _path(t: float, index: int) -> Vector3:
	# Both the body and every wake sample call this function. Mastery's
	# resolved size/count/arc/spread are consumed once, without new timing.
	if _kind == "bubble_volley": return _projectile_position(t, index)
	var end := _impact_visual_origin({"visual_anchor": "contact_surface"})
	var direction := (end - _from).normalized()
	var side := direction.cross(Vector3.UP).normalized()
	if side.is_zero_approx(): side = Vector3.RIGHT
	var lane := float(index) - float(_bodies.size() - 1) * 0.5
	return _from.lerp(end, t) + side * lane * float(_params.get("spread", 0.0)) * sin(t * PI) \
		+ Vector3.UP * float(_params.get("arc", 0.0)) * sin(t * PI)

func _update_bodies(t: float) -> void:
	var size := float(_params.size)
	var steps := clampi(int(tuning.get("body_steps", 24)), 12, 32)
	var sides := clampi(int(tuning.get("tube_sides", 8)), 6, 12)
	for i in _bodies.size():
		var body := _bodies[i]
		body.position = _path(t, i)
		if _kind == "slash_trail":
			# A hooked, round claw stroke advances from caster to contact.
			# It has thickness in depth as well as height, even edge-on.
			var points: Array[Vector3] = []
			for k in steps + 1:
				var f := float(k) / float(steps)
				points.append(Vector3(sin(f * PI) * size * 0.55, (f - 0.5) * size * 2.0, (f - 0.5) * size * 0.5))
			body.mesh = VOLUME.tube(points, size * float(tuning.get("slash_radius_scale", 0.19)), sides, true)
			var direction := (_to - _from).normalized()
			if direction.is_zero_approx(): direction = Vector3.FORWARD
			body.quaternion = Quaternion(Vector3.FORWARD, direction)
		elif _kind == "catch_tether_beam":
			var points: Array[Vector3] = []
			for k in steps + 1: points.append(_from.lerp(_path(t, i), float(k) / float(steps)))
			body.position = Vector3.ZERO
			body.mesh = VOLUME.tube(points, size * float(tuning.get("beam_radius_scale", 1.15)), sides)
		elif _kind == "buff_aura":
			var pivot := _source_pivot.get_ref() as Node3D if _source_pivot != null else null
			if not is_instance_valid(pivot):
				cancel_presentation(); return
			var centre := _source_bounds.get_center()
			var half := _source_bounds.size * 0.5 * float(tuning.get("aura_padding", 1.1))
			# A rising double turn wraps the measured torso from lower body to
			# shoulders. Thickness grows with mastery; the actor remains legible.
			var points: Array[Vector3] = []
			for k in steps + 1:
				var f := float(k) / float(steps)
				var angle := f * TAU * 2.0 + _elapsed * 2.2
				points.append(centre + Vector3(cos(angle) * half.x,
					lerpf(-0.65, 0.65, f) * half.y, sin(angle) * half.z))
			body.transform = pivot.global_transform
			var scale := pivot.global_basis.get_scale()
			var model_scale := maxf(0.001, maxf(scale.x, maxf(scale.y, scale.z)))
			body.mesh = VOLUME.tube(points, size * float(tuning.get("aura_tube_radius_scale", 0.12)) / model_scale, sides, true)
			body.visible = true
			var fade := 1.0 if not _arrived else 1.0 - clampf((_elapsed - _travel) / maxf(_lifetime_after_contact(), 0.001), 0.0, 1.0)
			_set_opacity(body.material_override, fade)

func _update_trail() -> void:
	var granted := int(BUDGET.allocation(_lease).get("trail", 0))
	var samples := mini(32, floori(float(granted) / float(maxi(1, _wake.size()))))
	var progress := 1.0 if _arrived or _travel <= 0.0 else clampf(_elapsed / _travel, 0.0, 1.0)
	var span := float(_params.trail) * 2.4 / maxf(_from.distance_to(_to), 0.001)
	for i in _wake.size():
		var wake := _wake[i]
		wake.visible = samples >= 2 and _kind != "buff_aura" and progress > 0.0
		if not wake.visible: continue
		var points: Array[Vector3] = []
		for k in samples:
			var f := float(k) / float(samples - 1)
			points.append(_path(lerpf(maxf(0.0, progress - span), progress, f), i))
		wake.mesh = VOLUME.tube(points, float(_params.size) * float(tuning.get("trail_radius_scale", 0.15)) * sqrt(float(_params.trail)), 6, true)

func _contact_position() -> Vector3:
	if _kind == "buff_aura" and _source_pivot != null:
		var pivot := _source_pivot.get_ref() as Node3D
		if is_instance_valid(pivot): return pivot.to_global(_source_bounds.get_center())
	return _to

func _build_impact() -> void:
	_impact = Node3D.new()
	add_child(_impact)
	# Existing surface resolver places the burst on the incoming target face;
	# a centre-of-mass burst can disappear inside a large creature.
	_impact.position = _contact_position() if _kind == "buff_aura" else _impact_visual_origin({"visual_anchor": "contact_surface"})
	var radius := float(_params.size) * float(_params.impact_scale) * float(tuning.get("impact_radius_scale", 1.65))
	if _kind == "catch_tether_beam":
		radius = float(_params.size) * float(_params.impact_scale) * float(tuning.get("tether_impact_radius_scale", 4.0))
	_contact_core = _mesh_node(VOLUME.sphere(radius), _colour)
	_contact_core.reparent(_impact, false)
	_contact_core.material_override = _presentation_material(VOLUME.surface(_colour.lerp(Color.WHITE, 0.6), 0.85))
	# One swelling contact body survives budget pressure; rounded spray/lobes
	# consume only the admitted impact slots. No lines, stars or flat flashes.
	_lobes = MultiMeshInstance3D.new()
	var multi := MultiMesh.new()
	multi.transform_format = MultiMesh.TRANSFORM_3D
	multi.mesh = VOLUME.sphere(radius * 0.3)
	multi.instance_count = int(BUDGET.allocation(_lease).get("impact", 0))
	_lobes.multimesh = multi
	_lobes.material_override = _presentation_material(VOLUME.surface(_colour.lerp(Color.WHITE, 0.3), 0.9))
	_lobes.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_impact.add_child(_lobes)
	for i in multi.instance_count:
		var y := 1.0 - 2.0 * (float(i) + 0.5) / float(multi.instance_count)
		var angle := float(i) * 2.399963
		_directions.append(Vector3(cos(angle) * sqrt(1.0 - y * y), y, sin(angle) * sqrt(1.0 - y * y)))
	_update_impact(0.0, 0.0)

func _update_impact(u: float, _delta: float) -> void:
	if _contact_core == null: return
	var size := float(_params.size) * float(_params.impact_scale)
	_contact_core.scale = Vector3.ONE * lerpf(0.6, 1.25, u)
	if _kind == "buff_aura": _contact_core.visible = false # Never engulf the caster in a solid ball.
	_set_opacity(_contact_core.material_override, 0.85 * (1.0 - u))
	var count := mini(_directions.size(), int(BUDGET.allocation(_lease).get("impact", 0)))
	_lobes.multimesh.visible_instance_count = count
	for i in count:
		var offset := _directions[i] * size * (0.85 + 3.0 * u)
		if _kind == "buff_aura":
			# Contact brightening stays on the body's surrounding envelope.
			var pivot := _source_pivot.get_ref() as Node3D if _source_pivot != null else null
			if is_instance_valid(pivot):
				offset = pivot.global_basis * (_directions[i] * _source_bounds.size * (0.53 + 0.08 * u))
		var scale := Vector3.ONE * (1.0 - u * 0.75)
		_lobes.multimesh.set_instance_transform(i, Transform3D(Basis.IDENTITY.scaled(scale), offset))
	_set_opacity(_lobes.material_override, 0.9 * (1.0 - u))

func _retire_contact_drawing() -> void:
	super._retire_contact_drawing()
	for wake: MeshInstance3D in _wake: wake.visible = false
