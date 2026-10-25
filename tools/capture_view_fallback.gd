extends RefCounted
## Bounded fallback for an offset capture view (approach/detail) whose point
## has no supported ground, e.g. a fixed 12 m approach backing off a ledge.
## Steps the offset in toward the stand on the same heading, then tries small
## heading turns, and returns the first point `grounded` accepts. An empty
## result means every candidate failed: the caller keeps failing closed.
## `grounded` is the production check (ground height and teleport walkability).

const STEP_M := 2.0
const MIN_OFFSET_M := 4.0
const TURNS_DEG := [15.0, -15.0, 30.0, -30.0]


static func candidates(offset_m: float) -> Array[float]:
	var result: Array[float] = [offset_m]
	var magnitude := absf(offset_m) - STEP_M
	while magnitude >= MIN_OFFSET_M - 0.001:
		result.append(signf(offset_m) * magnitude)
		magnitude -= STEP_M
	return result


static func resolve(origin: Vector2, forward: Vector2, offset_m: float, grounded: Callable) -> Dictionary:
	var offsets := candidates(offset_m)
	for turn: float in [0.0] + TURNS_DEG:
		var heading := forward.rotated(-deg_to_rad(turn))
		for offset: float in offsets:
			var point := origin + heading * offset
			if bool(grounded.call(point)):
				return {"position_xz": [point.x, point.y], "offset_m": offset, "turn_deg": turn,
					"forward": [heading.x, heading.y], "fallback": offset != offset_m or turn != 0.0}
	return {}
