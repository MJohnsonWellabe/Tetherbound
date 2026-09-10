extends SceneTree

## One production-world proof for Gull Rest's signal site. The canonical pair
## reproduces stand 19's authored destination and retained catalogue heading.
## The supplemental proof starts at the preceding authored waypoint and uses
## only ordinary left-stick travel across both adjacent route legs.

const WATER_SCENE := preload("res://scenes/world/water_archipelago.tscn")
const NAVIGATOR := preload("res://tests/helpers/stick_navigator.gd")
const BUILD_TIMEOUT_MSEC := 900000
const OUTPUT_DEFAULT := "res://shots/catalogue/water/gull-rest-signal-site-0909"
const LANDMARK_XZ := Vector2(-72.615, 899.886)
const SITE_XZ := Vector2(-70.0, 881.5)
const PREVIOUS_XZ := Vector2(-123.694, 839.0)
const NEXT_XZ := Vector2(-33.865, 921.607)
const CANONICAL_FORWARD := Vector2(0.1410574, -0.9900014)
const TRAINER_CLEARANCE := 0.08

var _output := OUTPUT_DEFAULT
var _failures: Array[String] = []
var _records: Array[Dictionary] = []
var _world: Node3D
var _player: CharacterBody3D
var _rig: SpringArm3D
var _camera: Camera3D
var _look: Node
var _site: Node3D


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	if DisplayServer.get_name() == "headless":
		_fail("capture requires a rendering display")
		_finish({})
		return
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--output="):
			var requested_output := argument.trim_prefix("--output=")
			if not requested_output.is_empty():
				_output = requested_output
	var absolute := ProjectSettings.globalize_path(_output)
	DirAccess.make_dir_recursive_absolute(absolute)
	if FileAccess.file_exists(absolute.path_join("manifest.json")):
		_fail("output already contains a manifest")
		_finish({})
		return
	var game := root.get_node_or_null(^"Game")
	if game == null:
		_fail("Game autoload is missing")
		_finish({})
		return
	game.call("reset_for_new_game")
	game.set("current_realm", "water")
	_world = WATER_SCENE.instantiate() as Node3D
	root.add_child(_world)
	current_scene = _world
	var deadline := Time.get_ticks_msec() + BUILD_TIMEOUT_MSEC
	while _world.has_method("shell_build_complete") and not bool(_world.call("shell_build_complete")):
		if Time.get_ticks_msec() > deadline:
			_fail("production Water shell timed out")
			_finish({})
			return
		await process_frame
	_player = _world.get_node_or_null(^"Player") as CharacterBody3D
	_rig = _world.get_node_or_null(^"CameraRig") as SpringArm3D
	_camera = _world.get_node_or_null(^"CameraRig/Camera3D") as Camera3D
	_look = _world.get_node_or_null(^"WorldLook")
	_site = _world.get_node_or_null(^"GullRestSignalSpire") as Node3D
	if _player == null or _rig == null or _camera == null or _look == null or _site == null:
		_fail("production player/camera/look/signal site is missing")
		_finish({})
		return
	_rig.set_process(true)
	_rig.set_physics_process(true)
	_camera.make_current()
	var terrain := _world.get_node_or_null(^"Terrain")
	if terrain != null and terrain.has_method("set_camera"):
		terrain.call("set_camera", _camera)
	for _frame in 45:
		await physics_frame

	var contact := _support_contact_evidence()
	if not bool(contact.get("complete", false)):
		_fail("one or more rendered supports do not contact their sampled terrain foot")

	# Exact stand-19 catalogue pose: authored landmark, retained route heading,
	# production spring arm, and the production time presets.
	if not await _place_catalogue_pose(game):
		_finish({"support_contact": contact})
		return
	for preset: String in ["day", "night"]:
		var observed := await _pin_time(preset)
		if observed.is_empty():
			continue
		await _capture("water__gull_rest__19__gull_rest_signal_spire__%s" % preset,
			"canonical", preset, observed)

	# Disclosed evidence reset only. From here onward the player/camera move via
	# production physics and ordinary input; the two full authored route legs
	# are traversed in sequence and no actor or landmark is repositioned.
	if not await _place_route_start(game):
		_finish({"support_contact": contact})
		return
	var navigator := NAVIGATOR.new(self, _player, _rig, Callable(self, "_drive_stick"))
	var approach_xz := PREVIOUS_XZ.lerp(LANDMARK_XZ, 0.70)
	var route_legs: Array[Dictionary] = []
	var leg_one_start := _player.global_position
	var reached_approach := await _walk(navigator, approach_xz, 1800)
	if reached_approach:
		var look_result := await _look_at_with_input(Vector3(SITE_XZ.x, _site.global_position.y + 3.0, SITE_XZ.y))
		if not bool(look_result.get("reached", false)):
			_fail("ordinary look input did not face the signal site")
		var banner_result := await _wait_for_banner()
		var observed_day := await _pin_time("day")
		if not observed_day.is_empty():
			await _capture("gull-rest-signal-spire-ordinary-incoming-day", "ordinary_input",
				"day", observed_day, {"look_input": look_result, "banner": banner_result})
	else:
		_fail("ordinary first route leg did not reach the incoming-view point")
	var reached_landmark := reached_approach and await _walk(navigator, LANDMARK_XZ, 1800)
	route_legs.append(_leg_record("previous_to_landmark", leg_one_start, LANDMARK_XZ,
		reached_approach and reached_landmark, navigator))
	if not reached_landmark:
		_fail("ordinary first adjacent route leg did not reach Gull Rest")
	var leg_two_start := _player.global_position
	var reached_next := reached_landmark and await _walk(navigator, NEXT_XZ, 1800)
	route_legs.append(_leg_record("landmark_to_next", leg_two_start, NEXT_XZ, reached_next, navigator))
	if not reached_next:
		_fail("ordinary second adjacent route leg did not reach its authored waypoint")

	var manifest_extra := {
		"support_contact": contact,
		"route_legs": route_legs,
		"site_position": _vec3(_site.global_position),
		"site_distance_from_landmark_m": SITE_XZ.distance_to(LANDMARK_XZ),
		"authored_content_clearance_m": {
			"water_gull_rest_wild_001": 23.275,
			"Rune": 32.066,
			"nearest_pickup_water_gull_rest_pickup_003": 41.931,
		},
		"fixture_disclosure": "Production Water scene and gameplay HUD. Canonical frames use stand 19's authored destination, retained heading and production camera/time presets. The supplemental route proof uses debug travel once to reach the preceding authored waypoint, then ordinary left-stick travel for both complete adjacent route legs and ordinary look input for its incoming view. No actor, pickup, signal, terrain, route, camera, encounter or progression transform is assigned.",
	}
	_finish(manifest_extra)


