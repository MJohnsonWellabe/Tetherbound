extends SceneTree

## Dedicated production-scene evidence for Grandpa's House and its south-east
## worked yard. The shared locations sweep is intentionally not edited here.
##
## This harness closes three evidence-only failure modes found during the Inn
## reproof: the requested clock is applied before it is frozen, the independent
## water hazard overlay is hidden alongside the HUD, and player/camera seating
## comes from the live collision surface rather than an analytic height that can
## put the ordinary trainer underground.

const SCENE := "res://scenes/world/meadows_playground.tscn"
const OUT_DIR := "res://ralph/reports/FOUR-BIOME-CONTINUATION-0910/GRANDPA-YARD-IDENTITY"
const READY_TIMEOUT_MS := 420_000
const STAND := Vector2(-8.5, -23.0)
const TARGET := Vector2(-15.7, -16.0)
const CAMERA_BACK_M := 1.5
const CAMERA_UP_M := 2.5
const AIM_UP_M := 1.3
const FOV := 70.0

const VIEWS := [
	{"name": "01-grandpa-yard-day", "time": "day"},
	{"name": "02-grandpa-yard-night", "time": "night"},
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
	for i in 30:
		await physics_frame

	var player := world.get_node_or_null(^"Player") as Node3D
	var look := world.get_node_or_null(^"WorldLook")
	var weather := world.get_node_or_null(^"WorldWeather")
	var rig := world.get_node_or_null(^"CameraRig")
	if player == null or look == null:
		push_error("capture requires production Player and WorldLook")
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
	camera.name = "GrandpaYardEvidenceCamera"
	camera.fov = FOV
	camera.far = 2000.0
	world.add_child(camera)
	camera.make_current()

	var stand_ground := _surface(world, STAND)
	var toward := (TARGET - STAND).normalized()
	var eye_xz := STAND - toward * CAMERA_BACK_M
	var eye_ground := _surface(world, eye_xz)
	# Target height deliberately comes from the production terrain API, not a
	# downward ray that could report the farmhouse roof as "ground".
	var target_ground := float(world.call("ground_height_at", TARGET.x, TARGET.y))
	var records: Array[Dictionary] = []
	var failures: Array[String] = []
	for raw: Variant in VIEWS:
		var view := raw as Dictionary
		_pin_clock(look, str(view.time))
		player.global_position = Vector3(STAND.x, stand_ground + 0.45, STAND.y)
		if player is CharacterBody3D:
			(player as CharacterBody3D).velocity = Vector3.ZERO
		player.rotation.y = atan2(toward.x, toward.y)
		camera.global_position = Vector3(eye_xz.x, eye_ground + CAMERA_UP_M, eye_xz.y)
		camera.look_at(Vector3(TARGET.x, target_ground + AIM_UP_M, TARGET.y), Vector3.UP)
		for i in 60:
			await physics_frame
		if player.global_position.y < stand_ground - 0.05:
			failures.append("%s: player settled below the live yard surface" % str(view.name))
			continue
		_hide_overlays(world)
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
			"player_xz": [STAND.x, STAND.y],
			"player_ground_y": stand_ground,
			"player_y": player.global_position.y,
			"camera_to_player_m": camera.global_position.distance_to(player.global_position),
			"image_size": [image.get_width(), image.get_height()],
		})
		print("wrote %s" % path)

	var manifest := {
		"production_scene": SCENE,
		"named_location": "Grandpa's House",
		"fixture_disclosure": "Production Meadows scene with ordinary player, Terrain3D, scatter, farm, props and NPCs. Authored day/night clock applied then frozen; weather clear; PlaygroundHUD and Water/SubmersionOverlay hidden. Live collision-surface player/camera seating; no progress, farm-state, encounter or route injection.",
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


func _pin_clock(look: Node, time_name: String) -> void:
	# Apply first. Freezing first is the shared-sweep bug: its modern branch
	# never calls apply_time at all and merely freezes whichever clock was live.
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


func _surface(world: Node3D, at: Vector2) -> float:
	var analytic := float(world.call("ground_height_at", at.x, at.y))
	var space := world.get_world_3d().direct_space_state
	var query := PhysicsRayQueryParameters3D.create(
		Vector3(at.x, analytic + 100.0, at.y),
		Vector3(at.x, analytic - 100.0, at.y))
	query.collide_with_areas = false
	var hit := space.intersect_ray(query)
	return analytic if hit.is_empty() else float((hit.position as Vector3).y)


func _wait_for_world(world: Node) -> bool:
	var deadline := Time.get_ticks_msec() + READY_TIMEOUT_MS
	while Time.get_ticks_msec() < deadline:
		if world.has_method("shell_build_complete") and bool(world.call("shell_build_complete")):
			return true
		await physics_frame
	return false
