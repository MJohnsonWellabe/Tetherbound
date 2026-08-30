extends SceneTree

## T1-CAST-FIX scratch probe: per-surface AABBs of Bonfire_Fire.obj (raw,
## unscaled) so camp.gd can seat camp_flame.glb on the real log-pile top
## instead of guessing. Run with --headless (no rendering needed).

func _init() -> void:
	var mesh := load("res://assets/props/quaternius_survival/Bonfire_Fire.obj") as Mesh
	if mesh == null:
		print("no mesh")
		quit(1)
		return
	print("whole-mesh aabb: %s" % mesh.get_aabb())
	for i in mesh.get_surface_count():
		var arrays := mesh.surface_get_arrays(i)
		var verts := arrays[Mesh.ARRAY_VERTEX] as PackedVector3Array
		var aabb := AABB(verts[0], Vector3.ZERO)
		for v in verts:
			aabb = aabb.expand(v)
		print("surface %d '%s': pos=%s size=%s (top y=%.3f)" % [
			i, mesh.surface_get_name(i), aabb.position, aabb.size,
			aabb.position.y + aabb.size.y])
	quit(0)
