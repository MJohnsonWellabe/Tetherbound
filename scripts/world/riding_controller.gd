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
const BUILD_HOLD := preload("res://scripts/build/build_hold.gd")
const ARBITER_NODE := preload("res://scripts/world/interaction_arbiter.gd")
const INPUT_OWNER := preload("res://scripts/ui/input_owner.gd")
const CONFIG_PATH := "res://data/config/movement.json"
## W14-RIDING / CL-O3. Everything about the RIDE rather than about the animal:
## the sprint multiplier, the hop height, and the rider's seated pose. Kept out
## of movement.json because that file is the TRAINER's locomotion sheet and the
## two drift apart -- see riding.json's own header.
const RIDING_CONFIG_PATH := "res://data/config/riding.json"

## How close the trainer has to be for the mount prompt to appear. Generous for
## the same reason `interactable.gd`'s default radius is: a prompt that only
## shows up when you are inside the animal reads as a prompt that is broken.
## TUNABLE.
const MOUNT_RADIUS := 4.5

## Below the priority-0 default every ordinary `interactable.gd` provider
## uses (trainers, chests, harvest nodes, ...), but above the -1
## `encounter_director.gd::_creature_control_offer()` falls back to for its
## own non-actionable "Put X away"/"Call out X" status line -- see
## `interaction_offer()`'s own comment for why the gap between them matters:
## a mount that TIES with that status line loses to it (worse, since pressing
## a status line does nothing), which is what happens if this is ever moved
## to -1 to match it instead of sitting between the two.
const RIDE_PRIORITY := -1

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

## W14-RIDING / CL-O3, from data/config/riding.json. Read once at ready, the
## same way `_ride_camera` is: these are tuning numbers, not live state.
var _sprint_multiplier: float = 1.4
var _jump_height: float = 1.6
var _jump_cooldown: float = 0.35
## Seconds left before the mount will accept another hop. Counted down rather
## than timestamped so a paused tree (the map, the pause menu) does not silently
## bank cooldown while nothing is ticking.
var _jump_cooldown_left: float = 0.0
## Whether the stick is currently asking the mount to run. Read by the smoke
## test, which has to prove the mount actually goes faster rather than trusting
## the multiplier in the data file.
var _sprinting: bool = false


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
	_load_riding_config()


func _load_riding_config() -> void:
	var cfg := riding_config()
	var sprint: Variant = cfg.get("sprint", {})
	if sprint is Dictionary:
		_sprint_multiplier = float((sprint as Dictionary).get("speed_multiplier", _sprint_multiplier))
	var jump: Variant = cfg.get("jump", {})
	if jump is Dictionary:
		_jump_height = float((jump as Dictionary).get("height", _jump_height))
		_jump_cooldown = float((jump as Dictionary).get("cooldown_seconds", _jump_cooldown))


