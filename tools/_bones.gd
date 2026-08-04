extends SceneTree

## Throwaway rig probe. The paths and questions change with whatever asset is
## being fitted; it stays in the tree because every retarget starts by finding
## out what the two rigs actually say, and guessing costs a whole round.

const KNIGHT := "res://assets/characters/knight.glb"


func _init() -> void:
	var knight: Node = (load(KNIGHT) as PackedScene).instantiate()
	root.add_child(knight)
	for m in knight.find_children("*", "MeshInstance3D", true, false):
		var mesh := m as MeshInstance3D
		if mesh.mesh == null:
			continue
		print("%s: %d surfaces" % [mesh.name, mesh.mesh.get_surface_count()])
		for i in mesh.mesh.get_surface_count():
			var mat: Material = mesh.mesh.surface_get_material(i)
			var pts: PackedVector3Array = mesh.mesh.surface_get_arrays(i)[Mesh.ARRAY_VERTEX]
			var box := AABB(pts[0], Vector3.ZERO)
			for v in pts:
				box = box.expand(v)
			print("  %d  %-14s verts=%d  x %+.2f..%+.2f  y %+.2f..%+.2f" % [
				i, mat.resource_name if mat else "<none>", pts.size(),
				box.position.x, box.position.x + box.size.x,
				box.position.y, box.position.y + box.size.y
			])
	quit(0)
