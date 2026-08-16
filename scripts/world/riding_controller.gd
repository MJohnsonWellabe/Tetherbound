extends Node

## R6.1: getting on the creature, and driving it.
##
## Riding is a WORLD VERB, not a mode. You walk up to your own creature, the
## one interact prompt says "Ride Meadowhart", you press the same button you
## press for Grandpa and berry bushes and the bed, and you are on it. That is
## the whole controller-first story (D35): no new binding, no held modifier, no
## menu. Pressing it again gets off. `docs/decisions/D35`'s Palworld parity is
## exactly this — mounting is a thing you do to a creature standing in front of
## you, with the button already in your hand.
##
## What drives what, while mounted:
##
##   stick  -> this node -> creature_body.request_move()  (the creature walks)
##   camera -> camera_rig.set_target(mount)               (the rig follows it)
##   player -> player_controller.set_carrier(mount)       (the trainer is cargo)
##
## There is deliberately no second movement implementation here. The mount walks
## with the same acceleration, the same turn rate, the same slope handling and
## the same animation blending it uses when it is following you or fighting,
## because it is literally the same code path — this node only decides a
## direction and a speed, exactly as `follower_creature.gd` and `combat_ai.gd`
## do. The one thing riding changes is the speed it asks for.
##
## It owns no state the world does not already have: which creature is out is
## the encounter director's, which items you have is the satchel's, whether a
## fight is running is the combat manager's. This node reads all three every
## frame rather than caching any of them, for the same reason
## `sequence_director.gd`'s lockout is polled — a gate set once when something
## changed is a gate that is wrong the first time something else touches it.

const SPECIES := preload("res://scripts/creatures/creature_species.gd")
const PROMPTS := preload("res://scripts/world/prompt_arbiter.gd")
const ARBITER_NODE := preload("res://scripts/world/interaction_arbiter.gd")
const CONFIG_PATH := "res://data/config/movement.json"

## How close the trainer has to be for the mount prompt to appear. Generous for
## the same reason `interactable.gd`'s default radius is: a prompt that only
## shows up when you are inside the animal reads as a prompt that is broken.
## TUNABLE.
const MOUNT_RADIUS := 4.5

signal mounted(body: Node3D)
signal dismounted()

@export var player_path: NodePath
@export var camera_rig_path: NodePath
@export var encounter_path: NodePath
@export var manager_path: NodePath

var _player: Node3D = null
var _camera_rig: Node = null
var _encounter: Node = null
var _manager: Node = null
var _arbiter: Node = null

## The body being ridden, or null. Never an id or an index: the thing that can
## be despawned out from under this node is the NODE, and holding anything else
## would mean asking the director every frame whether the answer still points at
## something alive.
var _mount: Node3D = null
## Whether a ride is in progress, tracked separately from `_mount` for the same
## measured reason `player_controller._carried` exists: a FREED Object reference
## compares EQUAL to null in GDScript, so `if _mount != null` goes false the
## moment the creature is deleted and the despawn branch below — the one written
## for exactly that event — is skipped. `is_instance_valid()` is the only honest
## test of "is it still there", and this flag is the only honest test of "were we
## on it".
var _riding_now: bool = false
## Where the mount was last seen standing. The only thing left to put the player
## down on if the mount is freed mid-ride (dismiss, a fight tearing it down, a
## scene change), which is the failure this whole variable exists for.
var _last_mount_position: Vector3 = Vector3.ZERO

var _ride_camera: Dictionary = {}
var _walk_speed: float = 5.0


func _ready() -> void:
	_player = get_node_or_null(player_path) as Node3D
	_camera_rig = get_node_or_null(camera_rig_path)
	_encounter = get_node_or_null(encounter_path)
	_manager = get_node_or_null(manager_path)
	_load_config()
	_attach()


func _load_config() -> void:
	var file := FileAccess.open(CONFIG_PATH, FileAccess.READ)
	if file == null:
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		return
	var cfg: Dictionary = parsed
	_walk_speed = float((cfg.get("locomotion", {}) as Dictionary).get("walk_speed", _walk_speed))
	var riding: Variant = cfg.get("riding", {})
	if riding is Dictionary:
		var block: Dictionary = riding
		var camera: Variant = block.get("camera", {})
		if camera is Dictionary:
			_ride_camera = camera


## Same late, group-based attach `interactable.gd` uses, and for the same
## reason: this node must not care where in the tree the arbiter sits, and a
## scene with no arbiter at all (the combat sandbox) simply has no ride prompt
## rather than a broken one.
func _attach() -> void:
	if _arbiter != null and is_instance_valid(_arbiter):
		return
	_arbiter = get_tree().get_first_node_in_group(ARBITER_NODE.GROUP)
	if _arbiter != null:
		_arbiter.call("register", self)


func _exit_tree() -> void:
	if _arbiter != null and is_instance_valid(_arbiter):
		_arbiter.call("unregister", self)
	_arbiter = null


## --- state ------------------------------------------------------------------

