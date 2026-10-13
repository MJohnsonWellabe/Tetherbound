extends "res://tools/phase2_capture_tidewake_fights.gd"

## One-preset F39 matrix. Location rows use the installed production Water
## scene, CameraRig, floor/capsule checks, weather, and WorldLook. The eight
## fight rows are captured only from the installed input-piloted Venn fight.
## Nothing here fabricates a fight pose or substitutes a missed row.

const LOCATIONS := preload("res://tools/phase2_capture_locations.gd")
const BOOTSTRAP := preload("res://tools/lookdev_capture_bootstrap.gd")
const GAME_SCENE := "res://scenes/world/water_archipelago.tscn"
const TRAINER_ID := "water_trainer_venn"
const SOURCE_CATALOGUE := "res://data/config/debug_teleport_spots.json"
const BUILD_TIMEOUT_MSEC := 900000
const ARRIVE_FRAMES := 20
const POPULATE_FRAMES := 45
const LIGHT_SETTLE_FRAMES := 12
const POSE_FRAMES := 4
const TRAINER_CLEARANCE := 0.4
const CAMERA_MIN_M := 3.5

var _job_manifest_path := ""
var _source_commit := ""
var _preset_name := ""
var _matrix_output := ""
var _matrix_rows: Array[Dictionary] = []
var _matrix_records: Array[Dictionary] = []
var _matrix_failures: Array[String] = []
var _matrix_keys := {}
var _fight_rows: Array[Dictionary] = []
var _fight_moments: Dictionary = {}
var _catalog_positions: Dictionary = {}
var _coordinate_discrepancies: Array[Dictionary] = []
var _fight_world: Node3D
var _fight_game: Node
var _world: Node3D
var _player: CharacterBody3D
var _rig: SpringArm3D
var _camera: Camera3D
var _look: Node
var _weather: Node
var _graphics: Dictionary = {}
var _weather_requested := "clear"
var _fight_switch_requested := false
var _fight_switch_source := ""
var _fight_switch_applied := false
var _fight_hit_serial := 0
var _fight_hit_seen := 0
var _fight_hit_source := ""
var _last_actor_positions := {}
var _manifest_write_failed := false


func _run() -> void:
	_parse_matrix_args()
	if not _validate_matrix_inputs():
		quit(1)
		return
	_graphics = BOOTSTRAP.prepare(self, "--out=")
	if _graphics.is_empty() or _graphics.get("resolution", []) != [1920, 1080]:
		_matrix_failures.append("graphics bootstrap did not establish the declared 1920x1080 preset")
		quit(1)
		return
	if not _load_matrix_plan():
		quit(1)
		return
	if DisplayServer.get_name() == "headless" or root.size != Vector2i(1920, 1080) \
			or DisplayServer.window_get_size() != Vector2i(1920, 1080):
		_matrix_failures.append("native display/window/viewport is not 1920x1080")
		quit(1)
		return
	DirAccess.make_dir_recursive_absolute(_matrix_output)
	_out = _matrix_output
	_level = 53
	_max_frames = 64
	_interval = 0.8
	_fight_cap_s = 180.0
	_policy = "QUICK"
	_attempt = {"source_commit": _source_commit, "preset": _preset_name,
		"job_manifest": _job_manifest_path, "trainer": TRAINER_ID,
		"party": PARTY, "level": _level, "interior_flags": INTERIOR_FLAGS,
		"pilot": "installed production QUICK input pilot; party_cycle is injected once as a player input"}
	seed(2042)
	_write_matrix_manifest(false)
	if not await _mount_fight_world():
		_finish_matrix()
		return
	for row: Dictionary in _fight_rows:
		_fight_moments[str(row.paired_frame_key)] = row.duplicate(true)
	if not await _capture_pre_engage():
		_finish_matrix()
		return
	var fought := await _capture(_world, _fight_game, TRAINER_ID)
	if not fought:
		_matrix_failures.append("production Venn fight capture did not complete through the real encounter runner")
	else:
		await _capture_victory_aftermath()
		for row: Dictionary in _matrix_rows:
			if str(row.group) != "real-fight":
				await _capture_location_row(row)
	for row: Dictionary in _matrix_rows:
		if not _matrix_keys.has(str(row.paired_frame_key)):
			_matrix_failures.append("required frame missing: %s" % str(row.paired_frame_key))
	_finish_matrix()


func _parse_matrix_args() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--job-manifest="):
			_job_manifest_path = arg.trim_prefix("--job-manifest=").strip_edges()
		elif arg.begins_with("--source-commit="):
			_source_commit = arg.trim_prefix("--source-commit=").strip_edges().to_lower()
		elif arg.begins_with("--preset="):
			_preset_name = arg.trim_prefix("--preset=").strip_edges()
		elif arg.begins_with("--out="):
			_matrix_output = arg.trim_prefix("--out=").strip_edges().trim_suffix("/")


func _validate_matrix_inputs() -> bool:
	var hash_check := RegEx.new()
	hash_check.compile("^[0-9a-f]{40}$")
	if hash_check.search(_source_commit) == null or _preset_name not in ["High", "Medium"] \
			or _job_manifest_path.is_empty() or _matrix_output.is_empty():
		push_error("F39 matrix requires --job-manifest, --source-commit, --preset=High|Medium, and --out")
		return false
	if not FileAccess.file_exists(_job_manifest_path):
		push_error("F39 paired job manifest is missing: %s" % _job_manifest_path)
		return false
	if DirAccess.dir_exists_absolute(_matrix_output):
		push_error("F39 matrix output must be a fresh, non-existent directory")
		return false
	return true


