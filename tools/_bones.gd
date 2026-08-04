extends SceneTree
func _init() -> void:
	for path in ["res://assets/pals/bramblit.fbx", "res://assets/pals/thornback.fbx"]:
		var packed: PackedScene = load(path)
		if packed == null: print(path, " FAILED"); continue
		var s: Node = packed.instantiate(); root.add_child(s)
		for sk in s.find_children("*", "Skeleton3D", true, false):
			var skel := sk as Skeleton3D
			var names: Array[String] = []
			for i in skel.get_bone_count(): names.append(skel.get_bone_name(i))
			print("%s  bones=%d" % [path.get_file(), skel.get_bone_count()])
			print("  ", ", ".join(names.slice(0, 26)))
		for ap in s.find_children("*", "AnimationPlayer", true, false):
			print("  clips: ", (ap as AnimationPlayer).get_animation_list())
		root.remove_child(s); s.queue_free()
	quit(0)
