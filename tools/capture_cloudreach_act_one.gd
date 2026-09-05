extends SceneTree

## Real production-scene evidence for Cloudreach Act I. The first frame uses
## the authored realm arrival; later frames reposition the same production
## player between already-proven interaction sites so the evidence set stays
## bounded. HUD, prompts and dialogue remain visible.
const SCENE := preload("res://scenes/world/cloudreach_cliffs.tscn")
const OUT_DIR := "res://ralph/reports/CLOUDREACH-ACT1-0904/shots"
const PERF_PATH := "res://ralph/reports/CLOUDREACH-ACT1-0904/performance.json"
const SETTLE_FRAMES := 18
const SAMPLE_FRAMES := 18

var _game: Node
var _world: Node3D
var _player: CharacterBody3D
var _rig: SpringArm3D
var _camera: Camera3D
var _rows: Array[Dictionary] = []
var _failures: Array[String] = []


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))
	_game = root.get_node_or_null(^"Game")
	if _game == null:
		_fail("Game autoload is missing")
		return
	_game.call("reset_for_new_game")
	_game.set("current_realm", "cloudreach")
	var progression: RefCounted = _game.get("progression")
	progression.call("set_flag", "realm_key_cloudreach")
	progression.call("set_flag", "realm_gate_cloudreach_unlocked")
	# A natural Cloudreach arrival follows a completed Meadows chapter, so show
	# the production quick bar with representative carried gear instead of the
	# fresh-debug-save's five empty cards.
	var inventory: RefCounted = _game.get("inventory")
	for item: Dictionary in [
		{"id": "axe", "count": 1},
		{"id": "pickaxe", "count": 1},
		{"id": "potion_small", "count": 3},
		{"id": "revive", "count": 2},
		{"id": "good_candy", "count": 1},
	]:
		inventory.call("add", item["id"], item["count"])
	_game.call("autofill_hotbar")

	_world = SCENE.instantiate()
	root.add_child(_world)
	current_scene = _world
	for _frame in SETTLE_FRAMES:
		await process_frame
	_player = _world.get_node_or_null(^"Player") as CharacterBody3D
	_rig = _world.get_node_or_null(^"CameraRig") as SpringArm3D
	_camera = _world.get_node_or_null(^"CameraRig/Camera3D") as Camera3D
	if _player == null or _rig == null or _camera == null:
		_fail("production player/camera shell is missing")
		return
	var look := _world.get_node_or_null(^"WorldLook")
	if look != null:
		look.call("set_clock_frozen", true)
		look.call("apply_time", "day")
	_camera.make_current()
	_rig.set_process(false)
	_rig.set_physics_process(false)
	root.size = Vector2i(1280, 720)

	await _pose(Vector3(0.0, 130.2, -260.0), Vector3(-80.0, 150.0, 40.0), 3.0)
	await _capture("01-arrival-objective")

	var chapter := _world.get_node_or_null(^"CloudreachChapter")
	if chapter == null:
		_fail("CloudreachChapter is missing")
		return
	var aila := chapter.get_node_or_null(^"People/Warden Aila") as Node3D
	if aila == null:
		_fail("Warden Aila is missing")
		return
	await _pose(Vector3(-275.0, 180.1, 517.5), aila.global_position + Vector3.UP * 1.35, 1.0)
	await _capture("02-galefoot-aila-prompt")
	await _press_interact()
	await _capture("03-aila-dialogue")
	for _line in 4:
		if not bool(_world.get_node(^"DialoguePanel").call("is_open")):
			break
		await _press_interact()
	if not bool(progression.call("has", "cloudreach_crisis_learned")):
		_failures.append("Aila dialogue did not grant cloudreach_crisis_learned")

	var west := chapter.get_node_or_null(^"lower_west") as Node3D
	if west == null:
		_fail("west Storm Anchor is missing")
		return
	await _pose(west.global_position + Vector3(0.0, 0.1, -2.5), west.global_position + Vector3.UP * 2.8, 2.0)
	await _capture("04-west-anchor-zero-of-two")
	await _press_interact()
	await _capture("05-west-anchor-one-of-two")

	var cache := chapter.get_node_or_null(^"cr_pickup_lower_good_candy") as Node3D
	if cache == null:
		_fail("Cloudreach Good Candy cache is missing")
		return
	await _pose(cache.global_position + Vector3(0.0, 0.1, -2.0), cache.global_position + Vector3.UP * 1.1, 1.0)
	await _capture("06-good-candy-cache")

	var file := FileAccess.open(PERF_PATH, FileAccess.WRITE)
	if file == null:
		_failures.append("could not write performance evidence")
	else:
		file.store_string(JSON.stringify({
			"captured_at_utc": Time.get_datetime_string_from_system(true),
			"engine": Engine.get_version_info().get("string", "unknown"),
			"display_server": DisplayServer.get_name(),
			"video_adapter": RenderingServer.get_video_adapter_name(),
			"resolution": [root.size.x, root.size.y],
			"sample_frames_per_view": SAMPLE_FRAMES,
			"views": _rows,
		}, "  "))
		file.close()
	if _failures.is_empty():
		print("CLOUDREACH ACT I CAPTURE OK: %d production frames" % _rows.size())
		quit(0)
	else:
		for failure: String in _failures:
			push_error("CLOUDREACH ACT I CAPTURE: " + failure)
		quit(1)


