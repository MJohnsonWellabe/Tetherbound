extends SceneTree

## Complete Settings-catalogue visual survey for one production biome.
##
## This is audit evidence only. It uses Game.debug_teleport_to for destination
## travel and pins the day/night clock; it is never campaign or progression
## evidence. It does not grant progress, creatures, items, health, or access.
## The production world, trainer, encounter population, and ordinary gameplay
## HUD remain present. The production CameraRig/SpringArm3D follows the 1.80 m
## trainer so authored obstruction handling and the player's settled floor are
## part of the evidence rather than recreated by a second camera.
##
##   godot --path . --rendering-driver opengl3 --resolution 1280x800 \
##     --script tools/catalogue_survey.gd -- \
##     --biome=meadows --output=res://shots/catalogue/meadows
##
## Optional: --subset=<case-insensitive id/name substring> (repeatable),
## --times=day or --times=night, and --character=trainer|kael|sera|lyra. The
## character option writes the same Game.local.chosen_character field as the
## production title-screen picker before the world instantiates.

const CATALOGUE_PATH := "res://data/config/debug_teleport_spots.json"
const DEFAULT_OUTPUT_ROOT := "res://shots/catalogue"
const SCENES := {
	"meadows": "res://scenes/world/meadows_playground.tscn",
	"cloudreach": "res://scenes/world/cloudreach_cliffs.tscn",
	"stormwood": "res://scenes/world/stormwood.tscn",
	"water": "res://scenes/world/water_archipelago.tscn",
}
const VALID_TIMES := ["day", "night"]
const VALID_CHARACTERS := ["trainer", "kael", "sera", "lyra"]
const BUILT_FLOOR := preload("res://scripts/world/built_floor.gd")
const BUILD_TIMEOUT_MSEC := 900000
const BOOT_SETTLE_FRAMES := 24
const ARRIVE_FRAMES := 20
const POPULATE_FRAMES := 45
const LIGHT_SETTLE_FRAMES := 12
const POSE_FRAMES := 4
const TRAINER_CLEARANCE := 0.4

var _biome_id := ""
var _output_dir := ""
var _subsets: Array[String] = []
var _times: Array[String] = []
var _character_id := "trainer"
var _world: Node3D
var _player: CharacterBody3D
var _rig: SpringArm3D
var _camera: Camera3D
var _look: Node
var _weather: Node
var _records: Array[Dictionary] = []
var _failures: Array[String] = []
var _planned: Array[Dictionary] = []
var _all_destinations: Array[Dictionary] = []
var _manifest: Dictionary = {}


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("catalogue survey requires a rendering display; never use --headless")
		quit(1)
		return
	if not _parse_args():
		quit(1)
		return
	if not _load_plan():
		quit(1)
		return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(_output_dir))
	if not _output_is_fresh():
		quit(1)
		return
	_begin_manifest()
	_write_manifest()
	if not await _mount_production_world():
		_finish(false)
		return
	if not _prepare_capture_shell():
		_finish(false)
		return
	for row: Dictionary in _planned:
		await _capture_row(row)
	_finish(_failures.is_empty() and _records.size() == _planned.size())


func _parse_args() -> bool:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--biome="):
			_biome_id = arg.trim_prefix("--biome=").strip_edges().to_lower()
		elif arg.begins_with("--output="):
			_output_dir = arg.trim_prefix("--output=").strip_edges()
		elif arg.begins_with("--subset="):
			_subsets.append(arg.trim_prefix("--subset=").strip_edges().to_lower())
		elif arg.begins_with("--times="):
			for value: String in arg.trim_prefix("--times=").split(",", false):
				_times.append(value.strip_edges().to_lower())
		elif arg.begins_with("--character="):
			_character_id = arg.trim_prefix("--character=").strip_edges().to_lower()
	if not SCENES.has(_biome_id):
		push_error("catalogue survey: --biome must be meadows, cloudreach, stormwood, or water")
		return false
	if _output_dir.is_empty():
		_output_dir = "%s/%s" % [DEFAULT_OUTPUT_ROOT, _biome_id]
	if _times.is_empty():
		_times.assign(VALID_TIMES)
	for time_name: String in _times:
		if time_name not in VALID_TIMES:
			push_error("catalogue survey: --times accepts only day and night")
			return false
	if _character_id not in VALID_CHARACTERS:
		push_error("catalogue survey: --character must be trainer, kael, sera, or lyra")
		return false
	return true


