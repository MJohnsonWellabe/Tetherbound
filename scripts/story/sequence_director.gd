extends Node

## The first fifteen minutes: which beat we are on, and what is possible during
## it. docs/OPENING_SEQUENCE.md is the prose version and the two are meant to be
## read together.
##
## Everything this drives already existed and none of it was connected. There
## was dialogue with nobody to start it, an interact arbiter with a modal
## lockout nothing switched, an `Interactable.enabled` flag written for exactly
## this job and never set, a naming panel nothing opened, and two methods on
## `encounter_director.gd` — `suspend_default_starter()` and `adopt_starter()` —
## whose own comments named this file as their caller while this file did not
## exist. The slice was built systems-first and the sequence was never built at
## all; this is the sequence.
##
## Split the same way `encounter_director.gd` is split from `combat_manager.gd`.
## The manager knows how a fight resolves and nothing about the world; the
## encounter director knows about the world and nothing about damage; this knows
## about the ORDER OF THINGS and nothing about either. It starts conversations
## rather than drawing them, asks for a pal rather than spawning one, and reads
## the outcome of a fight rather than running one.
##
## It does spawn the opening's cast — Grandpa and the three starters — because
## nothing else does and their placements are already written down in
## data/config/opening.json. That is placement, not behaviour: Grandpa turns to
## look at you because `npc_body.gd` does that, and a starter stands still
## because nothing tells it to move.
##
## Beat order and the per-beat conversations are DATA
## (`data/config/opening.json`, read through `opening_beats.gd`). This file
## names six beats in code because the machine has to recognise them —
## `opening_beats.missing_beats()` fails loudly at boot if the data no longer
## contains one, which is the difference between a renamed beat and a gate that
## silently never opens.

const BEATS := preload("res://scripts/story/opening_beats.gd")
const RUNNER := preload("res://scripts/story/dialogue_runner.gd")
const INTERACTABLE := preload("res://scripts/world/interactable.gd")
const NPC := preload("res://scripts/npc/npc_body.gd")
const SPECIES := preload("res://scripts/pals/pal_species.gd")
const PAL_SCENE := preload("res://scenes/pals/pal.tscn")
## pal.tscn is scriptless and the role picks the script, exactly as
## encounter_director.gd does it. A starter standing in the meadow is the bare
## body: it does not roam, it does not follow, it waits to be chosen.
const PAL_BODY := preload("res://scripts/pals/pal_body.gd")

## Mirrors CombatManager.OUTCOME_CAUGHT rather than typing "caught" twice, so a
## renamed outcome cannot silently stop matching here. Same reason
## encounter_director.gd declares its own.
const CAUGHT := "caught"

## The dialogue key `$name` is substituted from. data/dialogue/opening.json
## writes `$name` and this is the other half of that agreement.
const NAME_KEY := "name"

## How many physics frames to keep trying to stand something on the ground.
##
## Terrain3D builds its collision over several frames after the data directory
## loads, and anything placed before then ends up at the world origin under the
## terrain with no error printed. Same value and same reason as
## encounter_director.GROUND_WAIT_FRAMES.
const GROUND_WAIT_FRAMES := 300

## Above the dialogue panel (5) and the naming panel (6), below the pause menu
## (20). A fade-in that the HUD draws over is not a fade-in.
const FADE_LAYER := 15

signal beat_changed(beat: String)

@export var player_path: NodePath
@export var arbiter_path: NodePath
@export var encounter_path: NodePath
@export var manager_path: NodePath
@export var camera_rig_path: NodePath
@export var dialogue_path: NodePath
@export var name_prompt_path: NodePath

var _player: Node3D = null
var _arbiter: Node = null
var _encounter: Node = null
var _manager: Node = null
var _camera_rig: Node = null
var _dialogue: CanvasLayer = null
var _name_prompt: CanvasLayer = null

var _beat: String = ""

var _grandpa: Node3D = null
var _grandpa_prompt: Node3D = null
## The three bodies, their species ids and their prompts, by the same index.
## Parallel arrays rather than a Dictionary keyed by node, because the index IS
## the choice and it is what the naming panel comes back with.
var _starter_bodies: Array[Node3D] = []
var _starter_species: Array[String] = []
var _starter_prompts: Array[Node3D] = []
var _choice: int = -1

