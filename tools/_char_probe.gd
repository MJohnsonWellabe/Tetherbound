extends SceneTree

## Is the trainer lit by the scene, or does his material opt out of it?
## Three surveys have reported him rendering at daylight brightness inside a
## dark world. Prints shading mode, emission and albedo for every surface.

func _init() -> void:
	var path := "res://assets/characters/trainer/trainer_lod0.glb"
	if not ResourceLoader.exists(path):
		for p in ["res://assets/characters/trainer/trainer.glb",
				  "res://assets/characters/trainer/trainer_lod0.gltf"]:
			if ResourceLoader.exists(p):
				path = p
				break
	print("probing ", path, " exists=", ResourceLoader.exists(path))
	var packed: PackedScene = load(path)
	if packed == null:
		quit(1)
		return
	var root_node := packed.instantiate()
	_walk(root_node)
	root_node.free()
	quit(0)

func _walk(n: Node) -> void:
	if n is MeshInstance3D:
		var m: Mesh = (n as MeshInstance3D).mesh
		if m != null:
			for s in m.get_surface_count():
				var mat := m.surface_get_material(s) as StandardMaterial3D
				if mat == null:
					print("  surface %d: not StandardMaterial3D" % s)
					continue
				print("  '%s' shading=%d(0=unshaded,1=per_pixel) emission_on=%s emission=%s energy=%.2f albedo=%s" % [
					mat.resource_name, mat.shading_mode, str(mat.emission_enabled),
					str(mat.emission), mat.emission_energy_multiplier, str(mat.albedo_color)])
	for c in n.get_children():
		_walk(c)
