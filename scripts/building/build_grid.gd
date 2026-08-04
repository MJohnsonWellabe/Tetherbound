extends RefCounted

## Where a build piece goes when you let go of it.
##
## Pure, static, and free of nodes on purpose — the same shape as
## `scatter_rules.gd`, and for the same reason: snapping is arithmetic, and
## arithmetic that needs a scene to run cannot be unit tested. Everything here is
## checkable with numbers alone (`tests/test_build_grid.gd`).
##
## THE NUMBERS ARE MEASURED, NOT CHOSEN. Every dimension below was read off the
## Quaternius kit's own glTF accessors, and the kit is authored in metres, so
## nothing here corrects an import scale the way the nature packs need:
##
##   - all eighteen full-height walls are X = 2.000 exactly, Z = 0.4065
##   - all five floors are 2 x 2, and the halves are exactly 1 x 2 and 2 x 1
##   - `Wall_Arch` is exactly Y 0..3.0; the others draw to 3.123, the extra
##     0.123 being a decorative cap that overlaps the course above
##   - `Stairs_Exterior_*` are 2.0 x 1.0 x 2.0 — three per storey
##
## So: a 2m cell, a 1m half-step, a 3m storey, and 90-degree rotation. If the art
## pack is ever replaced, these are the four measurements to retake.
##
## THE TRAP, and the reason a piece carries a category at all: the kit uses TWO
## different origins. A wall's origin is the bottom-centre of a 2m EDGE; a
## floor's is the centre of the CELL. Snapping both the same way puts every wall
## half a cell out of place, which looks like a rotation bug and is not one.

## Metres per cell. The horizontal module.
const CELL := 2.0
## The finest horizontal step, for half-floors and half-gables.
const HALF_CELL := 1.0
## Metres per storey — floor of one level to floor of the next.
const STOREY := 3.0
## Stairs climb this much, so three make a storey.
const STAIR_RISE := 1.0
## Yaw increment. Stairs alone ship 45-degree variants; nothing else does.
const YAW_STEP := PI * 0.5

## Anchors. A piece snaps to the middle of a cell or to the middle of one of its
## four edges, and which one is a fact about the model's own origin.
const ANCHOR_CELL := "cell"
const ANCHOR_EDGE := "edge"


## Snap a world point to the centre of the cell containing it.
##
## Y is passed through untouched — height comes from the terrain or from the
## storey, never from the horizontal grid.
static func snap_to_cell(point: Vector3) -> Vector3:
	return Vector3(
		floorf(point.x / CELL) * CELL + CELL * 0.5,
		point.y,
		floorf(point.z / CELL) * CELL + CELL * 0.5
	)


## Snap to the nearest EDGE of the nearest cell, and report which way that edge
## faces.
##
## Returns `{position, yaw}`. A wall lies along an edge, so its facing is not a
## free choice — it is decided by which edge was picked, and a caller that snaps
## the position here and then takes yaw from the player's own rotation gets walls
## that float diagonally across cell corners.
##
## The player's yaw only breaks ties, by choosing which of the two axes to prefer
## when a point sits almost exactly on a corner.
static func snap_to_edge(point: Vector3) -> Dictionary:
	var cell := snap_to_cell(point)
	var offset := point - cell
	# Whichever axis the point is further along decides which pair of edges is
	# in play; the sign then picks one of that pair.
	if absf(offset.x) >= absf(offset.z):
		var side: float = signf(offset.x) if offset.x != 0.0 else 1.0
		return {
			"position": Vector3(cell.x + side * CELL * 0.5, point.y, cell.z),
			# A wall on an X-facing edge runs along Z.
			"yaw": PI * 0.5,
		}
	var side_z: float = signf(offset.z) if offset.z != 0.0 else 1.0
	return {
		"position": Vector3(cell.x, point.y, cell.z + side_z * CELL * 0.5),
		"yaw": 0.0,
	}


## Snap a point for a piece of the given anchor kind.
##
## The single entry point callers should use, so "which anchor does this piece
## want" is asked once here rather than at every call site.
static func snap(point: Vector3, anchor: String) -> Dictionary:
	if anchor == ANCHOR_EDGE:
		return snap_to_edge(point)
	return {"position": snap_to_cell(point), "yaw": NAN}


## Round a yaw to the nearest 90 degrees, normalised into [0, TAU).
##
## Normalised because it gets serialised: `-PI/2` and `3*PI/2` are the same
## rotation and should not produce two different save files.
static func snap_yaw(yaw: float) -> float:
	return fposmod(roundf(yaw / YAW_STEP) * YAW_STEP, TAU)


## Height of a storey above the structure's base.
static func storey_height(level: int) -> float:
	return float(level) * STOREY


## The four corners of a footprint, for asking the terrain whether the ground
## under a piece is flat enough to build on.
##
## Corners rather than the centre because the centre of a 2m tile can sit on
## perfectly level ground while the tile itself bridges a gully. `size_cells` is
## the piece's footprint in cells, so a 1x1 floor gets a 2m square.
static func footprint_corners(centre: Vector3, size_cells: Vector2i, yaw: float) -> Array[Vector3]:
	var half_x := float(size_cells.x) * CELL * 0.5
	var half_z := float(size_cells.y) * CELL * 0.5
	var basis := Basis(Vector3.UP, yaw)
	var out: Array[Vector3] = []
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			out.append(centre + basis * Vector3(sx * half_x, 0.0, sz * half_z))
	return out
