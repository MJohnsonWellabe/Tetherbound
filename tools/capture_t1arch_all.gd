extends SceneTree

## T1-ARCH: one scene load, all four sites -- Warrens exterior, Warrens
## interior (positive reference), stronghold exterior/approach, stronghold
## interior, and the castle at its CORRECT post-GATE-E2 site.
##
## Consolidated into one scene load deliberately: this environment's software
## rasterizer makes each full scene boot (100k+ props, 315k+ grass instances)
## the dominant cost, so three separate capture scripts (each paying that
## cost once) is three times the wall-clock of one script paying it once and
## sharing it across every stand. Settle is also cut from the base scripts'
## 240 physics frames to 90 -- long enough for the player body (parked and
## frozen right after) and any dynamic props to stop moving, not to bake in
## a five-minute idle before the first frame.
##
##   xvfb-run -a -s "-screen 0 1280x800x24" \
##     godot --path . --rendering-driver opengl3 --resolution 1280x800 \
##     --script tools/capture_t1arch_all.gd

const SCENE := "res://scenes/world/meadows_playground.tscn"
const OUT_DIR := "res://shots/t1arch"
const LANDMARK := preload("res://scripts/world/landmark.gd")
const SETTLE_FRAMES := 90
const POSE_FRAMES := 3
const FOV := 70.0

func _init() -> void:
	_run()


