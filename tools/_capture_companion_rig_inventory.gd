extends SceneTree

## W12-COMPANION-0904: what the installed creature rigs actually carry, so the
## companion-presence layer only asks for clips and bones that exist.
##
##   godot --headless --path . --script tools/_capture_companion_rig_inventory.gd
##
## Prints, per species in data/creatures/species.json: the AnimationPlayer's
## clip list, each clip's length, and every bone whose name mentions head, neck
## or spine (the bones a LookAtModifier3D could drive). Read-only.

func _init() -> void:
	var file := FileAccess.open("res://data/creatures/species.json", FileAccess.READ)
	var parsed: Dictionary = JSON.parse_string(file.get_as_text())
	var species: Dictionary = parsed.get("species", {})
	var seen: Dictionary = {}
	for sid in species.keys():
		var placeholder: Dictionary = (species[sid] as Dictionary).get("placeholder", {})
		var model := str(placeholder.get("model", ""))
		if model.is_empty() or seen.has(model):
			print("%s -> shares %s" % [sid, model.get_file()])
			continue
		seen[model] = true
		var packed: PackedScene = load(model)
		if packed == null:
			print("%s: LOAD FAILED %s" % [sid, model])
			continue
		var node: Node = packed.instantiate()
		root.add_child(node)
		var clips: Array = []
		for ap in node.find_children("*", "AnimationPlayer", true, false):
			var player := ap as AnimationPlayer
			for clip in player.get_animation_list():
				clips.append("%s(%.2fs)" % [clip, player.get_animation(clip).length])
		var bones: Array = []
		var bone_count := 0
		for sk in node.find_children("*", "Skeleton3D", true, false):
			var skel := sk as Skeleton3D
			bone_count += skel.get_bone_count()
			for i in skel.get_bone_count():
				var bone_name := skel.get_bone_name(i)
				var lower := bone_name.to_lower()
				if lower.contains("head") or lower.contains("neck"):
					bones.append(bone_name)
		print("%s | clips=%s | bones=%d head/neck=%s" % [sid, clips, bone_count, bones])
		root.remove_child(node)
		node.queue_free()
	quit(0)
