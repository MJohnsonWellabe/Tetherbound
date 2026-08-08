extends Node

## Riding. The trainer on the back of a creature that can carry them.
##
## `MEADOWS_VERTICAL_SLICE.md` M12 and `GAME_DESIGN.md` §17. Riding is the ONLY
## traversal verb in this slice: §17 lists ride, swim, fly and teleport as a
## progression and §32 puts the last three outside the first Meadows, so there is
## no swimming, no flying and no teleport here, not even as a disabled branch.
##
## WHAT THIS IS, MECHANICALLY: the creature becomes the thing that walks, and the
## trainer becomes a passenger. `pal_body` already knows how to move a creature
## over this terrain — gravity, slopes, the world's own ground query, and a clip
## map with `Gallop` in it — so riding drives that rather than growing a second
## locomotion system next to the trainer's. What is left here is small: read the
## stick, ask the body to move, put the trainer on its back, and spend the
## creature's stamina.
##
## THE TRAINER STILL CANNOT FIGHT, mounted or not. There is no attack here, no
## aim, no target and nothing that can be pointed at a creature. CLAUDE.md's
## "human cannot fight" is a hard rule and being carried is not a loophole in it.
##
## A MOUNT IS A PARTY MEMBER, NOT A VEHICLE SLOT. The creature ridden is the
## party's own active pal — the same one that would be deployed if a fight
## started — so riding cannot be a sixth thing you own and there is nowhere here
## for a mount to be stored. Five is five (CLAUDE.md, `party.gd`).
##
## D09 IS BINDING. Nothing in this file casts a ray downwards to find the floor.
## The creature is stood up by `pal_body.place_on_ground`, which asks the world's
## heightfield first, and the dismount spot comes from the same `ground_height_at`
## the world offers. Roughly a quarter of downward rays miss terrain that is
## demonstrably there, so a mount placed by ray would drop through the world one
## time in four, intermittently, and read as a physics bug.

const SPECIES := preload("res://scripts/pals/pal_species.gd")
const BODY_SCENE := preload("res://scenes/pals/pal.tscn")
## `pal.tscn` deliberately carries no script; the role picks one. A ridden
## creature is a plain body — it is driven from here and has no AI of its own.
const BODY_SCRIPT := preload("res://scripts/pals/pal_body.gd")

const CONFIG_PATH := "res://data/config/movement.json"

## The button. See `project.godot` for why this is a new action rather than
## `interact`, which three systems already read and one of which would fire in
## the same frame as this.
const ACTION := "mount"
## Held to gallop. `sprint` reused on purpose: it already means "go faster", and
## it is dead input for a trainer whose own legs are not carrying him.
const GALLOP_ACTION := "sprint"

## THE ONE SADDLE. §17: "Riding saddle is generic across compatible rideable
## pals", and M12's last bullet is "no species-specific saddle clutter". This
## constant is singular and there is no table beside it mapping species to tack —
## the day a second id appears here, that bullet has been broken.
const SADDLE_ITEM := "riding_saddle"

signal mounted(species_id: String)
signal dismounted(species_id: String)
## Why a press did nothing, as a stable token rather than a sentence — the idiom
## `party.gd` and `inventory.gd` use, for the reason they give: this file has no
## business knowing how a refusal is worded on a 7-inch screen.
signal refused(token: String)

const REFUSED_BUSY := "busy"
const REFUSED_NO_PARTY := "no_party"
const REFUSED_NO_PAL := "no_pal"
const REFUSED_FAINTED := "pal_fainted"
const REFUSED_NOT_RIDEABLE := "not_rideable"
const REFUSED_NO_SADDLE := "no_saddle"
const REFUSED_NO_GROUND := "no_ground"

const REFUSALS := [
	REFUSED_BUSY,
	REFUSED_NO_PARTY,
	REFUSED_NO_PAL,
	REFUSED_FAINTED,
	REFUSED_NOT_RIDEABLE,
	REFUSED_NO_SADDLE,
	REFUSED_NO_GROUND,
]


