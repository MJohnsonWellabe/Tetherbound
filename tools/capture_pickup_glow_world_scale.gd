extends SceneTree

## Matched full-scene proof for PICKUP-GLOW-FAR-CAP-0911. These three views
## reuse the Road Gate, Old Mill and Ironwood compositions that exposed small
## pickups becoming dominant additive orbs. One production-world load captures
## all three, avoiding three expensive independent Meadows boots.
##
## Run with a real Compatibility renderer (never --headless):
##   godot --path . --rendering-driver opengl3 --resolution 1280x720 \
##     --script tools/capture_pickup_glow_world_scale.gd

const SCENE := "res://scenes/world/meadows_playground.tscn"
const OUT_DIR := "res://ralph/reports/BROAD-VISUAL-0910/PICKUP-GLOW-FAR-CAP-R1"
const READY_TIMEOUT_MS := 420_000

const WORLD_VIEWS := [
	{"name": "02-old-mill-crossing-axis", "stand": Vector2(-151.0, 4185.0),
		"target": Vector2(-154.0, 4220.0), "back": 1.8, "up": 3.1, "aim_up": 4.0, "fov": 60.0},
	{"name": "03-ironwood-crafting-glade", "stand": Vector2(-320.0, 5098.0),
		"target": Vector2(-345.0, 5075.0), "back": 5.2, "up": 2.75, "aim_up": 4.8, "fov": 67.0},
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
	var gate := world.find_child("RoadGate", true, false) as Node3D
	if player == null or look == null or gate == null:
		push_error("capture requires production Player, WorldLook and RoadGate")
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
	_hide_overlays(world)

	var camera := Camera3D.new()
	camera.name = "PickupGlowWorldScaleEvidenceCamera"
	camera.far = 2000.0
	world.add_child(camera)
	camera.make_current()

	var records: Array[Dictionary] = []
	var failures: Array[String] = []
	# Terrain3D streams around the trainer, not this evidence camera. Park the
	# hidden trainer at the Road Gate before grading its established approach.
	var gate_xz := Vector2(gate.global_position.x, gate.global_position.z)
	player.global_position = Vector3(gate_xz.x, 0.0, gate_xz.y)
	for i in 36:
		await physics_frame
	var gate_ground := float(world.call("ground_height_at", gate_xz.x, gate_xz.y))
	player.global_position = Vector3(gate_xz.x, gate_ground + 0.35, gate_xz.y)
	for i in 12:
		await physics_frame
	for time_name: String in ["day", "night"]:
		_pin_clock(look, time_name)
		player.visible = false
		player.set_process(false)
		player.set_physics_process(false)
		camera.fov = 68.0
		camera.global_position = gate.to_global(Vector3(1.8, 1.72, -12.0))
		camera.look_at(gate.to_global(Vector3(0.0, 1.65, 0.0)), Vector3.UP)
		await _save_frame("01-road-gate-approach-%s" % time_name, camera, records, failures)

	for raw: Variant in WORLD_VIEWS:
		var view := raw as Dictionary
		for time_name: String in ["day", "night"]:
			_pin_clock(look, time_name)
			player.visible = true
			player.set_process(false)
			player.set_physics_process(false)
			var stand: Vector2 = view.stand
			var target: Vector2 = view.target
			var stand_ground := float(world.call("ground_height_at", stand.x, stand.y))
			player.global_position = Vector3(stand.x, stand_ground + 0.35, stand.y)
			if player is CharacterBody3D:
				(player as CharacterBody3D).velocity = Vector3.ZERO
			var toward := (target - stand).normalized()
			player.rotation.y = atan2(toward.x, toward.y)
			for i in 36:
				await physics_frame
			# Re-sample and re-seat after destination streaming. Cold first samples
			# can precede Terrain3D residency even when shell construction is done.
			stand_ground = float(world.call("ground_height_at", stand.x, stand.y))
			player.global_position = Vector3(stand.x, stand_ground + 0.35, stand.y)
			if player is CharacterBody3D:
				(player as CharacterBody3D).velocity = Vector3.ZERO
			for i in 12:
				await physics_frame
			var eye_xz := stand - toward * float(view.back)
			var eye_ground := float(world.call("ground_height_at", eye_xz.x, eye_xz.y))
			camera.fov = float(view.fov)
			camera.global_position = Vector3(eye_xz.x, eye_ground + float(view.up), eye_xz.y)
			var target_ground := float(world.call("ground_height_at", target.x, target.y))
			camera.look_at(Vector3(target.x, target_ground + float(view.aim_up), target.y), Vector3.UP)
			await _save_frame("%s-%s" % [str(view.name), time_name], camera, records, failures)

	var manifest := {
		"production_scene": SCENE,
		"change": "pickup glow far-screen cap 1.30 -> 1.0",
		"fixture_disclosure": "One production Meadows scene with current baked scatter, props, pickups and encounters. Reuses established Road Gate approach, Old Mill crossing-axis and Ironwood crafting-glade compositions at matched day/night. HUD/independent overlay hidden; clear weather/time pin. No pickup, light, prop, creature or progress injection.",
		"expected_frame_count": 6,
		"complete": failures.is_empty() and records.size() == 6,
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


func _save_frame(
	name: String, camera: Camera3D, records: Array[Dictionary], failures: Array[String]
) -> void:
	for i in 36:
		await physics_frame
	for i in 6:
		await process_frame
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	if image == null or image.is_empty():
		failures.append("%s: viewport returned no image" % name)
		return
	var path := "%s/%s.png" % [OUT_DIR, name]
	if image.save_png(path) != OK:
		failures.append("%s: save_png failed" % name)
		return
	records.append({
		"frame": name,
		"camera_global": [camera.global_position.x, camera.global_position.y, camera.global_position.z],
		"image_size": [image.get_width(), image.get_height()],
	})
	print("wrote %s" % path)


func _pin_clock(look: Node, time_name: String) -> void:
	look.call("apply_time", time_name)
	if look.has_method("set_clock_frozen"):
		look.call("set_clock_frozen", true)


func _hide_overlays(world: Node) -> void:
	var hud := world.get_node_or_null(^"PlaygroundHUD") as CanvasLayer
	if hud != null:
		hud.visible = false
	var submersion := world.get_node_or_null(^"Water/SubmersionOverlay") as CanvasLayer
	if submersion != null:
		submersion.visible = false


func _wait_for_world(world: Node) -> bool:
	var deadline := Time.get_ticks_msec() + READY_TIMEOUT_MS
	while Time.get_ticks_msec() < deadline:
		if world.has_method("shell_build_complete") and bool(world.call("shell_build_complete")):
			return true
		await physics_frame
	return false