func _place_catalogue_pose(game: Node) -> bool:
	if not bool(game.call("debug_teleport_to", LANDMARK_XZ.x, LANDMARK_XZ.y, "water", "")):
		_fail("catalogue debug travel refused Gull Rest")
		return false
	for _frame in 8:
		await physics_frame
	var ground := float(_world.call("ground_height_at", LANDMARK_XZ.x, LANDMARK_XZ.y))
	if not is_finite(ground):
		_fail("Gull Rest catalogue ground is non-finite")
		return false
	_player.global_position = Vector3(LANDMARK_XZ.x, ground + TRAINER_CLEARANCE, LANDMARK_XZ.y)
	_player.velocity = Vector3.ZERO
	_player.rotation.y = atan2(CANONICAL_FORWARD.x, CANONICAL_FORWARD.y)
	_rig.call("set_target", _player)
	var yaw := atan2(-CANONICAL_FORWARD.x, -CANONICAL_FORWARD.y)
	var pitch := float(_rig.get("pitch"))
	_rig.set("yaw", yaw)
	_rig.rotation = Vector3(pitch, yaw, 0.0)
	_rig.global_position = _player.global_position
	_player.reset_physics_interpolation()
	_rig.reset_physics_interpolation()
	_camera.reset_physics_interpolation()
	for _frame in 30:
		await physics_frame
	return true


