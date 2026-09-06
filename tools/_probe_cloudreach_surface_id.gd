extends SceneTree
## What IS the ground under a point: which MeshInstance3D draws it, which
## material, and which key that material has in cloudreach_world's _materials.

const SCENE := preload("res://scenes/world/cloudreach_cliffs.tscn")
const POINTS := {
	"05 stand": Vector3(-400.0, 830.0, 3890.0),
	"05 in front": Vector3(-380.0, 830.0, 3910.0),
	"01 stand": Vector3(0.0, 150.0, -260.0),
}


func _initialize() -> void:
	var world: Node3D = SCENE.instantiate()
	root.add_child(world)
	await process_frame
	await process_frame
	var runtime: Node = _find_with(world, "config_data")
	var materials: Dictionary = runtime.get("_materials") if runtime != null else {}
	var by_id := {}
	for key: Variant in materials.keys():
		var m: Variant = materials[key]
		if m is Resource:
			by_id[(m as Resource).get_instance_id()] = str(key)
	var meshes: Array = []
	_collect(world, meshes)
	print("mesh instances: %d, world materials: %d" % [meshes.size(), materials.size()])
	for label: String in POINTS.keys():
		var at: Vector3 = POINTS[label]
		print("\n=== %s at %s ===" % [label, str(at)])
		var hits := 0
		for raw: Variant in meshes:
			var mi: MeshInstance3D = raw
			if mi.mesh == null:
				continue
			var aabb := mi.global_transform * mi.get_aabb()
			if at.x < aabb.position.x or at.x > aabb.end.x:
				continue
			if at.z < aabb.position.z or at.z > aabb.end.z:
				continue
			if aabb.end.y < at.y - 80.0 or aabb.position.y > at.y + 80.0:
				continue
			hits += 1
			if hits > 14:
				continue
			var names: Array = []
			for surface in mi.mesh.get_surface_count():
				var m: Material = mi.get_surface_override_material(surface)
				if m == null:
					m = mi.mesh.surface_get_material(surface)
				var key := "(none)"
				if m != null:
					key = str(by_id.get(m.get_instance_id(), "NOT-IN-_materials:" + m.get_class()))
				names.append(key)
			print("  %-42s parent=%-26s y=[%.1f..%.1f] materials=%s"
				% [mi.name, str(mi.get_parent().name), aabb.position.y, aabb.end.y, str(names)])
		print("  (%d mesh instances overlap this point)" % hits)
	quit(0)


func _collect(node: Node, out: Array) -> void:
	if node is MeshInstance3D:
		out.append(node)
	for child in node.get_children():
		_collect(child, out)


func _find_with(node: Node, method: String) -> Node:
	if node.has_method(method):
		return node
	for child in node.get_children():
		var found := _find_with(child, method)
		if found != null:
			return found
	return null
