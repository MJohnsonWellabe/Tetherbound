extends SceneTree

## One-boot production receipt for the 2026-09-12 Meadows wayfinding and
## south-trail world-content work. It captures the current South Bridge
## objective beam from an actual road-distance approach and near its base, then
## captures the Long Field wayfarer signal and both fixed pre-camp creature
## groups from their authored road seats. Every view is matched day/night.
##
## Use a fresh output directory and the real Compatibility renderer, never
## --headless. The tool refuses to open an output directory that already exists:
##   godot --path . --rendering-method gl_compatibility --rendering-driver opengl3 \
##     --resolution 1280x720 \
##     --script tools/capture_meadows_0912_wayfinding_and_pulls.gd \
##     -- --output=res://ralph/reports/MEADOWS-0912/wayfinding-pulls-R1

const SCENE := "res://scenes/world/meadows_playground.tscn"
const CAPTURE_CHECK := preload("res://tools/capture_check.gd")
const OBJECTIVES_PATH := "res://data/progression/objectives.json"
const TARGET_OBJECTIVE_ID := "head_to_south_bridge"
const OBJECTIVE_AT := Vector2(14.0, 1314.0)
const WAYFARER_AT := Vector2(160.0, 710.0)
const CAPTURE_SIZE := Vector2i(1280, 720)
const READY_TIMEOUT_MS := 420_000
const TIMES: Array[String] = ["day", "night"]
const SUBJECT_COUNTS := {1913: 3, 1914: 3, 1915: 3}

## All road stands are literal points from band1_lower_meadows's production
## trail polyline. The one `detour` stand is inside the authored signal site.
const VIEWS: Array[Dictionary] = [
	{"id": "01-objective-road-approach", "kind": "objective", "seat": "road",
		"stand": Vector2(360.0, 910.0), "target": OBJECTIVE_AT,
		"back": 5.2, "up": 2.7, "aim_up": 38.0, "fov": 62.0,
		"orders": [], "hud": true},
	{"id": "02-objective-near-destination", "kind": "objective", "seat": "road",
		"stand": Vector2(30.0, 1250.0), "target": OBJECTIVE_AT,
		"back": 5.2, "up": 2.7, "aim_up": 14.0, "fov": 68.0,
		"orders": [], "hud": true},
	{"id": "03-wayfarer-signal-from-road", "kind": "wayfarer_signal", "seat": "road",
		"stand": Vector2(90.0, 760.0), "target": WAYFARER_AT,
		"back": 5.2, "side": 1.8, "up": 2.45, "aim_up": 1.6, "fov": 58.0,
		"orders": [1915], "hud": false},
	{"id": "04-wayfarer-signal-at-detour", "kind": "wayfarer_signal", "seat": "detour",
		"stand": Vector2(150.0, 722.0), "target": WAYFARER_AT,
		"back": 5.2, "side": 1.8, "up": 2.45, "aim_up": 1.35, "fov": 68.0,
		"orders": [1915], "hud": false},
	{"id": "05-trailpup-sightline-from-road", "kind": "south_trail_creatures", "seat": "road",
		"stand": Vector2(132.0, 781.0), "target": Vector2(170.0, 815.0),
		"back": 5.2, "up": 2.45, "aim_up": 1.15, "fov": 62.0,
		"orders": [1913], "hud": false},
	{"id": "06-bramblebun-sightline-from-road", "kind": "south_trail_creatures", "seat": "road",
		"stand": Vector2(230.0, 830.0), "target": Vector2(275.0, 862.0),
		"back": 5.2, "up": 2.45, "aim_up": 1.15, "fov": 62.0,
		"orders": [1914], "hud": false},
]

var _output_dir := ""
var _game: Node = null
var _world: Node3D = null
var _player: Node3D = null
var _look: Node = null
var _weather: Node = null
var _director: Node = null
var _beacon: Node3D = null
var _hud: CanvasLayer = null
var _camera: Camera3D = null
var _failures: Array[String] = []
var _records: Array[Dictionary] = []
var _manifest: Dictionary = {}
var _started_utc := ""


func _init() -> void:
	_run.call_deferred()


static func capture_plan() -> Array[Dictionary]:
	return VIEWS.duplicate(true)