func is_mounted() -> bool:
	return _riding_now and is_instance_valid(_mount)


func mount_body() -> Node3D:
	return _mount if is_mounted() else null


## The speed the current mount travels at, m/s. Zero when not mounted. Read by
## the smoke test, which has to prove riding actually beats running rather than
## trusting the multiplier in the data file.
func ride_speed() -> float:
	if not is_mounted():
		return 0.0
	return _ride_speed_for(str(_mount.get("species_id")))


func _ride_speed_for(species_id: String) -> float:
	var block := SPECIES.rideable(species_id)
	if block.is_empty():
		return 0.0
	return _walk_speed * float(block.get("ride_speed_multiplier", 1.5))


## --- can we ride right now? -------------------------------------------------

## The creature standing in the world that could be mounted, or null.
##
## Only ever the player's OWN active creature: the encounter director's ally
## body. A wild Meadowhart is not a mount you can climb onto, and a trainer's is
## not yours to touch — CLAUDE.md's five-creature rule cuts the same way here as
## it does for catching.
func _mountable_body() -> Node3D:
	if _encounter == null or not is_instance_valid(_encounter):
		return null
	var body: Node3D = _encounter.call("ally_body")
	if body == null or not is_instance_valid(body) or not body.visible:
		return null
	if not SPECIES.is_rideable(str(body.get("species_id"))):
		return null
	var instance: RefCounted = _encounter.call("ally_instance")
	# A creature on its side does not carry anybody. The director already
	# refuses to summon a fainted creature; this is the same rule for a creature
	# that fainted while it was already out.
	if instance != null and bool(instance.get("fainted")):
		return null
	return body


## Do we own the tack this species needs? `requires_item` is per-species on
## purpose (see species.json's `_comment_rideable`) so R8.5's legendary can want
## different gear without this function growing a second branch.
func _has_tack(species_id: String) -> bool:
	var required := str(SPECIES.rideable(species_id).get("requires_item", ""))
	if required == "":
		return true
	var game := get_node_or_null(^"/root/Game")
	if game == null:
		return false
	var bag: RefCounted = game.get("inventory")
	return bag != null and int(bag.call("count", required)) > 0


## Everything that says "not now", in one place, so mounting and staying mounted
## cannot disagree about what a legal moment is.
##
## The arbiter's own `enabled` flag is the single check that covers a running
## fight, a trainer battle between rounds, an open conversation, the naming
## prompt, the starter picker, a screen fade and an armed build ghost — see
## `sequence_director.gd::_refresh_lockout()`, which computes exactly that set.
## Reusing it means a new modal added there is automatically a modal that ends a
## ride, instead of a modal somebody has to remember to list here too.
##
## The pause menu is NOT in this list and does not end a ride: opening it pauses
## the tree, so this node stops ticking and the ride is simply frozen with
## everything else. Being thrown off your mount for checking the map would be a
## worse game than being put back where you were.
func _riding_allowed() -> bool:
	if _manager != null and is_instance_valid(_manager) and bool(_manager.call("is_fighting")):
		return false
	if _encounter != null and is_instance_valid(_encounter) \
			and _encounter.has_method("trainer_battle_active") \
			and bool(_encounter.call("trainer_battle_active")):
		return false
	if _arbiter != null and is_instance_valid(_arbiter) and not bool(_arbiter.call("enabled")):
		return false
	return true


## --- mounting ---------------------------------------------------------------

## Get on. Returns whether it happened, so a caller driving this from a test can
## tell a refused press from a missed one — same contract
## `interaction_arbiter.activate()` uses.
func mount() -> bool:
	if is_mounted() or _player == null or not is_instance_valid(_player):
		return false
	if not _riding_allowed():
		return false
	var body := _mountable_body()
	if body == null:
		return false
	var species_id := str(body.get("species_id"))
	if not _has_tack(species_id):
		return false
	if _player.global_position.distance_to(body.global_position) > MOUNT_RADIUS:
		return false

	_mount = body
	_riding_now = true
	_last_mount_position = body.global_position

	# The follower stops following. It is being driven by the stick now, and two
	# things calling `request_move` on one creature in one frame is one of them
	# silently losing — `encounter_director._set_exploration_active()` states the
	# same rule for combat, for the same body.
	if body.has_method("set_following"):
		body.call("set_following", false)

	var offset: Vector3 = SPECIES.rideable(species_id).get("mount_offset", Vector3.UP)
	_player.call("set_carrier", body, offset)
	if _camera_rig != null and is_instance_valid(_camera_rig) and _camera_rig.has_method("set_target"):
		_camera_rig.call("set_target", body, _ride_camera)
	mounted.emit(body)
	return true


