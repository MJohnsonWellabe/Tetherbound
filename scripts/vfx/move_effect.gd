extends Node3D

## Local rendering of a host-scheduled action. No collision objects, timers
## driving damage, durable fields or RPCs are owned by this node.
const GEOMETRY := preload("res://scripts/vfx/move_effect_geometry.gd")
const BUDGET := preload("res://scripts/vfx/move_effect_budget.gd")
const AUDIO := preload("res://scripts/audio/audio_manager.gd")

signal arrived()
signal presentation_arrived(receipt: Dictionary)

var _from: Vector3
var _to: Vector3
var _row: Dictionary
var _context: Dictionary
var _config: Dictionary
var _params: Dictionary
var _travel: float
var _elapsed: float = 0.0
var _arrived: bool = false
var _lease: int = 0
var _bodies: Array[MeshInstance3D] = []
var _trails: Array[MeshInstance3D] = []
var _histories: Array = []
var _impact: Node3D
var _marker: MeshInstance3D
var _motes: MultiMeshInstance3D
var _mote_positions: Array[Vector3] = []
var _velocities: Array[Vector3] = []
var _mote_bases: Array[Basis] = []
var _puffs: MultiMeshInstance3D
var _puff_directions: Array[Vector3] = []
var _puff_scales: Array[float] = []
var _puff_extent := Vector3.ZERO
var _puff_origin := Vector3.ZERO
var _rng := RandomNumberGenerator.new()
var _colour: Color
var _presentation_clock: SceneTreeTimer

func configure(from: Vector3, to: Vector3, row: Dictionary, context: Dictionary,
		travel: float, config: Dictionary) -> void:
	_from = from
	_to = to
	_row = row.duplicate(true)
	_context = context
	_config = config.duplicate(true)
	_params = _row.parameters
	_travel = travel
	_colour = Color(str(_params.get("colour", "#e4c67d")))
	_rng.seed = int(context.get("seed", 0))

func _ready() -> void:
	add_to_group("move_effect_presentation")
	top_level = true
	global_transform = Transform3D.IDENTITY
	var budget: Dictionary = _row.get("budget", {})
	var limit := int(_config.get("ultimate_particle_limit", 160)) if bool(_context.get("ultimate", false)) else int(_config.get("ordinary_particle_limit", 48))
	var requested_impact := mini(int(budget.get("impact", 24)), limit)
	var requested_trail := mini(int(budget.get("trail", 12)), maxi(0, limit - requested_impact))
	_lease = BUDGET.reserve(str(_context.get("encounter_id", "global")), requested_impact,
		requested_trail, int(_config.get("encounter_particle_cap", 384)))
	var profile: Dictionary = _row.get("body", {})
	for i in int(_params.count):
		var body := _mesh_node(GEOMETRY.shape(str(profile.shape), float(_params.size), profile),
			_colour, float(profile.get("opacity", 1.0)), bool(profile.get("lit", false)))
		if str(profile.shape) in ["stone", "flame_orb", "burning_core", "water_stream", "rolling_wave", "ice_crystal", "flame_volume", "mist_cone"]:
			body.material_override = GEOMETRY.authored_material(str(profile.shape), profile, _colour)
			body.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if str(profile.shape) == "stone" else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		if str(profile.get("motion", "")) == "sky": body.material_override = GEOMETRY.authored_material("ion_filament", profile, _colour)
		_bodies.append(body)
		var history: Array[Vector3] = []
		_histories.append(history)
		for layer: Dictionary in profile.get("layers", []):
			var component := _mesh_node(GEOMETRY.shape(str(layer.get("shape", "orb")), float(_params.size) * float(layer.get("size_scale", 0.5)), layer),
				Color(str(layer.get("colour", _params.colour))), float(layer.get("opacity", 0.8)))
			component.reparent(body, false)
			if str(layer.get("shape", "")) in ["flame_orb", "fire_bloom", "flame_tongue"]:
				component.material_override = GEOMETRY.authored_material(str(layer.shape), layer, Color(str(layer.get("colour", _params.colour))))
			var offset: Array = layer.get("offset", [0.0, 0.0, 0.0])
			component.position = Vector3(float(offset[0]), float(offset[1]), float(offset[2])) * float(_params.size)
			component.set_meta("spin_rate", float(layer.get("spin_rate", 0.0)))
			component.set_meta("yaw_offset", deg_to_rad(float(layer.get("yaw_offset_deg", 0.0))))
		if str(profile.shape) == "stone":
			body.scale = Vector3(_rng.randf_range(0.82, 1.14), _rng.randf_range(0.82, 1.14), _rng.randf_range(0.82, 1.14))
			body.rotation = Vector3(_rng.randf() * TAU, _rng.randf() * TAU, _rng.randf() * TAU)
	if str(profile.get("motion", "")) == "sky" or (str(profile.get("motion", "")) == "target" and str(profile.get("shape", "")) == "spike"):
		_marker = _mesh_node(GEOMETRY.shape("sigil", float(_params.size) * float(profile.get("marker_scale", 2.0)), profile), _colour, float(profile.get("marker_opacity", 0.38)))
		_marker.position = _context.get("target_ground", _to)
	for i in _bodies.size():
		var trail_layers := 2 if bool(_row.secondary_trail) and int(BUDGET.allocation(_lease).get("trail", 0)) >= _bodies.size() * 6 else 1
		for layer in trail_layers:
			var trail := _mesh_node(ImmediateMesh.new(), Color.WHITE, float((_row.trail as Dictionary).get("opacity", 0.78)))
			var trail_profile: Dictionary = _row.trail.duplicate(true)
			trail_profile["dust"] = str(trail_profile.get("style", "air")) not in ["flame", "ember", "ion"]
			trail.material_override = GEOMETRY.authored_material("soft_trail", trail_profile, Color(str(trail_profile.get("colour", _params.colour))))
			trail.set_meta("body_index", i)
			trail.set_meta("layer", layer)
			_trails.append(trail)
	_update_bodies(0.0)
	_play_launch()
	if _context.has("travel_seconds") and _travel > 0.0:
		# The host creates its separate authoritative timer after launch returns.
		# Both timers have the same idle clock and birth phase; this one can
		# finish visuals only and is independent of the damage transaction.
		_presentation_clock = get_tree().create_timer(_travel, false)
		_presentation_clock.timeout.connect(_finish_presentation, CONNECT_ONE_SHOT)

