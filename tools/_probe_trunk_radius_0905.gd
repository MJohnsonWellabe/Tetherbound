extends SceneTree
## Real trunk radius of the scatter's tree meshes at scale 1.0: the maximum
## horizontal distance from the model's vertical axis, measured only in the
## lowest 2 m of the mesh (trunk, below the canopy). Decides whether
## vegetation.json's `collision_radius` is inside or outside the actual trunk.
func _init() -> void:
	for path in [
		"res://assets/environment/stylized_nature/CommonTree_1.gltf",
		"res://assets/environment/stylized_nature/CommonTree_2.gltf",
		"res://assets/environment/stylized_nature/CommonTree_3.gltf",
		"res://assets/environment/stylized_nature/TwistedTree_2.gltf",
		"res://assets/environment/stylized_nature/CherryBlossom_3.gltf",
	]:
		var packed: PackedScene = load(path)
		if packed == null:
			print("%s: cannot load" % path); continue
		var node: Node = packed.instantiate()
		var lo := INF
		var verts: Array[Vector3] = []
		var stack: Array[Node] = [node]
		while not stack.is_empty():
			var cur: Node = stack.pop_back()
			var mi := cur as MeshInstance3D
			if mi != null and mi.mesh != null:
				var xf := Transform3D.IDENTITY
				var w: Node = mi
				while w != null and w != node:
					if w is Node3D: xf = (w as Node3D).transform * xf
					w = w.get_parent()
				for s in mi.mesh.get_surface_count():
					var arrays: Array = mi.mesh.surface_get_arrays(s)
					for v: Vector3 in (arrays[Mesh.ARRAY_VERTEX] as PackedVector3Array):
						var p := xf * v
						verts.append(p)
						lo = minf(lo, p.y)
			for c in cur.get_children(): stack.append(c)
		var trunk_r := 0.0
		var n := 0
		for p in verts:
			if p.y - lo <= 2.0:
				trunk_r = maxf(trunk_r, Vector2(p.x, p.z).length())
				n += 1
		print("%-18s trunk radius (lowest 2 m) = %.3f m   [%d verts]" % [
			path.get_file(), trunk_r, n])
		node.free()
	quit(0)
