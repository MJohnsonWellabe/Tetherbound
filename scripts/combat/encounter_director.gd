extends Node

## Everything around a fight that is not the fight: spawning the wild pal,
## offering the engage prompt, suspending exploration, and putting the world
## back afterwards.
##
## Split from CombatManager on purpose. The manager knows how a fight resolves
## and nothing about the world it happens in; this knows about the world and
## nothing about damage. M3 adds catching to the manager and M4 adds a party,
## and neither should have to touch spawn placement or the interact prompt.
##
## Split from the playground world too, which is about terrain. This node can be
## dropped into the real Meadows scene unchanged.

const MATH := preload("res://scripts/combat/combat_math.gd")
const SPECIES := preload("res://scripts/pals/pal_species.gd")
const PAL_SCENE := preload("res://scenes/pals/pal.tscn")
## pal.tscn carries no script; one body shape serves both roles and the script
## is chosen here. The alternative is two near-identical scenes, which means
## M11's real creature model has to be wired into the game twice.
const BODY_SCRIPT := preload("res://scripts/pals/pal_body.gd")
const WILD_SCRIPT := preload("res://scripts/pals/wild_pal.gd")

signal prompt_changed(text: String)

## M2 ships one wild creature and one of yours. Both are ids into
## data/pals/species.json, so swapping them is a data edit.
const WILD_SPECIES := "wild_rabbit"
const STARTER_SPECIES := "starter_ground"

## Where the wild pal is placed, relative to the player's spawn. Far enough that
## the player walks to it — finding a creature is part of the encounter — and
## close enough that they find it without a search.
const SPAWN_OFFSET := Vector3(14.0, 0.0, -10.0)

## Seconds before a defeated wild pal is back on its feet. M2 only: the milestone
## exists to find out whether the owner wants another fight, and making them
## restart the game to have one would answer a different question.
const RESPAWN_DELAY := 6.0

@export var player_path: NodePath
@export var manager_path: NodePath
@export var camera_rig_path: NodePath

var _player: CharacterBody3D = null
var _manager: Node = null
var _camera_rig: Node = null
var _wild: Node3D = null
var _ally_body: Node3D = null
var _ally: RefCounted = null

var _engage_range: float = 6.0
var _respawn_left: float = 0.0
var _prompt: String = ""


func _ready() -> void:
	_engage_range = float(MATH.config().get("flow", {}).get("engage_range", 6.0))
	_player = get_node_or_null(player_path) as CharacterBody3D
	_manager = get_node_or_null(manager_path)
	_camera_rig = get_node_or_null(camera_rig_path)
	if _player == null or _manager == null:
		push_error("encounter director needs a player and a combat manager")
		set_process(false)
		return
	_manager.connect("exited", _on_combat_exited)

	# `_ready` runs while the parent is still setting up its children, and
	# add_child() is refused during that. One frame is enough to be out of it.
	await get_tree().process_frame
	await _spawn_creatures()


## How many physics frames to keep trying to stand the wild pal on the ground.
##
## Terrain3D builds its collision over several frames after the data directory
## loads, and a raycast before then hits nothing. The first version of this
## spawned once on frame two, the ray missed, and the creature sat at the world
## origin under the terrain — where the player could neither see nor reach it,
## and where no error was printed. Retrying is the fix; the frame budget is so a
## scene with genuinely no ground fails loudly instead of looping.
const GROUND_WAIT_FRAMES := 300


func _spawn_creatures() -> void:
	var origin := _player.global_position

	_wild = PAL_SCENE.instantiate()
	_wild.name = "WildPal"
	_wild.set_script(WILD_SCRIPT)
	get_parent().add_child(_wild)
	if not await _stand_on_ground(_wild, origin + SPAWN_OFFSET):
		push_error("no ground under the wild pal spawn point; it will be unreachable")
	_wild.call("populate", WILD_SPECIES, _player)
	_wild.call("configure", MATH.config().get("wild", {}))
	_wild.set("home", _wild.global_position)

	# The player's pal exists as a body in the world the whole time and is simply
	# hidden outside combat. Instancing it at the moment a fight opens is a hitch
	# in the one frame that most needs to be smooth.
	_ally_body = PAL_SCENE.instantiate()
	_ally_body.name = "AllyPal"
	_ally_body.set_script(BODY_SCRIPT)
	get_parent().add_child(_ally_body)
	_ally_body.call("setup", STARTER_SPECIES)
	_ally_body.visible = false

	_ally = SPECIES.spawn(STARTER_SPECIES)
	if _ally == null:
		push_error("starter species '%s' is missing from species.json" % STARTER_SPECIES)


