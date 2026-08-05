extends CharacterBody3D

## Third-person locomotion: walk, sprint, jump, stamina, fall damage.
##
## M1's whole job. Nothing here knows about pals, combat or the world beyond the
## ground it stands on, and it should stay that way until traversal feels good
## on the Ally (docs/MEADOWS_VERTICAL_SLICE.md M1 acceptance).
##
## Every number comes from data/config/movement.json. If a value is typed into
## this file, that is a bug: the owner's feedback in M1 is going to be "too
## floaty", "sprint too slow", "camera too close", and each of those has to be
## answerable by editing data, not code.

const CONFIG_PATH := "res://data/config/movement.json"
const VITALS := preload("res://scripts/player/player_vitals.gd")

## The key this node owns inside `SaveManager`'s one envelope (D14).
##
## The TRAINER — where they are standing, what their meters read, and what they
## have eaten. Not their items: those are `TrainerInventory`'s domain, because the
## bag is a thing in its own right that a satchel and a chest also talk to.
##
## `SaveDirector` finds contributors by walking the tree for `save_data` /
## `load_data` plus this constant, so being a save domain costs this file nothing
## but the two methods at the bottom.
const SAVE_DOMAIN := "trainer"

signal landed(impact_speed: float, damage: float)
signal died()

var vitals: RefCounted = VITALS.new()

@export var camera_rig_path: NodePath
## The trainer's bag. M9's `TrainerInventory` node, which is what `inventory()`
## below hands out — see its header for the interface other systems call.
@export var inventory_path: NodePath = NodePath("../TrainerInventory")
## The world, for `ground_height_at`. Defaults to the parent, which is where the
## playground puts the player; exported so a test scene can point elsewhere.
@export var world_path: NodePath = NodePath("..")
var _camera_rig: Node3D = null
var _model: Node3D = null
var _world: Node = null

var _walk_speed: float = 4.2
var _sprint_speed: float = 7.6
var _ground_accel: float = 42.0
var _ground_friction: float = 38.0
var _air_accel: float = 9.0
var _turn_speed: float = 11.0

var _jump_velocity: float = 7.0
var _gravity: float = 26.0
var _fall_multiplier: float = 1.35
var _coyote_time: float = 0.12
var _buffer_time: float = 0.12

## Time since last leaving the ground, for coyote time.
var _airborne_for: float = 0.0
## Time since jump was pressed, for input buffering.
var _jump_buffered_for: float = INF
## Downward speed on the frame before landing, since velocity.y is zeroed by
## the time is_on_floor() reports true.
var _fall_speed: float = 0.0
var _was_on_floor: bool = true
var _sprinting: bool = false

## Cleared while a fight is running. Gravity, landing and stamina keep ticking —
## the trainer is still a body standing in the world, and switching them off
## leaves the player hovering wherever combat happened to open.
var _locomotion_enabled: bool = true

## How far below the heightfield the body may legitimately sit before it is
## treated as embedded rather than as noise.
##
## Not zero. The heightfield is SAMPLED and the collider is MESHED from it, so
## the two disagree by centimetres on any slope, and a rescue that fired on every
## such disagreement would be teleporting the player constantly. The observed
## embedding was 0.52-0.74m, so this sits well clear of both.
var _embed_tolerance: float = 0.35

## Rescues so far, and how many get a warning before it goes quiet. A body that
## embeds once is an incident; one that embeds every frame is a different bug,
## and a log with ten thousand identical lines in it hides that rather than
## showing it.
var _embed_rescues: int = 0
const EMBED_WARN_LIMIT := 5


func _ready() -> void:
	_load_config()
	_camera_rig = get_node_or_null(camera_rig_path) as Node3D
	_model = get_node_or_null(^"Model") as Node3D
	_world = get_node_or_null(world_path)
	if _world != null and not _world.has_method("ground_height_at"):
		_world = null
	if _camera_rig != null and _camera_rig.has_method("set_target"):
		_camera_rig.call("set_target", self)


