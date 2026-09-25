extends "res://tests/helpers/meadows_earned_warrens_segment.gd"

## Earned Quarry/Warrens for the C1 chain: the unchanged read-only helper
## (`tests/helpers/meadows_earned_warrens_segment.gd`) with one added ordinary
## detour. On main 10b635d38 the helper's direct stick leg from the third
## quarry rootstone (406,1800) to the fourth (401,1809) is pushed west into the
## pocket south of the retained foundation (397,1805, yaw 30) and times out
## (tools/earned_saves/BLOCKERS.md B2, 2/2 on seed 4). This variant first walks
## the east side of the conduit pylon (404,1804) with the same controller walk
## the helper uses, then lets the helper take its own leg to the node. No
## position, flag or item is written; the detour is disclosed in a receipt.
const FOURTH_STOP := Vector2(401.0, 1809.0)
const EAST_DETOUR: Array[Vector2] = [Vector2(408.5, 1803.5), Vector2(406.5, 1809.5)]

var _detoured := false


func _walk_ground(at: Vector2, radius: float = 1.5) -> bool:
	if not _detoured and at.distance_to(FOURTH_STOP) < 0.1:
		_detoured = true
		_receipt("quarry_east_detour", {"from": _player.global_position, "waypoints": str(EAST_DETOUR),
			"reason": "helper's direct leg (406,1800)->(401,1809) stalls west of the foundation; ordinary walk around the pylon's east side"})
		for point: Vector2 in EAST_DETOUR:
			if not await super._walk_ground(point, 1.5):
				return false
	return await super._walk_ground(at, radius)
