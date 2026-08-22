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

## BUILD-KIT-2 (measured, NOT applied below -- see the header note this
## points at). The roof mesh's local Z bounds are not centred on its own
## origin (measured [-0.47, 1.48], centre +0.505, not 0) and
## `Wall_Plaster_Straight`/`Wall_Plaster_Door_Flat`'s local Z bounds are not
## centred either (measured [-0.31, 0.09], centre -0.11, matching
## `build_door.gd::WALL_Z_CENTER` -- that file already needed the number for
## its jamb/lintel collision boxes). Uncorrected, a single-row roof
## undershoots a building's outward-facing edge by ~0.5m, and a wall's true
## thickness sits 0.11m off whichever line `_add_floor_edges` anchors it to
## -- and because that anchor line is fixed in WORLD space while each offset
## is fixed in the mesh's own LOCAL space, the offset lands in a different
## world direction per yaw, so two walls that should meet flush at a corner
## land on two different lines instead. Both are real, confirmed defects
## (the blind critic's #1 residual and #3). Recentring `_add_floor_edges`/
## `_add_supported_roofs` by these values is the correct fix, but every
## anchor coordinate they resolve is asserted to 0.08–0.0001m tolerance by
## `tests/test_gate_a_world_extent.gd` and `tests/helpers/
## gate_a_build_segment.gd`, neither owned by this lane -- shifting the
## contract's real output without updating every one of those assertions in
## the same change would ship a red branch or a silently un-tested drift.
## Left as a measured, ready-to-wire remainder rather than guessed at or
## shipped un-reviewed; see this branch's own report for detail.
const ROOF_Z_OFFSET := -0.505
const WALL_Z_CENTER := -0.11


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
		# front/back Z edge; yaw 90 walls run on left/right X edge.
		out.append({"position": p + Vector3(0, 0, HALF), "yaw_deg": 0.0})
		out.append({"position": p + Vector3(0, 0, -HALF), "yaw_deg": 0.0})
		out.append({"position": p + Vector3(HALF, 0, 0), "yaw_deg": 90.0})
		out.append({"position": p + Vector3(-HALF, 0, 0), "yaw_deg": 90.0})


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
			out.append({"position": Vector3(p.x, p.y + ROOF_Y, p.z), "yaw_deg": support_yaw})


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