func _stand_on_ground(body: Node3D, spot: Vector3) -> bool:
	for i in GROUND_WAIT_FRAMES:
		if bool(body.call("place_on_ground", spot)):
			return true
		await get_tree().physics_frame
	return false


func wild_pal() -> Node3D:
	return _wild


func ally_body() -> Node3D:
	return _ally_body


func ally_instance() -> RefCounted:
	return _ally


func prompt() -> String:
	return _prompt


func _process(delta: float) -> void:
	_tick_respawn(delta)
	_update_prompt()


## Engage is read on the physics tick, not the idle tick.
##
## `Input.is_action_just_pressed()` is scoped to whichever frame the press was
## recorded in, and reading it from `_process` while CombatManager reads its own
## actions from `_physics_process` means one press can be seen by one and missed
## by the other depending on where in the frame it landed. It cost a survey run
## that captured four frames of a fight that had never started.
func _physics_process(_delta: float) -> void:
	_read_engage_input()


func _tick_respawn(delta: float) -> void:
	if _respawn_left <= 0.0:
		return
	_respawn_left -= delta
	if _respawn_left <= 0.0 and _wild != null:
		_wild.call("revive_at_home")


func _can_engage() -> bool:
	if _wild == null or _ally == null or _manager == null:
		return false
	if bool(_manager.call("is_fighting")):
		return false
	if not bool(_wild.call("is_alive")) or not _wild.visible:
		return false
	if _ally.fainted:
		return false
	return _player.global_position.distance_to(_wild.global_position) <= _engage_range


func _update_prompt() -> void:
	var text := ""
	if bool(_manager.call("is_fighting")):
		text = ""
	elif _ally != null and _ally.fainted:
		text = "%s is out of the fight." % _ally.display_name
	elif _respawn_left > 0.0:
		text = ""
	elif _can_engage():
		var name_text: String = str(_wild.get("display_name"))
		text = "[X] / [E]   Engage %s" % name_text
	if text != _prompt:
		_prompt = text
		prompt_changed.emit(text)


func _read_engage_input() -> void:
	if not Input.is_action_just_pressed("interact"):
		return
	if not _can_engage():
		return
	# Engagement is always this: an explicit press. GAME_DESIGN.md 14 forbids
	# proximity starting a fight with a peaceful pal, and the wild pal's own
	# script never initiates.
	var party: Array[RefCounted] = [_ally]
	# The manager takes it from here: it opens the arena, places the fighters,
	# engages the wild pal and moves the camera onto yours. This node's job ends
	# at deciding a fight may start.
	if not bool(_manager.call("begin", _player, _wild, _ally_body, party, _camera_rig)):
		return
	_set_exploration_active(false)


func _on_combat_exited(outcome: String) -> void:
	_set_exploration_active(true)

	if outcome == "won" and _wild != null:
		_wild.call("notify_fainted")
		_respawn_left = RESPAWN_DELAY

	# M2 has no healing system, no camp and no bond, so the player's pal is
	# restored between fights. That is a placeholder for M5's stronghold rest and
	# is deliberately generous: this milestone is measuring whether the fight is
	# worth repeating, and a recovery chore in front of the second fight measures
	# something else.
	if _ally != null:
		_ally.heal_fully()


## Hand control back and forth between exploration and combat. One place, so a
## new way of entering a fight cannot forget half of it.
func _set_exploration_active(active: bool) -> void:
	if _player != null and _player.has_method("set_locomotion_enabled"):
		_player.call("set_locomotion_enabled", active)
