extends SceneTree

## X04 evidence for F13#5 / T2: "currents, inhabited docks and Veilfall distance
## read" at the NORMAL camera. Production Water scene, production Player,
## CameraRig/Camera3D and HUD -- unlike survey_water.gd, which swaps in its own
## free camera. Each view stands the player at a point (ground, or swimming at
## the surface where the ground is under water), turns the rig's yaw toward
## the target and lets the rig settle on its own. Day and night per view.
## Teleported stands are visual fixtures, not traversal evidence.
##
##   godot --path . --rendering-driver opengl3 --fullscreen --resolution 1920x1080 \
##     --script res://tools/art_pipeline/capture_tidewake_matrix.gd -- \
##     --out=res://.artifacts/phase2/matrix-fresh --seed=2042 [--only=name,name] \
##     [--hold-seconds=30] [--source-metadata=res://path/to/caller-metadata.json]
## Holds are stationary fixtures, not walked routes. Use engine --write-movie
## for continuous footage; this script saves start/end stills and movie frame ranges.
##
## Coordinates: data/config/water_world.json and water_veilfall.json.

const SCENE := "res://scenes/world/water_archipelago.tscn"
const READY_TIMEOUT_MS := 600000
const SETTLE_FRAMES := 90
## The third-person trainer stands at frame centre; turning the rig this far
## off the target puts the subject beside the trainer instead of behind them.
const YAW_OFFSET_DEG := 14.0

## stand xz, target xyz (y < -999 means ground height at target + 4 m).
const VIEWS := [
	{"name": "dock-first-shore-settlement", "stand": Vector2(12.0, 150.0), "target": Vector3(35.7, -1000.0, 98.1),
		"what": "First Shore settlement and Welcome Beacon from the Reedhaven dock"},
	{"name": "dock-reedhaven-arrival", "stand": Vector2(0.0, 278.0), "target": Vector3(-54.0, -1000.0, 440.0),
		"what": "Reedhaven Woven Hall from the dock arrival point"},
	{"name": "dock-shellwatch-jetty", "stand": Vector2(250.0, 975.0), "target": Vector3(267.0, -1000.0, 1006.3),
		"what": "Shellwatch Rescue Jetty (occupied dock) from 35 m"},
	{"name": "current-first-shore-reedhaven", "stand": Vector2(0.0, 162.0), "target": Vector3(0.0, 1.0, 262.0),
		"what": "First Shore to Reedhaven current, from the dock looking along it"},
	{"name": "current-cradle-salt-crown", "stand": Vector2(560.0, 1728.0), "target": Vector3(299.8, 2.0, 2097.5),
		"what": "Tidal Cradle to Salt Crown current along its line"},
	{"name": "current-sluice-veilfall", "stand": Vector2(722.0, 3192.0), "target": Vector3(393.0, 2.0, 3789.6),
		"what": "Sluice Isle to Veilfall current (strongest) along its line"},
	# Dock stands (X04 F13#5 re-judge): the First Shore departure pier sits
	# 4 m west of the safe->shore line (0,162)->(0,180) and runs ~14 m north
	# (water_dock_dressing.json). Near/mid/far frame the pier itself.
	{"name": "dock-first-shore-pier-near", "stand": Vector2(5.0, 174.0), "target": Vector3(-4.0, 1.0, 184.0),
		"what": "First Shore departure pier from the beach, ~12 m", "yaw_offset": 0.0, "pitch": -0.08},
	{"name": "dock-first-shore-pier-mid", "stand": Vector2(22.0, 168.0), "target": Vector3(-4.0, 1.0, 185.0),
		"what": "First Shore departure pier along the shore, ~30 m", "yaw_offset": 0.0, "pitch": -0.06},
	{"name": "dock-first-shore-pier-far", "stand": Vector2(-40.0, 158.0), "target": Vector3(-4.0, 1.0, 186.0),
		"what": "First Shore departure pier from the west beach, ~45 m", "yaw_offset": 0.0, "pitch": -0.05},
	{"name": "veilfall-far-first-shore", "stand": Vector2(0.0, 162.0), "target": Vector3(200.0, 620.0, 4140.0),
		"what": "Veilfall from First Shore, ~4 km (design sightline)", "pitch": -0.05, "yaw_offset": 24.0},
	{"name": "veilfall-mid-salt-crown", "stand": Vector2(419.6, 2640.0), "target": Vector3(200.0, 620.0, 4140.0),
		"what": "Veilfall from the Salt Crown rest, ~1.5 km", "pitch": -0.05, "yaw_offset": 24.0},
	{"name": "veilfall-near-arrival", "stand": Vector2(384.3, 3805.4), "target": Vector3(335.2, 139.4, 3885.7),
		"what": "Veilfall Cascade from arrival; actual 3D distance recorded"},
]

