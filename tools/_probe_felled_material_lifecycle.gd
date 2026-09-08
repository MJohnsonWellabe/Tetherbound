extends SceneTree
## Isolate the actual felled-resource visual lifecycle from Terrain3D removal.
func _initialize() -> void: _run.call_deferred()
func _run() -> void:
	var world := Node3D.new()
	root.add_child(world)
	var pile := preload("res://scripts/world/felled_resource.gd").new()
	world.add_child(pile)
	print("BEGIN actual wood pile setup")
	pile.setup({"item":"wood","amount":3,"realm":"meadows"})
	for frame in 5: await process_frame
	var mesh_ids: Array[int] = []
	for node: Node in pile.find_children("*","MeshInstance3D",true,false):
		mesh_ids.append((node as MeshInstance3D).mesh.get_instance_id())
	world.remove_child(pile)
	world.add_child(pile)
	var restored_ids: Array[int] = []
	for node: Node in pile.find_children("*","MeshInstance3D",true,false):
		var instance := node as MeshInstance3D
		restored_ids.append(instance.mesh.get_instance_id() if instance.mesh != null else 0)
	var reparent_preserved := not mesh_ids.is_empty() and restored_ids == mesh_ids
	print("REPARENT live mesh identities preserved=",reparent_preserved," count=",mesh_ids.size())
	var held: Array[Material] = []
	for node: Node in pile.find_children("*","MeshInstance3D",true,false):
		var instance := node as MeshInstance3D
		if OS.get_cmdline_user_args().has("--hold-materials"):
			for surface in instance.mesh.get_surface_count():
				var source := instance.mesh.surface_get_material(surface)
				if source != null: held.append(source)
				var override_material := instance.get_surface_override_material(surface)
				if override_material != null: held.append(override_material)
		if OS.get_cmdline_user_args().has("--detach-meshes"):
			instance.mesh = null
	print("END actual wood pile setup; BEGIN free")
	world.queue_free()
	for frame in 5: await process_frame
	print("END actual wood pile free")
	held.clear()
	print("END held material release")
	quit(0 if reparent_preserved else 1)
