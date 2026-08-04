extends SceneTree

## Throwaway probe. Round 4: "no character casts a shadow" — trainer, pal and
## enemy all sit on the terrain with no contact while trees beside them cast.
## Nothing in our code turns that off, so the question is whether the IMPORT
## does.

func _init() -> void:
	for path in [
		"res://assets/characters/knight.glb",
		"res://assets/pals/bramblit.fbx",
		"res://assets/environment/stylized_nature/CommonTree_1.gltf",
	]:
		if not ResourceLoader.exists(path):
			print(path, " MISSING")
			continue
		var n: Node = (load(path) as PackedScene).instantiate()
		root.add_child(n)
		for m in n.find_children("*", "MeshInstance3D", true, false):
			var mesh := m as MeshInstance3D
			print("%-28s %-22s cast_shadow=%d visible=%s" % [
				path.get_file(), mesh.name, mesh.cast_shadow, mesh.visible
			])
		root.remove_child(n)
	quit(0)
