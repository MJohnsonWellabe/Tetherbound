extends RefCounted

## Pure grid/rotation/snap math for BG1's placement system — no nodes, no
## scene tree, so `tests/test_build_grid.gd` can exercise every rule
## headlessly, the same split `autoload/inventory.gd` and
## `scripts/ui/key_bindings.gd` already draw. `build_placer.gd` is the only
## caller; it owns the ghost node and the input, this owns the arithmetic.
##
## TUNABLE. All three constants below are temporary numbers, not settled
## design — CLAUDE.md's "Tunable Values" section is explicit that a chosen
## number here must not calcify into a permanent mechanic without being
## re-examined once real castle-parts modules (BG2) land.

## Metres per grid cell, on the X/Z plane. Matches the module grid
## `data/config/building_prefabs.json`'s own header comment already
## establishes for the Medieval Village kit ("authored at real scale on a 2m
## wall grid, walls 2.0w x 3.12h, measured") — reusing it here rather than
## inventing a second grid size means a player-placed wall and an
## author-placed `building_prefabs.json` wall land on the same lines.
const GRID_SIZE := 2.0

## One rotation step. Four steps is a full turn — the "at minimum 90-degree
## steps, four orientations" the task asks for, and the smallest useful
## rotation for square/rectangular modules (finer steps would leave gaps
## between axis-aligned neighbours instead of flush edges).
const ROTATION_STEP_DEG := 90.0

## How close a placement has to be to an already-placed piece of the SAME
## catalogue id before it snaps flush against it, rather than merely to the
## nearest grid line. Just over one cell's diagonal so a piece aimed roughly
## at a neighbour's near edge — not pixel-perfect — still catches it.
const SNAP_RADIUS := 2.6

## D34/spec 13.4's `build_snap_cycle`: the rotation step size a rotate press
## turns the ghost by, cycled coarse-to-fine rather than fine-to-coarse so
## the default (first press away from 90) still gets you to a flush 45 for
## diagonal work before the player has to hunt for the fussier 15.
const SNAP_STEP_DEGS: Array[float] = [90.0, 45.0, 15.0]


## Rounds `raw`'s X/Z onto the world grid, in absolute world space (grid lines
## run through the origin) so any two grid-snapped pieces are automatically
## flush with each other even with no neighbour in range. `ground_y` is used
## as-is; this function has no opinion about height.
static func snap_to_grid(raw: Vector3, ground_y: float) -> Vector3:
	return Vector3(snappedf(raw.x, GRID_SIZE), ground_y, snappedf(raw.z, GRID_SIZE))


## `steps` (any integer, wrapped mod 4) as a yaw in degrees.
static func yaw_for_steps(steps: int) -> float:
	return float(posmod(steps, 4)) * ROTATION_STEP_DEG


## The next rotation step, wrapping 3 -> 0. `build_placer.gd` calls this once
## per `build_rotate` press.
static func next_rotation_steps(steps: int) -> int:
	return posmod(steps + 1, 4)


## Where a ghost at `raw` actually lands, given the ground height under it and
## the world positions of already-placed pieces of the SAME id.
##
## Returns {"position": Vector3, "snapped_to_neighbour": bool}. When a
## neighbour is within `SNAP_RADIUS`, the result is that neighbour's own
## position plus a whole number of grid cells toward `raw` — pulling the new
## piece flush against it and onto its exact height, so a continuous wall run
## does not stair-step over uneven terrain the way independently
## ground-snapped pieces would. With no neighbour in range, the result is a
## plain world-grid snap at `ground_y`.
static func resolve_position(raw: Vector3, ground_y: float, neighbour_positions: Array) -> Dictionary:
	var nearest: Variant = _nearest(raw, neighbour_positions)
	if nearest == null:
		return {"position": snap_to_grid(raw, ground_y), "snapped_to_neighbour": false}

	var neighbour: Vector3 = nearest
	var dx := snappedf(raw.x - neighbour.x, GRID_SIZE)
	var dz := snappedf(raw.z - neighbour.z, GRID_SIZE)
	if dx == 0.0 and dz == 0.0:
		# `raw` rounded onto the neighbour's own cell — that is overlap, not a
		# continuation of the run. Push out one cell along whichever axis
		# `raw` actually leaned toward, defaulting +X on a dead-even tie so
		# the result is always deterministic.
		if absf(raw.z - neighbour.z) > absf(raw.x - neighbour.x):
			dz = GRID_SIZE if raw.z >= neighbour.z else -GRID_SIZE
		else:
			dx = GRID_SIZE if raw.x >= neighbour.x else -GRID_SIZE
	return {
		"position": Vector3(neighbour.x + dx, neighbour.y, neighbour.z + dz),
		"snapped_to_neighbour": true,
	}


## D34/spec 13.4: the next step size in `SNAP_STEP_DEGS`, wrapping back to the
## coarsest after the finest. `build_placer.gd` calls this once per
## `build_snap_cycle` press; unlike `next_rotation_steps` this is a size a
## rotate press turns BY, not a count of turns already taken.
static func next_snap_step_deg(current_deg: float) -> float:
	var index := SNAP_STEP_DEGS.find(current_deg)
	return SNAP_STEP_DEGS[(index + 1) % SNAP_STEP_DEGS.size()] if index != -1 else SNAP_STEP_DEGS[0]


## D34/spec 13.2: every position in `candidates` within `SNAP_RADIUS` of `raw`
## on the X/Z plane, nearest first — the dots `build_placer.gd` draws at each
## candidate snap point, brightest on the one `resolve_position` above would
## actually choose (always `result[0]` when the array is non-empty, since
## `resolve_position` picks the same "closest" `_nearest` does). Capped at 4:
## the spec's own "1-4 dots," and a same-id neighbour set is never so dense
## that a 5th candidate this close would mean anything different.
static func neighbours_in_range(raw: Vector3, candidates: Array) -> Array:
	var out: Array = []
	for candidate: Variant in candidates:
		var pos: Vector3 = candidate
		if Vector2(raw.x - pos.x, raw.z - pos.z).length() <= SNAP_RADIUS:
			out.append(pos)
	out.sort_custom(func(a: Vector3, b: Vector3) -> bool:
		return Vector2(raw.x - a.x, raw.z - a.z).length_squared() \
			< Vector2(raw.x - b.x, raw.z - b.z).length_squared())
	return out.slice(0, mini(4, out.size()))


## The closest position in `candidates` to `raw` on the X/Z plane, or null if
## none is within `SNAP_RADIUS` (or the list is empty).
static func _nearest(raw: Vector3, candidates: Array) -> Variant:
	var best: Variant = null
	var best_d := INF
	for candidate: Variant in candidates:
		var pos: Vector3 = candidate
		var d := Vector2(raw.x - pos.x, raw.z - pos.z).length()
		if d < best_d:
			best_d = d
			best = pos
	if best != null and best_d <= SNAP_RADIUS:
		return best
	return null
