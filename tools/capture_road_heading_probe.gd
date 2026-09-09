extends SceneTree

## One disclosed graphical reproduction of the sample 37 -> 43 road segment.
##
## This tool mounts the unmodified Meadows production scene, uses the Settings
## catalogue's debug travel once to establish sample 37, then walks the exact
## historical sample waypoints with the shared stick navigator. Camera changes
## go through the production look actions. It does not write campaign state,
## move actors directly, change spawns, or judge rendered silhouettes.

const NAVIGATOR := preload("res://tests/helpers/stick_navigator.gd")
const OBSERVER := preload("res://tests/helpers/four_biome_road_coverage_observer.gd")
const SCENE := "res://scenes/world/meadows_playground.tscn"
const OUTPUT_SIZE := Vector2i(1280, 720)
const BUILD_TIMEOUT_MSEC := 900000
const BOOT_SETTLE_FRAMES := 60
const TELEPORT_SETTLE_LIMIT := 240
const GROUND_STABLE_FRAMES := 12
const LOOK_TIMEOUT_FRAMES := 420
const LOOK_STABLE_FRAMES := 10
const LOOK_TOLERANCE_DEG := 0.75
const RECORDED_YAW := deg_to_rad(-17.2375449933173)
const RECORDED_PITCH := deg_to_rad(-24.99841225637508)
const WAYPOINTS := [
	{"sample": 37, "xz": Vector2(15.6616468429565, 15.8377752304077)},
	{"sample": 38, "xz": Vector2(13.4528427124023, 25.5546131134033)},
	{"sample": 39, "xz": Vector2(11.0136871337891, 35.271297454834)},
	{"sample": 40, "xz": Vector2(8.57400512695313, 44.9969215393066)},
	{"sample": 41, "xz": Vector2(6.12584972381592, 54.7262191772461)},
	{"sample": 42, "xz": Vector2(3.31288623809814, 70.1781692504883)},
	{"sample": 43, "xz": Vector2(9.69799041748047, 77.8953475952148)},
]
const PAIR_NAMES := ["Wild_meadowhart_1910_1", "Wild_meadowhart_1910_2"]

var _output_dir := ""
var _launch_head := ""
var _parse_only := false
var _world: Node3D
var _player: CharacterBody3D
var _rig: SpringArm3D
var _camera: Camera3D
var _director: Node
var _look: Node
var _weather: Node
var _navigator: RefCounted
var _observer: RefCounted
var _receipt: FileAccess
var _manifest: Dictionary = {}
var _frames: Array[Dictionary] = []
var _walk_receipts: Array[Dictionary] = []
var _failures: Array[String] = []
var _walking := false
var _walk_previous := Vector3.INF
var _walk_distance_m := 0.0
var _sample_37_position := Vector3.ZERO
var _last_leg_forward := Vector3.ZERO


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	if not _parse_args():
		quit(1)
		return
	if _parse_only:
		print("ROAD HEADING PROBE PARSE OK")
		quit(0)
		return
	if DisplayServer.get_name() == "headless":
		push_error("road heading probe: graphical capture requires a rendering display")
		quit(1)
		return
	if not _prepare_output():
		_finish(false)
		return
	DisplayServer.window_set_size(OUTPUT_SIZE)
	root.size = OUTPUT_SIZE
	await process_frame
	_begin_manifest()
	_write_manifest()
	if root.size != OUTPUT_SIZE:
		_stop("explicit render target is %s, expected %s" % [str(root.size), str(OUTPUT_SIZE)])
		_finish(false)
		return
	if not await _mount_world():
		_finish(false)
		return
	_navigator = NAVIGATOR.new(self, _player, _rig, _drive_stick)
	_observer = OBSERVER.new()
	if not await _establish_sample_37():
		_finish(false)
		return
	if not await _bind_pair("after_sample_37_setup"):
		_finish(false)
		return
	if not await _capture_endpoint(37, "original_recorded_heading", RECORDED_YAW, Vector3.ZERO):
		_finish(false)
		return
	_sample_37_position = _player.global_position
	var outgoing_37 := _historical_tangent(37)
	if not await _capture_endpoint(37, "travel_facing", _yaw_for_forward(outgoing_37), outgoing_37):
		_finish(false)
		return
	_start_walk_meter()
	for index in range(1, WAYPOINTS.size()):
		var waypoint: Dictionary = WAYPOINTS[index]
		if not await _walk_to_waypoint(waypoint):
			_stop_walk_meter()
			_finish(false)
			return
	_stop_walk_meter()
	if not await _capture_endpoint(43, "original_recorded_heading", RECORDED_YAW, Vector3.ZERO):
		_finish(false)
		return
	if _last_leg_forward.is_zero_approx():
		_stop("sample 43 has no measured incoming walking direction")
		_finish(false)
		return
	if not await _capture_endpoint(43, "travel_facing", _yaw_for_forward(_last_leg_forward), _last_leg_forward):
		_finish(false)
		return
	_finish(_failures.is_empty() and _frames.size() == 4)