func _pose(at: Vector3, target: Vector3, pitch_deg: float) -> void:
	var ground := float(_world.call("ground_height_near", at))
	if not is_nan(ground):
		at.y = ground + 0.08
	_player.global_position = at
	_player.velocity = Vector3.ZERO
	_player.reset_physics_interpolation()
	for _frame in 8:
		await physics_frame
	var sightline := target - _player.global_position
	var model := _player.get_node_or_null(^"Model") as Node3D
	if model != null:
		var flat := sightline
		flat.y = 0.0
		if flat.length_squared() > 0.01:
			model.global_rotation.y = atan2(-flat.x, -flat.z)
	_rig.global_position = _player.global_position + Vector3.UP * 1.55
	_rig.rotation = Vector3(deg_to_rad(pitch_deg), atan2(-sightline.x, -sightline.z), 0.0)
	_rig.reset_physics_interpolation()
	for _frame in SETTLE_FRAMES:
		await process_frame


func _press_interact() -> void:
	var arbiter := _world.get_node_or_null(^"InteractionArbiter")
	if arbiter != null:
		arbiter.call("_recompute")
	var event := InputEventAction.new()
	event.action = "interact"
	event.pressed = true
	Input.parse_input_event(event)
	await physics_frame
	event = InputEventAction.new()
	event.action = "interact"
	event.pressed = false
	Input.parse_input_event(event)
	for _frame in 5:
		await process_frame


func _capture(label: String) -> void:
	var draws := 0.0
	var primitives := 0.0
	var objects := 0.0
	var fps := 0.0
	var started := Time.get_ticks_usec()
	for _frame in SAMPLE_FRAMES:
		await RenderingServer.frame_post_draw
		draws += Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)
		primitives += Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)
		objects += Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME)
		fps += Performance.get_monitor(Performance.TIME_FPS)
	var elapsed_ms := float(Time.get_ticks_usec() - started) / 1000.0
	var image := root.get_texture().get_image()
	var path := "%s/%s.png" % [OUT_DIR, label]
	if image == null or image.save_png(path) != OK:
		_failures.append("viewport capture failed: " + label)
		return
	var n := float(SAMPLE_FRAMES)
	_rows.append({
		"view": label,
		"draw_calls": roundi(draws / n),
		"primitives": roundi(primitives / n),
		"objects": roundi(objects / n),
		"reported_fps": snappedf(fps / n, 0.1),
		"measured_frame_ms": snappedf(elapsed_ms / n, 0.01),
	})
	print("CLOUDREACH ACT I CAPTURE %s -> %s" % [label, path])


func _fail(message: String) -> void:
	push_error("CLOUDREACH ACT I CAPTURE: " + message)
	quit(1)
