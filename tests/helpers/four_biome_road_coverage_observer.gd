extends RefCounted

## Optional NEXT-run instrumentation. Reads live state only; never drives play.
## Nearest-route metadata is not road membership or complete-route coverage.
const ROAD := preload("res://tools/gate_f/road_creature_visibility_model.gd")
const INPUT_OWNER := preload("res://scripts/ui/input_owner.gd")
var failures: Array[String] = []
var _tree: SceneTree
var _file: FileAccess
var _outdoor: Callable
var _routes_cache := {}
var _scene_id := 0
var _previous := Vector3.INF
var _since_sample := 0.0
var _travelled := 0.0
var _samples := 0
var _below_two := 0
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
		"route_classifier":"nearest_authored_polyline_only", "complete_coverage":false,
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
		"observed_travel_m":_travelled, "undersampled_intervals":_undersampled_intervals,
		"complete_coverage":false, "failures":failures.duplicate(),
		"caveat":"Counts describe observed travel only; unknown indoor/road membership and unvisited routes remain unproved"}

func _observe() -> void:
	var scene := _tree.current_scene as Node3D
	var game := _tree.root.get_node_or_null("Game")
	if scene == null or game == null:
		_previous = Vector3.INF
		return
	var player := scene.get_node_or_null("Player") as CharacterBody3D
	var director := scene.get_node_or_null("EncounterDirector")
	var camera := scene.get_viewport().get_camera_3d()
	var realm := str(game.get("current_realm"))
	if player == null or director == null or camera == null or not director.has_method("wild_creatures"):
		_previous = Vector3.INF
		return
	if _scene_id != scene.get_instance_id():
		_scene_id = scene.get_instance_id()
		_previous = Vector3.INF
		_since_sample = 0
		_write({"kind":"scene_boundary", "realm":realm, "scene":str(scene.scene_file_path), "scene_id":_scene_id})
	var manager := scene.get_node_or_null("CombatManager")
	if _tree.paused or INPUT_OWNER.current(_tree) != null \
			or (manager != null and manager.has_method("is_fighting") and manager.is_fighting()):
		_previous = Vector3.INF
		_since_sample = 0
		return
	var context := "unknown"
	if _outdoor.is_valid():
		context = "outdoor" if bool(_outdoor.call(scene, player)) else "indoor"
	else:
		var cave := scene.get_node_or_null("WaterVeilfall")
		if cave != null and cave.contains_interior(player.global_position):
			context = "indoor"
	if context == "indoor":
		_previous = Vector3.INF
		_since_sample = 0
		return
	var at := player.global_position
	if not at.is_finite():
		_previous = Vector3.INF
		return
	if not _previous.is_finite():
		_previous = at
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
	var bodies: Array[Dictionary] = []
	var accepted := 0
	var forward := -camera.global_basis.z
	var viewport := camera.get_viewport().get_visible_rect().size
	for candidate in director.wild_creatures():
		var body := candidate as Node3D
		if not eligible_body(body):
			continue
		var observation := _body_sample(body, player, camera, at, forward, viewport)
		bodies.append(observation)
		if bool(observation.credited): accepted += 1
	_samples += 1
	if accepted < ROAD.REQUIRED_VISIBLE: _below_two += 1
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
		"unobserved_sample_intervals":skipped, "nearest_route":nearest_route(at, _routes(realm)),
		"visible_forward_count":accepted, "below_two":accepted < ROAD.REQUIRED_VISIBLE, "bodies":bodies})

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

static func nearest_route(at: Vector3, routes: Array) -> Dictionary:
	var best := {"classification":"nearest_only_not_membership", "id":"", "distance_m":INF, "along_m":0.0}
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