func _mesh_node(mesh: Mesh, colour: Color, opacity: float = 1.0, lit: bool = false) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.mesh = mesh
	node.material_override = GEOMETRY.material(colour, opacity, lit)
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(node)
	return node

func _process(delta: float) -> void:
	if not _arrived and _presentation_clock != null:
		_elapsed = maxf(0.0, _travel - _presentation_clock.time_left)
	else:
		_elapsed += delta
	var t := clampf(_elapsed / maxf(_travel, 0.00001), 0.0, 1.0)
	if not _arrived:
		_update_bodies(t)
		_update_trail()
		if _presentation_clock == null and _elapsed >= _travel:
			_finish_presentation()
	else:
		_update_trail()
		var duration := float((_row.impact as Dictionary).get("duration", 0.45))
		var u := clampf((_elapsed - _travel) / maxf(duration, 0.001), 0.0, 1.0)
		_update_impact(u, delta)
		var contact_age := _elapsed - _travel
		for body: MeshInstance3D in _bodies:
			# Retain the completed vertical strike through contact and early
			# impact, so the visual actually joins sky, target and ground.
			body.visible = str(_row.body.get("motion", "")) == "sky" and contact_age < float(_row.body.get("contact_hold_seconds", 0.0))
		for trail: MeshInstance3D in _trails:
			_set_opacity(trail.material_override, (1.0 - u) * float((_row.trail as Dictionary).get("opacity", 0.78)))
		if u >= 1.0: queue_free()

func _finish_presentation() -> void:
	if _arrived: return
	_elapsed = _travel
	_update_bodies(1.0)
	_arrived = true
	_build_impact()
	_play_impact()
	# Contact geometry exists before the later host timer can resolve HP.
	# No observer of this informational signal can authorize a gameplay hit.
	arrived.emit()
	presentation_arrived.emit(_context)

