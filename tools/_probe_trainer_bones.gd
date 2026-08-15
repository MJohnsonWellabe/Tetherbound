extends SceneTree

func _init() -> void:
	var packed: PackedScene = load("res://assets/characters/trainer/trainer_lod0.glb")
	var inst := packed.instantiate()
	root.add_child(inst)
	var skeleton := _find_skeleton(inst)
	if skeleton == null:
		print("no Skeleton3D found")
		quit(1)
		return
	for i in skeleton.get_bone_count():
		print(skeleton.get_bone_name(i))
	quit(0)


func _find_skeleton(node: Node) -> Skeleton3D:
	if node is Skeleton3D:
		return node
	for child in node.get_children():
		var found := _find_skeleton(child)
		if found != null:
			return found
	return null
