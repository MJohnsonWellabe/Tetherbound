extends RefCounted

## Gate A modular construction contract for the Medieval Village MegaKit.
## The kit's own authored prefabs establish the measurements: floors/walls are on
## a 2m module, wall segments are 2m wide and 3.12m tall, and roofs sit at
## y=3.33 (below). This file turns those same measurements into player-build
## anchors. No second architecture scale is invented.

const GRID := preload("res://scripts/build/build_grid.gd")

const MODULE := 2.0
const HALF := MODULE * 0.5
## BUILD-KIT-2: was 3.05, which sat the roof's own lowest vertex (measured
## local y=-0.34, scaled by buildables.json's roof `scale.y`=0.6066 to
## -0.206) a full 0.27m BELOW `WALL_HEIGHT` (3.12, `Wall_Plaster_Straight`'s
## measured top). At a grazing exterior angle that gap reads as "open sky
## over the top plate" — the blind critic's #1 defect — because the camera
## sees past the sunk-in eave into the gable's hollow underside before it
## ever reaches solid roof. 3.12 + 0.206 = 3.326 puts the eave's lowest
## vertex exactly flush with the wall top instead of below it.
const ROOF_Y := 3.326
const WALL_IDS := ["wall", "door"]

## BUILD-KIT-3: NOW WIRED IN (was measured-but-not-applied on BUILD-KIT-2 --
## see the git history of this comment for why it was left out that round).
## Re-measured fresh against the installed glTFs
## (`tools/diag_roof_wall_bounds.gd`, not shipped) rather than trusted from
## the prior lane's numbers: `Wall_Plaster_Straight`/`Wall_Plaster_Door_Flat`
## local Z bounds are [-0.314035, 0.092447], centre -0.110794 (the prior
## lane's -0.11 was already correct to 3 decimals). `Roof_RoundTile_2x1`
## local Z bounds at the OLD scale.z=1.0 were [-0.468915, 1.483274], centre
## +0.507180 -- also not centred on its own origin.
##
## A blind critic's rendered evidence (this branch, `shots/_diag/
## build_kit_house_exterior.png` before this fix) showed both consequences
## live, not just in theory: a ~0.5m strip of open sky between the front
## wall's top plate and the front row of roof tiles (the roof mesh's own Z
## content sits mostly BEHIND where its node origin is placed, so a roof
## "at" a floor tile's anchor covers mostly the tile beyond it, not the one
## it is nominally roofing), and diagonal cross-brace timber from one wall's
## exterior face visible through the gap at an unflush corner into the next
## wall's interior side.
##
## `_thickness_correction()` below fixes both the same way: a piece's own
## local-space Z centre, rotated into world space by the piece's placement
## yaw (identity for a yaw-0 wall/roof, but a front/back Z offset becomes a
## left/right X offset once a wall/roof is placed on the OTHER pair of floor
## edges, which is exactly why a flat per-axis constant added un-rotated
## made two flush-intended walls land on two different world lines), added
## to the anchor `_add_floor_edges`/`_add_supported_roofs` already compute.
## Recentres the piece's VISIBLE material on the anchor line instead of the
## piece's glTF origin.
##
## Every anchor coordinate these functions resolve is asserted to
## 0.08-0.0001m tolerance by `tests/test_gate_a_world_extent.gd` and
## `tests/helpers/gate_a_build_segment.gd` -- both updated in this same
## change (see their own diffs) so this ships without a silently-stale test.
const WALL_Z_CENTER := -0.110794

## BUILD-KIT-3: the roof's Z scale is now 1.10 (was 1.0) rather than the flush
## 1.0 BUILD-KIT-2 shipped -- a deliberate eave overhang past the wall plane
## (blind critic's #2: "walls projecting past the roof" reads wrong on every
## reference building; the fix stays inside the art rules because it is an
## offset/scale of the existing roof piece, not new geometry). Scaling only
## the Z axis (the eave-to-eave direction; `ralph/BLOCKED.md`'s open gable-cap
## item already established the ridge runs along local X, so leaving X/Y
## scale untouched does not touch the blocked mid-run seam) moves the mesh's
## own local-Z centre too, since Godot scales a node's children about that
## node's origin, not about the content's bounding-box centre: centre(k) =
## 0.507180 * k. At k=1.10, centre = 0.557898.
const ROOF_Z_CENTER := 0.557898