func _update_bodies(t: float) -> void:
	var mode := str((_row.body as Dictionary).get("motion", "projectile"))
	var direction := (_to - _from).normalized()
	if direction.length_squared() < 0.001: direction = Vector3.FORWARD
	var side := direction.cross(Vector3.UP).normalized()
	if side.length_squared() < 0.001: side = Vector3.RIGHT
	var front := _from.lerp(_to, t)
	for i in _bodies.size():
		var body := _bodies[i]
		var angle := TAU * float(i) / float(_bodies.size())
		var spread_size := float(_params.get("spread", 0.0))
		if _bodies.size() > 1:
			spread_size = maxf(spread_size, float(_params.size) * float(_row.body.get("volley_separation_scale", 2.8)))
		var spread := spread_size * sin(t * PI)
		body.position = front + (side * cos(angle) + Vector3.UP * sin(angle)) * spread
		if _bodies.size() > 1:
			body.position += direction * (float(i) - float(_bodies.size() - 1) * 0.5) * float(_row.body.get("volley_stagger_m", 0.25)) * sin(t * PI)
		body.position.y += float(_params.get("arc", 0.0)) * sin(t * PI)
		if mode == "projectile": body.position = _projectile_position(t, i)
		match mode:
			"sky":
				var marker_fraction := float((_row.body as Dictionary).get("marker_fraction", 0.65))
				body.visible = t >= marker_fraction
				if _marker != null: _marker.visible = not body.visible
				var contact_t := clampf((t - marker_fraction) / maxf(0.001, 1.0 - marker_fraction), 0.0, 1.0)
				var height := float((_row.body as Dictionary).get("sky_height", 6.0))
				var points: Array[Vector3] = []
				var contact: Vector3 = _context.get("target_ground", _to) if str(_row.body.get("contact_anchor", "target")) == "target_ground" else _to
				var start := contact + Vector3.UP * height
				var across := side.cross(Vector3.UP).normalized()
				var phase := float(int(_context.get("seed", 0)) % 97) * 0.1
				for k in 9:
					var f := float(k) / 8.0
					var irregular := side * sin(f * 19.3 + phase) + across * sin(f * 31.7 - phase) * 0.55
					points.append(start.lerp(contact, f * contact_t) + irregular * float(_params.size) * sin(f * PI))
				body.position = Vector3.ZERO
				var bolt_profile: Dictionary = _row.body.duplicate(true)
				bolt_profile["branch_count"] = int(_row.body.get("branch_count", 3)) + (int(_row.mastery_rank) - 1) * int(_row.body.get("branch_add_per_rank", 1))
				bolt_profile["branch_length_m"] = float(_row.body.get("branch_length_m", 0.9)) * float(_params.trail)
				body.mesh = GEOMETRY.bolt(points, float(_params.size) * float(_row.body.get("stroke_width_scale", 0.34)), _colour, bolt_profile)
			"chain", "beam":
				var points: Array[Vector3] = []
				for k in 10:
					var f := float(k) / 9.0
					points.append(_from.lerp(front, f) + side * sin(f * TAU * 4.0) * float(_params.size) * 0.5 * sin(f * PI))
				body.position = Vector3.ZERO
				body.mesh = GEOMETRY.ribbon(points, float(_params.size) * 0.22, _colour)
			"cone", "stream":
				body.position = _from.lerp(front, 0.5)
				body.quaternion = Quaternion(Vector3.UP, direction)
				body.scale.y = maxf(0.02, _from.distance_to(front) / (float(_params.size) * float((_row.body as Dictionary).get("height_ratio", 3.0))))
			"pulse":
				body.position = _from
				# Keep the wavefront's width constant as its radius expands.
				# Scaling the whole band would turn a long pulse into a slab.
				var profile: Dictionary = _row.body
				body.mesh = GEOMETRY.shape(str(profile.shape), maxf(0.05, _from.distance_to(_to) * t), profile)
			"radial":
				var radius := _from.distance_to(_to) * t
				body.position = _from + (direction * cos(angle) + side * sin(angle)) * radius
				body.position.y += float(_params.get("arc", 0.0)) * sin(t * PI)
			"target":
				body.position = _to + (side * cos(angle) + direction * sin(angle)) * float(_params.get("spread", 0.0))
				body.scale.y = maxf(0.02, t)
				if str((_row.body as Dictionary).get("shape", "")) == "spike":
					var marker_fraction := float((_row.body as Dictionary).get("marker_fraction", 0.65))
					body.visible = t >= marker_fraction
					body.scale.y = maxf(0.02, (t - marker_fraction) / maxf(0.001, 1.0 - marker_fraction))
					# CylinderMesh is centered on its origin. Raise its center by
					# half its current height so the root grows from the floor,
					# rather than from the target's torso or below the ground.
					var ground: Vector3 = _context.get("target_ground", _to)
					var horizontal := Vector3(direction.x, 0.0, direction.z).normalized()
					if horizontal.length_squared() < 0.001: horizontal = Vector3.FORWARD
					var across := horizontal.cross(Vector3.UP).normalized()
					body.position = ground + (across * cos(angle) + horizontal * sin(angle)) * float(_params.get("spread", 0.0))
					body.position.y += float(_params.size) * float((_row.body as Dictionary).get("height_ratio", 3.0)) * body.scale.y * 0.5
					if _marker != null: _marker.visible = not body.visible
				if str((_row.body as Dictionary).get("shape", "")) == "crescent":
					body.rotation = Vector3(PI * 0.5, angle, t * PI * 0.5)
			"self":
				body.position = _from
				body.rotation.y = angle + t * TAU
			_:
				if str((_row.body as Dictionary).get("shape", "")) in ["shard", "cone", "crescent", "ice_crystal"]: body.quaternion = Quaternion(Vector3.UP, direction)
		if str((_row.body as Dictionary).get("shape", "")) == "vortex": body.rotation.y = t * TAU
		if str(_row.body.get("shape", "")) == "rolling_wave":
			var planar := Vector3(direction.x, 0.0, direction.z).normalized()
			if not planar.is_zero_approx(): body.quaternion = Quaternion(Vector3.FORWARD, planar)
			var ground: Vector3 = _context.get("target_ground", _to)
			body.position.y = ground.y + float(_params.size) * 0.05
		for component: Node in body.get_children():
			if component is Node3D: component.rotation.y = float(component.get_meta("yaw_offset", 0.0)) + _elapsed * float(component.get_meta("spin_rate", 0.0))
		var trail_head := body.position if mode not in ["sky", "chain", "beam"] else front
		if mode == "sky":
			var contact: Vector3 = _context.get("target_ground", _to) if str(_row.body.get("contact_anchor", "target")) == "target_ground" else _to
			var start := contact + Vector3.UP * float(_row.body.get("sky_height", 6.0))
			trail_head = start.lerp(contact, clampf((t - float(_row.body.get("marker_fraction", 0.65))) / maxf(0.001, 1.0 - float(_row.body.get("marker_fraction", 0.65))), 0.0, 1.0))
		_append_trail_point(i, trail_head)

