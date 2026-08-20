extends CharacterBody3D

## Third-person locomotion: walk, sprint, jump, stamina, fall damage.
##
## M1's whole job. Nothing here knows about creatures, combat or the world beyond the
## ground it stands on, and it should stay that way until traversal feels good
## on the Ally (docs/MEADOWS_VERTICAL_SLICE.md M1 acceptance).
##
## Every number comes from data/config/movement.json. If a value is typed into
## this file, that is a bug: the owner's feedback in M1 is going to be "too
## floaty", "sprint too slow", "camera too close", and each of those has to be
## answerable by editing data, not code.

const CONFIG_PATH := "res://data/config/movement.json"
const VITALS_CONFIG_PATH := "res://data/config/vitals.json"
const VITALS := preload("res://scripts/player/player_vitals.gd")
const TORCH := preload("res://scripts/player/torch.gd")
const TOOL_HOLD := preload("res://scripts/player/tool_hold.gd")
const INPUT_OWNER := preload("res://scripts/ui/input_owner.gd")

signal landed(impact_speed: float, damage: float)
signal died()

var vitals: RefCounted = VITALS.new()
## The torch's light (scripts/player/torch.gd) -- built here from the first
## frame like `tool_hold` below, but only actually lit while `torch` is the
## equipped tool (OW12; see that file's own header). Exposed the same way
## `vitals` is, so the HUD can read `torch.is_on()` without reaching past
## this node.
var torch: Node3D = null

## The tool in the trainer's hand, and the swing that harvests with it. Held
## here for the same reason `torch` and `vitals` are: the HUD and the harvest
## nodes ask the player for it rather than hunting the tree for it.
var tool_hold: Node3D = null

@export var camera_rig_path: NodePath
var _camera_rig: Node3D = null
var _model: Node3D = null

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

## R6.1. Something else is carrying this body: a node whose transform this one
## rides on, plus the local offset to sit at.
##
## Deliberately a bare Node3D rather than "the mount". This file's own header
## promises it knows nothing about creatures, and it still does not — it knows
## that a body can be carried, which is the same statement a lift or a cart
## would need. `riding_controller.gd` is the thing that knows the carrier is a
## Meadowhart.
##
## While carried, the trainer runs NO locomotion of its own: no gravity, no
## friction, no jump, no move_and_slide. Two things writing one transform in one
## frame is one of them silently losing, the same rule `_set_exploration_active`
## states for the ally body.
var _carrier: Node3D = null
## Whether this body is currently being carried, tracked separately from
## `_carrier` because a FREED Object reference compares equal to null in
## GDScript. `if _carrier != null` therefore goes false the instant the mount is
## deleted, which silently skips the one branch written to handle exactly that —
## measured, not guessed (tests/smoke_riding.gd's despawn case caught it leaving
## the trainer invisible and collisionless).
var _carried: bool = false
var _carry_offset: Vector3 = Vector3.ZERO
## Saved so dismounting restores exactly what mounting took, rather than
## assuming the layer this scene happened to ship with.
var _carry_saved_layer: int = 0
var _carry_saved_mask: int = 0


func _ready() -> void:
	_load_config()
	_camera_rig = get_node_or_null(camera_rig_path) as Node3D
	_model = get_node_or_null(^"Model") as Node3D
	if _camera_rig != null and _camera_rig.has_method("set_target"):
		_camera_rig.call("set_target", self)

	torch = TORCH.new()
	torch.name = "Torch"
	add_child(torch)

	tool_hold = TOOL_HOLD.new()
	tool_hold.name = "ToolHold"
	add_child(tool_hold)
	if tool_hold.has_signal("swing_started"):
		tool_hold.connect("swing_started", _on_tool_swing_started)

	# RG7: if a slot was loaded before this scene existed (title -> Load), Game
	# retained the pose and can finally apply it now that Player/CameraRig exist.
	var game := get_node_or_null(^"/root/Game")
	if game != null and game.has_method("apply_loaded_player_pose"):
		game.call_deferred("apply_loaded_player_pose")


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
	_load_vitals_config()


