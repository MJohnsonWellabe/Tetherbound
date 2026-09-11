extends RefCounted

## Optional NEXT-run instrumentation. Reads live state only; never drives play.
## Nearest-route metadata is not road membership or complete-route coverage.
const ROAD := preload("res://tools/gate_f/road_creature_visibility_model.gd")
const INPUT_OWNER := preload("res://scripts/ui/input_owner.gd")
const MIN_TRAVEL_HEADING_M := ROAD.SAMPLE_STEP_M * 0.5
const MAX_ROUTE_DISTANCE_M := 5.0
const HEADING_ALIGNMENT_DOT := 0.9
var failures: Array[String] = []
var _tree: SceneTree
var _file: FileAccess
var _outdoor: Callable
var _routes_cache := {}
var _scene_id := 0
var _previous := Vector3.INF
var _sample_origin := Vector3.INF
var _since_sample := 0.0
var _travelled := 0.0
var _samples := 0
var _camera_below_two := 0
var _graded_road_samples := 0
var _below_two := 0
var _unaligned_road_samples := 0
var _off_route_samples := 0
var _unusable_heading_samples := 0
var _undersampled_intervals := 0
var _running := false

func start(tree: SceneTree, new_output_path: String, outdoor_classifier: Callable = Callable()) -> bool:
	if _tree != null or tree == null or new_output_path.is_empty() or FileAccess.file_exists(new_output_path):
		failures.append("Observer needs a tree and a new output file; existing evidence is never overwritten")
		return false
	_file = FileAccess.open(new_output_path, FileAccess.WRITE)
	if _file == null:
		failures.append("Observer could not create its requested evidence file")
		return false
	_tree = tree
	_outdoor = outdoor_classifier
	_running = true
	_write({"kind":"contract", "sample_step_m":ROAD.SAMPLE_STEP_M,
		"forward_degrees":180, "required_visible":ROAD.REQUIRED_VISIBLE,
		"minimum_projected_height_px_at_720p":ROAD.MIN_VISIBLE_HEIGHT_PX,
		"minimum_travel_heading_m":MIN_TRAVEL_HEADING_M,
		"maximum_route_distance_m":MAX_ROUTE_DISTANCE_M,
		"heading_alignment_dot_strictly_greater_than":HEADING_ALIGNMENT_DOT,
		"route_classifier":"nearest authored polyline; membership requires distance <= maximum_route_distance_m",
		"complete_coverage":false,
		"visibility":"actual camera frustum, projected body-height endpoints and centre ray; not rendered silhouette proof"})
	tree.physics_frame.connect(_observe)
	return true

func stop() -> Dictionary:
	if _running and _tree != null and _tree.physics_frame.is_connected(_observe):
		_tree.physics_frame.disconnect(_observe)
	_running = false
	var summary := result()
	if _file != null:
		_write(summary)
		_file.flush()
		_file.close()
		_file = null
	return summary

func result() -> Dictionary:
	return {"kind":"summary", "samples":_samples, "below_two_samples":_below_two,
		"camera_below_two_samples":_camera_below_two,
		"graded_road_samples":_graded_road_samples,
		"unaligned_road_samples":_unaligned_road_samples,
		"off_route_samples":_off_route_samples,
		"unusable_heading_samples":_unusable_heading_samples,
		"observed_travel_m":_travelled, "undersampled_intervals":_undersampled_intervals,
		"complete_coverage":false, "failures":failures.duplicate(),
		"caveat":"below_two_samples grades only aligned <=5m road samples; camera_below_two_samples retains all observed-camera telemetry; unvisited routes and rendered silhouette readability remain unproved"}