func _projectile_position(t: float, index: int) -> Vector3:
	var direction := (_to - _from).normalized()
	if direction.length_squared() < 0.001: direction = Vector3.FORWARD
	var side := direction.cross(Vector3.UP).normalized()
	if side.length_squared() < 0.001: side = Vector3.RIGHT
	var count := maxi(1, _bodies.size())
	var spread_size := float(_params.get("spread", 0.0))
	if count > 1: spread_size = maxf(spread_size, float(_params.size) * float(_row.body.get("volley_separation_scale", 2.8)))
	var angle := TAU * float(index) / float(count)
	var position := _from.lerp(_to, t) + (side * cos(angle) + Vector3.UP * sin(angle)) * spread_size * sin(t * PI)
	if count > 1:
		position += direction * (float(index) - float(count - 1) * 0.5) * float(_row.body.get("volley_stagger_m", 0.25)) * sin(t * PI)
	position.y += float(_params.get("arc", 0.0)) * sin(t * PI)
	return position

func _append_trail_point(index: int, point: Vector3) -> void:
	var history: Array[Vector3] = _histories[index]
	var spacing := maxf(0.025, float(_row.trail.get("sample_spacing_m", 0.14)) * float(_params.trail))
	if history.is_empty(): history.append(point); return
	var distance: float = history.back().distance_to(point)
	if distance < spacing: return
	var start: Vector3 = history.back()
	var steps := mini(32, floori(distance / spacing))
	for i in steps:
		history.append(start.lerp(point, float(i + 1) / float(steps)))

