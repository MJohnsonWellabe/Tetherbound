extends SceneTree

## Dedicated production receipt for the bridge-aligned Three Bells signal.

const WORLD_SCENE := preload("res://scenes/world/cloudreach_cliffs.tscn")
const DEFAULT_OUTPUT := "res://shots/locations/cloudreach-three-bells-bridge"
const BELL_CENTRE := Vector3(-485.0, 338.0, 1320.0)
const STANDS := [
	{"id": "west-approach", "position": Vector2(-535.0, 1274.5), "target": BELL_CENTRE + Vector3(8.0, 7.0, 0.0)},
	{"id": "east-landing", "position": Vector2(-454.0, 1357.0), "target": BELL_CENTRE + Vector3(8.0, 7.0, 0.0)},
]

var _output := DEFAULT_OUTPUT
var _world: Node3D
var _player: CharacterBody3D
var _rig: SpringArm3D
var _camera: Camera3D
var _look: Node
var _presentation: Node3D
var _records: Array[Dictionary] = []
var _failures: Array[String] = []


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--output="):
			var requested := argument.trim_prefix("--output=").strip_edges()
			if not requested.is_empty():
				_output = requested
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
	_rig = _world.get_node_or_null(^"CameraRig") as SpringArm3D
	_camera = _world.get_node_or_null(^"CameraRig/Camera3D") as Camera3D
	_look = _world.get_node_or_null(^"WorldLook")
	_presentation = _world.find_child("ThreeBellsBridgePresentation", true, false) as Node3D
	if _player == null or _rig == null or _camera == null or _look == null or _presentation == null:
		_fail("production player, camera, look, or Three Bells presentation is missing")
		_finish()
		return
	_camera.make_current()
	_rig.set_process(false)
	_rig.set_physics_process(false)
	root.size = Vector2i(1280, 800)
	for stand: Dictionary in STANDS:
		if not await _pose(stand.position as Vector2, stand.target as Vector3):
			continue
		for time_name: String in ["day", "night"]:
			var observed := await _pin_time(time_name)
			if not observed.is_empty():
				await _capture("three-bells-%s-%s" % [str(stand.id), time_name], str(stand.id), observed)
	_finish()


func _pose(at: Vector2, target: Vector3) -> bool:
	var ground := float(_world.call("ground_height_at", at.x, at.y))
	if not is_finite(ground):
		_fail("stand %s has no production ground" % at)
		return false
	_player.global_position = Vector3(at.x, ground + 0.10, at.y)
	_player.velocity = Vector3.ZERO
	var sightline := target - _player.global_position
	var flat := Vector3(sightline.x, 0.0, sightline.z)
	var model := _player.get_node_or_null(^"Model") as Node3D
	if model != null:
		model.global_rotation.y = atan2(-flat.x, -flat.z)
	_rig.global_position = _player.global_position + Vector3.UP * 1.55
	var pitch := clampf(atan2(sightline.y, Vector2(sightline.x, sightline.z).length()), deg_to_rad(2.0), deg_to_rad(17.0))
	_rig.rotation = Vector3(pitch, atan2(-sightline.x, -sightline.z), 0.0)
	_player.reset_physics_interpolation()
	_rig.reset_physics_interpolation()
	_camera.reset_physics_interpolation()
	for _frame in 24:
		await physics_frame
	return _player.global_position.distance_to(Vector3(at.x, _player.global_position.y, at.y)) <= 0.6


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
	var bell_read := _bell_visibility()
	if int(bell_read.get("visible_centres", 0)) != 3:
		_fail("%s does not retain all three bell centres" % frame_id)
	var image := root.get_texture().get_image()
	var path := "%s/%s.png" % [_output, frame_id]
	if image == null or image.is_empty() or image.get_width() != 1280 or image.get_height() != 800:
		_fail("%s produced an empty or wrong-sized frame" % frame_id)
		return
	if image.save_png(path) != OK:
		_fail("%s could not be retained" % frame_id)
		return
	_records.append({"frame_id": frame_id, "file": path, "stand_id": stand_id,
		"observed_clock": observed, "player_position": _vec3(_player.global_position),
		"camera_position": _vec3(_camera.global_position), "camera_fov": _camera.fov,
		"bell_visibility": bell_read, "bytes": FileAccess.get_file_as_bytes(path).size()})
	print("THREE BELLS CAPTURE %s -> %s" % [frame_id, path])


func _bell_visibility() -> Dictionary:
	var positions: Array = []
	var visible := 0
	for value: Node in _presentation.find_children("SkyBell*", "Node3D", true, false):
		var bell := value as Node3D
		var centre := bell.global_position - Vector3.UP * 1.1
		var behind := _camera.is_position_behind(centre)
		var screen := _camera.unproject_position(centre) if not behind else Vector2(-1.0, -1.0)
		var on_screen := not behind and screen.x >= 0.0 and screen.x <= 1280.0 and screen.y >= 0.0 and screen.y <= 800.0
		if on_screen:
			visible += 1
		positions.append({"name": bell.name, "screen": [screen.x, screen.y], "on_screen": on_screen})
	return {"bell_count": positions.size(), "visible_centres": visible, "bells": positions}


func _vec3(value: Vector3) -> Array[float]:
	return [value.x, value.y, value.z]


func _fail(message: String) -> void:
	_failures.append(message)
	push_error("THREE BELLS: %s" % message)


func _finish() -> void:
	var absolute := ProjectSettings.globalize_path(_output)
	DirAccess.make_dir_recursive_absolute(absolute)
	var complete := _failures.is_empty() and _records.size() == STANDS.size() * 2
	var manifest := {"schema_version": 1, "scene": "res://scenes/world/cloudreach_cliffs.tscn",
		"fixture_disclosure": "Production Cloudreach world, player, HUD, CameraRig, bridge, terrain and WorldLook. Only the audit clock is frozen; no traversal, landmark, actor, route, FOV or progression transform is changed for capture.",
		"resolution": [root.size.x, root.size.y], "records": _records, "failures": _failures,
		"complete": complete, "capture_finished_utc": Time.get_datetime_string_from_system(true)}
	var file := FileAccess.open(absolute.path_join("manifest.json"), FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(manifest, "\t") + "\n")
		file.close()
	print("THREE BELLS CAPTURE %s: %d/%d" % ["OK" if complete else "FAIL", _records.size(), STANDS.size() * 2])
	quit(0 if complete else 1)