func _observe() -> void:
	var scene := _tree.current_scene as Node3D
	var game := _tree.root.get_node_or_null("Game")
	if scene == null or game == null:
		_reset_motion_sample()
		return
	var player := scene.get_node_or_null("Player") as CharacterBody3D
	var director := scene.get_node_or_null("EncounterDirector")
	var camera := scene.get_viewport().get_camera_3d()
	var realm := str(game.get("current_realm"))
	if player == null or director == null or camera == null or not director.has_method("wild_creatures"):
		_reset_motion_sample()
		return
	if _scene_id != scene.get_instance_id():
		_scene_id = scene.get_instance_id()
		_reset_motion_sample()
		_write({"kind":"scene_boundary", "realm":realm, "scene":str(scene.scene_file_path), "scene_id":_scene_id})
	var manager := scene.get_node_or_null("CombatManager")
	if _tree.paused or INPUT_OWNER.current(_tree) != null \
			or (manager != null and manager.has_method("is_fighting") and manager.is_fighting()) \
			or (director.has_method("trainer_battle_active") and director.trainer_battle_active()):
		_reset_motion_sample()
		return
	var context := "unknown"
	if _outdoor.is_valid():
		context = "outdoor" if bool(_outdoor.call(scene, player)) else "indoor"
	else:
		var cave := scene.get_node_or_null("WaterVeilfall")
		if cave != null and cave.contains_interior(player.global_position):
			context = "indoor"
	if context == "indoor":
		_reset_motion_sample()
		return
	var at := player.global_position
	if not at.is_finite():
		_reset_motion_sample()
		return
	if not _previous.is_finite():
		_previous = at
		_sample_origin = at
		return
	var distance := Vector2(at.x-_previous.x, at.z-_previous.z).length()
	_previous = at
	_travelled += distance
	_since_sample += distance
	if _since_sample < ROAD.SAMPLE_STEP_M:
		return
	var elapsed_distance := _since_sample
	var skipped := maxi(0, int(floor(_since_sample / ROAD.SAMPLE_STEP_M)) - 1)
	_undersampled_intervals += skipped
	# Observe at this actual frame; never interpolate a visibility observation
	# at a position the camera was not sampled. Preserve any spacing overshoot.
	_since_sample = 0.0
	var travel_vector := at - _sample_origin
	travel_vector.y = 0.0
	var travel_displacement := travel_vector.length()
	var travel_heading := travel_heading_from_sample_origin(_sample_origin, at)
	_sample_origin = at
	var route := nearest_route(at, _routes(realm))
	var route_tangent: Vector3 = route.get("tangent", Vector3.ZERO)
	var route_record := route.duplicate()
	route_record["tangent"] = _v(route_tangent)
	var aligned_route_tangent := align_route_tangent_to_travel(route_tangent, travel_heading)
	var forward := -camera.global_basis.z
	var alignment := alignment_metrics(forward, travel_heading, aligned_route_tangent)
	var route_distance: Variant = route.get("distance_m")
	var near_route := route_distance is float and float(route_distance) <= MAX_ROUTE_DISTANCE_M
	var heading_usable := travel_displacement >= MIN_TRAVEL_HEADING_M \
		and not travel_heading.is_zero_approx() and not aligned_route_tangent.is_zero_approx()
	var alignment_eligible := heading_usable and near_route \
		and alignment_is_eligible(alignment)
	var bodies: Array[Dictionary] = []
	var accepted := 0
	var travel_size_candidates := 0
	var route_size_candidates := 0
	var viewport := camera.get_viewport().get_visible_rect().size
	for candidate in director.wild_creatures():
		var body := candidate as Node3D
		if not eligible_body(body):
			continue
		var observation := _body_sample(body, player, camera, at, forward, viewport)
		var offset := body.global_position - at
		var travel_forward: Variant = null if travel_heading.is_zero_approx() \
			else in_forward_half_plane(offset, travel_heading)
		var route_forward: Variant = null if aligned_route_tangent.is_zero_approx() \
			else in_forward_half_plane(offset, aligned_route_tangent)
		observation["travel_forward"] = travel_forward
		observation["route_forward"] = route_forward
		if travel_forward == true and float(observation.cp2_calibrated_height_px) >= ROAD.MIN_VISIBLE_HEIGHT_PX:
			travel_size_candidates += 1
		if route_forward == true and float(observation.cp2_calibrated_height_px) >= ROAD.MIN_VISIBLE_HEIGHT_PX:
			route_size_candidates += 1
		bodies.append(observation)
		if bool(observation.credited): accepted += 1
	_samples += 1
	var camera_below_two := accepted < ROAD.REQUIRED_VISIBLE
	if camera_below_two:
		_camera_below_two += 1
	if alignment_eligible:
		_graded_road_samples += 1
		if is_road_failure(accepted, true):
			_below_two += 1
	elif not near_route:
		_off_route_samples += 1
	elif not heading_usable:
		_unusable_heading_samples += 1
	else:
		_unaligned_road_samples += 1
	var riding := scene.get_node_or_null("RidingController")
	var mode := "grounded" if player.is_on_floor() else "airborne_or_carried"
	if riding != null and riding.is_mounted(): mode = "mounted"
	_write({"kind":"sample", "time_ms":Time.get_ticks_msec(), "physics_frame":Engine.get_physics_frames(),
		"realm":realm, "scene":str(scene.scene_file_path), "scene_id":_scene_id,
		"trainer":_v(at), "camera":_v(camera.global_position), "camera_forward":_v(forward),
		"camera_fov":camera.fov, "camera_keep_aspect":camera.keep_aspect,
		"viewport":[viewport.x,viewport.y], "renderer":RenderingServer.get_current_rendering_method(),
		"display_server":DisplayServer.get_name(), "context":context, "movement":mode,
		"observed_travel_m":_travelled, "distance_since_previous_sample_m":elapsed_distance,
		"sample_displacement_m":travel_displacement, "travel_heading":_v(travel_heading),
		"route_tangent_aligned_to_travel":_v(aligned_route_tangent),
		"camera_forward_travel_dot":alignment.camera_travel_dot,
		"camera_forward_route_dot":alignment.camera_route_dot,
		"travel_route_dot":alignment.travel_route_dot,
		"heading_usable":heading_usable, "near_route":near_route,
		"alignment_eligible":alignment_eligible,
		"unobserved_sample_intervals":skipped, "nearest_route":route_record,
		"visible_forward_count":accepted, "camera_visible_forward_count":accepted,
		"travel_forward_size_candidate_count":travel_size_candidates,
		"route_forward_size_candidate_count":route_size_candidates,
		"camera_below_two":camera_below_two,
		"below_two":is_road_failure(accepted, alignment_eligible), "bodies":bodies})