func _update_trail() -> void:
	var samples := floori(float(BUDGET.allocation(_lease).get("trail", 0)) / float(maxi(1, _trails.size())))
	var profile: Dictionary = _row.trail
	for trail: MeshInstance3D in _trails:
		var layer := int(trail.get_meta("layer", 0))
		var body_index := int(trail.get_meta("body_index", 0))
		var history: Array[Vector3] = _histories[body_index]
		while history.size() > maxi(1, samples): history.pop_front()
		trail.visible = samples >= 2 and history.size() >= 2
		if trail.visible:
			var base_colour := Color(str(profile.get("colour", _params.colour)))
			var colour := base_colour.lerp(Color.WHITE, 0.7) if layer == 1 else base_colour
			var points: Array[Vector3] = history.duplicate()
			var max_length := float(profile.get("max_length_m", 2.4)) * float(_params.trail)
			while points.size() > 2 and points.front().distance_to(points.back()) > max_length: points.pop_front()
			var style := str(profile.get("style", "air"))
			# A small volley has only a few leased trail control points per
			# stone. Sample its actual frozen visual path across a meaningful
			# length instead of spending those points on centimetres of wake.
			if style == "dust" and str(_row.body.get("motion", "")) == "projectile":
				var progress := clampf(_elapsed / maxf(_travel, 0.00001), 0.0, 1.0)
				var span := max_length / maxf(_from.distance_to(_to), 0.001)
				var start := maxf(0.0, progress - span)
				points.clear()
				for sample in maxi(2, samples):
					points.append(_projectile_position(lerpf(start, progress, float(sample) / float(maxi(1, samples - 1))), body_index))
			var amplitude := float(profile.get("wave_amplitude", 0.05)) * float(_params.size)
			var frequency := float(profile.get("wave_frequency", 3.0))
			for i in points.size():
				var f := float(i) / float(maxi(1, points.size() - 1))
				var phase := f * frequency * TAU + _elapsed * float(profile.get("wave_speed", 4.0))
				match style:
					"ion", "tether": points[i].y += signf(sin(phase)) * amplitude * sin(f * PI)
					"flame", "ember", "painted_flame": points[i].y += absf(sin(phase)) * amplitude * (1.0 - f)
					"wisp", "ripple", "mote": points[i] += Vector3(cos(phase), sin(phase), 0.0) * amplitude * sin(f * PI)
					"foam", "spray", "bubble": points[i].y += sin(phase) * amplitude
					"dust": points[i].y -= amplitude * (1.0 - f)
					_: points[i].y += sin(phase) * amplitude * sin(f * PI)
			var width := float(profile.get("width", 0.08)) * float(_params.trail) * (0.48 if layer == 1 else 1.0)
			var camera := get_viewport().get_camera_3d()
			var camera_position := camera.global_position if camera != null else _from + Vector3(0, 5, 14)
			trail.mesh = GEOMETRY.flowing_ribbon(points, width, camera_position)
			var colour_uniform := "dust_colour" if style == "dust" else "flame_colour"
			(trail.material_override as ShaderMaterial).set_shader_parameter(colour_uniform, colour)

