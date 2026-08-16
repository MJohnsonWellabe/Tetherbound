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

## How far the arm stops short of whatever it hit. SpringArm3D's own property;
## kept here as a named default so it is data-driven like the rest of the rig
## instead of a bare number sitting in the .tscn.
##
## The scene shipped this at 0.3, which is standoff-from-the-hit-surface, not
## standoff-from-the-player. A tree trunk directly behind the player (the
## `trees`/`grove`/`rocks` vegetation layers collide, `scripts/world/vegetation.gd`
## `_add_collision()`, radius up to 1.1m) can leave the arm barely longer than
## the trunk's own radius, and the render is a close-up of whatever the arm
## stopped against filling the frame — the same failure this file's own header
## already names happening to the combat camera against a bush, now hit by the
## exploration camera against the denser Meadows scatter. Raising the margin
## does not stop the collapse; it stops the collapse from reading as the
## camera being INSIDE the obstruction.
var _collision_margin: float = 0.6

## Radius of the ball the arm sweeps along itself, in metres.
##
## SpringArm3D only shape-casts if it has been given a `shape`. Nothing ever
## assigned one — not the .tscn, not this file — so the arm fell back to its
## default single, infinitely thin raycast down the centre line, and a
## third-person camera indoors behaved exactly the way that implies. It slipped
## between a chair back and a table edge and then drew the camera inside them,
## and when the one ray did hit something nearer than `margin` the arm collapsed
## to about zero length and put the camera inside the player's head. Both were
## reported by the same blind playtest as one symptom ("the camera collapses
## into the character indoors"), and neither is reachable by tuning distance or
## margin, because a ray that misses reports no hit at all.
##
## Small on purpose: the ball is a stand-in for the camera's near plane, not for
## the player. Too large and the arm shortens for doorframes it would have fitted
## through. TUNABLE.
var _probe_radius: float = 0.25

var _target: Node3D = null
var _mouse_delta := Vector2.ZERO

## Defaults from movement.json, kept so a combat profile can be handed back.
var _base_distance: float = 5.2
var _base_height: float = 1.75
var _base_pitch_min: float = -60.0
var _base_pitch_max: float = 32.0

## Profile-scoped look tuning. catching.json's aim profile carried
## `sensitivity_scale: 0.55` and pitch bounds from the day it was written, and
## nothing read them — aim mode ran at the full 190 deg/s exploration turn
## rate, which is most of what "aiming is fiddly on the stick" was. A profile
## may now scale sensitivity, bend the stick response (exponent > 1 gives a
## fine-aim centre without costing full-deflection speed), and narrow pitch.
var _sensitivity_scale: float = 1.0
var _response_exponent: float = 1.0

## An extra, per-frame scale pushed in by whoever owns the current aim (the
## throw slows the stick further when the reticle is near the target). Reset
## to 1.0 by every set_target.
var _assist_scale: float = 1.0

## While a fight is running the rig follows the player's creature instead of the
## trainer, at a shorter creature's height. Combat is piloted (D07), and a
## piloted creature wants exactly this camera — so it is re-pointed rather than
## replaced by a second one that would have to be kept in sync.
var _retarget_lag: float = 0.0

## The camera hanging off the end of the arm. A combat profile narrows its lens:
## the exploration 70 is right for looking at a landscape and wrong for looking
## at two creatures four metres away.
@onready var _camera: Camera3D = get_node_or_null(^"Camera3D") as Camera3D
var _base_fov: float = 70.0

## Over-the-shoulder offset, in metres, applied to the ARM's pivot rather than
## to the camera hanging off it.
##
## The obvious implementation — sliding the child Camera3D sideways — silently
## does nothing. SpringArm3D rewrites its children's transforms every frame to
## place them at the end of the arm, so the offset was wiped before it was ever
## drawn, and combat spent a whole survey with the camera dead behind the creature
## while the config confidently said 1.5.
var _shoulder: float = 0.0


func _ready() -> void:
	_load_config()
	top_level = true          # the arm follows the player by code, not by parenting
	spring_length = _distance
	margin = _collision_margin
	# Set here rather than in the .tscn for the same reason `margin` is: the rig
	# is configured from movement.json in one place, and the scene carrying half
	# the values is how `collision_margin` sat in the config being ignored.
	if shape == null:
		var probe := SphereShape3D.new()
		probe.radius = _probe_radius
		shape = probe
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
	_base_pitch_min = _pitch_min
	_base_pitch_max = _pitch_max
	pitch = float(cfg.get("pitch_start_deg", -12.0))
	_gamepad_sensitivity = float(cfg.get("gamepad_sensitivity", _gamepad_sensitivity))
	_mouse_sensitivity = float(cfg.get("mouse_sensitivity", _mouse_sensitivity))
	_deadzone = float(cfg.get("stick_deadzone", _deadzone))
	_invert_y = bool(cfg.get("invert_y", false))
	_follow_lag = float(cfg.get("follow_lag", _follow_lag))
	_recover_speed = float(cfg.get("collision_recover_speed", _recover_speed))
	_collision_margin = float(cfg.get("collision_margin", _collision_margin))
	_probe_radius = float(cfg.get("collision_probe_radius", _probe_radius))
	_base_distance = _distance
	_base_height = _height
	if _camera != null:
		_base_fov = _camera.fov


