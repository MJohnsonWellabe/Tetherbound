extends Node3D

## Villagers standing in the square (R7.2), from data/config/village_npcs.json.
##
## Same shape as village.gd's structures: data describes, code places. Each
## entry becomes an `npc_body.gd` body (the same script Grandpa already uses),
## stood on the ground synchronously — this runs from `_build_settlement()`,
## well after the terrain's collision is confirmed solid (village.gd's own
## structures place the same way, with no retry loop), so there is nothing to
## wait several frames for here the way the opening's own cast has to.
##
## Deliberately NOT part of the opening's cast (sequence_director.gd): these
## villagers have no beat to gate them, no effect to fire, and no reason to be
## built before the player can even leave the house. Wired in from
## playground_world.gd's settlement step instead, alongside village.gd.

const NPC := preload("res://scripts/npc/npc_body.gd")
const CONFIG_PATH := "res://data/config/village_npcs.json"

var _placed := 0


func build(player: Node3D) -> void:
	var file := FileAccess.open(CONFIG_PATH, FileAccess.READ)
	if file == null:
		push_error("village_npcs.json missing; the square has nobody in it")
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		push_error("village_npcs.json is not valid JSON")
		return

	for entry: Variant in (parsed as Dictionary).get("villagers", []):
		if entry is Dictionary:
			_spawn(entry as Dictionary, player)
	print("[village_npcs] placed %d villagers" % _placed)


func placed() -> int:
	return _placed


func _spawn(spec: Dictionary, player: Node3D) -> void:
	var config_key := str(spec.get("config_key", ""))
	var display_name := str(spec.get("name", "Villager"))
	var npc: Node3D = NPC.new()
	npc.name = display_name
	add_child(npc)
	if not bool(npc.call("setup", config_key, player)):
		push_error("villager '%s' has no model for art key '%s'; nothing will stand there" % [display_name, config_key])

	var at: Array = spec.get("position", [0.0, 0.0])
	var x := float(at[0]) if at.size() > 0 else 0.0
	var z := float(at[1]) if at.size() > 1 else 0.0
	if not bool(npc.call("stand_at", x, z)):
		push_error("no ground under villager '%s' at %.0f, %.0f" % [display_name, x, z])
		return
	npc.rotation.y = deg_to_rad(float(spec.get("facing_deg", 0.0)))

	# "Greet <name>", built here rather than stored in the JSON, and never
	# "Talk to". tests/smoke_opening.gd finds Grandpa via the FIRST enabled
	# interactable whose label contains "grandpa" or "talk", and separately
	# asserts exactly three "choose" matches for the starters — a villager
	# label containing either substring would corrupt one of those checks.
	var prompt: Node3D = npc.call("add_prompt", "Greet %s" % display_name)
	prompt.connect("activated", _on_greeted.bind(str(spec.get("greeting", ""))))
	_placed += 1


## Reaches the dialogue panel through the "dialogue_panel" group rather than an
## exported NodePath, the same way interactable.gd finds the interaction
## arbiter through "interaction_arbiter". This node is built by
## playground_world.gd, which has no reason to know sequence_director.gd's own
## wiring, and this way a villager can talk without sequence_director.gd
## changing at all.
##
## No lockout check beyond "is something already open": InteractionArbiter
## itself stops OFFERING any prompt, this one included, while a conversation,
## the naming panel or a fight has the modal lock (sequence_director.gd's
## `_refresh_lockout`), so a press can only reach here when nothing else has
## the screen.
func _on_greeted(conversation_id: String) -> void:
	if conversation_id == "":
		return
	var panel := get_tree().get_first_node_in_group("dialogue_panel")
	if panel == null:
		push_warning("no node in the 'dialogue_panel' group; a villager has nothing to say")
		return
	if bool(panel.call("is_open")):
		return
	panel.call("start", conversation_id)