func _parse_args() -> bool:
	for argument: String in OS.get_cmdline_user_args():
		if argument == "--parse-only":
			_parse_only = true
		elif argument.begins_with("--output="):
			_output_dir = argument.trim_prefix("--output=").strip_edges().trim_suffix("/")
		elif argument.begins_with("--launch-head="):
			_launch_head = argument.trim_prefix("--launch-head=").strip_edges()
	if _parse_only:
		return true
	if _output_dir.is_empty() or not _output_dir.begins_with("res://shots/road-heading/"):
		push_error("road heading probe: --output must be a fresh res://shots/road-heading/<unique> directory")
		return false
	if _launch_head.is_empty():
		push_error("road heading probe: --launch-head is required")
		return false
	return true


func _prepare_output() -> bool:
	var manifest_path := _output_dir.path_join("manifest.json")
	if FileAccess.file_exists(manifest_path):
		_stop("output already contains a manifest: " + manifest_path)
		return false
	var error := DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(_output_dir))
	if error != OK:
		_stop("could not create output directory (%d)" % error)
		return false
	_receipt = FileAccess.open(_output_dir.path_join("walk-receipts.jsonl"), FileAccess.WRITE)
	if _receipt == null:
		_stop("could not create walk receipt stream")
		return false
	return true


func _begin_manifest() -> void:
	_manifest = {
		"schema_version": 1,
		"purpose": "Paired-heading graphical reproduction for ROAD live-gap samples 37 through 43",
		"scene": SCENE,
		"launch_head": _launch_head,
		"capture_started_utc": Time.get_datetime_string_from_system(true),
		"display_server": DisplayServer.get_name(),
		"rendering_method": RenderingServer.get_current_rendering_method(),
		"adapter": RenderingServer.get_video_adapter_name(),
		"render_target_resolution": [root.size.x, root.size.y],
		"logical_visible_rect_at_start": [root.get_visible_rect().size.x, root.get_visible_rect().size.y],
		"recorded_heading_deg": {"yaw": rad_to_deg(RECORDED_YAW), "pitch": rad_to_deg(RECORDED_PITCH)},
		"travel_heading_definition": "Sample 37 uses its outgoing 37->38 waypoint tangent and is checked against measured net walking; sample 43 uses the measured incoming 42->43 walking direction. Each rendered camera-forward dot must exceed 0.9.",
		"fixture_disclosure": "Unmodified production Meadows, live wild spawns and gameplay HUD. One Game.debug_teleport_to(x,z,'meadows') at historical sample 37, then exact sample 38-43 XZ waypoints by shared stick_navigator. Production right-stick look actions only, production FOV, ambient clock and weather. No save copy, progress, inventory, party, HP, spawn, actor transform, camera transform, time, or art mutation.",
		"source_inputs": "res://.artifacts/road-live-gap-paired-heading-inputs.json",
		"source_sha256": "EF4836593FF1F8BE2E4B9C1E8FA603BC5D7B283A10F4E10A7FD8F570B957FA4D",
		"prior_failed_setup": {"output": "res://shots/road-heading/20260909T033505Z",
			"failure": "Logical 1920x1080 visible rect was incorrectly treated as physical output dimensions",
			"frames": 0, "walk_m": 0.0},
		"waypoints": WAYPOINTS,
		"frames": _frames,
		"walk_receipts": _walk_receipts,
		"failures": _failures,
		"complete": false,
		"interpretation_limit": "Observer counts are the existing centre-ray proxy. Rendered silhouettes require an independent blind visual judgment.",
	}


