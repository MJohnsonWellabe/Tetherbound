extends SceneTree

## Dedicated production-scene evidence for Stronghold Approach. This loads the
## shipped Meadows scene, keeps its ordinary player/scatter/props/encounters,
## pins clear weather and an authored clock, and hides only independent screen
## overlays. Four route-authored views prove the occupation sequence and final
## Hall reveal in both day and night without changing progress or encounters.
## It deliberately does not share or modify tools/_capture_locations.gd.
##
## Run with a real Compatibility renderer:
##   godot --path . --rendering-driver opengl3 --resolution 1280x720 \
##     --script tools/capture_stronghold_approach_identity.gd

const SCENE := "res://scenes/world/meadows_playground.tscn"
const OUT_DIR := "res://ralph/reports/BROAD-VISUAL-0910/STRONGHOLD-APPROACH-VERTICAL-STANDARDS-R3"
const READY_TIMEOUT_MS := 420_000
const HALL := Vector2(0.0, 7560.0)

const VIEWS := [
	{"name": "01-outer-watch-arrival", "stand": Vector2(0.0, 7000.0),
		"target": Vector2(-67.0, 7145.0), "aim_up": 3.5, "back": 2.0, "up": 3.0, "fov": 60.0},
	{"name": "02-road-drop", "stand": Vector2(-20.0, 7250.0),
		"target": Vector2(14.0, 7281.0), "aim_up": 2.8, "back": 1.8, "up": 3.0, "fov": 58.0},
	{"name": "03-processional-reveal", "stand": Vector2(75.0, 7390.0),
		"target": HALL, "aim_up": 14.0, "back": 2.2, "up": 3.3, "fov": 56.0},
	{"name": "04-hallward-overlook", "stand": Vector2(20.0, 7480.0),
		"target": HALL, "aim_up": 15.0, "back": 1.8, "up": 3.2, "fov": 54.0},
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
	_hide_overlays(world)

	var camera := Camera3D.new()
	camera.name = "StrongholdApproachEvidenceCamera"
	camera.far = 2000.0
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
			var ground := _surface(world, stand, player)
			player.global_position = Vector3(stand.x, ground + 0.35, stand.y)
			if player is CharacterBody3D:
				(player as CharacterBody3D).velocity = Vector3.ZERO
			var toward := (target - stand).normalized()
			player.rotation.y = atan2(toward.x, toward.y)
			var eye_xz := stand - toward * float(view.back)
			var eye_ground := _surface(world, eye_xz, player)
			camera.fov = float(view.fov)
			camera.global_position = Vector3(eye_xz.x, eye_ground + float(view.up), eye_xz.y)
			var target_ground := float(world.call("ground_height_at", target.x, target.y))
			camera.look_at(Vector3(target.x, target_ground + float(view.aim_up), target.y), Vector3.UP)
			# The first long-distance stand begins outside the collision-streaming
			# ring around spawn. Give the stream one settle pass, then seat again
			# on the now-live surface before recording. Without this second seat
			# only the first day frame can fall while its Terrain3D collision tile
			# arrives; the following night frame at the same XZ is already warm.
			for i in 60:
				await physics_frame
			ground = _surface(world, stand, player)
			player.global_position = Vector3(stand.x, ground + 0.35, stand.y)
			if player is CharacterBody3D:
				(player as CharacterBody3D).velocity = Vector3.ZERO
			for i in 60:
				await physics_frame
			var settled_xz := Vector2(player.global_position.x, player.global_position.z)
			if player.global_position.y < _surface(world, settled_xz, player) - 0.15:
				failures.append("%s-%s: player below live surface" % [str(view.name), time_name])
				continue
			_hide_overlays(world)
			for i in 6:
				await process_frame
			await RenderingServer.frame_post_draw
			var image := root.get_texture().get_image()
			if image == null or image.is_empty():
				failures.append("%s-%s: viewport returned no image" % [str(view.name), time_name])
				continue
			var frame_name := "%s-%s" % [str(view.name), time_name]
			var path := "%s/%s.png" % [OUT_DIR, frame_name]
			if image.save_png(path) != OK:
				failures.append("%s: save_png failed" % frame_name)
				continue
			records.append({
				"frame": frame_name,
				"time": time_name,
				"player_xz": [stand.x, stand.y],
				"camera_to_player_m": camera.global_position.distance_to(player.global_position),
				"hall_distance_m": stand.distance_to(HALL),
				"image_size": [image.get_width(), image.get_height()],
			})
			print("wrote %s" % path)

	var manifest := {
		"production_scene": SCENE,
		"named_location": "Stronghold Approach",
		"fixture_disclosure": "Production Meadows scene with ordinary player, live Terrain3D, scatter, props, harvestables and encounters. Authored day/night clock applied then frozen; clear weather; HUD and independent SubmersionOverlay hidden. Live collision-surface seating. No progress, encounter, route or Hall injection.",
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


func _surface(world: Node3D, at: Vector2, player: Node3D) -> float:
	var analytic := float(world.call("ground_height_at", at.x, at.y))
	# Keep the live proof local to the authored terrain surface. A +/-100 m ray
	# can hit an encounter body, banner, or scaffold above the road and call
	# that temporary collider "ground"; the first outer-watch day frame caught
	# exactly that and then (correctly, but misleadingly) rejected the trainer
	# as underground. Terrain3D and its route dressing stay within this bounded
	# neighbourhood of the analytic surface at every authored stand below.
	var query := PhysicsRayQueryParameters3D.create(
		Vector3(at.x, analytic + 4.0, at.y),
		Vector3(at.x, analytic - 6.0, at.y))
	query.collide_with_areas = false
	if player is CollisionObject3D:
		query.exclude = [(player as CollisionObject3D).get_rid()]
	var hit := world.get_world_3d().direct_space_state.intersect_ray(query)
	return analytic if hit.is_empty() else float((hit.position as Vector3).y)


func _wait_for_world(world: Node) -> bool:
	var deadline := Time.get_ticks_msec() + READY_TIMEOUT_MS
	while Time.get_ticks_msec() < deadline:
		if world.has_method("shell_build_complete") and bool(world.call("shell_build_complete")):
			return true
		await physics_frame
	return false
