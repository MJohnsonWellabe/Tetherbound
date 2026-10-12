extends "res://scripts/vfx/astra_family_effect.gd"

## Only the eight held/weak families. Accepted family source stays immutable.
const SOFT_MOTE := preload("res://scripts/vfx/astra_soft_mote_r4.gdshader")
var _trail_cloud: MultiMeshInstance3D
var _radii: Array[float] = []

func _ready() -> void:
	super._ready()
	# Actual mesh support bounds include child layers and the crescent's extent.
	for body: MeshInstance3D in _bodies:
		var box := body.mesh.get_aabb()
		var radius := maxf(box.position.length(), box.end.length()) * body.scale.abs()[body.scale.abs().max_axis_index()]
		for child: Node in body.get_children():
			if child is MeshInstance3D:
				var mesh_child := child as MeshInstance3D
				var child_box := mesh_child.mesh.get_aabb()
				radius = maxf(radius, mesh_child.position.length() + maxf(child_box.position.length(), child_box.end.length()))
		_radii.append(radius)
	var multi := MultiMesh.new()
	multi.transform_format = MultiMesh.TRANSFORM_3D
	multi.use_custom_data = true
	var sphere := SphereMesh.new()
	sphere.radius = 1.0
	sphere.height = 2.0
	sphere.radial_segments = 16
	sphere.rings = 8
	multi.mesh = sphere
	multi.instance_count = int(BUDGET.allocation(_lease).get("trail", 0))
	_trail_cloud = MultiMeshInstance3D.new()
	_trail_cloud.multimesh = multi
	var material := ShaderMaterial.new()
	material.shader = SOFT_MOTE
	material.set_shader_parameter("mote_colour", _colour.lerp(Color.WHITE, 0.22))
	material.set_shader_parameter("opacity", 0.72 * _peer_opacity)
	_trail_cloud.material_override = material
	_trail_cloud.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_trail_cloud.set_meta(&"detail_cull_skip", true)
	add_child(_trail_cloud)
	_update_bodies(1.0 if _travel <= 0.0 else 0.0)
	_update_trail()

func _crescent_mesh(size: float) -> ArrayMesh:
	return super._crescent_mesh(maxf(size, float(_row.body.get("min_body_size_m", 0.0))))

func _path(t: float, index: int) -> Vector3:
	var direction := (_to - _from).normalized()
	var side := direction.cross(Vector3.UP).normalized()
	if side.is_zero_approx(): side = Vector3.RIGHT
	var radius := _radii[index] if index < _radii.size() else float(_params.size) * 1.5
	var contact := _impact_visual_origin({"visual_anchor": "contact_surface"})
	# Full mesh stays outside the incoming target surface even on arrival.
	var end := contact - direction * radius
	var body := _bodies[index]
	var support := Transform3D(body.basis, Vector3.ZERO) * body.mesh.get_aabb()
	for child: Node in body.get_children():
		if child is MeshInstance3D:
			var mesh_child := child as MeshInstance3D
			support = support.merge(Transform3D(body.basis, Vector3.ZERO) * mesh_child.transform * mesh_child.mesh.get_aabb())
	var bounds: Dictionary = _context.get("target_visual_bounds", {})
	if bounds.get("position") is Vector3 and bounds.get("size") is Vector3:
		# Minkowski expansion by actual oriented mesh support, including layers.
		var expanded := AABB(bounds.position - support.end, bounds.size + support.size)
		var entry: Variant = expanded.intersects_segment(_from, _to)
		if entry is Vector3: end = entry
	var lane := float(index) - float(_bodies.size() - 1) * 0.5
	var fan := sin(t * PI)
	var point := _from.lerp(end, t) + side * lane * maxf(float(_params.spread), radius * 1.8) * fan
	point.y += float(_params.arc) * fan
	if _family in ["ground_debris", "ground_wave"]:
		var source_ground: Vector3 = _context.get("source_ground", _from)
		var target_ground: Vector3 = _context.get("target_ground", _to)
		point.y = lerpf(_from.y, lerpf(source_ground.y, target_ground.y, t) - support.position.y, smoothstep(0.0, 0.25, t))
	return point