func _mount_world() -> bool:
	var game := root.get_node_or_null(^"Game")
	if game == null:
		_stop("Game autoload is missing")
		return false
	if game.has_method("reset_for_new_game"):
		game.call("reset_for_new_game")
	game.set("current_realm", "meadows")
	var packed := load(SCENE) as PackedScene
	if packed == null:
		_stop("could not load production Meadows scene")
		return false
	_world = packed.instantiate() as Node3D
	root.add_child(_world)
	current_scene = _world
	var deadline := Time.get_ticks_msec() + BUILD_TIMEOUT_MSEC
	while _world.has_method("shell_build_complete") and not bool(_world.call("shell_build_complete")):
		if Time.get_ticks_msec() > deadline:
			_stop("production world shell build timed out")
			return false
		await process_frame
	for _frame in BOOT_SETTLE_FRAMES:
		await physics_frame
	_player = _world.get_node_or_null(^"Player") as CharacterBody3D
	_rig = _world.get_node_or_null(^"CameraRig") as SpringArm3D
	_camera = _world.get_node_or_null(^"CameraRig/Camera3D") as Camera3D
	_director = _world.get_node_or_null(^"EncounterDirector")
	_look = _world.get_node_or_null(^"WorldLook")
	_weather = _world.get_node_or_null(^"WorldWeather")
	if _player == null or _rig == null or _camera == null or _director == null:
		_stop("production Player, CameraRig/Camera3D, or EncounterDirector is missing")
		return false
	if not _director.has_method("wild_creatures"):
		_stop("production EncounterDirector has no wild_creatures reader")
		return false
	_camera.make_current()
	await process_frame
	var logical_viewport := _camera.get_viewport().get_visible_rect().size
	var render_target := root.size
	if render_target != OUTPUT_SIZE:
		_stop("post-mount render target is %s, expected %s" % [str(render_target), str(OUTPUT_SIZE)])
		return false
	_manifest["post_mount_dimensions"] = {"render_target": [render_target.x, render_target.y],
		"logical_camera_viewport": [logical_viewport.x, logical_viewport.y]}
	_receipt_event("world_ready", {"player": _vec3(_player.global_position),
		"render_target": [render_target.x, render_target.y],
		"logical_camera_viewport": [logical_viewport.x, logical_viewport.y]})
	_write_manifest()
	return true


func _establish_sample_37() -> bool:
	_release_inputs()
	var game := root.get_node_or_null(^"Game")
	var at: Vector2 = WAYPOINTS[0].xz
	var moved := game != null and bool(game.call("debug_teleport_to", at.x, at.y, "meadows", ""))
	if not moved:
		_stop("Game.debug_teleport_to refused the disclosed sample 37 setup")
		return false
	if not await _wait_grounded("sample_37_after_debug_travel"):
		return false
	var gap := Vector2(_player.global_position.x, _player.global_position.z).distance_to(at)
	var receipt := _pose_receipt("sample_37_setup")
	receipt["requested_xz"] = [at.x, at.y]
	receipt["gap_m"] = gap
	_walk_receipts.append(receipt)
	_receipt_event("sample_37_setup", receipt)
	_write_manifest()
	if gap > 2.0:
		_stop("debug travel settled %.2fm from sample 37" % gap)
		return false
	return true


func _bind_pair(stage: String) -> bool:
	var found := _pair_nodes()
	var snapshots: Array[Dictionary] = []
	for expected: String in PAIR_NAMES:
		var body: Node3D = found.get(expected) as Node3D
		if body != null:
			snapshots.append(_body_identity(body, expected))
		else:
			snapshots.append({"expected_name": expected, "found": false, "alive": false})
	_receipt_event("pair_binding", {"stage": stage, "pair": snapshots})
	_manifest["pair_binding"] = snapshots
	_write_manifest()
	if found.size() != PAIR_NAMES.size():
		_stop("could not rebind both order-1910 Meadowharts by runtime name/path")
		return false
	return true


