extends RefCounted

## Gate A modular construction contract for the Medieval Village MegaKit.
## The kit's own authored prefabs establish the measurements: floors/walls are on
## a 2m module, wall segments are 2m wide and 3.12m tall, and roofs sit around
## y=3.05. This file turns those same measurements into player-build anchors.
## No second architecture scale is invented.

const GRID := preload("res://scripts/build/build_grid.gd")

const MODULE := 2.0
const HALF := MODULE * 0.5
const ROOF_Y := 3.05
const WALL_IDS := ["wall", "door"]


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
		var pos := _position(entry)
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
		var p_raw := _position(entry)
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
		var p_raw := _position(entry)
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
		var p_raw := _position(entry)
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
		var p_raw := _position(floor)
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
			var w_raw := _position(wall)
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
