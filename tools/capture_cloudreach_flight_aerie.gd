extends SceneTree

## Dedicated production evidence for Windscar Flight Aerie. The harness changes
## no lesson, route, actor, encounter, or landmark transform.

const WORLD_SCENE := preload("res://scenes/world/cloudreach_cliffs.tscn")
const DEFAULT_OUTPUT := "res://shots/locations/cloudreach-flight-aerie-r3"
const AERIE_CENTRE := Vector2(400.0, 3250.0)
const STANDS := [
	{"id": "ground-route-oblique", "position": Vector2(373.0, 3262.5357), "target": Vector2(403.0, 3248.0), "camera_back_m": 7.5, "camera_lateral_m": -4.5, "aim_up_m": 7.0},
	{"id": "lesson-floor-east-oblique", "position": Vector2(412.0, 3262.0), "target": Vector2(398.0, 3248.0), "camera_back_m": 5.5, "camera_lateral_m": 3.5, "aim_up_m": 7.5},
]

var _output := DEFAULT_OUTPUT
var _world: Node3D
var _player: CharacterBody3D
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
	_look = _world.get_node_or_null(^"WorldLook")
	_presentation = _world.find_child("FlightAeriePresentation", true, false) as Node3D
	if _player == null or _look == null or _presentation == null:
		_fail("production player, WorldLook, or Flight Aerie presentation is missing")
		_finish()
		return
	if _wildlife_within_aerie(20.0) != 0:
		_fail("wildlife remains on the flight-lesson dais")
	var production_rig := _world.get_node_or_null(^"CameraRig") as SpringArm3D
	if production_rig != null:
		production_rig.set_process(false)
		production_rig.set_physics_process(false)
	_camera = Camera3D.new()
	_camera.name = "FlightAerieEvidenceCamera"
	_camera.fov = 70.0
	_camera.far = 3000.0
	_world.add_child(_camera)
	_camera.make_current()
	_player.process_mode = Node.PROCESS_MODE_DISABLED
	_player.velocity = Vector3.ZERO
	_hide_overlays()
	root.size = Vector2i(1280, 720)
	for stand: Dictionary in STANDS:
		if not await _pose(stand):
			continue
		for time_name: String in ["day", "night"]:
			var observed := await _pin_time(time_name)
			if not observed.is_empty():
				await _capture("flight-aerie-%s-%s" % [str(stand.id), time_name], str(stand.id), observed)
	_finish()


func _pose(stand: Dictionary) -> bool:
	var at := stand.position as Vector2
	var target := stand.target as Vector2
	var ground := _surface(at)
	if not is_finite(ground):
		_fail("stand %s has no production ground" % at)
		return false
	_player.global_position = Vector3(at.x, ground + 0.22, at.y)
	_player.velocity = Vector3.ZERO
	var target_y := float(_world.call("ground_height_at", target.x, target.y))
	if not is_finite(target_y):
		_fail("target %s has no production ground" % target)
		return false
	var toward := (target - at).normalized()
	var right := Vector2(-toward.y, toward.x)
	var model := _player.get_node_or_null(^"Model") as Node3D
	if model != null:
		model.global_rotation.y = atan2(-toward.x, -toward.y)
	var camera_xz := at - toward * float(stand.get("camera_back_m", 5.2)) \
		+ right * float(stand.get("camera_lateral_m", 0.0))
	_camera.global_position = Vector3(camera_xz.x, ground + 2.65, camera_xz.y)
	_camera.look_at(Vector3(target.x, target_y + float(stand.get("aim_up_m", 2.5)), target.y), Vector3.UP)
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
	var observed := {"requested": time_name}
	if _look.has_method("time_of_day"):
		observed["time_of_day"] = str(_look.call("time_of_day"))
		if str(observed.time_of_day) != time_name:
			_fail("WorldLook time mismatch for %s" % time_name)
			return {}
	if _look.has_method("hour"):
		observed["hour"] = float(_look.call("hour"))
	return observed


func _capture(frame_id: String, stand_id: String, observed: Dictionary) -> void:
	for _frame in 12:
		await process_frame
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	var path := "%s/%s.png" % [_output, frame_id]
	if image == null or image.is_empty() or image.get_width() != 1280 or image.get_height() != 720:
		_fail("%s produced an empty or wrong-sized frame" % frame_id)
		return
	if image.save_png(path) != OK:
		_fail("%s could not be retained" % frame_id)
		return
	_records.append({"frame_id": frame_id, "file": path, "stand_id": stand_id,
		"observed_clock": observed, "player_position": _vec3(_player.global_position),
		"camera_position": _vec3(_camera.global_position), "camera_fov": _camera.fov,
		"wildlife_within_20m": _wildlife_within_aerie(20.0),
		"presentation_children": _presentation.get_child_count(),
		"bytes": FileAccess.get_file_as_bytes(path).size()})
	print("FLIGHT AERIE CAPTURE %s -> %s" % [frame_id, path])


func _wildlife_within_aerie(radius: float) -> int:
	var director := _world.get_node_or_null(^"EncounterDirector")
	if director == null or not director.has_method("wild_creatures"):
		return -1
	var count := 0
	for value: Variant in director.call("wild_creatures"):
		var body := value as Node3D
		if body != null and is_instance_valid(body):
			if Vector2(body.global_position.x, body.global_position.z).distance_to(AERIE_CENTRE) <= radius:
				count += 1
	return count


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


func _vec3(value: Vector3) -> Array[float]:
	return [value.x, value.y, value.z]


func _fail(message: String) -> void:
	_failures.append(message)
	push_error("FLIGHT AERIE: %s" % message)


func _finish() -> void:
	var absolute := ProjectSettings.globalize_path(_output)
	DirAccess.make_dir_recursive_absolute(absolute)
	var complete := _failures.is_empty() and _records.size() == STANDS.size() * 2
	var manifest := {"schema_version": 1, "scene": "res://scenes/world/cloudreach_cliffs.tscn",
		"named_location": "Windscar Flight Aerie",
		"fixture_disclosure": "Production Cloudreach world, terrain, encounters, mounted Flight Aerie presentation, player and WorldLook. HUD/modal overlays are hidden, player locomotion is frozen, and a fixed 70-degree evidence camera uses the authored ground-route arrival and lesson-floor shoulder. No progress, encounter, route, lesson, traversal or landmark transform is injected.",
		"resolution": [root.size.x, root.size.y], "records": _records, "failures": _failures,
		"complete": complete, "capture_finished_utc": Time.get_datetime_string_from_system(true)}
	var file := FileAccess.open(absolute.path_join("manifest.json"), FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(manifest, "\t") + "\n")
		file.close()
	print("FLIGHT AERIE CAPTURE %s: %d/%d" % ["OK" if complete else "FAIL", _records.size(), STANDS.size() * 2])
	quit(0 if complete else 1)