func _load_plan() -> bool:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(CATALOGUE_PATH))
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("catalogue survey: invalid %s" % CATALOGUE_PATH)
		return false
	var selected_biome: Dictionary = {}
	for raw_biome: Variant in (parsed as Dictionary).get("biomes", []):
		if raw_biome is Dictionary and str((raw_biome as Dictionary).get("id", "")) == _biome_id:
			selected_biome = raw_biome
			break
	if selected_biome.is_empty():
		push_error("catalogue survey: biome %s is absent from catalogue" % _biome_id)
		return false
	var destination_index := 0
	var frame_ids := {}
	for raw_band: Variant in selected_biome.get("bands", []):
		var band := raw_band as Dictionary
		var spot_index := 0
		for raw_spot: Variant in band.get("spots", []):
			spot_index += 1
			destination_index += 1
			var spot := raw_spot as Dictionary
			var position_value: Variant = spot.get("position", null)
			if typeof(position_value) != TYPE_ARRAY or (position_value as Array).size() != 2:
				push_error("catalogue survey: invalid position for %s" % str(spot.get("display_name", "")))
				return false
			var position_parts := position_value as Array
			if typeof(position_parts[0]) not in [TYPE_INT, TYPE_FLOAT] or typeof(position_parts[1]) not in [TYPE_INT, TYPE_FLOAT]:
				push_error("catalogue survey: non-numeric position for %s" % str(spot.get("display_name", "")))
				return false
			var identity := "%s__%s__%02d__%s" % [_biome_id, str(band.get("id", "")), destination_index, _slug(str(spot.get("display_name", "")))]
			var parsed_x := float(position_parts[0])
			var parsed_z := float(position_parts[1])
			if not is_finite(parsed_x) or not is_finite(parsed_z):
				push_error("catalogue survey: non-finite position for %s" % str(spot.get("display_name", "")))
				return false
			_all_destinations.append({
				"destination_index": destination_index,
				"identity": identity,
				"position_xz": [parsed_x, parsed_z],
				"view_heading_deg": spot.get("view_heading_deg", null),
			})
			var searchable := (identity + " " + str(band.get("display_name", "")) + " " + str(spot.get("display_name", ""))).to_lower()
			if not _matches_subset(searchable):
				continue
			for time_name: String in _times:
				var frame_id := "%s__%s" % [identity, time_name]
				if frame_ids.has(frame_id):
					push_error("catalogue survey: duplicate frame id %s" % frame_id)
					return false
				frame_ids[frame_id] = true
				_planned.append({
					"frame_id": frame_id,
					"biome_id": _biome_id,
					"biome_display_name": str(selected_biome.get("display_name", _biome_id)),
					"band_id": str(band.get("id", "")),
					"band_display_name": str(band.get("display_name", "")),
					"destination_index": destination_index,
					"spot_index_in_band": spot_index,
					"destination_display_name": str(spot.get("display_name", "")),
					"position_xz": [parsed_x, parsed_z],
					"view_heading_deg": spot.get("view_heading_deg", null),
					"time": time_name,
				})
	if _planned.is_empty():
		push_error("catalogue survey: selection yielded no frames")
		return false
	return true


func _matches_subset(searchable: String) -> bool:
	if _subsets.is_empty():
		return true
	for subset: String in _subsets:
		if subset in searchable:
			return true
	return false


