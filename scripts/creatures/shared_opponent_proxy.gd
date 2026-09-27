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
var route_count: int = 0

var _target_feet: Vector3 = Vector3.ZERO
var _target_facing: Vector3 = Vector3.FORWARD
var _pose_received := false
var _interpolation_half_life_s := 0.05
## F04/F10#2: the host body's ground marks for the current tell, drawn from
## the optional cue `shape` (presentation only; the host still decides hits).
var _shape_lane_travels := false
var _shape_lane_lock_left := -1.0
## Set by a route cue and consumed by the telegraph that follows it in the same
## tell: only then is the drawn lane carried over instead of redrawn.
var _shape_route_pending := false


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


func present_telegraph(serial: int, seconds: float, total: int, shape: Dictionary = {}) -> bool:
	if serial <= last_cue_serial or not is_finite(seconds) or seconds <= 0.0:
		return false
	last_cue_serial = serial
	telegraph_count = maxi(telegraph_count, total)
	if _animator != null and _animator.has_method("begin_attack_telegraph"):
		_animator.call("begin_attack_telegraph", seconds)
	# A new tell never inherits marks from an earlier one (a catch pause, say,
	# ends a tell on the host without a strike cue); only its own route carries.
	if not _shape_route_pending:
		_clear_shape()
	_shape_route_pending = false
	_present_shape(shape)
	telegraph_started.emit(seconds)
	return true


## F10#2: the host body's route cue began; the tell proper follows as an
## ordinary telegraph cue. Draws the route only, no anticipation.
func present_route(serial: int, seconds: float, shape: Dictionary = {}) -> bool:
	if serial <= last_cue_serial or not is_finite(seconds) or seconds <= 0.0:
		return false
	last_cue_serial = serial
	route_count += 1
	_clear_shape()
	_present_shape(shape)
	_shape_route_pending = true
	return true


func present_strike(serial: int, total: int) -> bool:
	if serial <= last_cue_serial:
		return false
	last_cue_serial = serial
	strike_count = maxi(strike_count, total)
	_release_shape()
	# Visual only. Never emit strike_ready: the host sends damage separately.
	play_attack()
	return true


func shape_lane() -> Node3D:
	return _lunge_lane if _lunge_lane != null and is_instance_valid(_lunge_lane) else null


func shape_guard_cone() -> MeshInstance3D:
	return _guard_cone if _guard_cone != null and is_instance_valid(_guard_cone) else null


## Draws what `shape` names and clears what it does not, so a cue without a
## shape (an older host, or an ordinary strike) leaves nothing stale behind.
## A lane already drawn for this tell's route cue is kept, not redrawn.
func _present_shape(shape: Dictionary) -> void:
	var length := _shape_number(shape, "lane_length")
	var half := _shape_number(shape, "lane_half_width")
	if length > 0.0 and half > 0.0:
		if shape_lane() == null:
			_lunge_lane = LUNGE_LANE.begin(self, maxf(0.0, _shape_number(shape, "lane_start")),
				length, half, _lunge_cfg())
			_lunge_lane.call("aim", global_position, _target_facing)
		_shape_lane_travels = bool(shape.get("lane_travels", false))
		var lock_in := _shape_number(shape, "lane_lock_in_s", -1.0)
		_shape_lane_lock_left = lock_in
		if lock_in == 0.0 and not bool(_lunge_lane.call("is_locked")):
			_lunge_lane.call("lock")
	else:
		_free_shape_lane()
	var reach := _shape_number(shape, "guard_reach")
	if reach > 0.0:
		if shape_guard_cone() == null:
			_show_guard_cone(reach, _shape_number(shape, "guard_cone"))
	else:
		_hide_guard_cone()


## An orb took the body: whatever tell was showing ended with it on the host.
func play_absorb(world_point: Vector3, seconds: float) -> void:
	_clear_shape()
	super(world_point, seconds)


func _clear_shape() -> void:
	_free_shape_lane()
	_hide_guard_cone()
	_shape_route_pending = false


## The strike: a travelling lane stays where it was drawn and fades under the
## running body, as the host's does; a route line ends with its tell.
func _release_shape() -> void:
	var lane := shape_lane()
	if lane != null and _shape_lane_travels:
		if not bool(lane.call("is_locked")):
			lane.call("lock")
		lane.call("release")
		_lunge_lane = null
	else:
		_free_shape_lane()
	_shape_lane_lock_left = -1.0
	_shape_route_pending = false
	_hide_guard_cone()


func _free_shape_lane() -> void:
	var lane := shape_lane()
	if lane != null:
		lane.queue_free()
	_lunge_lane = null
	_shape_lane_lock_left = -1.0
	_shape_lane_travels = false


## Follows the host-sent facing until the host's lock point, then holds.
func _advance_shape_lane(delta: float) -> void:
	var lane := shape_lane()
	if lane == null or bool(lane.call("is_locked")):
		return
	lane.call("aim", global_position, _target_facing)
	if _shape_lane_lock_left > 0.0:
		_shape_lane_lock_left = maxf(0.0, _shape_lane_lock_left - delta)
		if _shape_lane_lock_left <= 0.0:
			lane.call("lock")


static func _shape_number(shape: Dictionary, key: String, fallback: float = 0.0) -> float:
	var value: Variant = shape.get(key, fallback)
	if not (value is int or value is float) or not is_finite(float(value)):
		return fallback
	return float(value)


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
	_advance_shape_lane(delta)


func _face_exact(direction: Vector3) -> void:
	rotation.y = atan2(direction.x, direction.z)


static func _flat_facing(value: Vector3) -> Vector3:
	var flat := Vector3(value.x, 0.0, value.z)
	return Vector3.FORWARD if flat.length_squared() <= 0.0001 else flat.normalized()
