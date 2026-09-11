extends SceneTree

## Trustworthy Road Gate presentation receipt.
##
## Windows production command (real Compatibility renderer; no --headless):
##   & 'C:\Users\mattj\.cache\tetherbound-tools\godot-4.7\Godot_v4.7-stable_win64_console.exe' `
##     --path . --rendering-driver opengl3 --resolution 1280x720 `
##     --script tools/capture_road_gate.gd
##
## The old harness duplicated the pre-VP5 gate coordinate, parked Player 500m
## below terrain, shot only daytime and never proved the open leaf. This one
## finds the live RoadGate, derives every camera from its transform, freezes the
## authored clock and records paired locked/open day/night views.

const SCENE := "res://scenes/world/meadows_playground.tscn"
const OUT_DIR := "res://ralph/reports/BROAD-VISUAL-0910/ROAD-GATE-HINGE-R2"
const SETTLE_FRAMES := 240
const POSE_FRAMES := 4
const FOV := 68.0


func _init() -> void:
	_run()


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))
	var packed := load(SCENE) as PackedScene
	if packed == null:
		push_error("could not load %s" % SCENE)
		quit(1)
		return
	var world := packed.instantiate()
	root.add_child(world)
	for i in SETTLE_FRAMES:
		await physics_frame

	var failures: Array[String] = []
	var gate := world.find_child("RoadGate", true, false) as Node3D
	if gate == null:
		push_error("production VillageBoundary has no live RoadGate")
		quit(1)
		return

	var rig := world.get_node_or_null(^"CameraRig")
	if rig != null:
		rig.set_process(false)
		rig.set_physics_process(false)
	var hud := world.get_node_or_null(^"PlaygroundHUD") as CanvasLayer
	if hud != null:
		hud.visible = false
	var overlay := world.find_child("SubmersionOverlay", true, false) as CanvasLayer
	if overlay != null:
		overlay.visible = false

	var look := world.get_node_or_null(^"WorldLook")
	if look != null and look.has_method("set_clock_frozen"):
		look.call("set_clock_frozen", true)
	var player := world.get_node_or_null(^"Player") as Node3D
	if player != null:
		player.visible = false
		player.set_process(false)
		player.set_physics_process(false)
		if player is CharacterBody3D:
			(player as CharacterBody3D).velocity = Vector3.ZERO

	var camera := Camera3D.new()
	camera.fov = FOV
	camera.far = 2000.0
	world.add_child(camera)
	camera.make_current()

	# -Z is the leaf's road-facing side; road_gate.gd's lock placement was
	# measured against that exact face. Local-space cameras survive any later
	# coordinate/yaw correction in village_boundary.json.
	var views: Array[Dictionary] = [
		{
			"name": "01-road-gate-approach",
			"eye": gate.to_global(Vector3(1.8, 1.72, -12.0)),
			"target": gate.to_global(Vector3(0.0, 1.65, 0.0)),
		},
		{
			"name": "02-road-gate-lock-and-joinery",
			"eye": gate.to_global(Vector3(-3.8, 1.65, -5.2)),
			"target": gate.to_global(Vector3(0.0, 1.65, 0.0)),
		},
	]
	var records: Array[Dictionary] = []
	for state: String in ["locked", "open"]:
		if state == "open":
			# Visual-state proof only. This deliberately does not claim the key or
			# progression was earned; open_permanently() is the production leaf pose.
			gate.call("open_permanently")
		for time: String in ["day", "night"]:
			if look != null:
				look.call("apply_time", time)
				if look.has_method("set_clock_frozen"):
					look.call("set_clock_frozen", true)
			for i in 24:
				await physics_frame
			for entry: Dictionary in views:
				var name := "%s-%s-%s" % [entry.name, state, time]
				camera.global_position = entry.eye
				camera.look_at(entry.target, Vector3.UP)
				if player != null:
					var ground := float(world.call("ground_height_at",
						camera.global_position.x, camera.global_position.z))
					if is_nan(ground):
						failures.append("%s: no live ground below camera" % name)
						continue
					player.global_position = Vector3(camera.global_position.x,
						ground + 0.05, camera.global_position.z)
				for i in 20:
					await physics_frame
				for i in POSE_FRAMES:
					await process_frame
				await RenderingServer.frame_post_draw
				var image := root.get_texture().get_image()
				if image == null:
					failures.append("%s: viewport returned no image" % name)
					continue
				var path := "%s/%s.png" % [OUT_DIR, name]
				var error := image.save_png(path)
				if error != OK:
					failures.append("%s: save_png failed (%d)" % [name, error])
					continue
				records.append({
					"frame": name,
					"state": state,
					"time": time,
					"image_size": [image.get_width(), image.get_height()],
					"camera_global": [camera.global_position.x, camera.global_position.y, camera.global_position.z],
				})
				print("  %-46s -> %s" % [name, path])

	var expected := views.size() * 4
	var manifest := {
		"schema_version": 1,
		"production_scene": SCENE,
		"named_location": "Road Gate / The Rise",
		"fixture_disclosure": "Production Meadows RoadGate and authoritative locked leaf. Fixed cameras derived from live gate transform; authored clock frozen; HUD and independent SubmersionOverlay hidden; Player hidden/physics-disabled on verified live ground. The open pair directly calls production open_permanently() to prove visual state only, not earned key progression. No lighting, weather, encounter or prop injection.",
		"expected_frame_count": expected,
		"complete": failures.is_empty() and records.size() == expected,
		"frames": records,
		"failures": failures,
		"capture_finished_utc": Time.get_datetime_string_from_system(true),
	}
	var manifest_file := FileAccess.open("%s/manifest.json" % OUT_DIR, FileAccess.WRITE)
	if manifest_file == null:
		failures.append("manifest could not be written")
	else:
		manifest_file.store_string(JSON.stringify(manifest, "\t") + "\n")
		manifest_file.close()

	print("")
	print("%d frames -> %s" % [records.size(), OUT_DIR])
	print("Compatibility capture. Frame times are NOT a performance measurement.")
	if not failures.is_empty():
		for line in failures:
			print("FAIL: %s" % line)
		quit(1)
		return
	quit(0)