## True from the moment a name is confirmed until the pal is standing beside the
## trainer. `adopt_starter` waits for ground, so there are frames in there where
## no panel is open and the player must still not be able to walk off.
var _adopting: bool = false

var _fade_layer: CanvasLayer = null
var _fade_rect: ColorRect = null
var _fade_hold: float = 0.0
var _fade_left: float = 0.0
var _fade_total: float = 0.0


func _ready() -> void:
	_encounter = get_node_or_null(encounter_path)
	# FIRST, before anything else in this function and before any await.
	#
	# encounter_director spawns its sandbox starter behind
	# `await get_tree().process_frame`, and every `_ready` in the tree completes
	# before the next idle frame does — so this is the only window in which the
	# default pal can be called off. Move it below an await and the player is
	# given a terrapup they did not choose, and `adopt_starter` then refuses the
	# one they did.
	if _encounter != null:
		_encounter.call("suspend_default_starter")

	_player = get_node_or_null(player_path) as Node3D
	_arbiter = get_node_or_null(arbiter_path)
	_manager = get_node_or_null(manager_path)
	_camera_rig = get_node_or_null(camera_rig_path)
	_dialogue = get_node_or_null(dialogue_path) as CanvasLayer
	_name_prompt = get_node_or_null(name_prompt_path) as CanvasLayer

	if _player == null or _arbiter == null or _encounter == null or _manager == null \
			or _dialogue == null or _name_prompt == null:
		push_error("the sequence director is missing wiring: player=%s arbiter=%s encounter=%s manager=%s dialogue=%s name_prompt=%s" % [
			_player != null, _arbiter != null, _encounter != null, _manager != null,
			_dialogue != null, _name_prompt != null
		])
		set_process(false)
		return

	# The panels are in the tree — but are they the panels?
	#
	# A .tscn whose script failed to parse instantiates as a bare CanvasLayer:
	# the node is there, the path resolves, and every call into it fails. It is
	# not hypothetical. `name_prompt.gd` had a type-inference parse error under
	# 4.7 and the scene was loading with no script at all, which showed up as
	# `_process` throwing "nonexistent function 'is_open'" once a frame forever.
	# One error at boot naming the node beats sixty a second naming a method.
	if not _dialogue.has_method("start") or not _dialogue.has_method("drain_effects") \
			or not _name_prompt.has_method("open") or not _name_prompt.has_signal("confirmed"):
		push_error("%s and/or %s are in the scene but are not answering their own API; check for a parse error in their scripts" % [
			_dialogue.name, _name_prompt.name
		])
		set_process(false)
		return

	_check_the_data()

	# The arbiter becomes the one voice for the prompt line and the one reader of
	# the interact button. Without this the encounter director keeps its own
	# hardcoded "Engage X" and two nodes read the same press, so walking between
	# Grandpa and a wild pal talks to him AND starts a fight.
	_encounter.call("set_arbiter", _arbiter)
	# Late binding rather than making the scene set `arbiter.player_path`: this
	# node already had to be given the player, and two places naming the same
	# body is one of them being wrong.
	_arbiter.call("set_player", _player)

	_manager.connect("entered", _on_combat_entered)
	_manager.connect("exited", _on_combat_exited)
	_name_prompt.connect("confirmed", _on_name_confirmed)

	_build_fade()
	_set_beat(BEATS.first())

	# One frame, for the same reason encounter_director waits: add_child() is
	# refused while the parent is still setting up its children, and the world's
	# own `_ready` — which drops the player onto the baked ground — has not run
	# yet, so `_player.global_position` is still whatever the scene said.
	await get_tree().process_frame
	await _spawn_the_cast()


## Fail at boot rather than at the beat.
##
## A beat id renamed in data/config/opening.json, or a dialogue effect pointing
## at a beat that is not in the list, produces a sequence that plays perfectly up
## to the point where it silently stops advancing. That is the worst possible
## shape for this bug: nothing errors, the player just stands in a meadow with
## nothing to do.
func _check_the_data() -> void:
	var missing: Array[String] = BEATS.missing_beats()
	if not missing.is_empty():
		push_error("data/config/opening.json has no beat(s) named %s; the gates gated by them will never open" % ", ".join(missing))
	var broken: Array[String] = BEATS.broken_effects()
	if not broken.is_empty():
		push_error("opening.json maps effect(s) %s to a beat that is not in the list; those conversations will end and change nothing" % ", ".join(broken))


