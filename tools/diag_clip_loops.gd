extends SceneTree

## Do the shipped clips actually loop?
##
##   godot --headless --path . --script tools/diag_clip_loops.gd
##
## A creature that "is just static posed and slides around" is the exact
## signature of a clip that plays once and stops. Godot's glTF importer sets
## `loop_mode = LOOP_NONE` unless told otherwise, and every clip in this
## project is authored in Blender and exported as an NLA track — so nothing has
## ever asked for looping.
##
## An idle that does not loop holds its first pose forever. A walk that does not
## loop takes one step and freezes while the body keeps moving. Both look
## exactly like "no animation".

const MODELS := {
	"terrapup": "res://assets/creatures/tetherbound/terrapup/models/creature_terrapup_lod0.glb",
	"ripplet": "res://assets/creatures/tetherbound/ripplet/models/creature_ripplet_lod0.glb",
	"galewisp": "res://assets/creatures/tetherbound/galewisp/models/creature_galewisp_lod0.glb",
	"veridian": "res://assets/creatures/tetherbound/veridian/models/creature_veridian_lod0.glb",
	"trainer": "res://assets/characters/trainer/trainer_lod0.glb",
}

const LOOP_NAMES := {
	Animation.LOOP_NONE: "NONE",
	Animation.LOOP_LINEAR: "LINEAR",
	Animation.LOOP_PINGPONG: "PINGPONG",
}


func _find(node: Node) -> AnimationPlayer:
	if node is AnimationPlayer:
		return node as AnimationPlayer
	for child in node.get_children():
		var found := _find(child)
		if found != null:
			return found
	return null


func _init() -> void:
	var looping := 0
	var total := 0
	for label: String in MODELS:
		var path: String = MODELS[label]
		if not ResourceLoader.exists(path):
			print("%-10s MISSING" % label)
			continue
		var instance: Node = (load(path) as PackedScene).instantiate()
		var player := _find(instance)
		if player == null:
			print("%-10s no AnimationPlayer" % label)
			instance.free()
			continue
		var parts: Array = []
		for clip: String in player.get_animation_list():
			var animation := player.get_animation(clip)
			var mode: int = animation.loop_mode
			total += 1
			if mode != Animation.LOOP_NONE:
				looping += 1
			parts.append("%s=%s(%.1fs)" % [clip, LOOP_NAMES.get(mode, str(mode)), animation.length])
		print("%-10s %s" % [label, ", ".join(parts)])
		instance.free()
	print("\n%d of %d clips loop" % [looping, total])
	quit()