static func requested_output(args: Array[String]) -> String:
	var found := ""
	for argument: String in args:
		if argument.begins_with("--output="):
			found = argument.trim_prefix("--output=").strip_edges().trim_suffix("/")
	return found


static func valid_output_request(path: String) -> bool:
	return path.begins_with("res://") and path.length() > "res://".length() \
		and not path.contains("..") and not path.contains("\\")


func _run() -> void:
	_output_dir = requested_output(OS.get_cmdline_user_args())
	if not valid_output_request(_output_dir):
		push_error("Meadows wayfinding capture requires a unique --output=res://... directory")
		quit(1)
		return
	var absolute := ProjectSettings.globalize_path(_output_dir)
	if DirAccess.dir_exists_absolute(absolute):
		push_error("capture output already exists; choose a new evidence directory: %s" % _output_dir)
		quit(1)
		return
	if DirAccess.make_dir_recursive_absolute(absolute) != OK:
		push_error("could not create capture output: %s" % _output_dir)
		quit(1)
		return

	_started_utc = Time.get_datetime_string_from_system(true)
	_begin_manifest()
	_write_manifest()
	if DisplayServer.get_name() == "headless":
		_failures.append("headless display server cannot produce production render evidence")
		_finish(false)
		return
	if RenderingServer.get_current_rendering_method() != "gl_compatibility":
		_failures.append("capture requires the Compatibility/gl_compatibility renderer")
		_finish(false)
		return
	DisplayServer.window_set_size(CAPTURE_SIZE)
	root.size = CAPTURE_SIZE
	await process_frame
	if root.size != CAPTURE_SIZE:
		_failures.append("viewport is %s, expected %s" % [root.size, CAPTURE_SIZE])
		_finish(false)
		return
	if not _prepare_game_for_objective():
		_finish(false)
		return

	var packed := load(SCENE) as PackedScene
	if packed == null:
		_failures.append("production Meadows scene did not load")
		_finish(false)
		return
	_world = packed.instantiate() as Node3D
	if _world == null:
		_failures.append("production Meadows scene did not instantiate as Node3D")
		_finish(false)
		return
	root.add_child(_world)
	current_scene = _world
	_manifest["scene_load_count"] = 1
	_manifest["scene_instance_id"] = _world.get_instance_id()
	_write_manifest()
	if not await _wait_for_world():
		_failures.append("production Meadows shell/content did not become ready")
		_finish(false)
		return
	if not _bind_runtime():
		_finish(false)
		return
	_prepare_presentation()

	for view: Dictionary in VIEWS:
		if not await _seat_and_frame(view):
			continue
		for time_name: String in TIMES:
			await _capture(view, time_name)
		_director.set_process(true)
	_finish(_failures.is_empty() and _records.size() == VIEWS.size() * TIMES.size())


func _prepare_game_for_objective() -> bool:
	_game = root.get_node_or_null(^"Game")
	if _game == null:
		_failures.append("Game autoload is missing")
		return false
	_game.call("reset_for_new_game")
	_game.set("world_seed", 0)
	_game.set("current_realm", "meadows")
	var progression: RefCounted = _game.get("progression")
	if progression == null:
		_failures.append("Game progression store is missing")
		return false
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(OBJECTIVES_PATH))
	if not parsed is Dictionary:
		_failures.append("Meadows objective data is invalid")
		return false
	var found := false
	var injected: Array[String] = []
	for raw: Variant in ((parsed as Dictionary).get("main", []) as Array):
		var entry := raw as Dictionary
		if str(entry.get("id", "")) == TARGET_OBJECTIVE_ID:
			found = true
			break
		var flag := str(entry.get("flag_id", ""))
		if not flag.is_empty():
			progression.call("set_flag", flag)
			injected.append(flag)
	if not found:
		_failures.append("target objective '%s' is not authored" % TARGET_OBJECTIVE_ID)
		return false
	_manifest["objective_fixture"] = {
		"target_id": TARGET_OBJECTIVE_ID,
		"target_xz": [OBJECTIVE_AT.x, OBJECTIVE_AT.y],
		"prior_flags_set_in_memory": injected,
		"saved_to_campaign": false,
	}
	_write_manifest()
	return true