## D29 satiety. Separate file from movement.json so hunger tuning does not
## get mixed into the locomotion sheet it has nothing to do with.
func _load_vitals_config() -> void:
	var file := FileAccess.open(VITALS_CONFIG_PATH, FileAccess.READ)
	if file == null:
		push_error("vitals.json missing at %s" % VITALS_CONFIG_PATH)
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		push_error("vitals.json is not valid JSON")
		return
	vitals.configure_satiety(parsed as Dictionary)


func _physics_process(delta: float) -> void:
	if _carried:
		_ride(delta)
		return
	# RG5 (owner playtest, 2026-08-18): "when the building menu is up, pressing
	# directions and pressing a still controls the character too as the menu."
	# `build_menu.gd` is the one panel that deliberately does not pause the
	# tree (its own header explains why), so this node kept polling movement
	# and jump underneath it -- and `jump` and the menu's own `ui_accept`
	# (picking a piece) are bound to the SAME physical button (project.godot:
	# joypad button 0), so confirming a piece also jumped the trainer. Every
	# other world-verb poll already asks `input_owner.gd` this same question
	# (`build_placer.gd`, `interaction_arbiter.gd`); this was the one that
	# never had, despite being the most obviously affected by a leak.
	var input_owned := INPUT_OWNER.current(get_tree()) != null
	_track_airborne(delta, input_owned)
	_apply_gravity(delta)
	_apply_movement(delta, input_owned)
	_try_jump(input_owned)

	var falling_speed := -velocity.y
	# Captured BEFORE move_and_slide: sliding against a wall zeroes the
	# into-wall component of velocity, which is precisely the motion the
	# step-up probe needs to test.
	var planned_motion := Vector3(velocity.x, 0.0, velocity.z) * delta
	move_and_slide()
	_try_step_up(planned_motion)
	_resolve_landing(falling_speed)

	vitals.tick(delta, _sprinting and velocity.length() > 0.5)
	vitals.tick_satiety(delta)


## Step up small ledges instead of stopping dead against them.
##
## Godot 4's CharacterBody3D has no built-in step offset, and the gap has been
## a documented constraint since the loft bug: "a CharacterBody3D cannot step
## UP a ledge: run it across the stair head and the loft is a cell"
## (grandpa_house.gd, which shortened a beam rather than fix this). The
## owner's brief asked for the traversal audit that finally fixes it.
##
## Shape: only when grounded, moving, and pressed against a wall. Three probes
## through the physics server's own sweep (`test_move`), never a teleport into
## unchecked space: (1) headroom straight up by the step height, (2) forward at
## the raised height by this frame's motion, (3) back down onto the step. The
## landing must be walkable ground (normal within `floor_max_angle`), so a
## steep bank does not become climbable by being approached in 0.35m slices.
##
## STEP_HEIGHT is deliberately small. Kerbs, stair treads, bridge lips and
## rock shelves are in; every intentional barrier stays a barrier -- the
## terrain carves are 11m walls, the arena ring is code, and a fence rail is
## over a metre. TUNABLE, but raise it knowing every barrier in the game was
## sized against players who cannot climb.
const STEP_HEIGHT := 0.35
## Minimum forward advance of the step probe. Far enough past the lip that the
## landing contact is walkable (sin(0.25/0.4) = 38.7 degrees, inside the 45 the
## body accepts), small enough that a step never reads as a lunge. TUNABLE.
const STEP_FORWARD_PROBE := 0.25