func _place_route_start(game: Node) -> bool:
	if not bool(game.call("debug_teleport_to", PREVIOUS_XZ.x, PREVIOUS_XZ.y, "water", "")):
		_fail("debug travel refused preceding route waypoint")
		return false
	for _frame in 8:
		await physics_frame
	var ground := float(_world.call("ground_height_at", PREVIOUS_XZ.x, PREVIOUS_XZ.y))
	if not is_finite(ground):
		_fail("preceding route waypoint ground is non-finite")
		return false
	_player.global_position = Vector3(PREVIOUS_XZ.x, ground + TRAINER_CLEARANCE, PREVIOUS_XZ.y)
	_player.velocity = Vector3.ZERO
	_rig.call("set_target", _player)
	_rig.global_position = _player.global_position
	_player.reset_physics_interpolation()
	_rig.reset_physics_interpolation()
	_camera.reset_physics_interpolation()
	for _frame in 24:
		await physics_frame
	return true


func _walk(navigator: RefCounted, target_xz: Vector2, budget: int) -> bool:
	var ground := float(_world.call("ground_height_at", target_xz.x, target_xz.y))
	var target := Vector3(target_xz.x, ground + 0.1 if is_finite(ground) else _player.global_position.y, target_xz.y)
	var reached: bool = bool(await navigator.walk_to(target, budget, 1.0))
	_drive_stick(0.0, 0.0)
	for _frame in 6:
		await physics_frame
	return reached


func _leg_record(label: String, start: Vector3, target_xz: Vector2, reached: bool,
		navigator: RefCounted) -> Dictionary:
	return {"label": label, "from": _vec3(start), "target_xz": [target_xz.x, target_xz.y],
		"to": _vec3(_player.global_position), "displacement_m": start.distance_to(_player.global_position),
		"reached": reached, "player_grounded": _player.is_on_floor(),
		"navigator_confined_resets": int(navigator.call("confined_resets"))}


func _pin_time(preset: String) -> Dictionary:
	if not _look.has_method("apply_time"):
		_fail("WorldLook/apply_time is missing")
		return {}
	_look.set_process(true)
	_look.set_physics_process(true)
	if _look.has_method("set_clock_frozen"):
		_look.call("set_clock_frozen", false)
	_look.call("apply_time", preset)
	for _frame in 12:
		await physics_frame
	if _look.has_method("set_clock_frozen"):
		_look.call("set_clock_frozen", true)
	_look.set_process(false)
	_look.set_physics_process(false)
	var observed := {"requested": preset}
	if _look.has_method("time_of_day"):
		observed["time_of_day"] = str(_look.call("time_of_day"))
		if str(observed.time_of_day) != preset:
			_fail("WorldLook reported %s for requested %s" % [str(observed.time_of_day), preset])
			return {}
	if _look.has_method("hour"):
		observed["hour"] = float(_look.call("hour"))
	return observed