func _load_matrix_plan() -> bool:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(_job_manifest_path))
	if not parsed is Dictionary or str(parsed.get("packet_schema", "")) != "tidewake-f39-paired-jobs-v1":
		push_error("F39 paired job manifest schema is not recognized")
		return false
	if str(parsed.get("status", "")) != "planned" or int(parsed.get("minimum_valid_actual_frames_per_preset", 0)) != 200:
		push_error("F39 paired plan is not the required planned 200-frame matrix")
		return false
	var selected: Dictionary = {}
	var preset_rows := {}
	for preset: Variant in parsed.get("presets", []):
		if not preset is Dictionary:
			continue
		var preset_name := str(preset.get("name", ""))
		if preset_name in ["High", "Medium"]:
			preset_rows[preset_name] = preset
		if preset_name == _preset_name:
			selected = preset
	if not preset_rows.has("High") or not preset_rows.has("Medium") \
			or not _validate_preset_pair(preset_rows.High, preset_rows.Medium):
		push_error("F39 High/Medium frame keys or visual dimensions are not identical")
		return false
	if selected.is_empty() or str(selected.get("renderer", "")) != "forward_plus" \
			or str(selected.get("resolution", "")) != "1920x1080" \
			or int(selected.get("planned_frame_count", -1)) != 200:
		push_error("F39 selected preset contract is absent or differs from forward_plus 1920x1080/200")
		return false
	var key_seen := {}
	for raw: Variant in selected.get("frames", []):
		if not raw is Dictionary:
			push_error("F39 plan contains a non-object frame row")
			return false
		var row: Dictionary = raw.duplicate(true)
		var key := str(row.get("paired_frame_key", ""))
		if key.is_empty() or key_seen.has(key) or not bool(row.get("required", false)):
			push_error("F39 plan has a missing/duplicate key or a non-required row")
			return false
		key_seen[key] = true
		_matrix_rows.append(row)
		if str(row.get("group", "")) == "real-fight":
			_fight_rows.append(row)
	if _matrix_rows.size() != 200 or _fight_rows.size() != 8:
		push_error("F39 plan must contain exactly 200 rows including 8 live-fight moments")
		return false
	var group_counts := {"catalog-sighting": 0, "camera-weather-matrix": 0, "real-fight": 0}
	for row: Dictionary in _matrix_rows:
		var group := str(row.get("group", ""))
		if not group_counts.has(group):
			push_error("F39 row has an unsupported group: %s" % group)
			return false
		group_counts[group] = int(group_counts[group]) + 1
	if group_counts != {"catalog-sighting": 96, "camera-weather-matrix": 96, "real-fight": 8}:
		push_error("F39 plan group counts do not match 96+96+8")
		return false
	if not _validate_catalog_rows():
		return false
	return true


func _validate_preset_pair(high: Dictionary, medium: Dictionary) -> bool:
	if int(high.get("planned_frame_count", -1)) != 200 or int(medium.get("planned_frame_count", -1)) != 200 \
			or str(high.get("renderer", "")) != "forward_plus" \
			or str(medium.get("renderer", "")) != "forward_plus" \
			or str(high.get("resolution", "")) != "1920x1080" \
			or str(medium.get("resolution", "")) != "1920x1080":
		return false
	var high_rows: Array = high.get("frames", [])
	var medium_rows: Array = medium.get("frames", [])
	if high_rows.size() != 200 or medium_rows.size() != 200:
		return false
	for index in 200:
		var first: Dictionary = high_rows[index]
		var second: Dictionary = medium_rows[index]
		for field: String in ["paired_frame_key", "group", "base_sighting_id", "band_id", "destination",
				"destination_index", "position_xz", "baseline_position_xz", "baseline_heading_xz",
				"coordinate_source", "view", "time", "weather", "encounter", "moment", "capture_spec"]:
			if first.get(field, null) != second.get(field, null):
				return false
	return true


func _validate_catalog_rows() -> bool:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(SOURCE_CATALOGUE))
	if not parsed is Dictionary:
		push_error("Current-source debug teleport catalogue is unreadable")
		return false
	var spots := {}
	for band_value: Variant in parsed.get("biomes", []):
		if not band_value is Dictionary or str(band_value.get("id", "")) != "water":
			continue
		for band: Variant in band_value.get("bands", []):
			if not band is Dictionary:
				continue
			for spot: Variant in (band as Dictionary).get("spots", []):
				if not spot is Dictionary:
					continue
		spots[_slug(str(spot.get("display_name", "")))] = spot
	if spots.size() != 24:
		push_error("Current Tidewake catalogue does not resolve exactly 24 sightings")
		return false
	for row: Dictionary in _matrix_rows:
		if str(row.get("group", "")) == "real-fight":
			continue
		var sighting_parts := str(row.get("base_sighting_id", "")).split("__", false)
		var slug := str(sighting_parts[sighting_parts.size() - 1]) if sighting_parts.size() >= 3 else ""
		if not spots.has(slug):
			push_error("Paired sighting is absent from current-source debug catalogue: %s" % str(row.paired_frame_key))
			return false
		var spot: Dictionary = spots[slug]
		var position: Array = spot.get("position", [])
		var planned: Array = row.get("position_xz", [])
		if position.size() != 2 or planned.size() != 2 \
				or not is_finite(float(position[0])) or not is_finite(float(position[1])):
			push_error("Current-source catalogue coordinate is invalid: %s" % str(row.paired_frame_key))
			return false
		_catalog_positions[str(row.get("base_sighting_id", ""))] = [float(position[0]), float(position[1])]
		if not is_equal_approx(float(position[0]), float(planned[0])) \
				or not is_equal_approx(float(position[1]), float(planned[1])):
			var already_recorded := false
			for mismatch: Dictionary in _coordinate_discrepancies:
				if str(mismatch.get("base_sighting_id", "")) == str(row.base_sighting_id):
					already_recorded = true
					break
			if not already_recorded:
				_coordinate_discrepancies.append({"base_sighting_id": str(row.base_sighting_id),
					"destination": str(row.get("destination", "")),
					"declared_manifest_position_xz": planned.duplicate(),
					"resolved_current_source_position_xz": [float(position[0]), float(position[1])],
					"coordinate_source": SOURCE_CATALOGUE,
					"policy": "capture exact current-source named sighting; keep declared coordinate discrepancy in both preset receipts"})
		if str(row.get("weather", "")) not in ["clear", "rain"] \
				or str(row.get("time", "")) not in ["day", "night"]:
			push_error("F39 location row has unsupported time/weather dimensions")
			return false
		var spec: Dictionary = row.get("capture_spec", {})
		if str(spec.get("camera", "")) != "production CameraRig/Camera3D" \
				or str(spec.get("support_failure", "")) == "" \
				or not spec.has("stand_offset_candidates_m"):
			push_error("F39 location row omits production camera/support contract")
			return false
	return true