func _try_step_up(motion: Vector3) -> void:
	if not is_on_wall() or not is_on_floor():
		return
	if motion.length() < 0.001:
		return

	# One frame of walk motion is ~7cm -- nowhere near enough to carry the
	# capsule's 0.4m-radius bottom OVER a ledge lip, so a frame-sized probe
	# lands on the edge at a wall-steep contact normal forever (measured: the
	# first version fired every frame and never once stepped). The probe
	# advances at least far enough that the landing contact sits inside the
	# capsule's walkable cone. The whole path is swept at the raised height
	# first, so this can never push the body through geometry.
	var probe := motion.normalized() * maxf(motion.length(), STEP_FORWARD_PROBE)
	var up := Vector3.UP * STEP_HEIGHT
	if test_move(global_transform, up):
		return
	var raised := global_transform.translated(up)
	if test_move(raised, probe):
		return
	var forward := raised.translated(probe)
	var drop := PhysicsTestMotionResult3D.new()
	var params := PhysicsTestMotionParameters3D.new()
	params.from = forward
	params.motion = Vector3.DOWN * STEP_HEIGHT
	if not PhysicsServer3D.body_test_motion(get_rid(), params, drop):
		return
	if drop.get_collision_normal().angle_to(Vector3.UP) > floor_max_angle:
		return
	global_position = forward.origin + Vector3.DOWN * drop.get_travel().length()
	# The step ate this frame's forward motion; killing the upward remnant of
	# the slide keeps the camera from popping.
	velocity.y = minf(velocity.y, 0.0)


func _track_airborne(delta: float, input_owned: bool) -> void:
	if is_on_floor():
		_airborne_for = 0.0
	else:
		_airborne_for += delta

	# A jump press swallowed while a panel owns input must not sit BUFFERED
	# either -- the buffer window (`_buffer_time`) would otherwise fire the
	# jump the instant the panel closed, the same leak one frame later.
	if not input_owned and Input.is_action_just_pressed("jump"):
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


func _apply_movement(delta: float, input_owned: bool) -> void:
	var input := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	if not _locomotion_enabled or input_owned:
		# Read as no input rather than skipped entirely, so the existing friction
		# brings the trainer to a stop instead of freezing them mid-stride.
		input = Vector2.ZERO
	var direction := Vector3.ZERO
	if input != Vector2.ZERO and _camera_rig != null and _camera_rig.has_method("planar_basis"):
		var basis_value: Basis = _camera_rig.call("planar_basis")
		direction = (basis_value * Vector3(input.x, 0.0, input.y)).normalized()

	_sprinting = Input.is_action_pressed("sprint") and vitals.can_sprint() and input != Vector2.ZERO
	# D29: critical hunger softens ground speed a little; never below that,
	# and never enough on its own to strand the player.
	var target_speed: float = (_sprint_speed if _sprinting else _walk_speed) * vitals.move_speed_scale()

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


func _try_jump(input_owned: bool) -> void:
	if not _locomotion_enabled or input_owned:
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


func _on_tool_swing_started() -> void:
	if _model != null and _model.has_method("play_tool_swing"):
		_model.call("play_tool_swing", 0.45)


func _resolve_landing(falling_speed: float) -> void:
	var on_floor := is_on_floor()
	if on_floor and not _was_on_floor:
		var damage: float = vitals.apply_landing(maxf(falling_speed, 0.0), _armor_defense())
		landed.emit(falling_speed, damage)
		if vitals.is_dead():
			died.emit()
	_was_on_floor = on_floor
	_fall_speed = falling_speed


## R7.7. `player_equipment.gd`'s own total_defense(), same lookup pattern
## tool_hold.gd already uses for `equipped_tool` -- a headless caller (a test,
## a capture tool with no Game autoload) reads 0.0, unarmoured, same as
## every fall-damage call before this task.
func _armor_defense() -> float:
	var game := get_node_or_null(^"/root/Game")
	if game == null:
		return 0.0
	var equipment: Variant = game.get("player_equipment")
	return float(equipment.call("total_defense")) if equipment is RefCounted else 0.0


## Horizontal speed, read by the HUD and by trainer_model.gd's
## `_clip_for_state()` to pick idle/walk/sprint.
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


