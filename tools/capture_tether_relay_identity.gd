extends SceneTree

## Dedicated production-scene proof for The Tether Relay. The shared locations
## sweep remains untouched. R3 showed that its generic rigs could place a huge
## checkpoint cloth against the lens, crop the new scaffold, and spend most of
## the standing/apparatus frames on sky. These four authored views keep an
## ordinary player ruler while proving gate, yard, pad and maintenance faces in
## both day and night.
##
## Windows production command (Compatibility renderer; deliberately no
## `--headless`):
##   godot --path . --rendering-driver opengl3 --resolution 1280x800 \
##     --script tools/capture_tether_relay_identity.gd -- \
##     --output=res://ralph/reports/MEADOWS-0912/final-relay-03

const SCENE := "res://scenes/world/meadows_playground.tscn"
const FRESH_OUTPUT := preload("res://tools/fresh_capture_output.gd")
const READY_TIMEOUT_MS := 420_000
const SEAT_SETTLE_FRAMES := 60
const SEAT_ATTEMPTS := 3

var _out_dir := ""

const VIEWS := [
	{"name": "01-relay-approach", "stand": Vector2(-25.0, 7.0),
		"target": Vector2(-10.0, 0.0), "target_y": 5.8, "back": 2.0, "up": 2.8, "fov": 62.0},
	{"name": "02-relay-standing", "stand": Vector2(-6.0, 2.0),
		"target": Vector2(7.0, -9.0), "target_y": 12.0, "back": 1.5, "up": 5.2, "fov": 62.0},
	{"name": "03-relay-apparatus", "stand": Vector2(15.0, -1.0),
		"target": Vector2(7.0, -9.0), "target_y": 12.7, "back": 1.4, "up": 6.2, "fov": 56.0},
	{"name": "04-relay-road", "stand": Vector2(-4.0, 5.0),
		"target": Vector2(6.0, -6.0), "target_y": 8.3, "back": 1.0, "up": 3.8, "fov": 64.0},
	{"name": "05-relay-route-console", "stand": Vector2(-16.0, -3.8),
		"target": Vector2(2.9, -9.0), "target_y": 10.65, "back": 0.5, "up": 2.45, "fov": 64.0},
]


func _init() -> void:
	_parse_args()
	_run()


func _parse_args() -> void:
	_out_dir = FRESH_OUTPUT.requested(OS.get_cmdline_user_args())


func _run() -> void:
	if not FRESH_OUTPUT.create_fresh(_out_dir, "Tether Relay capture"):
		quit(1)
		return
	if DisplayServer.get_name() == "headless":
		push_error("Tether Relay capture requires a rendering display")
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

	var relay := world.find_child("TetherRelay", true, false) as Node3D
	var player := world.get_node_or_null(^"Player") as Node3D
	var look := world.get_node_or_null(^"WorldLook")
	var weather := world.get_node_or_null(^"WorldWeather")
	var rig := world.get_node_or_null(^"CameraRig")
	if relay == null or player == null or look == null:
		push_error("capture requires production TetherRelay, Player and WorldLook")
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
	camera.name = "TetherRelayIdentityCamera"
	camera.far = 2000.0
	world.add_child(camera)
	camera.make_current()
	var records: Array[Dictionary] = []
	var failures: Array[String] = []
	for raw: Variant in VIEWS:
		var view := raw as Dictionary
		for time_name: String in ["day", "night"]:
			_pin_clock(look, time_name)
			var stand_local: Vector2 = view.get("stand", Vector2.ZERO)
			var target_local: Vector2 = view.get("target", Vector2.ZERO)
			var stand_xz: Vector2 = relay.call("world_of", stand_local)
			var target_xz: Vector2 = relay.call("world_of", target_local)
			var toward := (target_xz - stand_xz).normalized()
			var eye_xz := stand_xz - toward * float(view.back)
			var eye_ground := _surface(world, eye_xz, player)
			camera.fov = float(view.fov)
			camera.global_position = Vector3(eye_xz.x, eye_ground + float(view.up), eye_xz.y)
			camera.look_at(Vector3(target_xz.x, float(view.target_y), target_xz.y), Vector3.UP)
			# Establish the camera/streaming target before seating. The first view is
			# the initial long jump from the opening village to the Relay: its day
			# attempt can begin before Terrain3D collision residency catches up,
			# while the identical night attempt succeeds only because that first
			# settling pass already warmed the region. Retry the same authored seat in the
			# same requested time instead of silently borrowing the night pass.
			if not await _seat_player_on_live_surface(world, player, stand_xz, toward):
				failures.append("%s-%s: player below live surface" % [view.name, time_name])
				continue
			_hide_overlays(world)
			for i in 6:
				await process_frame
			await RenderingServer.frame_post_draw
			var image := root.get_texture().get_image()
			if image == null or image.is_empty():
				failures.append("%s-%s: viewport returned no image" % [view.name, time_name])
				continue
			var frame_name := "%s-%s" % [view.name, time_name]
			var path := "%s/%s.png" % [_out_dir, frame_name]
			if image.save_png(path) != OK:
				failures.append("%s: save_png failed" % frame_name)
				continue
			records.append({
				"frame": frame_name,
				"time": time_name,
				"stand_local": [stand_local.x, stand_local.y],
				"target_local": [target_local.x, target_local.y],
				"camera_to_player_m": camera.global_position.distance_to(player.global_position),
				"image_size": [image.get_width(), image.get_height()],
			})
			print("wrote %s" % path)

	var expected := VIEWS.size() * 2
	var complete := failures.is_empty() and records.size() == expected
	var manifest := {
		"production_scene": SCENE,
		"named_location": "The Tether Relay",
		"output_directory": _out_dir,
		"expected_frame_count": expected,
		"captured_frame_count": records.size(),
		"planned_frames": _planned_frames(),
		"fixture_disclosure": "Production Meadows scene, ordinary player, terrain, scatter, props, trainers and relay state. Authored day/night clock applied then frozen; clear weather; HUD and independent SubmersionOverlay hidden. Live collision-surface seating. No progression, encounter, route or relay-state injection.",
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
		Vector3(at.x, analytic + 100.0, at.y),
		Vector3(at.x, analytic - 100.0, at.y))
	query.collide_with_areas = false
	if player is CollisionObject3D:
		query.exclude = [(player as CollisionObject3D).get_rid()]
	var hit := world.get_world_3d().direct_space_state.intersect_ray(query)
	return analytic if hit.is_empty() else float((hit.position as Vector3).y)


func _seat_player_on_live_surface(world: Node3D, player: Node3D,
		stand_xz: Vector2, toward: Vector2) -> bool:
	for _attempt in SEAT_ATTEMPTS:
		var stand_ground := _surface(world, stand_xz, player)
		player.global_position = Vector3(stand_xz.x, stand_ground + 0.45, stand_xz.y)
		if player is CharacterBody3D:
			(player as CharacterBody3D).velocity = Vector3.ZERO
		player.rotation.y = atan2(toward.x, toward.y)
		player.reset_physics_interpolation()
		for _frame in SEAT_SETTLE_FRAMES:
			await physics_frame
		var settled_xz := Vector2(player.global_position.x, player.global_position.z)
		var settled_ground := _surface(world, settled_xz, player)
		if player.global_position.y >= settled_ground - 0.15:
			return true
	return false


func _wait_for_world(world: Node) -> bool:
	var deadline := Time.get_ticks_msec() + READY_TIMEOUT_MS
	while Time.get_ticks_msec() < deadline:
		if world.has_method("shell_build_complete") and bool(world.call("shell_build_complete")):
			return true
		await physics_frame
	return false