func _mount_fight_world() -> bool:
	var game := root.get_node_or_null(^"Game")
	if game == null:
		_matrix_failures.append("Game autoload is missing")
		return false
	game.set("current_realm", "water")
	var local: Object = game.get("local")
	if local == null:
		_matrix_failures.append("Game.local player state is missing")
		return false
	local.set("character_id", "tidewake-f39-capture")
	var world_state: Object = game.get("world")
	if world_state == null:
		_matrix_failures.append("Game.world state is missing")
		return false
	world_state.set("world_id", "tidewake-f39-capture-world")
	game.set("save_system", SAVE.new("user://tidewake_f39_capture_%d/" % Time.get_ticks_usec()))
	for species_id: String in PARTY:
		var creature: RefCounted = SPECIES.spawn(species_id)
		if creature == null:
			_matrix_failures.append("Could not instantiate declared live-fight party member %s" % species_id)
			return false
		creature.set_level(_level, PROGRESSION.config())
		var party: Object = local.get("party")
		if party == null:
			_matrix_failures.append("Game.local.party is missing")
			return false
		party.call("add", creature)
	for flag: String in INTERIOR_FLAGS:
		var flags: Object = world_state.get("flags")
		if flags == null:
			_matrix_failures.append("Game.world.flags is missing")
			return false
		flags.call("set_flag", flag)
	_world = load(GAME_SCENE).instantiate() as Node3D
	if _world == null:
		_matrix_failures.append("Production Tidewake scene failed to instantiate")
		return false
	root.add_child(_world)
	current_scene = _world
	var deadline := Time.get_ticks_msec() + BUILD_TIMEOUT_MSEC
	while _world.has_method("shell_build_complete") and not bool(_world.call("shell_build_complete")):
		if Time.get_ticks_msec() > deadline:
			_matrix_failures.append("Production Tidewake shell build timed out")
			return false
		await process_frame
	for _frame in 24:
		await physics_frame
	_player = _world.call("local_rig") as CharacterBody3D
	_rig = _world.get_node_or_null(^"CameraRig") as SpringArm3D
	_camera = _world.get_node_or_null(^"CameraRig/Camera3D") as Camera3D
	_look = _world.get_node_or_null(^"WorldLook")
	_weather = _world.get_node_or_null(^"WorldWeather")
	if _player == null or _rig == null or _camera == null or _look == null or _weather == null \
			or not _look.has_method("apply_time") or not _weather.has_method("set_weather") \
			or not _weather.has_method("weather"):
		_matrix_failures.append("Production player, CameraRig, WorldLook, or WorldWeather API missing")
		return false
	_rig.set_process(true)
	_rig.set_physics_process(true)
	_camera.make_current()
	var terrain := _world.get_node_or_null(^"Terrain")
	if terrain != null and terrain.has_method("set_camera"):
		terrain.call("set_camera", _camera)
	_fight_world = _world
	_fight_game = game
	var clock := await _apply_time_weather("day", "clear")
	if clock.is_empty():
		return false
	_matrix_manifest["production_camera"] = {"path": str(_world.get_path_to(_camera)),
		"instance_id": _camera.get_instance_id(), "fov": _camera.fov,
		"near": _camera.near, "far": _camera.far}
	_matrix_manifest["camera_rig"] = {"path": str(_world.get_path_to(_rig)),
		"instance_id": _rig.get_instance_id(), "class": _rig.get_class(),
		"spring_length": _rig.spring_length, "margin": _rig.margin,
		"has_shape": _rig.shape != null}
	return true


var _matrix_manifest: Dictionary = {}


