extends SceneTree

## Actual Water scene frames. Run through tools/survey.sh --water on a real
## display. Teleported viewpoint fixtures are not continuous-play evidence.
const SCENE := "res://scenes/world/water_archipelago.tscn"
const OUT := "res://shots/water"
var _records: Array = []
var _failed: Array[String] = []
var _camera: Camera3D
var _world: Node3D
var _player: CharacterBody3D

func _init() -> void:
	call_deferred("_run")

func _wait_frames(count: int) -> void:
	for _frame in count:
		await process_frame

func _run() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("Water survey requires a rendering display, never --headless")
		quit(1)
		return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	# Remove only this tool's known outputs so stale files cannot pass a run.
	for name: String in ["01-first-shore-veilfall", "02-lesson-beach", "03-midwater", "04-alpha-island", "05-veilfall-shore", "06-skills-menu"]:
		if FileAccess.file_exists(OUT + "/" + name + ".png"):
			DirAccess.remove_absolute(OUT + "/" + name + ".png")
	DirAccess.remove_absolute(OUT + "/metadata.json")
	_world = (load(SCENE) as PackedScene).instantiate()
	root.add_child(_world)
	current_scene = _world
	var game: Node = root.get_node("Game")
	game.set("current_realm", "water")
	var deadline := Time.get_ticks_msec() + 120000
	while not _world.call("shell_build_complete"):
		if Time.get_ticks_msec() > deadline:
			push_error("Water shell timed out before capture")
			quit(1)
			return
		await process_frame
	await _wait_frames(60)
	_player = _world.get_node("Player")
	var rig: Node = _world.get_node("CameraRig")
	rig.set_process(false)
	rig.set_physics_process(false)
	_camera = Camera3D.new()
	_camera.fov = 70.0
	_camera.far = 6500.0
	_world.add_child(_camera)
	_camera.make_current()
	_world.get("terrain").call("set_camera", _camera)
	var look: Node = _world.get_node_or_null("WorldLook")
	if look != null:
		if look.has_method("set_clock_frozen"):
			look.call("set_clock_frozen", true)
		if look.has_method("apply_time"):
			look.call("apply_time", "day")
	await _pose("01-first-shore-veilfall", Vector3(0, 0, 0), Vector3(-4, 3.2, -7), Vector3(200, 310, 4140), false)
	await _pose("02-lesson-beach", Vector3(57.368121, 0, 151.502141), Vector3(-3, 2.7, -4), Vector3(94, 0, 168), false)
	await _pose("03-midwater", Vector3(0, 0, 220), Vector3(-4, 3.0, -6), Vector3(0, 3, 400), true)
	await _pose("04-alpha-island", Vector3(535.497, 0, 1352.51), Vector3(-4, 3.0, -6), Vector3(700, 70, 1530), false)
	await _pose("05-veilfall-shore", Vector3(384.311, 0, 3805.405), Vector3(3, 3.0, -6), Vector3(200, 300, 4140), false)
	var personal: RefCounted = game.get("local")
	personal.skills.enter_realm("water")
	var menu: Node = game.call("menu")
	if menu.call("open", "skills"):
		await _wait_frames(12)
		await _capture("06-skills-menu", {"fixture": "Water realm Skills reveal; no Candy or XP grants"})
		menu.call("close")
	else:
		_failed.append("Skills menu refused to open")
	var metadata := {"schema_version": 1, "scene": SCENE, "utc": Time.get_datetime_string_from_system(true),
		"display_server": DisplayServer.get_name(), "rendering_method": RenderingServer.get_current_rendering_method(),
		"adapter": RenderingServer.get_video_adapter_name(), "adapter_vendor": RenderingServer.get_video_adapter_vendor(),
		"resolution": [root.size.x, root.size.y], "engine": Engine.get_version_info(),
		"world_source_sha256": FileAccess.get_file_as_string("res://scripts/world/water_world.gd").replace("\r\n", "\n").sha256_text(),
		"terrain_manifest_sha256": FileAccess.get_file_as_string("res://data/terrain/water/manifest.json").replace("\r\n", "\n").sha256_text(),
		"capture_fixture": "Teleported actual player and survey camera; production world/resources. Fixed daytime. No traversal or visual-quality acceptance.",
		"frames": _records, "failures": _failed, "complete": _failed.is_empty() and _records.size() == 6}
	var output := FileAccess.open(OUT + "/metadata.json", FileAccess.WRITE)
	output.store_string(JSON.stringify(metadata, "\t"))
	output.close()
	print("Water survey: ", _records.size(), " frames, failures=", _failed)
	quit(0 if metadata.complete else 1)

func _pose(name: String, at: Vector3, offset: Vector3, target: Vector3, swimming: bool) -> void:
	var ground: float = _world.call("ground_height_at", at.x, at.z)
	at.y = 0.15 if swimming else ground + 0.15
	_player.global_position = at
	_player.velocity = Vector3.ZERO
	await _wait_frames(12)
	var eye := _player.global_position + offset
	var eye_ground: float = _world.call("ground_height_at", eye.x, eye.z)
	eye.y = maxf(eye.y, eye_ground + 2.0)
	_camera.global_position = eye
	_camera.look_at(target, Vector3.UP)
	_camera.make_current()
	await _wait_frames(20)
	await _capture(name, {"requested_player_position": [at.x, at.y, at.z], "target": [target.x, target.y, target.z], "water_pose": swimming})

func _capture(name: String, extra: Dictionary) -> void:
	await RenderingServer.frame_post_draw
	var frame := root.get_texture().get_image()
	if frame == null or frame.is_empty() or frame.get_width() != 1280 or frame.get_height() != 720:
		_failed.append(name + ": empty or wrong-sized viewport image")
		return
	var path := OUT + "/" + name + ".png"
	if frame.save_png(path) != OK:
		_failed.append(name + ": could not save PNG")
		return
	var row := extra.duplicate(true)
	row["file"] = path
	row["player_position"] = [_player.global_position.x, _player.global_position.y, _player.global_position.z]
	row["camera_position"] = [_camera.global_position.x, _camera.global_position.y, _camera.global_position.z]
	row["camera_player_distance_m"] = _camera.global_position.distance_to(_player.global_position)
	row["bytes"] = FileAccess.get_file_as_bytes(path).size()
	_records.append(row)
	print("CAPTURE ", name, " bytes=", row.bytes)