func _reset_motion_sample() -> void:
	_previous = Vector3.INF
	_sample_origin = Vector3.INF
	_since_sample = 0.0

func _body_sample(body: Node3D, player: CharacterBody3D, camera: Camera3D,
		origin: Vector3, forward: Vector3, viewport: Vector2) -> Dictionary:
	var height := float(body.body_height()) if body.has_method("body_height") else 0.0
	var foot := body.global_position
	var head := foot + Vector3.UP * height
	var centre := foot + Vector3.UP * height * 0.52 # Existing production capture sample.
	var ahead := in_forward_half_plane(foot - origin, forward)
	var projected := 0.0
	if height > 0 and not camera.is_position_behind(foot) and not camera.is_position_behind(head):
		projected = absf(camera.unproject_position(head).y - camera.unproject_position(foot).y)
	var reference_pixels := pixels_at_reference_height(projected, viewport.y)
	var framed := camera.is_position_in_frustum(centre) and not camera.is_position_behind(centre)
	var los := {"clear":false, "checked":false, "blocker":""}
	if ahead and reference_pixels >= ROAD.MIN_VISIBLE_HEIGHT_PX:
		var query := PhysicsRayQueryParameters3D.create(camera.global_position, centre)
		query.collide_with_areas = false
		query.exclude = [player.get_rid()]
		var hit := body.get_world_3d().direct_space_state.intersect_ray(query)
		var collider: Object = hit.get("collider")
		los = {"clear":hit.is_empty() or collider == body, "checked":true,
			"blocker":str((collider as Node).get_path()) if collider is Node and collider != body else ""}
	return {"body_id":body.get_instance_id(), "path":str(body.get_path()),
		"species":str(body.get("species_id")), "position":_v(foot), "height_m":height,
		"site":str(body.get_meta("water_site_id", "")), "forward":ahead,
		"distance_m":origin.distance_to(foot), "projected_height_px":projected,
		"projected_height_px_at_720p":reference_pixels,
		"cp2_calibrated_height_px":ROAD.projected_height_px(height, Vector2(foot.x-origin.x,foot.z-origin.z).length()),
		"framed":framed,
		"los":los, "credited":ahead and framed and reference_pixels >= ROAD.MIN_VISIBLE_HEIGHT_PX and bool(los.clear)}

static func eligible_body(body: Node3D) -> bool:
	return is_instance_valid(body) and body.is_inside_tree() and body.is_visible_in_tree() \
		and body.has_method("is_alive") and bool(body.is_alive())

static func in_forward_half_plane(offset: Vector3, camera_forward: Vector3) -> bool:
	var horizontal := Vector2(offset.x, offset.z)
	var forward := Vector2(camera_forward.x, camera_forward.z)
	return not forward.is_zero_approx() and (horizontal.is_zero_approx() or horizontal.dot(forward) >= 0.0)

static func pixels_at_reference_height(actual_pixels: float, viewport_height: float) -> float:
	return actual_pixels * ROAD.VIEWPORT_HEIGHT_PX / viewport_height if viewport_height > 0 else 0.0

static func horizontal_heading(vector: Vector3) -> Vector3:
	var horizontal := Vector3(vector.x, 0.0, vector.z)
	return horizontal.normalized() if not horizontal.is_zero_approx() else Vector3.ZERO

