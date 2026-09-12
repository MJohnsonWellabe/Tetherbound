extends SceneTree

## Focused production-scene evidence for the broad Stonewater Reach sequence.
## Uses the production player, HUD, weather/time system, and third-person FOV.

const REACH := preload("res://scripts/world/stonewater_reach.gd")
const SCENE := "res://scenes/world/meadows_playground.tscn"
const FRESH_OUTPUT := preload("res://tools/fresh_capture_output.gd")
const READY_TIMEOUT_MS := 420_000
const CAMERA_BACK_M := 5.2
const CAMERA_UP_M := 2.65
const FOV := 70.0

var _out_dir := ""

const VIEWS := [
	{"name": "01-haulage-wreck-day", "at": Vector2(-91.0, 3238.0), "look": REACH.WRECK, "time": "day", "aim_up": 2.1},
	{"name": "02-road-arrival-day", "at": REACH.APPROACH, "look": Vector2(-111.0, 3468.0), "time": "day", "aim_up": 1.4},
	{"name": "03-overlook-water-day", "at": Vector2(-143.0, 3439.0), "look": Vector2(-110.0, 3472.0), "time": "day", "aim_up": 1.0},
	{"name": "04-run-east-day", "at": Vector2(-103.0, 3465.0), "look": Vector2(-49.0, 3505.0), "time": "day", "aim_up": 0.8},
	{"name": "05-spring-arrival-day", "at": Vector2(-28.0, 3530.0), "look": REACH.SPRING, "time": "day", "aim_up": 1.0},
	{"name": "06-springhead-day", "at": Vector2(-6.0, 3569.0), "look": Vector2(14.8, 3566.8), "time": "day", "aim_up": 2.0},
	{"name": "07-overlook-water-night", "at": Vector2(-143.0, 3439.0), "look": Vector2(-110.0, 3472.0), "time": "night", "aim_up": 1.0},
	{"name": "08-springhead-night", "at": Vector2(-6.0, 3569.0), "look": Vector2(14.8, 3566.8), "time": "night", "aim_up": 2.0},
	{"name": "09-haulage-wreck-night", "at": Vector2(-91.0, 3238.0), "look": REACH.WRECK, "time": "night", "aim_up": 2.1},
	{"name": "10-causeway-front-day", "at": Vector2(-104.0, 3465.0), "look": Vector2(-84.0, 3482.0), "time": "day", "aim_up": 2.5},
	{"name": "11-causeway-reverse-day", "at": Vector2(-66.0, 3492.0), "look": Vector2(-84.0, 3482.0), "time": "day", "aim_up": 2.5},
	{"name": "12-causeway-front-night", "at": Vector2(-104.0, 3465.0), "look": Vector2(-84.0, 3482.0), "time": "night", "aim_up": 2.5},
	{"name": "13-causeway-reverse-night", "at": Vector2(-66.0, 3492.0), "look": Vector2(-84.0, 3482.0), "time": "night", "aim_up": 2.5},
	{"name": "14-spring-arrival-night", "at": Vector2(-28.0, 3530.0), "look": REACH.SPRING, "time": "night", "aim_up": 1.0},
	{"name": "15-haulage-wreck-oblique-day", "at": Vector2(-58.0, 3264.0), "look": REACH.WRECK, "time": "day", "aim_up": 1.8},
	{"name": "16-haulage-wreck-oblique-night", "at": Vector2(-58.0, 3264.0), "look": REACH.WRECK, "time": "night", "aim_up": 1.8},
	{"name": "17-road-arrival-night", "at": REACH.APPROACH, "look": Vector2(-111.0, 3468.0), "time": "night", "aim_up": 1.4},
]


func _init() -> void:
	_parse_args()
	_run()


func _parse_args() -> void:
	_out_dir = FRESH_OUTPUT.requested(OS.get_cmdline_user_args())


