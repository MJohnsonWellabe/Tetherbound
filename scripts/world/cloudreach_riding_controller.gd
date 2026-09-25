extends "res://scripts/world/riding_controller.gd"

## Cloudreach's ground riding: the production controller with this realm's
## rules for a vertical world. Owner playtest 2026-09-11: "I couldn't get back
## on the creatures with the saddle after going into cloudreach." — the realm
## never built a RidingController (`cloudreach_world_runtime.gd`).
##
## 1. Dismount on real collision. The base sets the trainer down at the
##    world's `ground_height_at()`; Cloudreach answers from its surface index,
##    which on the arrival road said 105.00 m beside the mount while the
##    cliff-shoulder collider's top is 106.01 m, burying the trainer
##    (`tests/smoke_cloudreach_saddle_remount.gd`). `fly_controller.gd` keeps
##    the same rule for landings. Each candidate beside, behind or ahead of the
##    mount is re-measured with a physics ray near the mount's own level, and
##    the trainer's real capsule has to fit there.
## 2. SYSTEMS §8 "dismount at supported nearby clearance, otherwise show
##    refusal": an asked-for dismount with no clear spot is refused with a
##    reason. A forced one (a fight, a modal, a freed mount) must still end the
##    ride, so it uses the last clear spot seen during this ride.
## 3. A mounted fall. A carried trainer has no collision layers, so the
##    realm's kill plane and grounded-fall anchor cannot see them. A mount that
##    falls as far as a walker would need to be recovered (100 m) is returned,
##    rider and all, to verified ground it stood on a moment before. Its floor
##    contact also keeps Fly's safe anchor current during the ride, so ending
##    the ride or reloading never reads a long descent as a fall.
## 4. SYSTEMS §8 limits: mounted jump apex no higher than the trainer's
##    1.35 m, and no climbing beyond the ordinary 45 degrees unless the species
##    authors its own climb (the legendary's 60).
## 5. The finale's creature-piloting exam owns the ally: no ride offer while
##    it does (`cloudreach_world_runtime.gd` dismounts before taking it).

const PROBE_UP_M := 2.0
const PROBE_DOWN_M := 3.0
const SETTLE_LIFT_M := 0.05
## Fallback only; the live cap is the trainer's own `movement.json` jump.
const TRAINER_JUMP_APEX_M := 1.35
const ORDINARY_CLIMB_DEG := 45.0
## SYSTEMS §8: "Same physical keys/barriers whether mounted or walking." A
## walking trainer is only recovered 100 m below their verified anchor
## (`cloudreach_physical_runtime.gd`); a mount gets the same, no stricter.
const MOUNTED_FALL_DROP_M := 100.0
const GROUND_SAMPLE_S := 0.25
const GROUND_HISTORY := 8
## A remembered clear spot further than this from the mount is not "nearby".
const REMEMBERED_SPOT_REACH_M := 25.0
## A fall is sustained: a hop, or a step down, is airborne for about a second
## at most and never lands this far below its take-off.
const MOUNTED_FALL_AIRBORNE_S := 0.6
const NO_ROOM_MESSAGE := "No room to dismount here."

var _ground_history: Array[Vector3] = []
var _ground_sample_left := 0.0
var _clear_spot := Vector3.INF
## The trainer's own collision mask. A carried trainer's is zero
## (`player_controller.set_carrier`), and the clearance probes run mid-ride.
var _standing_mask := 1
var _airborne_s := 0.0
var mounted_fall_recoveries := 0


func _ready() -> void:
	super._ready()
	_jump_height = minf(_jump_height, _trainer_jump_height())


static func _trainer_jump_height() -> float:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(CONFIG_PATH))
	if parsed is Dictionary:
		return float(((parsed as Dictionary).get("jump", {}) as Dictionary).get("height", TRAINER_JUMP_APEX_M))
	return TRAINER_JUMP_APEX_M


func _riding_allowed() -> bool:
	return super._riding_allowed() and not _creature_piloted()


func _creature_piloted() -> bool:
	var runtime := get_parent().get_node_or_null(^"CloudreachRuntime") if get_parent() != null else null
	return runtime != null and runtime.has_method("creature_piloted") and bool(runtime.call("creature_piloted"))


