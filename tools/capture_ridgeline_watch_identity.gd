extends SceneTree

## Focused production-scene evidence for the named Ridgeline Watch.
##
## Captures the ordinary watchtower-spur approach and the canonical north-side
## bearing, with a third pair proving that the service shelter survives day and
## night. The R4 player stands were only 15m and 7.6m from a roughly 20m-tall
## subject, so even a production 70-degree lens necessarily cropped the watch.
## R5 extends those same bearings to honest walked positions and tries a short,
## fixed list of nearby alternatives when production physics hides the watch.
## The player remains 5.2m in front of the camera at every candidate: these are
## normal third-person compositions, not detached telephoto evidence.
##
## Run with a real Compatibility renderer, never `--headless`:
##
##   godot --path . --rendering-driver opengl3 --resolution 1280x720 \
##     --script tools/capture_ridgeline_watch_identity.gd

const WATCH := preload("res://scripts/world/ridgeline_watch.gd")
const SCENE := "res://scenes/world/meadows_playground.tscn"
const OUT_DIR := "res://ralph/reports/MEADOWS-0912/RIDGELINE-WATCH-R5-FRAMED"
const FRESH_OUTPUT := preload("res://tools/fresh_capture_output.gd")
const CAPTURE_CHECK := preload("res://tools/capture_check.gd")
const READY_TIMEOUT_MS := 420_000
const CAMERA_BACK_M := 5.2
const CAMERA_UP_M := 2.65
const FOV := 70.0

## Each candidate is a player stand. The evidence camera remains the ordinary
## CAMERA_BACK_M behind it on the subject bearing. Primary route candidates
## stay on the vector from SITE through ORDINARY_APPROACH; the small lateral
## offsets are deterministic escape hatches for production trees, never edits
## to world art or actors.
const ROUTE_CANDIDATES := [
	{"id": "route-34m", "at": Vector2(-260.4, 6451.8)},
	{"id": "route-38m-west", "at": Vector2(-267.0, 6449.0)},
	{"id": "route-38m-east", "at": Vector2(-258.5, 6446.0)},
]
const CANONICAL_CANDIDATES := [
	{"id": "canonical-north-34m", "at": Vector2(-260.4, 6514.2)},
	{"id": "canonical-northwest-38m", "at": Vector2(-271.5, 6512.0)},
	{"id": "canonical-northeast-38m", "at": Vector2(-250.5, 6521.0)},
]

const VIEWS := [
	{"name": "01-route-arrival-day", "candidates": ROUTE_CANDIDATES, "look": WATCH.SITE, "time": "day", "aim_up": 9.0, "subject": "watch"},
	{"name": "02-route-arrival-night", "candidates": ROUTE_CANDIDATES, "look": WATCH.SITE, "time": "night", "aim_up": 9.0, "subject": "watch"},
	{"name": "03-canonical-watch-day", "candidates": CANONICAL_CANDIDATES, "look": WATCH.SITE, "time": "day", "aim_up": 9.0, "subject": "watch"},
	{"name": "04-canonical-watch-night", "candidates": CANONICAL_CANDIDATES, "look": WATCH.SITE, "time": "night", "aim_up": 9.0, "subject": "watch"},
	{"name": "05-service-shelter-day", "at": Vector2(-236.0, 6470.0), "look": WATCH.SITE + WATCH.SERVICE_SHELTER_CENTRE, "time": "day", "aim_up": 2.1, "subject": "service"},
	{"name": "06-service-shelter-night", "at": Vector2(-236.0, 6470.0), "look": WATCH.SITE + WATCH.SERVICE_SHELTER_CENTRE, "time": "night", "aim_up": 2.1, "subject": "service"},
]


func _init() -> void:
	_run()


