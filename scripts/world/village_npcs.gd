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
## villagers have no beat to gate them and no reason to be built before the
## player can even leave the house. Wired in from playground_world.gd's
## settlement step instead, alongside village.gd.
##
## OF30 gave one of them (Tam, the smith) real `give:`/`flag:` effects, and
## still nothing here or in sequence_director.gd had to change to carry them:
## village lines open on the SHARED dialogue panel, and the director drains
## that panel's effects every frame without asking whose conversation it is.
## What DID have to change is which conversation Tam opens — see
## `greeting_for()` at the bottom of this file.

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
	#
	# The whole spec is bound, not just the greeting id: which conversation a
	# villager opens can depend on progression flags (OF30's `greeting_when`),
	# and those change while the player is standing in the square. Resolving it
	# here, once, at build time would freeze Tam on whatever branch was true
	# when the settlement was built.
	var prompt: Node3D = npc.call("add_prompt", "Greet %s" % display_name)
	prompt.connect("activated", _on_greeted.bind(spec))
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
func _on_greeted(spec: Dictionary) -> void:
	var game := get_node_or_null(^"/root/Game")
	var progression: RefCounted = game.get("progression") if game != null else null
	var conversation_id := greeting_for(spec, progression)
	if conversation_id == "":
		return
	var panel := get_tree().get_first_node_in_group("dialogue_panel")
	if panel == null:
		push_warning("no node in the 'dialogue_panel' group; a villager has nothing to say")
		return
	if bool(panel.call("is_open")):
		return
	panel.call("start", conversation_id)


## --- which conversation, given what has already happened ---------------------

## OF30. Pick the conversation a villager opens right now.
##
## `greeting` is the villager's ordinary line and is the answer unless something
## says otherwise. `greeting_when` is an ordered list of branches checked ahead
## of it -- first match wins, no match falls through to `greeting`. See
## village_npcs.json's own `_comment_greeting_when` for the data contract.
##
## Additive by design, and that is the whole point of the shape: OF30 gives Tam
## two entries (the tool handover, then the orb recipe), SC12 appends his battle
## offer as a third, and OF31 gives Mira and Oskar lists of their own. Nobody's
## `greeting` is ever replaced, so a villager who runs out of matching branches
## goes back to being a villager.
##
## Static and pure -- no nodes, no tree, no `/root/Game` -- so
## tests/test_dialogue_runner.gd can drive the real selection with a real
## progression store instead of booting a world to find out whether a gift can
## be taken twice.
##
## A null `progression` means the flag store could not be reached at all (no
## Game autoload -- a bare test scene, a capture tool). Every conditional branch
## is skipped in that case and the plain `greeting` wins. Deliberately the
## cautious direction: an `unless_flag` branch treated as matching would hand
## out a one-time gift on every single greeting, forever.
static func greeting_for(spec: Dictionary, progression: RefCounted) -> String:
	var fallback := str(spec.get("greeting", ""))
	if progression == null:
		return fallback
	var branches: Variant = spec.get("greeting_when", [])
	if typeof(branches) != TYPE_ARRAY:
		return fallback
	for raw: Variant in (branches as Array):
		if typeof(raw) != TYPE_DICTIONARY:
			continue
		var branch := raw as Dictionary
		var conversation := str(branch.get("conversation", ""))
		if conversation == "":
			push_warning("a greeting_when branch names no conversation; ignored")
			continue
		if _branch_holds(branch, progression):
			return conversation
	return fallback


## Every `if_flag` set and every `unless_flag` clear. A branch naming neither
## always holds, which is how an unconditional override (a villager permanently
## moved onto new lines) is written without a sentinel flag.
static func _branch_holds(branch: Dictionary, progression: RefCounted) -> bool:
	for flag: String in _flag_list(branch.get("if_flag", null)):
		if not bool(progression.call("has", flag)):
			return false
	for flag: String in _flag_list(branch.get("unless_flag", null)):
		if bool(progression.call("has", flag)):
			return false
	return true


## One flag id, or several. Both spellings are accepted for the same key so a
## branch that grows a second condition does not have to change shape.
static func _flag_list(raw: Variant) -> Array[String]:
	var out: Array[String] = []
	if typeof(raw) == TYPE_STRING and not (raw as String).is_empty():
		out.append(raw as String)
	elif typeof(raw) == TYPE_ARRAY:
		for entry: Variant in (raw as Array):
			if typeof(entry) == TYPE_STRING and not (entry as String).is_empty():
				out.append(entry as String)
	return out