const CONFIG := "res://data/config/water_world.json"
const SPAWN_TABLES := preload("res://scripts/combat/spawn_tables.gd")
const SIZE := Vector2i(1920, 1080)
const ROUTE_REGIONS := {
	"first_shore": "first-shores", "reedhaven": "marsh-channels",
	"tidal_cradle": "tidal-cradle", "salt_crown": "outer-reaches",
	"sluice_isle": "tether-current", "veilfall": "veilfall",
}

var _world: Node3D
var _player: CharacterBody3D
var _rig: SpringArm3D
var _camera: Camera3D
var _look: Node
var _out := ""
var _only: PackedStringArray = []
var _seed := 2042
var _hold_seconds := 0.0
var _source_metadata: Dictionary = {}
var _metadata_path := ""
var _save_dir := ""
var _records: Array[Dictionary] = []
var _expected: Array[String] = []
var _failures: Array[String] = []
var _started := ""
var _seed_environment_before: Variant = null
var _seed_environment_applied := false


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			_out = arg.trim_prefix("--out=")
		elif arg.begins_with("--only="):
			_only = arg.trim_prefix("--only=").split(",", false)
		elif arg.begins_with("--seed="):
			var value := arg.trim_prefix("--seed=")
			if not value.is_valid_int():
				_failures.append("seed must be an integer")
			_seed = int(value)
		elif arg.begins_with("--hold-seconds="):
			var value := arg.trim_prefix("--hold-seconds=")
			if not value.is_valid_float():
				_failures.append("hold-seconds must be numeric")
			_hold_seconds = float(value)
		elif arg.begins_with("--source-metadata="):
			_metadata_path = arg.trim_prefix("--source-metadata=")
	if not is_finite(_hold_seconds) or _hold_seconds < 0.0 or _hold_seconds > 300.0:
		_failures.append("hold-seconds must be between 0 and 300")
	# Never merge new frames into an earlier run or write outside evidence roots.
	_out = ProjectSettings.localize_path(ProjectSettings.globalize_path(_out).simplify_path()).trim_suffix("/")
	if not (_out.begins_with("res://.artifacts/phase2/") or _out.begins_with("res://ralph/reports/VISUAL/phase2/tidewake/")):
		_failures.append("out must be a fresh child directory under .artifacts/phase2 or the Tidewake Phase 2 report")
	if DirAccess.dir_exists_absolute(_out) or FileAccess.file_exists(_out):
		_failures.append("output already exists; choose a fresh run directory")
	if not _failures.is_empty():
		push_error(str(_failures))
		quit(1)
		return
	if DirAccess.make_dir_recursive_absolute(_out) != OK:
		push_error("could not create output directory")
		quit(1)
		return
	_started = Time.get_datetime_string_from_system(true)
	_save_dir = "user://capture_tidewake_matrix_%s_%s/" % [str(Time.get_unix_time_from_system()).replace(".", "_"), OS.get_process_id()]
	if not _metadata_path.is_empty():
		var metadata: Variant = JSON.parse_string(FileAccess.get_file_as_string(_metadata_path))
		if metadata is Dictionary:
			_source_metadata = metadata
		else:
			_failures.append("source-metadata must contain a JSON object")
	_write_manifest(false)
	if not _display_valid() or not _failures.is_empty():
		_finish()
		return
	# The global RNG alone does not pin production encounter populations.
	# resolve_seed() reads this process-local override before using the save seed.
	if OS.has_environment(SPAWN_TABLES.SEED_ENV_VAR):
		_seed_environment_before = OS.get_environment(SPAWN_TABLES.SEED_ENV_VAR)
	OS.set_environment(SPAWN_TABLES.SEED_ENV_VAR, str(_seed))
	_seed_environment_applied = OS.get_environment(SPAWN_TABLES.SEED_ENV_VAR) == str(_seed)
	if not _seed_environment_applied:
		_failures.append("could not set process-local TB_WORLD_SEED")
		_finish()
		return
	seed(_seed)
	var game := root.get_node_or_null(^"Game")
	if game == null:
		_failures.append("Game autoload missing")
		_finish()
		return
	var save_script: Script = load("res://scripts/save/save_game.gd")
	game.set("save_system", save_script.new(_save_dir))
	game.call("reset_for_new_game")
	game.set("current_realm", "water")
	_world = (load(SCENE) as PackedScene).instantiate() as Node3D
	root.add_child(_world)
	current_scene = _world
	var deadline := Time.get_ticks_msec() + READY_TIMEOUT_MS
	while Time.get_ticks_msec() < deadline and not bool(_world.call("shell_build_complete")):
		await physics_frame
	if not bool(_world.call("shell_build_complete")):
		_failures.append("production Water shell did not finish building")
		_finish()
		return
	_player = _world.get_node_or_null(^"Player") as CharacterBody3D
	_rig = _world.get_node_or_null(^"CameraRig") as SpringArm3D
	_look = _world.get_node_or_null(^"WorldLook")
	_camera = _world.get_node_or_null(^"CameraRig/Camera3D") as Camera3D
	if _player == null or _rig == null or _look == null or _camera == null:
		_failures.append("production Player, CameraRig/Camera3D or WorldLook missing")
		_finish()
		return
	var director := _world.get_node_or_null(^"EncounterDirector")
	if director == null or not director.has_method("world_seed") or int(director.call("world_seed")) != _seed:
		_failures.append("production EncounterDirector did not resolve the requested world seed")
		_finish()
		return
	if _look.has_method("set_clock_frozen"):
		_look.call("set_clock_frozen", true)
	var views: Array = VIEWS.duplicate(true)
	views.append_array(_authored_views())
	var selected: Array[Dictionary] = []
	var known: Array[String] = []
	for view: Dictionary in views:
		known.append(str(view.name))
		if _only.is_empty() or _only.has(str(view.name)):
			selected.append(view)
			for time_name: String in ["day", "night"]:
				_expected.append("%s-%s" % [view.name, time_name])
	for requested: String in _only:
		if not known.has(requested):
			_failures.append("unknown requested view: " + requested)
	if selected.is_empty():
		_failures.append("no selected views")
	_write_manifest(false)
	if not _failures.is_empty():
		_finish()
		return
	for view: Dictionary in selected:
		for time_name: String in ["day", "night"]:
			_records.append(await _capture(view, time_name))
			_write_manifest(false)
	_finish()


