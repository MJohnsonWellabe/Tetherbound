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
##    reason, and the rider stays seated. Every other ending (a modal, the
##    finale pilot, combat admission, a freed mount, a fall) walks one
##    verified chain, in this order; see `_verified_spot`. Every rule except
##    "vacated" checks what the ring does -- walkable floor under the spot
##    ("airborne" excepted), the trainer's capsule fits there against world
##    collision AND against the mount's own capsule measured geometrically
##    (whatever its layer, enabled or not), and a clear line from the saddle
##    -- and stays within REMEMBERED_SPOT_REACH_M of the mount:
##      clear        the ring beside/behind/ahead of the mount;
##      airborne     only during a real drop (airborne for
##                   MOUNTED_FALL_AIRBORNE_S, or no floor within the probe
##                   under the mount): the ring at the mount's own level with
##                   no floor required, so the trainer comes off beside it into
##                   the same air and falls as a walker would. During a hop or
##                   an edge flicker it is tried only after the ground rules;
##      remembered   the last clear spot this ride recorded;
##      history      the NEWEST ground sample the mount stood on;
##      mounted_from where the trainer stood when the ride began;
##      vacated      the mount was freed: where it stood, its volume now empty;
##      deferred     nothing verifiable: `dismount()` returns false and the
##                   rider stays seated, told once "No room to dismount here.".
##                   The caller decides what that means: the base's per-frame
##                   modal "not allowed, dismount" retries every frame; combat
##                   admission is refused (`dismount_for_admission`, called by
##                   `cloudreach_encounter_director.gd` BEFORE the fight
##                   begins, so no fight ever starts with a rider on); the
##                   finale pilot waits (`cloudreach_world_runtime.gd` takes
##                   the ally only once the rider is off).
##    Never inside the mount, never inside geometry, never on the mount.
##    When a fight or the pilot already owns the body, the ride's end leaves
##    the camera where its owner put it.
## 3. A mounted fall. A carried trainer has no collision layers, so the
##    realm's kill plane and grounded-fall anchor cannot see them. A mount that
##    falls as far as a walker would need to be recovered (100 m) is returned,
##    rider and all, to the newest verified ground it stood on (line-clear from
##    where it took off), and so is one crossing the cloud-sea kill plane,
##    as a walker would be. Its floor samples also keep Fly's safe anchor
##    current during the ride (the clear spot beside the mount), so ending the
##    ride or reloading never reads a long descent as a fall.
## 4. SYSTEMS §8 limits: mounted jump apex no higher than the trainer's
##    1.35 m, and no climbing beyond the ordinary 45 degrees unless the species
##    authors its own climb (the legendary's 60).
## 5. The finale's creature-piloting exam owns the ally: no ride offer while
##    it does (`cloudreach_world_runtime.gd` dismounts before taking it).
##
## Overrides of `riding_controller.gd`: `_ready` (jump cap), `_riding_allowed`
## (finale pilot), `_combat_took_the_mount` (the pilot keeps the body too),
## `mount` (per-ride state), `interaction_activate` (refusal), `dismount`
## (verify first, defer when nothing verifies), `_physics_process`
## (mounted-ground watch, Fly's carried anchor clock), `_apply_climb_limit`
## (45 degrees) and `_dismount_spot` (the spot `dismount` verified).

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
## A remembered clear spot further than this from the mount is not "nearby":
## a forced dismount must not carry the trainer back along the route.
const REMEMBERED_SPOT_REACH_M := 8.0
## How much further out the second ring of dismount candidates sits.
const OUTER_RING_EXTRA_M := 1.2
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
## Where the trainer stood, on their own feet, when this ride began.
var _mounted_from := Vector3.INF
## Where the mount stood when this ride began: the fall reference before any
## ground sample exists (a mount set on a slope steeper than 45 degrees can
## slide off before it is ever "on floor").
var _ride_start := Vector3.INF
var mounted_fall_recoveries := 0
## Which rule placed the last dismount, or "deferred" when the last forced
## attempt found nothing verifiable (see the header's chain), for tests and
## diagnosis.
var last_dismount_rule := ""
## Deferral EPISODES this session: a run of refused attempts (one per frame
## while a modal holds) counts once, and tells the player once.
var deferred_dismounts := 0
var _deferring := false
## The spot `dismount()` verified, consumed by `_dismount_spot()`.
var _planned_spot := Vector3.INF


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
	var standing_at := _player.global_position if _player != null else Vector3.INF
	var ok := super.mount()
	if ok:
		_mounted_from = standing_at
		_ride_start = _mount.global_position if _mount != null else Vector3.INF
		_ground_history.clear()
		_ground_sample_left = 0.0
		_clear_spot = Vector3.INF
		_airborne_s = 0.0
		_deferring = false
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
	# A carried trainer never reaches `fly_controller.physics_step`
	# (`player_controller` rides instead), so the clock that times out an
	# unanswered landing-anchor proposal is ticked here, every frame of the
	# ride, airborne or not.
	var fly: Node = _player.get("fly_controller") if _player != null else null
	if fly != null and fly.has_method("tick_carried_anchor"):
		fly.call("tick_carried_anchor", delta)
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
			var spot := _find_clear_spot(body)
			if spot != Vector3.INF:
				_clear_spot = spot
				# Room again: a later deferral is a new episode, told anew.
				_deferring = false
				# Fly's anchor is the clear spot BESIDE the mount, not the
				# mount's own feet: it is ground the trainer could stand on
				# (walkable to the trainer's 45 degrees, capsule fits), and a
				# guest's proposal there cannot be confused with the mount by
				# the host's probe (`remote_trainer.gd::_anchor_params` rays
				# down from 2 m above the claim and would meet the mount's
				# capsule, 3.45 m tall, if it were solid on the host), while
				# staying within the host's 6 m drift of the carried trainer.
				if fly != null and fly.has_method("observe_carried_ground"):
					fly.call("observe_carried_ground", spot)
		return
	_airborne_s += delta
	if _airborne_s < MOUNTED_FALL_AIRBORNE_S:
		return
	# Never "no reference": with no ground sample yet, the fall is measured
	# from where this ride began, and that spot is the first recovery candidate.
	if _ground_history.is_empty() and _ride_start != Vector3.INF:
		_ground_history.append(_ride_start)
	if _ground_history.is_empty():
		dismount()
		return
	var last_ground: Vector3 = _ground_history[_ground_history.size() - 1]
	# Walker parity: a walking trainer is recovered 100 m below its anchor OR
	# on entering the cloud-sea kill volume (`fall_recovery.gd`), whichever
	# comes first. The volume only reports the trainer's own body, which has
	# no collision layer while carried, so its top face is checked here.
	if body.global_position.y > last_ground.y - MOUNTED_FALL_DROP_M \
			and body.global_position.y > _kill_trigger_y():
		return
	# The newest still-supported sample, re-probed so a spot that no longer
	# holds ground is never the answer, with a clear line from the take-off
	# sample so a gate or seal that closed behind the mount is never crossed.
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


