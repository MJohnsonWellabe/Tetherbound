extends SceneTree

## Focused production-scene evidence for The Ironwood Grove. The generic named-
## location strip predates the grove's three-crown age ladder and bounded crown
## glade, so it cannot grade the current world. This harness keeps the player on
## live Terrain3D and shows the same four compositions at day and night.
##
## Run with a real Compatibility renderer (never --headless):
##   godot --path . --rendering-driver opengl3 --resolution 1280x720 \
##     --script tools/capture_ironwood_grove_identity.gd

const SCENE := "res://scenes/world/meadows_playground.tscn"
const OUT_DIR := "res://ralph/reports/BROAD-VISUAL-0910/IRONWOOD-GROVE-IDENTITY-R1"
const READY_TIMEOUT_MS := 420_000
const CAMERA_BACK_M := 5.2
const CAMERA_UP_M := 2.75
const FOV := 67.0

const VIEWS := [
	# First real-route point inside the Grove's authored 60m landmark radius.
	{"name": "01-road-arrival-day", "stand": Vector2(-321.0, 5025.0), "target": Vector2(-344.0, 5075.0), "time": "day", "aim_up": 7.0},
	{"name": "01-road-arrival-night", "stand": Vector2(-321.0, 5025.0), "target": Vector2(-344.0, 5075.0), "time": "night", "aim_up": 7.0},
	{"name": "02-southwest-crown-day", "stand": Vector2(-368.0, 5034.0), "target": Vector2(-344.0, 5075.0), "time": "day", "aim_up": 7.0},
	{"name": "02-southwest-crown-night", "stand": Vector2(-368.0, 5034.0), "target": Vector2(-344.0, 5075.0), "time": "night", "aim_up": 7.0},
	{"name": "03-inside-age-ladder-day", "stand": Vector2(-351.0, 5058.0), "target": Vector2(-345.0, 5082.0), "time": "day", "aim_up": 6.5},
	{"name": "03-inside-age-ladder-night", "stand": Vector2(-351.0, 5058.0), "target": Vector2(-345.0, 5082.0), "time": "night", "aim_up": 6.5},
	# Aim between the paired elders and the existing north-west felling trace, low
	# enough to judge the grounded harvest cue without losing the crown hierarchy.
	{"name": "04-crafting-glade-day", "stand": Vector2(-320.0, 5098.0), "target": Vector2(-349.0, 5083.0), "time": "day", "aim_up": 3.0},
	{"name": "04-crafting-glade-night", "stand": Vector2(-320.0, 5098.0), "target": Vector2(-349.0, 5083.0), "time": "night", "aim_up": 3.0},
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
	camera.name = "IronwoodGroveEvidenceCamera"
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
		player.global_position = Vector3(stand.x, stand_ground + 0.35, stand.y)
		if player is CharacterBody3D:
			(player as CharacterBody3D).velocity = Vector3.ZERO
		var toward := (target - stand).normalized()
		player.rotation.y = atan2(toward.x, toward.y)
		# Terrain3D streams around the player, not the evidence camera. Let the
		# destination cells settle before asking for the eye's ground height;
		# otherwise the first frame can sample an unloaded height and put the
		# camera tens of metres above the trainer while later matched views do not.
		for i in 36:
			await physics_frame
		# The first cold destination can begin with an unloaded stand-height sample.
		# Re-seat the trainer only after Terrain3D has streamed around the requested
		# XZ; otherwise gravity can carry it far below the later-valid eye sample.
		stand_ground = float(world.call("ground_height_at", stand.x, stand.y))
		player.global_position = Vector3(stand.x, stand_ground + 0.35, stand.y)
		if player is CharacterBody3D:
			(player as CharacterBody3D).velocity = Vector3.ZERO
		for i in 12:
			await physics_frame
		var eye_xz := stand - toward * CAMERA_BACK_M
		var eye_ground := float(world.call("ground_height_at", eye_xz.x, eye_xz.y))
		camera.global_position = Vector3(eye_xz.x, eye_ground + CAMERA_UP_M, eye_xz.y)
		var target_ground := float(world.call("ground_height_at", target.x, target.y))
		camera.look_at(Vector3(target.x, target_ground + float(view.aim_up), target.y), Vector3.UP)
		for i in 36:
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
			"grove_centre_distance_m": stand.distance_to(Vector2(-344.0, 5075.0)),
			"image_size": [image.get_width(), image.get_height()],
		})
		print("wrote %s" % path)

	var manifest := {
		"production_scene": SCENE,
		"named_location": "The Ironwood Grove",
		"fixture_disclosure": "Production Meadows scene with ordinary player, live Terrain3D, current scatter configuration, harvest nodes, pickups, props and encounters. Scatter loads the committed bake when fresh and regenerates live when workspace configuration is newer; the run log records which path served each receipt. HUD hidden for unobstructed art review; clear weather/time pin; 67-degree third-person camera at 5.2m stand-off. No progress, creature, prop or reward injection.",
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


static func approach_distance_m() -> float:
	var stand: Vector2 = VIEWS[0].stand
	return stand.distance_to(Vector2(-344.0, 5075.0))


func _wait_for_world(world: Node) -> bool:
	var deadline := Time.get_ticks_msec() + READY_TIMEOUT_MS
	while Time.get_ticks_msec() < deadline:
		if world.has_method("shell_build_complete") and bool(world.call("shell_build_complete")):
			return true
		await physics_frame
	return false