func _build_impact() -> void:
	if _marker != null: _marker.visible = false
	_impact = Node3D.new()
	add_child(_impact)
	_impact.position = _contact_position()
	var profile: Dictionary = _row.impact
	var scale_factor := float(_params.size) * float(_params.impact_scale)
	# Only child presentation geometry moves to the measured surface. The
	# frozen contact endpoint, arrived clock and host gameplay stay unchanged.
	var surface_offset := _impact_visual_origin(profile) - _contact_position()
	var core := _mesh_node(GEOMETRY.shape(str(profile.get("shape", "ring")), scale_factor, profile),
		_colour.lerp(Color.WHITE, float(profile.get("heat", 0.45))), float(profile.get("opacity", 0.82)))
	if str(profile.get("shape", "")) in ["fire_bloom", "soft_dust", "soft_ember", "soft_foam", "flame_tongue", "electrical_splash"]: core.material_override = GEOMETRY.authored_material(str(profile.shape), profile, _colour)
	core.set_meta("base_opacity", float(profile.get("opacity", 0.82)))
	core.reparent(_impact, false)
	core.position = surface_offset
	for layer: Dictionary in profile.get("layers", []):
		var scale := float(layer.get("size_scale", 1.0))
		var part := _mesh_node(GEOMETRY.shape(str(layer.get("shape", "orb")), scale_factor * scale, layer),
			Color(str(layer.get("colour", _params.colour))), float(layer.get("opacity", 0.6)), bool(layer.get("lit", false)))
		if str(layer.get("shape", "")) in ["fire_bloom", "soft_dust", "soft_ember", "soft_foam", "flame_tongue", "electrical_splash"]: part.material_override = GEOMETRY.authored_material(str(layer.shape), layer, Color(str(layer.get("colour", _params.colour))))
		part.set_meta("base_opacity", float(layer.get("opacity", 0.6)))
		part.reparent(_impact, false)
		var offset: Array = layer.get("offset", [0.0, 0.0, 0.0])
		part.position = surface_offset + Vector3(float(offset[0]), float(offset[1]), float(offset[2])) * scale_factor
		if bool(layer.get("at_ground", false)):
			var ground: Vector3 = _context.get("target_ground", _to)
			part.position.y = ground.y - _contact_position().y + scale_factor * float(layer.get("ground_lift_scale", 0.3))
	if bool(_row.impact_layer):
		var secondary := _mesh_node(GEOMETRY.shape(str(profile.get("secondary_shape", "ring")), scale_factor * 1.35, profile), _colour, 0.65)
		if str(profile.get("secondary_shape", "")) in ["fire_bloom", "soft_dust", "soft_ember", "soft_foam", "flame_tongue", "electrical_splash"]: secondary.material_override = GEOMETRY.authored_material(str(profile.secondary_shape), profile, _colour)
		secondary.set_meta("base_opacity", 0.65)
		secondary.reparent(_impact, false)
		secondary.position = surface_offset
		secondary.rotation.x = float(profile.get("secondary_rotation_x", PI * 0.5))
	var impact_slots := int(BUDGET.allocation(_lease).get("impact", 0))
	var puff_count := mini(impact_slots, maxi(0, int(profile.get("puff_count", 0))))
	if puff_count > 0: _build_puffs(puff_count, profile, scale_factor)
	var count := impact_slots - puff_count
	if count > 0:
		# One draw call for all manually integrated CPU motes. No GPU-particle
		# fallback dependency and no per-mote Node or material allocations.
		var multimesh := MultiMesh.new()
		multimesh.transform_format = MultiMesh.TRANSFORM_3D
		multimesh.use_custom_data = true
		multimesh.mesh = GEOMETRY.shape(str(profile.get("mote_shape", "orb")), float(profile.get("mote_size", 0.045)))
		multimesh.instance_count = count
		_motes = MultiMeshInstance3D.new()
		_motes.multimesh = multimesh
		_motes.material_override = GEOMETRY.material(Color(str(profile.get("mote_colour", _params.colour))), 0.86, str(profile.get("mote_shape", "orb")) == "stone")
		if str(profile.get("mote_shape", "")) in ["soft_ember", "stone", "ice_crystal"]:
			_motes.material_override = GEOMETRY.authored_material(str(profile.mote_shape), profile, Color(str(profile.get("mote_colour", _params.colour))))
		_motes.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		_impact.add_child(_motes)
	for i in count:
		var start := surface_offset + Vector3(_rng.randf_range(-0.08, 0.08), _rng.randf_range(-0.03, 0.08), _rng.randf_range(-0.08, 0.08)) * scale_factor
		_mote_positions.append(start)
		var varied_basis := Basis.from_euler(Vector3(_rng.randf() * TAU, _rng.randf() * TAU, _rng.randf() * TAU)).scaled(Vector3.ONE * _rng.randf_range(0.55, 1.45))
		_mote_bases.append(varied_basis)
		_motes.multimesh.set_instance_transform(i, Transform3D(varied_basis, start))
		_motes.multimesh.set_instance_custom_data(i, Color(_rng.randf(), 0, 0, 0))
		var direction := Vector3(_rng.randf_range(-1.0, 1.0), _rng.randf_range(0.2, 1.0), _rng.randf_range(-1.0, 1.0)).normalized()
		var backscatter := (_from - _to).normalized()
		direction = (direction + backscatter * float(profile.get("mote_backscatter", 0.0))).normalized()
		_velocities.append(direction * float(profile.get("speed", 3.8)) * _rng.randf_range(0.65, 1.25))

func _impact_visual_origin(profile: Dictionary) -> Vector3:
	var contact := _contact_position()
	var anchor := str(profile.get("visual_anchor", ""))
	if anchor not in ["contact_surface", "sky_surface"]: return contact
	var raw_bounds: Variant = _context.get("target_visual_bounds", {})
	if not raw_bounds is Dictionary: return contact
	var raw_position: Variant = raw_bounds.get("position", null)
	var raw_size: Variant = raw_bounds.get("size", null)
	if not raw_position is Vector3 or not raw_size is Vector3: return contact
	var position: Vector3 = raw_position
	var size: Vector3 = raw_size
	if not position.is_finite() or not size.is_finite() or size.x <= 0.0 or size.y <= 0.0 or size.z <= 0.0: return contact
	if anchor == "sky_surface":
		return Vector3(clampf(contact.x, position.x, position.x + size.x),
			position.y + size.y + float(profile.get("visual_surface_lift_m", 0.02)),
			clampf(contact.z, position.z, position.z + size.z))
	var intersection: Variant = AABB(position, size).intersects_segment(_from, _to)
	return intersection as Vector3 if intersection is Vector3 else contact