## The mount's own stamina.
##
## A RefCounted with no scene in it, for the reason `encounter_director.Hunt`
## gives about itself: everything it decides is decidable from a clock and a
## number, and that is what lets `tests/test_mount.gd` prove the rules — that a
## gallop ends, and that ending one does not end the ride — with no world at all.
##
## IT IS THE CREATURE'S, NOT THE TRAINER'S, and that is the decision M12's
## "riding stamina if needed" asks for. The trainer's meter means "what my body
## can still do"; spending it on a creature's legs makes travelling compete with
## jumping and climbing, so arriving somewhere would leave you unable to do
## anything there. Mounted, the trainer's stamina is untouched and in fact
## regenerates — he is sitting down.
##
## And it costs the GALLOP only. The base pace is free forever, so a drained
## mount slows to something still faster than a sprint rather than stopping: a
## gallop that never ends makes the walk pointless, and a ride that strands you
## makes the saddle a disappointment.
class Legs extends RefCounted:

	var maximum: float = 100.0
	var drain: float = 9.0
	var regen: float = 14.0
	var regen_delay: float = 0.8
	## Below this the gallop is refused until the meter climbs back past it. The
	## same anti-stutter rule `player_vitals` uses on sprint, and for the same
	## reason: without it, holding the button at zero gallops for one frame per
	## physics tick forever.
	var exhausted_below: float = 20.0

	var stamina: float = 100.0
	var _cooldown: float = 0.0
	var _blown: bool = false

	func configure(cfg: Dictionary) -> void:
		maximum = maxf(1.0, float(cfg.get("max", maximum)))
		drain = maxf(0.0, float(cfg.get("gallop_drain_per_second", drain)))
		regen = maxf(0.0, float(cfg.get("regen_per_second", regen)))
		regen_delay = maxf(0.0, float(cfg.get("regen_delay", regen_delay)))
		exhausted_below = clampf(float(cfg.get("exhausted_below", exhausted_below)), 0.0, maximum)
		stamina = maximum

	func can_gallop() -> bool:
		return not _blown and stamina > 0.0

	func tick(delta: float, galloping: bool) -> void:
		if galloping:
			stamina = maxf(0.0, stamina - drain * delta)
			_cooldown = regen_delay
			if stamina <= 0.0:
				_blown = true
			return
		_cooldown = maxf(0.0, _cooldown - delta)
		if _cooldown <= 0.0:
			stamina = minf(maximum, stamina + regen * delta)
		if _blown and stamina >= exhausted_below:
			_blown = false

	func fraction() -> float:
		return 0.0 if maximum <= 0.0 else clampf(stamina / maximum, 0.0, 1.0)

	func rest() -> void:
		stamina = maximum
		_cooldown = 0.0
		_blown = false


## --- the data ---------------------------------------------------------------
##
## Static and pure, so the rules can be asserted against the shipped data with no
## scene. Every one of these reads a file the milestone owns; none of them
## decides anything a designer has not written down.

static var _config: Dictionary = {}


static func config() -> Dictionary:
	if not _config.is_empty():
		return _config
	var file := FileAccess.open(CONFIG_PATH, FileAccess.READ)
	if file == null:
		push_error("movement.json missing at %s" % CONFIG_PATH)
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if parsed is Dictionary:
		var block: Variant = (parsed as Dictionary).get("riding")
		if block is Dictionary:
			_config = block
	return _config


## Can a saddled trainer get onto this creature?
##
## Defaults to FALSE, the safe direction: a species added without an opinion
## behaves like every creature did before M12 rather than surprising a player by
## being climbable. See `_comment_rideable` in species.json for the rule the
## flags were set by — the back must clear the trainer's hip.
static func is_rideable(species_id: String) -> bool:
	return bool(SPECIES.definition(species_id).get("rideable", false))


static func ride_data(species_id: String) -> Dictionary:
	var block: Variant = SPECIES.definition(species_id).get("ride", {})
	return block if block is Dictionary else {}


