extends RefCounted

## The kit's exterior braces stay outward-facing. Shallow interior joinery
## gives a placed plaster wall a timber frame without crossing the room.
const WALL_PATH := "res://assets/buildings/quaternius_medieval/Wall_Plaster_Straight.gltf"
const CONFIG_PATH := "res://data/config/build_wall_interior.json"
const PREFIX := "InteriorTimber"


static func apply(model: Node3D, mesh_path: String) -> void:
	if mesh_path != WALL_PATH or model.has_node(NodePath(PREFIX + "LeftStile")):
		return
	var wall := model.find_child("Wall_Plaster_Straight", true, false) as MeshInstance3D
	if model is MeshInstance3D and model.name == "Wall_Plaster_Straight":
		wall = model as MeshInstance3D
	if wall == null or wall.mesh == null:
		return
	var wood: StandardMaterial3D = null
	for surface: int in wall.mesh.get_surface_count():
		var material := wall.get_active_material(surface) as StandardMaterial3D
		if material != null and material.resource_name == "MI_WoodTrim":
			wood = material.duplicate() as StandardMaterial3D
			break
	if wood == null:
		return
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(CONFIG_PATH))
	if not parsed is Dictionary:
		push_error("Placed wall interior config is invalid")
		return
	# The imported module has no nested transform. Keep new meshes directly
	# under the model so BuildPiece's bounds and recursive ghost tint see them.
	var bounds: AABB = wall.transform * wall.mesh.get_aabb()
	for part: Dictionary in parsed.get("parts", []):
		var size := _vec(part.size)
		var requested := AABB(_vec(part.position) - size * 0.5, size)
		var inside := requested.intersection(bounds)
		if inside.size.x <= 0.0 or inside.size.y <= 0.0 or inside.size.z <= 0.0:
			continue
		var mesh := BoxMesh.new()
		mesh.size = inside.size
		mesh.material = wood
		var beam := MeshInstance3D.new()
		beam.name = PREFIX + str(part.name)
		beam.mesh = mesh
		beam.position = inside.get_center()
		model.add_child(beam)


static func _vec(values: Array) -> Vector3:
	return Vector3(float(values[0]), float(values[1]), float(values[2]))