## data/config/riding.json, parsed. Static so `trainer_model.gd` reads the
## rider's seated pose out of the SAME file this node reads the ride out of,
## without either of them owning a copy of the other's numbers.
static func riding_config() -> Dictionary:
	var file := FileAccess.open(RIDING_CONFIG_PATH, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	return parsed if parsed is Dictionary else {}


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


## The speed the current mount travels at, m/s, at a WALK. Zero when not
## mounted. Read by the smoke test, which has to prove riding actually beats
## running rather than trusting the multiplier in the data file.
func ride_speed() -> float:
	if not is_mounted():
		return 0.0
	return _ride_speed_for(str(_mount.get("species_id")))


## W14-RIDING / CL-O3. The speed the mount is being asked for RIGHT NOW: the
## walk above, multiplied while the sprint button is held. Owner, on hardware:
## "You can't sprint or jump when riding."
##
## One multiplier on the species' own ride speed rather than a second speed
## table, for the same reason `ride_speed_multiplier` multiplies the trainer's
## walk instead of naming an absolute: retuning a mount moves one number.
func ride_speed_now() -> float:
	var base := ride_speed()
	return base * _sprint_multiplier if _sprinting else base


## The top speed this mount can be asked for. Data, not live state, so a test
## can price the sprint before it drives it.
func ride_sprint_speed() -> float:
	return ride_speed() * _sprint_multiplier


## Is the mount running? False when not mounted, and false the frame the stick
## goes to centre — sprint is speed, not a mode.
func is_ride_sprinting() -> bool:
	return is_mounted() and _sprinting


## Metres of clearance a hop asks for. Read by the smoke test so the hop is
## checked against what the mount was ASKED for rather than a number typed twice.
func ride_jump_height() -> float:
	return _jump_height


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

	_apply_climb_limit(body, species_id)
	# Putting it on. The saddle stays on afterwards -- see the saddle rule
	# below for why "only while you are sitting on it" was the wrong reading of
	# the owner's sentence.
	fit_saddle(body)
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
	_restore_climb_limit(body if alive else null)

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

func _physics_process(delta: float) -> void:
	_attach()
	_jump_cooldown_left = maxf(0.0, _jump_cooldown_left - delta)
	# Every frame, on both branches: a creature that was summoned since the last
	# tick has to put its saddle back on, and one whose saddle was never fitted
	# has to be standing there without one. See `_refresh_worn_saddle()`.
	_refresh_worn_saddle()
	if not is_mounted():
		if _riding_now:
			# The body was freed while we held it. This is the despawn case:
			# dismount() puts the player back at the last place the mount was
			# standing, visible, collidable and under their own power.
			dismount()
		_sprinting = false
		return
	if not _riding_allowed():
		dismount()
		return

	_last_mount_position = _mount.global_position

	# RG5's rule, applied to the mount. `jump` and the build menu's own
	# `ui_accept` are the SAME physical button (project.godot: joypad button 0),
	# and `build_menu.gd` deliberately does not pause the tree -- so without
	# this, confirming a piece in the catalogue would hop the creature you are
	# sitting on. `player_controller._try_jump()` already asks this question for
	# the trainer; a mounted player is the same button and the same panel.
	var input_owned := INPUT_OWNER.current(get_tree()) != null

	# OP-0904-3's second item: the mount jumps. A real hop, not a nudge --
	# `riding.json`'s height clears the low fences and rocks a walking player
	# vaults with `player_controller._try_step_up()`. The rider stays seated
	# through it for free: they are parented to the mount's transform by
	# `set_carrier`, so the arc is the creature's and the trainer simply goes
	# with it, which is exactly what a rider does.
	if not input_owned and Input.is_action_just_pressed("jump") and _jump_cooldown_left <= 0.0 \
			and _mount.has_method("request_jump"):
		_mount.call("request_jump", _jump_height)
		_jump_cooldown_left = _jump_cooldown

	var input := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	# Sprint is speed, not a mode: held with the stick centred it does nothing,
	# the same rule `player_controller._apply_movement()` uses for the trainer.
	# D48 §3 and D75: it costs the player nothing and the mount has no meter.
	_sprinting = not input_owned and input != Vector2.ZERO \
		and Input.is_action_pressed("sprint")
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
	_mount.call("request_move", direction.normalized(), ride_speed_now())


## --- R8.5: the tier above Meadowhart ----------------------------------------
##
## Part of the legendary's tier. Its `rideable` block carries
## `climb_max_slope_deg`, and while it is being ridden that becomes the
## creature body's own `floor_max_angle` — so ground that slides every other
## creature in the roster off holds this one. The baseline is MEASURED rather
## than assumed: `scenes/creatures/creature.tscn` already gives every creature
## 55 degrees (the trainer's own body gets 45), so the legendary's 60 is a
## capability none of the others have, not a restatement of one they all do.
##
## Deliberately the smallest thing that could possibly work: `move_and_slide()`
## already reads that property every physics frame on every CharacterBody3D, so
## there is no climb state, no second locomotion path and no new movement code
## — the same "riding changes the speed it asks for, nothing else" rule this
## file opens with, extended by exactly one property.
##
## It is set on MOUNT and put back on DISMOUNT, never left on the body: a
## legendary walking beside you as a follower is an ordinary creature, and a
## permanent 55-degree floor on a body the combat AI also drives would change
## fights nobody tuned for it.
##
## The ceiling matters and species.json says why: every severed spoke's carve
## walls are 65-66 degrees, so this stays a mobility perk and never a way out
## of the Meadows (D23's carve-out). `tests/smoke_boss.gd` drives a probe body
## at this limit against the storm-road seam to keep that true, and
## `tests/smoke_riding.gd` fails if the number is ever raised into that band.
##
## The legendary's OTHER advantage needs no code at all and is deliberately not
## here: its `requires_item` is empty, so `_has_tack()` above already lets it be
## ridden with nothing in the bag. A mount that needs no saddle is the whole
## point of that key having been per-species since R6.2.
func _apply_climb_limit(body: Node3D, species_id: String) -> void:
	var limit := float(SPECIES.rideable(species_id).get("climb_max_slope_deg", 0.0))
	if limit <= 0.0 or not body is CharacterBody3D:
		return
	var character := body as CharacterBody3D
	# Remembered on the body rather than in a field here, so a ride that ends
	# through the despawn path (this node's `_mount` already freed) still has
	# somewhere honest to read the old value back from if the body survives.
	if not character.has_meta("ride_floor_max_angle"):
		character.set_meta("ride_floor_max_angle", character.floor_max_angle)
	character.floor_max_angle = deg_to_rad(limit)


func _restore_climb_limit(body: Node3D) -> void:
	if body == null or not is_instance_valid(body) or not body is CharacterBody3D:
		return
	var character := body as CharacterBody3D
	if not character.has_meta("ride_floor_max_angle"):
		return
	character.floor_max_angle = float(character.get_meta("ride_floor_max_angle"))
	character.remove_meta("ride_floor_max_angle")


## --- the saddle rule (OP-0904-3, CL-O3) -------------------------------------
##
## Owner, playing the shipped build: *"Nothing that is rideable should come with
## a saddle on it. You have to build the saddle and put it on then it visually
## appears. It shouldn't visually be there."*
##
## That is three claims and they are tested separately in
## `tests/test_riding_saddle.gd`:
##
##   1. **Never at spawn.** No rideable species' scene or mesh carries a saddle,
##      and nothing here attaches one until it is fitted. This half was already
##      true before this lane and is now pinned by a test that spawns every
##      species carrying a `rideable` block and asserts the node is absent.
##   2. **Built.** `_has_tack()` already refuses to mount without the item, and
##      the item is the tournament's prize (`D48` §4, `test_recipes.gd`'s
##      `TOURNAMENT_GATED_RECIPE`). Nothing is fitted that was not crafted.
##   3. **Then it visually appears — and STAYS.** This is what changed. The
##      saddle used to be attached in `mount()` and torn off again in
##      `dismount()`, so it existed only for as long as you were sitting on it:
##      the visible proof of the craft was invisible in every moment the player
##      would actually look at their creature. `fit_saddle()` now records the
##      fit and the saddle is worn from then on, following, standing, resting or
##      being ridden.
##
## **Where "fitted" lives, and why it is a flag rather than a field on the
## creature.** `autoload/progression_state.gd`'s flag store is saved and loaded
## with the game, and this node can write it without reaching into
## `creature_instance.gd`'s serialisation — which this lane does not own and
## which would have to grow a field, a save key and a migration for a boolean.
## The flag is per-SPECIES (`saddle_fitted_meadowhart`), so a second Meadowhart
## in a five-creature roster wears the saddle its species was fitted for. That
## is a deliberate simplification and it is recorded in `D75`; the alternative
## reads as a bug the first time a player swaps mounts and finds bare leather.
##
## **The legendary is exempt and stays exempt.** Its `requires_item` is empty
## (`species.json`'s own `_comment_rideable`: *"it carries you because it
## offered to"*), so there is no saddle to fit and none is ever attached —
## strapping the crafting bench's leather to it would be the wrong sentence
## about what just happened in that chamber. The check below is on the species'
## own required item, not on "is it rideable".
const SADDLE_MODEL := "res://assets/props/riding_saddle/riding_saddle.glb"
## The item whose craft this mesh is the proof of. A species asking for
## different tack (`requires_item`) is a species this saddle is not for.
const SADDLE_ITEM := "saddle"
const SADDLE_NODE := ^"RideSaddle"
## Fallback scale and vertical offset when a species carries no seat block
## of its own. `mount_offset` is the RIDER's seat, a little under the
## creature's own back line (see that key's own comment in species.json);
## the saddle sits just below that, on the back itself, hence the small
## downward nudge rather than reusing the offset unchanged.
const SADDLE_SCALE := 0.5
const SADDLE_Y_NUDGE := -0.12


## Is THIS saddle the tack this species wants? False for a species that needs
## none (the legendary) and false for one that names different gear, so the
## mesh is never hung on an animal the craft was not for. Pure data, so
## `tests/test_riding_saddle.gd` can hold the rule without standing a body up.
static func saddle_belongs_on(species_id: String) -> bool:
	return str(SPECIES.rideable(species_id).get("requires_item", "")) == SADDLE_ITEM


## Has a saddle been built and fitted to this species? Saved with the game.
##
## `store` exists for the unit test and for nothing else: the flag store is
## normally `/root/Game`'s, and `tests/run_tests.gd` does all its work inside
## `_init()`, before the tree has autoloads — so a test that could not be
## handed a store could only assert against a null one, which passes for the
## wrong reason.
static func saddle_is_fitted(species_id: String, store: RefCounted = null) -> bool:
	var flags: RefCounted = store if store != null else _progression()
	if flags == null:
		return false
	return bool(flags.call("has", saddle_fitted_flag(species_id)))


static func saddle_fitted_flag(species_id: String) -> String:
	return "saddle_fitted_%s" % species_id


static func _progression() -> RefCounted:
	var loop := Engine.get_main_loop()
	if loop == null or not loop is SceneTree:
		return null
	var game := (loop as SceneTree).root.get_node_or_null(^"/root/Game")
	return game.get("progression") if game != null else null


## Put the saddle on. The moment the owner's sentence turns on: the item has
## been built, the player is putting it on the animal, and from here it is
## visibly there. Returns whether anything was fitted, so a caller can tell a
## refusal from a no-op.
##
## Called by `mount()`, because getting on is the act of putting it on and the
## project has no spare button for a second one (D48 §1: riding spends no new
## binding). A species that needs no tack is never fitted; see the header.
func fit_saddle(body: Node3D) -> bool:
	if body == null or not is_instance_valid(body):
		return false
	var species_id := str(body.get("species_id"))
	if not saddle_belongs_on(species_id):
		return false
	if not _has_tack(species_id):
		return false
	var store := _progression()
	if store != null:
		store.call("set_flag", saddle_fitted_flag(species_id))
	_attach_saddle(body, species_id)
	return true


## The creature standing in the world wears its saddle if, and only if, one has
## been fitted to its species. Ticked every frame rather than hooked onto a
## summon signal for the reason this file's own header gives: a gate set once
## when something changed is a gate that is wrong the first time something else
## touches it — and the ally body is destroyed and rebuilt by
## `encounter_director.gd` on every dismiss, every fight and every scene change.
func _refresh_worn_saddle() -> void:
	if _encounter == null or not is_instance_valid(_encounter):
		return
	var body: Node3D = _encounter.call("ally_body")
	if body == null or not is_instance_valid(body):
		return
	var species_id := str(body.get("species_id"))
	var wanted := saddle_belongs_on(species_id) and saddle_is_fitted(species_id)
	var worn := body.get_node_or_null(SADDLE_NODE) != null
	if wanted and not worn:
		_attach_saddle(body, species_id)
	elif worn and not wanted:
		_detach_saddle(body)


func _attach_saddle(body: Node3D, species_id: String) -> void:
	if body == null or not is_instance_valid(body):
		return
	_detach_saddle(body)
	var resource: Resource = load(SADDLE_MODEL)
	var visual: Node3D = null
	if resource is PackedScene:
		visual = (resource as PackedScene).instantiate()
	elif resource is Mesh:
		var mesh_instance := MeshInstance3D.new()
		mesh_instance.mesh = resource
		visual = mesh_instance
	if visual == null:
		return
	visual.name = "RideSaddle"
	var offset: Vector3 = SPECIES.rideable(species_id).get("mount_offset", Vector3.UP)
	visual.position = Vector3(offset.x, offset.y + SADDLE_Y_NUDGE, offset.z)
	visual.scale = Vector3.ONE * SADDLE_SCALE
	body.add_child(visual)


func _detach_saddle(body: Node3D) -> void:
	if body == null or not is_instance_valid(body):
		return
	var existing := body.get_node_or_null(SADDLE_NODE)
	if existing != null:
		existing.queue_free()
		# Named nodes are only freed at the end of the frame, so a re-attach in
		# the same tick would find the old one still sitting there and Godot
		# would rename the new one `RideSaddle2` -- which `_refresh_worn_saddle`
		# would then never see and would re-add forever.
		existing.name = "RideSaddleRemoved"


## The slope, in degrees, the current mount treats as floor. The trainer's own
## 45 when the mount has no opinion, and zero when nothing is being ridden —
## read by the smoke test so the legendary's tier is proved against the live
## body rather than against the number in the data file.
func ride_climb_limit_deg() -> float:
	if not is_mounted():
		return 0.0
	if not _mount is CharacterBody3D:
		return 0.0
	return rad_to_deg((_mount as CharacterBody3D).floor_max_angle)


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
		# past matters more than being able to get off it. Deliberately still
		# offered with the hammer out -- see BUILD_HOLD's own header.
		return PROMPTS.offer("Dismount", 0.0, 50)
	if not _riding_allowed():
		return {}
	# OWNER DIRECTIVE 2026-08-23 §3: Build owns Interact while the hammer is
	# out. This offer is actionable and the creature making it FOLLOWS the
	# player, so without this there is no spot in the open field from which
	# `playground_hud.gd::_hammer_opens_the_catalogue()` can win the button --
	# measured in `tools/_probe_hammer_gate.gd`. Riding is not lost, only
	# deferred: put the hammer away and the offer is back the same frame.
	if BUILD_HOLD.hammer_is_out(get_tree()):
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
		return PROMPTS.offer("%s needs a %s." % [label, _item_name(tack)], distance, RIDE_PRIORITY, false)
	# RIDE_PRIORITY (-1), not the ordinary-interactable default of 0. Riding a
	# creature that is just following you is the least deliberate thing a
	# player can be reaching for -- it is always in range, any time, by
	# design -- so it should never win a tie against something that is only
	# reachable right here and right now: a trainer's challenge, a chest, a
	# harvest node, all still on `interactable.gd`'s ordinary priority-0
	# default. Without this, `_dismount_spot` (below) lands the mount within
	# `dismount_distance` of the player and it then FOLLOWS at roughly that
	# distance indefinitely, so a rider who dismounts next to whatever they
	# actually came to interact with -- ride up to a captain, dismount,
	# challenge is this segment's OWN designed sequence
	# (`docs/acceptance/GATE_F_MASTER_PROTOCOL.md` section B's S08 span: "...saddle &
	# riding -> three captains...") -- has their own dismissed mount silently
	# winning `prompt_arbiter.gd`'s nearest-wins tiebreak and remounting them
	# instead of opening the challenge. Found live by `ralph/GATE-F-LEG-S08`'s
	# isolated S08 run: camera distance round-tripped 6.8 -> 5.2 -> 6.8 across
	# a dismount then a captain-challenge press, proving the "challenge" press
	# actually remounted instead -- and a plain 1.5 s post-dismount cooldown
	# was NOT enough on its own, because a follower keeps pace this close for
	# as long as it is following, not just for the first couple of seconds.
	return PROMPTS.offer("Ride %s" % label, distance, RIDE_PRIORITY)


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