## Get off, for any reason: the player asked, a fight started, the creature was
## dismissed, the world took the screen. One exit, so no route off a mount can
## restore half the state.
##
## Safe to call when not mounted, and safe to call when the mount has already
## been freed — the freed case is the one it most has to survive, because the
## alternative is an invisible trainer with no collision standing wherever the
## creature was when it stopped existing.
func dismount() -> bool:
	if not _riding_now:
		return false
	var body := _mount
	_mount = null
	_riding_now = false

	var alive := is_instance_valid(body)
	if alive:
		_last_mount_position = body.global_position

	if _player != null and is_instance_valid(_player):
		_player.call("set_carrier", null)
		_player.global_position = _dismount_spot(body if alive else null)
	if alive and body.has_method("set_following") and _riding_allowed():
		# Straight back to walking beside you. Skipped when a fight is what
		# ended the ride: the combat manager is about to drive this same body,
		# and `_set_exploration_active(false)` has already said so.
		body.call("set_following", true)
	if _camera_rig != null and is_instance_valid(_camera_rig) and _camera_rig.has_method("set_target"):
		_camera_rig.call("set_target", _player, {})
	dismounted.emit()
	return true


## Where the trainer's feet go when they get off.
##
## Beside the mount rather than inside it, at the mount's own feet height —
## a creature standing on the ground is itself the best available evidence of
## where the ground is, which is why the freed-mount case (`body == null`) can
## still use the last position it was seen at and is never left guessing.
## The world's own `ground_height_at` is preferred where the scene offers it,
## for the same reason `creature_body.place_on_ground` asks the world before it
## casts a ray (D09).
func _dismount_spot(body: Node3D) -> Vector3:
	var base := _last_mount_position
	var side := Vector3.RIGHT
	var distance := 1.6
	if body != null:
		base = body.global_position
		side = body.global_transform.basis.x
		var block := SPECIES.rideable(str(body.get("species_id")))
		if not block.is_empty():
			distance = float(block.get("dismount_distance", distance))
	side.y = 0.0
	if side.length() < 0.01:
		side = Vector3.RIGHT
	var spot := base + side.normalized() * distance
	var ground := _ground_height(spot)
	# A small lift so the trainer settles DOWN onto the ground over a frame or
	# two rather than starting a hair inside it, which reads as being stuck.
	spot.y = (ground if not is_nan(ground) else base.y) + 0.2
	return spot


func _ground_height(at: Vector3) -> float:
	var world := get_parent()
	if world != null and world.has_method("ground_height_at"):
		return float(world.call("ground_height_at", at.x, at.z))
	return NAN


## --- driving ----------------------------------------------------------------

func _physics_process(_delta: float) -> void:
	_attach()
	if not is_mounted():
		if _riding_now:
			# The body was freed while we held it. This is the despawn case:
			# dismount() puts the player back at the last place the mount was
			# standing, visible, collidable and under their own power.
			dismount()
		return
	if not _riding_allowed():
		dismount()
		return

	_last_mount_position = _mount.global_position

	var input := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	if input == Vector2.ZERO:
		return
	var direction := Vector3(input.x, 0.0, input.y)
	if _camera_rig != null and is_instance_valid(_camera_rig) and _camera_rig.has_method("planar_basis"):
		var basis_value: Basis = _camera_rig.call("planar_basis")
		direction = basis_value * direction
	direction.y = 0.0
	if direction.length() < 0.01:
		return
	# The one line that is riding. Everything else about how the creature moves
	# is the creature's, unchanged.
	_mount.call("request_move", direction.normalized(), ride_speed())


## --- the provider contract, see scripts/world/interaction_arbiter.gd --------
##
## No line-of-sight test, unlike `interactable.gd`. That check exists because
## Grandpa's prompt reached through the loft floor; the thing being offered here
## is a two-metre animal standing four metres away that walked to this spot
## behind you. There is nothing for it to be occluded by that it did not follow
## you through.

func interaction_offer(from: Vector3) -> Dictionary:
	if is_mounted():
		# Beats proximity: with a creature under you, nothing you could walk
		# past matters more than being able to get off it.
		return PROMPTS.offer("Dismount", 0.0, 50)
	if not _riding_allowed():
		return {}
	var body := _mountable_body()
	if body == null:
		return {}
	var distance := from.distance_to(body.global_position)
	if distance > MOUNT_RADIUS:
		return {}
	var species_id := str(body.get("species_id"))
	var label := str(body.get("display_name"))
	if not _has_tack(species_id):
		# A statement, not an offer — the same shape the director uses for a
		# fainted creature. Telling the player what is missing is the only
		# place the saddle recipe gets taught in the world; a silent absence of
		# a prompt teaches nothing.
		var tack := str(SPECIES.rideable(species_id).get("requires_item", ""))
		return PROMPTS.offer("%s needs a %s." % [label, _item_name(tack)], distance, 0, false)
	return PROMPTS.offer("Ride %s" % label, distance)


func interaction_activate() -> void:
	if is_mounted():
		dismount()
		return
	mount()


func _item_name(item_id: String) -> String:
	var game := get_node_or_null(^"/root/Game")
	if game == null:
		return item_id
	var items: RefCounted = game.get("items")
	if items == null:
		return item_id
	var label := str(items.call("item_name", item_id))
	return label if label != "" else item_id
