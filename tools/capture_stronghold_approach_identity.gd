extends SceneTree

## Dedicated production-scene evidence for Stronghold Approach. This loads the
## shipped Meadows scene, keeps its player/HUD/scatter/encounters, pins clear
## weather and time only, and uses the production 70-degree third-person view.
## It deliberately does not share or modify tools/_capture_locations.gd.
##
## Run with a real Compatibility renderer:
##   godot --path . --rendering-driver opengl3 --resolution 1280x720 \
##     --script tools/capture_stronghold_approach_identity.gd

const SCENE := "res://scenes/world/meadows_playground.tscn"
const OUT_DIR := "res://ralph/reports/BROAD-VISUAL-0910/STRONGHOLD-APPROACH-IDENTITY"
const READY_TIMEOUT_MS := 420_000
const CAMERA_BACK_M := 5.2
const CAMERA_UP_M := 2.65
const FOV := 70.0
const HALL := Vector2(0.0, 7560.0)

const VIEWS := [
	{"name": "01-arrival-day", "stand": Vector2(0.0, 7000.0), "target": HALL, "time": "day", "aim_up": 10.0},
	{"name": "02-arrival-night", "stand": Vector2(0.0, 7000.0), "target": HALL, "time": "night", "aim_up": 10.0},
	{"name": "03-outer-watch-day", "stand": Vector2(-25.0, 7040.0), "target": Vector2(-67.0, 7145.0), "time": "day", "aim_up": 2.4},
	{"name": "04-road-drop-day", "stand": Vector2(-20.0, 7250.0), "target": Vector2(80.0, 7370.0), "time": "day", "aim_up": 2.4},
	{"name": "05-road-drop-night", "stand": Vector2(-20.0, 7250.0), "target": Vector2(80.0, 7370.0), "time": "night", "aim_up": 2.4},
	{"name": "06-gateward-day", "stand": Vector2(80.0, 7370.0), "target": HALL, "time": "day", "aim_up": 12.0},
	{"name": "07-gateward-night", "stand": Vector2(80.0, 7370.0), "target": HALL, "time": "night", "aim_up": 12.0},
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
	if player == null or look == null:
		push_error("capture requires the production Player and WorldLook")
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

	var camera := Camera3D.new()
	camera.name = "StrongholdApproachEvidenceCamera"
	camera.fov = FOV
	camera.far = 2000.0
	world.add_child(camera)
	camera.make_current()

	var records: Array[Dictionary] = []
	var failures: Array[String] = []
	for raw: Variant in VIEWS:
		var view := raw as Dictionary
		look.call("apply_time", str(view.time))
		var stand: Vector2 = view.stand
		var target: Vector2 = view.target
		var ground := float(world.call("ground_height_at", stand.x, stand.y))
		player.global_position = Vector3(stand.x, ground + 0.35, stand.y)
		if player is CharacterBody3D:
			(player as CharacterBody3D).velocity = Vector3.ZERO
		var toward := (target - stand).normalized()
		player.rotation.y = atan2(toward.x, toward.y)
		var eye_xz := stand - toward * CAMERA_BACK_M
		var eye_ground := float(world.call("ground_height_at", eye_xz.x, eye_xz.y))
		camera.global_position = Vector3(eye_xz.x, eye_ground + CAMERA_UP_M, eye_xz.y)
		var target_ground := float(world.call("ground_height_at", target.x, target.y))
		camera.look_at(Vector3(target.x, target_ground + float(view.aim_up), target.y), Vector3.UP)
		for i in 60:
			await physics_frame
		for i in 6:
			await process_frame
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
			"camera_to_player_m": camera.global_position.distance_to(player.global_position),
			"hall_distance_m": stand.distance_to(HALL),
			"image_size": [image.get_width(), image.get_height()],
		})
		print("wrote %s" % path)

	var manifest := {
		"production_scene": SCENE,
		"named_location": "Stronghold Approach",
		"fixture_disclosure": "Production Meadows scene with ordinary player, HUD, Terrain3D, scatter, props and encounters. Clear weather/time pin; 70-degree third-person camera at 5.2m stand-off. No progress or encounter injection.",
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
