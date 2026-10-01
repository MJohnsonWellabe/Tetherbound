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
	return required_distance_points(box_points(ally), box_points(foe), pivot_position,
		camera_basis, vertical_fov_deg, aspect, fill, near_clearance)

static func box_points(box: AABB, pose: Transform3D = Transform3D.IDENTITY) -> PackedVector3Array:
	var points := PackedVector3Array()
	for index: int in 8: points.append(pose * box.get_endpoint(index))
	return points

static func required_distance_points(ally: PackedVector3Array, foe: PackedVector3Array, pivot_position: Vector3,
		camera_basis: Basis, vertical_fov_deg: float, aspect: float, fill: float,
		near_clearance: float) -> float:
	var vertical_tan := maxf(tan(deg_to_rad(vertical_fov_deg) * 0.5) * clampf(fill, 0.1, 0.95), 0.01)
	var horizontal_tan := vertical_tan * maxf(aspect, 0.1)
	var distance := maxf(near_clearance, 0.01)
	for points: PackedVector3Array in [ally, foe]:
		for point: Vector3 in points:
			var relative := point - pivot_position
			var depth := relative.dot(camera_basis.z)
			distance = maxf(distance, depth + maxf(absf(relative.dot(camera_basis.x)) / horizontal_tan,
				absf(relative.dot(camera_basis.y)) / vertical_tan) + near_clearance)
	return distance

static func project_box(box: AABB, camera_transform: Transform3D,
		vertical_fov_deg: float, aspect: float, near_plane: float) -> Dictionary:
	if box.size.is_zero_approx(): return {"valid": false}
	return project_points(box_points(box), camera_transform, vertical_fov_deg, aspect, near_plane)

## Transform the measured model box once, rather than axis-align it again after
## rotation. Re-aligning adds empty corner volume to a turning long creature.
static func project_points(points: PackedVector3Array, camera_transform: Transform3D,
		vertical_fov_deg: float, aspect: float, near_plane: float) -> Dictionary:
	if points.size() != 8: return {"valid": false}
	var inverse := camera_transform.affine_inverse()
	var tan_y := maxf(tan(deg_to_rad(vertical_fov_deg) * 0.5), 0.01)
	var tan_x := tan_y * maxf(aspect, 0.1)
	var lo := Vector2(INF, INF)
	var hi := Vector2(-INF, -INF)
	for point_world: Vector3 in points:
		var relative: Vector3 = inverse * point_world
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

## A conservative world-space corner margin; actual measured corners still own
## both the framing and zero-overlap result. No body transform changes.
static func guarded_points(points: PackedVector3Array, centre: Vector3, margin: float) -> PackedVector3Array:
	var out := PackedVector3Array()
	for point: Vector3 in points:
		out.append(point + (point-centre).normalized() * maxf(margin,0.0))
	return out

## Lens protection against the rotated model box, with the same world margin
## and minimum arm policy as the legacy axis-aligned guard.
static func oriented_body_limit(pivot_position: Vector3, arm_end: Vector3, box: AABB,
		pose: Transform3D, margin: float, minimum: float) -> float:
	var scale := pose.basis.get_scale().abs()
	if box.size.is_zero_approx() or minf(scale.x,minf(scale.y,scale.z)) <= 0.0001: return INF
	var local_margin := Vector3.ONE * maxf(margin,0.0) / scale
	var grown := AABB(box.position-local_margin,box.size+local_margin*2.0)
	var inverse := pose.affine_inverse()
	var local_start: Vector3 = inverse * pivot_position
	if grown.has_point(local_start): return INF
	var hit: Variant = grown.intersects_segment(local_start,inverse * arm_end)
	return INF if hit == null else maxf(minimum,pivot_position.distance_to(pose * (hit as Vector3))-margin)