## --- the beat -----------------------------------------------------------------

func beat() -> String:
	return _beat


func is_fading() -> bool:
	return _fade_rect != null and is_instance_valid(_fade_rect)


## Move to a named beat. The only way `_beat` changes.
##
## Refuses to go backwards. Nothing in the opening should, and the way it would
## happen is a conversation the player can re-run emitting its effect a second
## time — which would put the starters back on offer after they had been chosen.
func _set_beat(target: String) -> void:
	if target == "" or target == _beat:
		return
	if not BEATS.has(target):
		push_error("no beat named '%s' in data/config/opening.json" % target)
		return
	if BEATS.index_of(target) < BEATS.index_of(_beat):
		push_warning("refused to move the opening back from '%s' to '%s'" % [_beat, target])
		return
	_beat = target
	beat_changed.emit(_beat)


func _advance() -> void:
	_set_beat(BEATS.next(_beat))


func _process(delta: float) -> void:
	_tick_fade(delta)
	_drain_effects()
	_refresh_lockout()
	_refresh_prompts()


## Effects are drained in production, here, every frame.
##
## `dialogue_panel.drain_effects()` has existed since the panel was written and
## its only caller was a unit test, which is how a conversation carrying
## `beat:starter_choice` could play end to end and unlock nothing. Drained per
## frame rather than on `finished`, so an effect takes hold when its line is
## SPOKEN — the intro's last line offers the choice while it is still on screen,
## and the prompts are live the instant the box closes.
func _drain_effects() -> void:
	for effect: String in _dialogue.call("drain_effects"):
		var parts: Array = RUNNER.parse_effect(effect)
		if str(parts[0]) != "beat":
			push_warning("the opening ignored dialogue effect '%s'; it knows about 'beat:' and nothing else" % effect)
			continue
		var target := BEATS.beat_for_effect(str(parts[1]))
		if target == "":
			push_warning("dialogue asked for '%s' but opening.json's beats.effects does not map it" % effect)
			continue
		_set_beat(target)


## --- what is possible right now -------------------------------------------------
##
## Polled, not pushed. Same house rule as `combat_hud.gd` and the pause menu: the
## gates are recomputed from the beat every frame and nothing keeps a second copy
## of "are the starters offering". A gate that is set once when a beat changes is
## a gate that is wrong the first time something else touches it.

## The modal lockout, through the mechanism built for it.
##
## `InteractionArbiter.set_enabled()` was written with the comment "cleared while
## a conversation, a naming prompt or a fight owns the screen" and had no callers
## at all. These are those three, plus the fade.
##
## The fight case is not decoration. `interact` and `combat_charged` are the same
## physical button (X), so with the arbiter live during a fight, one press both
## swings your pal and opens a conversation with Grandpa if the fight happened to
## start near him.
func _refresh_lockout() -> void:
	var fighting: bool = _manager != null and bool(_manager.call("is_fighting"))
	var panel: bool = bool(_dialogue.call("is_open")) or bool(_name_prompt.call("is_open"))
	var modal := panel or is_fading() or _adopting

	_arbiter.call("set_enabled", not modal and not fighting)

	# Locomotion and the camera belong to combat while a fight is running.
	# Handing them back here every frame would undo what the encounter director
	# and the combat manager just did to them.
	if fighting:
		return
	if _player.has_method("set_locomotion_enabled"):
		_player.call("set_locomotion_enabled", not modal)
	if _camera_rig != null and is_instance_valid(_camera_rig):
		# The rig has no suspend of its own, so its idle tick — which is where
		# both the stick look and the follow live — is switched off. Not during
		# the fade: the world is black, but the camera still has to be sitting
		# behind the player by the time it clears.
		_camera_rig.set_process(not panel)


