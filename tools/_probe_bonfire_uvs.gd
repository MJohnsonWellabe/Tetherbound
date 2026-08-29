extends SceneTree
## T1-CAST scratch: measure Bonfire_Fire.obj's own UV bounding box per
## surface, so a texture tile scale can be chosen from real numbers instead
## of guessed.
const MESH_PATH := "res://assets/props/quaternius_survival/Bonfire_Fire.obj"


func _init() -> void:
	var mesh: Mesh = load(MESH_PATH)
	for i in mesh.get_surface_count():
		var surf_name: String = mesh.surface_get_name(i)
		var arrays := mesh.surface_get_arrays(i)
		var uvs: PackedVector2Array = arrays[Mesh.ARRAY_TEX_UV]
		var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var min_uv := Vector2(INF, INF)
		var max_uv := Vector2(-INF, -INF)
		for uv in uvs:
			min_uv = Vector2(minf(min_uv.x, uv.x), minf(min_uv.y, uv.y))
			max_uv = Vector2(maxf(max_uv.x, uv.x), maxf(max_uv.y, uv.y))
		var aabb := AABB()
		var first := true
		for v in verts:
			if first:
				aabb.position = v
				first = false
			else:
				aabb = aabb.expand(v)
		print("surface %d (%s): %d verts, UV range %s..%s (span %s), local AABB size %s" % [
			i, surf_name, verts.size(), str(min_uv), str(max_uv), str(max_uv - min_uv), str(aabb.size)])
	quit(0)
