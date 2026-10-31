extends RefCounted

## World dressing (P2-033 / P2-045 / P2-054; OFF until GPU judged). The GPU
## item judges read one-time finds as "pinhead-sized", "small, weakly grounded
## props on flat grass" and "unreadable at gameplay distance". Per realm and
## per item, from data/config/pickup_grounding.json:
##   * `scale`: a uniform size step on the find's own visual;
##   * `shadow_m`: a soft radial contact shadow under it;
##   * `stone`: a half-sunk flat stone from the installed rock-path family the
##     find rests on, so it reads as set down on purpose rather than lost in
##     the carpet (candies, potions, orbs; never mushrooms, which grow);
##   * `pebbles`: a few installed pebbles round its foot.
## Children of the pickup, visual only: no collider, claim, glow, flag or save
## change, and they free with the pickup when it is taken. Deterministic per
## placement so every peer builds the same dressing.
const CONFIG := "res://data/config/pickup_grounding.json"
const APPLIED := &"pickup_grounding_applied"

static var _cfg: Dictionary = {}
static var _loaded := false


static func config() -> Dictionary:
	if not _loaded:
		_loaded = true
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(CONFIG))
		_cfg = parsed if parsed is Dictionary else {}
	return _cfg


static func spec_for(item_id: String, realm: String) -> Dictionary:
	var cfg := config()
	if not bool(cfg.get("enabled", false)):
		return {}
	var realm_cfg: Dictionary = (cfg.get("realms", {}) as Dictionary).get(realm, {})
	if realm_cfg.is_empty():
		return {}
	var families: Dictionary = cfg.get("families", {})
	for family: String in families:
		if item_id in ((families[family] as Dictionary).get("items", []) as Array):
			# A realm dresses only the families it lists.
			if not realm_cfg.has(family):
				return {}
			var merged: Dictionary = (families[family] as Dictionary).duplicate(true)
			var per_realm: Dictionary = (realm_cfg.get(family, {}) as Dictionary)
			for key: String in per_realm:
				merged[key] = per_realm[key]
			return merged
	return {}


static func apply(pickup: Node3D, visual: Node3D, item_id: String, realm: String, placement_id: String = "") -> void:
	if pickup == null or visual == null or pickup.has_meta(APPLIED):
		return
	var spec := spec_for(item_id, realm)
	if spec.is_empty():
		return
	pickup.set_meta(APPLIED, true)
	var seed_value := absi((placement_id if not placement_id.is_empty() else item_id).hash()) % 9973
	var scale := float(spec.get("scale", 1.0))
	if not is_equal_approx(scale, 1.0):
		visual.scale *= scale
	var root := Node3D.new()
	root.name = "PickupGrounding"
	pickup.add_child(root)
	var stone_cfg: Dictionary = spec.get("stone", {})
	var stone_top := 0.0
	if not stone_cfg.is_empty():
		stone_top = _stone(root, stone_cfg, seed_value)
		if stone_top > 0.0:
			visual.position.y += stone_top
	var shadow_m := float(spec.get("shadow_m", 0.0))
	if shadow_m > 0.0:
		root.add_child(_shadow(shadow_m, float(spec.get("shadow_alpha", 0.5)), stone_top + 0.015))
	var pebbles: Dictionary = spec.get("pebbles", {})
	if not pebbles.is_empty():
		_pebbles(root, pebbles, seed_value)


static func _stone(root: Node3D, cfg: Dictionary, seed_value: int) -> float:
	var models: Array = cfg.get("models", [])
	if models.is_empty():
		return 0.0
	var parts := _flat_meshes(str(models[seed_value % models.size()]))
	if parts.is_empty():
		return 0.0
	var src: AABB = parts[0].aabb
	var across := float(cfg.get("across_m", 0.9))
	var height := float(cfg.get("height_m", 0.16))
	var exposed := float(cfg.get("exposed_m", 0.07))
	var basis := Basis(Vector3.UP, float(seed_value % 360) * PI / 180.0) * Basis.from_scale(Vector3(
		across / maxf(src.size.x, 0.001), height / maxf(src.size.y, 0.001), across / maxf(src.size.z, 0.001)))
	var origin := Vector3(0.0, exposed - height, 0.0) - basis * Vector3(src.get_center().x, src.position.y, src.get_center().z)
	var tint := Color(str(cfg.get("tint", "#ffffff")))
	for entry: Dictionary in parts:
		var mesh_node := MeshInstance3D.new()
		mesh_node.name = "FindStone"
		mesh_node.mesh = entry.mesh
		mesh_node.transform = Transform3D(basis, origin) * (entry.local as Transform3D)
		_tint(mesh_node, tint)
		root.add_child(mesh_node)
	return exposed