func _pair_nodes() -> Dictionary:
	var found := {}
	for candidate in _director.call("wild_creatures"):
		var body := candidate as Node3D
		if body == null or not is_instance_valid(body):
			continue
		var body_name := str(body.name)
		if PAIR_NAMES.has(body_name):
			found[body_name] = body
	return found


func _walk_to_waypoint(waypoint: Dictionary) -> bool:
	var at: Vector2 = waypoint.xz
	var from := _player.global_position
	var straight_m := Vector2(from.x, from.z).distance_to(at)
	var budget := maxi(1200, ceili(straight_m * 90.0))
	var target := Vector3(at.x, _player.global_position.y, at.y)
	var started_frame := Engine.get_physics_frames()
	var arrived := bool(await _navigator.call("walk_to", target, budget, 0.75))
	_drive_stick(0.0, 0.0)
	var receipt := _pose_receipt("sample_%d_walk" % int(waypoint.sample))
	var actual_leg := _player.global_position - from
	actual_leg.y = 0.0
	_last_leg_forward = actual_leg.normalized() if not actual_leg.is_zero_approx() else Vector3.ZERO
	receipt["sample"] = int(waypoint.sample)
	receipt["requested_xz"] = [at.x, at.y]
	receipt["gap_m"] = Vector2(_player.global_position.x, _player.global_position.z).distance_to(at)
	receipt["straight_leg_m"] = straight_m
	receipt["physics_frames"] = Engine.get_physics_frames() - started_frame
	receipt["navigator_confined_resets"] = int(_navigator.call("confined_resets"))
	receipt["arrived"] = arrived
	receipt["actual_leg_forward"] = _vec3(_last_leg_forward)
	_walk_receipts.append(receipt)
	_receipt_event("waypoint", receipt)
	_write_manifest()
	if not arrived:
		_stop("ordinary walk failed before sample %d at %s" % [int(waypoint.sample), str(_player.global_position)])
		return false
	if int(waypoint.sample) == 38:
		var actual_outgoing := _player.global_position - _sample_37_position
		actual_outgoing.y = 0.0
		actual_outgoing = actual_outgoing.normalized() if not actual_outgoing.is_zero_approx() else Vector3.ZERO
		if not _record_sample_37_actual_heading(actual_outgoing):
			return false
	if not await _wait_grounded("sample_%d_ground_settle" % int(waypoint.sample)):
		return false
	return true


func _start_walk_meter() -> void:
	_walk_distance_m = 0.0
	_walk_previous = _player.global_position
	_walking = true
	physics_frame.connect(_measure_walk_frame)


func _stop_walk_meter() -> void:
	_walking = false
	if physics_frame.is_connected(_measure_walk_frame):
		physics_frame.disconnect(_measure_walk_frame)
	_manifest["actual_walk_distance_m"] = _walk_distance_m
	_write_manifest()


func _measure_walk_frame() -> void:
	if not _walking or _player == null or not is_instance_valid(_player):
		return
	var now := _player.global_position
	if _walk_previous.is_finite():
		_walk_distance_m += Vector2(now.x - _walk_previous.x, now.z - _walk_previous.z).length()
	_walk_previous = now


func _wait_grounded(stage: String) -> bool:
	var stable := 0
	for waited in TELEPORT_SETTLE_LIMIT:
		await physics_frame
		if _player.is_on_floor() and absf(_player.velocity.y) < 0.15:
			stable += 1
			if stable >= GROUND_STABLE_FRAMES:
				_receipt_event("ground_settle", {"stage": stage, "waited_frames": waited + 1,
					"stable_frames": stable, "player": _vec3(_player.global_position), "grounded": true})
				return true
		else:
			stable = 0
	_stop("player did not ground-settle at " + stage)
	return false


func _capture_endpoint(sample: int, heading: String, wanted_yaw: float,
		travel_reference: Vector3) -> bool:
	if not await _orient_camera(wanted_yaw, RECORDED_PITCH, "%d/%s" % [sample, heading]):
		return false
	if not await _wait_grounded("sample_%d_%s" % [sample, heading]):
		return false
	return await _capture("sample_%d__%s" % [sample, heading], sample, heading,
		wanted_yaw, travel_reference)


