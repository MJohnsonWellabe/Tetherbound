extends SceneTree

## Dedicated production-scene proof for The Capacitor Grove. The canonical map
## seat is intentionally not used as a camera stand: it is also the authored
## named-alpha and pickup position. These road-scale views preserve that content
## while showing the nearby old footing and its capacitor crescent.
const SCENE := "res://scenes/world/stormwood.tscn"
const OUT_DIR := "res://ralph/reports/BROAD-VISUAL-0910/CAPACITOR-GROVE-R1"
const TIMEOUT_MS := 420_000
const VIEWS := [
	{"name": "01-conductor-road-reveal", "stand": Vector2(-1012.0, 2998.0), "target": Vector2(-1040.0, 3070.0), "aim_up": 5.0},
	{"name": "02-west-crescent-profile", "stand": Vector2(-1073.0, 3044.0), "target": Vector2(-1040.0, 3070.0), "aim_up": 5.2},
	{"name": "03-footing-threshold", "stand": Vector2(-1039.0, 3048.0), "target": Vector2(-1040.0, 3074.0), "aim_up": 4.8},
]


func _init() -> void:
	_run()


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))
	var packed := load(SCENE) as PackedScene
	if packed == null:
		push_error("Capacitor Grove capture could not load production Stormwood")
		quit(1)
		return
	var world := packed.instantiate() as Node3D
	root.add_child(world)
	var deadline := Time.get_ticks_msec() + TIMEOUT_MS
	while Time.get_ticks_msec() < deadline and not bool(world.call("shell_build_complete")):
		await physics_frame
	if not bool(world.call("shell_build_complete")):
		push_error("production Stormwood did not finish building")
		quit(1)
		return
	var rig := world.get_node_or_null(^"CameraRig") as Node3D
	if rig != null:
		rig.process_mode = Node.PROCESS_MODE_DISABLED
	var hud := world.get_node_or_null(^"PlaygroundHUD") as CanvasLayer
	if hud != null:
		hud.visible = false
	var player := world.get_node_or_null(^"Player") as Node3D
	var look := world.get_node_or_null(^"WorldLook")
	var camera := Camera3D.new()
	camera.name = "CapacitorGroveEvidenceCamera"
	camera.fov = 66.0
	camera.far = 2000.0
	world.add_child(camera)
	camera.make_current()
	var records: Array[Dictionary] = []
	var failures: Array[String] = []
	for view: Dictionary in VIEWS:
		var stand: Vector2 = view.stand
		var target: Vector2 = view.target
		var forward := (target - stand).normalized()
		var ground := float(world.call("ground_height_at", stand.x, stand.y))
		player.global_position = Vector3(stand.x, ground + 0.35, stand.y)
		player.rotation.y = atan2(forward.x, forward.y)
		player.process_mode = Node.PROCESS_MODE_DISABLED
		var eye := stand - forward * 5.0
		var eye_ground := float(world.call("ground_height_at", eye.x, eye.y))
		camera.global_position = Vector3(eye.x, eye_ground + 2.75, eye.y)
		var target_ground := float(world.call("ground_height_at", target.x, target.y))
		camera.look_at(Vector3(target.x, target_ground + float(view.aim_up), target.y), Vector3.UP)
		for time_name: String in ["day", "night"]:
			look.call("apply_time", time_name)
			for _frame in 30:
				await physics_frame
			for _frame in 6:
				await process_frame
			await RenderingServer.frame_post_draw
			var image := root.get_texture().get_image()
			var frame_name := "%s-%s" % [str(view.name), time_name]
			var path := "%s/%s.png" % [OUT_DIR, frame_name]
			if image == null or image.is_empty() or image.save_png(path) != OK:
				failures.append("%s failed" % frame_name)
			else:
				records.append({"frame": frame_name, "image_size": [image.get_width(), image.get_height()],
					"player_xz": [stand.x, stand.y], "target_xz": [target.x, target.y],
					"camera_to_player_m": camera.global_position.distance_to(player.global_position)})
	var manifest := {"production_scene": SCENE, "named_location": "The Capacitor Grove",
		"fixture_disclosure": "Production Stormwood and ordinary trainer-scale player. The authored named alpha, pickup, roads, footing and world lighting remain live; HUD hidden and no content or progression injected.",
		"complete": failures.is_empty() and records.size() == 6, "frames": records, "failures": failures}
	var file := FileAccess.open("%s/manifest.json" % OUT_DIR, FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(manifest, "\t") + "\n")
	quit(0 if bool(manifest.complete) else 1)