func mount() -> bool:
	var body := _player as CollisionObject3D
	if body != null and body.collision_mask != 0:
		_standing_mask = body.collision_mask
	var ok := super.mount()
	if ok:
		_ground_history.clear()
		_ground_sample_left = 0.0
		_clear_spot = Vector3.INF
		_airborne_s = 0.0
	return ok


func interaction_activate() -> void:
	if is_mounted():
		if _find_clear_spot(_mount) == Vector3.INF:
			var game := get_node_or_null(^"/root/Game")
			if game != null and game.has_method("push_world_message"):
				game.call("push_world_message", NO_ROOM_MESSAGE)
			return
		dismount()
		return
	mount()


func _physics_process(delta: float) -> void:
	if is_mounted():
		_watch_mounted_ground(delta)
	super._physics_process(delta)


func _watch_mounted_ground(delta: float) -> void:
	var body := _mount as CharacterBody3D
	if body == null:
		return
	if body.is_on_floor():
		if _airborne_s > 0.0:
			_ground_sample_left = 0.0
		_airborne_s = 0.0
		_ground_sample_left -= delta
		if _ground_sample_left <= 0.0:
			_ground_sample_left = GROUND_SAMPLE_S
			_ground_history.append(body.global_position)
			if _ground_history.size() > GROUND_HISTORY:
				_ground_history.pop_front()
			# Only ground the trainer could stand on becomes Fly's anchor: the
			# legendary climbs 60 degrees, and `recover_to_anchor` refuses
			# anything steeper than the trainer's own 45.
			var stood := _supported_floor(body.global_position, body.global_position.y, body)
			var fly: Node = _player.get("fly_controller") if _player != null else null
			if not is_nan(stood) and fly != null and fly.has_method("observe_carried_ground"):
				fly.call("observe_carried_ground", Vector3(body.global_position.x, stood, body.global_position.z))
			var spot := _find_clear_spot(body)
			if spot != Vector3.INF:
				_clear_spot = spot
		return
	_airborne_s += delta
	if _ground_history.is_empty() or _airborne_s < MOUNTED_FALL_AIRBORNE_S:
		return
	var last_ground: Vector3 = _ground_history[_ground_history.size() - 1]
	if body.global_position.y > last_ground.y - MOUNTED_FALL_DROP_M:
		return
	# Oldest still-supported sample: a moment back from the edge, re-probed so
	# a spot that no longer holds ground is never the answer.
	var back_from_edge := _supported_history(body)
	if back_from_edge == Vector3.INF:
		# Nothing verified to return to: end the ride so the trainer, solid
		# again, falls into the realm's ordinary walker recovery rather than
		# riding an unseen fall forever.
		dismount()
		return
	body.global_position = back_from_edge + Vector3.UP * SETTLE_LIFT_M
	body.velocity = Vector3.ZERO
	_ground_history.clear()
	_ground_history.append(back_from_edge)
	_airborne_s = 0.0
	mounted_fall_recoveries += 1
	var game := get_node_or_null(^"/root/Game")
	if game != null and game.has_method("push_world_message"):
		game.call("push_world_message", "Your mount scrambled back from the drop.")


func _supported_history(body: Node3D) -> Vector3:
	for sample: Vector3 in _ground_history:
		var floor_y := _supported_floor(sample, sample.y, body)
		if not is_nan(floor_y):
			return Vector3(sample.x, floor_y, sample.z)
	return Vector3.INF


func _apply_climb_limit(body: Node3D, species_id: String) -> void:
	super._apply_climb_limit(body, species_id)
	if float(SPECIES.rideable(species_id).get("climb_max_slope_deg", 0.0)) > 0.0 or not body is CharacterBody3D:
		return
	var character := body as CharacterBody3D
	if not character.has_meta("ride_floor_max_angle"):
		character.set_meta("ride_floor_max_angle", character.floor_max_angle)
	character.floor_max_angle = minf(character.floor_max_angle, deg_to_rad(ORDINARY_CLIMB_DEG))


