extends SceneTree

const WORLD_SCENE := preload("res://scenes/world/cloudreach_cliffs.tscn")
const NAVIGATOR := preload("res://tests/helpers/stick_navigator.gd")
const OUTPUT_DEFAULT := "res://shots/catalogue/cloudreach/round-windscar-open-beacon-20260909"
const ANCHOR := Vector2(-260.0, 2680.0)
const HEADING := Vector2(0.7568230, 0.6536199)
const SITE_CENTRE := ANCHOR + HEADING * 15.0
const APPROACH := ANCHOR - HEADING * 12.0
const CROWN_HEIGHT_BAND_M := 6.0

var _output := OUTPUT_DEFAULT
var _failures: Array[String] = []
var _frames: Array[Dictionary] = []
var _world: Node3D
var _player: CharacterBody3D
var _rig: SpringArm3D
var _camera: Camera3D
var _look: Node
var _site: Node3D


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--output="):
			var requested := argument.trim_prefix("--output=")
			if not requested.is_empty():
				_output = requested
	var absolute := ProjectSettings.globalize_path(_output)
	DirAccess.make_dir_recursive_absolute(absolute)
	if DisplayServer.get_name() == "headless" or FileAccess.file_exists(absolute.path_join("manifest.json")):
		_fail("capture requires a display and a unique output path")
		_finish({})
		return
	var game := root.get_node_or_null(^"Game")
	if game == null:
		_fail("Game autoload is missing")
		_finish({})
		return
	game.call("reset_for_new_game")
	game.set("current_realm", "cloudreach")
	_world = WORLD_SCENE.instantiate() as Node3D
	root.add_child(_world)
	current_scene = _world
	var deadline := Time.get_ticks_msec() + 900000
	while _world.has_method("shell_build_complete") and not bool(_world.call("shell_build_complete")):
		if Time.get_ticks_msec() > deadline:
			_fail("Cloudreach shell timed out")
			_finish({})
			return
		await process_frame
	_player = _world.get_node_or_null(^"Player") as CharacterBody3D
	_rig = _world.get_node_or_null(^"CameraRig") as SpringArm3D
	_camera = _world.get_node_or_null(^"CameraRig/Camera3D") as Camera3D
	_look = _world.get_node_or_null(^"WorldLook")
	_site = _world.find_child("OpenWindscarBeacon", true, false) as Node3D
	if _player == null or _rig == null or _camera == null or _look == null or _site == null:
		_fail("production player/camera/look/open beacon is missing")
		_finish({})
		return
	_rig.set_process(true)
	_rig.set_physics_process(true)
	_camera.make_current()
	for _frame in 45:
		await physics_frame
	var contact := _contact_evidence()
	if not bool(contact.get("complete", false)):
		_fail("production beacon feet do not match sampled terrain")

	# Exact retained stand05 destination, heading, production rig and FOV.
	if not await _place(game, ANCHOR, HEADING):
		_finish({"terrain_contact": contact})
		return
	for preset: String in ["day", "night"]:
		var observed := await _pin_time(preset)
		if not observed.is_empty():
			await _capture("cloudreach__windscar_ravine__05__windscar_beacon__%s" % preset,
				"canonical_stand05", observed, false)

	# Establish the ordinary view by walking from the verified canonical anchor
	# to a point inside the actual elliptical crown. The former pickup-court
	# corner was only inside the broad surface-index rectangle and had no physical
	# ledge beneath it.
	var navigator := NAVIGATOR.new(self, _player, _rig, Callable(self, "_drive_stick"))
	var travel: Array[Dictionary] = []
	var establish_start := _player.global_position
	var establish := await _walk(navigator, APPROACH, 900)
	travel.append(_leg("establish_grounded_approach", establish_start, APPROACH, establish, navigator))
	if not bool(establish.get("reached", false)):
		_fail("ordinary approach point was not reached on the physical crown")
		_finish({"terrain_contact": contact, "ordinary_travel": travel})
		return
	var view_target := Vector3(SITE_CENTRE.x, float(_site.call("frame_base_y")) + 12.8, SITE_CENTRE.y)
	var look_input := await _look_at_with_input(view_target)
	if not bool(look_input.get("reached", false)):
		_fail("ordinary look input did not frame the beacon")
	var banner := await _wait_banner()
	var day := await _pin_time("day")
	if not day.is_empty():
		await _capture("windscar-beacon-ordinary-full-silhouette-day", "ordinary_look_input",
			day, true, {"look_input": look_input, "banner": banner})

	var first_start := _player.global_position
	var reached_anchor := await _walk(navigator, ANCHOR, 900)
	travel.append(_leg("approach_to_anchor", first_start, ANCHOR, reached_anchor, navigator))
	if not bool(reached_anchor.get("reached", false)):
		_fail("ordinary approach did not reach the authored anchor")
		_finish({"terrain_contact": contact, "ordinary_travel": travel})
		return
	var exit_xz := SITE_CENTRE + HEADING * 4.0
	var second_start := _player.global_position
	var reached_exit := await _walk(navigator, exit_xz, 900)
	travel.append(_leg("through_aperture", second_start, exit_xz, reached_exit, navigator))
	if not bool(reached_exit.get("reached", false)):
		_fail("ordinary input did not cross the complete beacon aperture")
	_finish({"terrain_contact": contact, "ordinary_travel": travel,
		"fixture_disclosure": "Production Cloudreach scene/HUD. Canonical pair uses the exact retained stand05 anchor, heading, CameraRig/Camera3D, FOV and production day/night presets. Supplemental proof starts on that verified canonical anchor, then uses ordinary left-stick input to establish a grounded view 12 m back inside the physical crown, ordinary look input for the full silhouette, and ordinary left-stick input through the unchanged anchor and aperture. No actor, pickup, landmark, route, terrain, camera or progression transform is assigned."})


