extends SceneTree
func _init() -> void:
	for name in ["CommonTree_1", "TwistedTree_1", "Bush_Common", "Grass_Common_Tall"]:
		var packed: PackedScene = load("res://assets/environment/stylized_nature/%s.gltf" % name)
		var scene: Node = packed.instantiate()
		root.add_child(scene)
		for mesh in scene.find_children("*", "MeshInstance3D", true, false):
			var m: Mesh = (mesh as MeshInstance3D).mesh
			for s in m.get_surface_count():
				var arrays: Array = m.surface_get_arrays(s)
				var cols: PackedColorArray = arrays[Mesh.ARRAY_COLOR] if arrays[Mesh.ARRAY_COLOR] != null else PackedColorArray()
				var mat := m.surface_get_material(s) as StandardMaterial3D
				var sample := "none" if cols.is_empty() else str(cols[0])
				print("%-18s surf %d  mat=%-22s vc_albedo=%s  vc[0]=%s  albedo=%s" % [
					name, s, mat.resource_name if mat else "?",
					str(mat.vertex_color_use_as_albedo) if mat else "?",
					sample, str(mat.albedo_color) if mat else "?"])
		root.remove_child(scene); scene.queue_free()
	quit(0)
