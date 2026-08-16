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

signal landed(impact_speed: float, damage: float)
signal died()

var vitals: RefCounted = VITALS.new()
## Carried from the first frame (scripts/player/torch.gd's own header
## explains why this is not an inventory item). Exposed the same way
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
	_track_airborne(delta)
	_apply_gravity(delta)
	_apply_movement(delta)
	_try_jump()

	var falling_speed := -velocity.y
	move_and_slide()
	_resolve_landing(falling_speed)

	vitals.tick(delta, _sprinting and velocity.length() > 0.5)
	vitals.tick_satiety(delta)


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


func _resolve_landing(falling_speed: float) -> void:
	var on_floor := is_on_floor()
	if on_floor and not _was_on_floor:
		var damage: float = vitals.apply_landing(maxf(falling_speed, 0.0))
		landed.emit(falling_speed, damage)
		if vitals.is_dead():
			died.emit()
	_was_on_floor = on_floor
	_fall_speed = falling_speed


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