func _capture_pre_engage() -> bool:
	var director := _world.get_node_or_null(^"EncounterDirector")
	var manager := _world.get_node_or_null(^"CombatManager")
	var specs: Dictionary = director.get("trainer_specs") if director != null else {}
	var spec: Dictionary = specs.get(TRAINER_ID, {})
	if director == null or manager == null or spec.is_empty() or not spec.has("position"):
		_matrix_failures.append("Authored Venn production trainer spec is missing")
		return false
	if bool(director.call("_host_holds_trainer_defeat", TRAINER_ID)):
		_matrix_failures.append("Venn is already defeated in the isolated capture fixture")
		return false
	var pos: Array = spec.position
	var near := Vector3(float(pos[0]), 0.0, float(pos[2]) + 6.0)
	near.y = float(_world.call("ground_height_at", near.x, near.z)) + 0.3
	_player.global_position = near
	_player.velocity = Vector3.ZERO
	for _frame in 30:
		await physics_frame
	var deadline := Time.get_ticks_msec() + 60000
	while not director.get("trainer_nodes").has(TRAINER_ID) and Time.get_ticks_msec() < deadline:
		await process_frame
	var trainer: Node3D = director.get("trainer_nodes").get(TRAINER_ID)
	if trainer == null:
		_matrix_failures.append("Production Venn actor did not stand up")
		return false
	_player.global_position = trainer.global_position + trainer.global_basis.z * 2.7 + Vector3(0, 0.1, 0)
	_player.velocity = Vector3.ZERO
	var facing := trainer.global_position - _player.global_position
	facing.y = 0.0
	if facing.length_squared() > 0.001:
		_player.rotation.y = atan2(facing.x, facing.z)
		_rig.call("set_target", _player)
		_rig.set("yaw", LOCATIONS.capture_yaw(Vector2(facing.x, facing.z).normalized()))
		_rig.global_position = _player.global_position
	await _frames(20)
	if not await director.call("summon_active_creature"):
		_matrix_failures.append("Production lead summon failed before Venn challenge")
		return false
	await _frames(12)
	return await _save_fight_row(_fight_row("pre-engage"), "before challenge", false)


func _capture(world: Node3D, game: Node, id: String) -> bool:
	if id != TRAINER_ID or bool(world.get_node("EncounterDirector").call("_host_holds_trainer_defeat", id)):
		_matrix_failures.append("Only a fresh production water_trainer_venn fight is accepted")
		return false
	var director: Node = world.get_node("EncounterDirector")
	var manager: Node = world.get_node("CombatManager")
	var prompt: Node3D = director.get("trainer_prompts").get(id)
	if prompt == null or prompt.call("interaction_offer", _player.global_position).is_empty():
		_matrix_failures.append("Venn challenge prompt is not actionable from the production stand")
		return false
	prompt.call("interaction_activate")
	await _frames(3)
	var dialogue: Node = world.get_node_or_null(^"DialoguePanel")
	for _step in 30:
		if manager.call("is_fighting") or dialogue == null or not dialogue.call("is_open"):
			break
		dialogue.call("advance")
		await _frames(3)
	if str(director.call("trainer_battle_id")) != TRAINER_ID or not bool(manager.call("is_fighting")):
		_matrix_failures.append("Real production Venn trainer battle did not activate through its prompt")
		return false
	return await _record(world, game, id, Callable(director, "trainer_battle_active"))


func _record(world: Node3D, game: Node, label: String, active: Callable) -> bool:
	var director: Node = world.get_node("EncounterDirector")
	var manager: Node = world.get_node("CombatManager")
	_record_result = {}
	_save_failures = 0
	var receipt := VICTORY_RECEIPT.new()
	if not receipt.begin(manager):
		_matrix_failures.append("Production Venn victory observer unavailable")
		_record_result = {"ok": false, "reason": "victory observer unavailable"}
		return false
	_fight_t = 0.0
	var tick := 0
	_fight_hit_serial = 0
	_fight_hit_seen = 0
	_fight_hit_source = ""
	_last_actor_positions = {}
	var on_hit := func(on_enemy: bool, _amount: float) -> void:
		_fight_hit_serial += 1
		_fight_hit_source = "player" if on_enemy else "opponent"
	manager.hit_landed.connect(on_hit)
	if not RenderingServer.render_loop_enabled:
		RenderingServer.render_loop_enabled = true
	while bool(active.call()) and _fight_t < _fight_cap_s:
		var enemy: Node3D = manager.call("enemy_body")
		var ally: Node3D = director.call("ally_body")
		if is_instance_valid(enemy) and is_instance_valid(ally):
			if not _matrix_keys.has(_fight_key("opponent-tell")) \
					and manager.has_method("enemy_is_winding_up") \
					and bool(manager.call("enemy_is_winding_up")):
				await _save_fight_row(_fight_row("opponent-tell"), "production opponent telegraph is active", true)
			if not _matrix_keys.has(_fight_key("ally-attack-windup")) \
					and _actor_has_animation(ally, "attack"):
				await _save_fight_row(_fight_row("ally-attack-windup"), "production ally attack animation is active", true)
			if _fight_hit_serial > _fight_hit_seen:
				_fight_hit_seen = _fight_hit_serial
				if not _matrix_keys.has(_fight_key("contact")):
					await _save_fight_row(_fight_row("contact"),
						"production hit_landed signal (%s)" % _fight_hit_source, true)
				elif not _matrix_keys.has(_fight_key("damage-response")) \
						and (_actor_has_animation(enemy, "hit") or _actor_has_animation(ally, "hit")):
					await _save_fight_row(_fight_row("damage-response"),
						"production damage response animation follows hit_landed", true)
			if not _fight_switch_requested and _fight_t >= 2.0:
				_fight_switch_source = str(ally.get("species_id"))
				_fight_switch_requested = true
				Input.action_press("party_cycle")
				await physics_frame
				Input.action_release("party_cycle")
				await physics_frame
				var switched: Node3D = director.call("ally_body")
				_fight_switch_applied = is_instance_valid(switched) \
					and str(switched.get("species_id")) != _fight_switch_source
				if _fight_switch_applied:
					await _save_fight_row(_fight_row("tag-switch"),
						"party_cycle input changed the active combatant", true)
				else:
					_matrix_failures.append("party_cycle input did not change the active Venn combatant")
			enemy = manager.call("enemy_body")
			ally = director.call("ally_body")
			if is_instance_valid(enemy) and is_instance_valid(ally):
				var positions := {"enemy": enemy.global_position, "ally": ally.global_position}
				if not _last_actor_positions.is_empty() \
						and (positions.enemy.distance_to(_last_actor_positions.enemy) > 0.75 \
						or positions.ally.distance_to(_last_actor_positions.ally) > 0.75) \
						and not _matrix_keys.has(_fight_key("reposition")):
					await _save_fight_row(_fight_row("reposition"),
						"production combatant transform changed during active combat", true)
				_last_actor_positions = positions
				_pilot(world, manager, enemy, ally, tick)
		tick += 1
		await physics_frame
		_fight_t += 1.0 / Engine.physics_ticks_per_second
	_release()
	Input.action_release("party_cycle")
	manager.hit_landed.disconnect(on_hit)
	var still_active := bool(active.call())
	_record_result = capture_terminal_result(still_active, _fight_t, _fight_cap_s,
		_matrix_records.size(), _max_frames, receipt.finish(still_active), _save_failures)
	if not bool(_record_result.get("ok", false)):
		_matrix_failures.append("Production Venn combat did not finish successfully: %s" % str(_record_result.get("reason", "unknown")))
	return bool(_record_result.get("ok", false))


