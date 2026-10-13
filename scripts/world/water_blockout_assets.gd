extends RefCounted
## Static installed mesh copies only. Never instantiate gameplay or collision.
const BOUNDS := preload("res://scripts/characters/render_bounds.gd")

static func piece(path: String, size: Vector3) -> Node3D:
	var packed := load(path) as PackedScene
	if packed == null:
		push_error("Water blockout installed asset missing: " + path)
		return null
	var source := packed.instantiate() as Node3D
	var result := Node3D.new()
	_copy_meshes(source, result, Transform3D.IDENTITY)
	source.free()
	var bounds := BOUNDS.measure(result)
	if bounds.size.x <= 0.0 or bounds.size.y <= 0.0 or bounds.size.z <= 0.0:
		result.free()
		return null
	var factor := size / bounds.size
	var offset := Vector3(bounds.get_center().x, bounds.position.y, bounds.get_center().z)
	for child: Node3D in result.get_children():
		child.transform = Transform3D(Basis.from_scale(factor), -offset * factor) * child.transform
	preload("res://scripts/world/tidewake_material_family.gd").prop(result, "stone")
	return result

static func _copy_meshes(source: Node3D, target: Node3D, inherited: Transform3D) -> void:
	var pose := inherited * source.transform
	if source is MeshInstance3D and source.mesh != null:
		var mesh := MeshInstance3D.new()
		mesh.mesh = source.mesh
		mesh.transform = pose
		mesh.material_override = source.material_override
		for surface in source.mesh.get_surface_count():
			mesh.set_surface_override_material(surface, source.get_surface_override_material(surface))
		target.add_child(mesh)
	for child: Node in source.get_children():
		if child is Node3D:
			_copy_meshes(child, target, pose)