func _load_config() -> void:
	var file := FileAccess.open(CONFIG_PATH, FileAccess.READ)
	if file == null:
		push_error("movement.json missing at %s" % CONFIG_PATH)
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		push_error("movement.json is not valid JSON")
		return
	var config: Dictionary = parsed

	var loco: Dictionary = config.get("locomotion", {})
	_walk_speed = float(loco.get("walk_speed", _walk_speed))
	_sprint_speed = float(loco.get("sprint_speed", _sprint_speed))
	_ground_accel = float(loco.get("ground_acceleration", _ground_accel))
	_ground_friction = float(loco.get("ground_friction", _ground_friction))
	_air_accel = float(loco.get("air_acceleration", _air_accel))
	_turn_speed = float(loco.get("turn_speed", _turn_speed))

	var jump: Dictionary = config.get("jump", {})
	_gravity = float(jump.get("gravity", _gravity))
	_fall_multiplier = float(jump.get("fall_gravity_multiplier", _fall_multiplier))
	_coyote_time = float(jump.get("coyote_time", _coyote_time))
	_buffer_time = float(jump.get("buffer_time", _buffer_time))
	# Derived from height so retuning gravity does not silently change how high
	# the character jumps, which is the usual way this pair drifts apart.
	_jump_velocity = sqrt(2.0 * _gravity * float(jump.get("height", 1.35)))

	vitals.configure(config)


func _physics_process(delta: float) -> void:
	if _settling_after_load():
		return
	_track_airborne(delta)
	_apply_gravity(delta)
	_apply_movement(delta)
	_try_jump()

	var falling_speed := -velocity.y
	move_and_slide()
	_resolve_landing(falling_speed)
	_stay_above_ground()

	vitals.tick(delta, _sprinting and velocity.length() > 0.5)


## Refuse to be underneath the terrain.
##
## `smoke_traversal` failed one run in three, and the counter said "the ground is
## not continuous", which was a conclusion rather than a finding. Instrumented,
## the same three words came out every time:
##
##     at -6.40, 0.57, 21.12   velocity 0.00, -54.06, 0.00
##     terrain height 1.18, player 0.57, gap -0.61
##     hit 0..5: Terrain  normal -0.00, -0.00, -1.00  (90.0 deg from up)
##
## The player is **inside the ground** — half a metre under the surface, gaining
## fall speed it never converts into movement, in contact with six perfectly
## axis-aligned VERTICAL faces. Not a hole, not a prop, not a slope past the
## floor limit: embedded in the collision mesh, where depenetration can only push
## sideways and `is_on_floor()` can never become true. Which is why the streak ran
## for three thousand frames instead of ending in a fall.
##
## This is a floor of last resort, and D09 is the reason it is allowed to be one:
## `ground_height_at` reads Terrain3D's own heightmap rather than asking the
## physics server, so it is the one source that cannot be wrong in the way the
## collider just was. When the two disagree about which side of the ground the
## player is on, the heightfield wins.
##
## HONEST LIMIT: this contains the symptom, it does not explain it. Why the body
## gets embedded at all — most likely a collision chunk rebuilding around it as
## regions stream — is not established, and this net will keep it playable
## rather than making it correct. It is deliberately silent about small
## disagreements and loud about large ones, so if the real cause ever gets worse
## the warnings say so instead of the net hiding it.
func _stay_above_ground() -> void:
	if _world == null:
		return
	var ground: float = float(_world.call("ground_height_at", global_position.x, global_position.z))
	if is_nan(ground):
		return

	# The capsule sits at +0.9 local with a 1.8 height, so its base is exactly at
	# the body origin: `global_position.y` IS the height of the feet.
	var below := ground - global_position.y
	if below <= _embed_tolerance:
		return

	global_position.y = ground
	# The fall is over — it ended in the ground rather than on it. Leaving the
	# accumulated speed would apply it again on the next frame and drive the body
	# straight back in.
	velocity.y = 0.0
	_embed_rescues += 1
	if _embed_rescues <= EMBED_WARN_LIMIT:
		push_warning("player was %.2fm inside the terrain at %.1f, %.1f; lifted to the heightfield" % [
			below, global_position.x, global_position.z
		])


func _track_airborne(delta: float) -> void:
	if is_on_floor():
		_airborne_for = 0.0
	else:
		_airborne_for += delta

	if Input.is_action_just_pressed("jump"):
		_jump_buffered_for = 0.0
	else:
		_jump_buffered_for += delta


func _apply_gravity(delta: float) -> void:
	if is_on_floor():
		# A small downward bias keeps the body pinned to slopes; without it the
		# character skips off the crest of every hill it walks over.
		velocity.y = -2.0
		return
	var scale := _fall_multiplier if velocity.y < 0.0 else 1.0
	velocity.y -= _gravity * scale * delta


