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
	# F38 P2-094 (OFF): a placed wall read as a featureless cream rectangle.
	# The Meshy timber-and-plaster segment takes the kit wall's exact bounds,
	# so grid tiling and the derived collider are unchanged.
	var hero: Dictionary = parsed.get("meshy_wall", {})
	if bool(hero.get("enabled", false)) and _hero_wall(model, wall, bounds, str(hero.get("model", ""))):
		return
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


static func _hero_wall(model: Node3D, wall: MeshInstance3D, bounds: AABB, path: String) -> bool:
	var packed := load(path) as PackedScene
	if packed == null:
		return false
	var hero := packed.instantiate() as Node3D
	var box := AABB()
	var first := true
	var meshes: Array[MeshInstance3D] = []
	for raw: Node in hero.find_children("*", "MeshInstance3D", true, false):
		var mesh := raw as MeshInstance3D
		var b := mesh.transform * mesh.mesh.get_aabb()
		box = b if first else box.merge(b)
		first = false
		meshes.append(mesh)
	if first:
		hero.free()
		return false
	# Flatten the hero's meshes directly under the model (BuildPiece reads
	# only direct and nested MeshInstance3D transforms relative to the model).
	var fit := Transform3D(Basis.from_scale(Vector3(bounds.size.x / box.size.x, bounds.size.y / box.size.y,
		bounds.size.z / box.size.z)), Vector3.ZERO)
	fit.origin = bounds.position - fit.basis * box.position
	for mesh: MeshInstance3D in meshes:
		var placed := MeshInstance3D.new()
		placed.name = PREFIX + "Hero" + str(mesh.name)
		placed.mesh = mesh.mesh
		placed.transform = fit * mesh.transform
		model.add_child(placed)
	hero.free()
	wall.visible = false
	return true


static func _vec(values: Array) -> Vector3:
	return Vector3(float(values[0]), float(values[1]), float(values[2]))