func _wait_for_world() -> bool:
	var deadline := Time.get_ticks_msec() + READY_TIMEOUT_MS
	while Time.get_ticks_msec() < deadline:
		if _world.has_method("shell_build_complete") and bool(_world.call("shell_build_complete")):
			var director := _world.get_node_or_null(^"EncounterDirector")
			if director != null and director.has_method("wild_creatures") \
					and _all_required_subjects_exist(director):
				return true
		await physics_frame
	return false


func _all_required_subjects_exist(director: Node) -> bool:
	for order_raw: Variant in SUBJECT_COUNTS:
		var order := int(order_raw)
		if _bodies_for_order(director, order).size() != int(SUBJECT_COUNTS[order]):
			return false
	return _world.find_child("WayfarerSignalFire", true, false) != null \
		and _world.find_child("BandPickup_b1_candy_wayfarer_signal", true, false) != null \
		and _world.find_child("BandPickup_b1_potion_wayfarer_signal", true, false) != null


func _bind_runtime() -> bool:
	_player = _world.get_node_or_null(^"Player") as Node3D
	_look = _world.get_node_or_null(^"WorldLook")
	_weather = _world.get_node_or_null(^"WorldWeather")
	_director = _world.get_node_or_null(^"EncounterDirector")
	_beacon = _world.get_node_or_null(^"ObjectiveBeacon") as Node3D
	_hud = _world.get_node_or_null(^"PlaygroundHUD") as CanvasLayer
	if _player == null or _look == null or _director == null or _beacon == null:
		_failures.append("capture requires production Player, WorldLook, EncounterDirector and ObjectiveBeacon")
		return false
	_beacon.call("refresh_now")
	if str(_beacon.call("active_objective_id")) != TARGET_OBJECTIVE_ID:
		_failures.append("ObjectiveBeacon did not select '%s'" % TARGET_OBJECTIVE_ID)
		return false
	if Vector2(_beacon.global_position.x, _beacon.global_position.z).distance_to(OBJECTIVE_AT) > 0.25:
		_failures.append("ObjectiveBeacon is not at the South Bridge objective destination")
		return false
	var ping_visual := _beacon.get_node_or_null(^"PingVisual") as Node3D
	var destination_label := _beacon.get_node_or_null(^"PingVisual/DestinationLabel") as Label3D
	if ping_visual == null or not ping_visual.is_visible_in_tree() or destination_label == null \
			or destination_label.text.strip_edges().is_empty():
		_failures.append("ObjectiveBeacon visual/label is not active")
		return false
	return true


func _prepare_presentation() -> void:
	# The ordinary fresh Meadows boot deploys the active party creature. These
	# frames judge distant route signals, so put it away through the production
	# control seam instead of hiding or moving its body for the camera.
	var companion: Node3D = _director.call("ally_body") as Node3D
	if companion != null:
		if not _director.has_method("dismiss_active_creature") \
				or not bool(_director.call("dismiss_active_creature")):
			_failures.append("production companion dismissal failed before route capture")
		_manifest["companion_dismissed_through_production_path"] = true
	else:
		_manifest["companion_dismissed_through_production_path"] = false
	var rig := _world.get_node_or_null(^"CameraRig")
	if rig != null:
		rig.set_process(false)
		rig.set_physics_process(false)
	_player.set_process(false)
	_player.set_physics_process(false)
	if _player is CharacterBody3D:
		(_player as CharacterBody3D).velocity = Vector3.ZERO
	if _weather != null:
		if _weather.has_method("set_weather"):
			_weather.call("set_weather", "clear")
		_weather.set_process(false)
		_weather.set_physics_process(false)
	if _look.has_method("set_clock_frozen"):
		_look.call("set_clock_frozen", true)
	_look.set_process(false)
	_look.set_physics_process(false)
	var overlay := _world.find_child("SubmersionOverlay", true, false) as CanvasLayer
	if overlay != null:
		overlay.visible = false
	_camera = Camera3D.new()
	_camera.name = "Meadows0912WayfindingPullsEvidenceCamera"
	_camera.far = 2400.0
	_world.add_child(_camera)
	_camera.make_current()