func _hide_canvas_layers(node: Node) -> void:
	if node is CanvasLayer:
		(node as CanvasLayer).visible = false
	for child in node.get_children():
		_hide_canvas_layers(child)


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))
	var packed: PackedScene = load(SCENE)
	if packed == null:
		push_error("could not load %s" % SCENE)
		quit(1)
		return
	var world: Node = packed.instantiate()
	root.add_child(world)
	for i in SETTLE_FRAMES:
		await physics_frame

	_hide_canvas_layers(root)
	var rig: Node = world.get_node_or_null(^"CameraRig")
	if rig != null:
		rig.set_process(false)
		rig.set_physics_process(false)

	var camera := Camera3D.new()
	camera.fov = FOV
	camera.far = 3000.0
	world.add_child(camera)
	camera.make_current()

	var look: Node = world.get_node_or_null(^"WorldLook")
	var weather: Node = world.get_node_or_null(^"WorldWeather")
	if weather != null:
		weather.set_process(false)
		weather.set_physics_process(false)
	if look != null:
		look.set_process(false)
		look.set_physics_process(false)
		if look.has_method("set_weather"):
			look.call("set_weather", {})
		look.call("apply_time", "day")

	var player: Node3D = world.get_node_or_null(^"Player") as Node3D
	if player != null:
		var park := Vector2(-357.0 + 900.0, 2610.0 + 900.0)
		var park_y := float(world.call("ground_height_at", park.x, park.y))
		player.global_position = Vector3(park.x, park_y + 0.2, park.y)
		player.visible = false
		player.set_physics_process(false)
		if player is CharacterBody3D:
			(player as CharacterBody3D).velocity = Vector3.ZERO

	var warrens: Node3D = world.get_node_or_null(^"BurrowWarrens") as Node3D
	var stronghold: Node3D = world.get_node_or_null(^"Stronghold") as Node3D
	var landmark: Node3D = world.get_node_or_null(^"StrongholdSilhouette") as Node3D

	var torch := OmniLight3D.new()
	torch.light_energy = 2.6
	torch.omni_range = 12.0
	torch.light_color = Color("#ffd8a0")
	torch.visible = false
	world.add_child(torch)

	var written: Array[String] = []
	var failures: Array[String] = []

	# --- Warrens exterior: found stands, same method as capture_warrens_63.gd ---
	if warrens != null:
		var mouth: Vector3 = warrens.call("marker", "mouth")
		var stands := _clear_exterior_views(world, warrens, mouth)
		for s: Dictionary in stands:
			await _shoot(camera, look, torch, false, s["eye"], s["target"], s["name"], written, failures)
		# Standing at the mouth itself, looking in -- the entrance/door read.
		var mouth_local_eye: Vector3 = warrens.to_global(Vector3(0.0, 0.0, -12.0))
		var mey := float(world.call("ground_height_at", mouth_local_eye.x, mouth_local_eye.z))
		var mouth_eye := Vector3(mouth_local_eye.x, (0.0 if is_nan(mey) else mey) + 1.7, mouth_local_eye.z)
		var mouth_target := warrens.to_global(Vector3(0.0, 1.4, 4.0))
		await _shoot(camera, look, torch, false, mouth_eye, mouth_target, "W-ext-03-mouth-door", written, failures)

	# --- Warrens interior: the four stands the owner already called good ---
	if warrens != null:
		var interior_views := [
			{"name": "W-int-01-den-wide", "eye": Vector2(-4.0, 35.5), "eye_h": 1.75, "target": Vector2(4.0, 43.0), "target_h": 1.6},
			{"name": "W-int-02-hall", "eye": Vector2(-2.0, 17.5), "eye_h": 1.7, "target": Vector2(3.0, 27.0), "target_h": 2.4},
		]
		for entry: Variant in interior_views:
			var v: Dictionary = entry
			var eye: Vector3 = _stand(warrens, v, "eye")
			var target: Vector3 = _stand(warrens, v, "target")
			if eye.is_equal_approx(Vector3.INF) or target.is_equal_approx(Vector3.INF):
				failures.append("%s: stand outside footprint" % str(v["name"]))
				continue
			await _shoot(camera, look, torch, true, eye, target, str(v["name"]), written, failures)

	# --- Stronghold exterior/approach ---
	if stronghold != null:
		var outer_z: float = float(stronghold.call("_mouth_outer_z")) if stronghold.has_method("_mouth_outer_z") else 0.0
		# Ramp foot, looking up the approach at the works.
		var ramp_local_eye: Vector3 = stronghold.to_global(Vector3(0.0, 0.0, outer_z - 24.0))
		var rey := float(world.call("ground_height_at", ramp_local_eye.x, ramp_local_eye.z))
		var ramp_eye := Vector3(ramp_local_eye.x, (0.0 if is_nan(rey) else rey) + 1.7, ramp_local_eye.z)
		var ramp_target: Vector3 = stronghold.to_global(Vector3(0.0, 4.0, outer_z + 6.0))
		await _shoot(camera, look, torch, false, ramp_eye, ramp_target, "S-ext-01-approach-ramp-foot", written, failures)
		# A wide flank stand, far enough back to see the whole works as a mass.
		var flank_local: Vector3 = stronghold.to_global(Vector3(-40.0, 0.0, outer_z - 10.0))
		var fey := float(world.call("ground_height_at", flank_local.x, flank_local.z))
		if not is_nan(fey):
			var flank_eye := Vector3(flank_local.x, fey + 1.7, flank_local.z)
			var flank_target: Vector3 = stronghold.to_global(Vector3(0.0, 5.0, outer_z + 10.0))
			await _shoot(camera, look, torch, false, flank_eye, flank_target, "S-ext-02-flank-wide", written, failures)

	# --- Stronghold interior: courtyard (open, the real question) + legendary chamber ---
	if stronghold != null:
		var s_views := [
			{"name": "S-int-01-courtyard", "eye": Vector2(-7.0, 21.0), "eye_h": 1.75, "target": Vector2(6.0, 42.0), "target_h": 4.0},
			{"name": "S-int-02-legendary-chamber", "eye": Vector2(-20.0, 82.0), "eye_h": 1.75, "target": Vector2(-36.0, 93.0), "target_h": 6.0},
		]
		for entry: Variant in s_views:
			var v: Dictionary = entry
			var eye: Vector3 = _stand(stronghold, v, "eye")
			var target: Vector3 = _stand(stronghold, v, "target")
			if eye.is_equal_approx(Vector3.INF) or target.is_equal_approx(Vector3.INF):
				failures.append("%s: stand outside footprint" % str(v["name"]))
				continue
			await _shoot(camera, look, torch, false, eye, target, str(v["name"]), written, failures)

	# --- Castle, at the CORRECT site (capture_castle.gd's SITE is stale -- see
	# tools/capture_castle_63.gd's own header) ---
	if landmark != null:
		var site := LANDMARK.SITE
		var ground: float = float(world.call("ground_height_at", site.x, site.y))
		if is_nan(ground):
			ground = 0.0
		print("[t1arch] castle SITE=%s ground=%.2f" % [str(site), ground])
		var c_views := [
			{"name": "C-01-approach-gate", "offset": Vector3(2.0, 1.8, 24.0), "look_at": Vector3(2.0, 8.0, 0.0)},
			{"name": "C-02-silhouette-far", "offset": Vector3(4.0, 20.0, 70.0), "look_at": Vector3(2.0, 14.0, 0.0)},
			{"name": "C-03-corner-close", "offset": Vector3(38.0, 14.0, 38.0), "look_at": Vector3(2.0, 9.0, 12.0)},
		]
		for entry: Variant in c_views:
			var v: Dictionary = entry
			var eye: Vector3 = Vector3(site.x, ground, site.y) + (v["offset"] as Vector3)
			var target: Vector3 = Vector3(site.x, ground, site.y) + (v["look_at"] as Vector3)
			await _shoot(camera, look, torch, false, eye, target, str(v["name"]), written, failures)

	print("")
	print("%d frames -> %s" % [written.size(), OUT_DIR])
	if not failures.is_empty():
		for line in failures:
			print("FAIL: %s" % line)
	quit(0 if failures.is_empty() else 1)