func _build_puffs(count: int, profile: Dictionary, scale_factor: float) -> void:
	# Puffs and chips share the exact reserved impact slots; never add particles
	# beyond the ordinary/ultimate/encounter lease to make a capture look richer.
	var raw_bounds: Variant = _context.get("target_visual_bounds", {})
	var bounds: Dictionary = raw_bounds if raw_bounds is Dictionary else {}
	var raw_size: Variant = bounds.get("size", Vector3.ZERO)
	var raw_position: Variant = bounds.get("position", _to)
	var valid_bounds := raw_size is Vector3 and raw_position is Vector3
	if valid_bounds:
		valid_bounds = (raw_size as Vector3).is_finite() and (raw_position as Vector3).is_finite() and (raw_size as Vector3).x > 0.0 and (raw_size as Vector3).y > 0.0 and (raw_size as Vector3).z > 0.0
	var radius := scale_factor * float(profile.get("puff_radius_scale", 1.5))
	_puff_extent = Vector3.ONE * radius
	_puff_origin = _impact_visual_origin(profile) - _contact_position()
	if valid_bounds:
		var size: Vector3 = raw_size
		_puff_extent = _puff_extent.max(size * float(profile.get("target_envelope_scale", 0.55)))
		if str(profile.get("visual_anchor", "")) not in ["contact_surface", "sky_surface"]:
			_puff_origin = (raw_position as Vector3) + size * 0.5 - _contact_position()
	var multimesh := MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.use_custom_data = true
	multimesh.mesh = GEOMETRY.shape(str(profile.get("puff_shape", "fire_bloom")), scale_factor * float(profile.get("puff_size_scale", 1.5)), profile)
	multimesh.instance_count = count
	_puffs = MultiMeshInstance3D.new()
	_puffs.multimesh = multimesh
	var puff_profile: Dictionary = profile.duplicate(true)
	puff_profile["opacity"] = float(profile.get("puff_opacity", 0.72))
	_puffs.material_override = GEOMETRY.authored_material(str(profile.get("puff_shape", "fire_bloom")), puff_profile, Color(str(profile.get("puff_colour", _params.colour))))
	_puffs.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_impact.add_child(_puffs)
	if bool(profile.get("puff_at_ground", false)):
		var ground: Vector3 = _context.get("target_ground", _to)
		# Lift the visible noisy card edge rather than clipping every puff at
		# the same floor height, which produces a straight horizontal band.
		var card_radius := scale_factor * float(profile.get("puff_size_scale", 1.5)) * float(profile.get("card_extent_scale", 3.2)) * 0.5
		_puff_origin.y = ground.y - _contact_position().y + card_radius * float(profile.get("puff_ground_clearance_scale", 0.75))
	for i in count:
		var angle := float(i) * 2.399963
		var y := 1.0 - 2.0 * (float(i) + 0.5) / float(count)
		var radial := sqrt(maxf(0.0, 1.0 - y * y))
		var direction := Vector3(cos(angle) * radial, y, sin(angle) * radial)
		if bool(profile.get("puff_at_ground", false)): direction.y = absf(direction.y) * 0.55
		else: direction.y = direction.y * 0.65 + 0.3
		direction += (_from - _to).normalized() * float(profile.get("puff_backscatter", 0.0))
		_puff_directions.append(direction)
		_puff_scales.append(_rng.randf_range(0.72, 1.18))
		multimesh.set_instance_custom_data(i, Color(_rng.randf(), 0, 0, 0))
	_update_puffs(0.0)

func _update_puffs(u: float) -> void:
	if _puffs == null: return
	var profile: Dictionary = _row.impact
	var extent := _puff_extent * lerpf(float(profile.get("puff_start_radius_scale", 0.65)), float(profile.get("puff_end_radius_scale", 1.4)), u)
	_set_opacity(_puffs.material_override, pow(1.0 - u, 1.2) * float(profile.get("puff_opacity", 0.72)))
	for i in _puff_directions.size():
		var center := _puff_origin + _puff_directions[i] * extent
		center.y += float(profile.get("puff_lift_m", 0.7)) * u
		var scale := _puff_scales[i] * lerpf(1.0, float(profile.get("puff_grow", 1.6)), u)
		_puffs.multimesh.set_instance_transform(i, Transform3D(Basis.IDENTITY.scaled(Vector3.ONE * scale), center))

