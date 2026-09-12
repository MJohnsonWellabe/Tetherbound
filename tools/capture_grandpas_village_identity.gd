extends SceneTree

## Production-scene evidence harness for Grandpa's Village. This supplements
## the broad gameplay catalogue with two unobstructed, repeatable compositions:
## the ordinary south-square arrival and the well/workshop civic axis.

const SCENE := "res://scenes/world/meadows_playground.tscn"
const FRESH_OUTPUT := preload("res://tools/fresh_capture_output.gd")
const READY_TIMEOUT_MS := 420_000
const VIEWS := [
	{"name": "01-civic-square-southwest", "stand": Vector2(2.0, -22.0), "target": Vector2(8.0, -9.0)},
	# Stay south of the separate four-realm shrine circle at (10, 8). The R2
	# north stand sat inside that ring and judged its four crescent stones as
	# duplicate wells instead of showing the village's actual civic structure.
	{"name": "02-well-path-south", "stand": Vector2(8.0, -18.0), "target": Vector2(10.0, -10.0)},
	# Face the opening farmhouse's east door and new home plaque from outside
	# both the house and inn footprints; R3's first draft stand (-6,-8) was on
	# the inn roof and therefore invalid production evidence.
	{"name": "03-grandpas-home-square", "stand": Vector2(-12.0, -21.0), "target": Vector2(-16.0, -16.0)},
	# OWNER-0912. Read the replanned west street as a sequence from Grandpa's
	# fixed endpoint through the moved inn to the civic well.
	{"name": "04-west-street-to-well", "stand": Vector2(-9.0, -14.5), "target": Vector2(6.0, -7.5)},
	# The terrible text-on-box shop sign was replaced by an installed physical
	# trade crest. This approach shows whether it reads at ordinary street range.
	{"name": "05-mira-trade-crest", "stand": Vector2(8.5, 4.8), "target": Vector2(14.8, 5.0)},
	# OWNER-0912. These two reciprocal frames are the acceptance proof for the
	# newly authored well-to-TrailGate street and its workshop/shop thresholds.
	{"name": "06-south-street-from-trail-gate", "stand": Vector2(13.8, 18.5), "target": Vector2(7.0, -7.0)},
	{"name": "07-south-street-from-well", "stand": Vector2(9.5, -1.0), "target": Vector2(14.0, 18.0)},
	# Reciprocal west-leg proof. The old batch only looked east from behind
	# Grandpa's garden, so it could neither prove the street from the bend nor
	# distinguish a real route break from foreground fence occlusion.
	{"name": "08-west-street-from-well", "stand": Vector2(1.0, -11.0), "target": Vector2(-14.5, -16.0)},
	# A second shop view looks through the real west-facing doorway so the
	# evidence proves Mira and the physical crest belong to one readable store.
	{"name": "09-mira-shop-threshold", "stand": Vector2(11.8, 5.0), "target": Vector2(19.4, 4.0)},
]

var _out_dir := ""


func _init() -> void:
	_run()


func _run() -> void:
	_out_dir = FRESH_OUTPUT.requested(OS.get_cmdline_user_args())
	if not FRESH_OUTPUT.create_fresh(_out_dir, "Grandpa's Village capture"):
		quit(1)
		return
	if DisplayServer.get_name() == "headless":
		push_error("Grandpa's Village capture requires a rendering display")
		quit(1)
		return
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
			var path := "%s/%s.png" % [_out_dir, frame_name]
			if image.save_png(path) != OK:
				failures.append("%s: save_png failed" % frame_name)
				continue
			records.append({"frame": frame_name, "time": time_name,
				"player_xz": [stand.x, stand.y], "target_xz": [target.x, target.y],
				"image_size": [image.get_width(), image.get_height()]})

	var expected := VIEWS.size() * 2
	var complete := failures.is_empty() and records.size() == expected
	var manifest := {
		"production_scene": SCENE,
		"named_location": "Grandpa's Village",
		"output_directory": _out_dir,
		"expected_frame_count": expected,
		"captured_frame_count": records.size(),
		"planned_frames": _planned_frames(),
		"fixture_disclosure": "Production Meadows scene, village, props, NPCs, harvest and ordinary trainer. Fixed evidence camera; authored day/night clock frozen and weather clear; HUD and independent SubmersionOverlay hidden. No progress, encounter, lighting, pose or location injection.",
		"complete": complete,
		"frames": records,
		"failures": failures,
	}
	var file := FileAccess.open("%s/manifest.json" % _out_dir, FileAccess.WRITE)
	if file == null:
		failures.append("manifest could not be written")
		complete = false
	else:
		file.store_string(JSON.stringify(manifest, "\t") + "\n")
		file.close()
	quit(0 if complete else 1)


func _planned_frames() -> Array[String]:
	var planned: Array[String] = []
	for raw: Variant in VIEWS:
		for time_name: String in ["day", "night"]:
			planned.append("%s-%s" % [str((raw as Dictionary).name), time_name])
	return planned


func _hide_overlays(world: Node) -> void:
	for path: NodePath in [^"PlaygroundHUD", ^"Water/SubmersionOverlay"]:
		var overlay := world.get_node_or_null(path) as CanvasLayer
		if overlay != null:
			overlay.visible = false
	for child: Node in root.get_children():
		if child is CanvasLayer:
			(child as CanvasLayer).visible = false


func _surface(world: Node3D, at: Vector2) -> float:
	# These are authored evidence-camera and trainer stands, not a traversal
	# proof. Asking the production terrain directly keeps a nearby roof, shrine,
	# cart or awning from lifting the diagnostic camera into the air.
	return float(world.call("ground_height_at", at.x, at.y))


func _wait_for_world(world: Node) -> bool:
	var deadline := Time.get_ticks_msec() + READY_TIMEOUT_MS
	while Time.get_ticks_msec() < deadline:
		if world.has_method("shell_build_complete") and bool(world.call("shell_build_complete")):
			return true
		await physics_frame
	return false
