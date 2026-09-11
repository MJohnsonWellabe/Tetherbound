extends SceneTree

## Dedicated production-scene proof for The Tether Relay. The shared locations
## sweep remains untouched. R3 showed that its generic rigs could place a huge
## checkpoint cloth against the lens, crop the new scaffold, and spend most of
## the standing/apparatus frames on sky. These four authored views keep an
## ordinary player ruler while proving gate, yard, pad and maintenance faces in
## both day and night.

const SCENE := "res://scenes/world/meadows_playground.tscn"
const OUT_DIR := "res://ralph/reports/FOUR-BIOME-CONTINUATION-0910/RELAY-IDENTITY-R6"
const READY_TIMEOUT_MS := 420_000

const VIEWS := [
	{"name": "01-relay-approach", "stand": Vector2(-25.0, 7.0),
		"target": Vector2(-10.0, 0.0), "target_y": 5.8, "back": 2.0, "up": 2.8, "fov": 62.0},
	{"name": "02-relay-standing", "stand": Vector2(-6.0, 2.0),
		"target": Vector2(7.0, -9.0), "target_y": 12.0, "back": 1.5, "up": 5.2, "fov": 62.0},
	{"name": "03-relay-apparatus", "stand": Vector2(15.0, -1.0),
		"target": Vector2(7.0, -9.0), "target_y": 12.2, "back": 0.5, "up": 7.2, "fov": 52.0},
	{"name": "04-relay-road", "stand": Vector2(-4.0, 5.0),
		"target": Vector2(6.0, -6.0), "target_y": 8.3, "back": 1.0, "up": 3.8, "fov": 64.0},
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
			var stand_ground := _surface(world, stand_xz, player)
			var eye_ground := _surface(world, eye_xz, player)
			player.global_position = Vector3(stand_xz.x, stand_ground + 0.45, stand_xz.y)
			if player is CharacterBody3D:
				(player as CharacterBody3D).velocity = Vector3.ZERO
			player.rotation.y = atan2(toward.x, toward.y)
			camera.fov = float(view.fov)
			camera.global_position = Vector3(eye_xz.x, eye_ground + float(view.up), eye_xz.y)
			camera.look_at(Vector3(target_xz.x, float(view.target_y), target_xz.y), Vector3.UP)
			for i in 60:
				await physics_frame
			# Judge the settled body against the live surface at its settled XZ,
			# not the original stand sample. On the approach the ordinary body can
			# slide downhill while collision residency catches up; comparing its
			# lower Y to the higher pre-slide sample falsely rejected the healthy
			# day frame even though the retry was visibly grounded at night.
			var settled_xz := Vector2(player.global_position.x, player.global_position.z)
			var settled_ground := _surface(world, settled_xz, player)
			if player.global_position.y < settled_ground - 0.15:
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
			var path := "%s/%s.png" % [OUT_DIR, frame_name]
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

	var manifest := {
		"production_scene": SCENE,
		"named_location": "The Tether Relay",
		"fixture_disclosure": "Production Meadows scene, ordinary player, terrain, scatter, props, trainers and relay state. Authored day/night clock applied then frozen; clear weather; HUD and independent SubmersionOverlay hidden. Live collision-surface seating. No progression, encounter, route or relay-state injection.",
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
	var query := PhysicsRayQueryParameters3D.create(
		Vector3(at.x, analytic + 100.0, at.y),
		Vector3(at.x, analytic - 100.0, at.y))
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