func _slug(value: String) -> String:
	var out := ""
	var prior_was_separator := true
	for index in value.length():
		var code := value.unicode_at(index)
		if code == 39: # Apostrophes do not create a separator (Grandpa's -> grandpas).
			continue
		var valid := (code >= 48 and code <= 57) or (code >= 65 and code <= 90) or (code >= 97 and code <= 122)
		if valid:
			out += char(code).to_lower()
			prior_was_separator = false
		elif not prior_was_separator:
			out += "_"
			prior_was_separator = true
	return out.trim_suffix("_") if not out.is_empty() else "unnamed"


func _output_is_fresh() -> bool:
	var manifest_path := "%s/manifest.json" % _output_dir
	if FileAccess.file_exists(manifest_path):
		push_error("catalogue survey: output already has a manifest; choose a unique round directory: %s" % _output_dir)
		return false
	for row: Dictionary in _planned:
		var path := "%s/%s.png" % [_output_dir, str(row.frame_id)]
		if FileAccess.file_exists(path):
			push_error("catalogue survey: refusing to overwrite retained frame %s; choose a unique round directory" % path)
			return false
	return true


func _begin_manifest() -> void:
	_manifest = {
		"schema_version": 1,
		"biome_id": _biome_id,
		"scene": str(SCENES[_biome_id]),
		"catalogue": CATALOGUE_PATH,
		"capture_started_utc": Time.get_datetime_string_from_system(true),
		"display_server": DisplayServer.get_name(),
		"rendering_method": RenderingServer.get_current_rendering_method(),
		"adapter": RenderingServer.get_video_adapter_name(),
		"resolution": [root.size.x, root.size.y],
		"fixture_disclosure": "Production scene and ordinary gameplay HUD. Real player body selected through Game.local.chosen_character and moved through Game.debug_teleport_to at every Settings catalogue coordinate. Audit-only day/night clock freeze. No gameplay/progress/save injection; not campaign proof.",
		"player_character": _character_id,
		"subsets": _subsets,
		"requested_times": _times,
		"planned_frame_ids": _planned.map(func(row: Dictionary) -> String: return str(row.frame_id)),
		"frames": _records,
		"failures": _failures,
		"complete": false,
	}


func _mount_production_world() -> bool:
	var game := root.get_node_or_null(^"Game")
	if game == null:
		_failures.append("Game autoload is missing")
		return false
	var local: Variant = game.get("local")
	if not local is Object:
		_failures.append("Game.local player state is missing")
		return false
	# Match title_screen.gd::_start_new_game_with_character: the production
	# choice is made before reset_for_new_game(), and PlayerState deliberately
	# preserves it across that reset.
	(local as Object).set("chosen_character", _character_id)
	if game.has_method("reset_for_new_game"):
		game.call("reset_for_new_game")
	if str((local as Object).get("chosen_character")) != _character_id:
		_failures.append("production player state did not retain character choice %s" % _character_id)
		return false
	game.set("current_realm", _biome_id)
	print("CATALOGUE BOOT %s load begin t=%d" % [_biome_id, Time.get_ticks_msec()])
	var packed := load(str(SCENES[_biome_id])) as PackedScene
	if packed == null:
		_failures.append("could not load production scene")
		return false
	print("CATALOGUE BOOT %s instantiate begin t=%d" % [_biome_id, Time.get_ticks_msec()])
	_world = packed.instantiate() as Node3D
	print("CATALOGUE BOOT %s attach begin t=%d" % [_biome_id, Time.get_ticks_msec()])
	root.add_child(_world)
	print("CATALOGUE BOOT %s attached t=%d" % [_biome_id, Time.get_ticks_msec()])
	current_scene = _world
	var deadline := Time.get_ticks_msec() + BUILD_TIMEOUT_MSEC
	while _world.has_method("shell_build_complete") and not bool(_world.call("shell_build_complete")):
		if Time.get_ticks_msec() > deadline:
			_failures.append("production world shell build timed out")
			return false
		await process_frame
	for _frame in BOOT_SETTLE_FRAMES:
		await physics_frame
	return true