func _capture(frame_id: String, movement: String, preset: String, observed: Dictionary,
		extra: Dictionary = {}) -> void:
	for _frame in 12:
		await process_frame
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	var path := "%s/%s.png" % [_output, frame_id]
	if image == null or image.is_empty() or image.get_width() != root.size.x or image.get_height() != root.size.y:
		_fail("%s viewport image is empty or wrong-sized" % frame_id)
		return
	if image.save_png(path) != OK:
		_fail("could not save %s" % frame_id)
		return
	var visibility := _site_visibility()
	if not bool(visibility.get("full_bounds_in_viewport", false)):
		_fail("%s does not contain the full rendered signal bounds" % frame_id)
	var record := {"frame_id": frame_id, "file": path, "time": preset,
		"observed_clock": observed, "movement": movement,
		"player_position": _vec3(_player.global_position), "player_grounded": _player.is_on_floor(),
		"camera_position": _vec3(_camera.global_position), "camera_transform": _transform(_camera.global_transform),
		"camera_fov": _camera.fov, "site_visibility": visibility,
		"bytes": FileAccess.get_file_as_bytes(path).size()}
	for key: Variant in extra:
		record[key] = extra[key]
	_records.append(record)
	print("GULL REST CAPTURE %s -> %s" % [frame_id, path])


func _site_visibility() -> Dictionary:
	var bounds := _rendered_world_bounds(_site)
	if bounds.size == Vector3.ZERO:
		return {"full_bounds_in_viewport": false, "reason": "no rendered bounds"}
	var viewport_size := Vector2(root.size)
	var min_screen := Vector2(INF, INF)
	var max_screen := Vector2(-INF, -INF)
	var all_front := true
	var all_inside := true
	for corner: Vector3 in _aabb_corners(bounds):
		if _camera.is_position_behind(corner):
			all_front = false
			all_inside = false
			continue
		var screen := _camera.unproject_position(corner)
		min_screen = min_screen.min(screen)
		max_screen = max_screen.max(screen)
		if screen.x < 0.0 or screen.y < 0.0 or screen.x > viewport_size.x or screen.y > viewport_size.y:
			all_inside = false
	return {"world_aabb_position": _vec3(bounds.position), "world_aabb_size": _vec3(bounds.size),
		"all_corners_in_front": all_front, "full_bounds_in_viewport": all_inside,
		"screen_rect_position": [min_screen.x, min_screen.y],
		"screen_rect_size": [max_screen.x - min_screen.x, max_screen.y - min_screen.y]}


func _support_contact_evidence() -> Dictionary:
	var records: Array[Dictionary] = []
	var complete := true
	for child: Node in _site.get_children():
		if child is Node3D and str(child.get_meta("signal_role", "")) == "terrain_support":
			var bounds := _rendered_world_bounds(child as Node3D)
			var foot := float(child.get_meta("terrain_foot_y", NAN))
			var platform := float(child.get_meta("platform_y", NAN))
			var bottom_delta := absf(bounds.position.y - foot)
			var top_delta := absf(bounds.end.y - platform)
			var valid := is_finite(foot) and is_finite(platform) and bottom_delta <= 0.015 and top_delta <= 0.015
			complete = complete and valid
			records.append({"node": str(_site.get_path_to(child)), "sampled_terrain_foot_y": foot,
				"rendered_bottom_y": bounds.position.y, "bottom_delta_m": bottom_delta,
				"platform_y": platform, "rendered_top_y": bounds.end.y, "top_delta_m": top_delta,
				"contact_valid": valid})
	return {"complete": complete and records.size() == 4, "support_count": records.size(), "supports": records}


func _rendered_world_bounds(from: Node3D) -> AABB:
	var result := AABB()
	var found := false
	var nodes: Array[Node] = [from]
	while not nodes.is_empty():
		var node: Node = nodes.pop_back()
		for child: Node in node.get_children():
			nodes.append(child)
		if node is MeshInstance3D and (node as MeshInstance3D).mesh != null:
			var mesh_node := node as MeshInstance3D
			for corner: Vector3 in _aabb_corners(mesh_node.get_aabb()):
				var world_point := mesh_node.global_transform * corner
				if not found:
					result = AABB(world_point, Vector3.ZERO)
					found = true
				else:
					result = result.expand(world_point)
	return result


func _aabb_corners(bounds: AABB) -> Array[Vector3]:
	var corners: Array[Vector3] = []
	for x: float in [bounds.position.x, bounds.end.x]:
		for y: float in [bounds.position.y, bounds.end.y]:
			for z: float in [bounds.position.z, bounds.end.z]:
				corners.append(Vector3(x, y, z))
	return corners