## Where the trainer's ORIGIN — the point between his feet — sits in the
## creature's own body-local metres.
##
## One number from the creature (`ride.back_height`, the measured top of its
## back) and one from the trainer (`riding.rider_hip_height`, his measured
## pelvis). Subtracting them puts his hips on its back, which is the only
## definition of "seated" that survives swapping either the mount or the trainer
## model.
static func seat_offset(species_id: String) -> Vector3:
	var ride := ride_data(species_id)
	var hip := float(config().get("rider_hip_height", 1.05))
	return Vector3(
		0.0,
		float(ride.get("back_height", hip)) - hip,
		float(ride.get("back_forward", 0.0))
	)


## How fast this creature travels, cantering or galloping.
##
## The base pace is above the trainer's sprint before any species multiplier, so
## M12's "clear advantage over running" is true of the slowest mount at its
## slowest pace — `tests/test_mount.gd` asserts exactly that against the two
## numbers in `movement.json`, because a bullet phrased as a comparison should
## fail a build when it stops being true.
static func ride_speed(species_id: String, galloping: bool) -> float:
	var cfg := config()
	var top := float(cfg.get("gallop_speed", 13.5)) if galloping \
		else float(cfg.get("base_speed", 9.0))
	return top * float(ride_data(species_id).get("speed_scale", 1.0))


## --- wiring -----------------------------------------------------------------

## The trainer. Set by `player_controller`, which builds this node.
var _player: CharacterBody3D = null
var _camera_rig: Node3D = null
## The party, found by duck typing rather than by a path, so this works in the
## shipping scene, in a preview tool and in a test world without any of them
## having to wire it. The same discovery `tools.gd` uses to find the bag.
var _party: Node = null
## Whatever can answer `ground_height_at`. D09: this, never a ray.
var _world: Node = null

var _body: CharacterBody3D = null
var _species: String = ""
var _seat: Vector3 = Vector3.ZERO
var _legs := Legs.new()
var _refusal: String = ""
var _galloping: bool = false
## The trainer's own AnimationPlayer, found once. Owned by `trainer_model`; see
## `_hold_riding_pose`.
var _trainer_anim: AnimationPlayer = null


func bind(player: CharacterBody3D, camera_rig: Node3D = null) -> void:
	_player = player
	_camera_rig = camera_rig
	_legs.configure(config().get("stamina", {}))


func _ready() -> void:
	if _player == null:
		_player = get_parent() as CharacterBody3D
	_legs.configure(config().get("stamina", {}))


func is_mounted() -> bool:
	return _body != null and is_instance_valid(_body)


func species_id() -> String:
	return _species


func body() -> Node3D:
	return _body


func stamina_fraction() -> float:
	return _legs.fraction()


func is_galloping() -> bool:
	return _galloping


func last_refusal() -> String:
	return _refusal


## --- the loop ---------------------------------------------------------------

func _physics_process(delta: float) -> void:
	if _player == null or not is_instance_valid(_player):
		return
	_read_input()
	if not is_mounted():
		# The mount recovers while it is put away, so getting off to look at
		# something is not a punishment.
		_legs.tick(delta, false)
		return
	_drive(delta)


func _read_input() -> void:
	if not Input.is_action_just_pressed(ACTION):
		return
	if is_mounted():
		dismount()
	else:
		mount()


## Drive the creature and carry the trainer.
##
## Both halves happen here, in `_physics_process`, so the order the engine runs
## nodes in cannot matter: the trainer is placed from where the body IS, and the
## body is then asked to move. A version that read the body's position from
## `_process` was correct too and depended on node order to stay that way.
func _drive(delta: float) -> void:
	if not is_instance_valid(_body):
		_clear()
		return

	var input := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction := Vector3.ZERO
	if input != Vector2.ZERO and _camera_rig != null and _camera_rig.has_method("planar_basis"):
		var basis_value: Basis = _camera_rig.call("planar_basis")
		direction = (basis_value * Vector3(input.x, 0.0, input.y)).normalized()
	elif input != Vector2.ZERO:
		direction = Vector3(input.x, 0.0, input.y).normalized()

	var moving := direction != Vector3.ZERO
	_galloping = moving and Input.is_action_pressed(GALLOP_ACTION) and _legs.can_gallop()
	_legs.tick(delta, _galloping)

	# Stick magnitude scales the pace, so the mount can be walked. Without it the
	# only speeds are "stopped" and "flat out", and a gallop you cannot decline is
	# a gallop that has to be balanced as if it were free.
	if moving:
		var pace := ride_speed(_species, _galloping) * clampf(input.length(), 0.0, 1.0)
		_body.call("request_move", direction, pace)

	_seat_the_trainer()