func _fight_row(moment: String) -> Dictionary:
	var key := _fight_key(moment)
	return _fight_moments.get(key, {})


func _fight_key(moment: String) -> String:
	return "realfight-water_trainer_venn-%02d-%s" % [
		{"pre-engage": 1, "opponent-tell": 2, "ally-attack-windup": 3,
		"contact": 4, "damage-response": 5, "tag-switch": 6,
		"reposition": 7, "victory-aftermath": 8}.get(moment, 0), moment]


func _actor_has_animation(actor: Node3D, role: String) -> bool:
	if not is_instance_valid(actor):
		return false
	var animator: Object = actor.get("_animator")
	return animator != null and str(animator.get("_current")).contains(role)


func _capture_victory_aftermath() -> void:
	var manager := _world.get_node_or_null(^"CombatManager")
	var director := _world.get_node_or_null(^"EncounterDirector")
	if manager == null or director == null or bool(manager.call("is_fighting")) \
			or not bool(director.call("_host_holds_trainer_defeat", TRAINER_ID)):
		_matrix_failures.append("Venn victory aftermath unavailable; no still-frame substitute recorded")
		return
	await _save_fight_row(_fight_row("victory-aftermath"), "actual production Venn defeat recorded", false)


func _save_fight_row(row: Dictionary, witness: String, require_live: bool) -> bool:
	if row.is_empty():
		return false
	var key := str(row.get("paired_frame_key", ""))
	if _matrix_keys.has(key):
		return true
	var manager := _world.get_node_or_null(^"CombatManager")
	var director := _world.get_node_or_null(^"EncounterDirector")
	var live := manager != null and bool(manager.call("is_fighting")) \
		and director != null and str(director.call("trainer_battle_id")) == TRAINER_ID
	if require_live and not live:
		_matrix_failures.append("Fight row %s rejected outside live Venn combat" % key)
		return false
	if root.get_camera_3d() != _camera or not RenderingServer.render_loop_enabled:
		_matrix_failures.append("Fight row %s rejected because the production camera/render loop is inactive" % key)
		return false
	if row.get("encounter", TRAINER_ID) != TRAINER_ID \
			or str(row.get("time", "day")) != "day" or str(row.get("weather", "clear")) != "clear":
		_matrix_failures.append("Fight row %s differs from its pinned Venn/day/clear contract" % key)
		return false
	await RenderingServer.frame_post_draw
	if require_live and (not bool(manager.call("is_fighting")) \
			or str(director.call("trainer_battle_id")) != TRAINER_ID):
		_matrix_failures.append("Fight row %s became inactive before the frame was saved" % key)
		return false
	return await _save_image_row(row, {"fight_witness": witness, "fight_active_at_save": live,
		"encounter": TRAINER_ID, "fight_seconds": _fight_t,
		"director_battle_id": str(director.call("trainer_battle_id")),
		"production_enemy_position": _node_position(manager.call("enemy_body")) if manager != null else [],
		"production_ally_position": _node_position(director.call("ally_body")) if director != null else [],
		"camera_transform": _transform(_camera.global_transform), "player_transform": _transform(_player.global_transform)})


