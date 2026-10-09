extends RefCounted

## A per-body material pass on the existing fitted mesh. Never adds geometry,
## changes transforms, scales a creature or mutates shared imported materials.
## A bound projection follows the actual body's fitted art and published gear.
## Flag-off until ordinary-view proof.
const GEAR := preload("res://scripts/creatures/creature_gear.gd")
const SHADER := preload("res://scripts/creatures/creature_gear_accent.gdshader")
var _restore: Array[Dictionary] = []
var _projection_body: WeakRef
var _projection_tree: WeakRef
var _published_reader: Callable
var _projection_character := ""
var _projection_uid := ""
var _projection_cfg: Dictionary = {}
var _last_gear: Dictionary = {}
var _last_meshes: Array[String] = []
var _next_refresh_ms := 0

## Actual deployed-body consumer. Its owner supplies a callable reading the
## SAME published personal record (local owner or host admission), never a
## deployment packet, requested stats or a separate gear balance. Weak body
## lifetime + scene-frame subscription follows equip/rejoin/evolution changes.
func bind_projection(body: Node3D, published_reader: Callable,
		character: String, uid: String, cfg: Dictionary = {}) -> bool:
	unbind_projection()
	_projection_cfg = GEAR.config() if cfg.is_empty() else cfg.duplicate(true)
	if not is_instance_valid(body) or not body.is_inside_tree() or not published_reader.is_valid() \
			or character.is_empty() or uid.is_empty() or not body.has_method("model_pivot") \
			or _projection_cfg.get("feature_flags", {}).get("visual_enabled") != true:
		return false
	_projection_body = weakref(body)
	_projection_tree = weakref(body.get_tree())
	_published_reader = published_reader
	_projection_character = character
	_projection_uid = uid
	body.tree_exiting.connect(unbind_projection, CONNECT_ONE_SHOT)
	body.get_tree().process_frame.connect(refresh_projection)
	refresh_projection()
	return true

func unbind_projection() -> void:
	var tree: SceneTree = _projection_tree.get_ref() as SceneTree if _projection_tree != null else null
	if tree != null and tree.process_frame.is_connected(refresh_projection):
		tree.process_frame.disconnect(refresh_projection)
	var body: Node3D = _projection_body.get_ref() as Node3D if _projection_body != null else null
	if is_instance_valid(body) and body.tree_exiting.is_connected(unbind_projection):
		body.tree_exiting.disconnect(unbind_projection)
	clear()
	_projection_body = null
	_projection_tree = null
	_published_reader = Callable()
	_projection_character = ""
	_projection_uid = ""
	_last_gear.clear()
	_last_meshes.clear()
	_next_refresh_ms = 0

func refresh_projection() -> void:
	var body: Node3D = _projection_body.get_ref() as Node3D if _projection_body != null else null
	if not is_instance_valid(body) or not body.is_inside_tree() or not _published_reader.is_valid():
		unbind_projection()
		return
	var now := Time.get_ticks_msec()
	if now < _next_refresh_ms:
		return
	_next_refresh_ms = now + int(_projection_cfg.get("accent", {}).get("refresh_ms", 100))
	var record: Variant = _published_reader.call()
	if not record is Dictionary or record.get("character_id") != _projection_character \
			or not GEAR.personal_errors(record, _projection_cfg).is_empty() \
			or not GEAR._owns(record, _projection_uid):
		clear()
		_last_gear.clear()
		return
	var art: Node3D = body.call("model_pivot") as Node3D
	if art == null or (body.has_method("has_model") and body.call("has_model") != true):
		clear()
		_last_gear.clear()
		return
	var gear := GEAR.gear_for(record, _projection_uid)
	var meshes: Array[MeshInstance3D] = []
	_collect(art, meshes)
	var identities: Array[String] = []
	for mesh: MeshInstance3D in meshes:
		identities.append("%d:%d" % [mesh.get_instance_id(), mesh.mesh.get_instance_id()])
	if gear != _last_gear or identities != _last_meshes or not _installed_matches():
		apply(art, gear, _projection_cfg)
		_last_gear = gear.duplicate(true)
		_last_meshes = identities

func _installed_matches() -> bool:
	for row: Dictionary in _restore:
		if not is_instance_valid(row.get("mesh")) or not row.get("mesh") is MeshInstance3D:
			return false
		var mesh: MeshInstance3D = row.mesh
		if not is_instance_valid(mesh):
			return false
		if int(row.surface) >= 0 and (mesh.mesh == null or int(row.surface) >= mesh.mesh.get_surface_count()):
			return false
		var current := mesh.material_override if int(row.surface) < 0 else mesh.get_surface_override_material(int(row.surface))
		if current != row.applied:
			return false
	return true

func clear() -> void:
	for row: Dictionary in _restore:
		if not is_instance_valid(row.get("mesh")) or not row.get("mesh") is MeshInstance3D:
			continue
		var mesh: MeshInstance3D = row.mesh
		if not is_instance_valid(mesh):
			continue
		if int(row.surface) < 0:
			if mesh.material_override == row.applied:
				mesh.material_override = row.before
		else:
			if mesh.mesh == null or int(row.surface) >= mesh.mesh.get_surface_count():
				continue
			# Shiny/aspect/rest art may replace a material between frames. Preserve
			# that newer writer rather than restoring the earlier unaccented copy.
			if mesh.get_surface_override_material(int(row.surface)) == row.applied:
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
			var copy := _with_pass(before, mesh, body_inverse, bounds, harness, charm, cfg, [gear.harness, gear.charm])
			if copy != null:
				_restore.append({"mesh": mesh, "surface": -1, "before": before, "applied": copy})
				mesh.material_override = copy
			continue
		for surface in mesh.mesh.get_surface_count():
			var source := mesh.get_active_material(surface)
			if source == null:
				continue
			var copy := _with_pass(source, mesh, body_inverse, bounds, harness, charm, cfg, [gear.harness, gear.charm])
			if copy == null:
				continue
			_restore.append({"mesh": mesh, "surface": surface,
				"before": mesh.get_surface_override_material(surface), "applied": copy})
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

## Glow multiplier for one piece: rises with its tier and its upgrade.
static func _glow(id: String, cfg: Dictionary) -> float:
	var item: Dictionary = cfg.get("items", {}).get(id, {})
	if item.is_empty():
		return 1.0
	var accent: Dictionary = cfg.get("accent", {})
	return 1.0 + float(accent.get("tier_emission_step", 0.45)) * (int(item.gear_tier) - 1) \
		+ float(accent.get("upgrade_emission_step", 0.1)) * int(item.get("gear_upgrade", 0))

static func _with_pass(source: Material, mesh: MeshInstance3D, body_inverse: Transform3D,
		bounds: AABB, harness: Color, charm: Color, cfg: Dictionary, gear_ids: Array = ["", ""]) -> Material:
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
	# Higher tiers and upgrades glow brighter, so the colour also reads as rank.
	pass_material.set_shader_parameter("harness_glow", _glow(gear_ids[0], cfg))
	pass_material.set_shader_parameter("charm_glow", _glow(gear_ids[1], cfg))
	for key: String in ["band_center", "band_width", "charm_band_center", "charm_band_width", "emission_energy"]:
		if cfg.get("accent", {}).has(key):
			pass_material.set_shader_parameter(key, cfg.accent[key])
	tail.next_pass = pass_material
	return copy