func _run() -> void:
	if not FRESH_OUTPUT.create_fresh(OUT_DIR, "Ridgeline Watch R5 capture"):
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

	var watch := world.get_node_or_null(^"RidgelineWatch") as Node3D
	var player := world.get_node_or_null(^"Player") as Node3D
	var look := world.get_node_or_null(^"WorldLook")
	var weather := world.get_node_or_null(^"WorldWeather")
	var rig := world.get_node_or_null(^"CameraRig")
	if watch == null or player == null or look == null:
		push_error("capture requires RidgelineWatch, Player and WorldLook")
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
	for overlay_path: NodePath in [
		^"PlaygroundHUD", ^"CombatHUD", ^"DialoguePanel", ^"NamePrompt", ^"StarterPicker"
	]:
		var overlay := world.get_node_or_null(overlay_path)
		if overlay != null:
			overlay.set("visible", false)
			overlay.process_mode = Node.PROCESS_MODE_DISABLED
	player.process_mode = Node.PROCESS_MODE_DISABLED
	if player is CharacterBody3D:
		(player as CharacterBody3D).velocity = Vector3.ZERO

	var camera := Camera3D.new()
	camera.name = "RidgelineWatchEvidenceCamera"
	camera.fov = FOV
	camera.far = 2000.0
	world.add_child(camera)
	camera.make_current()

	var records: Array[Dictionary] = []
	var failures: Array[String] = []
	for raw in VIEWS:
		var view: Dictionary = raw
		look.call("apply_time", str(view.time))
		var target: Vector2 = view.look
		var subject := watch if str(view.subject) == "watch" \
			else watch.get_node_or_null(^"WatchServiceShelter") as Node3D
		var subject_box: Variant = _node_world_aabb(subject)
		if subject == null or subject_box == null:
			failures.append("%s: named %s subject is missing" % [str(view.name), str(view.subject)])
			continue
		var candidates: Array = view.candidates if view.has("candidates") \
			else [{"id": "retained-service", "at": view.at}]
		var selected := await _select_candidate(world, player, camera, target,
			float(view.aim_up), subject_box as AABB, subject, candidates,
			str(view.subject) == "watch")
		if selected.is_empty():
			failures.append("%s: no deterministic gameplay camera candidate passed production readability: %s" % [
				str(view.name), " | ".join(_candidate_failures)])
			continue
		var stand: Vector2 = selected.at
		for i in 60:
			await physics_frame
		for i in 6:
			await process_frame
		await RenderingServer.frame_post_draw
		var readable := CAPTURE_CHECK.readable_problems_for_camera(camera, [{
			"name": "Ridgeline Watch" if str(view.subject) == "watch" else "Watch service shelter",
			"aabb": subject_box as AABB,
			"body": watch,
		}], {
			"min_height_frac": 0.16 if str(view.subject) == "watch" else 0.13,
			"min_inside_frac": 0.82,
			"max_height_frac": 0.88,
			"space": world.get_world_3d().direct_space_state,
		})
		readable.append_array(_player_readability(camera, player, stand,
			float(world.call("ground_height_at", stand.x, stand.y)), world))
		if not readable.is_empty():
			failures.append("%s: refused unreadable subject: %s" % [str(view.name), " | ".join(readable)])
			continue
		var image := root.get_texture().get_image()
		if image == null or image.is_empty():
			failures.append("%s: viewport returned no image" % str(view.name))
			continue
		var out_path := "%s/%s.png" % [OUT_DIR, str(view.name)]
		if image.save_png(out_path) != OK:
			failures.append("%s: save_png failed" % str(view.name))
			continue
		records.append({
			"frame": str(view.name),
			"time": str(view.time),
			"player_xz": [player.global_position.x, player.global_position.z],
			"camera_to_player_m": camera.global_position.distance_to(player.global_position),
			"camera_candidate": str(selected.id),
			"camera_xz": [camera.global_position.x, camera.global_position.z],
			"watch_distance_m": stand.distance_to(WATCH.SITE),
			"image_size": [image.get_width(), image.get_height()],
		})
		print("wrote %s" % out_path)

	var manifest := {
		"production_scene": SCENE,
		"named_location": "The Ridgeline Watch",
		"runtime_node": "RidgelineWatch",
		"fixture_disclosure": "Production Meadows scene and player, HUD/modal overlays hidden for composition review, clear-weather/time pin, production 70-degree third-person camera at 5.2m stand-off. R5 selects the first fixed walked-position candidate that passes projected size, crop and production-physics occlusion gates. Player processing and velocity pause only to hold that honest gameplay coordinate; no art or actor movement, hiding or injection.",
		"complete": failures.is_empty() and records.size() == VIEWS.size(),
		"frames": records,
		"failures": failures,
	}
	var file := FileAccess.open("%s/manifest.json" % OUT_DIR, FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(manifest, "\t") + "\n")
		file.close()
	else:
		failures.append("manifest could not be written")

	quit(0 if failures.is_empty() else 1)


