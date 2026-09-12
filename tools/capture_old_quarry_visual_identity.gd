extends SceneTree

## Dedicated current-production proof for The Old Quarry after the creature-scale
## and consolidated Meadows scatter passes. Does not edit world state, actors,
## quarry art, or the generic location harness.
##
## Windows production command (Compatibility renderer; deliberately no headless):
##   godot --path . --rendering-driver opengl3 --resolution 1280x720 \
##     --script tools/capture_old_quarry_visual_identity.gd

const SCENE := "res://scenes/world/meadows_playground.tscn"
const OUT_DIR := "res://ralph/reports/BROAD-VISUAL-0910/OLD-QUARRY-CUT-FACE-R5B"
const READY_TIMEOUT_MS := 420_000
const SHOTS := [
	{
		"label": "01-arrival", "stand": Vector2(380.0, 1820.0),
		"target": Vector2(400.0, 1800.0), "back": 2.0, "up": 3.0,
		"aim_up": 2.0, "fov": 62.0,
	},
	{
		"label": "02-worked-floor", "stand": Vector2(400.0, 1803.0),
		"target": Vector2(418.0, 1764.0), "back": 2.0, "up": 2.5,
		"aim_up": 2.0, "fov": 64.0,
	},
	{
		# Back off along the actual pylon sightline rather than the old 399,1809
		# close crop whose foreground deadfall/foundation edge hid the machine.
		"label": "03-conduit-head", "stand": Vector2(392.0, 1812.0),
		"target": Vector2(404.0, 1804.0), "back": 1.5, "up": 2.6,
		"aim_up": 1.7, "fov": 58.0,
	},
	{
		# Reverse shoulder view: proves the installed-rock mass reads as a cut
		# wall behind the low extraction gear rather than blocking the live spine.
		"label": "04-cut-face", "stand": Vector2(407.0, 1818.0),
		"target": Vector2(383.0, 1803.0), "back": 2.0, "up": 3.0,
		"aim_up": 2.4, "fov": 62.0,
	},
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
	var camera := Camera3D.new()
	camera.name = "OldQuarryVisualEvidenceCamera"
	camera.far = 2000.0
	world.add_child(camera)
	camera.make_current()
	_hide_overlays(world)

	var records: Array[Dictionary] = []
	var failures: Array[String] = []
	var grounding: Dictionary = {}
	for time_name: String in ["day", "night"]:
		grounding[time_name] = {}
		for shot: Dictionary in SHOTS:
			var result := await _capture(world, player, look, camera, shot, time_name,
				records, failures)
			(grounding[time_name] as Dictionary)[str(shot["label"])] = result
	for shot: Dictionary in SHOTS:
		var label := str(shot["label"])
		var day: Dictionary = (grounding.get("day", {}) as Dictionary).get(label, {})
		var night: Dictionary = (grounding.get("night", {}) as Dictionary).get(label, {})
		if absf(float(day.get("surface_y", INF)) - float(night.get("surface_y", -INF))) > 0.05:
			failures.append("%s day/night sampled different live ground surfaces" % label)
		if absf(float(day.get("player_ground_delta", INF))) > 0.75 \
				or absf(float(night.get("player_ground_delta", INF))) > 0.75:
			failures.append("%s player did not remain grounded in both frames" % label)

	var manifest := {
		"production_scene": SCENE,
		"named_location": "The Old Quarry",
		"fixture_disclosure": "Production Meadows scene with current Terrain3D, consolidated scatter, vegetation, quarry art, player, props, gatherables and live encounters. Clear authored day/night; HUD and independent SubmersionOverlay hidden. No actor relocation, progression state, or production art mutation.",
		"complete": failures.is_empty() and records.size() == SHOTS.size() * 2,
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


func _capture(world: Node3D, player: Node3D, look: Node, camera: Camera3D,
		shot: Dictionary, time_name: String, records: Array[Dictionary],
		failures: Array[String]) -> Dictionary:
	_pin_clock(look, time_name)
	var stand: Vector2 = shot["stand"]
	var target: Vector2 = shot["target"]
	var toward := (target - stand).normalized()
	var eye_xz := stand - toward * float(shot["back"])
	camera.fov = float(shot["fov"])
	camera.global_position = Vector3(eye_xz.x,
		_surface(world, eye_xz, player) + float(shot["up"]), eye_xz.y)
	var target_y := float(world.call("ground_height_at", target.x, target.y))
	camera.look_at(Vector3(target.x, target_y + float(shot["aim_up"]), target.y), Vector3.UP)
	for i in 36:
		await physics_frame
	var ground := _surface(world, stand, player)
	player.global_position = Vector3(stand.x, ground + 0.30, stand.y)
	player.rotation.y = atan2(toward.x, toward.y)
	if player is CharacterBody3D:
		(player as CharacterBody3D).velocity = Vector3.ZERO
	player.reset_physics_interpolation()
	for i in 9:
		await physics_frame
	var seated_surface := _surface(world, stand, player)
	var ground_delta := player.global_position.y - seated_surface
	_hide_overlays(world)
	for i in 6:
		await process_frame
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	var label := "%s-%s" % [str(shot["label"]), time_name]
	if image == null or image.is_empty():
		failures.append("%s: viewport returned no image" % label)
	elif image.save_png("%s/%s.png" % [OUT_DIR, label]) != OK:
		failures.append("%s: save_png failed" % label)
	else:
		records.append({
			"frame": label,
			"stand_xz": [stand.x, stand.y],
			"player_xyz": [player.global_position.x, player.global_position.y, player.global_position.z],
			"camera_xyz": [camera.global_position.x, camera.global_position.y, camera.global_position.z],
			"surface_y": seated_surface,
			"player_ground_delta": ground_delta,
			"image_size": [image.get_width(), image.get_height()],
		})
		print("wrote %s/%s.png" % [OUT_DIR, label])
	return {"surface_y": seated_surface, "player_ground_delta": ground_delta}


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
	var query := PhysicsRayQueryParameters3D.create(
		Vector3(at.x, analytic + 100.0, at.y), Vector3(at.x, analytic - 100.0, at.y))
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