func _prepare_capture_shell() -> bool:
	_player = _world.get_node_or_null(^"Player") as CharacterBody3D
	_rig = _world.get_node_or_null(^"CameraRig") as SpringArm3D
	_camera = _world.get_node_or_null(^"CameraRig/Camera3D") as Camera3D
	if _player == null or _rig == null or _camera == null:
		_failures.append("production Player or CameraRig/Camera3D is missing")
		return false
	var player_model := _player.get_node_or_null(^"Model")
	if player_model == null or str(player_model.get("_config_key")) != _character_id:
		_failures.append("production Player/Model did not bind requested character %s" % _character_id)
		return false
	_manifest["bound_player_character"] = str(player_model.get("_config_key"))
	_rig.set_process(true)
	_rig.set_physics_process(true)
	_camera.make_current()
	var terrain := _world.get_node_or_null(^"Terrain")
	if terrain != null and terrain.has_method("set_camera"):
		terrain.call("set_camera", _camera)
	_look = _world.get_node_or_null(^"WorldLook")
	_weather = _world.get_node_or_null(^"WorldWeather")
	if _look == null or not _look.has_method("apply_time"):
		_failures.append("production WorldLook/apply_time is missing; day/night labels would be unverified")
		return false
	var camera_metadata := {
		"path": str(_world.get_path_to(_camera)),
		"instance_id": _camera.get_instance_id(),
		"fov": _camera.fov,
		"near": _camera.near,
		"far": _camera.far,
	}
	_manifest["production_camera"] = camera_metadata.duplicate(true)
	_manifest["capture_camera"] = camera_metadata.duplicate(true)
	_manifest["capture_camera"]["source"] = "production CameraRig/Camera3D"
	_manifest["camera_rig"] = {
		"path": str(_world.get_path_to(_rig)),
		"instance_id": _rig.get_instance_id(),
		"class": _rig.get_class(),
		"spring_length": _rig.spring_length,
		"margin": _rig.margin,
		"has_shape": _rig.shape != null,
	}
	return true


