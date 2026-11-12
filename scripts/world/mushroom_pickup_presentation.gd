extends RefCounted

## Shared P2-054 presentation for the installed mushroom pickup mesh.
## Stamina retains its texture; Speed is blue; Wild is redder and broader.
const LOOK := {
	"speed_mushroom": {"tint": Color(0.60, 0.72, 1.0), "scale": Vector3.ONE},
	"stamina_mushroom": {"tint": Color(1.0, 1.0, 1.0), "scale": Vector3.ONE},
	"wild_mushroom": {"tint": Color(1.0, 0.62, 0.52), "scale": Vector3(1.30, 0.90, 1.30)},
}
const DRESSED := &"mushroom_pickup_dressed"
const VARIANTS := "res://data/config/mushroom_pickup_variants.json"


static func apply(pickup: Node3D, item_id: String) -> void:
	if not LOOK.has(item_id):
		return
	var mesh := _first_mesh(pickup)
	if mesh != null:
		var look: Dictionary = (LOOK[item_id] as Dictionary).duplicate()
		look["item_id"] = item_id
		look["placement_id"] = str(pickup.get("_placement_id")) if pickup.get("_placement_id") != null else ""
		dress_mesh(mesh, look)


static func dress_mesh(mesh: MeshInstance3D, look: Dictionary) -> void:
	# Meadows also dresses after cache setup. Both consumers may reach the
	# same mesh, but its nonuniform Wild scale must be applied only once.
	if mesh.has_meta(DRESSED):
		return
	var tint: Color = look["tint"]
	if not tint.is_equal_approx(Color.WHITE):
		var source := mesh.get_active_material(0)
		var material: StandardMaterial3D
		if source is StandardMaterial3D:
			material = (source as StandardMaterial3D).duplicate() as StandardMaterial3D
		else:
			material = StandardMaterial3D.new()
		material.albedo_color = tint
		mesh.material_override = material
	var scale: Vector3 = look["scale"]
	if not scale.is_equal_approx(Vector3.ONE):
		mesh.scale = mesh.scale * scale
	mesh.set_meta(DRESSED, true)
	_swap_silhouette(mesh, str(look.get("item_id", "")), str(look.get("placement_id", "")))


## F40#16 P2-054 (NEAR6-CR, flag-off): `mushroom_pickup_variants.json` can
## give a mushroom its own installed model, fitted to the pickup mesh's height
## and footprint, so Speed and Wild stop sharing one silhouette. The original
## mesh stays in the tree (hidden) for interaction and grounding.
static func _swap_silhouette(mesh: MeshInstance3D, item_id: String, placement_id: String = "") -> void:
	if item_id == "":
		return
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(VARIANTS))
	if not parsed is Dictionary:
		return
	var arm: Variant = (parsed as Dictionary).get("natural_cluster_1112", {})
	# `perch_rim_cluster_1112`: the same natural patches, only at the placements
	# it lists (G-below6-mushrooms: the High Perches rim gains, the open finds lose).
	var scoped: Variant = (parsed as Dictionary).get("perch_rim_cluster_1112", {})
	var scoped_here: bool = scoped is Dictionary and bool((scoped as Dictionary).get("enabled", false)) \
		and ((scoped as Dictionary).get("only_placements", []) as Array).has(placement_id)
	if (parsed as Dictionary).get("enabled") != true \
			and not (arm is Dictionary and bool((arm as Dictionary).get("enabled", false))) and not scoped_here:
		return
	var spec: Dictionary = ((parsed as Dictionary).get("items", {}) as Dictionary).get(item_id, {})
	var natural: Variant = (parsed as Dictionary).get("natural_cluster_1112", {})
	if natural is Dictionary and (bool((natural as Dictionary).get("enabled", false)) or scoped_here):
		spec = ((natural as Dictionary).get("items", {}) as Dictionary).get(item_id, spec)
	if not spec.has("scene") or mesh.mesh == null:
		return
	var packed := load(str(spec.get("scene", ""))) as PackedScene
	if packed == null:
		return
	var model := packed.instantiate() as Node3D
	var box := AABB()
	var first := true
	for raw: Node in model.find_children("*", "MeshInstance3D", true, false):
		var part := raw as MeshInstance3D
		var t := Transform3D()
		var walk: Node = part
		while walk != null and walk != model:
			t = (walk as Node3D).transform * t
			walk = walk.get_parent()
		var b := t * part.mesh.get_aabb()
		box = b if first else box.merge(b)
		first = false
	if first or box.size.y <= 0.0:
		model.free()
		return
	var target := mesh.mesh.get_aabb()
	# Fit the larger of height and footprint, so a wide shelf fungus does not
	# outgrow the pickup it replaces.
	var target_extent := maxf(target.size.y, maxf(target.size.x, target.size.z))
	var box_extent := maxf(box.size.y, maxf(box.size.x, box.size.z))
	var factor := target_extent * float(spec.get("height_scale", 1.0)) / box_extent
	var wrapper := Node3D.new()
	wrapper.name = "MushroomVariant"
	wrapper.transform = mesh.transform
	wrapper.rotation.y += deg_to_rad(float(spec.get("yaw_deg", 0.0)))
	model.scale = Vector3.ONE * factor
	model.position = Vector3(target.get_center().x - box.get_center().x * factor,
		target.position.y - box.position.y * factor,
		target.get_center().z - box.get_center().z * factor)
	wrapper.add_child(model)
	_tint(model, spec)
	# natural_cluster (flag-off arm): smaller copies of the same model around the
	# first, each with its own size and turn, so the find reads as a patch that
	# grew there instead of one large cap.
	var index := 0
	for raw: Variant in spec.get("cluster", []):
		if not raw is Dictionary:
			continue
		var extra := raw as Dictionary
		var copy := packed.instantiate() as Node3D
		var k := factor * float(extra.get("size", 0.7))
		var offset: Array = extra.get("offset", [0.0, 0.0])
		var reach := target_extent
		copy.scale = Vector3.ONE * k
		copy.rotation.y = deg_to_rad(float(extra.get("yaw_deg", 70.0 * (index + 1))))
		copy.position = Vector3(target.get_center().x + float(offset[0]) * reach,
			target.position.y - box.position.y * k,
			target.get_center().z + float(offset[1]) * reach)
		wrapper.add_child(copy)
		_tint(copy, spec)
		index += 1
	mesh.get_parent().add_child(wrapper)
	mesh.visible = false


static func _tint(model: Node3D, spec: Dictionary) -> void:
	if not spec.has("tint"):
		return
	var tint := Color(str(spec.get("tint", "#ffffff")))
	for raw: Node in model.find_children("*", "MeshInstance3D", true, false):
		var part := raw as MeshInstance3D
		for surface in part.mesh.get_surface_count():
			var source := part.get_active_material(surface)
			if source is StandardMaterial3D:
				var material := (source as StandardMaterial3D).duplicate() as StandardMaterial3D
				material.albedo_color = material.albedo_color * tint
				part.set_surface_override_material(surface, material)


static func _first_mesh(node: Node) -> MeshInstance3D:
	if node is MeshInstance3D and (node as MeshInstance3D).mesh != null:
		return node as MeshInstance3D
	for child in node.get_children():
		var found := _first_mesh(child)
		if found != null:
			return found
	return null