func _place(game: Node, at: Vector2, forward: Vector2) -> bool:
	if not bool(game.call("debug_teleport_to", at.x, at.y, "cloudreach", "")):
		_fail("debug travel refused %s" % at)
		return false
	for _frame in 8:
		await physics_frame
	var ground := float(_world.call("ground_height_at", at.x, at.y))
	if not is_finite(ground):
		_fail("capture position has no finite ground")
		return false
	_player.global_position = Vector3(at.x, ground + 0.08, at.y)
	_player.velocity = Vector3.ZERO
	_player.rotation.y = atan2(forward.x, forward.y)
	_rig.call("set_target", _player)
	var yaw := atan2(-forward.x, -forward.y)
	_rig.set("yaw", yaw)
	_rig.rotation = Vector3(float(_rig.get("pitch")), yaw, 0.0)
	_rig.global_position = _player.global_position
	_player.reset_physics_interpolation()
	_rig.reset_physics_interpolation()
	_camera.reset_physics_interpolation()
	for _frame in 30:
		await physics_frame
	var support := _support_state(at)
	if not bool(support.get("supported", false)):
		_fail("capture position did not settle grounded in the crown height band")
		return false
	return true


func _pin_time(preset: String) -> Dictionary:
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
			_fail("WorldLook time mismatch")
			return {}
	if _look.has_method("hour"):
		observed["hour"] = float(_look.call("hour"))
	return observed


func _capture(frame_id: String, mode: String, observed: Dictionary, require_full: bool,
		extra: Dictionary = {}) -> void:
	for _frame in 12:
		await process_frame
	await RenderingServer.frame_post_draw
	var visibility := _visibility()
	if require_full and not bool(visibility.get("full_bounds_in_viewport", false)):
		_fail("ordinary view does not contain the complete signal structure")
	var path := "%s/%s.png" % [_output, frame_id]
	var image := root.get_texture().get_image()
	if image == null or image.is_empty() or image.get_width() != 1280 or image.get_height() != 800:
		_fail("%s image is empty or wrong-sized" % frame_id)
		return
	if image.save_png(path) != OK or not FileAccess.file_exists(ProjectSettings.globalize_path(path)):
		_fail("%s PNG was not retained" % frame_id)
		return
	var record := {"frame_id": frame_id, "file": path, "mode": mode,
		"observed_clock": observed, "player_position": _vec3(_player.global_position),
		"player_grounded": _player.is_on_floor(), "camera_position": _vec3(_camera.global_position),
		"camera_transform": _transform(_camera.global_transform), "camera_fov": _camera.fov,
		"site_visibility": visibility, "bytes": FileAccess.get_file_as_bytes(path).size()}
	for key: Variant in extra:
		record[key] = extra[key]
	_frames.append(record)
	print("WINDSCAR BEACON CAPTURE %s -> %s" % [frame_id, path])


