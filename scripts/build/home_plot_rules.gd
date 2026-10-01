extends RefCounted

## Pure home-plot geometry/data policy. No save, inventory mutation or station
## registry. BuildPlacer supplies canonical config/catalogue and actual pose.
const DATA := preload("res://scripts/data/redesign_data.gd")

static func refusal(code: String) -> Dictionary:
	return {"ok": false, "code": code}


static func numbers(value: Variant, count: int) -> bool:
	if not value is Array or value.size() != count: return false
	for n: Variant in value:
		if not (n is int or n is float) or not is_finite(float(n)): return false
	return true


## Compose the canonical F16 station array under an authoring envelope; never
## replace its strict schema with the envelope or create another station set.
static func config_valid(cfg: Variant, schema: Dictionary, canonical: Array) -> bool:
	if not cfg is Dictionary or cfg.get("schema_version") != 1: return false
	var stations: Variant = cfg.get("stations")
	if not DATA.validate(stations, schema).is_empty() or stations != canonical: return false
	var plot: Variant = cfg.get("homestead_plot")
	var altar: Variant = cfg.get("altar")
	if not plot is Dictionary or not altar is Dictionary: return false
	if plot.get("realm") != "meadows" or altar.get("id") != "altar" or altar.get("realm") != "meadows": return false
	if not numbers(plot.get("centre"), 2) or not numbers(plot.get("size_m"), 2): return false
	for n: Variant in plot.size_m:
		if float(n) <= 0.0: return false
	var exclusions: Variant = plot.get("exclusions")
	if not exclusions is Array or exclusions.size() != 3: return false
	var names: Array = []
	for row: Variant in exclusions:
		if not row is Dictionary or not ["farmhouse", "village_road", "berry_beds"].has(row.get("id")): return false
		if names.has(row.id) or not numbers(row.get("min"), 2) or not numbers(row.get("max"), 2): return false
		names.append(row.id)
		if float(row.min[0]) >= float(row.max[0]) or float(row.min[1]) >= float(row.max[1]): return false
	if altar.get("mesh") != "res://assets/props/quaternius_fantasy/BookStand.gltf": return false
	if not numbers(altar.get("model_min"), 3) or not numbers(altar.get("model_max"), 3): return false
	for i: int in 3:
		if float(altar.model_min[i]) >= float(altar.model_max[i]): return false
	for key: String in ["placement_clearance_m", "maximum_slope_rise_m", "ground_tolerance_m", "maximum_place_distance_m"]:
		var n: Variant = altar.get(key)
		if not (n is int or n is float) or not is_finite(float(n)) or float(n) <= 0.0: return false
	return true


static func corners(cfg: Dictionary, position: Vector3, yaw_deg: float) -> Array[Vector2]:
	var altar: Dictionary = cfg.altar
	var lo: Array = altar.model_min
	var hi: Array = altar.model_max
	var margin := float(altar.placement_clearance_m)
	var out: Array[Vector2] = []
	var rotation := Basis(Vector3.UP, deg_to_rad(yaw_deg))
	for point: Vector3 in [Vector3(float(lo[0]) - margin, 0, float(lo[2]) - margin),
		Vector3(float(hi[0]) + margin, 0, float(lo[2]) - margin),
		Vector3(float(hi[0]) + margin, 0, float(hi[2]) + margin),
		Vector3(float(lo[0]) - margin, 0, float(hi[2]) + margin)]:
		var world_point := position + rotation * point
		out.append(Vector2(world_point.x, world_point.z))
	return out


## Convex SAT: touching an exclusion is refused too. Corner-only checks miss
## a rotated footprint straddling a thin road with every corner outside it.
static func _overlaps(a: Array[Vector2], b: Array[Vector2]) -> bool:
	for polygon: Array[Vector2] in [a, b]:
		for i: int in polygon.size():
			var edge := polygon[(i + 1) % polygon.size()] - polygon[i]
			var axis := Vector2(-edge.y, edge.x)
			var a_min := INF
			var a_max := -INF
			var b_min := INF
			var b_max := -INF
			for v: Vector2 in a:
				a_min = minf(a_min, v.dot(axis))
				a_max = maxf(a_max, v.dot(axis))
			for v: Vector2 in b:
				b_min = minf(b_min, v.dot(axis))
				b_max = maxf(b_max, v.dot(axis))
			if a_max < b_min or b_max < a_min: return false
	return true


static func placement(cfg: Dictionary, realm: String, position: Vector3, yaw_deg: float) -> Dictionary:
	if realm != str(cfg.homestead_plot.realm): return refusal("station_home_only")
	if not position.is_finite() or not is_finite(yaw_deg): return refusal("station_pose_invalid")
	var plot: Dictionary = cfg.homestead_plot
	var centre := Vector2(float(plot.centre[0]), float(plot.centre[1]))
	var half := Vector2(float(plot.size_m[0]), float(plot.size_m[1])) * 0.5
	var polygon := corners(cfg, position, yaw_deg)
	for v: Vector2 in polygon:
		if v.x < centre.x - half.x or v.x > centre.x + half.x \
				or v.y < centre.y - half.y or v.y > centre.y + half.y:
			return refusal("station_home_only")
	for exclusion: Dictionary in plot.exclusions:
		var lo := Vector2(float(exclusion.min[0]), float(exclusion.min[1]))
		var hi := Vector2(float(exclusion.max[0]), float(exclusion.max[1]))
		var box: Array[Vector2] = [lo, Vector2(hi.x, lo.y), hi, Vector2(lo.x, hi.y)]
		if _overlaps(polygon, box): return refusal("station_home_only")
	return {"ok": true, "code": ""}


## UID is existing WorldLedger bN, never minted by this module. Every matching
## row, including removed or wrong-realm duplicates, participates in uniqueness.
static func record(cfg: Dictionary, records: Array, uid: String) -> Dictionary:
	if not uid.begins_with("b") or uid.length() < 2: return refusal("station_uid_invalid")
	var digits := uid.substr(1)
	if not digits.is_valid_int() or int(digits) <= 0 or str(int(digits)) != digits:
		return refusal("station_uid_invalid")
	var index := -1
	for i: int in records.size():
		var row: Variant = records[i]
		if row is Dictionary and row.get("uid") == uid:
			if index >= 0: return refusal("station_uid_duplicate")
			index = i
	if index < 0: return refusal("station_gone")
	var row: Dictionary = records[index]
	if row.get("id") != "altar" or row.get("realm") != "meadows" \
			or not row.get("removed", false) is bool or row.get("removed", false) != false \
			or not row.get("paid") is bool or row.get("paid") != true:
		return refusal("station_record_invalid")
	if not numbers(row.get("position"), 3): return refusal("station_pose_invalid")
	var yaw: Variant = row.get("yaw_deg")
	if not (yaw is int or yaw is float) or not is_finite(float(yaw)): return refusal("station_pose_invalid")
	var p: Array = row.position
	var result := placement(cfg, "meadows", Vector3(float(p[0]), float(p[1]), float(p[2])), float(yaw))
	if not result.ok: return result
	return {"ok": true, "code": "", "index": index, "record": row.duplicate(true), "key": "altar:meadows:" + uid}