var _candidate_failures: Array[String] = []


func _select_candidate(world: Node, player: Node3D, camera: Camera3D,
		target: Vector2, aim_up: float, subject_box: AABB, subject: Node3D,
		candidates: Array, is_watch: bool) -> Dictionary:
	_candidate_failures.clear()
	for raw_candidate: Variant in candidates:
		var candidate: Dictionary = raw_candidate
		var stand: Vector2 = candidate.at
		var stand_ground := float(world.call("ground_height_at", stand.x, stand.y))
		if is_nan(stand_ground):
			_candidate_failures.append("%s has no production ground" % str(candidate.id))
			continue
		var toward := (target - stand).normalized()
		var eye_xz := stand - toward * CAMERA_BACK_M
		var eye_ground := float(world.call("ground_height_at", eye_xz.x, eye_xz.y))
		if is_nan(eye_ground):
			_candidate_failures.append("%s camera has no production ground" % str(candidate.id))
			continue
		player.global_position = Vector3(stand.x, stand_ground + 0.35, stand.y)
		if player is CharacterBody3D:
			(player as CharacterBody3D).velocity = Vector3.ZERO
		player.rotation.y = atan2(toward.x, toward.y)
		camera.global_position = Vector3(eye_xz.x, eye_ground + CAMERA_UP_M, eye_xz.y)
		var target_ground := float(world.call("ground_height_at", target.x, target.y))
		camera.look_at(Vector3(target.x, target_ground + aim_up, target.y), Vector3.UP)
		for i in 8:
			await physics_frame
		for i in 2:
			await process_frame
		var problems := CAPTURE_CHECK.readable_problems_for_camera(camera, [{
			"name": "Ridgeline Watch" if is_watch else "Watch service shelter",
			"aabb": subject_box,
			"body": subject,
		}], {
			"min_height_frac": 0.16 if is_watch else 0.13,
			"min_inside_frac": 0.82,
			"max_height_frac": 0.88,
			"space": world.get_world_3d().direct_space_state,
		})
		problems.append_array(_player_readability(camera, player, stand, stand_ground, world))
		if problems.is_empty():
			return candidate
		_candidate_failures.append("%s: %s" % [str(candidate.id), " / ".join(problems)])
	return {}


func _player_readability(camera: Camera3D, player: Node3D, stand: Vector2,
		stand_ground: float, world: Node) -> Array[String]:
	return CAPTURE_CHECK.readable_problems_for_camera(camera, [{
		"name": "ordinary player context",
		"aabb": CAPTURE_CHECK.body_box(Vector3(stand.x, stand_ground, stand.y), 1.8, 0.45),
		"body": player,
	}], {
		"min_height_frac": 0.12,
		"min_inside_frac": 0.72,
		"max_height_frac": 0.72,
		"space": world.get_world_3d().direct_space_state,
	})


func _wait_for_world(world: Node) -> bool:
	var deadline := Time.get_ticks_msec() + READY_TIMEOUT_MS
	while Time.get_ticks_msec() < deadline:
		if world.has_method("shell_build_complete") and bool(world.call("shell_build_complete")):
			return true
		await physics_frame
	return false


func _node_world_aabb(node: Node3D) -> Variant:
	if node == null:
		return null
	var result: Variant = null
	if node is VisualInstance3D and node.is_visible_in_tree():
		result = node.global_transform * (node as VisualInstance3D).get_aabb()
	for child: Node in node.get_children():
		if child is Node3D:
			var child_box: Variant = _node_world_aabb(child as Node3D)
			if child_box != null:
				result = (result as AABB).merge(child_box as AABB) if result != null else child_box
	return result