func _look_at_with_input(target: Vector3) -> Dictionary:
	var view := target - _player.global_position
	var desired := atan2(-view.x, -view.z)
	var start := float(_rig.get("yaw"))
	var frames := 0
	while absf(wrapf(desired - float(_rig.get("yaw")), -PI, PI)) > deg_to_rad(4.0) and frames < 180:
		var delta := wrapf(desired - float(_rig.get("yaw")), -PI, PI)
		var action: StringName = &"look_left" if delta > 0.0 else &"look_right"
		Input.action_press(action, 0.55)
		await physics_frame
		Input.action_release(&"look_left")
		Input.action_release(&"look_right")
		frames += 1
	for _frame in 12:
		await physics_frame
	return {"reached": absf(wrapf(desired - float(_rig.get("yaw")), -PI, PI)) <= deg_to_rad(5.0),
		"start_yaw_deg": rad_to_deg(start), "desired_yaw_deg": rad_to_deg(desired),
		"finish_yaw_deg": rad_to_deg(float(_rig.get("yaw"))), "physics_frames": frames}


func _wait_for_banner() -> Dictionary:
	var banner := _world.find_child("RegionBanner", true, false) as CanvasItem
	var frames := 0
	while banner != null and banner.visible and frames < 300:
		await physics_frame
		frames += 1
	if banner != null and banner.visible:
		_fail("region banner did not clear before ordinary capture")
	return {"found": banner != null, "visible_at_capture": banner != null and banner.visible, "wait_frames": frames}


func _drive_stick(x: float, y: float) -> void:
	_drive_axis(JOY_AXIS_LEFT_X, x)
	_drive_axis(JOY_AXIS_LEFT_Y, y)


func _drive_axis(axis: JoyAxis, value: float) -> void:
	var event := InputEventJoypadMotion.new()
	event.axis = axis
	event.axis_value = value
	Input.parse_input_event(event)


func _vec3(value: Vector3) -> Array[float]:
	return [value.x, value.y, value.z]


func _transform(value: Transform3D) -> Dictionary:
	return {"origin": _vec3(value.origin), "basis_x": _vec3(value.basis.x),
		"basis_y": _vec3(value.basis.y), "basis_z": _vec3(value.basis.z)}


func _fail(message: String) -> void:
	_failures.append(message)
	push_error("GULL REST SIGNAL SITE: %s" % message)


func _finish(extra: Dictionary) -> void:
	var absolute := ProjectSettings.globalize_path(_output)
	DirAccess.make_dir_recursive_absolute(absolute)
	var manifest := {"schema_version": 1, "scene": "res://scenes/world/water_archipelago.tscn",
		"display_server": DisplayServer.get_name(), "rendering_method": RenderingServer.get_current_rendering_method(),
		"production_camera": "CameraRig/Camera3D", "canonical_contract": {
			"destination_xz": [LANDMARK_XZ.x, LANDMARK_XZ.y],
			"view_heading_xz": [CANONICAL_FORWARD.x, CANONICAL_FORWARD.y], "fov": _camera.fov if _camera != null else NAN},
		"frames": _records, "failures": _failures, "complete": _failures.is_empty() and _records.size() == 3,
		"capture_finished_utc": Time.get_datetime_string_from_system(true)}
	for key: Variant in extra:
		manifest[key] = extra[key]
	var file := FileAccess.open(absolute.path_join("manifest.json"), FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(manifest, "\t") + "\n")
		file.close()
	else:
		push_error("Gull Rest signal capture could not write manifest")
	print("GULL REST SIGNAL SITE %s: %d/3 frames" % ["PASS" if bool(manifest.complete) else "FAIL", _records.size()])
	quit(0 if bool(manifest.complete) else 1)