func _update_bodies(t: float) -> void:
	super._update_bodies(t)
	for i in _bodies.size():
		_bodies[i].position = _path(t, i)
		_bodies[i].visible = not _arrived and not _contact_retired
		if _family == "target_orb": _bodies[i].scale = Vector3.ONE
	if _marker != null: _marker.visible = false

func _update_trail() -> void:
	# Replace the tube/ribbon draw, reusing exactly the admitted trail slots.
	for trail: MeshInstance3D in _trails: trail.visible = false
	if _trail_cloud == null: return
	_trail_cloud.visible = not _arrived and not _contact_retired
	if not _trail_cloud.visible: return
	var count := mini(_trail_cloud.multimesh.instance_count, int(BUDGET.allocation(_lease).get("trail", 0)))
	_trail_cloud.multimesh.visible_instance_count = count
	var t := clampf(_elapsed / maxf(_travel, 0.001), 0.0, 1.0)
	var bodies := maxi(1, _bodies.size())
	var span := minf(0.28, float(_params.trail) * 2.0 / maxf(_from.distance_to(_to), 0.001))
	for i in count:
		var index := i % bodies
		var per_body := maxi(1, ceili(float(count - index) / float(bodies)))
		var slot := int(i / bodies)
		var head := 1.0 - float(slot) / float(per_body)
		var sample := maxf(0.0, t - span * (1.0 - head))
		var radius := maxf(0.16, float(_params.size) * 0.75) * lerpf(0.25, 1.0, head)
		_trail_cloud.multimesh.set_instance_transform(i, Transform3D(Basis.IDENTITY.scaled(Vector3.ONE * radius), _path(sample, index)))
		_trail_cloud.multimesh.set_instance_custom_data(i, Color(head * minf(t * 20.0, 1.0), 0, 0, 0))

func _build_impact() -> void:
	super._build_impact()
	if _motes != null and str(_row.impact.get("mote_shape", "")) == "orb":
		var material := ShaderMaterial.new()
		material.shader = SOFT_MOTE
		material.set_shader_parameter("mote_colour", Color(str(_row.impact.mote_colour)))
		material.set_shader_parameter("opacity", 0.9 * _peer_opacity)
		_motes.material_override = material
		for i in _motes.multimesh.instance_count:
			_motes.multimesh.set_instance_custom_data(i, Color(1, 0, 0, 0))
	# Flash and admitted 3D debris carry contact; discard the old expanding card.
	for child: Node in _impact.get_children():
		if child is MeshInstance3D: (child as MeshInstance3D).visible = false
	if _trail_cloud != null: _trail_cloud.visible = false

func cancel_presentation() -> void:
	_retire_contact_drawing()
	for stage: Dictionary in _stages:
		if is_instance_valid(stage.node): (stage.node as Node3D).visible = false
	super.cancel_presentation()

func _retire_contact_drawing() -> void:
	super._retire_contact_drawing()
	if is_instance_valid(_trail_cloud): _trail_cloud.visible = false

func diagnostic_receipt() -> Dictionary:
	var receipt := super.diagnostic_receipt()
	receipt["candidate"] = "astra_final_combined"
	receipt["surface_contact"] = [_impact_visual_origin({"visual_anchor": "contact_surface"}).x,
		_impact_visual_origin({"visual_anchor": "contact_surface"}).y, _impact_visual_origin({"visual_anchor": "contact_surface"}).z]
	receipt["mesh_support_radii"] = _radii.duplicate()
	receipt["trail_instances"] = _trail_cloud.multimesh.visible_instance_count if is_instance_valid(_trail_cloud) and _trail_cloud.visible else 0
	return receipt
