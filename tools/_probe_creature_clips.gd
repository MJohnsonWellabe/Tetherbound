extends SceneTree

## Does every species in `species.json` actually reach the game with the clips
## it declares? Answers in seconds, with no world and no renderer:
##
##   godot --headless --path . --script tools/_probe_creature_clips.gd
##
## WHY NOT `tests/smoke_art.gd`. That test asks the same question as one of
## many checks inside a full `meadows_playground.tscn` boot, and two separate
## lanes have now recorded it running for tens of minutes in a software-
## rendered container without finishing. This loads the imported model resource
## on its own, which is the part that answers "is this creature a statue", and
## nothing else. It is a probe, not a replacement: `smoke_art.gd` also checks
## scale, colliders, shiny variants and human fit, none of which this touches.
##
## It reads the model through `species.json`'s own `placeholder.model` path and
## the same `animations` role map `creature_animator.gd` resolves against, so a
## clip that exists in the `.glb` under a name the data does not name still
## fails here -- which is the failure mode that matters. A model with no
## AnimationPlayer at all is the specific state the five expansion meshes
## shipped in before T1-RIG-2.

const SPECIES_FILE := "res://data/creatures/species.json"
const ROLES := ["idle", "walk", "run", "attack", "hit", "faint"]


func _init() -> void:
	var file := FileAccess.open(SPECIES_FILE, FileAccess.READ)
	if file == null:
		print("FAIL cannot open %s" % SPECIES_FILE)
		quit(1)
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if typeof(parsed) != TYPE_DICTIONARY:
		print("FAIL %s did not parse as a dictionary" % SPECIES_FILE)
		quit(1)
		return

	var species: Dictionary = (parsed as Dictionary).get("species", {})
	var ids: Array = species.keys()
	ids.sort()
	var failures := 0
	var statues: Array[String] = []
	for id: String in ids:
		var placeholder: Dictionary = (species[id] as Dictionary).get("placeholder", {})
		var path := str(placeholder.get("model", ""))
		if path == "":
			continue
		if not ResourceLoader.exists(path):
			print("FAIL %-22s model not importable: %s" % [id, path])
			failures += 1
			continue
		var scene: PackedScene = load(path) as PackedScene
		var node: Node = scene.instantiate() if scene != null else null
		if node == null:
			print("FAIL %-22s model did not instantiate" % id)
			failures += 1
			continue
		var players: Array[Node] = node.find_children("*", "AnimationPlayer", true, false)
		if players.is_empty():
			print("FAIL %-22s NO AnimationPlayer -- this creature is a statue in the world" % id)
			statues.append(id)
			failures += 1
			node.free()
			continue
		var player := players[0] as AnimationPlayer
		var declared: Dictionary = placeholder.get("animations", {})
		var missing: Array[String] = []
		for role: String in ROLES:
			var clip := str(declared.get(role, ""))
			if clip == "" or not player.has_animation(clip):
				missing.append(role)
		var skeletons: Array[Node] = node.find_children("*", "Skeleton3D", true, false)
		var bones: int = (skeletons[0] as Skeleton3D).get_bone_count() if not skeletons.is_empty() else 0
		if missing.is_empty() and bones > 0:
			print("ok   %-22s %d bones, %d clips" % [id, bones, player.get_animation_list().size()])
		else:
			var why := "no skeleton" if bones == 0 else "missing roles: %s" % ", ".join(missing)
			print("FAIL %-22s %s" % [id, why])
			failures += 1
		node.free()

	if not statues.is_empty():
		print("\nstatues: %s" % ", ".join(statues))
	print("\n%d species checked, %d failed" % [ids.size(), failures])
	quit(1 if failures > 0 else 0)