func _shoot(camera: Camera3D, look: Node, torch: OmniLight3D, interior: bool,
		eye: Vector3, target: Vector3, name_value: String,
		written: Array[String], failures: Array[String]) -> void:
	camera.global_position = eye
	camera.look_at(target, Vector3.UP)
	torch.visible = interior
	torch.global_position = eye + Vector3(0.0, 0.35, 0.0)
	for i in 8:
		await physics_frame
	if look != null:
		if look.has_method("set_weather"):
			look.call("set_weather", {})
		look.call("apply_time", "day")
	for i in POSE_FRAMES:
		await process_frame
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	if image == null:
		failures.append("%s: viewport returned no image" % name_value)
		return
	var path := "%s/%s.png" % [OUT_DIR, name_value]
	if image.save_png(path) != OK:
		failures.append("%s: save_png failed" % name_value)
		return
	written.append(path)
	print("  %-28s -> %s" % [name_value, path])


## Building-local [x,z] + height above the building's own built floor.
func _stand(host: Node3D, view: Dictionary, key: String) -> Vector3:
	var flat: Vector2 = view[key]
	var world_flat: Vector3 = host.to_global(Vector3(flat.x, 0.0, flat.y))
	var floor_y := float(host.call("built_floor_height_at", world_flat.x, world_flat.z))
	if is_nan(floor_y):
		return Vector3.INF
	return Vector3(world_flat.x, floor_y + float(view.get("%s_h" % key, 1.7)), world_flat.z)


## Two exterior stands that can actually see the warrens knoll, found by
## ray-casting rather than guessed. Same method as capture_warrens_63.gd.
func _clear_exterior_views(world: Node, warrens: Node3D, mouth: Vector3) -> Array:
	var space := (world as Node3D).get_world_3d().direct_space_state
	var aim := mouth + Vector3.UP * 2.5
	var found: Array = []
	for radius in [26.0, 40.0]:
		for step in 16:
			var angle := TAU * float(step) / 16.0
			var at := Vector2(mouth.x + sin(angle) * radius, mouth.z + cos(angle) * radius)
			var ground := float(world.call("ground_height_at", at.x, at.y))
			if is_nan(ground):
				continue
			var eye := Vector3(at.x, ground + 1.7, at.y)
			var query := PhysicsRayQueryParameters3D.create(eye, aim)
			var hit := space.intersect_ray(query)
			if hit.is_empty():
				continue
			var collider: Node = hit["collider"] as Node
			if collider == null or not warrens.is_ancestor_of(collider):
				continue
			var reach: float = eye.distance_to(hit["position"] as Vector3)
			if reach < 12.0:
				continue
			found.append({"eye": eye, "angle": angle, "reach": reach})
	found.sort_custom(func(a, b): return float(a["reach"]) > float(b["reach"]))
	var picked: Array = []
	for candidate: Dictionary in found:
		var far_enough := true
		for already: Dictionary in picked:
			if absf(wrapf(float(candidate["angle"]) - float(already["angle"]), -PI, PI)) < 1.2:
				far_enough = false
		if far_enough:
			picked.append(candidate)
		if picked.size() == 2:
			break
	var out: Array = []
	for index in picked.size():
		out.append({
			"name": "W-ext-%02d-knoll-from-outside" % (index + 1),
			"eye": (picked[index]["eye"] as Vector3),
			"target": aim,
		})
	return out