## The mounted-fall recovery's return point: the NEWEST ground sample that
## still holds walkable floor and has a clear line from the take-off sample
## (the last ground the mount stood on). Newest, because every older sample
## is further back along the route, and anything that closed across that
## route (a gate, an arena seal) would otherwise be crossed. Never a dismount
## spot (see `_verified_spot`).
func _supported_history(body: Node3D) -> Vector3:
	if _ground_history.is_empty():
		return Vector3.INF
	var takeoff: Vector3 = _ground_history[_ground_history.size() - 1]
	for i in range(_ground_history.size() - 1, -1, -1):
		var sample: Vector3 = _ground_history[i]
		var floor_y := _supported_floor(sample, sample.y, body)
		if is_nan(floor_y):
			continue
		var at := Vector3(sample.x, floor_y, sample.z)
		if i < _ground_history.size() - 1 and not _line_clear(takeoff, at, body):
			continue
		return at
	return Vector3.INF


## The height at which a WALKER is caught: the top face of the realm's
## cloud-sea kill volume (`fall_recovery.gd` builds `FallRecoveryKillVolume`, a
## box KILL_PLANE_THICKNESS tall centred on the plane, and recovers the trainer
## on entering it). Read from that public scene node, or -INF where there is
## none.
func _kill_trigger_y() -> float:
	var world := get_parent()
	var volume := world.get_node_or_null(^"FallRecovery/FallRecoveryKillVolume") as Node3D if world != null else null
	if volume == null:
		return -INF
	for child: Node in volume.get_children():
		var shape := child as CollisionShape3D
		if shape != null and shape.shape is BoxShape3D:
			return shape.global_position.y + (shape.shape as BoxShape3D).size.y * 0.5
	return volume.global_position.y


