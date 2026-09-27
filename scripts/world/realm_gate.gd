extends Node3D

## A durable, physical gate between realms.
##
## The key is a progression entitlement, not a carried inventory item.  It is
## therefore impossible to drop, overflow from a full satchel, or lose on the
## frame the Warden reward is granted.  Unlocking writes its own progression
## flag and takes one deliberate interaction; entering takes the next.
##
## `Game.enter_realm(destination_realm, destination_entry_id)` owns scene
## transition/loading, including the OP-0905-20 "Loading <realm>…" overlay it
## shows before the blocking scene swap.  This component only proves the gate
## state, changes its physical presentation, and asks Game to travel.
##
## `enter_realm()` is a coroutine (it awaits the overlay). `try_enter()` below
## fires it via `game.call(...)` without `await` and never reads its return —
## exactly the "issuing the request is Game's job to see through" contract its
## own header already states, and precisely the shape a fire-and-forget
## coroutine call supports: it runs to completion in the background whether or
## not the caller awaits it.

const INTERACTABLE := preload("res://scripts/world/interactable.gd")
const VISUAL_CONFIG_PATH := "res://data/config/realm_gate_visual.json"
const PRESENTATION := preload("res://scripts/world/realm_gate_presentation.gd")

const STATE_LOCKED := "locked"
const STATE_UNLOCKABLE := "unlockable"
const STATE_UNLOCKED := "unlocked"

const SEALED := Color("4ec2cb")
const OPEN := Color("a8e9d1")

@export var destination_realm: String = "cloudreach"
@export var destination_entry_id: String = "meadows_gate"
@export var destination_label: String = "Cloudreach Cliffs"
## Stage B lane 5.A. A realm key and a realm unlock are WORLD facts.
const STORY_LEDGER := preload("res://scripts/story/story_ledger.gd")
const LEDGER_CLAIM := preload("res://scripts/world/ledger_claim.gd")
@export var origin_realm: String = ""

@export var key_flag: String = "realm_key_cloudreach"
@export var unlock_flag: String = "realm_gate_cloudreach_unlocked"
@export var interaction_radius: float = 4.0

var _prompt: Node3D = null
var _barrier_shape: CollisionShape3D = null
var _sealed_visual: Node3D = null
var _open_visual: Node3D = null
var _open_material: ShaderMaterial = null
var _visual_config: Dictionary = {}
var _built := false
var _observed_progression: RefCounted = null
var _progression_revision := -1


## Configure before adding to the scene tree.  The destination entry id names
## the authored arrival point in the destination realm; it is not a position
## copied across unrelated coordinate spaces.
func setup(
		p_destination_realm: String,
		p_destination_entry_id: String,
		p_destination_label: String,
		p_key_flag: String,
		p_unlock_flag: String
	) -> void:
	destination_realm = p_destination_realm
	destination_entry_id = p_destination_entry_id
	destination_label = p_destination_label
	key_flag = p_key_flag
	unlock_flag = p_unlock_flag
	if is_inside_tree():
		refresh_from_game()


func _ready() -> void:
	add_to_group("progression_restore")
	_build_visual()
	_build_prompt()
	refresh_from_game()


## Public, side-effect-free state query for tests and world sequencing.
func state_for(game: Node) -> String:
	if is_unlocked(game):
		return STATE_UNLOCKED
	if has_key(game):
		return STATE_UNLOCKABLE
	return STATE_LOCKED


func current_state() -> String:
	return state_for(_game())


func _process(_delta: float) -> void:
	var game := _game()
	var progression := _progression(game)
	if progression != _observed_progression \
			or (progression != null and int(progression.get("revision")) != _progression_revision):
		_refresh(game)


## Stage B lane 5.A: the WORLD's store, never the merged view. `realm_key_*` and
## `realm_gate_*_unlocked` are world flags (D99) -- the Warden falls once and the
## realm opens once, for everybody -- so a player who was not in the room reads
## the same open gate as the one who was.
## `game` is used again, so it loses its underscore. Lane 5.A prefixed it when
## the read moved to the tree walk, and the prefix was honest at the time --
## but it also made "this function ignores what you passed it" look deliberate
## rather than like the defect it turned into.
func has_key(game: Node) -> bool:
	return key_flag != "" and STORY_LEDGER.world_flag(self, key_flag, game)


func is_unlocked(game: Node) -> bool:
	return unlock_flag != "" and STORY_LEDGER.world_flag(self, unlock_flag, game)