## Grandpa offers his prompt on any beat he has something to say on; the starters
## offer theirs on exactly one.
##
## `Interactable.enabled` is the flag its own comment describes: "the starters
## exist in the world before the choice is unlocked, and a visible 'Choose
## Terrapup' the button refuses is worse than no prompt". It had no callers
## either.
func _refresh_prompts() -> void:
	if _grandpa_prompt != null and is_instance_valid(_grandpa_prompt):
		_grandpa_prompt.call("set_enabled", BEATS.conversation_for(_beat) != "")
	var offering := _beat == BEATS.CHOOSE
	for prompt: Node3D in _starter_prompts:
		if prompt != null and is_instance_valid(prompt):
			prompt.call("set_enabled", offering)


## --- beat 1: the fade ------------------------------------------------------------

## Beat 1 is a fade-in from black rather than an interior, which saves an entire
## interior art pass for a beat that lasts forty seconds
## (docs/OPENING_SEQUENCE.md). Both numbers are in data/config/opening.json and
## until now nothing read them.
##
## Built in code rather than added to the scene: it is two nodes with no layout,
## it belongs to this beat and to nothing else, and a scene the world has to
## remember to include is a scene one world will be missing.
func _build_fade() -> void:
	var cfg := BEATS.fade()
	_fade_total = maxf(float(cfg.get("seconds", 1.6)), 0.01)
	_fade_hold = float(cfg.get("hold_seconds", 0.5))
	_fade_left = _fade_total

	_fade_layer = CanvasLayer.new()
	_fade_layer.name = "OpeningFade"
	_fade_layer.layer = FADE_LAYER
	add_child(_fade_layer)

	_fade_rect = ColorRect.new()
	_fade_rect.name = "Black"
	_fade_rect.color = Color(0.0, 0.0, 0.0, 1.0)
	_fade_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	# The black must not eat the cursor: the naming panel releases the mouse and
	# this is the layer above it.
	_fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade_layer.add_child(_fade_rect)


func _tick_fade(delta: float) -> void:
	if not is_fading():
		return
	if _fade_hold > 0.0:
		_fade_hold -= delta
		return

	_fade_left -= delta
	_fade_rect.color.a = clampf(_fade_left / _fade_total, 0.0, 1.0)
	if _fade_left > 0.0:
		return

	_fade_layer.queue_free()
	_fade_layer = null
	_fade_rect = null
	# Beat 1 is over when the player can see. Beat 2 is the walk to Grandpa and
	# has no gate of its own — it is the meadow, and it is meant to be looked at.
	_advance()


## --- the cast ---------------------------------------------------------------------

## Grandpa and the three starters, placed from data/config/opening.json.
##
## Parented to this node's PARENT rather than to this node, matching
## encounter_director: `pal_body` and `npc_body` both find the ground by walking
## up the tree looking for `ground_height_at`, and the world root is what offers
## it. A creature hung under a plain Node is also outside the 3D transform chain.
func _spawn_the_cast() -> void:
	var origin := _player.global_position
	var cfg := BEATS.grandpa()

	_grandpa = NPC.new()
	_grandpa.name = "Grandpa"
	get_parent().add_child(_grandpa)
	_grandpa.call("setup", str(cfg.get("art", "grandpa")), _player)

	var spot := origin + _to_vector3(cfg.get("offset", []))
	if not await _stand_npc(_grandpa, spot):
		push_error("no ground under Grandpa's spot; beat 3 has nobody to talk to")

	# He faces the player from the start rather than swinging round on the first
	# frame they come into his notice range.
	var towards := origin - _grandpa.global_position
	towards.y = 0.0
	if towards.length() > 0.01:
		_grandpa.rotation.y = atan2(towards.x, towards.z)

	_grandpa_prompt = _grandpa.call("add_prompt",
		str(cfg.get("prompt", "Talk to Grandpa")),
		float(cfg.get("prompt_radius", 3.8)))
	_grandpa_prompt.call("set_enabled", false)
	_grandpa_prompt.connect("activated", _on_grandpa_activated)

	await _spawn_starters(origin)