static func travel_heading_from_sample_origin(sample_origin: Vector3, at: Vector3) -> Vector3:
	if not sample_origin.is_finite() or not at.is_finite():
		return Vector3.ZERO
	return horizontal_heading(at - sample_origin)

static func align_route_tangent_to_travel(route_tangent: Vector3, travel_heading: Vector3) -> Vector3:
	var route := horizontal_heading(route_tangent)
	var travel := horizontal_heading(travel_heading)
	if route.is_zero_approx() or travel.is_zero_approx():
		return route
	return -route if route.dot(travel) < 0.0 else route

static func alignment_metrics(camera_forward: Vector3, travel_heading: Vector3,
		route_tangent: Vector3) -> Dictionary:
	var camera := horizontal_heading(camera_forward)
	var travel := horizontal_heading(travel_heading)
	var route := horizontal_heading(route_tangent)
	return {
		"camera_travel_dot": camera.dot(travel) if not camera.is_zero_approx() and not travel.is_zero_approx() else null,
		"camera_route_dot": camera.dot(route) if not camera.is_zero_approx() and not route.is_zero_approx() else null,
		"travel_route_dot": travel.dot(route) if not travel.is_zero_approx() and not route.is_zero_approx() else null,
	}

static func alignment_is_eligible(metrics: Dictionary) -> bool:
	for key: String in ["camera_travel_dot", "camera_route_dot", "travel_route_dot"]:
		if metrics.get(key) == null or float(metrics[key]) <= HEADING_ALIGNMENT_DOT:
			return false
	return true

static func is_road_failure(visible_count: int, alignment_eligible: bool) -> bool:
	return alignment_eligible and visible_count < ROAD.REQUIRED_VISIBLE

static func nearest_route(at: Vector3, routes: Array) -> Dictionary:
	var best := {"classification":"nearest_only_not_membership", "id":"", "distance_m":INF,
		"along_m":0.0, "tangent":Vector3.ZERO}
	var here := Vector2(at.x, at.z)
	for route: Dictionary in routes:
		var walked := 0.0
		var points: Array = route.points
		for index in range(1, points.size()):
			var start := Vector2(points[index-1].x, points[index-1].z)
			var end := Vector2(points[index].x, points[index].z)
			var segment := end-start
			var length := segment.length()
			if length <= 0: continue
			var t := clampf((here-start).dot(segment) / segment.length_squared(), 0, 1)
			var distance := here.distance_to(start+segment*t)
			if distance < float(best.distance_m):
				best.id = str(route.id)
				best.distance_m = distance
				best.along_m = walked+length*t
				best.tangent = Vector3(segment.x, 0.0, segment.y).normalized()
			walked += length
	if str(best.id).is_empty(): best.distance_m = null
	return best

func _routes(realm: String) -> Array:
	if _routes_cache.has(realm): return _routes_cache[realm]
	var routes := []
	if realm == "meadows":
		for row: Dictionary in ROAD._json(ROAD.MEADOWS_TERRAIN).get("trail", {}).get("bands", []):
			routes.append({"id":str(row.id), "points":ROAD._points_xz(row.get("points", []))})
	elif realm == "cloudreach":
		for row: Dictionary in ROAD._json(ROAD.CLOUDREACH_WORLD).get("routes", []):
			if ROAD.CLOUDREACH_MAIN_ROUTE_IDS.has(str(row.id)):
				routes.append({"id":str(row.id), "points":ROAD._points_cloudreach(row.get("polyline", []))})
	elif realm == "stormwood":
		for row: Dictionary in ROAD._json(ROAD.STORMWOOD_WORLD).get("routes", []):
			if str(row.get("kind", "")) == "critical":
				routes.append({"id":str(row.id), "points":ROAD._points_xz(row.get("points", []))})
	elif realm == "water":
		var data: Dictionary = ROAD._json(ROAD.WATER_WORLD)
		for group: String in ["land_routes", "water_routes"]:
			for row: Dictionary in data.get(group, []):
				if bool(row.get("main_path", false)):
					routes.append({"id":str(row.id), "points":ROAD._points_cloudreach(row.get("polyline", []))})
	_routes_cache[realm] = routes
	return routes

func _write(record: Dictionary) -> void:
	_file.store_line(JSON.stringify(record))
	_file.flush()
	if _file.get_error() != OK and not failures.has("Coverage evidence write failed"):
		failures.append("Coverage evidence write failed")

static func _v(value: Vector3) -> Array:
	return [value.x,value.y,value.z]
