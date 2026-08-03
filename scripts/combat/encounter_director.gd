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
const CATCH := preload("res://scripts/combat/catch_math.gd")
const SPECIES := preload("res://scripts/pals/pal_species.gd")
## Mirrors CombatManager.OUTCOME_CAUGHT. Declared rather than typed twice so a
## renamed outcome cannot silently stop matching here.
const CAUGHT := "caught"
const PAL_SCENE := preload("res://scenes/pals/pal.tscn")
## pal.tscn carries no script; one body shape serves both roles and the script
## is chosen here. The alternative is two near-identical scenes, which means
## M11's real creature model has to be wired into the game twice.
const BODY_SCRIPT := preload("res://scripts/pals/pal_body.gd")
const WILD_SCRIPT := preload("res://scripts/pals/wild_pal.gd")

signal prompt_changed(text: String)

## Ids into data/pals/species.json, so swapping any of them is a data edit.
##
## Two wild creatures in M3: one peaceful to practise throwing at, and one that
## comes at you. They are separated in the playground so the ambush is something
## you walk into rather than something that happens while you are aiming at the
## other one.
const STARTER_SPECIES := "starter_ground"
const WILD_SPAWNS := [
	{"species": "wild_rabbit", "offset": Vector3(14.0, 0.0, -10.0)},
	{"species": "wild_bristler", "offset": Vector3(-6.0, 0.0, 26.0)},
]

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
var _wild_pals: Array[Node3D] = []
var _engaged_with: Node3D = null
var _ally_body: Node3D = null
var _ally: RefCounted = null

var _engage_range: float = 6.0
var _prompt: String = ""

## Pals waiting on their faint to clear, and on their respawn. Keyed by node, so
## two creatures can be knocked out at once without one cancelling the other's
## timer — which is the bug a single shared `_respawn_left` would have.
var _faint_timers: Dictionary = {}
var _respawn_timers: Dictionary = {}

## Everything the player has caught. The party and the five-slot rule are M4;
## this list is the seam they attach to, exactly as CombatManager's `_party` and
## `_active_index` are the seam for switching.
##
## CLAUDE.md forbids implementing storage beyond five pals. This is not storage —
## it is a milestone-local record that catching worked, and M4 replaces it.
var _caught: Array[RefCounted] = []


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

	for entry: Variant in WILD_SPAWNS:
		var spawn: Dictionary = entry
		var species := str(spawn["species"])
		var wild: Node3D = PAL_SCENE.instantiate()
		wild.name = "Wild_%s" % species
		wild.set_script(WILD_SCRIPT)
		get_parent().add_child(wild)
		if not await _stand_on_ground(wild, origin + (spawn["offset"] as Vector3)):
			push_error("no ground under the %s spawn point; it will be unreachable" % species)
		wild.call("populate", species, _player)
		wild.call("configure", MATH.config().get("wild", {}))
		wild.set("home", wild.global_position)
		# An aggressive pal asks; this node decides. Keeping the decision here
		# means every route into a fight goes through one place, so a new one
		# cannot forget to suspend exploration or hand over the camera.
		wild.connect("wants_to_engage", _on_wild_wants_to_engage.bind(wild))
		_wild_pals.append(wild)

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


## The peaceful practice pal. Named for what it is used for rather than by index,
## so tests and tools do not silently start pointing at a different creature when
## the spawn list changes.
func wild_pal() -> Node3D:
	return _wild_of_species("wild_rabbit")


func aggressive_pal() -> Node3D:
	return _wild_of_species("wild_bristler")


func wild_pals() -> Array[Node3D]:
	return _wild_pals


func caught() -> Array[RefCounted]:
	return _caught


func _wild_of_species(id: String) -> Node3D:
	for wild in _wild_pals:
		if str(wild.get("species_id")) == id:
			return wild
	return null


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


## Two clocks per knocked-out creature: how long its body lies there, and how
## long until it is back. Kept per-node so two faints cannot cancel each other.
func _tick_respawn(delta: float) -> void:
	for wild: Node3D in _faint_timers.keys().duplicate():
		var left: float = float(_faint_timers[wild]) - delta
		if left > 0.0:
			_faint_timers[wild] = left
			continue
		_faint_timers.erase(wild)
		if is_instance_valid(wild):
			wild.call("clear_faint")

	for wild: Node3D in _respawn_timers.keys().duplicate():
		var left: float = float(_respawn_timers[wild]) - delta
		if left > 0.0:
			_respawn_timers[wild] = left
			continue
		_respawn_timers.erase(wild)
		if is_instance_valid(wild):
			wild.call("revive_at_home")
			# M3-only: the orb stock refills with the practice pal, because there
			# is no inventory until M8 and running dry mid-session would end the
			# testing rather than teach anything.
			_refill_orbs()


