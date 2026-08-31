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
const CHARACTER_MODEL := preload("res://scripts/characters/character_model.gd")
const NPC_RANKS := preload("res://scripts/characters/npc_ranks.gd")
const CONFIG_PATH := "res://data/config/village_npcs.json"

## SE27. The same placer, pointed at a second list. `build()` takes an optional
## config path so the relay site's captive (data/config/relay_site.json) is
## another entry in another file rather than a second copy of this file — the
## whole contents of it that the captive needs (an npc_body, a "Greet <name>"
## prompt, `greeting_when` branching on progression flags) already exist here.
## The list key may be spelled `villagers` or `people`; the relay's occupants
## are not villagers and calling them that in their own file would be a lie.
const RELAY_CONFIG_PATH := "res://data/config/relay_site.json"

var _placed := 0
var _player: Node3D = null
var _specs: Array = []
## display name -> the body currently standing for it. Only entries whose
## `place_when` holds are in here; see `_refresh_placements()`.
var _bodies: Dictionary = {}
## Last `progression.revision` this node re-evaluated `place_when` against.
var _revision := -1
var _label := "village_npcs"


func build(player: Node3D, config_path: String = CONFIG_PATH) -> void:
	_player = player
	_label = config_path.get_file().get_basename()
	var file := FileAccess.open(config_path, FileAccess.READ)
	if file == null:
		push_error("%s missing; the square has nobody in it" % config_path)
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		push_error("%s is not valid JSON" % config_path)
		return

	var listed: Variant = (parsed as Dictionary).get("villagers", (parsed as Dictionary).get("people", []))
	if listed is Array:
		for entry: Variant in (listed as Array):
			if entry is Dictionary:
				_specs.append(entry)
	_refresh_placements()
	set_process(true)
	print("[%s] placed %d of %d" % [_label, _placed, _specs.size()])


func placed() -> int:
	return _placed


## SE27. `place_when` is the same ordered-branch shape `greeting_when` uses,
## asked about whether somebody is STANDING there at all rather than about what
## they say. The captive exists at the relay until they are freed; the Rescued
## Ranger exists in the village only after that. Both are one entry with one
## gate, and neither needs a second scene or a reload to appear: the gate is
## re-read whenever the flag store's revision moves (the same polling idiom
## party.gd/inventory.gd/map_state.gd already use — progression_state.gd has no
## signal by design).
func _process(_delta: float) -> void:
	# Never while somebody is mid-sentence. The rescue conversation sets
	# `captive_rescued` on its THIRD line of six, and the person saying those
	# lines is the person that flag removes — freeing her body there would
	# delete the speaker (and the prompt the interaction arbiter is holding)
	# halfway through her own scene. `_revision` is deliberately not advanced
	# in this branch, so the change is applied on the first frame after the box
	# closes rather than dropped.
	var panel := get_tree().get_first_node_in_group("dialogue_panel")
	if panel != null and bool(panel.call("is_open")):
		return
	var progression := _progression()
	var revision: int = int(progression.get("revision")) if progression != null else -1
	if revision == _revision:
		return
	_revision = revision
	_refresh_placements()


func _progression() -> RefCounted:
	var game := get_node_or_null(^"/root/Game")
	return game.get("progression") if game != null else null


func _refresh_placements() -> void:
	var progression := _progression()
	for entry: Variant in _specs:
		var spec := entry as Dictionary
		var who := str(spec.get("name", "Villager"))
		var wanted := _placement_holds(spec, progression)
		var standing: bool = _bodies.has(who)
		if wanted and not standing:
			_spawn(spec, _player)
		elif standing and not wanted:
			var body: Node = _bodies[who]
			_bodies.erase(who)
			_placed = maxi(0, _placed - 1)
			if is_instance_valid(body):
				body.queue_free()


## No `place_when` at all means "always here", which is every villager who was
## already standing in the square before SE27 and is why this is additive.
## A null flag store (a bare test scene, a capture tool) also reads as "here":
## the cautious direction for placement is the opposite of the cautious
## direction for a one-time gift — a missing body is a task the player cannot
## even find, where a duplicate greeting is only noise.
static func placement_holds(spec: Dictionary, progression: RefCounted) -> bool:
	var branches: Variant = spec.get("place_when", null)
	if branches == null:
		return true
	if typeof(branches) != TYPE_ARRAY or (branches as Array).is_empty():
		return true
	if progression == null:
		return true
	for raw: Variant in (branches as Array):
		if typeof(raw) == TYPE_DICTIONARY and _branch_holds(raw as Dictionary, progression):
			return true
	return false


func _placement_holds(spec: Dictionary, progression: RefCounted) -> bool:
	return placement_holds(spec, progression)


## SE27. The art.json block this person's body is built from, with their own
## per-part variants laid over it. Deliberately the same five override keys
## `trainer_npc.model_config()` accepts, and for the same CLAUDE.md/§21 reason:
## human NPCs are differentiated by hair, palette entries and accessories on a
## rig that already exists. An entry naming none of them gets the plain block
## back, which is what `setup()` used to hand `build()` anyway.
##
## E3-RELAY-POPULATION: `rank` is the same second path `trainer_npc.model_config()`
## already reads — a Team Tether rank (`data/config/npc_ranks.json`) instead of
## a villager's own `config_key` — so a non-combat Team Tether body (a patrol,
## a worker) gets the faction's own grunt/officer rig, palette and badge rather
## than a villager's. An entry naming neither gets an empty config, same as
## before this existed.
static func model_config(spec: Dictionary) -> Dictionary:
	var rank := str(spec.get("rank", ""))
	var cfg := NPC_RANKS.config_for(rank, str(spec.get("base", ""))) if rank != "" \
		else CHARACTER_MODEL.config_for(str(spec.get("config_key", "")))
	if cfg.is_empty():
		return cfg
	cfg = cfg.duplicate(true)
	for key: String in ["hair", "palette", "accessories", "tint", "height"]:
		if spec.has(key):
			cfg[key] = spec[key]
	return cfg


func _spawn(spec: Dictionary, player: Node3D) -> void:
	var config_key := str(spec.get("config_key", ""))
	var display_name := str(spec.get("name", "Villager"))
	var npc: Node3D = NPC.new()
	npc.name = display_name
	add_child(npc)
	# SE27: an entry may lay its own per-part variants over the art.json base —
	# hair, a `palette` map, accessories — exactly as a trainer entry does
	# (CLAUDE.md/spec §21: a new person is a variant on a rig that already
	# exists, never a new model). An entry naming none of them takes the plain
	# art key, which is every villager placed before this.
	if not bool(npc.call("setup_from_config", model_config(spec), player)):
		push_error("villager '%s' has no model for art key '%s'; nothing will stand there" % [display_name, config_key])
	_bodies[display_name] = npc

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