func _orient_camera(wanted_yaw: float, wanted_pitch: float, stage: String) -> bool:
	_release_look()
	var stable := 0
	for _frame in LOOK_TIMEOUT_FRAMES:
		var yaw_error := angle_difference(float(_rig.get("yaw")), wanted_yaw)
		var pitch_error := wanted_pitch - float(_rig.get("pitch"))
		_release_look()
		if absf(rad_to_deg(yaw_error)) > LOOK_TOLERANCE_DEG:
			Input.action_press(&"look_left" if yaw_error > 0.0 else &"look_right", 0.45)
		if absf(rad_to_deg(pitch_error)) > LOOK_TOLERANCE_DEG:
			Input.action_press(&"look_up" if pitch_error > 0.0 else &"look_down", 0.45)
		await process_frame
		var remaining_yaw := angle_difference(float(_rig.get("yaw")), wanted_yaw)
		var remaining_pitch := wanted_pitch - float(_rig.get("pitch"))
		if absf(rad_to_deg(remaining_yaw)) <= LOOK_TOLERANCE_DEG \
				and absf(rad_to_deg(remaining_pitch)) <= LOOK_TOLERANCE_DEG:
			stable += 1
			if stable >= LOOK_STABLE_FRAMES:
				_release_look()
				_receipt_event("ordinary_look", {"stage": stage,
					"wanted_yaw_deg": rad_to_deg(wanted_yaw), "wanted_pitch_deg": rad_to_deg(wanted_pitch),
					"actual_yaw_deg": rad_to_deg(float(_rig.get("yaw"))),
					"actual_pitch_deg": rad_to_deg(float(_rig.get("pitch")))})
				return true
		else:
			stable = 0
	_release_look()
	_stop("ordinary look actions could not reach " + stage)
	return false


func _capture(id: String, sample: int, heading: String, wanted_yaw: float,
		travel_reference: Vector3) -> bool:
	if _frames.size() >= 4:
		_stop("four-frame evidence cap would be exceeded")
		return false
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	var viewport := _camera.get_viewport().get_visible_rect().size
	if image == null or image.is_empty() or image.get_width() != 1280 or image.get_height() != 720:
		_stop(id + ": frame is empty or not the verified 1280x720 viewport")
		return false
	var path := _output_dir.path_join(id + ".png")
	if image.save_png(path) != OK:
		_stop(id + ": save_png failed")
		return false
	var forward := -_camera.global_basis.z
	var bodies: Array[Dictionary] = []
	var credited := 0
	for candidate in _director.call("wild_creatures"):
		var body := candidate as Node3D
		if not OBSERVER.eligible_body(body):
			continue
		var observation: Dictionary = _observer.call("_body_sample", body, _player, _camera,
			_player.global_position, forward, viewport)
		observation["alive"] = bool(body.call("is_alive"))
		observation["first_rejection"] = _first_rejection(observation)
		bodies.append(observation)
		if bool(observation.credited):
			credited += 1
	bodies.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return float(a.distance_m) < float(b.distance_m))
	var pair := _pair_nodes()
	var pair_records: Array[Dictionary] = []
	for expected: String in PAIR_NAMES:
		var bound: Node3D = pair.get(expected) as Node3D
		if bound == null:
			pair_records.append({"expected_name": expected, "found": false, "alive": false})
			continue
		var identity := _body_identity(bound, expected)
		var matched := _sample_for_path(bodies, str(bound.get_path()))
		identity["observer"] = matched
		pair_records.append(identity)
	var record := {
		"frame_id": id,
		"file": path,
		"sha256": FileAccess.get_sha256(path),
		"bytes": FileAccess.get_file_as_bytes(path).size(),
		"sample": sample,
		"heading": heading,
		"wanted_yaw_deg": rad_to_deg(wanted_yaw),
		"player_position": _vec3(_player.global_position),
		"player_grounded": _player.is_on_floor(),
		"camera_position": _vec3(_camera.global_position),
		"camera_forward": _vec3(forward),
		"camera_transform": _transform(_camera.global_transform),
		"camera_rig_transform": _transform(_rig.global_transform),
		"camera_yaw_deg": rad_to_deg(float(_rig.get("yaw"))),
		"camera_pitch_deg": rad_to_deg(float(_rig.get("pitch"))),
		"camera_fov": _camera.fov,
		"camera_keep_aspect": _camera.keep_aspect,
		"logical_camera_viewport": [viewport.x, viewport.y],
		"render_target": [root.size.x, root.size.y],
		"clock": _clock_snapshot(),
		"wild_eligible_count": bodies.size(),
		"observer_credited_count": credited,
		"observer_required_count": 2,
		"observer_count_pass": credited >= 2,
		"pair": pair_records,
		"bodies": bodies,
		"physics_frame": Engine.get_physics_frames(),
		"time_ms": Time.get_ticks_msec(),
	}
	if not travel_reference.is_zero_approx():
		var camera_horizontal := Vector3(forward.x, 0.0, forward.z).normalized()
		var reference_horizontal := Vector3(travel_reference.x, 0.0, travel_reference.z).normalized()
		record["travel_reference_forward"] = _vec3(reference_horizontal)
		record["camera_forward_horizontal"] = _vec3(camera_horizontal)
		record["camera_forward_travel_dot"] = camera_horizontal.dot(reference_horizontal)
	_frames.append(record)
	_receipt_event("capture", {"frame_id": id, "file": path, "sha256": str(record.sha256),
		"sample": sample, "heading": heading, "player": record.player_position,
		"camera_forward": record.camera_forward, "render_target": record.render_target,
		"logical_camera_viewport": record.logical_camera_viewport,
		"observer_credited_count": credited, "pair": pair_records})
	_write_manifest()
	print("ROAD HEADING CAPTURE %s count=%d pair=%d -> %s" % [id, credited, pair.size(), path])
	if record.has("camera_forward_travel_dot") and float(record.camera_forward_travel_dot) <= 0.9:
		_stop("%s camera/travel dot %.4f did not exceed 0.9" % [id, float(record.camera_forward_travel_dot)])
		return false
	return true


