extends SceneTree

func _init() -> void:
	var mesh: Mesh = load("res://assets/buildings/quaternius_castle/WallBricks.obj")
	print("mesh=%s surfaces=%d" % [str(mesh), mesh.get_surface_count()])
	for i in mesh.get_surface_count():
		var mat := mesh.surface_get_material(i)
		print("  surface %d: mat=%s resource_name=%s" % [i, str(mat), str(mat.resource_name) if mat != null else "NULL"])
		if mat is StandardMaterial3D:
			var sm := mat as StandardMaterial3D
			print("    albedo_color=%s albedo_texture=%s" % [str(sm.albedo_color), str(sm.albedo_texture)])
	quit()
