extends SpringArm3D

## Third-person orbit camera.
##
## A SpringArm3D so terrain intrusion is handled by the engine rather than by
## hand-written raycasts, which is the kind of thing the previous prototype
## reimplemented badly. The arm shortens instantly when something gets between
## the camera and the player, and eases back out, because the reverse reads as
## the camera lunging at your back.
##
## Yaw lives here rather than on the player: the player turns to face travel,
## and the camera turns to face where the player is looking. Coupling them makes
## the character spin when you look around while standing still.

const CONFIG_PATH := "res://data/config/movement.json"

var yaw: float = 0.0
var pitch: float = 0.0

var _distance: float = 5.2
var _height: float = 1.75
var _pitch_min: float = -60.0
var _pitch_max: float = 32.0
var _gamepad_sensitivity: float = 190.0
var _mouse_sensitivity: float = 0.16
var _deadzone: float = 0.18
var _invert_y: bool = false
var _follow_lag: float = 14.0
var _recover_speed: float = 4.0

var _target: Node3D = null
var _mouse_delta := Vector2.ZERO


func _ready() -> void:
	_load_config()
	top_level = true          # the arm follows the player by code, not by parenting
	spring_length = _distance
	pitch = deg_to_rad(clampf(pitch, _pitch_min, _pitch_max))


func _load_config() -> void:
	var file := FileAccess.open(CONFIG_PATH, FileAccess.READ)
	if file == null:
		push_warning("movement.json missing; camera using built-in defaults")
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		return
	var cfg: Dictionary = (parsed as Dictionary).get("camera", {})
	_distance = float(cfg.get("distance", _distance))
	_height = float(cfg.get("height", _height))
	_pitch_min = float(cfg.get("pitch_min_deg", _pitch_min))
	_pitch_max = float(cfg.get("pitch_max_deg", _pitch_max))
	pitch = float(cfg.get("pitch_start_deg", -12.0))
	_gamepad_sensitivity = float(cfg.get("gamepad_sensitivity", _gamepad_sensitivity))
	_mouse_sensitivity = float(cfg.get("mouse_sensitivity", _mouse_sensitivity))
	_deadzone = float(cfg.get("stick_deadzone", _deadzone))
	_invert_y = bool(cfg.get("invert_y", false))
	_follow_lag = float(cfg.get("follow_lag", _follow_lag))
	_recover_speed = float(cfg.get("collision_recover_speed", _recover_speed))


func set_target(target: Node3D) -> void:
	_target = target
	if target != null:
		global_position = target.global_position + Vector3.UP * _height


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		_mouse_delta += (event as InputEventMouseMotion).relative


func _process(delta: float) -> void:
	if _target == null:
		return
	_apply_look(delta)
	_follow(delta)


func _apply_look(delta: float) -> void:
	# Gamepad, in degrees per second so sensitivity is frame-rate independent.
	var stick := Input.get_vector("look_left", "look_right", "look_up", "look_down")
	if stick.length() < _deadzone:
		stick = Vector2.ZERO
	var yaw_change := -stick.x * _gamepad_sensitivity * delta
	var pitch_change := -stick.y * _gamepad_sensitivity * delta

	# Mouse, in degrees per pixel. Not scaled by delta: the motion event already
	# describes distance moved, and multiplying it by frame time makes fast
	# frames turn less than slow ones for the same physical movement.
	yaw_change += -_mouse_delta.x * _mouse_sensitivity
	pitch_change += -_mouse_delta.y * _mouse_sensitivity
	_mouse_delta = Vector2.ZERO

	if _invert_y:
		pitch_change = -pitch_change

	yaw = wrapf(yaw + deg_to_rad(yaw_change), -PI, PI)
	pitch = clampf(pitch + deg_to_rad(pitch_change), deg_to_rad(_pitch_min), deg_to_rad(_pitch_max))
	rotation = Vector3(pitch, yaw, 0.0)


func _follow(delta: float) -> void:
	var desired := _target.global_position + Vector3.UP * _height
	# Exponential smoothing written frame-rate independently. A raw lerp by
	# `lag * delta` changes behaviour with frame rate, which shows up as the
	# camera feeling different on the handheld than on the desktop.
	var weight := 1.0 - exp(-_follow_lag * delta)
	global_position = global_position.lerp(desired, weight)

	# The spring arm collapses instantly on intrusion (SpringArm3D's own
	# behaviour) and is eased back out here, so leaving cover is smooth.
	if spring_length < _distance:
		spring_length = move_toward(spring_length, _distance, _recover_speed * delta)


## Forward direction on the horizontal plane, for translating stick input into
## world movement. Kept here so the controller never has to know how the camera
## is oriented.
func planar_basis() -> Basis:
	return Basis(Vector3.UP, yaw)
