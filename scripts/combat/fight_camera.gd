extends RefCounted

const CONFIG_PATH := "res://data/config/camera.json"
static var _cached_config: Dictionary = {}

static func config() -> Dictionary:
	if _cached_config.is_empty():
		var raw: Variant = JSON.parse_string(FileAccess.get_file_as_string(CONFIG_PATH))
		if raw is Dictionary: _cached_config = raw.get("fight", {})
	return _cached_config


## Pure presentation composition from actual rendered bounds. No authority,
## collision, creature scale, player input or renderer state is mutated here.
static func size_class(height: float, config: Dictionary) -> String:
	var classes: Dictionary = config.get("size_classes", {})
	if height <= float(classes.get("small_max_m", 2.5)): return "small"
	if height <= float(classes.get("normal_max_m", 5.0)): return "normal"
	return "giant"

static func pair_profile(ally: AABB, foe: AABB, config: Dictionary) -> Dictionary:
	var key := size_class(ally.size.y, config) + "/" + size_class(foe.size.y, config)
	var profiles: Dictionary = config.get("size_matrix", {})
	var out: Dictionary = (profiles.get(key, {}) as Dictionary).duplicate()
	out["pair"] = key
	return out

static func pivot(ally: AABB, foe: AABB, config: Dictionary, profile: Dictionary) -> Vector3:
	var point := ally.get_center().lerp(foe.get_center(), clampf(float(config.get("midpoint_bias", 0.5)), 0.0, 1.0))
	point.y += float(profile.get("height_offset_m", 0.0))
	return point

static func required_distance(ally: AABB, foe: AABB, pivot_position: Vector3,
		camera_basis: Basis, vertical_fov_deg: float, aspect: float, fill: float,
		near_clearance: float) -> float:
	var vertical_tan := maxf(tan(deg_to_rad(vertical_fov_deg) * 0.5) * clampf(fill, 0.1, 0.95), 0.01)
	var horizontal_tan := vertical_tan * maxf(aspect, 0.1)
	var distance := maxf(near_clearance, 0.01)
	for box: AABB in [ally, foe]:
		for index: int in 8:
			var relative := box.get_endpoint(index) - pivot_position
			var depth := relative.dot(camera_basis.z)
			distance = maxf(distance, depth + maxf(absf(relative.dot(camera_basis.x)) / horizontal_tan,
				absf(relative.dot(camera_basis.y)) / vertical_tan) + near_clearance)
	return distance

static func project_box(box: AABB, camera_transform: Transform3D,
		vertical_fov_deg: float, aspect: float, near_plane: float) -> Dictionary:
	if box.size.is_zero_approx(): return {"valid": false}
	var inverse := camera_transform.affine_inverse()
	var tan_y := maxf(tan(deg_to_rad(vertical_fov_deg) * 0.5), 0.01)
	var tan_x := tan_y * maxf(aspect, 0.1)
	var lo := Vector2(INF, INF)
	var hi := Vector2(-INF, -INF)
	for index: int in 8:
		var relative: Vector3 = inverse * box.get_endpoint(index)
		var depth := -relative.z
		if depth <= near_plane: return {"valid": false}
		var point := Vector2(0.5 + relative.x / (2.0 * depth * tan_x), 0.5 - relative.y / (2.0 * depth * tan_y))
		lo = lo.min(point)
		hi = hi.max(point)
	return {"valid": true, "rect": Rect2(lo, hi-lo), "in_frame": lo.x >= 0.0 and lo.y >= 0.0 and hi.x <= 1.0 and hi.y <= 1.0}

static func overlap_ratio(ally: Rect2, foe: Rect2) -> float:
	var denominator := minf(ally.get_area(), foe.get_area())
	if denominator <= 0.0: return 1.0
	return ally.intersection(foe).get_area() / denominator

## Choose the nearest authored orbit correction that actually meets the overlap
## threshold; otherwise return the best measured candidate with pass=false.
## Caller retains manual-look grace and world-obstruction authority.
static func solve(ally: AABB, foe: AABB, yaw: float, pitch: float,
		vertical_fov_deg: float, aspect: float, base_distance: float, config: Dictionary, apply_pitch_offset: bool = true) -> Dictionary:
	var profile := pair_profile(ally, foe, config)
	var point := pivot(ally, foe, config, profile)
	var start_pitch := pitch + (deg_to_rad(float(profile.get("pitch_offset_deg", 0.0))) if apply_pitch_offset else 0.0)
	var offsets: Array = config.get("orbit_candidates_deg", [0.0,15.0,-15.0,30.0,-30.0,45.0,-45.0,60.0,-60.0])
	var best: Dictionary = {}
	for raw: Variant in offsets:
		var offset := float(raw)
		var basis := Basis.from_euler(Vector3(start_pitch, yaw + deg_to_rad(offset), 0.0))
		var distance := maxf(base_distance + float(profile.get("distance_offset_m", 0.0)), required_distance(ally, foe, point, basis,
			vertical_fov_deg, aspect, float(config.get("frame_fill", 0.82)), float(config.get("near_clearance_m", 0.5))))
		distance = minf(distance, float(config.get("max_distance_m", 48.0)))
		var transform := Transform3D(basis, point + basis.z * distance)
		var a := project_box(ally, transform, vertical_fov_deg, aspect, 0.05)
		var b := project_box(foe, transform, vertical_fov_deg, aspect, 0.05)
		if not bool(a.get("valid", false)) or not bool(b.get("valid", false)): continue
		var overlap := overlap_ratio(a.rect, b.rect)
		var passed := bool(a.in_frame) and bool(b.in_frame) and overlap <= float(config.get("max_actor_overlap", 0.1))
		var framed := bool(a.in_frame) and bool(b.in_frame)
		var candidate := {"pair": profile.pair, "pivot": point, "distance": distance, "pitch": start_pitch,
			"yaw_offset_deg": offset, "overlap": overlap, "ally_rect": a.rect, "foe_rect": b.rect, "pass": passed, "framed": framed}
		if best.is_empty() or (framed and not bool(best.framed)) \
				or (framed == bool(best.framed) and overlap < float(best.overlap)):
			best = candidate
		if passed: return candidate
	return best