func _record_sample_37_actual_heading(actual_outgoing: Vector3) -> bool:
	for frame: Dictionary in _frames:
		if str(frame.frame_id) != "sample_37__travel_facing":
			continue
		var camera_forward: Array = frame.camera_forward_horizontal
		var camera_horizontal := Vector3(float(camera_forward[0]), 0.0, float(camera_forward[2])).normalized()
		var dot := camera_horizontal.dot(actual_outgoing)
		frame["actual_outgoing_walk_forward"] = _vec3(actual_outgoing)
		frame["camera_forward_actual_walk_dot"] = dot
		_manifest["sample_37_actual_outgoing_walk_forward"] = _vec3(actual_outgoing)
		_write_manifest()
		_receipt_event("sample_37_heading_check", {"camera_forward": _vec3(camera_horizontal),
			"actual_outgoing_walk_forward": _vec3(actual_outgoing), "dot": dot, "required_gt": 0.9})
		if dot <= 0.9:
			_stop("sample 37 camera/actual outgoing walk dot %.4f did not exceed 0.9" % dot)
			return false
		return true
	_stop("sample 37 travel-facing frame is missing for actual heading check")
	return false


func _historical_tangent(sample: int) -> Vector3:
	if sample == 37:
		var start: Vector2 = WAYPOINTS[0].xz
		var finish: Vector2 = WAYPOINTS[1].xz
		return Vector3(finish.x - start.x, 0.0, finish.y - start.y).normalized()
	return Vector3.ZERO


func _yaw_for_forward(forward: Vector3) -> float:
	return atan2(-forward.x, -forward.z)


func _first_rejection(observation: Dictionary) -> String:
	if not bool(observation.forward):
		return "camera_relative_forward_half_plane"
	if float(observation.projected_height_px_at_720p) < 15.0:
		return "projected_height_below_15px_at_720p"
	if not bool(observation.framed):
		return "centre_outside_camera_frustum"
	if not bool(observation.los.clear):
		return "centre_ray_blocked"
	return "credited"


func _sample_for_path(bodies: Array[Dictionary], path: String) -> Dictionary:
	for body: Dictionary in bodies:
		if str(body.path) == path:
			return body
	return {}