## Three pals in a row in front of him, on his own facing, so he is behind them
## and the player approaches all three head-on.
##
## They are bodies you walk up to and NOT a menu. docs/OPENING_SEQUENCE.md calls
## that decided and load-bearing: it is the first expression of the game's whole
## posture toward its creatures, and a list box would undo it.
func _spawn_starters(origin: Vector3) -> void:
	var cfg := BEATS.starters()
	var species: Array = cfg.get("species", [])
	if species.is_empty():
		push_error("opening.json lists no starter species; beat 4 has nothing to choose from")
		return

	var facing := origin - _grandpa.global_position
	var offsets := BEATS.starter_offsets(facing)
	var radius := float(cfg.get("prompt_radius", 2.6))

	for i in species.size():
		var id := str(species[i])
		var body: Node3D = PAL_SCENE.instantiate()
		body.name = "Starter_%s" % id
		body.set_script(PAL_BODY)
		# Hidden until it is standing on the ground. A visible body at the world
		# origin is a solid capsule inside the terrain, or inside the trainer —
		# and two overlapping bodies resolve the overlap by shoving each other
		# apart, which once launched the player off the playground at 500 m/s.
		body.visible = false
		get_parent().add_child(body)
		body.call("setup", id)
		if not await _stand_on_ground(body, _grandpa.global_position + offsets[i]):
			push_error("no ground under the %s starter; it will be unreachable" % id)
		body.visible = true
		body.call("face_towards", origin)

		var prompt: Node3D = INTERACTABLE.new()
		prompt.name = "Interactable"
		# At the creature's shoulder rather than between its feet, which is where
		# the player is actually looking.
		prompt.position = Vector3(0.0, float(body.call("body_height")) * 0.6, 0.0)
		# Off. The starters stand in the meadow from beat 1 and cannot be taken
		# until beat 4; `_refresh_prompts` turns them on.
		prompt.call("configure", "Choose %s" % _display_name(id), radius, false)
		body.add_child(prompt)
		prompt.connect("activated", _on_starter_activated.bind(i))

		_starter_bodies.append(body)
		_starter_species.append(id)
		_starter_prompts.append(prompt)


func _display_name(species_id: String) -> String:
	return str(SPECIES.definition(species_id).get("display_name", species_id))


func _stand_npc(npc: Node3D, spot: Vector3) -> bool:
	for i in GROUND_WAIT_FRAMES:
		if bool(npc.call("stand_at", spot.x, spot.z)):
			return true
		await get_tree().physics_frame
	return false


func _stand_on_ground(body: Node3D, spot: Vector3) -> bool:
	for i in GROUND_WAIT_FRAMES:
		if bool(body.call("place_on_ground", spot)):
			return true
		await get_tree().physics_frame
	return false


## `[10.0, 0.0, 32.0]` out of JSON. Y is ignored everywhere in opening.json —
## everything is stood on the ground by asking the world (docs/decisions/D09) —
## but it is carried here so a config with a Y in it is not silently reshaped.
func _to_vector3(raw: Variant) -> Vector3:
	if not raw is Array or (raw as Array).size() < 3:
		return Vector3.ZERO
	var values: Array = raw
	return Vector3(float(values[0]), float(values[1]), float(values[2]))


## --- beat 3: Grandpa ---------------------------------------------------------------

func _on_grandpa_activated() -> void:
	_start_conversation(BEATS.conversation_for(_beat))


func _start_conversation(id: String) -> bool:
	if id == "":
		return false
	if bool(_dialogue.call("is_open")):
		return false
	return bool(_dialogue.call("start", id))


## --- beats 4 and 5: the choice, and the name ------------------------------------------

func _on_starter_activated(index: int) -> void:
	if _beat != BEATS.CHOOSE or _adopting:
		return
	if index < 0 or index >= _starter_species.size():
		return
	_choice = index
	# Naming is mandatory, not skippable (docs/OPENING_SEQUENCE.md): a pal you did
	# not name is a pal you did not adopt. The panel has no cancel, and the beat
	# does not advance until it comes back with a word.
	_name_prompt.call("open", _display_name(_starter_species[index]))


func _on_name_confirmed(chosen: String) -> void:
	if _choice < 0:
		push_error("a name came back with no starter chosen")
		return
	await _adopt(_choice, chosen)


