extends SceneTree

## What the animation libraries actually contain, as imported.
##
##   /opt/godot/godot --headless --path . --script tools/_dump_clips.gd
##
## Length, loop mode, step and track count for every clip in the two KayKit rigs
## the trainer wears. Written to answer one question and it answered it: all 25
## clips import with `loop_mode` 0, including `Walking_A` (1.07s), `Running_A`
## (0.80s) and `Idle_A` (1.07s) — which is why a held sprint animated for eight
## tenths of a second and then held its last frame. `trainer_model._apply_loops`
## exists because of this output.
##
## Keep it for the next animation pack. The same question will be worth asking.

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