func _seat_and_frame(view: Dictionary) -> bool:
	_director.set_process(true)
	var stand: Vector2 = view.stand
	var target: Vector2 = view.target
	var toward := (target - stand).normalized()
	var stand_y := float(_world.call("ground_height_at", stand.x, stand.y))
	# A small production-style shoulder offset keeps the player from sitting
	# directly over the fire/reward line. Round 02's centred diagnostic camera
	# hid the 15m signal behind the player even after reaching the detour.
	var right := Vector2(-toward.y, toward.x)
	var eye_xz := stand - toward * float(view.back) + right * float(view.get("side", 0.0))
	var eye_y := float(_world.call("ground_height_at", eye_xz.x, eye_xz.y))
	if not is_finite(stand_y) or not is_finite(eye_y):
		_failures.append("%s: initial terrain sample is not finite" % str(view.id))
		return false
	_player.global_position = Vector3(stand.x, stand_y + 0.30, stand.y)
	_camera.global_position = Vector3(eye_xz.x, eye_y + float(view.up), eye_xz.y)
	_camera.fov = float(view.fov)
	_camera.look_at(Vector3(target.x, float(_world.call("ground_height_at", target.x, target.y))
		+ float(view.aim_up), target.y), Vector3.UP)
	for _frame in 48:
		await physics_frame
	stand_y = _surface(stand)
	eye_y = _surface(eye_xz)
	if not is_finite(stand_y) or not is_finite(eye_y):
		_failures.append("%s: live collision surface is not finite" % str(view.id))
		return false
	_player.global_position = Vector3(stand.x, stand_y + 0.30, stand.y)
	_player.rotation.y = atan2(toward.x, toward.y)
	_player.reset_physics_interpolation()
	_camera.global_position = Vector3(eye_xz.x, eye_y + float(view.up), eye_xz.y)
	var target_y := float(_world.call("ground_height_at", target.x, target.y))
	_camera.look_at(Vector3(target.x, target_y + float(view.aim_up), target.y), Vector3.UP)
	_camera.reset_physics_interpolation()
	for _frame in 12:
		await physics_frame
	_director.set_process(false)
	for order_raw: Variant in (view.orders as Array):
		var order := int(order_raw)
		for body: Node3D in _bodies_for_order(_director, order):
			body.call("revive_at_home")
			body.set_physics_process(false)
	for _frame in 8:
		await process_frame
	return true


func _capture(view: Dictionary, time_name: String) -> void:
	_look.call("apply_time", time_name)
	if _look.has_method("set_clock_frozen"):
		_look.call("set_clock_frozen", true)
	var observed_time := time_name
	if _look.has_method("time_of_day"):
		observed_time = str(_look.call("time_of_day"))
		if observed_time != time_name:
			_failures.append("%s-%s: WorldLook reports '%s'" % [view.id, time_name, observed_time])
			return
	if _hud != null:
		_hud.visible = bool(view.hud)
	for _frame in 8:
		await process_frame
	var capture_problems: Array[String] = []
	if str(view.kind) == "wayfarer_signal":
		capture_problems = _wayfarer_readability_problems()
	if not capture_problems.is_empty():
		_failures.append("%s-%s: refused unreadable production frame: %s" % [
			str(view.id), time_name, " | ".join(capture_problems)])
		return
	await RenderingServer.frame_post_draw
	var frame_id := "%s-%s" % [str(view.id), time_name]
	var path := "%s/%s.png" % [_output_dir, frame_id]
	if FileAccess.file_exists(path):
		_failures.append("%s: output image already exists" % frame_id)
		return
	var image := root.get_texture().get_image()
	if image == null or image.is_empty() or image.save_png(path) != OK:
		_failures.append("%s: viewport capture/save failed" % frame_id)
		return
	var record := {
		"frame_id": frame_id,
		"file": path,
		"bytes": FileAccess.get_file_as_bytes(path).size(),
		"kind": str(view.kind),
		"seat": str(view.seat),
		"requested_time": time_name,
		"observed_time": observed_time,
		"hud_visible": bool(view.hud),
		"stand_xz": [float(view.stand.x), float(view.stand.y)],
		"target_xz": [float(view.target.x), float(view.target.y)],
		"target_distance_m": (view.stand as Vector2).distance_to(view.target as Vector2),
		"camera_xyz": _vec3(_camera.global_position),
		"camera_side_m": float(view.get("side", 0.0)),
		"player_xyz": _vec3(_player.global_position),
		"image_size": [image.get_width(), image.get_height()],
		"subjects": _subject_records(view),
	}
	_records.append(record)
	_write_manifest()
	print("MEADOWS 0912 CAPTURE %s -> %s" % [frame_id, path])


