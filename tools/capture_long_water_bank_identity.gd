extends SceneTree

## Dedicated production-scene evidence for The Long Water's bank rhythm,
## lower-face shelves and authored overlook. Does not modify the shared
## named-location capture tool.

const SCENE := "res://scenes/world/meadows_playground.tscn"
const OUT_DIR := "res://ralph/reports/BROAD-VISUAL-0910/LONG-WATER-BANK-RHYTHM"
const READY_TIMEOUT_MS := 420_000
const CAMERA_BACK_M := 5.0
const CAMERA_UP_M := 3.0
const FOV := 68.0

const VIEWS := [
	{"name": "01-axis-arrival-day", "stand": Vector2(-250.0, 4165.0), "target": Vector2(-340.0, 4185.0), "time": "day", "aim_up": 0.5, "camera_up": 6.0},
	{"name": "02-axis-arrival-night", "stand": Vector2(-250.0, 4165.0), "target": Vector2(-340.0, 4185.0), "time": "night", "aim_up": 0.5, "camera_up": 6.0},
	{"name": "03-overlook-west-day", "stand": Vector2(-280.0, 4174.0), "target": Vector2(-360.0, 4187.0), "time": "day", "aim_up": 0.6, "camera_up": 3.4},
	{"name": "04-overlook-west-night", "stand": Vector2(-280.0, 4174.0), "target": Vector2(-360.0, 4187.0), "time": "night", "aim_up": 0.6, "camera_up": 3.4},
	{"name": "05-overlook-east-day", "stand": Vector2(-280.0, 4174.0), "target": Vector2(-205.0, 4200.0), "time": "day", "aim_up": 0.6, "camera_up": 3.4},
	{"name": "06-overlook-east-night", "stand": Vector2(-280.0, 4174.0), "target": Vector2(-205.0, 4200.0), "time": "night", "aim_up": 0.6, "camera_up": 3.4},
]


func _init() -> void:
	_run()


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))
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

	var player := world.get_node_or_null(^"Player") as Node3D
	var look := world.get_node_or_null(^"WorldLook")
	var weather := world.get_node_or_null(^"WorldWeather")
	var rig := world.get_node_or_null(^"CameraRig")
	var hud := world.get_node_or_null(^"PlaygroundHUD") as CanvasLayer
	var submersion := world.find_child("SubmersionOverlay", true, false) as CanvasLayer
	if player == null or look == null:
		push_error("capture requires production Player and WorldLook")
		quit(1)
		return
	if rig != null:
		rig.set_process(false)
		rig.set_physics_process(false)
	# The capture moves the ordinary production player between distant proof
	# stands. Hold only its locomotion physics after each live ground sample so
	# the first frame cannot fall while collision streaming follows the new eye.
	player.set_physics_process(false)
	if hud != null:
		hud.visible = false
	if submersion != null:
		submersion.visible = false
	if weather != null:
		if weather.has_method("set_weather"):
			weather.call("set_weather", "clear")
		weather.set_process(false)
		weather.set_physics_process(false)
	var camera := Camera3D.new()
	camera.name = "LongWaterBankEvidenceCamera"
	camera.fov = FOV
	camera.far = 2000.0
	world.add_child(camera)
	camera.make_current()

	var records: Array[Dictionary] = []
	var failures: Array[String] = []
	for raw: Variant in VIEWS:
		var view := raw as Dictionary
		# Apply the authored clock while WorldLook is active, then freeze it.
		# This ordering prevents a settling frame from advancing or replacing
		# the requested day/night state.
		look.set_process(true)
		look.set_physics_process(true)
		look.call("apply_time", str(view.time))
		look.set_process(false)
		look.set_physics_process(false)
		var stand: Vector2 = view.stand
		var target: Vector2 = view.target
		var stand_ground := float(world.call("ground_height_at", stand.x, stand.y))
		player.global_position = Vector3(stand.x, stand_ground + 0.35, stand.y)
		if player is CharacterBody3D:
			(player as CharacterBody3D).velocity = Vector3.ZERO
		var toward := (target - stand).normalized()
		player.rotation.y = atan2(toward.x, toward.y)
		var eye_xz := stand - toward * CAMERA_BACK_M
		var eye_ground := float(world.call("ground_height_at", eye_xz.x, eye_xz.y))
		camera.global_position = Vector3(eye_xz.x, eye_ground + float(view.get("camera_up", CAMERA_UP_M)), eye_xz.y)
		var target_ground := float(world.call("ground_height_at", target.x, target.y))
		camera.look_at(Vector3(target.x, target_ground + float(view.aim_up), target.y), Vector3.UP)
		for i in 60:
			await physics_frame
		for i in 6:
			await process_frame
		if absf(player.global_position.y - (stand_ground + 0.35)) > 0.05:
			failures.append("%s: player moved off the sampled live ground" % str(view.name))
			continue
		await RenderingServer.frame_post_draw
		var image := root.get_texture().get_image()
		if image == null or image.is_empty():
			failures.append("%s: viewport returned no image" % str(view.name))
			continue
		var path := "%s/%s.png" % [OUT_DIR, str(view.name)]
		if image.save_png(path) != OK:
			failures.append("%s: save_png failed" % str(view.name))
			continue
		records.append({
			"frame": str(view.name),
			"time": str(view.time),
			"player_xz": [stand.x, stand.y],
			"player_ground_y": stand_ground,
			"player_y": player.global_position.y,
			"camera_to_player_m": camera.global_position.distance_to(player.global_position),
			"reach_distance_m": stand.distance_to(Vector2(-280.0, 4195.0)),
			"image_size": [image.get_width(), image.get_height()],
		})
		print("wrote %s" % path)

	var manifest := {
		"production_scene": SCENE,
		"named_location": "The Long Water",
		"fixture_disclosure": "Production Meadows scene with ordinary player, Terrain3D, scatter, props and encounters. Authored day/night clock applied before WorldLook is frozen; clear weather; PlaygroundHUD and independent Water/SubmersionOverlay hidden; 68-degree third-person camera at 5m stand-off. Player and camera are seated from live ground_height_at samples, never parked underground. No progress or encounter injection.",
		"complete": failures.is_empty() and records.size() == VIEWS.size(),
		"frames": records,
		"failures": failures,
	}
	var file := FileAccess.open("%s/manifest.json" % OUT_DIR, FileAccess.WRITE)
	if file == null:
		failures.append("manifest could not be written")
	else:
		file.store_string(JSON.stringify(manifest, "\t") + "\n")
		file.close()
	quit(0 if failures.is_empty() else 1)


func _wait_for_world(world: Node) -> bool:
	var deadline := Time.get_ticks_msec() + READY_TIMEOUT_MS
	while Time.get_ticks_msec() < deadline:
		if world.has_method("shell_build_complete") and bool(world.call("shell_build_complete")):
			return true
		await physics_frame
	return false