## Put the trainer on the creature's back, facing where it faces.
##
## The seat is body-LOCAL, so it is carried around by the creature's own
## transform and stays on its back through every turn. The trainer's body is not
## simulated while this is happening — see `player_controller._physics_process` —
## so nothing is fighting this for the position.
func _seat_the_trainer() -> void:
	_player.global_position = _body.global_transform * _seat
	_player.velocity = Vector3.ZERO
	if _player.has_method("set_model_yaw"):
		_player.call("set_model_yaw", _body.rotation.y)
	_hold_riding_pose()


## Hold the trainer in a riding pose.
##
## THE ANIMATION LIBRARY HAS NO SEATED CLIP. All 25 clips merged onto the trainer
## were listed and there is no sit, no mount, no ride: the nearest thing to a
## rider is `Jump_Idle`, whose legs are bent under the body. Everything else is a
## man standing up straight, and a man standing up straight on an animal's back
## is the failure this project has already had a review about — invisible to
## every assertion in `tests/test_mount.gd` and the first thing anyone sees.
##
## WHICH clip is data (`riding.trainer_pose` in movement.json) for the reason
## `species.json` keeps its own clip names in data: the trainer's pack can be
## replaced, and a name typed into this file would make that a code change. Blank
## in the config means "leave him alone", so this whole mechanism can be switched
## off from data if a later pack ships a real seated clip and `art.json` drives
## it properly.
##
## HOW IT COEXISTS WITH `trainer_model`, which owns this AnimationPlayer:
## `trainer_model._play` returns early when the clip it wants is the one it last
## asked for AND something is playing, so it does not fight this — it asks for
## `Idle_A`, sees it is still the clip it asked for and that the player is busy,
## and leaves. The re-check below is what makes that safe rather than lucky: if
## anything ever does take the pose back, it is reclaimed on the next frame
## rather than for the rest of the ride.
##
## HONEST LIMIT: this is a borrowed pose, not a riding animation. It does not
## bend to the mount, the legs do not sit on a barrel, and on a narrow-bodied
## creature they hang below the belly. The real fix is a seated clip in the
## trainer's animation library and a `ride` role in `data/config/art.json` —
## both files this milestone does not own. See the M12 report.
func _hold_riding_pose() -> void:
	var wanted := str(config().get("trainer_pose", ""))
	if wanted == "":
		return
	if _trainer_anim == null or not is_instance_valid(_trainer_anim):
		_trainer_anim = _find_trainer_anim()
	if _trainer_anim == null or not _trainer_anim.has_animation(wanted):
		return
	# `is_playing` as well as the name, because the chosen clip does not loop:
	# `trainer_model._apply_loops` only marks the four roles art.json lists, and
	# a stopped AnimationPlayer is exactly what makes that file restart the idle.
	if _trainer_anim.current_animation != wanted or not _trainer_anim.is_playing():
		_trainer_anim.play(wanted, 0.18)

	# HELD AT ONE FRAME, not played.
	#
	# Every clip in this library is an ANIMATION and they all move. `Jump_Idle`
	# was the obvious pick and it is wrong: a second into its loop the arms are
	# spread wide for balance, which from the game's own camera — which is behind
	# the player — is a trainer riding in a T-pose. So the pose is pinned to the
	# one frame that reads as a rider (see movement.json for how it was chosen).
	#
	# Re-seeking every frame rather than pausing, because a paused player is a
	# stopped player and `trainer_model._play` takes the pose straight back. This
	# also keeps the clip nowhere near its end, which is what stops a non-looping
	# clip running out.
	var at := float(config().get("trainer_pose_at", -1.0))
	if at >= 0.0:
		_trainer_anim.seek(at, true)


func _find_trainer_anim() -> AnimationPlayer:
	for node in _player.find_children("*", "AnimationPlayer", true, false):
		return node as AnimationPlayer
	return null


## --- mounting ---------------------------------------------------------------