## Fail closed on the three pieces that make this a road pull rather than a
## receipt that objects merely exist: signal/smoke, one living silhouette,
## and one reward accent. Each candidate uses the shared projection and
## production-physics occlusion checks. The accepted subject may differ as
## the deterministic herd settles, but the frame cannot pass with all three
## animals or both rewards hidden.
func _wayfarer_readability_problems() -> Array[String]:
	var out := CAPTURE_CHECK.problems(self, _camera, "clear", null, [_player])
	var fire := _world.find_child("WayfarerSignalFire", true, false) as Node3D
	out.append_array(_readable_node_problems(fire, "wayfarer signal/smoke", 0.02))

	var herd: Array[Node3D] = _bodies_for_order(_director, 1915)
	out.append_array(_at_least_one_readable(herd, "wayfarer Meadowhart", 0.012))

	var rewards: Array[Node3D] = []
	for node_name: String in ["BandPickup_b1_candy_wayfarer_signal",
			"BandPickup_b1_potion_wayfarer_signal"]:
		var reward := _world.find_child(node_name, true, false) as Node3D
		if reward != null:
			rewards.append(reward)
	out.append_array(_at_least_one_readable(rewards, "wayfarer reward", 0.007))
	return out


func _at_least_one_readable(nodes: Array[Node3D], label: String,
		min_height_frac: float) -> Array[String]:
	var candidate_findings: Array[String] = []
	for node: Node3D in nodes:
		var findings := _readable_node_problems(node, "%s %s" % [label, node.name],
			min_height_frac)
		if findings.is_empty():
			return []
		candidate_findings.append("%s: %s" % [node.name, " / ".join(findings)])
	return ["no readable %s (%s)" % [label,
		"; ".join(candidate_findings) if not candidate_findings.is_empty() else "none present"]]


func _readable_node_problems(node: Node3D, label: String,
		min_height_frac: float) -> Array[String]:
	if node == null:
		return ["%s is missing" % label]
	var box_value: Variant = _node_world_aabb(node)
	if box_value == null:
		return ["%s has no visible production geometry" % label]
	return CAPTURE_CHECK.readable_problems_for_camera(_camera, [{
		"name": label,
		"aabb": box_value as AABB,
		"body": _production_collision_owner(node),
	}], {
		"min_height_frac": min_height_frac,
		"min_inside_frac": 0.75,
		"max_height_frac": 0.62,
		"max_overlap_frac": 0.0,
	})


func _production_collision_owner(node: Node3D) -> Node:
	var parent := node.get_parent()
	if parent != null:
		var sibling := parent.get_node_or_null(NodePath("%s_Collision" % node.name))
		if sibling is CollisionObject3D:
			return sibling
	return node


func _node_world_aabb(node: Node3D) -> Variant:
	var result: Variant = null
	if node is VisualInstance3D and node.is_visible_in_tree():
		result = node.global_transform * (node as VisualInstance3D).get_aabb()
	for child: Node in node.get_children():
		if child is Node3D:
			var child_box: Variant = _node_world_aabb(child as Node3D)
			if child_box != null:
				result = (result as AABB).merge(child_box as AABB) if result != null else child_box
	return result


func _subject_records(view: Dictionary) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for order_raw: Variant in (view.orders as Array):
		var order := int(order_raw)
		for body: Node3D in _bodies_for_order(_director, order):
			out.append({"kind": "authored_creature", "order": order, "name": str(body.name),
				"species_id": str(body.get("species_id")), "visible": body.is_visible_in_tree(),
				"xyz": _vec3(body.global_position)})
	if str(view.kind) == "objective":
		var ping_visual := _beacon.get_node_or_null(^"PingVisual") as Node3D
		var destination_label := _beacon.get_node_or_null(^"PingVisual/DestinationLabel") as Label3D
		out.append({"kind": "objective_beacon", "active_id": str(_beacon.call("active_objective_id")),
			"visual_visible": ping_visual != null and ping_visual.is_visible_in_tree(),
			"label": destination_label.text if destination_label != null else "",
			"xyz": _vec3(_beacon.global_position)})
	elif str(view.kind) == "wayfarer_signal":
		for node_name: String in ["WayfarerSignalFire", "BandPickup_b1_candy_wayfarer_signal",
				"BandPickup_b1_potion_wayfarer_signal"]:
			var node := _world.find_child(node_name, true, false) as Node3D
			if node != null:
				out.append({"kind": "wayfarer_site", "name": node_name,
					"visible": node.is_visible_in_tree(), "xyz": _vec3(node.global_position)})
	return out