## Rotates a piece's own local-space Z-centring offset (`WALL_Z_CENTER` for a
## wall/door, `ROOF_Z_CENTER` for a roof) into world space for the piece's
## placement yaw, so a candidate position built from a floor-tile anchor
## lands the piece's VISIBLE material centre on that anchor line instead of
## the piece's glTF origin. Identity at yaw 0 (a straight Z offset); a wall
## or roof placed on the perpendicular pair of floor edges (yaw 90) needs the
## same physical offset expressed along world X instead, which is exactly
## what `Vector3.rotated` does and a flat unrotated constant cannot.
static func _thickness_correction(local_z_center: float, yaw_deg: float) -> Vector3:
	return Vector3(0.0, 0.0, -local_z_center).rotated(Vector3.UP, deg_to_rad(yaw_deg))


## Resolve an armed piece. Structural candidates win when the aim is near one;
## otherwise the old same-id/grid resolver remains the free-placement fallback.
## Returns {position, snapped_to_neighbour, yaw_deg, structural}.
static func resolve(raw: Vector3, ground_y: float, armed: String, placed: Array) -> Dictionary:
	var structural := candidates(armed, placed)
	var nearest := _nearest_candidate(raw, structural)
	if not nearest.is_empty():
		return {
			"position": nearest.position,
			"snapped_to_neighbour": true,
			"yaw_deg": float(nearest.get("yaw_deg", 0.0)),
			"structural": true,
		}

	var same: Array = []
	for raw_entry: Variant in placed:
		if typeof(raw_entry) != TYPE_DICTIONARY:
			continue
		var entry := raw_entry as Dictionary
		if bool(entry.get("removed", false)) or str(entry.get("id", "")) != armed:
			continue
		var pos: Variant = _position(entry)
		if pos != null:
			same.append(pos)
	var old := GRID.resolve_position(raw, ground_y, same)
	return {
		"position": old.position,
		"snapped_to_neighbour": bool(old.snapped_to_neighbour),
		"yaw_deg": NAN,
		"structural": false,
	}


## Candidate anchor dictionaries. Position is enough for overlay drawing; yaw is
## present for walls/doors so edge orientation is automatic and flush.
static func candidates(armed: String, placed: Array) -> Array:
	var out: Array = []
	if WALL_IDS.has(armed):
		_add_floor_edges(out, placed)
		_add_wall_continuations(out, placed)
	elif armed == "roof":
		_add_supported_roofs(out, placed)
	return _dedupe(out)


static func candidate_positions(armed: String, placed: Array) -> Array:
	var out: Array = []
	for candidate: Dictionary in candidates(armed, placed):
		out.append(candidate.position)
	return out


## Occupancy is structural rather than same-id-only: wall and door share an edge
## slot; roof can occupy X/Z above a floor because Y is part of the check.
static func occupied(armed: String, spot: Vector3, placed: Array) -> bool:
	var blocked_ids := WALL_IDS if WALL_IDS.has(armed) else [armed]
	for raw_entry: Variant in placed:
		if typeof(raw_entry) != TYPE_DICTIONARY:
			continue
		var entry := raw_entry as Dictionary
		if bool(entry.get("removed", false)) or not blocked_ids.has(str(entry.get("id", ""))):
			continue
		var p_raw: Variant = _position(entry)
		if p_raw == null:
			continue
		var p: Vector3 = p_raw
		if absf(p.x - spot.x) < 0.02 and absf(p.z - spot.z) < 0.02 and absf(p.y - spot.y) < 0.15:
			return true
	return false


static func _add_floor_edges(out: Array, placed: Array) -> void:
	for raw_entry: Variant in placed:
		if typeof(raw_entry) != TYPE_DICTIONARY:
			continue
		var entry := raw_entry as Dictionary
		if bool(entry.get("removed", false)) or str(entry.get("id", "")) != "floor":
			continue
		var p_raw: Variant = _position(entry)
		if p_raw == null:
			continue
		var p: Vector3 = p_raw
		# MegaKit convention from building_prefabs.json: yaw 0 walls run on the
		# front/back Z edge; yaw 90 walls run on left/right X edge. Each anchor
		# gets `_thickness_correction` added so the wall's own off-centre
		# material lands ON this edge line, not offset from it (see that
		# function's header).
		var c0 := _thickness_correction(WALL_Z_CENTER, 0.0)
		var c90 := _thickness_correction(WALL_Z_CENTER, 90.0)
		out.append({"position": p + Vector3(0, 0, HALF) + c0, "yaw_deg": 0.0})
		out.append({"position": p + Vector3(0, 0, -HALF) + c0, "yaw_deg": 0.0})
		out.append({"position": p + Vector3(HALF, 0, 0) + c90, "yaw_deg": 90.0})
		out.append({"position": p + Vector3(-HALF, 0, 0) + c90, "yaw_deg": 90.0})


