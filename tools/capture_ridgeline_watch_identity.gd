extends SceneTree

## Focused production-scene evidence for the named Ridgeline Watch.
##
## Captures the ordinary watchtower-spur approach and the exact Settings
## catalogue position, with a third night frame proving that the lookout's
## signal survives the dark.  The player stays at the evidence position so
## Terrain3D and encounter streaming match ordinary play; the camera uses the
## production 70-degree FOV and 5.2m third-person stand-off.
##
## Run with a real Compatibility renderer, never `--headless`:
##
##   godot --path . --rendering-driver opengl3 --resolution 1280x720 \
##     --script tools/capture_ridgeline_watch_identity.gd

const WATCH := preload("res://scripts/world/ridgeline_watch.gd")
const SCENE := "res://scenes/world/meadows_playground.tscn"
const OUT_DIR := "res://ralph/reports/BROAD-VISUAL-0910/RIDGELINE-WATCH-R2"
const READY_TIMEOUT_MS := 420_000
const CAMERA_BACK_M := 5.2
const CAMERA_UP_M := 2.65
const FOV := 70.0

const VIEWS := [
	{"name": "01-southwest-arrival-day", "at": WATCH.ORDINARY_APPROACH, "look": WATCH.SITE, "time": "day", "aim_up": 7.2},
	{"name": "02-southwest-arrival-night", "at": WATCH.ORDINARY_APPROACH, "look": WATCH.SITE, "time": "night", "aim_up": 7.2},
	{"name": "03-canonical-watch-day", "at": WATCH.CANONICAL_VIEW, "look": WATCH.SITE, "time": "day", "aim_up": 6.2},
	{"name": "04-canonical-watch-night", "at": WATCH.CANONICAL_VIEW, "look": WATCH.SITE, "time": "night", "aim_up": 6.2},
	{"name": "05-service-shelter-day", "at": Vector2(-270.0, 6483.0), "look": WATCH.SITE + WATCH.SERVICE_SHELTER_CENTRE, "time": "day", "aim_up": 2.1},
	{"name": "06-service-shelter-night", "at": Vector2(-270.0, 6483.0), "look": WATCH.SITE + WATCH.SERVICE_SHELTER_CENTRE, "time": "night", "aim_up": 2.1},
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

	var watch := world.get_node_or_null(^"RidgelineWatch") as Node3D
	var player := world.get_node_or_null(^"Player") as Node3D
	var look := world.get_node_or_null(^"WorldLook")
	var weather := world.get_node_or_null(^"WorldWeather")
	var rig := world.get_node_or_null(^"CameraRig")
	if watch == null or player == null or look == null:
		push_error("capture requires RidgelineWatch, Player and WorldLook")
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
	camera.name = "RidgelineWatchEvidenceCamera"
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
		var stand_ground := float(world.call("ground_height_at", stand.x, stand.y))
		player.global_position = Vector3(stand.x, stand_ground + 0.35, stand.y)
		if player is CharacterBody3D:
			(player as CharacterBody3D).velocity = Vector3.ZERO
		var target: Vector2 = view.look
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
		var out_path := "%s/%s.png" % [OUT_DIR, str(view.name)]
		if image.save_png(out_path) != OK:
			failures.append("%s: save_png failed" % str(view.name))
			continue
		records.append({
			"frame": str(view.name),
			"time": str(view.time),
			"player_xz": [player.global_position.x, player.global_position.z],
			"camera_to_player_m": camera.global_position.distance_to(player.global_position),
			"watch_distance_m": stand.distance_to(WATCH.SITE),
			"image_size": [image.get_width(), image.get_height()],
		})
		print("wrote %s" % out_path)

	var manifest := {
		"production_scene": SCENE,
		"named_location": "The Ridgeline Watch",
		"runtime_node": "RidgelineWatch",
		"fixture_disclosure": "Production Meadows scene and player, HUD/modal overlays hidden for composition review, clear-weather/time pin, production-equivalent 70-degree third-person camera at 5.2m stand-off. Player processing and velocity paused only to hold each evidence coordinate; no progress or encounter injection.",
		"complete": failures.is_empty() and records.size() == VIEWS.size(),
		"frames": records,
		"failures": failures,
	}
	var file := FileAccess.open("%s/manifest.json" % OUT_DIR, FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(manifest, "\t") + "\n")
		file.close()
	else:
		failures.append("manifest could not be written")

	quit(0 if failures.is_empty() else 1)


func _wait_for_world(world: Node) -> bool:
	var deadline := Time.get_ticks_msec() + READY_TIMEOUT_MS
	while Time.get_ticks_msec() < deadline:
		if world.has_method("shell_build_complete") and bool(world.call("shell_build_complete")):
			return true
		await physics_frame
	return false
