extends "res://scripts/vfx/move_effect.gd"

## Partial-GO families only. Profiles change local drawing, never the accepted
## parameters, mastery, sound, budget, arrival, action or gameplay contracts.
const ROUND := preload("res://scripts/vfx/astra_geometry_r2.gd")
const VOLUME := preload("res://scripts/vfx/astra_effect_geometry.gd")
const CRESCENT := preload("res://scripts/vfx/astra_crescent_surface.gdshader")
var tuning: Dictionary = {}
var _style: Dictionary = {}
var _family := ""

func configure(from: Vector3, to: Vector3, row: Dictionary, context: Dictionary,
		travel: float, config: Dictionary) -> void:
	_style = (tuning.profiles as Dictionary).get(str(row.archetype), {}).duplicate(true)
	_family = str(_style.get("family", ""))
	var drawing := row.duplicate(true)
	for part: String in ["body", "impact"]:
		for key: String in _style.get(part, {}): drawing[part][key] = _style[part][key]
	super.configure(from, to, drawing, context, travel, config)
	if _style.has("tint"): _colour = _colour.lerp(Color(str(_style.tint)), float(_style.get("tint_mix", 0.0)))

func _ready() -> void:
	super._ready()
	for body: MeshInstance3D in _bodies:
		if _family == "crescent":
			body.mesh = _crescent_mesh(float(_params.size))
			body.material_override = _crescent_material()
		elif _family == "wind_orb": body.scale = Vector3(0.8, 1.35, 0.8)
		# Round foam crests use the accepted bubble's broad film and rim.
		if _family == "wave_projectile":
			for child: Node in body.get_children():
				if child is MeshInstance3D:
					(child as MeshInstance3D).material_override = _presentation_material(GEOMETRY.authored_material("bubble",
						{"opacity": 1.65, "center_opacity": 0.15, "rim_power": 0.5}, _colour.lerp(Color.WHITE, 0.35)))
	for trail: MeshInstance3D in _trails:
		trail.material_override = _presentation_material(VOLUME.surface(_colour.lerp(Color.WHITE, 0.25), float(tuning.trail_opacity)))

func _crescent_mesh(size: float) -> ArrayMesh:
	var points: Array[Vector3] = []
	for k in 33:
		var f := float(k) / 32.0
		points.append(Vector3(sin(f * PI) * size * 0.55, (f - 0.5) * size * 2.0, (f - 0.5) * size * 0.5))
	# Accepted crescent volume, thickened for bright-horizon readability.
	return VOLUME.tube(points, size * float(tuning.crescent_radius_scale), 12, true)

func _crescent_material() -> Material:
	var material := ShaderMaterial.new()
	material.shader = CRESCENT
	material.set_shader_parameter("blade_colour", _colour)
	material.set_shader_parameter("opacity", 1.0)
	return _presentation_material(material)

func _path(t: float, index: int) -> Vector3:
	if _family == "crescent":
		var direction := (_to - _from).normalized()
		var side := direction.cross(Vector3.UP).normalized()
		if side.is_zero_approx(): side = Vector3.RIGHT
		var lane := float(index) - float(_bodies.size() - 1) * 0.5
		return _from.lerp(_impact_visual_origin({"visual_anchor": "contact_surface"}), t) \
			+ side * lane * float(_params.spread) * sin(t * PI) + Vector3.UP * float(_params.arc) * sin(t * PI)
	if str(_row.body.motion) == "radial":
		var direction := (_to - _from).normalized()
		var side := direction.cross(Vector3.UP).normalized()
		var angle := TAU * float(index) / float(maxi(1, _bodies.size()))
		return _from + (direction * cos(angle) + side * sin(angle)) * _from.distance_to(_to) * t \
			+ Vector3.UP * float(_params.arc) * sin(t * PI)
	var point := _projectile_position(t, index)
	if _family == "psychic_orb": point -= (_to - _impact_visual_origin({"visual_anchor": "contact_surface"})) * t
	if _family == "wave_projectile":
		var ground: Vector3 = _context.get("target_ground", _to)
		point.y = ground.y + float(_params.size) * 0.05
	return point

func _update_bodies(t: float) -> void:
	super._update_bodies(t)
	for i in _bodies.size():
		var body := _bodies[i]
		if _family == "crescent":
			body.position = _path(t, i)
			body.scale = Vector3.ONE
			var direction := (_to - _from).normalized()
			body.quaternion = Quaternion(Vector3.FORWARD, direction if not direction.is_zero_approx() else Vector3.FORWARD)
		elif _family == "ground_wave":
			var ground: Vector3 = _context.get("source_ground", _from)
			body.position.y = ground.y + float(_row.body.width) + 0.02
		elif _family == "target_orb":
			body.position = _impact_visual_origin({"visual_anchor": "contact_surface"})
			body.scale = Vector3.ONE * lerpf(0.35, 1.0, t)
		elif _family == "psychic_orb": body.position = _path(t, i)

func _update_trail() -> void:
	var samples := mini(32, floori(float(BUDGET.allocation(_lease).get("trail", 0)) / float(maxi(1, _trails.size()))))
	var travelling := str(_row.body.motion) in ["projectile", "radial"] or _family == "crescent"
	var progress := 1.0 if _travel <= 0.0 else clampf(_elapsed / _travel, 0.0, 1.0)
	var span := float(_params.trail) * 2.4 / maxf(_from.distance_to(_to), 0.001)
	for trail: MeshInstance3D in _trails:
		trail.visible = travelling and not _arrived and not _contact_retired and samples >= 2 and progress > 0.0
		if not trail.visible: continue
		var points: Array[Vector3] = []
		for k in samples:
			points.append(_path(lerpf(maxf(0.0, progress - span), progress, float(k) / float(samples - 1)), int(trail.get_meta("body_index", 0))))
		var radius := float(_params.size) * float(_style.get("trail_radius_scale", tuning.trail_radius_scale)) * sqrt(float(_params.trail))
		if int(trail.get_meta("layer", 0)) > 0: radius *= 0.5
		trail.mesh = ROUND.tube(points, radius, 8, true)

func _build_impact() -> void:
	super._build_impact()
	for trail: MeshInstance3D in _trails: trail.visible = false
	if _family == "crescent":
		# Cut-shaped contact plus the existing admitted spark burst; no bubble
		# core or droplet circle for the optional slash revision.
		for child: Node in _impact.get_children():
			if child is MeshInstance3D:
				var cut := child as MeshInstance3D
				cut.mesh = _crescent_mesh(float(_params.size) * float(_params.impact_scale))
				cut.material_override = _crescent_material()
				var direction := (_to - _from).normalized()
				cut.quaternion = Quaternion(Vector3.FORWARD, direction if not direction.is_zero_approx() else Vector3.FORWARD)

func diagnostic_receipt() -> Dictionary:
	return {"candidate": "astra_approved_families", "archetype": str(_row.archetype), "family": _family,
		"arrived": _arrived, "travel_seconds": _travel, "elapsed": _elapsed,
		"contact_retired": _contact_retired, "lease": BUDGET.allocation(_lease),
		"resolved_parameters": _params.duplicate(true), "local_body_motion": str(_row.body.motion)}