## Call the active pal and get on it. Returns whether it happened; `refused`
## carries the token when it did not.
func mount() -> bool:
	if is_mounted():
		return false
	# One gate for every reason riding is unavailable, checked in the order a
	# player would meet them.
	if _player == null or not is_instance_valid(_player):
		return _refuse(REFUSED_BUSY)
	# Locomotion is taken away by a fight and by an open menu. Both of those are
	# somebody else's state and neither is this file's to interpret — asking the
	# trainer whether he is currently allowed to move is one question that covers
	# every present and future reason he is not.
	if _player.has_method("locomotion_enabled") and not bool(_player.call("locomotion_enabled")):
		return _refuse(REFUSED_BUSY)

	var party := _find_party()
	if party == null:
		return _refuse(REFUSED_NO_PARTY)
	var pal: RefCounted = party.call("active") as RefCounted
	if pal == null:
		return _refuse(REFUSED_NO_PAL)
	if bool(pal.get("fainted")):
		return _refuse(REFUSED_FAINTED)
	var id := str(pal.get("species_id"))
	if not is_rideable(id):
		return _refuse(REFUSED_NOT_RIDEABLE)
	if not _has_saddle():
		return _refuse(REFUSED_NO_SADDLE)

	var creature := _spawn_body(id)
	if creature == null:
		return _refuse(REFUSED_NO_GROUND)

	_body = creature
	_species = id
	_seat = seat_offset(id)
	_galloping = false
	# Excepted rather than layer-masked. The trainer's capsule is INSIDE the
	# creature's while he is on its back, and two CharacterBody3Ds resolving that
	# overlap shove each other — the same failure `pal_body._on_visibility_changed`
	# records, which launched the trainer off the playground at 500 m/s.
	_body.add_collision_exception_with(_player)
	_player.add_collision_exception_with(_body)
	_exclude_from_camera(_body)
	_apply_camera(config().get("camera", {}))
	_seat_the_trainer()

	_refusal = ""
	print("[mount] riding %s (back %.2fm, seat %.2fm, %.1f m/s base)" % [
		SPECIES.display_name(id), float(ride_data(id).get("back_height", 0.0)),
		_seat.y, ride_speed(id, false)
	])
	mounted.emit(id)
	return true


## Get off. Safe to call when not mounted.
func dismount() -> void:
	if not is_mounted():
		return
	var id := _species
	var spot := _dismount_spot()
	_body.remove_collision_exception_with(_player)
	_player.remove_collision_exception_with(_body)
	_stop_excluding_from_camera(_body)
	_body.queue_free()
	_clear()

	_player.global_position = spot
	_player.velocity = Vector3.ZERO
	_apply_camera({})
	print("[mount] dismounted %s" % SPECIES.display_name(id))
	dismounted.emit(id)


## The ride ends because something else took the world over — a fight opening, a
## menu, a death.
##
## THE RULE FOR A FIGHT STARTING WHILE MOUNTED, and it is deliberately the
## smallest one available: you get off, and the fight then runs exactly as it
## always has. No new combat mode, no mounted attack, nothing added to
## `scripts/combat/` at all. The creature carrying you IS the party's active pal,
## so it is the creature that was going to be deployed anyway — dismounting hands
## it to the fight rather than taking it away.
##
## You CAN still be ambushed while riding: an aggressive wild pal initiates on
## proximity (`encounter_director._on_wild_wants_to_engage`) and being mounted
## changes none of its conditions. It simply ends with your feet on the ground.
##
## Wired through `set_locomotion_enabled(false)`, which is already the one door
## in and out of exploration, so a future way of suspending the trainer gets this
## for free instead of having to remember it.
func forced_dismount() -> void:
	if is_mounted():
		dismount()


func _refuse(token: String) -> bool:
	_refusal = token
	refused.emit(token)
	return false


func _clear() -> void:
	_body = null
	_species = ""
	_seat = Vector3.ZERO
	_galloping = false


func _has_saddle() -> bool:
	if not _player.has_method("inventory"):
		return false
	var bag: RefCounted = _player.call("inventory") as RefCounted
	if bag == null:
		return false
	return int(bag.call("count_of", SADDLE_ITEM)) > 0