func _apply_climb_limit(body: Node3D, species_id: String) -> void:
	super._apply_climb_limit(body, species_id)
	if float(SPECIES.rideable(species_id).get("climb_max_slope_deg", 0.0)) > 0.0 or not body is CharacterBody3D:
		return
	var character := body as CharacterBody3D
	if not character.has_meta("ride_floor_max_angle"):
		character.set_meta("ride_floor_max_angle", character.floor_max_angle)
	character.floor_max_angle = minf(character.floor_max_angle, deg_to_rad(ORDINARY_CLIMB_DEG))


## The pilot, like a fight, keeps the body: the base must not hand it back to
## following (which also takes its collision layer away) under the exam, nor
## take the camera off it (`dismount`).
func _combat_took_the_mount() -> bool:
	return super._combat_took_the_mount() or _creature_piloted()


## Verify first, then get off. With nothing verifiable the ending is
## deferred rather than guessed: the rider stays seated, and the caller retries
## (see the header). An asked-for dismount never gets here unverified:
## `interaction_activate` refuses first.
func dismount() -> bool:
	if not _riding_now:
		return false
	var body := _mount
	if _player == null or not is_instance_valid(_player):
		return super.dismount()
	if is_instance_valid(body):
		var chosen := _verified_spot(body)
		if chosen.is_empty():
			last_dismount_rule = "deferred"
			if not _deferring:
				_deferring = true
				deferred_dismounts += 1
				var game := get_node_or_null(^"/root/Game")
				if game != null and game.has_method("push_world_message"):
					game.call("push_world_message", NO_ROOM_MESSAGE)
			return false
		_planned_spot = chosen.spot
		last_dismount_rule = str(chosen.rule)
	else:
		_planned_spot = _vacated_spot()
		last_dismount_rule = "vacated"
	_deferring = false
	# A fight or the finale pilot already owns this body and the camera; the
	# base's hand-back of the camera to the trainer would take it off the
	# creature being piloted for the rest of that fight or exam.
	var owned := _combat_took_the_mount()
	var rig := _camera_rig
	if owned:
		_camera_rig = null
	var ok := super.dismount()
	_camera_rig = rig
	return ok


## SYSTEMS §8 "Combat admission dismounts safely first. No mounted
## catch/combat." Called by the encounter director before a fight (wild or
## trainer) begins. True when no rider is on, or the rider is now standing on
## a verified spot; false (the rider told why) refuses the admission.
func dismount_for_admission() -> bool:
	if not is_mounted():
		return true
	return dismount()


## Only reached through `dismount()` above, which always plans the spot first
## (a live mount: verified or deferred before the base runs; a freed one:
## "vacated"; no trainer: the base never asks).
func _dismount_spot(_body: Node3D) -> Vector3:
	var spot := _planned_spot
	_planned_spot = Vector3.INF
	if spot == Vector3.INF:
		push_error("cloudreach riding: a dismount reached the base without a verified spot")
		return _player.global_position
	return spot