func _authored_views() -> Array:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(CONFIG))
	if not parsed is Dictionary:
		_failures.append("invalid water_world.json")
		return []
	var config: Dictionary = parsed
	var views: Array = []
	for island: String in ROUTE_REGIONS:
		var route := _row(config.get("land_routes", []), island + "_exploration_spine")
		var points: Array = route.get("polyline", [])
		if points.size() < 4:
			_failures.append("missing authored route: " + island)
			continue
		var at := _v3(points[2])
		for direction: String in ["forward", "reverse", "detail"]:
			var target := _v3(points[1 if direction == "reverse" else 3])
			var view := {"name": "route-%s-%s" % [ROUTE_REGIONS[island], direction],
				"stand": Vector2(at.x, at.z), "target": target,
				"what": "Authored route %s; stationary %s fixture" % [route.id, direction],
				"source": {"file": CONFIG, "route_id": route.id, "stand_point_index": 2,
					"target_point_index": 1 if direction == "reverse" else 3, "authored_stand": points[2]}}
			if direction == "detail":
				var forward := Vector2(target.x - at.x, target.z - at.z).normalized()
				var detail := Vector2(at.x, at.z) + forward * 3.0
				view.target = Vector3(detail.x, float(_world.call("ground_height_at", detail.x, detail.y)), detail.y)
				view.pitch = deg_to_rad(-45.0)
				view.yaw_offset = 0.0
				view.source["detail_offset_m"] = 3.0
			views.append(view)
	var landmark := _row(config.get("landmarks", []), "veilfall_white_cascade")
	var rest := _row(config.get("anchors", []), "sluice_isle_to_veilfall_rest_04")
	var spine := _row(config.get("land_routes", []), "veilfall_exploration_spine")
	var path: Array = spine.get("polyline", [])
	if landmark.is_empty() or rest.is_empty() or path.size() < 2:
		_failures.append("missing Veilfall finale landmark, rest anchor or route")
		return views
	var target := _v3(landmark.position)
	var far_at := _v3(rest.safe_position)
	views.append({"name": "veilfall-finale-400", "stand": Vector2(far_at.x, far_at.z), "target": target,
		"what": "Cascade from authored rest shoal, about 400 m; actual range recorded", "nominal_distance_m": 400.0,
		"source": {"file": CONFIG, "anchor_id": rest.id, "landmark_id": landmark.id}})
	# Search only the last authored segment, sampling the REAL terrain height.
	# Do not infer that an interpolated design Y is the current surface.
	var a := _v3(path[path.size() - 2])
	var b := _v3(path[path.size() - 1])
	var best := Vector2.ZERO
	var error := INF
	for step in 1001:
		var sample := a.lerp(b, float(step) / 1000.0)
		var seated := _stand_at(Vector2(sample.x, sample.z))
		var difference := absf(seated.distance_to(target) - 100.0)
		if difference < error:
			error = difference
			best = Vector2(sample.x, sample.z)
	if error > 5.0 and (_only.is_empty() or _only.has("veilfall-finale-100")):
		_failures.append("last Veilfall route segment has no sampled terrain stand within 5 m of 100 m range")
	views.append({"name": "veilfall-finale-100", "stand": best, "target": target,
		"what": "Cascade from final authored route segment, terrain-sampled 100 m stand", "nominal_distance_m": 100.0,
		"source": {"file": CONFIG, "route_id": spine.id, "landmark_id": landmark.id, "sample_error_m": error}})
	return views


