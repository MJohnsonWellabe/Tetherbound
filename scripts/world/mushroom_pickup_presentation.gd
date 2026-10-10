extends RefCounted

## Shared P2-054 presentation for the installed mushroom pickup mesh.
## Stamina retains its texture; Speed is blue; Wild is redder and broader.
const LOOK := {
	"speed_mushroom": {"tint": Color(0.60, 0.72, 1.0), "scale": Vector3.ONE},
	"stamina_mushroom": {"tint": Color(1.0, 1.0, 1.0), "scale": Vector3.ONE},
	"wild_mushroom": {"tint": Color(1.0, 0.62, 0.52), "scale": Vector3(1.30, 0.90, 1.30)},
}
const DRESSED := &"mushroom_pickup_dressed"


static func apply(pickup: Node3D, item_id: String) -> void:
	if not LOOK.has(item_id):
		return
	var mesh := _first_mesh(pickup)
	if mesh != null:
		dress_mesh(mesh, LOOK[item_id])


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


static func _first_mesh(node: Node) -> MeshInstance3D:
	if node is MeshInstance3D and (node as MeshInstance3D).mesh != null:
		return node as MeshInstance3D
	for child in node.get_children():
		var found := _first_mesh(child)
		if found != null:
			return found
	return null
