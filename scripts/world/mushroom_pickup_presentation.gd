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
	_swap_silhouette(mesh, str(look.get("item_id", "")))


## F40#16 P2-054 (NEAR6-CR, flag-off): `mushroom_pickup_variants.json` can
## give a mushroom its own installed model, fitted to the pickup mesh's height
## and footprint, so Speed and Wild stop sharing one silhouette. The original
## mesh stays in the tree (hidden) for interaction and grounding.
static func _swap_silhouette(mesh: MeshInstance3D, item_id: String) -> void:
	if item_id == "":
		return
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(VARIANTS))
	if not parsed is Dictionary or (parsed as Dictionary).get("enabled") != true:
		return
	var spec: Dictionary = ((parsed as Dictionary).get("items", {}) as Dictionary).get(item_id, {})
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
	var factor := target.size.y * float(spec.get("height_scale", 1.0)) / box.size.y
	var wrapper := Node3D.new()
	wrapper.name = "MushroomVariant"
	wrapper.transform = mesh.transform
	wrapper.rotation.y += deg_to_rad(float(spec.get("yaw_deg", 0.0)))
	model.scale = Vector3.ONE * factor
	model.position = Vector3(target.get_center().x - box.get_center().x * factor,
		target.position.y - box.position.y * factor,
		target.get_center().z - box.get_center().z * factor)
	wrapper.add_child(model)
	mesh.get_parent().add_child(wrapper)
	mesh.visible = false


static func _first_mesh(node: Node) -> MeshInstance3D:
	if node is MeshInstance3D and (node as MeshInstance3D).mesh != null:
		return node as MeshInstance3D
	for child in node.get_children():
		var found := _first_mesh(child)
		if found != null:
			return found
	return null
