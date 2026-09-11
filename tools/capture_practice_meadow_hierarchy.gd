extends SceneTree

## Dedicated production proof for the Practice Meadow / tournament hierarchy.
## Loads the shipped Meadows world with ordinary player, HUD, Terrain3D,
## scatter, encounters, relic circle and tournament systems. Only clear weather
## and time are pinned. Do not substitute tools/_capture_locations.gd.

const SCENE := "res://scenes/world/meadows_playground.tscn"
const OUT_DIR := "res://ralph/reports/BROAD-VISUAL-0910/PRACTICE-MEADOW-HIERARCHY-R5"
const READY_TIMEOUT_MS := 420_000
const CAMERA_BACK_M := 5.2
const CAMERA_UP_M := 2.65
const FOV := 70.0

const VIEWS := [
	# Both primary frames stand inside the open lists. They prove the marked
	# fight floor, bracket and installed marshal stall together without putting
	# a village building between the production camera and its subject.
	{"name": "01-lists-board-stall-day", "stand": Vector2(22.0, 9.0), "target": Vector2(20.2, 16.1), "time": "day", "aim_up": 2.45},
	{"name": "02-lists-board-stall-night", "stand": Vector2(22.0, 9.0), "target": Vector2(20.2, 16.1), "time": "night", "aim_up": 2.45},
	# Two unobstructed in-field shoulders look outward at the varied equipment.
	# Both cameras remain inside the lists rather than backing into the cottage,
	# boundary fence or the tree that invalidated R2's reverse view.
	{"name": "03-equipment-side-day", "stand": Vector2(30.6, -1.7), "target": Vector2(33.7, -5.9), "time": "day", "aim_up": 1.25, "player_offset_m": 1.35},
	{"name": "04-equipment-side-night", "stand": Vector2(30.6, -1.7), "target": Vector2(33.7, -5.9), "time": "night", "aim_up": 1.25, "player_offset_m": 1.35},
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
	var hud := world.get_node_or_null(^"PlaygroundHUD") as CanvasLayer
	if hud != null:
		hud.visible = false
	# The water hazard feedback is an independent CanvasLayer, not a child of
	# PlaygroundHUD. Suppress it explicitly so a delayed hazard update cannot
	# tint a dry Meadows location proof.
	var submersion_overlay := world.find_child("SubmersionOverlay", true, false) as CanvasLayer
	if submersion_overlay != null:
		submersion_overlay.visible = false
	if weather != null:
		if weather.has_method("set_weather"):
			weather.call("set_weather", "clear")
		weather.set_process(false)
		weather.set_physics_process(false)
	look.set_process(false)
	look.set_physics_process(false)
	if look.has_method("set_clock_frozen"):
		look.call("set_clock_frozen", true)
	# The harness moves the visible player to terrain-derived stands itself.
	# Disable locomotion/gravity so capture settle frames cannot drift that pose.
	player.set_process(false)
	player.set_physics_process(false)
	if player is CharacterBody3D:
		(player as CharacterBody3D).velocity = Vector3.ZERO

	var camera := Camera3D.new()
	camera.name = "PracticeMeadowEvidenceCamera"
	camera.fov = FOV
	camera.far = 2000.0
	world.add_child(camera)
	camera.make_current()
	var records: Array[Dictionary] = []
	var failures: Array[String] = []
	for raw: Variant in VIEWS:
		var view := raw as Dictionary
		look.call("apply_time", str(view.time))
		if look.has_method("set_clock_frozen"):
			look.call("set_clock_frozen", true)
		var stand: Vector2 = view.stand
		var target: Vector2 = view.target
		var ground := float(world.call("ground_height_at", stand.x, stand.y))
		if is_nan(ground):
			failures.append("%s: no valid terrain under player stand" % str(view.name))
			continue
		var toward := (target - stand).normalized()
		var player_xz := stand + Vector2(-toward.y, toward.x) * float(view.get("player_offset_m", 0.0))
		var player_ground := float(world.call("ground_height_at", player_xz.x, player_xz.y))
		if is_nan(player_ground):
			failures.append("%s: no valid terrain under offset player stand" % str(view.name))
			continue
		player.global_position = Vector3(player_xz.x, player_ground + 0.35, player_xz.y)
		if player is CharacterBody3D:
			(player as CharacterBody3D).velocity = Vector3.ZERO
		player.rotation.y = atan2(toward.x, toward.y)
		var eye_xz := stand - toward * CAMERA_BACK_M
		var eye_ground := float(world.call("ground_height_at", eye_xz.x, eye_xz.y))
		if is_nan(eye_ground):
			failures.append("%s: no valid terrain under camera stand" % str(view.name))
			continue
		camera.global_position = Vector3(eye_xz.x, eye_ground + CAMERA_UP_M, eye_xz.y)
		var target_ground := float(world.call("ground_height_at", target.x, target.y))
		if is_nan(target_ground):
			failures.append("%s: no valid terrain under camera target" % str(view.name))
			continue
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
			"player_xz": [player_xz.x, player_xz.y],
			"camera_to_player_m": camera.global_position.distance_to(player.global_position),
			"image_size": [image.get_width(), image.get_height()],
		})
		print("wrote %s" % path)

	var manifest := {
		"production_scene": SCENE,
		"named_location": "Practice Meadow / tournament ground",
		"fixture_disclosure": "Production Meadows scene with ordinary player, HUD, Terrain3D, scatter, encounters, shrine circle and tournament. Clear weather/time pin; production 70-degree third-person camera. No progress or encounter injection.",
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
