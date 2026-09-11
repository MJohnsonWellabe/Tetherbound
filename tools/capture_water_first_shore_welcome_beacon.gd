extends SceneTree

## Dedicated production-scene receipt for the First Shore welcome beacon and
## its R2 torch-cairn approach. This does not mutate progression or actors.
## Run with a real Compatibility renderer (never --headless):
##   godot --path . --rendering-driver opengl3 --resolution 1280x720 \
##     --script tools/capture_water_first_shore_welcome_beacon.gd

const SCENE := "res://scenes/world/water_archipelago.tscn"
const OUT_DIR := "res://ralph/reports/FOUR-BIOME-CONTINUATION-0910/FIRST-SHORE-WELCOME-BEACON-R3"
const READY_TIMEOUT_MS := 420_000
const CAMERA_BACK_M := 5.2
const CAMERA_UP_M := 2.8
const VIEWS := [
	{"name": "01-canonical-day", "stand": Vector2(35.707, 98.104),
		"target": Vector2(16.0, 98.0), "time": "day", "aim_up": 2.7},
	{"name": "02-canonical-night", "stand": Vector2(35.707, 98.104),
		"target": Vector2(16.0, 98.0), "time": "night", "aim_up": 2.7},
	{"name": "03-threshold-day", "stand": Vector2(28.0, 98.0),
		"target": Vector2(16.0, 98.0), "time": "day", "aim_up": 2.4},
	{"name": "04-threshold-night", "stand": Vector2(28.0, 98.0),
		"target": Vector2(16.0, 98.0), "time": "night", "aim_up": 2.4},
]


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("First Shore welcome capture requires a rendering display")
		quit(1)
		return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))
	var game := root.get_node_or_null(^"Game")
	if game != null:
		game.call("reset_for_new_game")
		game.set("current_realm", "water")
	var packed := load(SCENE) as PackedScene
	if packed == null:
		push_error("could not load production Water scene")
		quit(1)
		return
	var world := packed.instantiate() as Node3D
	root.add_child(world)
	current_scene = world
	if not await _wait_for_world(world):
		push_error("production Water scene did not finish building")
		quit(1)
		return
	var player := world.get_node_or_null(^"Player") as Node3D
	var look := world.get_node_or_null(^"WorldLook")
	var rig := world.get_node_or_null(^"CameraRig")
	var site := world.get_node_or_null(^"FirstShoreWelcomeBeacon") as Node3D
	if player == null or look == null or site == null:
		push_error("capture requires production Player, WorldLook and welcome beacon")
		quit(1)
		return
	for required: String in ["WelcomeArch", "WelcomeMarkerTorchSouth", "WelcomeMarkerTorchNorth"]:
		if site.get_node_or_null(required) == null:
			push_error("welcome beacon is missing %s" % required)
			quit(1)
			return
	if rig != null:
		rig.set_process(false)
		rig.set_physics_process(false)
	player.set_process(false)
	player.set_physics_process(false)
	_hide_overlays(world)
	var camera := Camera3D.new()
	camera.name = "FirstShoreWelcomeEvidenceCamera"
	camera.fov = 64.0
	camera.far = 2400.0
	world.add_child(camera)
	camera.make_current()

	var records: Array[Dictionary] = []
	var failures: Array[String] = []
	for raw: Variant in VIEWS:
		var view := raw as Dictionary
		look.call("apply_time", str(view.time))
		if look.has_method("set_clock_frozen"):
			look.call("set_clock_frozen", true)
		look.set_process(false)
		look.set_physics_process(false)
		var stand: Vector2 = view.stand
		var target: Vector2 = view.target
		var stand_y := float(world.call("ground_height_at", stand.x, stand.y))
		var target_y := float(world.call("ground_height_at", target.x, target.y))
		if not is_finite(stand_y) or not is_finite(target_y):
			failures.append("%s: non-finite production ground" % str(view.name))
			continue
		player.global_position = Vector3(stand.x, stand_y + 0.35, stand.y)
		if player is CharacterBody3D:
			(player as CharacterBody3D).velocity = Vector3.ZERO
		var toward := (target - stand).normalized()
		player.rotation.y = atan2(toward.x, toward.y)
		var eye := stand - toward * CAMERA_BACK_M
		var eye_y := float(world.call("ground_height_at", eye.x, eye.y))
		camera.global_position = Vector3(eye.x, eye_y + CAMERA_UP_M, eye.y)
		camera.look_at(Vector3(target.x, target_y + float(view.aim_up), target.y), Vector3.UP)
		for frame in 48:
			await physics_frame
		for frame in 6:
			await process_frame
		await RenderingServer.frame_post_draw
		var actual := Vector2(player.global_position.x, player.global_position.z)
		if actual.distance_to(stand) > 0.25:
			failures.append("%s: player left authored stand" % str(view.name))
			continue
		var image := root.get_texture().get_image()
		if image == null or image.is_empty() \
				or image.save_png("%s/%s.png" % [OUT_DIR, str(view.name)]) != OK:
			failures.append("%s: capture failed" % str(view.name))
			continue
		records.append({"frame": str(view.name), "time": str(view.time),
			"stand_xz": [stand.x, stand.y], "image_size": [image.get_width(), image.get_height()],
			"beacon_distance_m": stand.distance_to(Vector2(16.0, 98.0))})
	var manifest := {"production_scene": SCENE, "named_location": "First Shore Welcome Beacon",
		"fixture_disclosure": "Production Water scene and ordinary player; fixed evidence camera, clear authored time, HUD hidden. No encounter, route or progression injection.",
		"complete": failures.is_empty() and records.size() == VIEWS.size(),
		"frames": records, "failures": failures}
	var file := FileAccess.open("%s/manifest.json" % OUT_DIR, FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(manifest, "\t") + "\n")
		file.close()
	else:
		failures.append("manifest could not be written")
	quit(0 if failures.is_empty() else 1)


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
