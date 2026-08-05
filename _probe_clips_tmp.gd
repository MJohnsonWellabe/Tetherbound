extends SceneTree
func _init() -> void:
	for path in ["res://assets/characters/Rig_Medium_General.glb", "res://assets/characters/Rig_Medium_MovementBasic.glb"]:
		var n: Node = (load(path) as PackedScene).instantiate()
		root.add_child(n)
		for p in n.find_children("*", "AnimationPlayer", true, false):
			var ap: AnimationPlayer = p
			var names: PackedStringArray = []
			for c in ap.get_animation_list():
				names.append("%s(%.2fs)" % [c, ap.get_animation(c).length])
			print("%s: %s" % [path.get_file(), ", ".join(names)])
		root.remove_child(n)
	quit(0)
