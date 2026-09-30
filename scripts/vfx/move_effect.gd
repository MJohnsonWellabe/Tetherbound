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
var _history: Array[Vector3] = []
var _impact: Node3D
var _marker: MeshInstance3D
var _motes: MultiMeshInstance3D
var _mote_positions: Array[Vector3] = []
var _velocities: Array[Vector3] = []
var _rng := RandomNumberGenerator.new()
var _colour: Color
var _audio_launch: AudioStreamPlayer3D
var _audio_impact: AudioStreamPlayer3D

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
		_bodies.append(body)
		for layer: Dictionary in profile.get("layers", []):
			var component := _mesh_node(GEOMETRY.shape(str(layer.get("shape", "orb")), float(_params.size) * float(layer.get("size_scale", 0.5)), layer),
				Color(str(layer.get("colour", _params.colour))), float(layer.get("opacity", 0.8)))
			component.reparent(body, false)
			var offset: Array = layer.get("offset", [0.0, 0.0, 0.0])
			component.position = Vector3(float(offset[0]), float(offset[1]), float(offset[2])) * float(_params.size)
			component.set_meta("spin_rate", float(layer.get("spin_rate", 0.0)))
		if str(profile.shape) == "stone":
			body.scale = Vector3(_rng.randf_range(0.82, 1.14), _rng.randf_range(0.82, 1.14), _rng.randf_range(0.82, 1.14))
			body.rotation = Vector3(_rng.randf() * TAU, _rng.randf() * TAU, _rng.randf() * TAU)
	if str(profile.get("motion", "")) == "sky" or (str(profile.get("motion", "")) == "target" and str(profile.get("shape", "")) == "spike"):
		_marker = _mesh_node(GEOMETRY.shape("sigil", float(_params.size) * float(profile.get("marker_scale", 2.0)), profile), _colour, float(profile.get("marker_opacity", 0.38)))
		_marker.position = _context.get("target_ground", _to)
	for layer in (2 if bool(_row.secondary_trail) else 1):
		var trail := _mesh_node(ImmediateMesh.new(), Color.WHITE, float((_row.trail as Dictionary).get("opacity", 0.78)))
		(trail.material_override as StandardMaterial3D).vertex_color_use_as_albedo = true
		_trails.append(trail)
	_update_bodies(0.0)
	_play_launch()

func _mesh_node(mesh: Mesh, colour: Color, opacity: float = 1.0, lit: bool = false) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.mesh = mesh
	node.material_override = GEOMETRY.material(colour, opacity, lit)
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(node)
	return node

