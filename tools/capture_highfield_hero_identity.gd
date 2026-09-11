extends SceneTree

## Dedicated production-scene evidence for The Highfield's herd -> drove gate
## -> visual stock-camp composition. This does not share or modify
## tools/_capture_locations.gd.
##
## Run with a real Compatibility renderer:
##   godot --path . --rendering-driver opengl3 --resolution 1280x720 \
##     --script tools/capture_highfield_hero_identity.gd

const SCENE := "res://scenes/world/meadows_playground.tscn"
const OUT_DIR := "res://ralph/reports/BROAD-VISUAL-0910/HIGHFIELD-HERO-IDENTITY-R3"
const READY_TIMEOUT_MS := 420_000
const CAMERA_BACK_M := 5.2
const CAMERA_UP_M := 2.75
const FOV := 70.0

const VIEWS := [
	{"name": "01-herd-gate-camp-day", "stand": Vector2(400.0, 5832.0), "target": Vector2(408.0, 5895.0), "time": "day", "aim_up": 2.8},
	{"name": "02-herd-gate-camp-night", "stand": Vector2(400.0, 5832.0), "target": Vector2(408.0, 5895.0), "time": "night", "aim_up": 2.8},
	{"name": "03-east-herd-gate-day", "stand": Vector2(438.0, 5842.0), "target": Vector2(407.0, 5895.0), "time": "day", "aim_up": 2.8},
	{"name": "04-east-herd-gate-night", "stand": Vector2(438.0, 5842.0), "target": Vector2(407.0, 5895.0), "time": "night", "aim_up": 2.8},
	{"name": "05-gate-camp-day", "stand": Vector2(414.0, 5864.0), "target": Vector2(407.0, 5897.0), "time": "day", "aim_up": 3.0},
	{"name": "06-gate-camp-night", "stand": Vector2(414.0, 5864.0), "target": Vector2(407.0, 5897.0), "time": "night", "aim_up": 3.0},
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
	if player == null or look == null:
		push_error("capture requires the production Player and WorldLook")
		quit(1)
		return
	if rig != null:
		rig.set_process(false)
		rig.set_physics_process(false)
	# Evidence moves the ordinary production player between fixed art-review
	# stands. Hold locomotion after each live ground sample so streamed collision
	# or a nearby creature cannot push the trainer away while the fixed camera
	# remains behind. R2 exposed exactly that in frame 01 (31.76m camera-to-player
	# instead of the intended ~6m).
	player.set_process(false)
	player.set_physics_process(false)
	if hud != null:
		hud.visible = false
	if weather != null:
		if weather.has_method("set_weather"):
			weather.call("set_weather", "clear")
		weather.set_process(false)
		weather.set_physics_process(false)
	look.set_process(false)
	look.set_physics_process(false)

	var camera := Camera3D.new()
	camera.name = "HighfieldHeroEvidenceCamera"
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
		var stand_ground := float(world.call("ground_height_at", stand.x, stand.y))
		if is_nan(stand_ground) or is_inf(stand_ground):
			failures.append("%s: production ground sample is not finite" % str(view.name))
			continue
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
		for i in 60:
			await physics_frame
		for i in 6:
			await process_frame
		await RenderingServer.frame_post_draw
		var actual_xz := Vector2(player.global_position.x, player.global_position.z)
		var stand_displacement := actual_xz.distance_to(stand)
		var ground_clearance := player.global_position.y - stand_ground
		if stand_displacement > 0.25:
			failures.append("%s: player left evidence stand by %.2fm" % [str(view.name), stand_displacement])
			continue
		if absf(ground_clearance - 0.35) > 0.1:
			failures.append("%s: player grounding drifted to %.2fm clearance" % [str(view.name), ground_clearance])
			continue
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
			"player_actual_xz": [actual_xz.x, actual_xz.y],
			"player_stand_displacement_m": stand_displacement,
			"player_ground_clearance_m": ground_clearance,
			"camera_to_player_m": camera.global_position.distance_to(player.global_position),
			"gate_distance_m": stand.distance_to(Vector2(400.0, 5900.0)),
			"image_size": [image.get_width(), image.get_height()],
		})
		print("wrote %s" % path)

	var manifest := {
		"production_scene": SCENE,
		"named_location": "The Highfield",
		"fixture_disclosure": "Production Meadows scene with ordinary player, Terrain3D, scatter, props and encounters. HUD hidden for unobstructed art review; clear weather/time pin; 70-degree third-person camera at 5.2m stand-off. No progress or encounter injection.",
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