## Follow a new target, optionally with an override profile.
##
## An empty profile restores the exploration defaults, which is how combat hands
## the camera back. The first call has no previous target and snaps; later calls
## ease, because a fight opening with a hard cut loses the connection between
## "the animal I walked up to" and "the animal I am fighting".
func set_target(target: Node3D, profile: Dictionary = {}) -> void:
	var had_target := _target != null
	_target = target

	_distance = float(profile.get("distance", _base_distance))
	_height = float(profile.get("height", _base_height))
	_retarget_lag = float(profile.get("retarget_lag", 0.0))
	_shoulder = float(profile.get("shoulder_offset", 0.0))
	_sensitivity_scale = float(profile.get("sensitivity_scale", 1.0))
	_response_exponent = maxf(float(profile.get("response_exponent", 1.0)), 0.1)
	_pitch_min = float(profile.get("pitch_min_deg", _base_pitch_min))
	_pitch_max = float(profile.get("pitch_max_deg", _base_pitch_max))
	_assist_scale = 1.0
	if _camera != null:
		_camera.fov = float(profile.get("fov", _base_fov))
	if profile.has("pitch_start_deg"):
		pitch = clampf(deg_to_rad(float(profile["pitch_start_deg"])),
			deg_to_rad(_pitch_min), deg_to_rad(_pitch_max))

	# The arm has to ignore whatever it is following.
	#
	# SpringArm3D excludes its own parent automatically, and this rig is
	# `top_level` so it has no parent to exclude. Following the player's creature put
	# the arm's origin inside that creature's capsule, the arm collided with it
	# on the first cast and collapsed to nothing, and the whole fight was played
	# from a camera buried in the back of your own creature.
	clear_excluded_objects()
	if target is CollisionObject3D:
		add_excluded_object((target as CollisionObject3D).get_rid())

	if target != null and not had_target:
		global_position = target.global_position + Vector3.UP * _height
		spring_length = _distance


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		_mouse_delta += (event as InputEventMouseMotion).relative


func _process(delta: float) -> void:
	# The freed check matters now that the rig can follow a thrown orb through
	# the catch resolution: the orb is freed with the fight, and a rig holding
	# the stale reference would crash on the next frame's follow.
	if _target == null or not is_instance_valid(_target):
		_target = null
		return
	_apply_look(delta)
	_follow(delta)


func _apply_look(delta: float) -> void:
	# Gamepad, in degrees per second so sensitivity is frame-rate independent.
	var stick := Input.get_vector("look_left", "look_right", "look_up", "look_down")
	if stick.length() < _deadzone:
		stick = Vector2.ZERO
	elif _response_exponent != 1.0:
		# Bend the response so small deflections move slowly and full
		# deflection keeps its speed — a fine-aim centre for the throw camera.
		stick = stick.normalized() * pow(stick.length(), _response_exponent)
	var turn := _gamepad_sensitivity * _sensitivity_scale * _assist_scale
	var yaw_change := -stick.x * turn * delta
	var pitch_change := -stick.y * turn * delta

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
	if not is_zero_approx(_shoulder):
		# Sideways relative to where the camera is looking, so the offset stays
		# on the same shoulder as you turn.
		desired += Basis(Vector3.UP, yaw).x * _shoulder
	# Exponential smoothing written frame-rate independently. A raw lerp by
	# `lag * delta` changes behaviour with frame rate, which shows up as the
	# camera feeling different on the handheld than on the desktop.
	#
	# `retarget_lag` slows the follow while a fight is opening or closing, so the
	# swap between trainer and creature is a glide rather than a snap.
	var lag := _retarget_lag if _retarget_lag > 0.0 else _follow_lag
	var weight := 1.0 - exp(-lag * delta)
	global_position = global_position.lerp(desired, weight)

	# Once the rig has arrived, hand pacing back to the normal follow lag —
	# otherwise the whole fight is played through a camera that lags behind
	# every dodge.
	if _retarget_lag > 0.0 and global_position.distance_to(desired) < 0.3:
		_retarget_lag = 0.0

	# The spring arm collapses instantly on intrusion (SpringArm3D's own
	# behaviour) and is eased back out here, so leaving cover is smooth.
	spring_length = move_toward(spring_length, _distance, _recover_speed * delta)


## Forward direction on the horizontal plane, for translating stick input into
## world movement. Kept here so the controller never has to know how the camera
## is oriented.
func planar_basis() -> Basis:
	return Basis(Vector3.UP, yaw)


## Per-frame extra look scaling from whoever owns the current aim — the throw
## slows the stick further while the reticle is near its target. Reset by
## every set_target, so a profile change cannot inherit a stale slowdown.
func set_look_scale(scale_value: float) -> void:
	_assist_scale = clampf(scale_value, 0.1, 1.0)