func _process(delta: float) -> void:
	_elapsed += delta
	var t := clampf(_elapsed / maxf(_travel, 0.00001), 0.0, 1.0)
	if not _arrived:
		_update_bodies(t)
		_update_trail()
		if _elapsed >= _travel:
			_arrived = true
			_build_impact()
			_play_impact()
			# Emitted after the contact body exists, never during _ready, so
			# existing launch(...).arrived.connect callers cannot miss it.
			arrived.emit()
			presentation_arrived.emit(_context)
	else:
		_update_trail()
		var duration := float((_row.impact as Dictionary).get("duration", 0.45))
		var u := clampf((_elapsed - _travel) / maxf(duration, 0.001), 0.0, 1.0)
		_update_impact(u, delta)
		for body: MeshInstance3D in _bodies: body.visible = false
		for trail: MeshInstance3D in _trails:
			(trail.material_override as StandardMaterial3D).albedo_color.a = (1.0 - u) * float((_row.trail as Dictionary).get("opacity", 0.78))
		if u >= 1.0: queue_free()

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
		var spread := float(_params.get("spread", 0.0)) * sin(t * PI)
		body.position = front + (side * cos(angle) + Vector3.UP * sin(angle)) * spread
		body.position.y += float(_params.get("arc", 0.0)) * sin(t * PI)
		match mode:
			"sky":
				var marker_fraction := float((_row.body as Dictionary).get("marker_fraction", 0.65))
				body.visible = t >= marker_fraction
				if _marker != null: _marker.visible = not body.visible
				var contact_t := clampf((t - marker_fraction) / maxf(0.001, 1.0 - marker_fraction), 0.0, 1.0)
				var height := float((_row.body as Dictionary).get("sky_height", 6.0))
				var points: Array[Vector3] = []
				var start := _to + Vector3.UP * height
				for k in 9:
					var f := float(k) / 8.0
					points.append(start.lerp(_to, f * contact_t) + side * sin(f * TAU * 3.0) * float(_params.size) * sin(f * PI))
				body.position = Vector3.ZERO
				body.mesh = GEOMETRY.ribbon(points, float(_params.size) * 0.22, _colour)
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
					if _marker != null: _marker.visible = not body.visible
				if str((_row.body as Dictionary).get("shape", "")) == "crescent":
					body.rotation = Vector3(PI * 0.5, angle, t * PI * 0.5)
			"self":
				body.position = _from
				body.rotation.y = angle + t * TAU
			_:
				if str((_row.body as Dictionary).get("shape", "")) in ["shard", "cone", "crescent"]: body.quaternion = Quaternion(Vector3.UP, direction)
		if str((_row.body as Dictionary).get("shape", "")) == "vortex": body.rotation.y = t * TAU
		for component: Node in body.get_children():
			if component is Node3D: component.rotation.y = _elapsed * float(component.get_meta("spin_rate", 0.0))
	if not _bodies.is_empty():
		_history.append(_bodies[0].position if mode not in ["sky", "chain", "beam"] else front)

func _update_trail() -> void:
	var samples := floori(float(BUDGET.allocation(_lease).get("trail", 0)) / float(maxi(1, _trails.size())))
	while _history.size() > maxi(1, samples): _history.pop_front()
	var profile: Dictionary = _row.trail
	for layer in _trails.size():
		var trail := _trails[layer]
		trail.visible = samples >= 2 and _history.size() >= 2
		if trail.visible:
			var colour := _colour.lerp(Color.WHITE, 0.7) if layer == 1 else _colour
			var points: Array[Vector3] = _history.duplicate()
			var style := str(profile.get("style", "air"))
			var amplitude := float(profile.get("wave_amplitude", 0.05)) * float(_params.size)
			var frequency := float(profile.get("wave_frequency", 3.0))
			for i in points.size():
				var f := float(i) / float(maxi(1, points.size() - 1))
				var phase := f * frequency * TAU + _elapsed * float(profile.get("wave_speed", 4.0))
				match style:
					"ion", "tether": points[i].y += signf(sin(phase)) * amplitude * sin(f * PI)
					"flame", "ember": points[i].y += absf(sin(phase)) * amplitude * (1.0 - f)
					"wisp", "ripple", "mote": points[i] += Vector3(cos(phase), sin(phase), 0.0) * amplitude * sin(f * PI)
					"foam", "spray", "bubble": points[i].y += sin(phase) * amplitude
					"dust": points[i].y -= amplitude * (1.0 - f)
					_: points[i].y += sin(phase) * amplitude * sin(f * PI)
			trail.mesh = GEOMETRY.ribbon(points, float(profile.get("width", 0.08)) * float(_params.trail) * (0.48 if layer == 1 else 1.0), colour)

