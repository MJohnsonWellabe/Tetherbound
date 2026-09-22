extends "res://scripts/creatures/wild_creature.gd"

## A guest's read-only body for the host's wild opponent. It has the ordinary
## creature rig and catch presentation, but never runs WildCreature AI,
## collision, impulses, or strike authority.

const LOG_TWO := 0.6931471805599453

var body_generation: int = 0
var last_pose_seq: int = 0
var last_cue_serial: int = 0
var telegraph_count: int = 0
var strike_count: int = 0

var _target_feet: Vector3 = Vector3.ZERO
var _target_facing: Vector3 = Vector3.FORWARD
var _pose_received := false
var _interpolation_half_life_s := 0.05


func configure_presentation(card: RefCounted, generation: int, feet: Vector3, facing_now: Vector3,
		interpolation_half_life_s: float) -> bool:
	if card == null or generation <= 0 or not feet.is_finite() or not facing_now.is_finite() \
			or not is_finite(interpolation_half_life_s):
		return false
	instance = card
	body_generation = generation
	_interpolation_half_life_s = maxf(0.001, interpolation_half_life_s)
	setup(str(card.get("species_id")), bool(card.get("shiny")))
	collision_layer = 0
	collision_mask = 0
	global_position = feet
	_target_feet = feet
	_target_facing = _flat_facing(facing_now)
	_face_exact(_target_facing)
	_pose_received = true
	return true


## WildCreature engagement is intentionally suppressed even when a failed catch
## asks the body to re-engage. The host remains the only AI and strike clock.
func set_engaged(_value: bool, _opponent: Node3D = null) -> void:
	engaged = false


func add_impulse(_direction: Vector3, _strength: float) -> void:
	pass


func apply_pose(generation: int, sequence: int, feet: Vector3, facing_now: Vector3) -> bool:
	if generation != body_generation or sequence <= last_pose_seq \
			or not feet.is_finite() or not facing_now.is_finite():
		return false
	last_pose_seq = sequence
	_target_feet = feet
	_target_facing = _flat_facing(facing_now)
	if not _pose_received:
		global_position = feet
		_face_exact(_target_facing)
		_pose_received = true
	return true


func present_telegraph(serial: int, seconds: float, total: int) -> bool:
	if serial <= last_cue_serial or not is_finite(seconds) or seconds <= 0.0:
		return false
	last_cue_serial = serial
	telegraph_count = maxi(telegraph_count, total)
	if _animator != null and _animator.has_method("begin_attack_telegraph"):
		_animator.call("begin_attack_telegraph", seconds)
	telegraph_started.emit(seconds)
	return true


func present_strike(serial: int, total: int) -> bool:
	if serial <= last_cue_serial:
		return false
	last_cue_serial = serial
	strike_count = maxi(strike_count, total)
	# Visual only. Never emit strike_ready: the host sends damage separately.
	play_attack()
	return true


func _physics_process(delta: float) -> void:
	if not _pose_received:
		return
	var before := global_position
	var weight := 1.0 - exp(-LOG_TWO * delta / _interpolation_half_life_s)
	global_position = global_position.lerp(_target_feet, clampf(weight, 0.0, 1.0))
	var wanted_yaw := atan2(_target_facing.x, _target_facing.z)
	rotation.y = lerp_angle(rotation.y, wanted_yaw, clampf(weight, 0.0, 1.0))
	if _animator != null:
		var speed := global_position.distance_to(before) / maxf(delta, 0.0001)
		_animator.call("tick", delta, speed, _speed)


func _face_exact(direction: Vector3) -> void:
	rotation.y = atan2(direction.x, direction.z)


static func _flat_facing(value: Vector3) -> Vector3:
	var flat := Vector3(value.x, 0.0, value.z)
	return Vector3.FORWARD if flat.length_squared() <= 0.0001 else flat.normalized()
