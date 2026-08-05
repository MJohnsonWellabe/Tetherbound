extends SceneTree

func _init() -> void:
	for path in [
		"res://assets/characters/Rig_Medium_General.glb",
		"res://assets/characters/Rig_Medium_MovementBasic.glb",
	]:
		var node: Node = (load(path) as PackedScene).instantiate()
		var player := _find(node)
		print("== %s" % path)
		for clip in player.get_animation_list():
			var a: Animation = player.get_animation(clip)
			print("  %-24s len %.3f  loop %d  step %.4f  tracks %d" % [
				clip, a.length, a.loop_mode, a.step, a.get_track_count()
			])
	quit()

func _find(node: Node) -> AnimationPlayer:
	if node is AnimationPlayer:
		return node
	for c in node.get_children():
		var f := _find(c)
		if f != null:
			return f
	return null