func _build_impact() -> void:
	if _marker != null: _marker.visible = false
	_impact = Node3D.new()
	add_child(_impact)
	_impact.position = _from if str((_row.body as Dictionary).get("motion", "")) == "self" else _to
	var profile: Dictionary = _row.impact
	var scale_factor := float(_params.size) * float(_params.impact_scale)
	var core := _mesh_node(GEOMETRY.shape(str(profile.get("shape", "ring")), scale_factor, profile),
		_colour.lerp(Color.WHITE, float(profile.get("heat", 0.45))), float(profile.get("opacity", 0.82)))
	core.reparent(_impact, false)
	if bool(_row.impact_layer):
		var secondary := _mesh_node(GEOMETRY.shape(str(profile.get("secondary_shape", "ring")), scale_factor * 1.35, profile), _colour, 0.65)
		secondary.reparent(_impact, false)
		secondary.rotation.x = PI * 0.5
	var count := int(BUDGET.allocation(_lease).get("impact", 0))
	if count > 0:
		# One draw call for all manually integrated CPU motes. No GPU-particle
		# fallback dependency and no per-mote Node or material allocations.
		var multimesh := MultiMesh.new()
		multimesh.transform_format = MultiMesh.TRANSFORM_3D
		multimesh.mesh = GEOMETRY.shape(str(profile.get("mote_shape", "orb")), float(profile.get("mote_size", 0.045)))
		multimesh.instance_count = count
		_motes = MultiMeshInstance3D.new()
		_motes.multimesh = multimesh
		_motes.material_override = GEOMETRY.material(_colour, 0.86)
		_motes.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		_impact.add_child(_motes)
	for i in count:
		_mote_positions.append(Vector3.ZERO)
		_motes.multimesh.set_instance_transform(i, Transform3D.IDENTITY)
		var direction := Vector3(_rng.randf_range(-1.0, 1.0), _rng.randf_range(0.2, 1.0), _rng.randf_range(-1.0, 1.0)).normalized()
		_velocities.append(direction * float(profile.get("speed", 3.8)))

func _update_impact(u: float, delta: float) -> void:
	if _impact == null: return
	var profile: Dictionary = _row.impact
	for child: Node in _impact.get_children():
		if child is MeshInstance3D:
			var material := child.material_override as StandardMaterial3D
			material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			material.albedo_color.a = (1.0 - u) * float(profile.get("opacity", 0.82))
	var growth := lerpf(0.35, float(profile.get("grow", 2.0)), u)
	for child: Node in _impact.get_children():
		if child is Node3D and child != _motes: child.scale = Vector3.ONE * growth
	if _motes != null:
		(_motes.material_override as StandardMaterial3D).albedo_color.a = (1.0 - u) * float(profile.get("opacity", 0.82))
	for i in _mote_positions.size():
		_velocities[i].y -= float(profile.get("gravity", 5.0)) * delta
		_mote_positions[i] += _velocities[i] * delta
		_motes.multimesh.set_instance_transform(i, Transform3D(Basis.IDENTITY.scaled(Vector3.ONE * lerpf(1.0, 0.05, u)), _mote_positions[i]))

func _cue(name: String) -> String:
	var sounds: Dictionary = _row.sound
	var id := str(sounds.get(name, ""))
	return str(AUDIO.section("move_effect_cues").get(id, ""))

func _play_launch() -> void:
	var minimum := float((_row.sound as Dictionary).get("travel_min_seconds", 0.18))
	var name := "launch_travel" if _travel >= minimum else "launch"
	if int(_row.mastery_rank) >= 5: name += "_mastery"
	var path := _cue(name)
	if path.is_empty(): return
	_audio_launch = AUDIO.play_file_at(path, str(_row.archetype) + ":" + name, _from, "SFX", float((_row.sound as Dictionary).get("gain_db", -7.0)))

func _play_impact() -> void:
	var name := "impact_mastery" if int(_row.mastery_rank) >= 5 else "impact"
	var path := _cue(name)
	if path.is_empty(): return
	_audio_impact = AUDIO.play_file_at(path, str(_row.archetype) + ":" + name, _to, "SFX", float((_row.sound as Dictionary).get("gain_db", -7.0)))

func _exit_tree() -> void:
	BUDGET.release(_lease)
	# AudioManager owns its pooled players; do not stop a recycled voice here.

func action_id() -> String:
	return str(_context.get("action_id", ""))

func encounter_id() -> String:
	return str(_context.get("encounter_id", "global"))

func cancel_presentation() -> void:
	# This cannot cancel an earned action or an authoritative pending hit.
	# Stop local processing now; deferred deletion still releases the lease.
	set_process(false)
	queue_free()