func _refill_orbs() -> void:
	var throw_aim: Node = _manager.call("throw_aim") as Node
	if throw_aim != null:
		throw_aim.call("refill")


## The nearest wild pal the player could choose to fight right now.
func _engageable() -> Node3D:
	if _ally == null or _manager == null or _ally.fainted:
		return null
	if bool(_manager.call("is_fighting")):
		return null

	var best: Node3D = null
	var best_distance := _engage_range
	for wild in _wild_pals:
		if not is_instance_valid(wild) or not wild.visible or not bool(wild.call("is_alive")):
			continue
		var distance := _player.global_position.distance_to(wild.global_position)
		if distance <= best_distance:
			best = wild
			best_distance = distance
	return best


func _update_prompt() -> void:
	var text := ""
	if bool(_manager.call("is_fighting")):
		text = ""
	elif _ally != null and _ally.fainted:
		text = "%s is out of the fight." % _ally.display_name
	else:
		var candidate := _engageable()
		if candidate != null:
			text = "[X] / [E]   Engage %s" % str(candidate.get("display_name"))
	if text != _prompt:
		_prompt = text
		prompt_changed.emit(text)


func _read_engage_input() -> void:
	if not Input.is_action_just_pressed("interact"):
		return
	var candidate := _engageable()
	if candidate == null:
		return
	# For a PEACEFUL pal this press is the only way in. GAME_DESIGN.md §14
	# forbids proximity starting a fight with one, and nothing but this line
	# starts a fight with the Meadow Hopper.
	_start_fight(candidate)


## An aggressive pal has reached the trainer and is starting the fight itself.
##
## §14 lists "Aggressive pal initiates" beside the player's own routes in, and
## scopes the "not simple proximity" rule to peaceful pals. This is that other
## route, and it is guarded rather than trusted: the creature asks, and gets
## refused if a fight is already running or the player has nothing to fight with.
func _on_wild_wants_to_engage(wild: Node3D) -> void:
	if not bool(wild.get("aggressive")):
		push_error("%s asked to initiate but is not aggressive" % wild.name)
		return
	if _ally == null or _ally.fainted or bool(_manager.call("is_fighting")):
		return
	if not is_instance_valid(wild) or not wild.visible or not bool(wild.call("is_alive")):
		return
	_start_fight(wild)


## One way in, whoever started it. A second route that forgot to suspend
## exploration or hand over the camera would be a bug that only shows up when
## something ambushes you.
func _start_fight(wild: Node3D) -> void:
	var party: Array[RefCounted] = [_ally]
	if not bool(_manager.call("begin", _player, wild, _ally_body, party, _camera_rig)):
		return
	_engaged_with = wild
	_set_exploration_active(false)


func _on_combat_exited(outcome: String) -> void:
	_set_exploration_active(true)
	var wild := _engaged_with
	_engaged_with = null

	if wild != null and is_instance_valid(wild):
		match outcome:
			"won":
				# It stays on the ground for a moment before it clears. §15: the
				# body is the feedback for having over-damaged something you
				# might have caught.
				wild.call("notify_fainted")
				_faint_timers[wild] = float(CATCH.config().get("faint", {}).get("linger_seconds", 4.0))
				_respawn_timers[wild] = RESPAWN_DELAY
			CAUGHT:
				var kept: RefCounted = _manager.call("caught_instance")
				if kept != null:
					_caught.append(kept)
				wild.visible = false
				# M3-only: the caught creature comes back so the owner can keep
				# testing throws. M4 owns it properly and this goes away.
				_respawn_timers[wild] = RESPAWN_DELAY

	# M2 has no healing system, no camp and no bond, so the player's pal is
	# restored between fights. That is a placeholder for M5's stronghold rest and
	# is deliberately generous: this milestone is measuring whether throwing is
	# satisfying, and a recovery chore in front of the second throw measures
	# something else.
	if _ally != null:
		_ally.heal_fully()


## Hand control back and forth between exploration and combat. One place, so a
## new way of entering a fight cannot forget half of it.
func _set_exploration_active(active: bool) -> void:
	if _player != null and _player.has_method("set_locomotion_enabled"):
		_player.call("set_locomotion_enabled", active)
