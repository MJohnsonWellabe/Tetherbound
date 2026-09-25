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
## The fifth stone (393,1802) sits on the foundation's south side. The
## helper's clearance legs lead north of the long wall, where its final leg
## stalls (attempt 3), and the west end is closed by the cut face (attempt 4).
## Instead of the helper's two routing-only clearance waypoints, walk back
## round the pylon's east side to the open quarry floor south of the ruin,
## then let the helper take its own leg to the node.
const FIFTH_STOP := Vector2(393.0, 1802.0)
const HELPER_CLEARANCE: Array[Vector2] = [Vector2(394.1, 1809.0), Vector2(392.85, 1806.82)]
const SOUTH_DETOUR: Array[Vector2] = [Vector2(406.5, 1809.5), Vector2(408.5, 1803.5),
	Vector2(403.0, 1797.5), Vector2(396.0, 1797.5)]

var _detoured := false
var _west_detoured := false


func _walk_ground(at: Vector2, radius: float = 1.5) -> bool:
	if not _detoured and at.distance_to(FOURTH_STOP) < 0.1:
		_detoured = true
		_receipt("quarry_east_detour", {"from": _player.global_position, "waypoints": str(EAST_DETOUR),
			"reason": "helper's direct leg (406,1800)->(401,1809) stalls west of the foundation; ordinary walk around the pylon's east side"})
		for point: Vector2 in EAST_DETOUR:
			if not await super._walk_ground(point, 1.5):
				return false
	for clearance: Vector2 in HELPER_CLEARANCE:
		if at.distance_to(clearance) < 0.05:
			if not _west_detoured:
				_west_detoured = true
				_receipt("quarry_south_detour", {"from": _player.global_position, "waypoints": str(SOUTH_DETOUR),
					"replaces_routing_waypoints": str(HELPER_CLEARANCE),
					"reason": "helper's north clearance leaves the fifth stone behind the foundation wall; ordinary walk back round the pylon to the ruin's open south side"})
				for point: Vector2 in SOUTH_DETOUR:
					if not await super._walk_ground(point, 1.5):
						return false
			return true
	return await super._walk_ground(at, radius)