func _capture_location_row(row: Dictionary) -> void:
	var key := str(row.paired_frame_key)
	var position: Array = row.get("position_xz", [])
	var spec: Dictionary = row.get("capture_spec", {})
	if position.size() != 2 or not spec.has("stand_offset_candidates_m"):
		_matrix_failures.append("%s: missing pinned coordinates or stand candidates" % key)
		return
	var heading_values: Array = row.get("baseline_heading_xz", [])
	if heading_values.size() != 2:
		_matrix_failures.append("%s: missing pinned catalogue heading" % key)
		return
	var base_forward := Vector2(float(heading_values[0]), float(heading_values[1])).normalized()
	var offset_degrees := float(spec.get("camera_heading_delta_deg", 0.0))
	var camera_forward := base_forward.rotated(deg_to_rad(offset_degrees))
	var declared_position := [float(position[0]), float(position[1])]
	var resolved_position: Array = _catalog_positions.get(str(row.get("base_sighting_id", "")), declared_position)
	var target := Vector2(float(resolved_position[0]), float(resolved_position[1]))
	var offsets: Array = spec.get("stand_offset_candidates_m", [])
	var lateral := float(spec.get("lateral_m", 0.0))
	var selected := false
	var rejected: Array[Dictionary] = []
	var final_stand := Vector2.ZERO
	var final_spec: Dictionary = {}
	var final_offset := NAN
	var terrain_y := NAN
	var resolved_y := NAN
	for raw_offset: Variant in offsets:
		var offset := float(raw_offset)
		var stand := target - base_forward * offset + Vector2(-base_forward.y, base_forward.x) * lateral
		var moved := bool(Game.call("debug_teleport_to", stand.x, stand.y, "water", ""))
		if not moved:
			rejected.append({"offset_m": offset, "stand_xz": [stand.x, stand.y], "stage": "travel", "reason": "debug travel failed"})
			continue
		for _frame in ARRIVE_FRAMES:
			await physics_frame
		terrain_y = float(_world.call("ground_height_at", stand.x, stand.y))
		if not is_finite(terrain_y):
			rejected.append({"offset_m": offset, "stand_xz": [stand.x, stand.y], "stage": "ground", "reason": "non-finite terrain height"})
			continue
		resolved_y = terrain_y if bool(row.get("prefer_terrain_ground", false)) \
			else LOCATIONS.resolve_capture_ground(_player, stand.x, stand.y, terrain_y)
		var stand_spec := _capture_support_spec(stand, terrain_y, resolved_y)
		var rejection := _capture_support_preflight(stand_spec)
		if not rejection.is_empty():
			rejected.append({"offset_m": offset, "stand_xz": [stand.x, stand.y], "stage": "preflight", "reason": rejection, "support": stand_spec})
			continue
		_player.global_position = stand_spec.position
		_player.velocity = Vector3.ZERO
		_player.rotation.y = atan2(base_forward.x, base_forward.y)
		_rig.call("set_target", _player)
		_rig.set("pitch", float(_rig.get("pitch")))
		_rig.set("yaw", LOCATIONS.capture_yaw(camera_forward))
		_rig.rotation = Vector3(float(_rig.get("pitch")), LOCATIONS.capture_yaw(camera_forward), 0.0)
		_rig.global_position = _player.global_position
		_camera.make_current()
		_player.reset_physics_interpolation()
		_rig.reset_physics_interpolation()
		_camera.reset_physics_interpolation()
		for _frame in POPULATE_FRAMES:
			await physics_frame
		for _frame in 2:
			await process_frame
		_weather_requested = str(row.weather)
		var clock := await _apply_time_weather(str(row.time), _weather_requested)
		if clock.is_empty():
			_matrix_failures.append("%s: production time/weather state did not settle" % key)
			return
		for _frame in POSE_FRAMES:
			await process_frame
		rejection = _capture_location_guard(stand, row, stand_spec)
		if not rejection.is_empty():
			rejected.append({"offset_m": offset, "stand_xz": [stand.x, stand.y], "stage": "settled", "reason": rejection,
				"player_position": _vec3(_player.global_position), "camera_position": _vec3(_camera.global_position)})
			continue
		_hide_hud()
		await RenderingServer.frame_post_draw
		rejection = _capture_location_guard(stand, row, stand_spec)
		if not rejection.is_empty():
			rejected.append({"offset_m": offset, "stand_xz": [stand.x, stand.y], "stage": "draw", "reason": rejection,
				"player_position": _vec3(_player.global_position), "camera_position": _vec3(_camera.global_position)})
			continue
		if not _weather_time_matches(_weather_requested, str(row.time)):
			rejected.append({"offset_m": offset, "stand_xz": [stand.x, stand.y], "stage": "weather-time", "reason": "observed state differs from requested"})
			continue
		selected = true
		final_stand = stand
		final_spec = stand_spec
		final_offset = offset
		break
	if not selected:
		_matrix_failures.append("%s: all explicit stand candidates failed; retries and alternate stands are forbidden" % key)
		return
	var surface_state := _capture_surface_record()
	var surface_failure: String = LOCATIONS.capture_surface_failure(final_spec, surface_state,
		_player.global_position.y, _player.floor_max_angle, root.get_camera_3d() == _camera)
	var capture_row := row.duplicate(true)
	capture_row["declared_manifest_position_xz"] = declared_position
	capture_row["position_xz"] = [target.x, target.y]
	var extra := {"debug_travel": true, "player_character": str((_player.get_node("Model") as Node).get("_config_key")),
		"target_position_xz": [target.x, target.y], "selected_stand_xz": [final_stand.x, final_stand.y],
		"coordinate_source_resolution": SOURCE_CATALOGUE,
		"declared_coordinate_matches_current_source": declared_position == [target.x, target.y],
		"selected_stand_offset_m": final_offset, "selected_stand_lateral_m": lateral,
		"terrain_ground_y": terrain_y, "resolved_ground_y": resolved_y,
		"support_state": final_spec, "surface_state": surface_state,
		"surface_failure": surface_failure, "rejected_stand_candidates": rejected,
		"view_heading_xz": [camera_forward.x, camera_forward.y],
		"camera_rig_transform": _transform(_rig.global_transform),
		"camera_rig_spring_length": _rig.spring_length,
		"camera_transform": _transform(_camera.global_transform),
		"camera_player_distance_m": _camera.global_position.distance_to(_player.global_position),
		"observed_clock": clock, "observed_weather": str(_weather.call("weather")),
		"trainer_visible_intent": true,
		"trainer_visibility_limit": "Production spring-arm framing; pixels remain for visual judgment"}
	await _save_image_row(capture_row, extra)