func _apply_movement(delta: float) -> void:
	var input := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	if not _locomotion_enabled:
		# Read as no input rather than skipped entirely, so the existing friction
		# brings the trainer to a stop instead of freezing them mid-stride.
		input = Vector2.ZERO
	var direction := Vector3.ZERO
	if input != Vector2.ZERO and _camera_rig != null and _camera_rig.has_method("planar_basis"):
		var basis_value: Basis = _camera_rig.call("planar_basis")
		direction = (basis_value * Vector3(input.x, 0.0, input.y)).normalized()

	_sprinting = Input.is_action_pressed("sprint") and vitals.can_sprint() and input != Vector2.ZERO
	var target_speed := _sprint_speed if _sprinting else _walk_speed

	var horizontal := Vector3(velocity.x, 0.0, velocity.z)
	var accel := _ground_accel if is_on_floor() else _air_accel

	if direction == Vector3.ZERO:
		# Friction only on the ground. Air-braking to a stop mid-jump is the
		# other half of what reads as "floaty".
		if is_on_floor():
			horizontal = horizontal.move_toward(Vector3.ZERO, _ground_friction * delta)
	else:
		horizontal = horizontal.move_toward(direction * target_speed, accel * delta)
		_face(direction, delta)

	velocity.x = horizontal.x
	velocity.z = horizontal.z


func _face(direction: Vector3, delta: float) -> void:
	if _model == null:
		return
	var target_yaw := atan2(direction.x, direction.z)
	_model.rotation.y = rotate_toward(_model.rotation.y, target_yaw, _turn_speed * delta)


func _try_jump() -> void:
	if not _locomotion_enabled:
		return
	var grounded_enough := is_on_floor() or _airborne_for <= _coyote_time
	var asked_recently := _jump_buffered_for <= _buffer_time
	if not (grounded_enough and asked_recently):
		return
	if not vitals.try_spend_jump():
		return
	velocity.y = _jump_velocity
	_jump_buffered_for = INF
	_airborne_for = _coyote_time + 1.0   # consume coyote so one press is one jump


## Something in the world hurt the trainer. Returns the damage actually taken.
##
## The ONE way anything other than a fall can damage the player, so that "what
## can kill me" is a list of callers of this function rather than a search for
## writes to `vitals.health`.
##
## GAME_DESIGN.md §14 says the trainer is not attacked while a fight is running
## and, outside one, that aggressive wild pals can threaten them. The owner has
## amended what "threaten" means when every owned pal is fainted: the creature
## does not merely posture, it hurts you, and getting home is the answer. That
## decision is `encounter_director.Hunt`'s to make and this is only where the
## damage lands.
##
## The trainer has no way to hit back and is not going to get one. There is no
## `attack()` beside this, no weapon slot, and no route into combat for the human
## — CLAUDE.md's "human cannot fight" is a hard rule and being hurtable is not
## the same thing as being a fighter.
##
## DEATH IS NOT IMPLEMENTED HERE. `died` is emitted, exactly as a lethal fall
## already emits it, and nothing listens. §22's satchel, the respawn at the bed
## and the "pals go home" rule are MEADOWS_VERTICAL_SLICE M9's player-death
## bullet, with their own rules about dropped inventory.
func hurt(amount: float) -> float:
	if vitals.is_dead():
		return 0.0
	var dealt: float = vitals.take_damage(amount)
	if dealt > 0.0 and vitals.is_dead():
		died.emit()
	return dealt


func _resolve_landing(falling_speed: float) -> void:
	var on_floor := is_on_floor()
	if on_floor and not _was_on_floor:
		var damage: float = vitals.apply_landing(maxf(falling_speed, 0.0))
		landed.emit(falling_speed, damage)
		if vitals.is_dead():
			died.emit()
	_was_on_floor = on_floor
	_fall_speed = falling_speed


## Horizontal speed, for the HUD and for animation later.
func ground_speed() -> float:
	return Vector3(velocity.x, 0.0, velocity.z).length()


func is_sprinting() -> bool:
	return _sprinting


## Suspend or restore walking and jumping. Called by the encounter director when
## a fight opens and closes; nothing here knows what combat is.
func set_locomotion_enabled(enabled: bool) -> void:
	_locomotion_enabled = enabled
	if not enabled:
		_jump_buffered_for = INF


func locomotion_enabled() -> bool:
	return _locomotion_enabled