func _capture_row(row: Dictionary) -> void:
	var position_values := row.position_xz as Array
	var at := Vector2(float(position_values[0]), float(position_values[1]))
	var forward := _capture_forward(row)
	var game := root.get_node_or_null(^"Game")
	var moved := game != null and bool(game.call("debug_teleport_to", at.x, at.y, _biome_id, ""))
	if not moved:
		_failures.append("%s: Game.debug_teleport_to refused destination" % str(row.frame_id))
		_write_manifest()
		return
	for _frame in ARRIVE_FRAMES:
		await physics_frame
	var terrain_ground := float(_world.call("ground_height_at", at.x, at.y))
	if is_nan(terrain_ground):
		_failures.append("%s: destination has no ground height" % str(row.frame_id))
		_write_manifest()
		return
	var resolved_ground := resolve_capture_ground(_player, at.x, at.y, terrain_ground)
	_player.global_position = Vector3(at.x, resolved_ground + TRAINER_CLEARANCE, at.y)
	_player.velocity = Vector3.ZERO
	_player.rotation.y = atan2(forward.x, forward.y)
	_rig.call("set_target", _player)
	var camera_yaw := capture_yaw(forward)
	var camera_pitch := float(_rig.get("pitch"))
	_rig.set("yaw", camera_yaw)
	_rig.rotation = Vector3(camera_pitch, camera_yaw, 0.0)
	# A catalogue jump is the same remote-target case as loading a saved pose:
	# snap the production pivot so Terrain3D collision and the spring arm update
	# at the destination immediately instead of lerping across kilometres.
	_rig.global_position = _player.global_position
	_camera.make_current()
	_player.reset_physics_interpolation()
	_rig.reset_physics_interpolation()
	_camera.reset_physics_interpolation()
	for _frame in POPULATE_FRAMES:
		await physics_frame
	var observed_clock := await _pin_time(str(row.time))
	if observed_clock.is_empty():
		_write_manifest()
		return
	for _frame in POSE_FRAMES:
		await process_frame
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	var path := "%s/%s.png" % [_output_dir, str(row.frame_id)]
	if image == null or image.is_empty() or image.get_width() != root.size.x or image.get_height() != root.size.y:
		_failures.append("%s: viewport image is empty or wrong-sized" % str(row.frame_id))
	elif image.save_png(path) != OK:
		_failures.append("%s: save_png failed" % str(row.frame_id))
	else:
		var record := row.duplicate(true)
		record["file"] = path
		record["debug_travel"] = true
		record["player_position"] = _vec3(_player.global_position)
		record["camera_position"] = _vec3(_camera.global_position)
		record["view_heading_xz"] = [forward.x, forward.y]
		record["terrain_ground_y"] = terrain_ground
		record["resolved_ground_y"] = resolved_ground
		record["camera_rig_transform"] = _transform(_rig.global_transform)
		record["camera_rig_spring_length"] = _rig.spring_length
		record["camera_transform"] = _transform(_camera.global_transform)
		record["camera_player_distance_m"] = _camera.global_position.distance_to(_player.global_position)
		record["observed_clock"] = observed_clock
		record["trainer_visible_intent"] = true
		record["player_character"] = _character_id
		record["trainer_visibility_limit"] = "Production spring-arm framing; manifest does not prove pixels are unobstructed. Judge the frame."
		var nearby_creatures := _nearby_creatures(_player.global_position)
		record["nearby_creatures_160m"] = nearby_creatures.size()
		record["nearby_creature_records_160m"] = nearby_creatures
		record["bytes"] = FileAccess.get_file_as_bytes(path).size()
		_records.append(record)
		print("CATALOGUE CAPTURE %s -> %s" % [str(row.frame_id), path])
	_write_manifest()


func _route_forward(destination_index: int) -> Vector2:
	var current_index := -1
	for index in _all_destinations.size():
		if int(_all_destinations[index].destination_index) == destination_index:
			current_index = index
			break
	if current_index < 0:
		return Vector2(0.0, 1.0)
	var current_values := _all_destinations[current_index].position_xz as Array
	var current := Vector2(float(current_values[0]), float(current_values[1]))
	var neighbour_index := current_index + 1 if current_index + 1 < _all_destinations.size() else current_index - 1
	if neighbour_index < 0:
		return Vector2(0.0, 1.0)
	var neighbour_values := _all_destinations[neighbour_index].position_xz as Array
	var neighbour := Vector2(float(neighbour_values[0]), float(neighbour_values[1]))
	var direction := (neighbour - current).normalized()
	if current_index == _all_destinations.size() - 1:
		direction = -direction
	return direction if direction.length_squared() > 0.0 else Vector2(0.0, 1.0)


func _capture_forward(row: Dictionary) -> Vector2:
	var authored: Variant = row.get("view_heading_deg", null)
	if (typeof(authored) == TYPE_INT or typeof(authored) == TYPE_FLOAT) \
			and is_finite(float(authored)):
		var yaw := deg_to_rad(float(authored))
		return Vector2(sin(yaw), cos(yaw))
	return _route_forward(int(row.destination_index))


static func resolve_capture_ground(from: Node, x: float, z: float, terrain: float) -> float:
	return BUILT_FLOOR.resolve(from, x, z, terrain)


static func capture_yaw(forward: Vector2) -> float:
	return atan2(-forward.x, -forward.y)