## The header's chain, for a live mount: {spot, rule}, or {} for "deferred".
func _verified_spot(body: Node3D) -> Dictionary:
	var spot := _find_clear_spot(body)
	if spot != Vector3.INF:
		return {"spot": spot, "rule": "clear"}
	var character := body as CharacterBody3D
	var in_air := character != null and not character.is_on_floor()
	var real_drop := in_air and (_airborne_s >= MOUNTED_FALL_AIRBORNE_S
		or is_nan(_supported_floor(body.global_position, body.global_position.y, body)))
	if real_drop:
		spot = _find_clear_spot(body, true)
		if spot != Vector3.INF:
			return {"spot": spot, "rule": "airborne"}
	if _clear_spot != Vector3.INF:
		spot = _verified_ground(_clear_spot, body)
		if spot != Vector3.INF:
			return {"spot": spot, "rule": "remembered"}
	# Newest first: the ground the mount stood on a quarter-second ago, not
	# the start of the history two seconds back along the route.
	for i in range(_ground_history.size() - 1, -1, -1):
		spot = _verified_ground(_ground_history[i], body)
		if spot != Vector3.INF:
			return {"spot": spot, "rule": "history"}
	if _mounted_from != Vector3.INF:
		spot = _verified_ground(_mounted_from, body)
		if spot != Vector3.INF:
			return {"spot": spot, "rule": "mounted_from"}
	# A hop or an edge flicker with no ground rule answering: the air beside
	# the mount, a step above whatever it is about to land on.
	if in_air and not real_drop:
		spot = _find_clear_spot(body, true)
		if spot != Vector3.INF:
			return {"spot": spot, "rule": "airborne"}
	return {}


## `candidate` as a dismount spot: within reach of the mount, walkable floor
## within a step of it, the trainer's capsule clear of world collision and of
## the mount's own capsule, and a clear line from the saddle. INF if any fails.
func _verified_ground(candidate: Vector3, body: Node3D) -> Vector3:
	var base := body.global_position
	if candidate.distance_to(base) > REMEMBERED_SPOT_REACH_M:
		return Vector3.INF
	var floor_y := _supported_floor(candidate, candidate.y, body)
	if is_nan(floor_y):
		return Vector3.INF
	var spot := Vector3(candidate.x, floor_y + SETTLE_LIFT_M, candidate.z)
	if spot.distance_to(base) > REMEMBERED_SPOT_REACH_M:
		return Vector3.INF
	if not _capsule_fits(spot, body) or not _line_clear(base, spot, body):
		return Vector3.INF
	return spot


## The freed-mount case: where it last stood. Its body occupied that volume,
## which is wider and taller than the trainer, so nothing solid is there.
func _vacated_spot() -> Vector3:
	var at := _last_mount_position
	var floor_y := _supported_floor(at, at.y, null)
	return Vector3(at.x, (floor_y if not is_nan(floor_y) else at.y) + SETTLE_LIFT_M, at.z)


## The first candidate beside (either side), behind, ahead of or diagonal to
## the mount -- at the species' dismount distance, then a ring further out --
## with walkable collision near the mount's level, room for the trainer's
## capsule clear of the mount, and a clear line from the saddle, or INF.
## `in_air` (a falling mount only) keeps the spot at the mount's own level and
## asks for no floor.
func _find_clear_spot(body: Node3D, in_air: bool = false) -> Vector3:
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
	var directions: Array[Vector3] = [side, -side, -ahead, ahead,
		(side - ahead).normalized(), (-side - ahead).normalized(),
		(side + ahead).normalized(), (-side + ahead).normalized()]
	for reach: float in [distance, distance + OUTER_RING_EXTRA_M]:
		for direction: Vector3 in directions:
			var candidate := base + direction * reach
			var spot := candidate
			if not in_air:
				var floor_y := _supported_floor(candidate, base.y, body)
				if is_nan(floor_y):
					continue
				spot = Vector3(candidate.x, floor_y + SETTLE_LIFT_M, candidate.z)
			if _capsule_fits(spot, body) and _line_clear(base, spot, body):
				return spot
	return Vector3.INF


