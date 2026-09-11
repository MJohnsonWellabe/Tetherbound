extends SceneTree

## Dedicated production-scene evidence for Trail Camp as a rest-stop subject.
## This does not share or modify tools/_capture_locations.gd.
##
## Windows production command (real Compatibility renderer; no --headless):
##   & 'C:\Users\mattj\.cache\tetherbound-tools\godot-4.7\Godot_v4.7-stable_win64_console.exe' `
##     --path . --rendering-driver opengl3 --resolution 1280x720 `
##     --script tools/capture_trail_camp_subject_identity.gd

const SCENE := "res://scenes/world/meadows_playground.tscn"
const OUT_DIR := "res://ralph/reports/BROAD-VISUAL-0910/TRAIL-CAMP-ARRIVAL-R6"
const READY_TIMEOUT_MS := 420_000
const FOV := 70.0

const VIEWS := [
	# (326,906) and (333,913) are exact points on oak_grove_ring's authored
	# south leg [(300,880),(370,950)]. R1's guessed (332,900) was 8.5 m off
	# that road, outside the camp clearing, and its analytic-only ground seat
	# produced an eye inside/under foreground geometry.
	# Keep the proof on the ordinary authored road at a normal third-person eye.
	# The R5 shoulder/elevation experiment was rejected: it exposed more canopy
	# rather than repairing the road-to-camp relationship. R6 instead verifies
	# the bounded vegetation lens that owns the actual obstruction fix.
	{"name": "01-south-road-arrival-day", "stand": Vector2(326.0, 906.0), "eye": Vector2(326.0, 906.0), "target": Vector2(346.3, 926.3), "time": "day", "camera_up": 2.15, "aim_up": 2.55},
	{"name": "02-south-road-arrival-night", "stand": Vector2(326.0, 906.0), "eye": Vector2(326.0, 906.0), "target": Vector2(346.3, 926.3), "time": "night", "camera_up": 2.15, "aim_up": 2.55},
	{"name": "03-threshold-approach-day", "stand": Vector2(333.0, 913.0), "eye": Vector2(333.0, 913.0), "target": Vector2(346.3, 926.3), "time": "day", "camera_up": 2.15, "aim_up": 2.55},
	{"name": "04-threshold-approach-night", "stand": Vector2(333.0, 913.0), "eye": Vector2(333.0, 913.0), "target": Vector2(346.3, 926.3), "time": "night", "camera_up": 2.15, "aim_up": 2.55},
	{"name": "05-clearing-mouth-day", "stand": Vector2(340.0, 920.0), "eye": Vector2(340.0, 920.0), "target": Vector2(346.3, 926.3), "time": "day", "camera_up": 2.15, "aim_up": 2.45},
	{"name": "06-clearing-mouth-night", "stand": Vector2(340.0, 920.0), "eye": Vector2(340.0, 920.0), "target": Vector2(346.3, 926.3), "time": "night", "camera_up": 2.15, "aim_up": 2.45},
	{"name": "07-fire-tent-day", "stand": Vector2(346.5, 929.5), "eye": Vector2(346.5, 929.5), "target": Vector2(343.8, 937.5), "time": "day", "camera_up": 2.15, "aim_up": 1.15},
	{"name": "08-fire-tent-night", "stand": Vector2(346.5, 929.5), "eye": Vector2(346.5, 929.5), "target": Vector2(343.8, 937.5), "time": "night", "camera_up": 2.15, "aim_up": 1.15},
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
	var hud := world.get_node_or_null(^"PlaygroundHUD") as CanvasLayer
	if player == null or look == null:
		push_error("capture requires the production Player and WorldLook")
		quit(1)
		return
	if rig != null:
		rig.set_process(false)
		rig.set_physics_process(false)
	if hud != null:
		hud.visible = false
	var overlay := world.find_child("SubmersionOverlay", true, false) as CanvasLayer
	if overlay != null:
		overlay.visible = false
	if weather != null:
		if weather.has_method("set_weather"):
			weather.call("set_weather", "clear")
		weather.set_process(false)
		weather.set_physics_process(false)
	if look.has_method("set_clock_frozen"):
		look.call("set_clock_frozen", true)

	var camera := Camera3D.new()
	camera.name = "TrailCampSubjectEvidenceCamera"
	camera.fov = FOV
	camera.far = 2000.0
	world.add_child(camera)
	camera.make_current()

	var records: Array[Dictionary] = []
	var failures: Array[String] = []
	var threshold := world.find_child("TrailCampRoadsideThreshold", true, false) as Node3D
	if threshold == null:
		push_error("production Trail Camp roadside threshold is missing")
		quit(1)
		return
	player.visible = false
	player.set_process(false)
	player.set_physics_process(false)
	if player is CharacterBody3D:
		(player as CharacterBody3D).velocity = Vector3.ZERO
	for raw: Variant in VIEWS:
		var view := raw as Dictionary
		look.call("apply_time", str(view.time))
		if look.has_method("set_clock_frozen"):
			look.call("set_clock_frozen", true)
		var stand: Vector2 = view.stand
		var eye: Vector2 = view.get("eye", stand)
		var target: Vector2 = view.target
		var stand_ground := _surface(world, stand, player)
		if is_nan(stand_ground):
			failures.append("%s: no live ground under camera" % str(view.name))
			continue
		player.global_position = Vector3(stand.x, stand_ground + 0.05, stand.y)
		var eye_ground := _surface(world, eye, player)
		if is_nan(eye_ground):
			failures.append("%s: no live ground under camera eye" % str(view.name))
			continue
		camera.global_position = Vector3(eye.x,
			eye_ground + float(view.get("camera_up", 2.15)), eye.y)
		if not _camera_clear(world, camera.global_position, player):
			failures.append("%s: fixed camera eye intersects production geometry" % str(view.name))
			continue
		# Look targets may sit on the marker/fire furniture itself. Use Terrain3D's
		# analytic terrain answer here; collision sampling is only for the eye.
		var target_ground := float(world.call("ground_height_at", target.x, target.y))
		camera.look_at(Vector3(target.x, target_ground + float(view.aim_up), target.y), Vector3.UP)
		for i in 48:
			await physics_frame
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
			"player_road_xz": [stand.x, stand.y],
			"camera_xz": [eye.x, eye.y],
			"fire_distance_m": stand.distance_to(Vector2(344.3, 936.6)),
			"image_size": [image.get_width(), image.get_height()],
		})
		print("wrote %s" % path)

	var manifest := {
		"production_scene": SCENE,
		"named_location": "Trail Camp",
		"fixture_disclosure": "Production Meadows scene with Terrain3D, authoritative scatter, props and encounters. Fixed camera on verified live ground; authored day/night clock frozen; clear weather pinned; Player hidden/physics-disabled on the same safe ground; HUD and independent SubmersionOverlay hidden. No progress, encounter, lighting, prop or pose injection.",
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


## Terrain3D's rendered/collision surface can diverge from its analytic height.
## R1 used only the analytic value and returned an eye buried in brown geometry.
## A bounded ray keeps the answer local to the authored road and avoids naming a
## distant prop top as ground.
func _surface(world: Node3D, at: Vector2, player: Node3D) -> float:
	var analytic := float(world.call("ground_height_at", at.x, at.y))
	if is_nan(analytic):
		return NAN
	var query := PhysicsRayQueryParameters3D.create(
		Vector3(at.x, analytic + 4.0, at.y),
		Vector3(at.x, analytic - 6.0, at.y))
	query.collide_with_areas = false
	if player is CollisionObject3D:
		query.exclude = [(player as CollisionObject3D).get_rid()]
	var hit := world.get_world_3d().direct_space_state.intersect_ray(query)
	return analytic if hit.is_empty() else float((hit.position as Vector3).y)


func _camera_clear(world: Node3D, eye: Vector3, player: Node3D) -> bool:
	var query := PhysicsShapeQueryParameters3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = 0.45
	query.shape = sphere
	query.transform = Transform3D(Basis(), eye)
	query.collide_with_areas = false
	if player is CollisionObject3D:
		query.exclude = [(player as CollisionObject3D).get_rid()]
	for raw: Variant in world.get_world_3d().direct_space_state.intersect_shape(query, 8):
		var body := (raw as Dictionary).get("collider") as Node
		if body != null and not _under_terrain(world, body):
			return false
	return true


func _under_terrain(world: Node3D, body: Node) -> bool:
	var terrain := world.get_node_or_null(^"Terrain")
	var cursor := body
	while cursor != null:
		if cursor == terrain:
			return true
		cursor = cursor.get_parent()
	return false


func _wait_for_world(world: Node) -> bool:
	var deadline := Time.get_ticks_msec() + READY_TIMEOUT_MS
	while Time.get_ticks_msec() < deadline:
		if world.has_method("shell_build_complete") and bool(world.call("shell_build_complete")):
			return true
		await physics_frame
	return false