func _capture_support_spec(at: Vector2, terrain_y: float, resolved_y: float) -> Dictionary:
	var result := {"position": Vector3(at.x, resolved_y + TRAINER_CLEARANCE, at.y),
		"ground_y": resolved_y, "terrain_y": terrain_y, "swimming": false}
	var field: Object = _world.get("field")
	if field == null or not field.has_method("water_level") or not _world.has_method("water_depth_at"):
		result["failure"] = "Water surface/depth query unavailable"
		return result
	var swim: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/water_swimming.json"))
	if not swim is Dictionary or not swim.get("human", null) is Dictionary:
		result["failure"] = "production human swim rules unavailable"
		return result
	var sea := float(field.call("water_level"))
	var depth := float(_world.call("water_depth_at", Vector3(at.x, resolved_y, at.y)))
	if not is_finite(sea) or not is_finite(depth):
		result["failure"] = "non-finite Water surface/depth"
		return result
	var rules: Dictionary = swim.human
	result["swimming"] = resolved_y < sea and depth >= float(rules.get("entry_depth_m", 1.2))
	result["water_surface_y"] = sea
	result["water_depth_m"] = depth
	result["swim_body_y"] = sea + float(rules.get("surface_body_offset_m", -0.7))
	if bool(result.swimming):
		result.position.y = float(result.swim_body_y)
	return result


func _capture_support_preflight(spec: Dictionary) -> String:
	if spec.has("failure"):
		return str(spec.failure)
	var at: Vector3 = spec.position
	if not at.is_finite() or not is_finite(float(spec.ground_y)):
		return "non-finite resolved stand"
	var space := _world.get_world_3d().direct_space_state
	if not bool(spec.swimming):
		var ground := Vector3(at.x, float(spec.ground_y), at.z)
		var ray := PhysicsRayQueryParameters3D.create(ground + Vector3.UP * 1.5,
			ground - Vector3.UP, _player.collision_mask, [_player.get_rid()])
		var failure: String = LOCATIONS.capture_floor_failure(float(spec.ground_y), space.intersect_ray(ray), _player.floor_max_angle)
		if not failure.is_empty():
			return failure
	var collision := _player.get_node_or_null(^"Collision") as CollisionShape3D
	if collision == null or collision.shape == null or collision.disabled:
		return "production player capsule unavailable for stand clearance"
	var shape := PhysicsShapeQueryParameters3D.new()
	shape.shape = collision.shape
	shape.transform = Transform3D(_player.global_basis, at) * collision.transform
	shape.collision_mask = _player.collision_mask
	shape.exclude = [_player.get_rid()]
	shape.margin = 0.0
	if not space.intersect_shape(shape, 1).is_empty():
		return "production player capsule overlaps solid geometry at staged stand"
	return ""


func _capture_surface_record() -> Dictionary:
	var controller: Object = _player.get("swim_controller")
	var state: Dictionary = controller.call("snapshot") if controller != null else {}
	var vitals: Object = _player.get("vitals")
	state["dead"] = bool(vitals.call("is_dead")) if vitals != null else false
	state["on_floor"] = _player.is_on_floor()
	state["floor_normal_y"] = _player.get_floor_normal().y if _player.is_on_floor() else 0.0
	return state


func _capture_location_guard(stand: Vector2, row: Dictionary, spec: Dictionary) -> String:
	var failure: String = LOCATIONS.capture_stand_failure(stand, _player.global_position,
		_camera.global_position, CAMERA_MIN_M, _rig.spring_length + 3.0)
	if not failure.is_empty():
		return failure
	return LOCATIONS.capture_surface_failure(spec, _capture_surface_record(), _player.global_position.y,
		_player.floor_max_angle, root.get_camera_3d() == _camera)


func _apply_time_weather(time_name: String, weather_name: String) -> Dictionary:
	if _weather == null or _look == null or not _weather.has_method("set_weather") \
			or not _weather.has_method("weather") or not _look.has_method("apply_time"):
		_matrix_failures.append("production weather/time setter unavailable")
		return {}
	_weather.set_process(true)
	_weather.set_physics_process(true)
	_weather.call("set_weather", weather_name)
	_look.set_process(true)
	_look.set_physics_process(true)
	if _look.has_method("set_clock_frozen"):
		_look.call("set_clock_frozen", false)
	_look.call("apply_time", time_name)
	for _frame in LIGHT_SETTLE_FRAMES:
		await physics_frame
	_weather.set_process(false)
	_weather.set_physics_process(false)
	if _look.has_method("set_clock_frozen"):
		_look.call("set_clock_frozen", true)
	_look.set_process(false)
	_look.set_physics_process(false)
	if not _weather_time_matches(weather_name, time_name):
		_matrix_failures.append("WorldWeather/WorldLook observed state differs: %s/%s" % [
			str(_weather.call("weather")), str(_look.call("time_of_day")) if _look.has_method("time_of_day") else "unknown"])
		return {}
	return {"requested_time": time_name, "observed_time": str(_look.call("time_of_day")) if _look.has_method("time_of_day") else "",
		"requested_weather": weather_name, "observed_weather": str(_weather.call("weather")),
		"world_look_frozen": true, "world_weather_frozen": true}


func _weather_time_matches(weather_name: String, time_name: String) -> bool:
	return _weather != null and _look != null and str(_weather.call("weather")) == weather_name \
		and _look.has_method("time_of_day") and str(_look.call("time_of_day")) == time_name