## --- the trainer's things ---------------------------------------------------

## The bag, as the `inventory.gd` instance itself.
##
## Reached THROUGH the player because that is how the rest of the game already
## asks — `scripts/pals/recovery.gd` looks for an `inventory()` on whatever it is
## pointed at, and a gathering system holding the trainer would otherwise have to
## know the shape of the world scene to find their pockets. It forwards and owns
## nothing: `TrainerInventory` is the owner and the save contributor.
func inventory() -> RefCounted:
	var bag: Node = get_node_or_null(inventory_path)
	if bag == null or not bag.has_method("inventory"):
		return null
	return bag.call("inventory") as RefCounted


## --- save contributor -------------------------------------------------------
##
## Position, facing and vitals. A player who quits on a hilltop should not come
## back at the spawn point with full health, and — the part that matters after M9
## — a player who dies, wakes up at their bed and closes the window must not come
## back standing where they died.

func save_data() -> Dictionary:
	var record: Dictionary = {
		"x": global_position.x,
		"y": global_position.y,
		"z": global_position.z,
		"yaw": 0.0 if _model == null else _model.rotation.y,
	}
	record.merge(vitals.to_record())
	return record


func load_data(data: Dictionary) -> void:
	global_position = Vector3(
		float(data.get("x", global_position.x)),
		float(data.get("y", global_position.y)),
		float(data.get("z", global_position.z))
	)
	# A restored body that keeps the velocity it had while the world was being
	# rebuilt resumes that motion on the first frame.
	velocity = Vector3.ZERO
	_restore_to = global_position
	_settle_frames = 0
	if _model != null:
		_model.rotation.y = float(data.get("yaw", _model.rotation.y))
	vitals.from_record(data)


## A RESTORED BODY DOES NOT SIMULATE UNTIL THERE IS GROUND UNDER IT.
##
## `SaveDirector` restores a frame after the scene is built, and the world is
## still setting itself up at that point: `playground_world._ready()` awaits two
## process frames for Terrain3D to publish its data before it drops the player
## onto the baked ground. A position restored inside that window is a position
## with no collision under it yet — and when the collision does arrive, the body
## is INSIDE it.
##
## MEASURED, and it is not subtle: a trainer restored to 0, 0, 0 was ejected by
## depenetration at 456 metres per second and was two kilometres away and still
## accelerating three hundred frames later. It looked like a save bug ("the
## trainer came back 2249m from where they were left") and it was a physics one.
##
## So the body holds still — no gravity, no input, no `move_and_slide` — until the
## heightfield can answer for the spot it was restored to, and is then placed just
## above it. D09: the height comes from `ground_height_at`, never a raycast. The
## frame budget is a floor of last resort so a world with no heightfield at all
## simulates normally rather than freezing the player forever.
const RESTORE_SETTLE_FRAMES := 240
## The same two metres `playground_world.SPAWN_CLEARANCE` drops a new player from,
## and for the reason written there: the collision mesh is BAKED from the
## heightfield and the two disagree by up to half a metre on a slope, so a body
## put down flush against the sampled height can arrive inside the collider.
##
## A tenth of a metre was tried first. It produced exactly the 456 m/s ejection
## this whole mechanism exists to prevent — the settle was working and the landing
## was still inside the ground. Two metres and a short fall is the honest answer.
const RESTORE_CLEARANCE := 2.0

## Where a load put the body, while it waits for ground. `Vector3.INF` when there
## is nothing to settle.
var _restore_to: Vector3 = Vector3.INF
var _settle_frames: int = 0


func _settling_after_load() -> bool:
	if _restore_to == Vector3.INF:
		return false
	velocity = Vector3.ZERO
	global_position = _restore_to
	_settle_frames += 1

	if _world == null:
		_restore_to = Vector3.INF
		return false

	var ground: float = float(_world.call("ground_height_at", _restore_to.x, _restore_to.z))
	if not is_nan(ground):
		global_position = Vector3(
			_restore_to.x, maxf(_restore_to.y, ground + RESTORE_CLEARANCE), _restore_to.z
		)
		_restore_to = Vector3.INF
		return false

	if _settle_frames >= RESTORE_SETTLE_FRAMES:
		push_warning("no heightfield under the restored trainer after %d frames; simulating anyway"
			% RESTORE_SETTLE_FRAMES)
		_restore_to = Vector3.INF
	return true
