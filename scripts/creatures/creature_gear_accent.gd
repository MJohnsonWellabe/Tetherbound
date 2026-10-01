extends RefCounted

## A per-body material pass on the existing fitted mesh. Never adds geometry,
## changes transforms, scales a creature or mutates shared imported materials.
## CreatureBody must clear BEFORE replacing/freeing art and apply AFTER fit,
## shiny/aspect/brightness material changes. Flag-off until ordinary-view proof.
const GEAR := preload("res://scripts/creatures/creature_gear.gd")
const SHADER := preload("res://scripts/creatures/creature_gear_accent.gdshader")
var _restore: Array[Dictionary] = []

func clear() -> void:
	for row: Dictionary in _restore:
		var mesh: MeshInstance3D = row.mesh
		if not is_instance_valid(mesh):
			continue
		if int(row.surface) < 0:
			mesh.material_override = row.before
		else:
			mesh.set_surface_override_material(int(row.surface), row.before)
	_restore.clear()

func apply(body_art: Node3D, gear: Dictionary, cfg: Dictionary) -> bool:
	clear()
	if body_art == null or not body_art.is_inside_tree() \
			or not bool(cfg.get("feature_flags", {}).get("visual_enabled", false)) \
			or not GEAR.slots_errors(gear, cfg).is_empty():
		return false
	var meshes: Array[MeshInstance3D] = []
	_collect(body_art, meshes)
	if meshes.is_empty():
		return false
	var bounds := AABB()
	var first := true
	var body_inverse := body_art.global_transform.affine_inverse()
	for mesh: MeshInstance3D in meshes:
		var local_bounds: AABB = (body_inverse * mesh.global_transform) * mesh.get_aabb()
		bounds = local_bounds if first else bounds.merge(local_bounds)
		first = false
	if bounds.size.y <= 0.001:
		return false
	var harness := _color(gear.harness, cfg)
	var charm := _color(gear.charm, cfg)
	if harness.a == 0.0 and charm.a == 0.0:
		return false
	for mesh: MeshInstance3D in meshes:
		if mesh.material_override != null:
			var before := mesh.material_override
			var copy := _with_pass(before, mesh, body_inverse, bounds, harness, charm, cfg)
			if copy != null:
				_restore.append({"mesh": mesh, "surface": -1, "before": before})
				mesh.material_override = copy
			continue
		for surface in mesh.mesh.get_surface_count():
			var source := mesh.get_active_material(surface)
			if source == null:
				continue
			var copy := _with_pass(source, mesh, body_inverse, bounds, harness, charm, cfg)
			if copy == null:
				continue
			_restore.append({"mesh": mesh, "surface": surface,
				"before": mesh.get_surface_override_material(surface)})
			mesh.set_surface_override_material(surface, copy)
	return not _restore.is_empty()

static func _collect(node: Node, meshes: Array[MeshInstance3D]) -> void:
	if node is MeshInstance3D and node.mesh != null \
			and not node.name.to_lower().contains("shadow"):
		meshes.append(node)
	for child: Node in node.get_children():
		_collect(child, meshes)

static func _color(id: String, cfg: Dictionary) -> Color:
	var item: Dictionary = cfg.get("items", {}).get(id, {})
	if item.is_empty():
		return Color(0.0, 0.0, 0.0, 0.0)
	var tier: Dictionary = cfg.tiers[int(item.gear_tier) - 1]
	var raw: Array = tier.get("color", [0.0, 0.0, 0.0, 0.0])
	return Color(float(raw[0]), float(raw[1]), float(raw[2]), float(raw[3]))

static func _with_pass(source: Material, mesh: MeshInstance3D, body_inverse: Transform3D,
		bounds: AABB, harness: Color, charm: Color, cfg: Dictionary) -> Material:
	# Transparent faces/eyes keep their original alpha; don't paint invisible
	# cards or contact shadows into opaque body trim.
	if source is BaseMaterial3D and source.transparency != BaseMaterial3D.TRANSPARENCY_DISABLED:
		return null
	var copy := source.duplicate(true) as Material
	var tail := copy
	var depth := 0
	while tail.next_pass != null:
		depth += 1
		if depth > 8:
			return null
		tail = tail.next_pass
	var pass_material := ShaderMaterial.new()
	pass_material.shader = SHADER
	pass_material.set_shader_parameter("harness_color", harness)
	pass_material.set_shader_parameter("charm_color", charm)
	pass_material.set_shader_parameter("mesh_to_body", body_inverse * mesh.global_transform)
	pass_material.set_shader_parameter("body_min_y", bounds.position.y)
	pass_material.set_shader_parameter("body_height", bounds.size.y)
	for key: String in ["band_center", "band_width", "charm_band_center", "charm_band_width", "emission_energy"]:
		if cfg.get("accent", {}).has(key):
			pass_material.set_shader_parameter(key, cfg.accent[key])
	tail.next_pass = pass_material
	return copy