static func _pebbles(root: Node3D, cfg: Dictionary, seed_value: int) -> void:
	var models: Array = cfg.get("models", [])
	var count := int(cfg.get("count", 3))
	if models.is_empty() or count <= 0:
		return
	var ring := float(cfg.get("ring_m", 0.55))
	var size := float(cfg.get("size_m", 0.14))
	var tint := Color(str(cfg.get("tint", "#ffffff")))
	for index in count:
		var parts := _flat_meshes(str(models[(seed_value + index) % models.size()]))
		if parts.is_empty():
			continue
		var src: AABB = parts[0].aabb
		var angle := TAU * float(index) / float(count) + float(seed_value % 628) * 0.01
		var r := ring * (0.8 + 0.4 * float((seed_value + index * 13) % 7) / 6.0)
		var k := size * (0.7 + 0.6 * float((seed_value + index * 5) % 5) / 4.0) / maxf(maxf(src.size.x, src.size.z), 0.001)
		var basis := Basis(Vector3.UP, angle * 2.1) * Basis.from_scale(Vector3.ONE * k)
		var at := Vector3(cos(angle) * r, -src.size.y * k * 0.35, sin(angle) * r)
		for entry: Dictionary in parts:
			var mesh_node := MeshInstance3D.new()
			mesh_node.name = "FindPebble%d" % index
			mesh_node.mesh = entry.mesh
			mesh_node.transform = Transform3D(basis, at - basis * Vector3(src.get_center().x, src.position.y, src.get_center().z)) * (entry.local as Transform3D)
			mesh_node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			_tint(mesh_node, tint)
			root.add_child(mesh_node)


static func _shadow(size_m: float, alpha: float, lift: float) -> MeshInstance3D:
	var gradient := Gradient.new()
	gradient.set_color(0, Color(0, 0, 0, alpha))
	gradient.set_color(1, Color(0, 0, 0, 0))
	var falloff := GradientTexture2D.new()
	falloff.gradient = gradient
	falloff.fill = GradientTexture2D.FILL_RADIAL
	falloff.fill_from = Vector2(0.5, 0.5)
	falloff.fill_to = Vector2(1.0, 0.5)
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_texture = falloff
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	var plane := PlaneMesh.new()
	plane.size = Vector2(size_m, size_m)
	plane.material = material
	var shadow := MeshInstance3D.new()
	shadow.name = "FindShadow"
	shadow.mesh = plane
	shadow.position.y = lift
	shadow.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return shadow


static func _tint(mesh_node: MeshInstance3D, tint: Color) -> void:
	if tint == Color.WHITE or mesh_node.mesh == null:
		return
	for surface in mesh_node.mesh.get_surface_count():
		var source := mesh_node.mesh.surface_get_material(surface) as BaseMaterial3D
		if source != null:
			var tinted := source.duplicate() as BaseMaterial3D
			tinted.albedo_color = source.albedo_color * tint
			mesh_node.set_surface_override_material(surface, tinted)


## Every MeshInstance3D in an installed scene, with its transform relative to
## the scene root and the scene's combined bounds in that root's space.
static func _flat_meshes(path: String) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	if not ResourceLoader.exists(path):
		return out
	var scene := load(path) as PackedScene
	if scene == null:
		return out
	var root := scene.instantiate() as Node3D
	var meshes: Array[Node] = root.find_children("*", "MeshInstance3D", true, false)
	if root is MeshInstance3D:
		meshes.append(root)
	var combined := AABB()
	var first := true
	for node: Node in meshes:
		var mesh_node := node as MeshInstance3D
		if mesh_node.mesh == null:
			continue
		var local := Transform3D()
		var walk: Node = mesh_node
		while walk != null and walk != root:
			local = (walk as Node3D).transform * local
			walk = walk.get_parent()
		var box: AABB = local * mesh_node.mesh.get_aabb()
		combined = box if first else combined.merge(box)
		first = false
		out.append({"mesh": mesh_node.mesh, "local": local})
	for entry: Dictionary in out:
		entry["aabb"] = combined
	root.free()
	return out
