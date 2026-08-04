extends SceneTree

## Print the real-world size of imported models, and what materials they carry.
##
##   godot --headless --path . --script tools/measure_models.gd <dir> [dir...]
##
## Every asset pack is authored at a different scale — Kenney's nature models
## are about one unit tall and needed a 3.4x per-layer correction, and a pack
## authored in metres needs none at all. Guessing that correction produces a
## meadow of knee-high trees or a single tree filling the frame, and both have
## happened here.
##
## It also reports whether a material carries a TEXTURE, which decides whether
## the scatter's retint may touch it: replacing a textured material with a flat
## colour throws away the thing that was worth having.

func _init() -> void:
	var dirs: Array = []
	for arg in OS.get_cmdline_user_args():
		dirs.append(arg)
	if dirs.is_empty():
		dirs = ["res://assets/environment/stylized_nature"]

	for dir_path: String in dirs:
		print("\n%s" % dir_path)
		var dir := DirAccess.open(dir_path)
		if dir == null:
			print("  cannot open")
			continue
		var names: Array[String] = []
		for file in dir.get_files():
			if file.get_extension() in ["gltf", "glb", "fbx"]:
				names.append(file)
		names.sort()
		for file in names:
			_report("%s/%s" % [dir_path, file])
	quit(0)


func _report(path: String) -> void:
	var packed: PackedScene = load(path) as PackedScene
	if packed == null:
		print("  %-32s FAILED TO LOAD" % path.get_file())
		return
	var scene: Node = packed.instantiate()
	root.add_child(scene)

	var meshes: Array[MeshInstance3D] = []
	_collect(scene, meshes)
	if meshes.is_empty():
		print("  %-32s no meshes" % path.get_file())
		root.remove_child(scene)
		scene.queue_free()
		return

	var box := AABB()
	var started := false
	var tris := 0
	var textured := 0
	var materials: Array[String] = []
	for mesh in meshes:
		var world: AABB = mesh.global_transform * mesh.get_aabb()
		box = world if not started else box.merge(world)
		started = true
		if mesh.mesh != null:
			for surface in mesh.mesh.get_surface_count():
				var material: Material = mesh.mesh.surface_get_material(surface)
				var name := "" if material == null else material.resource_name
				if material is StandardMaterial3D and (material as StandardMaterial3D).albedo_texture != null:
					textured += 1
					name += "*"
				if not materials.has(name):
					materials.append(name)
			tris += mesh.mesh.get_faces().size() / 3

	print("  %-30s %5.2f x %5.2f x %5.2f  %6d tris  %d mesh  mats: %s" % [
		path.get_file().get_basename(), box.size.x, box.size.y, box.size.z,
		tris, meshes.size(), ", ".join(materials)
	])
	root.remove_child(scene)
	scene.queue_free()


func _collect(node: Node, into: Array[MeshInstance3D]) -> void:
	if node is MeshInstance3D and (node as MeshInstance3D).mesh != null:
		into.append(node as MeshInstance3D)
	for child in node.get_children():
		_collect(child, into)
