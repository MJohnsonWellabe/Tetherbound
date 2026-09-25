extends "res://scripts/world/riding_controller.gd"

## Cloudreach's ground riding: the production controller, with one realm rule.
##
## `riding_controller.gd::_dismount_spot()` sets the trainer down at the
## world's `ground_height_at()`. Cloudreach answers that from its own surface
## index, and on this cliff realm the index and the real collision disagree:
## on the arrival road the index said 105.00 m beside the mount while the
## ArrivalGateRoad cliff-shoulder collider's top is 106.01 m, so a dismount put
## the trainer's capsule inside the shoulder, frozen and unable to move
## (`tests/smoke_cloudreach_saddle_remount.gd`). `fly_controller.gd` keeps the
## same rule for landings: never trust a highest-XZ height on stacked strata.
##
## So the spot the base class picks is re-measured against the collision the
## trainer actually stands on, near the mount's own level, and the trainer's
## real capsule must fit there. If that side is blocked, the other side is
## tried; if both are, the trainer is set down where the mount itself stands,
## which is ground by definition. SYSTEMS §8: "dismount at supported nearby
## clearance".

## How far above the mount's feet a supporting surface may be (a stepped
## shoulder beside the road) and how far below it (a shallow drop).
const PROBE_UP_M := 2.0
const PROBE_DOWN_M := 3.0
const SETTLE_LIFT_M := 0.05


func _dismount_spot(body: Node3D) -> Vector3:
	var chosen: Vector3 = super._dismount_spot(body)
	if body == null or not is_instance_valid(body) or _player == null or not is_instance_valid(_player):
		return chosen
	var base := body.global_position
	var mirrored := base + (base - chosen) * Vector3(1.0, 0.0, 1.0)
	for candidate: Vector3 in [chosen, mirrored]:
		var floor_y := _supported_floor(candidate, base.y, body)
		if is_nan(floor_y):
			continue
		var spot := Vector3(candidate.x, floor_y + SETTLE_LIFT_M, candidate.z)
		if _capsule_fits(spot, body):
			return spot
	return base + Vector3.UP * SETTLE_LIFT_M


## The top of real collision under `at`, within reach of the mount's level, or
## NAN. Walkable only: a wall face is not somewhere to stand.
func _supported_floor(at: Vector3, level: float, body: Node3D) -> float:
	var space := _player.get_world_3d().direct_space_state
	var exclude: Array[RID] = [_player.get_rid()]
	if body is CollisionObject3D:
		exclude.append((body as CollisionObject3D).get_rid())
	var query := PhysicsRayQueryParameters3D.create(
		Vector3(at.x, level + PROBE_UP_M, at.z), Vector3(at.x, level - PROBE_DOWN_M, at.z),
		_player.collision_mask, exclude)
	var hit := space.intersect_ray(query)
	if hit.is_empty() or (hit["normal"] as Vector3).y < cos(_player.floor_max_angle):
		return NAN
	return (hit["position"] as Vector3).y


func _capsule_fits(spot: Vector3, body: Node3D) -> bool:
	var collision := _player.get_node_or_null(^"Collision") as CollisionShape3D
	if collision == null or collision.shape == null:
		return true
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = collision.shape
	query.collision_mask = _player.collision_mask
	query.transform = Transform3D(Basis.IDENTITY, spot + collision.position + Vector3.UP * SETTLE_LIFT_M)
	var exclude: Array[RID] = [_player.get_rid()]
	if body is CollisionObject3D:
		exclude.append((body as CollisionObject3D).get_rid())
	query.exclude = exclude
	return _player.get_world_3d().direct_space_state.intersect_shape(query, 1).is_empty()