func _look_at_with_input(target: Vector3) -> Dictionary:
	var delta := target - _player.global_position
	var desired_yaw := atan2(-delta.x, -delta.z)
	var desired_pitch := atan2(delta.y, Vector2(delta.x, delta.z).length())
	var frames := 0
	while frames < 240:
		var yaw_gap := wrapf(desired_yaw - float(_rig.get("yaw")), -PI, PI)
		var pitch_gap := desired_pitch - float(_rig.get("pitch"))
		if absf(yaw_gap) <= deg_to_rad(3.0) and absf(pitch_gap) <= deg_to_rad(3.0):
			break
		if absf(yaw_gap) > deg_to_rad(3.0):
			Input.action_press(&"look_left" if yaw_gap > 0.0 else &"look_right", 0.45)
		if absf(pitch_gap) > deg_to_rad(3.0):
			Input.action_press(&"look_up" if pitch_gap > 0.0 else &"look_down", 0.45)
		await physics_frame
		for action: StringName in [&"look_left", &"look_right", &"look_up", &"look_down"]:
			Input.action_release(action)
		frames += 1
	for _frame in 12:
		await physics_frame
	return {"reached": absf(wrapf(desired_yaw - float(_rig.get("yaw")), -PI, PI)) <= deg_to_rad(4.0)
		and absf(desired_pitch - float(_rig.get("pitch"))) <= deg_to_rad(4.0),
		"desired_yaw_deg": rad_to_deg(desired_yaw), "finish_yaw_deg": rad_to_deg(float(_rig.get("yaw"))),
		"desired_pitch_deg": rad_to_deg(desired_pitch), "finish_pitch_deg": rad_to_deg(float(_rig.get("pitch"))),
		"physics_frames": frames}


func _walk(navigator: RefCounted, target_xz: Vector2, budget: int) -> Dictionary:
	var ground := float(_world.call("ground_height_at", target_xz.x, target_xz.y,
		float(_site.call("frame_base_y"))))
	if not is_finite(ground):
		return {"reached": false, "navigator_reached": false, "supported": false,
			"target_ground_y": ground, "reason": "non-finite target ground"}
	var target := Vector3(target_xz.x, ground + 0.1, target_xz.y)
	var navigator_reached: bool = bool(await navigator.walk_to(target, budget, 0.9))
	_drive_stick(0.0, 0.0)
	for _frame in 6:
		await physics_frame
	var result := _support_state(target_xz)
	result["navigator_reached"] = navigator_reached
	result["target_ground_y"] = ground
	result["reached"] = navigator_reached and bool(result.get("supported", false))
	return result


func _leg(label: String, start: Vector3, target: Vector2, outcome: Dictionary,
		navigator: RefCounted) -> Dictionary:
	var record := {"label": label, "from": _vec3(start), "target_xz": [target.x, target.y],
		"to": _vec3(_player.global_position), "displacement_m": start.distance_to(_player.global_position),
		"reached": bool(outcome.get("reached", false)), "player_grounded": _player.is_on_floor(),
		"confined_resets": int(navigator.call("confined_resets"))}
	for key: Variant in outcome:
		record[key] = outcome[key]
	return record


func _support_state(target_xz: Vector2) -> Dictionary:
	var base_y := float(_site.call("frame_base_y"))
	var xz_error := Vector2(_player.global_position.x, _player.global_position.z).distance_to(target_xz)
	var height_delta := absf(_player.global_position.y - base_y)
	var grounded := _player.is_on_floor()
	return {"supported": grounded and xz_error <= 1.25 and height_delta <= CROWN_HEIGHT_BAND_M,
		"grounded": grounded, "xz_error_m": xz_error, "crown_height_delta_m": height_delta,
		"crown_base_y": base_y}