## Top of walkable collision under `at`, within reach of the mount's level.
## The ray starts only 2 m up; beside a tall wall it can begin inside rock and
## report a floor under it. Every dismount caller (`_find_clear_spot`,
## `_verified_ground`) therefore also requires the trainer's capsule to fit
## there -- a capsule inside rock never fits. The two ground-watch callers
## (Fly's carried anchor, the fall recovery's back-from-edge sample) probe the
## mount's own contact point, which its capsule already stood on.
func _supported_floor(at: Vector3, level: float, body: Node3D) -> float:
	var query := PhysicsRayQueryParameters3D.create(
		Vector3(at.x, level + PROBE_UP_M, at.z), Vector3(at.x, level - PROBE_DOWN_M, at.z),
		_standing_mask, _excluded(body))
	var hit := _player.get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty() or (hit["normal"] as Vector3).y < cos(_player.floor_max_angle):
		return NAN
	return (hit["position"] as Vector3).y


## The trainer's capsule at `spot` touches no world collision (the mount's
## physics body excluded) and does not overlap the mount's own capsule,
## measured geometrically so the answer does not depend on the mount's layer.
func _capsule_fits(spot: Vector3, body: Node3D) -> bool:
	var collision := _player.get_node_or_null(^"Collision") as CollisionShape3D
	if collision == null or collision.shape == null:
		return true
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = collision.shape
	query.collision_mask = _standing_mask
	query.transform = Transform3D(Basis.IDENTITY, spot + collision.position + Vector3.UP * SETTLE_LIFT_M)
	query.exclude = _excluded(body)
	if not _player.get_world_3d().direct_space_state.intersect_shape(query, 1).is_empty():
		return false
	return not capsules_overlap(collision, Transform3D(Basis.IDENTITY, spot + collision.position), body)


## Whether `shape_node`'s capsule placed at `at` overlaps any capsule collider
## of `body`, from the shapes and transforms alone (no physics query, so no
## collision layer can hide it). Public and static: the saddle smoke measures
## its "never inside the mount" checks with the same geometry.
static func capsules_overlap(shape_node: CollisionShape3D, at: Transform3D, body: Node) -> bool:
	if shape_node == null or not shape_node.shape is CapsuleShape3D or body == null or not is_instance_valid(body):
		return false
	var mine := shape_node.shape as CapsuleShape3D
	var a := _capsule_segment(mine, at)
	for child: Node in body.get_children():
		var other := child as CollisionShape3D
		# Disabled too: a hidden mount turns its collider off, and its body
		# is still where the trainer would be set down.
		if other == null or not other.shape is CapsuleShape3D:
			continue
		var theirs := other.shape as CapsuleShape3D
		var b := _capsule_segment(theirs, other.global_transform)
		var closest := Geometry3D.get_closest_points_between_segments(a[0], a[1], b[0], b[1])
		if closest[0].distance_to(closest[1]) < mine.radius + theirs.radius - 0.001:
			return true
	return false


static func _capsule_segment(shape: CapsuleShape3D, at: Transform3D) -> Array[Vector3]:
	var half := maxf(shape.height * 0.5 - shape.radius, 0.0)
	var up := at.basis.y.normalized()
	return [at.origin - up * half, at.origin + up * half]


## Nothing solid between the saddle height and the spot's standing height: a
## dismount never passes the trainer through a wall, barrier or thin rock.
func _line_clear(base: Vector3, spot: Vector3, body: Node3D) -> bool:
	var from := base + Vector3.UP * 1.0
	var to := spot + Vector3.UP * 1.0
	var query := PhysicsRayQueryParameters3D.create(from, to, _standing_mask, _excluded(body))
	return _player.get_world_3d().direct_space_state.intersect_ray(query).is_empty()


func _excluded(body: Node3D) -> Array[RID]:
	var exclude: Array[RID] = [_player.get_rid()]
	if is_instance_valid(body) and body is CollisionObject3D:
		exclude.append((body as CollisionObject3D).get_rid())
	return exclude
