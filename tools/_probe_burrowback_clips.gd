extends SceneTree
func _init() -> void:
	var packed: PackedScene = load("res://assets/creatures/tetherbound/burrowback/models/creature_burrowback_lod0.glb")
	var node: Node = packed.instantiate()
	for p: Node in node.find_children("*", "AnimationPlayer", true, false):
		var ap := p as AnimationPlayer
		for clip in ap.get_animation_list():
			var a := ap.get_animation(clip)
			print("clip '%s' length=%.2f tracks=%d" % [clip, a.length, a.get_track_count()])
	node.free()
	quit(0)