func _pin_time(time_name: String) -> Dictionary:
	if _look == null or not _look.has_method("apply_time"):
		_failures.append("%s: production WorldLook/apply_time became unavailable" % time_name)
		return {}
	if _look.has_method("times_available") \
			and time_name not in (_look.call("times_available") as Array):
		_failures.append("%s: requested time is absent from production WorldLook" % time_name)
		return {}
	if _weather != null:
		_weather.set_process(true)
		_weather.set_physics_process(true)
		if _weather.has_method("set_weather"):
			_weather.call("set_weather", "clear")
	_look.set_process(true)
	_look.set_physics_process(true)
	if _look.has_method("set_clock_frozen"):
		_look.call("set_clock_frozen", false)
	_look.call("apply_time", time_name)
	for _frame in LIGHT_SETTLE_FRAMES:
		await physics_frame
	if _weather != null:
		_weather.set_process(false)
		_weather.set_physics_process(false)
	if _look.has_method("set_clock_frozen"):
		_look.call("set_clock_frozen", true)
	_look.set_process(false)
	_look.set_physics_process(false)
	var observed := {"requested": time_name}
	if _look.has_method("time_of_day"):
		observed["time_of_day"] = str(_look.call("time_of_day"))
		if str(observed.time_of_day) != time_name:
			_failures.append("%s: WorldLook reports observed time '%s'" % [time_name, str(observed.time_of_day)])
			return {}
	if _look.has_method("hour"):
		observed["hour"] = float(_look.call("hour"))
	if _look.has_method("elapsed_seconds"):
		observed["elapsed_seconds"] = float(_look.call("elapsed_seconds"))
	return observed


func _nearby_creatures(at: Vector3) -> Array[Dictionary]:
	var director := _world.get_node_or_null(^"EncounterDirector")
	if director == null or not director.has_method("wild_creatures"):
		return []
	var records: Array[Dictionary] = []
	for value: Variant in director.call("wild_creatures"):
		var body := value as Node3D
		if body != null and is_instance_valid(body) and body.global_position.distance_to(at) <= 160.0:
			var record := {
				"node_path": str(_world.get_path_to(body)),
				"species_id": str(body.get("species_id")),
				"position": _vec3(body.global_position),
				"node_scale": _vec3(body.global_basis.get_scale()),
			}
			# CreatureBody exposes gameplay dimensions as the public size contract;
			# its render-bounds helper is private, so no bounds claim is invented.
			if body.has_method("body_height"):
				record["body_height_m"] = float(body.call("body_height"))
			if body.has_method("body_radius"):
				record["body_radius_m"] = float(body.call("body_radius"))
			records.append(record)
	records.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return str(a.node_path) < str(b.node_path))
	return records


func _vec3(value: Vector3) -> Array[float]:
	return [value.x, value.y, value.z]


func _transform(value: Transform3D) -> Dictionary:
	return {
		"origin": _vec3(value.origin),
		"basis_x": _vec3(value.basis.x),
		"basis_y": _vec3(value.basis.y),
		"basis_z": _vec3(value.basis.z),
	}


func _write_manifest() -> void:
	_manifest["frames"] = _records
	_manifest["failures"] = _failures
	var file := FileAccess.open("%s/manifest.json" % _output_dir, FileAccess.WRITE)
	if file == null:
		push_error("catalogue survey: could not write manifest")
		return
	file.store_string(JSON.stringify(_manifest, "\t") + "\n")
	file.close()


func _finish(complete: bool) -> void:
	_manifest["capture_finished_utc"] = Time.get_datetime_string_from_system(true)
	_manifest["complete"] = complete
	_manifest["captured_frame_count"] = _records.size()
	_manifest["planned_frame_count"] = _planned.size()
	_write_manifest()
	if not complete:
		for failure: String in _failures:
			push_error("catalogue survey: %s" % failure)
	print("CATALOGUE SURVEY %s: %d/%d frames in %s" % ["OK" if complete else "FAILED", _records.size(), _planned.size(), _output_dir])
	quit(0 if complete else 1)