static func _add_wall_continuations(out: Array, placed: Array) -> void:
	for raw_entry: Variant in placed:
		if typeof(raw_entry) != TYPE_DICTIONARY:
			continue
		var entry := raw_entry as Dictionary
		if bool(entry.get("removed", false)) or not WALL_IDS.has(str(entry.get("id", ""))):
			continue
		var p_raw: Variant = _position(entry)
		if p_raw == null:
			continue
		var p: Vector3 = p_raw
		var yaw := fposmod(float(entry.get("yaw_deg", 0.0)), 180.0)
		if absf(yaw - 90.0) < 45.0:
			out.append({"position": p + Vector3(0, 0, MODULE), "yaw_deg": 90.0})
			out.append({"position": p + Vector3(0, 0, -MODULE), "yaw_deg": 90.0})
		else:
			out.append({"position": p + Vector3(MODULE, 0, 0), "yaw_deg": 0.0})
			out.append({"position": p + Vector3(-MODULE, 0, 0), "yaw_deg": 0.0})


static func _add_supported_roofs(out: Array, placed: Array) -> void:
	for raw_floor: Variant in placed:
		if typeof(raw_floor) != TYPE_DICTIONARY:
			continue
		var floor := raw_floor as Dictionary
		if bool(floor.get("removed", false)) or str(floor.get("id", "")) != "floor":
			continue
		var p_raw: Variant = _position(floor)
		if p_raw == null:
			continue
		var p: Vector3 = p_raw
		var support_yaw := NAN
		for raw_wall: Variant in placed:
			if typeof(raw_wall) != TYPE_DICTIONARY:
				continue
			var wall := raw_wall as Dictionary
			if bool(wall.get("removed", false)) or not WALL_IDS.has(str(wall.get("id", ""))):
				continue
			var w_raw: Variant = _position(wall)
			if w_raw == null:
				continue
			var w: Vector3 = w_raw
			var dx := absf(w.x - p.x)
			var dz := absf(w.z - p.z)
			var edge_support := (absf(dx - HALF) < 0.12 and dz < 0.12) or (absf(dz - HALF) < 0.12 and dx < 0.12)
			if edge_support:
				support_yaw = float(wall.get("yaw_deg", 0.0))
				break
		if not is_nan(support_yaw):
			var roof_c := _thickness_correction(ROOF_Z_CENTER, support_yaw)
			out.append({
				"position": Vector3(p.x, p.y + ROOF_Y, p.z) + roof_c,
				"yaw_deg": support_yaw,
			})


static func _nearest_candidate(raw: Vector3, candidates_in: Array) -> Dictionary:
	var best: Dictionary = {}
	var best_d := INF
	for candidate: Dictionary in candidates_in:
		var p: Vector3 = candidate.position
		var d := Vector2(raw.x - p.x, raw.z - p.z).length()
		if d < best_d:
			best_d = d
			best = candidate
	return best if not best.is_empty() and best_d <= GRID.SNAP_RADIUS else {}


static func _dedupe(entries: Array) -> Array:
	var out: Array = []
	for candidate: Dictionary in entries:
		var p: Vector3 = candidate.position
		var duplicate := false
		for existing: Dictionary in out:
			var q: Vector3 = existing.position
			if p.distance_squared_to(q) < 0.0004:
				duplicate = true
				break
		if not duplicate:
			out.append(candidate)
	return out


static func _position(entry: Dictionary) -> Variant:
	var raw: Variant = entry.get("position", [])
	if raw is Array and (raw as Array).size() >= 3:
		return Vector3(float(raw[0]), float(raw[1]), float(raw[2]))
	return null