func _update_impact(u: float, delta: float) -> void:
	if _impact == null: return
	var profile: Dictionary = _row.impact
	_update_puffs(u)
	for child: Node in _impact.get_children():
		if child is MeshInstance3D:
			var alpha := (1.0 - u) * float(child.get_meta("base_opacity", profile.get("opacity", 0.82)))
			_set_opacity(child.material_override, alpha)
	var growth := lerpf(float(profile.get("initial_grow", 0.35)), float(profile.get("grow", 2.0)), u)
	for child: Node in _impact.get_children():
		if child is Node3D and child != _motes and child != _puffs: child.scale = Vector3.ONE * growth
	if _motes != null:
		_set_opacity(_motes.material_override, (1.0 - u) * float(profile.get("opacity", 0.82)))
	for i in _mote_positions.size():
		_velocities[i].y -= float(profile.get("gravity", 5.0)) * delta
		_mote_positions[i] += _velocities[i] * delta
		var tumble := float(profile.get("mote_tumble_radians", 0.0))
		if tumble > 0.0:
			_mote_bases[i] = _mote_bases[i].rotated(Vector3(0.7, 0.3, 0.6).normalized(), tumble * delta * (1.0 + float(i % 3) * 0.3))
		var ground: Vector3 = _context.get("target_ground", _to)
		var floor_y := ground.y - _contact_position().y + float(profile.get("mote_size", 0.045))
		if bool(profile.get("settle_on_ground", false)) and _mote_positions[i].y < floor_y:
			_mote_positions[i].y = floor_y
			_velocities[i] = Vector3.ZERO
		_motes.multimesh.set_instance_transform(i, Transform3D(_mote_bases[i].scaled(Vector3.ONE * lerpf(1.0, float(profile.get("mote_end_scale", 0.05)), u)), _mote_positions[i]))

func _set_opacity(material: Material, alpha: float) -> void:
	if material is ShaderMaterial:
		(material as ShaderMaterial).set_shader_parameter("opacity", alpha)
	elif material is StandardMaterial3D:
		(material as StandardMaterial3D).transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		(material as StandardMaterial3D).albedo_color.a = alpha

func _cue(name: String) -> String:
	var sounds: Dictionary = _row.sound
	var id := str(sounds.get(name, ""))
	return str(AUDIO.section("move_effect_cues").get(id, ""))

func _contact_position() -> Vector3:
	if str(_row.impact.get("contact_anchor", "")) == "target": return _to
	var body: Dictionary = _row.body
	if str(body.get("motion", "")) == "self": return _from
	if str(body.get("contact_anchor", "")) == "target_ground": return _context.get("target_ground", _to)
	if str(body.get("motion", "")) == "target" and str(body.get("shape", "")) == "spike":
		return _context.get("target_ground", _to)
	return _to

func _play_launch() -> void:
	var minimum := float((_row.sound as Dictionary).get("travel_min_seconds", 0.18))
	var name := "launch_travel" if _travel >= minimum else "launch"
	if int(_row.mastery_rank) >= 5: name += "_mastery"
	var path := _cue(name)
	if path.is_empty(): return
	AUDIO.play_file_at(path, str(_row.archetype) + ":" + name, _from, "SFX", float((_row.sound as Dictionary).get("gain_db", -7.0)))

func _play_impact() -> void:
	# An accepted combat receipt can own the one classified contact cue. This
	# frozen presentation value never authorizes damage or depends on lifetime.
	if str(_context.get("impact_audio_owner", "renderer")) == "receipt": return
	var name := "impact_mastery" if int(_row.mastery_rank) >= 5 else "impact"
	var path := _cue(name)
	if path.is_empty(): return
	AUDIO.play_file_at(path, str(_row.archetype) + ":" + name, _contact_position(), "SFX", float((_row.sound as Dictionary).get("gain_db", -7.0)))

func _exit_tree() -> void:
	BUDGET.release(_lease)
	# AudioManager owns its pooled players; do not stop a recycled voice here.

func action_id() -> String:
	return str(_context.get("action_id", ""))

func encounter_id() -> String:
	return str(_context.get("encounter_id", "global"))

func confirm_presentation_impact() -> void:
	# A host result may reach a late client before its local travel clock.
	# Snap the frozen visual only; guarded finish keeps arrival exactly once.
	_finish_presentation()

func cancel_presentation() -> void:
	# This cannot cancel an earned action or an authoritative pending hit.
	# Stop local processing now; deferred deletion still releases the lease.
	set_process(false)
	_arrived = true
	queue_free()
