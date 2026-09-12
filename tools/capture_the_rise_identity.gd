extends SceneTree

## Production-scene proof for The Rise's corrected tree-and-stone crown.
## Run only through the coordinated real Compatibility-renderer lane:
##   godot --path . --rendering-driver opengl3 --resolution 1280x720 \
##     --script tools/capture_the_rise_identity.gd

const SCENE := "res://scenes/world/meadows_playground.tscn"
const OUT_DIR := "res://ralph/reports/BROAD-VISUAL-0910/THE-RISE-IDENTITY-R3-OPEN-CROWN"
const READY_TIMEOUT_MS := 420_000
const HERO_NODE := ^"Props/the_rise_rock_crown/RiseHeroTree"

const VIEWS := [
	{"name": "01-road-approach", "stand": Vector2(52.0, -28.0),
		"target": Vector2(99.5, -55.0), "aim_up": 8.0, "back": 2.5, "up": 3.0, "fov": 60.0},
	{"name": "02-road-end-crown", "stand": Vector2(74.0, -41.0),
		"target": Vector2(99.5, -55.0), "aim_up": 8.0, "back": 2.5, "up": 3.0, "fov": 60.0},
	{"name": "03-region-standing-matched", "stand": Vector2(74.0, -41.0),
		"target": Vector2(99.5, -55.0), "aim_up": 7.0, "back": 3.2, "up": 2.8, "fov": 65.0},
	{"name": "04-west-foot-profile", "stand": Vector2(61.0, -69.0),
		"target": Vector2(99.5, -55.0), "aim_up": 7.0, "back": 2.5, "up": 3.2, "fov": 58.0},
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
	var hero := world.get_node_or_null(HERO_NODE) as Node3D
	if player == null or look == null or hero == null:
		push_error("capture requires production Player, WorldLook and RiseHeroTree")
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
	player.set_process(false)
	player.set_physics_process(false)
	_hide_overlays(world)

	var camera := Camera3D.new()
	camera.name = "TheRiseEvidenceCamera"
	camera.far = 1200.0
	world.add_child(camera)
	camera.make_current()

	var records: Array[Dictionary] = []
	var failures: Array[String] = []
	for raw: Variant in VIEWS:
		var view := raw as Dictionary
		for time_name: String in ["day", "night"]:
			_pin_clock(look, time_name)
			var stand: Vector2 = view.stand
			var target: Vector2 = view.target
			var ground := float(world.call("ground_height_at", stand.x, stand.y))
			player.global_position = Vector3(stand.x, ground + 0.35, stand.y)
			if player is CharacterBody3D:
				(player as CharacterBody3D).velocity = Vector3.ZERO
			var toward := (target - stand).normalized()
			player.rotation.y = atan2(toward.x, toward.y)
			var eye_xz := stand - toward * float(view.back)
			camera.fov = float(view.fov)
			camera.global_position = Vector3(eye_xz.x,
				float(world.call("ground_height_at", eye_xz.x, eye_xz.y)) + float(view.up), eye_xz.y)
			camera.look_at(Vector3(target.x,
				float(world.call("ground_height_at", target.x, target.y)) + float(view.aim_up), target.y),
				Vector3.UP)
			for i in 10:
				await process_frame
			_hide_overlays(world)
			await RenderingServer.frame_post_draw
			var image := root.get_texture().get_image()
			var frame_name := "%s-%s" % [str(view.name), time_name]
			if image == null or image.is_empty():
				failures.append("%s: viewport returned no image" % frame_name)
				continue
			var path := "%s/%s.png" % [OUT_DIR, frame_name]
			if image.save_png(path) != OK:
				failures.append("%s: save_png failed" % frame_name)
				continue
			records.append({
				"frame": frame_name,
				"time": time_name,
				"player_xz": [stand.x, stand.y],
				"hero_distance_m": stand.distance_to(Vector2(hero.global_position.x, hero.global_position.z)),
				"image_size": [image.get_width(), image.get_height()],
			})
			print("wrote %s" % path)

	var manifest := {
		"production_scene": SCENE,
		"named_location": "The Rise",
		"fixture_disclosure": "Production Meadows scene with ordinary trainer, live Terrain3D, authoritative scatter, props, encounters and both authored roads. Player locomotion is frozen after exact road-position placement; clear day/night clocks are frozen; HUD and independent SubmersionOverlay are hidden. No scene content or progression is injected.",
		"complete": failures.is_empty() and records.size() == VIEWS.size() * 2,
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


func _pin_clock(look: Node, time_name: String) -> void:
	look.call("apply_time", time_name)
	if look.has_method("set_clock_frozen"):
		look.call("set_clock_frozen", true)
	look.set_process(false)
	look.set_physics_process(false)


func _hide_overlays(world: Node) -> void:
	var hud := world.get_node_or_null(^"PlaygroundHUD") as CanvasLayer
	if hud != null:
		hud.visible = false
	var submersion := world.get_node_or_null(^"Water/SubmersionOverlay") as CanvasLayer
	if submersion != null:
		submersion.visible = false
	for child: Node in root.get_children():
		if child is CanvasLayer:
			(child as CanvasLayer).visible = false


func _wait_for_world(world: Node) -> bool:
	var deadline := Time.get_ticks_msec() + READY_TIMEOUT_MS
	while Time.get_ticks_msec() < deadline:
		if world.has_method("shell_build_complete") and bool(world.call("shell_build_complete")):
			return true
		await physics_frame
	return false
