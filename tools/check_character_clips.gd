extends SceneTree

## Does every clip data/config/art.json names actually exist in the .glb?
##
##     xvfb-run -a -s "-screen 0 1280x720x24" ~/.cache/tetherbound-art/godot \
##         --path . --headless --script tools/check_character_clips.gd
##
## A clip name that does not resolve is the quietest failure in this project.
## Nothing errors: the AnimationPlayer is asked for "Walking_A", does not have
## it, and the character stands in its rest pose looking like a model with no
## animations at all. The trainer swapped skeletons when it stopped being
## KayKit's Ranger — which changed every clip name at once — so the mapping is
## worth asserting rather than eyeballing.
##
## Also catches the other half of the same problem: a .glb that Godot has not
## imported yet reads as MISSING here rather than as a capsule at run time.

const CONFIG_PATH := "res://data/config/art.json"

## The art.json blocks that describe a character with a model and clips.
const CHARACTERS := ["trainer", "grandpa", "warden"]


func _find_player(node: Node) -> AnimationPlayer:
	if node is AnimationPlayer:
		return node as AnimationPlayer
	for child in node.get_children():
		var found := _find_player(child)
		if found != null:
			return found
	return null


func _init() -> void:
	var file := FileAccess.open(CONFIG_PATH, FileAccess.READ)
	if file == null:
		printerr("no %s" % CONFIG_PATH)
		quit(1)
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		printerr("%s is not valid JSON" % CONFIG_PATH)
		quit(1)
		return
	var config := parsed as Dictionary

	var failures := 0
	for who: String in CHARACTERS:
		var block: Dictionary = config.get(who, {})
		var path := str(block.get("model", ""))
		if path == "" or not ResourceLoader.exists(path):
			print("%-8s FAIL  no such model: %s" % [who, path])
			failures += 1
			continue
		var packed := load(path) as PackedScene
		if packed == null:
			print("%-8s FAIL  model will not load: %s" % [who, path])
			failures += 1
			continue
		var instance: Node = packed.instantiate()
		var player := _find_player(instance)
		var present: Array = [] if player == null else Array(player.get_animation_list())
		var wanted: Dictionary = block.get("clips", {})
		var missing: Array = []
		for role: String in wanted:
			if not present.has(str(wanted[role])):
				missing.append("%s -> %s" % [role, str(wanted[role])])
		instance.free()

		if missing.is_empty():
			print("%-8s ok    %d clips, all %d mapped roles resolve"
				% [who, present.size(), wanted.size()])
		else:
			print("%-8s FAIL  %d unresolved: %s\n         present: %s"
				% [who, missing.size(), str(missing), str(present)])
			failures += 1

	print("\n%d character(s), %d failed" % [CHARACTERS.size(), failures])
	quit(1 if failures > 0 else 0)