func _row(rows: Array, id: String) -> Dictionary:
	for row: Dictionary in rows:
		if str(row.get("id", "")) == id:
			return row
	return {}


func _v3(value: Array) -> Vector3:
	return Vector3(float(value[0]), float(value[1]), float(value[2]))


func _xyz(value: Vector3) -> Array:
	return [value.x, value.y, value.z]


func _stand_at(stand: Vector2) -> Vector3:
	var ground := float(_world.call("ground_height_at", stand.x, stand.y))
	return Vector3(stand.x, 0.15 if ground < 0.0 else ground + 0.15, stand.y)


func _pose(at: Vector3, target: Vector3, view: Dictionary) -> void:
	var to := target - at
	_player.global_position = at
	_player.velocity = Vector3.ZERO
	_rig.set("yaw", atan2(-to.x, -to.z) + deg_to_rad(float(view.get("yaw_offset", YAW_OFFSET_DEG))))
	_rig.set("pitch", float(view.get("pitch", clampf(atan2(to.y, Vector2(to.x, to.z).length()) * 0.5,
		deg_to_rad(-10.0), deg_to_rad(12.0)))))


func _capture(view: Dictionary, time_name: String) -> Dictionary:
	var stand: Vector2 = view.stand
	var target: Vector3 = view.target
	var name := "%s-%s" % [view.name, time_name]
	if not stand.is_finite() or not target.is_finite():
		_failures.append(name + ": non-finite authored stand or target")
		return {"frame_id": name, "status": "failed"}
	if target.y < -999.0:
		target.y = float(_world.call("ground_height_at", target.x, target.z)) + 4.0
	var ground := float(_world.call("ground_height_at", stand.x, stand.y))
	var at := _stand_at(stand)
	if not is_finite(ground) or not at.is_finite() or not target.is_finite():
		_failures.append(name + ": non-finite terrain-resolved stand or target")
		return {"frame_id": name, "status": "failed"}
	var record := {"frame_id": name, "frame": name, "file": name + ".png", "what": view.what,
		"time": time_name, "requested_player": _xyz(at), "target": _xyz(target), "ground_y": ground,
		"swimming_stand": ground < 0.0, "source": view.get("source", {"file": get_script().resource_path, "view": view.name}),
		"status": "failed", "hold_seconds_requested": _hold_seconds}
	_look.call("apply_time", time_name)
	for i in SETTLE_FRAMES:
		_pose(at, target, view)
		await physics_frame
	for i in 6:
		_pose(at, target, view)
		await process_frame
	await RenderingServer.frame_post_draw
	if not _capture_valid(at, name):
		return record
	record["observed_clock"] = _clock_record(time_name, name)
	if record.observed_clock.is_empty():
		return record
	record["seed_context"] = _seed_record()
	record["player"] = _xyz(_player.global_position)
	record["distance_m"] = _player.global_position.distance_to(target)
	record["horizontal_distance_m"] = Vector2(_player.global_position.x, _player.global_position.z).distance_to(Vector2(target.x, target.z))
	record["camera"] = _camera_record()
	record["render"] = _render_record()
	if view.has("nominal_distance_m"):
		record["nominal_distance_m"] = view.nominal_distance_m
		if absf(float(record.distance_m) - float(view.nominal_distance_m)) > float(view.nominal_distance_m) * 0.1:
			_failures.append(name + ": actual finale range outside 10 percent tolerance")
			return record
	if not _save_png(str(record.file)):
		return record
	record["hold_start_process_frame"] = Engine.get_process_frames()
	record["hold_start_physics_frame"] = Engine.get_physics_frames()
	var elapsed := 0.0
	while elapsed < _hold_seconds:
		_pose(at, target, view)
		await physics_frame
		elapsed += root.get_physics_process_delta_time()
		if not _capture_valid(at, name):
			return record
	record["hold_seconds_simulated"] = elapsed
	record["hold_end_process_frame"] = Engine.get_process_frames()
	record["hold_end_physics_frame"] = Engine.get_physics_frames()
	if _hold_seconds > 0.0:
		await RenderingServer.frame_post_draw
		if not _capture_valid(at, name):
			return record
		record["hold_end_observed_clock"] = _clock_record(time_name, name)
		if record.hold_end_observed_clock.is_empty():
			return record
		record["hold_end_file"] = name + "-hold-end.png"
		if not _save_png(str(record.hold_end_file)):
			return record
		record["hold_end_camera"] = _camera_record()
		record["hold_end_player"] = _xyz(_player.global_position)
	record.status = "captured"
	print("frame %s player=%s distance=%.2f stationary_hold=%.2fs" % [name, _player.global_position, record.distance_m, elapsed])
	return record