func _contact_evidence() -> Dictionary:
	var records: Array[Dictionary] = []
	var complete := true
	for child: Node in _site.get_children():
		if child is MeshInstance3D and str(child.get_meta("beacon_role", "")) == "terrain_foundation":
			var mesh := child as MeshInstance3D
			var bottom := mesh.global_position.y - (mesh.mesh as BoxMesh).size.y * 0.5
			var expected := float(mesh.get_meta("sampled_ground_y")) - 0.35
			var delta := absf(bottom - expected)
			complete = complete and delta <= 0.001
			records.append({"node": str(_site.get_path_to(mesh)), "rendered_bottom_y": bottom,
				"expected_socket_bottom_y": expected, "contact_delta_m": delta})
	return {"complete": complete and records.size() == 4, "feet": records}


func _visibility() -> Dictionary:
	var bounds := _world_bounds(_site)
	var min_screen := Vector2(INF, INF)
	var max_screen := Vector2(-INF, -INF)
	var inside := true
	for corner: Vector3 in _corners(bounds):
		if _camera.is_position_behind(corner):
			inside = false
			continue
		var screen := _camera.unproject_position(corner)
		min_screen = min_screen.min(screen)
		max_screen = max_screen.max(screen)
		inside = inside and screen.x >= 0.0 and screen.y >= 0.0 and screen.x <= 1280.0 and screen.y <= 800.0
	return {"world_aabb_position": _vec3(bounds.position), "world_aabb_size": _vec3(bounds.size),
		"screen_rect_position": [min_screen.x, min_screen.y],
		"screen_rect_size": [max_screen.x - min_screen.x, max_screen.y - min_screen.y],
		"full_bounds_in_viewport": inside}


func _world_bounds(from: Node3D) -> AABB:
	var result := AABB()
	var found := false
	var pending: Array[Node] = [from]
	while not pending.is_empty():
		var node: Node = pending.pop_back()
		for child: Node in node.get_children():
			pending.append(child)
		if node is MeshInstance3D and (node as MeshInstance3D).mesh != null:
			var mesh := node as MeshInstance3D
			for corner: Vector3 in _corners(mesh.get_aabb()):
				var point := mesh.global_transform * corner
				if not found:
					result = AABB(point, Vector3.ZERO)
					found = true
				else:
					result = result.expand(point)
	return result


func _corners(bounds: AABB) -> Array[Vector3]:
	var result: Array[Vector3] = []
	for x: float in [bounds.position.x, bounds.end.x]:
		for y: float in [bounds.position.y, bounds.end.y]:
			for z: float in [bounds.position.z, bounds.end.z]:
				result.append(Vector3(x, y, z))
	return result


func _wait_banner() -> Dictionary:
	var banner := _world.find_child("RegionBanner", true, false) as CanvasItem
	var frames := 0
	while banner != null and banner.visible and frames < 300:
		await physics_frame
		frames += 1
	if banner != null and banner.visible:
		_fail("region banner remained visible")
	return {"found": banner != null, "visible": banner != null and banner.visible, "wait_frames": frames}


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
	push_error("WINDSCAR OPEN BEACON: %s" % message)


func _finish(extra: Dictionary) -> void:
	var absolute := ProjectSettings.globalize_path(_output)
	DirAccess.make_dir_recursive_absolute(absolute)
	var manifest := {"schema_version": 1, "scene": "res://scenes/world/cloudreach_cliffs.tscn",
		"display_server": DisplayServer.get_name(), "rendering_method": RenderingServer.get_current_rendering_method(),
		"canonical_anchor_xz": [ANCHOR.x, ANCHOR.y], "canonical_heading_xz": [HEADING.x, HEADING.y],
		"site_centre_xz": [SITE_CENTRE.x, SITE_CENTRE.y], "frames": _frames,
		"failures": _failures, "complete": _failures.is_empty() and _frames.size() == 3,
		"capture_finished_utc": Time.get_datetime_string_from_system(true)}
	for key: Variant in extra:
		manifest[key] = extra[key]
	var manifest_path := absolute.path_join("manifest.json")
	var file := FileAccess.open(manifest_path, FileAccess.WRITE)
	if file == null:
		push_error("Windscar capture manifest could not be opened")
		quit(1)
		return
	file.store_string(JSON.stringify(manifest, "\t") + "\n")
	file.close()
	var retained := FileAccess.file_exists(manifest_path)
	print("WINDSCAR OPEN BEACON %s: %d/3 frames manifest=%s" % [
		"PASS" if bool(manifest.complete) and retained else "FAIL", _frames.size(), retained])
	quit(0 if bool(manifest.complete) and retained else 1)
