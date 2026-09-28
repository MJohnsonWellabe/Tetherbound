extends SceneTree

const WORLD_SCENE := preload("res://scenes/world/cloudreach_cliffs.tscn")
const DEFAULT_OUTPUT := "res://ralph/reports/VISUAL/phase2/cloudreach/arch_targeted_main"
const STANDS := [
	{"id": "east-reveal", "position": Vector2(365.0, 1925.0), "camera_back_m": 7.0, "camera_lateral_m": 0.0},
	{"id": "east-profile", "position": Vector2(365.0, 1925.0), "camera_back_m": 3.0, "camera_lateral_m": -8.0},
]

var _output := DEFAULT_OUTPUT
var _world: Node3D
var _player: CharacterBody3D
var _camera: Camera3D
var _look: Node
var _presentation: Node3D
var _records: Array[Dictionary] = []
var _failures: Array[String] = []
var _seed := 2042


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--output="):
			var requested := argument.trim_prefix("--output=").strip_edges()
			if not requested.is_empty():
				_output = requested
		elif argument.begins_with("--seed="):
			_seed = int(argument.trim_prefix("--seed="))
	if not _output.begins_with("res://ralph/reports/VISUAL/phase2/cloudreach/"):
		_fail("output must stay under Cloudreach Phase 2 evidence")
		_finish()
		return
	seed(_seed)
	if DisplayServer.get_name() == "headless":
		_fail("capture requires a rendering display")
		_finish()
		return
	var absolute := ProjectSettings.globalize_path(_output)
	if FileAccess.file_exists(absolute.path_join("manifest.json")):
		_fail("capture output must be fresh")
		_finish()
		return
	DirAccess.make_dir_recursive_absolute(absolute)
	var game := root.get_node_or_null(^"Game")
	if game == null:
		_fail("Game autoload is missing")
		_finish()
		return
	game.call("reset_for_new_game")
	game.set("current_realm", "cloudreach")
	_world = WORLD_SCENE.instantiate() as Node3D
	root.add_child(_world)
	current_scene = _world
	var deadline := Time.get_ticks_msec() + 900000
	while _world.has_method("shell_build_complete") and not bool(_world.call("shell_build_complete")):
		if Time.get_ticks_msec() > deadline:
			_fail("Cloudreach production world timed out")
			_finish()
			return
		await process_frame
	for _frame in 24:
		await physics_frame
	_player = _world.get_node_or_null(^"Player") as CharacterBody3D
	_look = _world.get_node_or_null(^"WorldLook")
	_presentation = _world.find_child("BrokenSkyroadArchPresentation", true, false) as Node3D
	if _player == null or _look == null or _presentation == null:
		_fail("production player, look, or Broken Skyroad Arch presentation is missing")
		_finish()
		return
	var production_rig := _world.get_node_or_null(^"CameraRig") as SpringArm3D
	if production_rig != null:
		production_rig.set_process(false)
		production_rig.set_physics_process(false)
	_camera = _world.get_node_or_null(^"CameraRig/Camera3D") as Camera3D
	if _camera == null:
		_fail("production CameraRig/Camera3D is missing")
		_finish()
		return
	_camera.make_current()
	_player.process_mode = Node.PROCESS_MODE_DISABLED
	_player.velocity = Vector3.ZERO
	_hide_overlays()
	root.size = Vector2i(1920, 1080)
	for stand: Dictionary in STANDS:
		if not await _pose(stand):
			continue
		for time_name: String in ["day", "golden", "night"]:
			var observed := await _pin_time(time_name)
			if not observed.is_empty():
				var view := "approach" if str(stand.id) == "east-reveal" else "close"
				await _capture("cloudreach__broken_causeways__04__broken_skyroad_arch__%s__%s" % [time_name, view], str(stand.id), observed)
	_finish()


func _pose(stand: Dictionary) -> bool:
	var at := stand.position as Vector2
	var ground := _surface(at)
	if not is_finite(ground):
		_fail("stand %s has no production ground" % at)
		return false
	_player.global_position = Vector3(at.x, ground + 0.22, at.y)
	_player.velocity = Vector3.ZERO
	var target := _gateway_centre()
	var sightline := target - _player.global_position
	var flat := Vector3(sightline.x, 0.0, sightline.z)
	var model := _player.get_node_or_null(^"Model") as Node3D
	if model != null:
		model.global_rotation.y = atan2(-flat.x, -flat.z)
	var toward := Vector2(sightline.x, sightline.z).normalized()
	var right := Vector2(-toward.y, toward.x)
	var camera_xz := at - toward * float(stand.get("camera_back_m", 7.0)) \
		+ right * float(stand.get("camera_lateral_m", 0.0))
	# The valid east stand sits on a crown-edge shelf; camera shoulders beyond
	# it are open sky, not additional terrain samples. Anchor the evidence camera
	# to the verified player shelf instead of rejecting that intentional reveal.
	_camera.global_position = Vector3(camera_xz.x, ground + 2.35, camera_xz.y)
	_camera.look_at(target, Vector3.UP)
	_player.reset_physics_interpolation()
	_camera.reset_physics_interpolation()
	_hide_overlays()
	for _frame in 12:
		await process_frame
	return _player.global_position.distance_to(Vector3(at.x, ground + 0.22, at.y)) <= 0.1


