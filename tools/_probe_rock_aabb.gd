extends SceneTree
func _init() -> void:
	for name in ["Rock_Medium_1","Rock_Medium_2","Rock_Medium_3"]:
		var path := "res://assets/environment/stylized_nature/%s.gltf" % name
		var ps: PackedScene = load(path)
		if ps == null:
			print("%s: MISSING" % name); continue
		var inst: Node3D = ps.instantiate()
		var aabb := AABB()
		var first := true
		for m in _meshes(inst):
			var a: AABB = (m as MeshInstance3D).get_aabb()
			a = (m as MeshInstance3D).global_transform * a if false else a
			if first: aabb = a; first = false
			else: aabb = aabb.merge(a)
		var r: float = maxf(aabb.size.x, aabb.size.z) * 0.5
		print("%-15s aabb size (%.2f, %.2f, %.2f)  -> visual radius %.2f" % [name, aabb.size.x, aabb.size.y, aabb.size.z, r])
		inst.free()
	quit(0)

func _meshes(n: Node) -> Array:
	var out: Array = []
	if n is MeshInstance3D: out.append(n)
	for c in n.get_children(): out.append_array(_meshes(c))
	return out