func _display_valid() -> bool:
	var mode := DisplayServer.window_get_mode()
	if DisplayServer.get_name() == "headless" or RenderingServer.get_current_rendering_method() != "gl_compatibility":
		_failures.append("native capture requires a rendering display and Compatibility renderer")
		return false
	if mode != DisplayServer.WINDOW_MODE_FULLSCREEN and mode != DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN:
		_failures.append("native capture requires actual fullscreen mode")
		return false
	if root.size != SIZE or DisplayServer.window_get_size() != SIZE:
		_failures.append("native fullscreen window and viewport must both be 1920x1080; actual %s / %s" % [DisplayServer.window_get_size(), root.size])
		return false
	return true


func _capture_valid(at: Vector3, name: String) -> bool:
	if not _display_valid():
		return false
	if not at.is_finite() or not _player.global_position.is_finite() or not _camera.global_position.is_finite() or not _rig.global_position.is_finite() or not _camera.global_rotation.is_finite():
		_failures.append(name + ": non-finite requested/player/rig/camera transform")
		return false
	var distance := _camera.global_position.distance_to(_player.global_position)
	var spring_length := _rig.spring_length
	if not is_finite(spring_length) or spring_length <= 0.0:
		_failures.append(name + ": invalid production spring length")
		return false
	# Match the installed location recorder's ordinary-camera bounds.
	if _player.global_position.distance_to(at) > 1.0 or root.get_camera_3d() != _camera or distance < 3.5 or distance > spring_length + 3.0:
		_failures.append(name + ": displaced player or stale/non-production camera")
		return false
	return true


func _clock_record(requested: String, name: String) -> Dictionary:
	if not _look.has_method("time_of_day") or not _look.has_method("hour") or not _look.has_method("elapsed_seconds"):
		_failures.append(name + ": production clock reporting unavailable")
		return {}
	var observed := str(_look.call("time_of_day"))
	var hour := float(_look.call("hour"))
	var elapsed := float(_look.call("elapsed_seconds"))
	if observed != requested or not is_finite(hour) or not is_finite(elapsed):
		_failures.append(name + ": observed clock invalid or different from requested " + requested)
		return {}
	return {"requested": requested, "time_of_day": observed, "hour": hour, "elapsed_seconds": elapsed}