func _body_identity(body: Node3D, expected: String) -> Dictionary:
	return {
		"expected_name": expected,
		"found": true,
		"name": str(body.name),
		"path": str(body.get_path()),
		"instance_id": body.get_instance_id(),
		"species": str(body.get("species_id")),
		"position": _vec3(body.global_position),
		"body_height_m": float(body.call("body_height")) if body.has_method("body_height") else 0.0,
		"alive": bool(body.call("is_alive")) if body.has_method("is_alive") else false,
	}


func _pose_receipt(stage: String) -> Dictionary:
	return {"stage": stage, "physics_frame": Engine.get_physics_frames(),
		"time_ms": Time.get_ticks_msec(), "player": _vec3(_player.global_position),
		"grounded": _player.is_on_floor(), "camera": _vec3(_camera.global_position),
		"camera_yaw_deg": rad_to_deg(float(_rig.get("yaw"))),
		"camera_pitch_deg": rad_to_deg(float(_rig.get("pitch"))), "clock": _clock_snapshot()}


func _clock_snapshot() -> Dictionary:
	var result := {"system_utc": Time.get_datetime_string_from_system(true), "pinned_by_probe": false}
	if _weather != null and _weather.has_method("weather"):
		result["weather"] = str(_weather.call("weather"))
	if _look != null:
		var elapsed := float(_look.get("_elapsed_seconds"))
		result["elapsed_seconds"] = elapsed
		var cycle: Variant = _look.get("_cycle")
		if cycle != null and cycle.has_method("hour_at"):
			var hour := float(cycle.call("hour_at", elapsed))
			result["hour"] = hour
			if cycle.has_method("preset_at"):
				result["time_preset"] = str(cycle.call("preset_at", hour))
			if cycle.has_method("interpolate_at"):
				result["time_blend"] = cycle.call("interpolate_at", hour)
	return result


func _drive_stick(x: float, y: float) -> void:
	Input.action_release(&"move_forward")
	Input.action_release(&"move_back")
	Input.action_release(&"move_left")
	Input.action_release(&"move_right")
	if y < -0.2:
		Input.action_press(&"move_forward", -y)
	elif y > 0.2:
		Input.action_press(&"move_back", y)
	if x < -0.2:
		Input.action_press(&"move_left", -x)
	elif x > 0.2:
		Input.action_press(&"move_right", x)


func _release_look() -> void:
	for action: StringName in [&"look_left", &"look_right", &"look_up", &"look_down"]:
		Input.action_release(action)


func _release_inputs() -> void:
	_drive_stick(0.0, 0.0)
	_release_look()


func _receipt_event(kind: String, data: Dictionary) -> void:
	if _receipt == null:
		return
	var row := data.duplicate(true)
	row["kind"] = kind
	_receipt.store_line(JSON.stringify(row))
	_receipt.flush()


func _stop(reason: String) -> void:
	if _failures.is_empty():
		_failures.append(reason)
	push_error("road heading probe: " + reason)
	_receipt_event("failure", {"reason": reason})
	_write_manifest()


func _finish(complete: bool) -> void:
	_release_inputs()
	_stop_walk_meter()
	_manifest["capture_finished_utc"] = Time.get_datetime_string_from_system(true)
	_manifest["captured_frame_count"] = _frames.size()
	_manifest["complete"] = complete and _failures.is_empty()
	_write_manifest()
	if _receipt != null:
		_receipt.close()
		_receipt = null
	print("ROAD HEADING PROBE %s frames=%d walk=%.3fm output=%s" % [
		"OK" if bool(_manifest.get("complete", false)) else "FAILED",
		_frames.size(), _walk_distance_m, _output_dir])
	quit(0 if bool(_manifest.get("complete", false)) else 1)


func _write_manifest() -> void:
	if _output_dir.is_empty():
		return
	var file := FileAccess.open(_output_dir.path_join("manifest.json"), FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(_manifest, "  "))
		file.close()


func _vec3(value: Vector3) -> Array[float]:
	return [value.x, value.y, value.z]


func _transform(value: Transform3D) -> Dictionary:
	return {"basis_x": _vec3(value.basis.x), "basis_y": _vec3(value.basis.y),
		"basis_z": _vec3(value.basis.z), "origin": _vec3(value.origin)}
