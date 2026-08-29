extends SceneTree

func _init() -> void:
	for path in [
		"res://assets/environment/stylized_nature/Rock_Medium_1.gltf",
		"res://assets/environment/stylized_nature/Rock_Medium_2.gltf",
		"res://assets/environment/stylized_nature/Rock_Medium_3.gltf",
	]:
		var packed: PackedScene = load(path)
		var inst: Node = packed.instantiate()
		_walk(inst, path)
	quit()

func _walk(node: Node, label: String) -> void:
	if node is MeshInstance3D:
		var mi := node as MeshInstance3D
		if mi.mesh != null:
			for s in mi.mesh.get_surface_count():
				var mat := mi.get_active_material(s)
				if mat is StandardMaterial3D:
					var sm := mat as StandardMaterial3D
					print("%s surf %d: albedo=%s metallic=%.2f roughness=%.2f tex=%s" % [
						label, s, str(sm.albedo_color), sm.metallic, sm.roughness, str(sm.albedo_texture)])
	for c in node.get_children():
		_walk(c, label)