func _dismount_spot(body: Node3D) -> Vector3:
	if body != null and is_instance_valid(body):
		var spot := _find_clear_spot(body)
		if spot != Vector3.INF:
			return spot
	# Forced ending with nowhere clear right here: the last clear spot this
	# ride passed, if it is still nearby; else the mount's own footing.
	var alive := body != null and is_instance_valid(body)
	var at := body.global_position if alive else _last_mount_position
	var probe_body: Node3D = body if alive else null
	if _clear_spot != Vector3.INF and _clear_spot.distance_to(at) <= REMEMBERED_SPOT_REACH_M \
			and _capsule_fits(_clear_spot, probe_body):
		return _clear_spot
	# Never mid-air: the last verified ground this ride stood on.
	var ground := _supported_history(probe_body)
	if ground != Vector3.INF and _capsule_fits(ground + Vector3.UP * SETTLE_LIFT_M, probe_body):
		return ground + Vector3.UP * SETTLE_LIFT_M
	return at + Vector3.UP * SETTLE_LIFT_M


## The first candidate beside (either side), behind or ahead of the mount with
## walkable collision near the mount's level and room for the trainer's
## capsule, or INF.
func _find_clear_spot(body: Node3D) -> Vector3:
	if body == null or not is_instance_valid(body) or _player == null or not is_instance_valid(_player):
		return Vector3.INF
	var base := body.global_position
	var distance := 1.6
	var block := SPECIES.rideable(str(body.get("species_id")))
	if not block.is_empty():
		distance = float(block.get("dismount_distance", distance))
	var side := body.global_transform.basis.x
	var ahead := -body.global_transform.basis.z
	side.y = 0.0
	ahead.y = 0.0
	side = side.normalized() if side.length() > 0.01 else Vector3.RIGHT
	ahead = ahead.normalized() if ahead.length() > 0.01 else Vector3.FORWARD
	for direction: Vector3 in [side, -side, -ahead, ahead]:
		var candidate := base + direction * distance
		var floor_y := _supported_floor(candidate, base.y, body)
		if is_nan(floor_y):
			continue
		var spot := Vector3(candidate.x, floor_y + SETTLE_LIFT_M, candidate.z)
		if _capsule_fits(spot, body) and _line_clear(base, spot, body):
			return spot
	return Vector3.INF


## Top of walkable collision under `at`, within reach of the mount's level.
func _supported_floor(at: Vector3, level: float, body: Node3D) -> float:
	var query := PhysicsRayQueryParameters3D.create(
		Vector3(at.x, level + PROBE_UP_M, at.z), Vector3(at.x, level - PROBE_DOWN_M, at.z),
		_standing_mask, _excluded(body))
	var hit := _player.get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty() or (hit["normal"] as Vector3).y < cos(_player.floor_max_angle):
		return NAN
	return (hit["position"] as Vector3).y


func _capsule_fits(spot: Vector3, body: Node3D) -> bool:
	var collision := _player.get_node_or_null(^"Collision") as CollisionShape3D
	if collision == null or collision.shape == null:
		return true
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = collision.shape
	query.collision_mask = _standing_mask
	query.transform = Transform3D(Basis.IDENTITY, spot + collision.position + Vector3.UP * SETTLE_LIFT_M)
	query.exclude = _excluded(body)
	return _player.get_world_3d().direct_space_state.intersect_shape(query, 1).is_empty()


## Nothing solid between the saddle height and the spot's standing height: a
## dismount never passes the trainer through a wall, barrier or thin rock.
func _line_clear(base: Vector3, spot: Vector3, body: Node3D) -> bool:
	var from := base + Vector3.UP * 1.0
	var to := spot + Vector3.UP * 1.0
	var query := PhysicsRayQueryParameters3D.create(from, to, _standing_mask, _excluded(body))
	return _player.get_world_3d().direct_space_state.intersect_ray(query).is_empty()


func _excluded(body: Node3D) -> Array[RID]:
	var exclude: Array[RID] = [_player.get_rid()]
	if body is CollisionObject3D and is_instance_valid(body):
		exclude.append((body as CollisionObject3D).get_rid())
	return exclude