## Build the creature and stand it where the trainer is standing.
##
## Returns null rather than a floating creature if the ground cannot be found:
## `pal_body.place_on_ground` asks the world's heightfield and only then falls
## back to a ray (D09), and a spot neither can answer for is a spot to refuse
## rather than to drop an animal into.
func _spawn_body(id: String) -> CharacterBody3D:
	var creature: CharacterBody3D = BODY_SCENE.instantiate()
	creature.set_script(BODY_SCRIPT)
	creature.name = "RiddenPal"
	var parent: Node = _find_world()
	if parent == null:
		parent = _player.get_parent()
	if parent == null:
		creature.free()
		return null
	parent.add_child(creature)
	creature.call("setup", id)
	if not bool(creature.call("place_on_ground", _player.global_position)):
		creature.queue_free()
		return null
	creature.call("face_towards", _player.global_position + _facing())
	return creature


## Where the trainer faces now, so the creature appears pointing the same way
## rather than spinning to some default on the frame it is called.
func _facing() -> Vector3:
	if _camera_rig != null and _camera_rig.has_method("planar_basis"):
		var basis_value: Basis = _camera_rig.call("planar_basis")
		return basis_value * Vector3(0.0, 0.0, 1.0)
	return Vector3.FORWARD


## Beside the creature, on the ground.
##
## D09 ALL THE WAY DOWN: the height comes from the world's heightfield, and if
## the world cannot answer, the trainer is put down at the creature's own feet —
## which is a known-good height, because the creature is standing on it. There is
## no ray in this path and there must not be one; a dismount that dropped the
## trainer through the floor one time in four would look like a collision bug and
## be a placement one.
func _dismount_spot() -> Vector3:
	var cfg := config()
	var side := float(cfg.get("dismount_side", 1.3))
	var clearance := float(cfg.get("dismount_clearance", 0.3))
	var at: Vector3 = _body.global_position + _body.global_transform.basis.x * side

	var world := _find_world()
	var ground := NAN
	if world != null:
		ground = float(world.call("ground_height_at", at.x, at.z))
	if is_nan(ground):
		ground = _body.global_position.y
	return Vector3(at.x, ground + clearance, at.z)


## --- the camera -------------------------------------------------------------

func _apply_camera(profile: Dictionary) -> void:
	if _camera_rig == null or not _camera_rig.has_method("set_target"):
		return
	_camera_rig.call("set_target", _player, profile)


## The arm must ignore the creature as well as the trainer.
##
## `SpringArm3D` collapses on the first thing it touches, and mounted, the thing
## between the camera and its target is the animal's own hindquarters — so
## without this the whole ride is played from a camera buried in a rump. Exactly
## the failure `camera_rig.set_target` already records about the player's pal
## during a fight, arriving from the other direction.
func _exclude_from_camera(node: Node3D) -> void:
	if _camera_rig != null and _camera_rig.has_method("exclude_from_arm"):
		_camera_rig.call("exclude_from_arm", node)


func _stop_excluding_from_camera(node: Node3D) -> void:
	if _camera_rig != null and _camera_rig.has_method("stop_excluding"):
		_camera_rig.call("stop_excluding", node)


## --- finding the rest of the scene ------------------------------------------
##
## Duck-typed and cached, the idiom `pal_body._find_ground_source` and
## `tools.gd`'s inventory lookup already use. It is what lets a mount work in the
## shipping scene, in `tools/preview_riding.gd` and in a bare test world without
## three exported NodePaths that each have to be right.

func _find_party() -> Node:
	if _party != null and is_instance_valid(_party):
		return _party
	_party = null
	var root: Node = _player.get_parent() if _player != null else null
	if root == null:
		return null
	for child in root.get_children():
		if child.has_method("active") and child.has_method("capacity"):
			_party = child
			break
	return _party


func _find_world() -> Node:
	if _world != null and is_instance_valid(_world):
		return _world
	_world = null
	var node: Node = _player.get_parent() if _player != null else null
	while node != null:
		if node.has_method("ground_height_at"):
			_world = node
			break
		node = node.get_parent()
	return _world