## Writes the durable unlock only when the key entitlement exists.  The key is
## intentionally retained: it is the player's record of completing the prior
## realm, not a consumable tooth snapped off in this one lock.
func try_unlock(game: Node) -> bool:
	if is_unlocked(game):
		return true
	if not has_key(game) or unlock_flag == "":
		return false
	# Stage B lane 5.A. A realm opens once, for the world: committed through the
	# ledger so the friend standing at the same gate walks through it too. A
	# client's verdict is `pending` and the gate re-poses on the delta
	# (`restore_progression_from_game` through the `progression_restore` group),
	# so this returns `is_unlocked()` -- the honest answer to "is it open NOW".
	var realm := origin_realm if not origin_realm.is_empty() else STORY_LEDGER.realm_of(self)
	var verdict := LEDGER_CLAIM.submit(self, {
		"kind": "set_world_flag", "realm": realm, "id": unlock_flag, "value": true,
	})
	# Bare fixtures retain their direct state adapter; a refused live intent
	# must never become a local unlock that bypasses the server.
	if str(verdict.get("code", "")) == "offline" and LEDGER_CLAIM.transport(self) == null:
		var progression := _progression(game)
		if progression != null:
			progression.call("set_flag", unlock_flag)
	return is_unlocked(game)


## Calls the persistent realm router only after the durable unlock is set.
## Returning true means the request was issued; the asynchronous transition is
## still Game's responsibility.
func try_enter(game: Node) -> bool:
	if game == null or not is_unlocked(game) or destination_realm == "":
		return false
	if not game.has_method("enter_realm"):
		push_error("RealmGate: Game has no enter_realm(destination, entry_id) method")
		return false
	game.call("enter_realm", destination_realm, destination_entry_id)
	return true


func restore_progression_from_game(game: Node) -> void:
	_refresh(game)


func refresh_from_game() -> void:
	_refresh(_game())


func _on_activated() -> void:
	var game := _game()
	match state_for(game):
		STATE_UNLOCKABLE:
			if try_unlock(game):
				_refresh(game)
				if game != null and game.has_method("push_world_message"):
					game.call("push_world_message", "The way to %s is open." % destination_label)
		STATE_UNLOCKED:
			try_enter(game)
		_:
			pass


func _refresh(game: Node) -> void:
	if not _built or _prompt == null:
		return
	_observed_progression = _progression(game)
	_progression_revision = int(_observed_progression.get("revision")) if _observed_progression != null else -1
	var state := state_for(game)
	match state:
		STATE_LOCKED:
			_prompt.call("configure", "The passage to %s is sealed" % destination_label, interaction_radius, true)
			_prompt.set("actionable", false)
			_set_open_visual(false, false)
		STATE_UNLOCKABLE:
			_prompt.call("configure", "Unlock the way to %s" % destination_label, interaction_radius, true)
			_prompt.set("actionable", true)
			_set_open_visual(false, true)
		STATE_UNLOCKED:
			_prompt.call("configure", "Enter %s" % destination_label, interaction_radius, true)
			_prompt.set("actionable", true)
			_set_open_visual(true, true)


func _set_open_visual(opened: bool, key_present: bool) -> void:
	_sealed_visual.visible = not opened
	_open_visual.visible = opened
	_barrier_shape.set_deferred("disabled", opened)
	# Before the Warden reward the seal is cold blue-grey.  Once the player has
	# the key it brightens visibly, making the next interaction legible without
	# turning the progression requirement into floating UI text.
	var seal_material := _sealed_visual.get_meta("material") as ShaderMaterial
	PRESENTATION.style(seal_material, SEALED if key_present else SEALED.darkened(0.58),
		_visual_config.unlockable if key_present else _visual_config.locked)
	PRESENTATION.style(_open_material, OPEN, _visual_config.open)


func _build_prompt() -> void:
	_prompt = INTERACTABLE.new()
	_prompt.name = "Interactable"
	_prompt.position = Vector3(0.0, 1.25, 0.72)
	_prompt.call("configure", "The passage is sealed", interaction_radius, true)
	_prompt.set("actionable", false)
	_prompt.connect("activated", _on_activated)
	add_child(_prompt)


func _build_visual() -> void:
	if _built:
		return
	_built = true
	_visual_config = JSON.parse_string(FileAccess.get_file_as_string(VISUAL_CONFIG_PATH))
	PRESENTATION.frame(self, _visual_config)
	_sealed_visual = Node3D.new()
	_sealed_visual.name = "RealmSeal"
	add_child(_sealed_visual)
	_sealed_visual.set_meta("material", PRESENTATION.veil(_sealed_visual, "EnergyVeil", _visual_config))
	_open_visual = Node3D.new()
	_open_visual.name = "OpenThreshold"
	add_child(_open_visual)
	_open_material = PRESENTATION.veil(_open_visual, "OpenAirShimmer", _visual_config)

	var body := StaticBody3D.new()
	body.name = "LockedBarrier"
	_barrier_shape = CollisionShape3D.new()
	var barrier := BoxShape3D.new()
	barrier.size = Vector3(3.15, 3.75, 0.64)
	_barrier_shape.shape = barrier
	_barrier_shape.position.y = 2.05
	body.add_child(_barrier_shape)
	add_child(body)


func _game() -> Node:
	return get_node_or_null(^"/root/Game")


func _progression(game: Node) -> RefCounted:
	if game == null:
		return null
	var value: Variant = game.get("progression")
	return value as RefCounted if value is RefCounted else null