## Choose the nearest authored orbit correction that actually meets the overlap
## threshold; otherwise return the best measured candidate with pass=false.
## Caller retains manual-look grace and world-obstruction authority.
static func solve(ally: AABB, foe: AABB, yaw: float, pitch: float,
		vertical_fov_deg: float, aspect: float, base_distance: float, config: Dictionary, apply_pitch_offset: bool = true,
		ally_points: PackedVector3Array = PackedVector3Array(), foe_points: PackedVector3Array = PackedVector3Array(),
		constrain_pose: Callable = Callable(), visibility_score: Callable = Callable()) -> Dictionary:
	var axis_ally := ally_points.is_empty()
	var axis_foe := foe_points.is_empty()
	if ally_points.is_empty(): ally_points = box_points(ally)
	if foe_points.is_empty(): foe_points = box_points(foe)
	var profile := pair_profile(ally, foe, config)
	var point := pivot(ally, foe, config, profile)
	var start_pitch := pitch + (deg_to_rad(float(profile.get("pitch_offset_deg", 0.0))) if apply_pitch_offset else 0.0)
	var offsets: Array = (config.get("orbit_candidates_deg", [0.0,15.0,-15.0,30.0,-30.0,45.0,-45.0,60.0,-60.0]) as Array).duplicate()
	# A fixed angular grid can miss the narrow side-on interval between a
	# short body and a tall neighbour. Include the actual pair's side-on view;
	# manual grace and obstruction handling remain at the caller.
	var line := foe.get_center() - ally.get_center()
	if bool(config.get("allow_pair_side_views",true)) and Vector2(line.x,line.z).length_squared() > 0.0001:
		var side_yaw := atan2(line.x,line.z) + PI * .5
		for side: float in [side_yaw, side_yaw + PI]:
			var offset := rad_to_deg(wrapf(side-yaw,-PI,PI))
			if not offsets.has(offset): offsets.append(offset)
	offsets.sort_custom(func(a: Variant,b: Variant) -> bool: return absf(float(a)) < absf(float(b)))
	var maximum := maxf(0.01,float(config.get("max_distance_m",48.0)))
	var distance_steps := clampi(int(config.get("separation_distance_steps",8)),1,12)
	var distance_scale := clampf(float(config.get("separation_distance_scale",1.2)),1.01,2.0)
	var best: Dictionary = {}
	# Reserve separation beyond the exact measured edge so the live tracker can
	# ease toward its chosen angle without spending its dead zone in overlap.
	var guard := maxf(0.0,float(config.get("separation_guard_m",0.0)))
	var guarded_ally := box_points(ally.grow(guard)) if axis_ally else guarded_points(ally_points,ally.get_center(),guard)
	var guarded_foe := box_points(foe.grow(guard)) if axis_foe else guarded_points(foe_points,foe.get_center(),guard)
	for raw: Variant in offsets:
		var offset := float(raw)
		var basis := Basis.from_euler(Vector3(start_pitch, yaw + deg_to_rad(offset), float(config.get("roll_radians",0.0))))
		var minimum := maxf(base_distance + float(profile.get("distance_offset_m", 0.0)), required_distance_points(guarded_ally, guarded_foe, point, basis,
			vertical_fov_deg, aspect, float(config.get("frame_fill", 0.82)), float(config.get("near_clearance_m", 0.5))))
		# Framing alone does not separate projected boxes. Search bounded
		# distances as well, preserving native size and the hard distance cap.
		for step: int in distance_steps + 1:
			var distance := minf(minimum * pow(distance_scale,step),maximum) if step < distance_steps else maximum
			var transform := Transform3D(basis, point + basis.z * distance)
			var actual_pivot := point
			var actual_distance := distance
			var constraint_info: Dictionary = {}
			if constrain_pose.is_valid():
				# Read-only caller probe owns world/model obstruction and the
				# actual available lens arm. Requested fit never bypasses it.
				var constrained: Variant = constrain_pose.call(point,basis,distance)
				if not constrained is Dictionary or not constrained.get("transform") is Transform3D \
					or not constrained.get("pivot") is Vector3 \
					or not constrained.get("distance") is float: continue
				transform = constrained.transform
				actual_pivot = constrained.pivot
				actual_distance = constrained.distance
				constraint_info = constrained
				if not transform.origin.is_finite() or not actual_pivot.is_finite() \
					or not is_finite(actual_distance) or actual_distance <= 0.0 or actual_distance > maximum: continue
			var a := project_points(ally_points, transform, vertical_fov_deg, aspect, 0.05)
			var b := project_points(foe_points, transform, vertical_fov_deg, aspect, 0.05)
			if not bool(a.get("valid", false)) or not bool(b.get("valid", false)): continue
			var overlap := overlap_ratio(a.rect, b.rect)
			var guarded_a := project_points(guarded_ally,transform,vertical_fov_deg,aspect,0.05)
			var guarded_b := project_points(guarded_foe,transform,vertical_fov_deg,aspect,0.05)
			var clear := bool(guarded_a.get("valid",false)) and bool(guarded_b.get("valid",false)) \
				and overlap_ratio(guarded_a.rect,guarded_b.rect)<=float(config.get("max_actor_overlap",0.0))
			var visibility: Dictionary = {}
			if visibility_score.is_valid():
				var checked: Variant = visibility_score.call(transform,a.rect,b.rect)
				if not checked is Dictionary or typeof(checked.get("pass"))!=TYPE_BOOL: continue
				visibility = checked
			var visibility_pass: bool = visibility.is_empty() or bool(visibility.get("pass",false))
			var passed := bool(a.in_frame) and bool(b.in_frame) and clear and visibility_pass
			var framed := bool(a.in_frame) and bool(b.in_frame)
			var candidate := {"pair": profile.pair, "pivot": actual_pivot, "distance": actual_distance, "pitch": start_pitch,
				"transform":transform,"requested_pivot":point,"requested_distance":distance,
				"yaw_offset_deg": offset, "overlap": overlap, "ally_rect": a.rect, "foe_rect": b.rect, "pass": passed, "framed": framed}
			candidate["visibility"] = visibility
			if not constraint_info.is_empty():
				candidate["world_room"] = constraint_info.get("world_room",null)
				candidate["model_room"] = constraint_info.get("model_room",INF)
			if best.is_empty() or (framed and not bool(best.framed)) \
					or (framed == bool(best.framed) and (overlap < float(best.overlap)
						or (overlap == float(best.overlap) and float(visibility.get("penalty",0.0))
							< float((best.get("visibility",{}) as Dictionary).get("penalty",0.0))))):
				best = candidate
			if passed: return candidate
			if distance >= maximum: break
	# A coarse orbit can straddle a narrow clear interval: one neighbour is
	# body-blocked and the other overlaps in projection. Refine only after the
	# complete coarse search fails, keeping the same constrained lens query.
	var refine_step := float(config.get("orbit_refinement_step_deg",0.0))
	var refine_span := float(config.get("orbit_refinement_span_deg",0.0))
	var refine_cap := clampi(int(config.get("orbit_refinement_max_candidates",12)),0,12)
	if best.is_empty() or offsets.size()<2 or not is_finite(refine_step) \
		or not is_finite(refine_span) or refine_step<=0.0 or refine_span<=0.0 or refine_cap==0:
		return best
	refine_step = clampf(refine_step,0.5,15.0)
	refine_span = clampf(refine_span,refine_step,30.0)
	var refined_offsets: Array = []
	for index: int in mini(60,int(floor(refine_span/refine_step))):
		for direction: float in [-1.0,1.0]:
			var refined := float(best.yaw_offset_deg)+direction*refine_step*float(index+1)
			if not offsets.has(refined): refined_offsets.append(refined)
	refined_offsets.sort_custom(func(a: Variant,b: Variant) -> bool: return absf(float(a)) < absf(float(b)))
	if refined_offsets.size()>refine_cap: refined_offsets.resize(refine_cap)
	if refined_offsets.is_empty(): return best
	var refined_config := config.duplicate()
	refined_config["orbit_candidates_deg"] = refined_offsets
	refined_config["allow_pair_side_views"] = false
	refined_config["orbit_refinement_step_deg"] = 0.0
	var refined_fit := solve(ally,foe,yaw,pitch,vertical_fov_deg,aspect,base_distance,
		refined_config,apply_pitch_offset,ally_points,foe_points,constrain_pose,visibility_score)
	if not refined_fit.is_empty() and (bool(refined_fit.get("pass",false)) \
		or (bool(refined_fit.framed) and not bool(best.framed)) \
		or (bool(refined_fit.framed)==bool(best.framed) and float(refined_fit.overlap)<float(best.overlap))):
		refined_fit["orbit_refined"] = true
		refined_fit["coarse_yaw_offset_deg"] = best.yaw_offset_deg
		refined_fit["refinement_candidate_count"] = refined_offsets.size()
		return refined_fit
	return best
