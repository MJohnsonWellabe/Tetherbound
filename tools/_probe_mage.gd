extends SceneTree

func _init() -> void:
	for path in ["res://assets/characters/mage.glb", "res://assets/characters/knight.glb", "res://assets/characters/dwarf.glb"]:
		var node: Node = (load(path) as PackedScene).instantiate()
		print("== %s" % path)
		var lo := INF
		var hi := -INF
		for m in _meshes(node):
			var box: AABB = m.get_aabb()
			lo = minf(lo, box.position.y)
			hi = maxf(hi, box.position.y + box.size.y)
			for s in m.mesh.get_surface_count():
				var mat: Material = m.mesh.surface_get_material(s)
				print("   mesh %-24s surface %d  material '%s' (%s)" % [
					m.name, s, "null" if mat == null else mat.resource_name,
					"null" if mat == null else mat.get_class()])
		print("   height %.3f" % (hi - lo))
		var sk := _skel(node)
		if sk != null:
			print("   bones %d" % sk.get_bone_count())
	quit()

func _meshes(n: Node) -> Array:
	var out := []
	if n is MeshInstance3D and (n as MeshInstance3D).mesh != null:
		out.append(n)
	for c in n.get_children():
		out.append_array(_meshes(c))
	return out

func _skel(n: Node) -> Skeleton3D:
	if n is Skeleton3D:
		return n
	for c in n.get_children():
		var f := _skel(c)
		if f != null:
			return f
	return null