func _bodies_for_order(director: Node, order: int) -> Array[Node3D]:
	var out: Array[Node3D] = []
	var needle := "_%d_" % order
	for body: Node3D in (director.call("wild_creatures") as Array[Node3D]):
		var body_name := str(body.name) if is_instance_valid(body) else ""
		if body_name.begins_with("Wild_") and body_name.contains(needle):
			out.append(body)
	return out


func _surface(at: Vector2) -> float:
	var analytic := float(_world.call("ground_height_at", at.x, at.y))
	if not is_finite(analytic):
		return NAN
	var query := PhysicsRayQueryParameters3D.create(
		Vector3(at.x, analytic + 4.0, at.y), Vector3(at.x, analytic - 6.0, at.y))
	query.collide_with_areas = false
	if _player is CollisionObject3D:
		query.exclude = [(_player as CollisionObject3D).get_rid()]
	var hit := _world.get_world_3d().direct_space_state.intersect_ray(query)
	return analytic if hit.is_empty() else float((hit.position as Vector3).y)


func _begin_manifest() -> void:
	var planned: Array[Dictionary] = []
	for view: Dictionary in VIEWS:
		for time_name: String in TIMES:
			planned.append({"frame_id": "%s-%s" % [view.id, time_name], "kind": view.kind,
				"seat": view.seat, "time": time_name, "orders": view.orders})
	_manifest = {
		"schema_version": 1,
		"capture_started_utc": _started_utc,
		"output_directory": _output_dir,
		"production_scene": SCENE,
		"scene_load_count": 0,
		"fixture_disclosure": (
			"One production Meadows boot with real Terrain3D, scatter, props, pickups, "
			+ "EncounterDirector residents, ObjectiveBeacon, WorldLook and player body. "
			+ "The objective-only fixture resets Game in memory and sets the production "
			+ "objective chain's prior flags so South Bridge is current; no campaign save "
			+ "is written. Authored orders 1913-1915 are reset to their deterministic homes "
			+ "and movement-frozen after each road seat streams, preventing elapsed AI time "
			+ "from changing matched day/night evidence. Clear weather/time are pinned; the "
			+ "production HUD is visible only in objective frames. Fixed third-person evidence "
			+ "camera; no creature, prop, pickup, route, terrain, light or art injection."
		),
		"capture_size": [CAPTURE_SIZE.x, CAPTURE_SIZE.y],
		"expected_frame_count": VIEWS.size() * TIMES.size(),
		"planned_frames": planned,
		"frames": [],
		"failures": [],
		"complete": false,
	}


func _write_manifest() -> void:
	_manifest["frames"] = _records
	_manifest["failures"] = _failures
	var file := FileAccess.open("%s/manifest.json" % _output_dir, FileAccess.WRITE)
	if file == null:
		if not _failures.has("manifest could not be written"):
			_failures.append("manifest could not be written")
		push_error("could not write Meadows 0912 capture manifest")
		return
	file.store_string(JSON.stringify(_manifest, "\t") + "\n")
	file.close()


func _finish(requested_complete: bool) -> void:
	_manifest["capture_finished_utc"] = Time.get_datetime_string_from_system(true)
	_manifest["captured_frame_count"] = _records.size()
	_manifest["complete"] = requested_complete and _failures.is_empty() \
		and _records.size() == int(_manifest.get("expected_frame_count", -1))
	_write_manifest()
	quit(0 if bool(_manifest.complete) else 1)


func _vec3(value: Vector3) -> Array[float]:
	return [value.x, value.y, value.z]
