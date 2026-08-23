extends SceneTree
func _init() -> void:
	for p in ["res://assets/props/quaternius_survival/Bonfire_Fire.obj",
			"res://assets/props/quaternius_survival/Bonfire.obj"]:
		var mesh: Mesh = load(p) as Mesh
		if mesh == null:
			print("%s -> not a Mesh" % p)
			continue
		var a := mesh.get_aabb()
		print("%s  surfaces=%d aabb=(%.2f, %.2f, %.2f) base=%.2f" % [
			p.get_file(), mesh.get_surface_count(), a.size.x, a.size.y, a.size.z, a.position.y])
		for i in mesh.get_surface_count():
			var m := mesh.surface_get_material(i)
			var albedo := ""
			if m is StandardMaterial3D:
				albedo = str((m as StandardMaterial3D).albedo_color)
			print("   surface %d  name=%s  mat=%s %s" % [
				i, mesh.surface_get_name(i) if mesh.has_method("surface_get_name") else "?",
				m.resource_name if m != null else "null", albedo])
	quit(0)