func _save_image_row(row: Dictionary, extra: Dictionary) -> bool:
	var key := str(row.get("paired_frame_key", ""))
	if key.is_empty() or _matrix_keys.has(key):
		_matrix_failures.append("empty or duplicate paired frame key: %s" % key)
		return false
	var path := _matrix_output.path_join(key + ".png")
	if FileAccess.file_exists(path):
		_matrix_failures.append("freshness guard refused existing output: %s" % path)
		return false
	var image := root.get_viewport().get_texture().get_image()
	if image == null or image.is_empty() or image.get_size() != Vector2i(1920, 1080) \
			or root.size != Vector2i(1920, 1080) or DisplayServer.window_get_size() != Vector2i(1920, 1080):
		_matrix_failures.append("%s: rendered raster/window is not exactly 1920x1080" % key)
		return false
	if image.save_png(path) != OK or not FileAccess.file_exists(path):
		_matrix_failures.append("%s: PNG write failed" % key)
		return false
	var bytes := FileAccess.get_file_as_bytes(path).size()
	if bytes <= 0:
		_matrix_failures.append("%s: PNG is empty after write" % key)
		return false
	var record := row.duplicate(true)
	record["file"] = path
	record["source_commit"] = _source_commit
	record["preset"] = _preset_name
	record["renderer"] = str(_graphics.get("renderer", ""))
	record["resolution"] = [image.get_width(), image.get_height()]
	record["display_server"] = DisplayServer.get_name()
	record["capture_ticks_ms"] = Time.get_ticks_msec()
	record["capture_camera"] = str(_world.get_path_to(_camera)) if _world != null else str(root.get_camera_3d().get_path())
	record["capture_camera_instance_id"] = _camera.get_instance_id() if _camera != null else -1
	record["bytes"] = bytes
	record.merge(extra, true)
	_matrix_records.append(record)
	_matrix_keys[key] = true
	return _write_matrix_manifest(false)


func _write_matrix_manifest(complete: bool) -> bool:
	var captured_fight_moments: Array[String] = []
	for frame: Dictionary in _matrix_records:
		if str(frame.get("group", "")) == "real-fight":
			captured_fight_moments.append(str(frame.get("moment", "")))
	_matrix_manifest.merge({"schema": "tidewake-f39-capture-run-v1",
		"feature": "F39#0/#3", "status": "capture-in-progress" if not complete else "complete",
		"source_commit": _source_commit, "preset": _preset_name,
		"renderer": _graphics.get("renderer", "forward_plus"),
		"resolution": [1920, 1080], "job_manifest": _job_manifest_path,
		"scene": GAME_SCENE, "production_camera_source": "World.CameraRig/Camera3D",
		"fixture_disclosure": "A fresh declared five-member level-53 party and the two Tidewake interior reachability flags are test fixtures; Venn is challenged through his live production prompt and the fight is driven by the installed QUICK pilot plus one party_cycle input. The fight uses a fresh temporary save namespace and its production victory/reward state stays run-local. Location audit uses debug_teleport_to at exact current-source-resolved stands; no product config or feature flags are changed.",
		"planned_frame_keys": _matrix_rows.map(func(row: Dictionary) -> String: return str(row.paired_frame_key)),
		"source_coordinate_discrepancies": _coordinate_discrepancies,
		"planned_frame_count": _matrix_rows.size(), "captured_frame_count": _matrix_records.size(),
		"frames": _matrix_records, "failures": _matrix_failures,
		"actual_fight_moments": captured_fight_moments, "complete": complete,
		"capture_started_utc": _matrix_manifest.get("capture_started_utc", Time.get_datetime_string_from_system(true)),
		"capture_finished_utc": Time.get_datetime_string_from_system(true)}, true)
	var file := FileAccess.open(_matrix_output.path_join("manifest.json"), FileAccess.WRITE)
	if file == null:
		push_error("F39 matrix manifest write failed")
		_manifest_write_failed = true
		return false
	file.store_string(JSON.stringify(_matrix_manifest, "\t") + "\n")
	file.flush()
	if file.get_error() != OK:
		push_error("F39 matrix manifest flush failed")
		_manifest_write_failed = true
	file.close()
	return not _manifest_write_failed


func _finish_matrix() -> void:
	if _matrix_records.size() != 200:
		for row: Dictionary in _matrix_rows:
			var key := str(row.get("paired_frame_key", ""))
			if not _matrix_keys.has(key):
				_matrix_failures.append("not counted; required frame absent: %s" % key)
	var success := _matrix_records.size() == 200 and _matrix_failures.is_empty() and not _manifest_write_failed
	if not _write_matrix_manifest(success):
		success = false
		_write_matrix_manifest(false)
	print("F39 MATRIX %s %s: %d/%d frames, %d failures, %s" % [
		_preset_name, "PASS" if success else "INCOMPLETE", _matrix_records.size(),
		_matrix_rows.size(), _matrix_failures.size(), _matrix_output])
	quit(0 if success else 1)


func _hide_hud() -> void:
	for node: Node in _world.find_children("*", "CanvasLayer", true, false):
		(node as CanvasLayer).visible = false


func _slug(value: String) -> String:
	var out := ""
	var prior_separator := true
	for index in value.length():
		var code := value.unicode_at(index)
		if code == 39:
			continue
		var valid := (code >= 48 and code <= 57) or (code >= 65 and code <= 90) or (code >= 97 and code <= 122)
		if valid:
			out += char(code).to_lower()
			prior_separator = false
		elif not prior_separator:
			out += "_"
			prior_separator = true
	return out.trim_suffix("_") if not out.is_empty() else "unnamed"


func _vec3(value: Vector3) -> Array[float]:
	return [value.x, value.y, value.z]


func _node_position(value: Variant) -> Array[float]:
	var node := value as Node3D
	return _vec3(node.global_position) if is_instance_valid(node) else []


func _transform(value: Transform3D) -> Dictionary:
	return {"origin": _vec3(value.origin), "basis_x": _vec3(value.basis.x),
		"basis_y": _vec3(value.basis.y), "basis_z": _vec3(value.basis.z)}