func _run() -> void:
	if not FRESH_OUTPUT.create_fresh(_out_dir, "Stonewater Reach capture"):
		quit(1)
		return
	if DisplayServer.get_name() == "headless":
		push_error("Stonewater Reach capture requires a rendering display")
		quit(1)
		return
	var packed := load(SCENE) as PackedScene
	if packed == null:
		push_error("could not load production Meadows scene")
		quit(1)
		return
	var world := packed.instantiate() as Node3D
	root.add_child(world)
	if not await _wait_for_world(world):
		push_error("production Meadows scene did not finish building")
		quit(1)
		return

	var reach := world.get_node_or_null(^"StonewaterReach") as Node3D
	var player := world.get_node_or_null(^"Player") as Node3D
	var look := world.get_node_or_null(^"WorldLook")
	var weather := world.get_node_or_null(^"WorldWeather")
	var rig := world.get_node_or_null(^"CameraRig")
	if reach == null or player == null or look == null:
		push_error("capture requires StonewaterReach, Player and WorldLook")
		quit(1)
		return
	if rig != null:
		rig.set_process(false)
		rig.set_physics_process(false)
	if weather != null:
		if weather.has_method("set_weather"):
			weather.call("set_weather", "clear")
		weather.set_process(false)
		weather.set_physics_process(false)
	look.set_process(false)
	look.set_physics_process(false)
	for overlay_path: NodePath in [
		^"PlaygroundHUD", ^"CombatHUD", ^"DialoguePanel", ^"NamePrompt", ^"StarterPicker"
	]:
		var overlay := world.get_node_or_null(overlay_path)
		if overlay != null:
			overlay.set("visible", false)
			overlay.process_mode = Node.PROCESS_MODE_DISABLED
	player.process_mode = Node.PROCESS_MODE_DISABLED
	if player is CharacterBody3D:
		(player as CharacterBody3D).velocity = Vector3.ZERO

	var camera := Camera3D.new()
	camera.name = "StonewaterReachEvidenceCamera"
	camera.fov = FOV
	camera.far = 2000.0
	world.add_child(camera)
	camera.make_current()

	var records: Array[Dictionary] = []
	var failures: Array[String] = []
	for raw in VIEWS:
		var view: Dictionary = raw
		look.call("apply_time", str(view.time))
		var stand: Vector2 = view.at
		var target: Vector2 = view.look
		var stand_ground := float(world.call("ground_height_at", stand.x, stand.y))
		player.global_position = Vector3(stand.x, stand_ground + 0.35, stand.y)
		if player is CharacterBody3D:
			(player as CharacterBody3D).velocity = Vector3.ZERO
		var toward := (target - stand).normalized()
		player.rotation.y = atan2(toward.x, toward.y)
		var eye_xz := stand - toward * CAMERA_BACK_M
		var eye_ground := float(world.call("ground_height_at", eye_xz.x, eye_xz.y))
		camera.global_position = Vector3(eye_xz.x, eye_ground + CAMERA_UP_M, eye_xz.y)
		var target_ground := float(world.call("ground_height_at", target.x, target.y))
		camera.look_at(Vector3(target.x, target_ground + float(view.aim_up), target.y), Vector3.UP)
		for i in 50:
			await physics_frame
		for i in 6:
			await process_frame
		await RenderingServer.frame_post_draw
		var image := root.get_texture().get_image()
		if image == null or image.is_empty():
			failures.append("%s: viewport returned no image" % str(view.name))
			continue
		var out_path := "%s/%s.png" % [_out_dir, str(view.name)]
		if image.save_png(out_path) != OK:
			failures.append("%s: save_png failed" % str(view.name))
			continue
		records.append({
			"frame": str(view.name),
			"time": str(view.time),
			"player_xz": [stand.x, stand.y],
			"target_xz": [target.x, target.y],
			"target_distance_m": stand.distance_to(target),
			"camera_to_player_m": camera.global_position.distance_to(player.global_position),
			"image_size": [image.get_width(), image.get_height()],
		})
		print("wrote %s" % out_path)

	var complete := failures.is_empty() and records.size() == VIEWS.size()
	var manifest := {
		"production_scene": SCENE,
		"named_location": "The Stonewater Reach",
		"runtime_node": "StonewaterReach",
		"output_directory": _out_dir,
		"expected_frame_count": VIEWS.size(),
		"captured_frame_count": records.size(),
		"planned_frames": VIEWS.map(func(view: Dictionary) -> String: return str(view.name)),
		"fixture_disclosure": "Production Meadows scene and player, clear-weather/time pin, production-equivalent 70-degree third-person camera at 5.2m stand-off. HUD and modal overlays are hidden for unobstructed location review. Player processing is paused only to hold each evidence coordinate; no progress or encounter injection.",
		"complete": complete,
		"frames": records,
		"failures": failures,
	}
	var file := FileAccess.open("%s/manifest.json" % _out_dir, FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(manifest, "\t") + "\n")
		file.close()
	else:
		failures.append("manifest could not be written")
		complete = false
	quit(0 if complete else 1)


func _wait_for_world(world: Node) -> bool:
	var deadline := Time.get_ticks_msec() + READY_TIMEOUT_MS
	while Time.get_ticks_msec() < deadline:
		if world.has_method("shell_build_complete") and bool(world.call("shell_build_complete")):
			return true
		await physics_frame
	return false
