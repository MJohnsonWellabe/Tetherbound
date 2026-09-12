extends SceneTree

## Focused production-scene evidence for The Broken Tower hard-pass candidate.
## It proves the real southwest route silhouette, the installed entry arch and
## the former-watch remnants from ordinary player height at both authored clocks.
## Run with the Windows Compatibility renderer, never `--headless`.

const SCENE := "res://scenes/world/meadows_playground.tscn"
const OUT_DIR := "res://ralph/reports/BROAD-VISUAL-0910/BROKEN-TOWER-HARD-PASS-R3-AIMED-WASH"
const READY_TIMEOUT_MS := 420_000
const SITE := Vector2(40.0, 6800.0)
const CAMERA_BACK_M := 5.2
const CAMERA_UP_M := 2.7
const FOV := 70.0

const VIEWS := [
	{"name": "01-route-arrival", "at": Vector2(12.0, 6762.0), "aim_up": 6.0},
	{"name": "02-arched-threshold", "at": Vector2(27.0, 6783.0), "aim_up": 4.4},
	{"name": "03-watch-remnants", "at": Vector2(34.0, 6792.0), "aim_up": 5.1},
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

	var tower := world.get_node_or_null(^"RuinedWatchtower") as Node3D
	var player := world.get_node_or_null(^"Player") as Node3D
	var look := world.get_node_or_null(^"WorldLook")
	var weather := world.get_node_or_null(^"WorldWeather")
	var rig := world.get_node_or_null(^"CameraRig")
	if tower == null or player == null or look == null:
		push_error("capture requires RuinedWatchtower, Player and WorldLook")
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
	var hud := world.get_node_or_null(^"PlaygroundHUD") as CanvasLayer
	if hud != null:
		hud.visible = false
	var overlay := world.find_child("SubmersionOverlay", true, false) as CanvasLayer
	if overlay != null:
		overlay.visible = false

	var camera := Camera3D.new()
	camera.name = "BrokenTowerEvidenceCamera"
	camera.fov = FOV
	camera.far = 2000.0
	world.add_child(camera)
	camera.make_current()

	var records: Array[Dictionary] = []
	var failures: Array[String] = []
	for time: String in ["day", "night"]:
		look.call("apply_time", time)
		if look.has_method("set_clock_frozen"):
			look.call("set_clock_frozen", true)
		for raw: Variant in VIEWS:
			var view := raw as Dictionary
			var stand: Vector2 = view.at
			var stand_ground := float(world.call("ground_height_at", stand.x, stand.y))
			if is_nan(stand_ground):
				failures.append("%s-%s: no stand ground" % [view.name, time])
				continue
			player.global_position = Vector3(stand.x, stand_ground + 0.35, stand.y)
			if player is CharacterBody3D:
				(player as CharacterBody3D).velocity = Vector3.ZERO
			var toward := (SITE - stand).normalized()
			player.rotation.y = atan2(toward.x, toward.y)
			# Terrain3D streams around the player. The R2 long-arrival camera sampled
			# its eye before that cell settled and ended 37 m from the actor despite
			# the disclosed 5.2 m stand-off. Settle first, then pin the actor again.
			for i in 36:
				await physics_frame
			player.global_position = Vector3(stand.x, stand_ground + 0.35, stand.y)
			if player is CharacterBody3D:
				(player as CharacterBody3D).velocity = Vector3.ZERO
			var eye_xz := stand - toward * CAMERA_BACK_M
			var eye_ground := float(world.call("ground_height_at", eye_xz.x, eye_xz.y))
			if is_nan(eye_ground):
				failures.append("%s-%s: no camera ground" % [view.name, time])
				continue
			camera.global_position = Vector3(eye_xz.x, eye_ground + CAMERA_UP_M, eye_xz.y)
			var target_ground := float(world.call("ground_height_at", SITE.x, SITE.y))
			camera.look_at(Vector3(SITE.x, target_ground + float(view.aim_up), SITE.y), Vector3.UP)
			for i in 72:
				await physics_frame
			for i in 6:
				await process_frame
			await RenderingServer.frame_post_draw
			var image := root.get_texture().get_image()
			var name := "%s-%s" % [view.name, time]
			if image == null or image.is_empty():
				failures.append("%s: viewport returned no image" % name)
				continue
			var path := "%s/%s.png" % [OUT_DIR, name]
			if image.save_png(path) != OK:
				failures.append("%s: save_png failed" % name)
				continue
			records.append({
				"frame": name,
				"time": time,
				"player_xz": [player.global_position.x, player.global_position.z],
				"tower_distance_m": stand.distance_to(SITE),
				"camera_to_player_m": camera.global_position.distance_to(player.global_position),
				"image_size": [image.get_width(), image.get_height()],
			})
			print("wrote %s" % path)

	var manifest := {
		"schema_version": 1,
		"production_scene": SCENE,
		"named_location": "The Broken Tower",
		"runtime_node": "RuinedWatchtower",
		"fixture_disclosure": "Production Meadows scene, ordinary player body, clear authored day/night, HUD/feedback overlays hidden, production-equivalent 70-degree third-person camera at 5.2m stand-off. No progress, encounter, terrain, vegetation, light or landmark injection.",
		"expected_frame_count": VIEWS.size() * 2,
		"complete": failures.is_empty() and records.size() == VIEWS.size() * 2,
		"frames": records,
		"failures": failures,
		"capture_finished_utc": Time.get_datetime_string_from_system(true),
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
