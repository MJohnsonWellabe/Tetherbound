extends SceneTree

## Production-scene evidence harness for Grandpa's Village. This supplements
## the broad gameplay catalogue with two unobstructed, repeatable compositions:
## the ordinary south-square arrival and the well/workshop civic axis.

const SCENE := "res://scenes/world/meadows_playground.tscn"
const OUT_DIR := "res://ralph/reports/BROAD-VISUAL-0910/GRANDPAS-VILLAGE-R3"
const READY_TIMEOUT_MS := 420_000
const VIEWS := [
	{"name": "01-civic-square-southeast", "stand": Vector2(20.0, -23.0), "target": Vector2(9.0, -9.0)},
	# Stay south of the separate four-realm shrine circle at (10, 8). The R2
	# north stand sat inside that ring and judged its four crescent stones as
	# duplicate wells instead of showing the village's actual civic structure.
	{"name": "02-well-path-south", "stand": Vector2(10.0, -23.0), "target": Vector2(10.0, -10.0)},
	# Face the opening farmhouse's east door and new home plaque from outside
	# both the house and inn footprints; R3's first draft stand (-6,-8) was on
	# the inn roof and therefore invalid production evidence.
	{"name": "03-grandpas-home-square", "stand": Vector2(-8.0, -16.0), "target": Vector2(-17.0, -16.0)},
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
	camera.name = "GrandpasVillageEvidenceCamera"
	camera.fov = 66.0
	camera.far = 2000.0
	world.add_child(camera)
	camera.make_current()

	var records: Array[Dictionary] = []
	var failures: Array[String] = []
	for raw: Variant in VIEWS:
		var view := raw as Dictionary
		var stand := view.stand as Vector2
		var target := view.target as Vector2
		var toward := (target - stand).normalized()
		var eye_xz := stand - toward * 4.6
		var stand_ground := _surface(world, stand)
		var eye_ground := _surface(world, eye_xz)
		var target_ground := float(world.call("ground_height_at", target.x, target.y))
		for time_name: String in ["day", "night"]:
			look.call("apply_time", time_name)
			if look.has_method("set_clock_frozen"):
				look.call("set_clock_frozen", true)
			player.global_position = Vector3(stand.x, stand_ground + 0.45, stand.y)
			if player is CharacterBody3D:
				(player as CharacterBody3D).velocity = Vector3.ZERO
			player.rotation.y = atan2(toward.x, toward.y)
			camera.global_position = Vector3(eye_xz.x, eye_ground + 2.9, eye_xz.y)
			camera.look_at(Vector3(target.x, target_ground + 1.55, target.y), Vector3.UP)
			for i in 45:
				await physics_frame
			_hide_overlays(world)
			for i in 6:
				await process_frame
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
			records.append({"frame": frame_name, "time": time_name,
				"player_xz": [stand.x, stand.y], "target_xz": [target.x, target.y],
				"image_size": [image.get_width(), image.get_height()]})

	var manifest := {
		"production_scene": SCENE,
		"named_location": "Grandpa's Village",
		"fixture_disclosure": "Production Meadows scene, village, props, NPCs, harvest and ordinary trainer. Fixed evidence camera; authored day/night clock frozen and weather clear; HUD and independent SubmersionOverlay hidden. No progress, encounter, lighting, pose or location injection.",
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


func _hide_overlays(world: Node) -> void:
	for path: NodePath in [^"PlaygroundHUD", ^"Water/SubmersionOverlay"]:
		var overlay := world.get_node_or_null(path) as CanvasLayer
		if overlay != null:
			overlay.visible = false
	for child: Node in root.get_children():
		if child is CanvasLayer:
			(child as CanvasLayer).visible = false


func _surface(world: Node3D, at: Vector2) -> float:
	var analytic := float(world.call("ground_height_at", at.x, at.y))
	var query := PhysicsRayQueryParameters3D.create(
		Vector3(at.x, analytic + 100.0, at.y), Vector3(at.x, analytic - 100.0, at.y))
	query.collide_with_areas = false
	var hit := world.get_world_3d().direct_space_state.intersect_ray(query)
	return analytic if hit.is_empty() else float((hit.position as Vector3).y)


func _wait_for_world(world: Node) -> bool:
	var deadline := Time.get_ticks_msec() + READY_TIMEOUT_MS
	while Time.get_ticks_msec() < deadline:
		if world.has_method("shell_build_complete") and bool(world.call("shell_build_complete")):
			return true
		await physics_frame
	return false