func _pin_time(time_name: String) -> Dictionary:
	_look.set_process(true)
	_look.set_physics_process(true)
	if _look.has_method("set_clock_frozen"):
		_look.call("set_clock_frozen", false)
	_look.call("apply_time", time_name)
	for _frame in 12:
		await physics_frame
	if _look.has_method("set_clock_frozen"):
		_look.call("set_clock_frozen", true)
	_look.set_process(false)
	_look.set_physics_process(false)
	var result := {"requested": time_name}
	if _look.has_method("time_of_day"):
		result["time_of_day"] = str(_look.call("time_of_day"))
		if str(result.time_of_day) != time_name:
			_fail("WorldLook time mismatch for %s" % time_name)
			return {}
	if _look.has_method("hour"):
		result["hour"] = float(_look.call("hour"))
	return result


func _capture(frame_id: String, stand_id: String, observed: Dictionary) -> void:
	for _frame in 12:
		await process_frame
	await RenderingServer.frame_post_draw
	var gateway := _presentation.get_node_or_null(^"InstalledSkyroadGateway") as MeshInstance3D
	var centre := _gateway_centre()
	var behind := gateway == null or _camera.is_position_behind(centre)
	var screen := _camera.unproject_position(centre) if not behind else Vector2(-1.0, -1.0)
	var gateway_visible := not behind and screen.x >= 0.0 and screen.x <= float(root.size.x) and screen.y >= 0.0 and screen.y <= float(root.size.y)
	if not gateway_visible:
		_fail("%s loses the installed gateway centre" % frame_id)
	var image := root.get_texture().get_image()
	var path := "%s/%s.jpg" % [_output, frame_id]
	if image == null or image.is_empty() or image.get_width() != root.size.x or image.get_height() != root.size.y:
		_fail("%s produced an empty or wrong-sized frame" % frame_id)
		return
	if image.save_jpg(path, 0.87) != OK:
		_fail("%s could not be retained" % frame_id)
		return
	_records.append({"frame_id": frame_id, "file": path, "stand_id": stand_id,
		"identity": "cloudreach__broken_causeways__04__broken_skyroad_arch",
		"destination_display_name": "Broken Skyroad Arch",
		"time": str(observed.requested),
		"view": "approach" if stand_id == "east-reveal" else "close",
		"route_class": "main",
		"observed_clock": observed, "player_position": _vec3(_player.global_position),
		"camera_position": _vec3(_camera.global_position), "camera_fov": _camera.fov,
		"gateway_centre_screen": [screen.x, screen.y], "gateway_visible": gateway_visible,
		"presentation_children": _presentation.get_child_count(), "bytes": FileAccess.get_file_as_bytes(path).size()})
	print("BROKEN SKYROAD ARCH CAPTURE %s -> %s" % [frame_id, path])


func _vec3(value: Vector3) -> Array[float]:
	return [value.x, value.y, value.z]


func _gateway_centre() -> Vector3:
	var gateway := _presentation.get_node_or_null(^"InstalledSkyroadGateway") as MeshInstance3D
	return gateway.global_transform * gateway.get_aabb().get_center() if gateway != null else Vector3.ZERO


func _surface(at: Vector2) -> float:
	var analytic := float(_world.call("ground_height_at", at.x, at.y))
	if not is_finite(analytic):
		return analytic
	var query := PhysicsRayQueryParameters3D.create(
		Vector3(at.x, analytic + 100.0, at.y), Vector3(at.x, analytic - 100.0, at.y))
	query.collide_with_areas = false
	query.exclude = [_player.get_rid()]
	var hit := _world.get_world_3d().direct_space_state.intersect_ray(query)
	return analytic if hit.is_empty() else float((hit.position as Vector3).y)


func _hide_overlays() -> void:
	for candidate: Node in root.find_children("*", "CanvasLayer", true, false):
		(candidate as CanvasLayer).visible = false


func _fail(message: String) -> void:
	_failures.append(message)
	push_error("BROKEN SKYROAD ARCH: %s" % message)


func _finish() -> void:
	var absolute := ProjectSettings.globalize_path(_output)
	DirAccess.make_dir_recursive_absolute(absolute)
	var complete := _failures.is_empty() and _records.size() == STANDS.size() * 3
	var manifest := {"schema_version": 1, "biome_id": "cloudreach", "scene": "res://scenes/world/cloudreach_cliffs.tscn",
		"fixture_disclosure": "Production Cloudreach world, terrain, Broken Skyroad presentation, player, WorldLook and CameraRig/Camera3D. HUD is hidden and the player frozen at the authored crown-edge stand; the production camera is manually posed from that shelf to show the arch.",
		"seed": _seed, "display_server": DisplayServer.get_name(),
		"rendering_method": RenderingServer.get_current_rendering_method(),
		"resolution": [root.size.x, root.size.y], "frames": _records, "failures": _failures,
		"complete": complete, "capture_finished_utc": Time.get_datetime_string_from_system(true)}
	var file := FileAccess.open(absolute.path_join("manifest.json"), FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(manifest, "\t") + "\n")
		file.close()
	print("BROKEN SKYROAD ARCH CAPTURE %s: %d/%d" % ["OK" if complete else "FAIL", _records.size(), STANDS.size() * 3])
	quit(0 if complete else 1)