## --- being carried (R6.1) ---------------------------------------------------

## Ride `node`, seated at `offset` in that node's local frame. Pass null to be
## put down again; the caller is responsible for where the body lands, because
## only it knows what there is to stand on beside whatever was carrying it.
##
## Physics layers are dropped while carried. A 0.4m capsule sitting inside a
## creature's capsule is two solid CharacterBody3Ds aimed at each other, which
## is the exact overlap that once launched the player off the playground at
## 500 m/s (encounter_director._spawn_ally_body's own comment) — and the reason
## `follower_creature.gd` already zeroes its layer while following.
func set_carrier(node: Node3D, offset: Vector3 = Vector3.ZERO) -> void:
	if node != null and not _carried:
		_carry_saved_layer = collision_layer
		_carry_saved_mask = collision_mask
		collision_layer = 0
		collision_mask = 0
	elif node == null and _carried:
		collision_layer = _carry_saved_layer
		collision_mask = _carry_saved_mask
	_carrier = node
	_carried = node != null
	_carry_offset = offset
	# The trainer's ART is hidden while carried, not the node: the torch is a
	# child of this body (scripts/player/torch.gd) and a rider who loses their
	# light at dusk because they got on a deer is a bug. Hiding is tied to the
	# carrier here, in ONE place, rather than left to the caller — that is what
	# makes "the player is never left invisible" an invariant of clearing the
	# carrier rather than a step somebody can forget on one of the exit paths.
	#
	# There is no seated pose in the trainer rig (M11's clips are idle/walk/
	# sprint/throw), so a visible standing trainer would ride the Meadowhart
	# standing bolt upright on its back. Hidden is the honest placeholder until
	# a sit clip exists; the mount offset is already authored for where the
	# rider belongs, so that swap is art, not code.
	if _model != null:
		_model.visible = node == null
	if node == null:
		# Nothing about the ride carries over into standing up: no leftover
		# velocity, no buffered jump from a button pressed in the saddle.
		velocity = Vector3.ZERO
		_jump_buffered_for = INF
		_was_on_floor = true
		_airborne_for = 0.0
		_sprinting = false


func carrier() -> Node3D:
	return _carrier if _carried else null


## Is the trainer's own art on screen? False only while carried. Read by
## tests/smoke_riding.gd, which exists mostly to prove this comes back true.
func rider_visible() -> bool:
	return _model == null or _model.visible


func is_carried() -> bool:
	return _carried


## Sit where the carrier says, and keep the trainer's own clocks running.
##
## STAMINA DECISION (R6.1): riding costs the PLAYER nothing and the mount has no
## stamina meter of its own. The honest reasons, in order — the trainer is
## sitting down, so a drain would be modelling exertion nobody is doing; a
## second stamina bar on the creature is a whole HUD element and a whole tuning
## problem for a system whose value (spec §3) is "revisiting known areas is less
## of a chore", which a meter that ends the ride directly undermines; and the
## creature's stamina is already spoken for by combat energy, which is a
## different resource with a different meaning. So the meter simply REGENERATES
## while mounted: `tick` is still called, with sprinting false, which is exactly
## what standing still does. Satiety still drains — riding is not a pause button
## on the day (D29).
func _ride(delta: float) -> void:
	if not is_instance_valid(_carrier):
		# The carrier was freed out from under us. Put the body back under its
		# own power immediately rather than following a dangling reference — it
		# stays exactly where it was, falls under gravity from the next frame,
		# and `riding_controller.gd` moves it somewhere sensible when it notices.
		set_carrier(null)
		return
	velocity = Vector3.ZERO
	global_position = _carrier.to_global(_carry_offset)
	# Face the way the mount faces, so dismounting does not spin the trainer.
	if _model != null:
		_model.global_rotation.y = _carrier.global_rotation.y
	_sprinting = false
	vitals.tick(delta, false)
	vitals.tick_satiety(delta)