func _adopt(index: int, chosen: String) -> void:
	_adopting = true
	var species := _starter_species[index]

	# The one they chose stops standing there. `adopt_starter` builds the body
	# that follows them — a follower, not this one — so leaving this here would
	# put two of the same creature in the meadow, one of them inert.
	var body := _starter_bodies[index]
	if body != null and is_instance_valid(body):
		body.queue_free()
	_starter_bodies[index] = null
	_starter_prompts[index] = null

	# The other two stay standing where they are. That is the five-pal rule's
	# first bite and the cost of the choice is meant to remain in the world where
	# the player can see it.

	var adopted: bool = await _encounter.call("adopt_starter", species, chosen)
	_adopting = false
	if not adopted:
		push_error("could not give the player the %s they chose" % species)
		return

	if not _give_to_party(_encounter.call("ally_instance"), chosen):
		push_error("the chosen %s is beside the trainer but not in the party" % species)

	# The first time this game says a word the player wrote.
	_dialogue.call("set_value", NAME_KEY, chosen)
	_set_beat(BEATS.NAMED)
	# Started here rather than waiting for them to walk back to him: the reply is
	# the beat, and data/dialogue/opening.json says so ("Immediately after the
	# name is entered"). Its last line carries `beat:first_encounter`.
	_start_conversation(BEATS.named_conversation())


## --- beats 6, 7 and 8: the encounter, the fight and the catch ----------------------------
##
## None of this is reimplemented here. The wild bramblebun, the engage prompt,
## the fight and the throw are `encounter_director.gd` and `combat_manager.gd`
## and they already work; this reads the result and moves the beat.
##
## Nothing gates the encounter either, and nothing needs to: the encounter
## director offers no engagement while the player has no pal, so beats 1 to 5 are
## already unreachable from a fight.

func _on_combat_entered() -> void:
	if _beat == BEATS.WALK_OUT:
		_set_beat(BEATS.ENCOUNTER)


func _on_combat_exited(outcome: String) -> void:
	if outcome != CAUGHT:
		# They won it instead of catching it, or ran. The encounter director puts
		# the bramblebun back on its feet after a few seconds, so the beat stays
		# where it is and they get another go — species.json gives that creature
		# the highest catch rate in the game precisely so the tutorial catch does
		# not have to succeed first time.
		return

	var kept: RefCounted = _manager.call("caught_instance")
	if kept == null:
		push_error("combat ended as a catch with nothing caught")
		return
	# No nickname. GAME_DESIGN.md 10: a new capture keeps its species name by
	# default, and `pal_instance.nickname` stays empty so the party screen can
	# still tell a pal the player never renamed from one they deliberately named
	# after its species.
	if not _give_to_party(kept, ""):
		push_error("the caught %s never reached the party" % kept.species_id)
	_set_beat(BEATS.ROAD)


## --- the party -------------------------------------------------------------------

## Into the real party, which is `Game`'s.
##
## Not through `scripts/story/party_seam.gd`. That file was written while there
## was no autoload to hold a party, and it says so in its own TODO; there is one
## now, `autoload/party.gd` enforces the five-pal cap in `add()` and nowhere
## else, and a second path into the party is a second place the cap can be
## missed.
##
## Looked up by path rather than through the `Game` global so a null is a
## push_error at the one call site instead of a crash, and so this node can be
## dropped into a scene run outside the normal boot.
func _give_to_party(instance: RefCounted, nickname: String) -> bool:
	if instance == null:
		return false
	if nickname != "":
		instance.set("nickname", nickname)

	var game := get_node_or_null(^"/root/Game")
	if game == null:
		push_error("no Game autoload; the pal exists but nobody owns it")
		return false
	var party: RefCounted = game.get("party")
	if party == null:
		push_error("the Game autoload has no party")
		return false

	if bool(party.call("is_full")):
		# The opening cannot reach this — it adds two pals to an empty party —
		# but the sixth-pal release ceremony is real design (GAME_DESIGN.md 3)
		# and a director that silently dropped a pal would hide the day it starts
		# mattering.
		push_warning("the party is full; %s was not added" % instance.get("display_name"))
		return false
	return bool(party.call("add", instance))