func _seed_record() -> Dictionary:
	var game := root.get_node_or_null(^"Game")
	var saved := int(game.get("world_seed")) if game != null else SPAWN_TABLES.AUTHORED_SEED
	return {"requested_rng_and_world_seed": _seed, "authored_world_seed": SPAWN_TABLES.AUTHORED_SEED,
		"saved_world_seed": saved, "effective_world_seed": SPAWN_TABLES.resolve_seed(saved),
		"environment_key": SPAWN_TABLES.SEED_ENV_VAR, "environment_override_applied": _seed_environment_applied,
		"environment_before_override": _seed_environment_before,
		"environment_value": OS.get_environment(SPAWN_TABLES.SEED_ENV_VAR)}


func _save_png(file: String) -> bool:
	var image := root.get_texture().get_image()
	if image == null or image.get_size() != SIZE:
		_failures.append(file + ": image is missing or not native 1920x1080")
		return false
	if image.save_png(_out.path_join(file)) != OK or not FileAccess.file_exists(_out.path_join(file)):
		_failures.append(file + ": PNG write failed")
		return false
	return true


func _camera_record() -> Dictionary:
	return {"path": str(_camera.get_path()), "position": _xyz(_camera.global_position),
		"rotation_degrees": _xyz(_camera.global_rotation_degrees), "fov": _camera.fov,
		"spring_length": _rig.spring_length, "player_distance_m": _camera.global_position.distance_to(_player.global_position),
		"near": _camera.near, "far": _camera.far, "rig_yaw": _rig.get("yaw"), "rig_pitch": _rig.get("pitch")}


func _render_record() -> Dictionary:
	return {"display": DisplayServer.get_name(), "window_mode": DisplayServer.window_get_mode(),
		"window_size": [DisplayServer.window_get_size().x, DisplayServer.window_get_size().y],
		"viewport_size": [root.size.x, root.size.y], "rendering_method": RenderingServer.get_current_rendering_method(),
		"adapter": RenderingServer.get_video_adapter_name(), "os": OS.get_name(), "engine": Engine.get_version_info()}


func _write_manifest(complete: bool) -> bool:
	var file := FileAccess.open(_out.path_join("frames.json"), FileAccess.WRITE)
	if file == null:
		_failures.append("could not write frames.json")
		return false
	var missing: Array[String] = []
	for id: String in _expected:
		var found := false
		for row: Dictionary in _records:
			if row.frame_id == id and row.status == "captured":
				found = true
		if not found:
			missing.append(id)
	file.store_string(JSON.stringify({"schema_version": 2, "complete": complete,
		"scene": SCENE, "started_utc": _started, "seed": _seed, "seed_context": _seed_record(), "source_metadata": _source_metadata,
		"source_metadata_path": _metadata_path, "script": get_script().resource_path, "engine_args": OS.get_cmdline_args(),
		"user_args": OS.get_cmdline_user_args(), "render": _render_record(),
		"camera": "production CameraRig/Camera3D, HUD on",
		"fixture": {"save_origin": "fresh reset_for_new_game", "isolated_save_dir": _save_dir,
			"party_or_flags_injected": false, "current_realm_set": "water", "teleported_stands": true,
			"clock_frozen": true, "player_pose_pinned": true, "stationary_hold_not_walk": true,
			"continuous_movie_requires_engine_write_movie": true,
			"device_claim": "computer capture, no Ally hardware", "performance_claim": false},
		"expected_frame_ids": _expected, "missing_or_failed_frame_ids": missing,
		"failures": _failures, "frames": _records}, "\t"))
	file.flush()
	var write_error := file.get_error()
	file.close()
	if write_error != OK:
		_failures.append("frames.json write failed: " + str(write_error))
		return false
	return true


func _finish() -> void:
	var complete := _failures.is_empty() and not _expected.is_empty() and _records.size() == _expected.size()
	for row: Dictionary in _records:
		complete = complete and row.status == "captured"
	if not _write_manifest(complete):
		complete = false
	if not complete:
		push_error("Tidewake matrix incomplete: " + str(_failures))
	quit(0 if complete else 1)
