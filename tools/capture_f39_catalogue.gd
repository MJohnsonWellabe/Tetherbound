extends "res://tools/capture_lookdev_catalogue.gd"

## F39 queued native recapture. Reuses the production survey's floor checks,
## camera, fresh-output protection and F26 renderer/preset preflight. Five
## distinct camera headings at every authored destination, day/night, provide
## >=200 frames. These are disclosed teleported visual fixtures, not a walk,
## close-detail proof, fight, rescoring verdict or device performance proof.
const FALLS := preload("res://scripts/world/water_veilfall_falls.gd")
const FLOW := preload("res://scripts/world/water_current_flow_view.gd")
const SPAWN_TABLES := preload("res://scripts/combat/spawn_tables.gd")
const SAVE := preload("res://scripts/save/save_game.gd")
const HEADINGS := [0.0, -45.0, 45.0, 90.0, 180.0]
var _candidate := false
var _weather_name := "clear"
var _candidate_applied := false
var _seed := 2042
var _save_fixture := ""


func _run() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg == "--f39-candidate":
			_candidate = true
		elif arg.begins_with("--f39-weather="):
			_weather_name = arg.trim_prefix("--f39-weather=")
		elif arg.begins_with("--seed="):
			var raw := arg.trim_prefix("--seed=")
			if not raw.is_valid_int():
				push_error("F39 seed must be an integer")
				quit(2)
				return
			_seed = int(raw)
	if _weather_name not in ["clear", "rain"]:
		push_error("F39 weather must be clear or rain")
		quit(2)
		return
	# Process-local override pins the production encounter generator as well as
	# the global RNG. No shared config, player save or world's seed is written.
	OS.set_environment(SPAWN_TABLES.SEED_ENV_VAR, str(_seed))
	seed(_seed)
	await super._run()


func _load_plan() -> bool:
	if not super._load_plan():
		return false
	if _biome_id != "water":
		push_error("F39 capture only owns water")
		return false
	var expanded: Array[Dictionary] = []
	for row: Dictionary in _planned:
		for heading: float in HEADINGS:
			var view := row.duplicate(true)
			view["f39_heading_offset_deg"] = heading
			view["frame_id"] = "%s__heading_%s" % [str(row.frame_id), str(heading).replace("-", "minus")]
			expanded.append(view)
	_planned = expanded
	return true


func _capture_forward(row: Dictionary) -> Vector2:
	return super._capture_forward(row).rotated(deg_to_rad(float(row.get("f39_heading_offset_deg", 0.0))))


func _mount_production_world() -> bool:
	var game := root.get_node_or_null(^"Game")
	if game == null:
		_failures.append("F39 Game service unavailable")
		return false
	_save_fixture = "user://f39_capture_%s_%s/" % [str(Time.get_unix_time_from_system()).replace(".", "_"), OS.get_process_id()]
	game.set("save_system", SAVE.new(_save_fixture))
	_manifest["f39_isolated_save_fixture"] = _save_fixture
	return await super._mount_production_world()


func _capture_row(row: Dictionary) -> void:
	if not _candidate_applied:
		_candidate_applied = true
		var fall_settings: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(FALLS.VISUAL_CONFIG))
		fall_settings["enabled"] = _candidate
		var flow_settings: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(FLOW.VISUAL_CONFIG))
		flow_settings["enabled"] = _candidate
		flow_settings["ridges_enabled"] = _candidate
		for found: Node in _world.find_children("*", "MeshInstance3D", true, false):
			if found.name == "VeilfallFallColumns":
				FALLS.apply_visual_settings((found as MeshInstance3D).material_override as ShaderMaterial, fall_settings)
			elif found.get_script() == FLOW:
				found.call("apply_visual_settings", flow_settings)
	await super._capture_row(row)


func _pin_time(time_name: String) -> Dictionary:
	var observed: Dictionary = await super._pin_time(time_name)
	if _weather == null or not _weather.has_method("set_weather"):
		_failures.append("F39 production weather service unavailable")
		return {}
	_weather.call("set_weather", _weather_name)
	for _frame in LIGHT_SETTLE_FRAMES:
		await physics_frame
	observed["f39_weather"] = _weather_name
	if not _weather.has_method("weather") or str(_weather.call("weather")) != _weather_name:
		_failures.append("F39 requested weather was not applied")
		return {}
	return observed


func _begin_manifest() -> void:
	super._begin_manifest()
	_manifest["f39_candidate"] = _candidate
	_manifest["f39_seed"] = _seed
	_manifest["f39_weather"] = _weather_name
	_manifest["f39_heading_offsets_deg"] = HEADINGS
	_manifest["f39_isolated_save_fixture"] = _save_fixture
	_manifest["f39_limitations"] = "Teleported stands and camera headings; no earned route, close detail, actual fight, device or judge proof. Candidate overrides are process-local material uniforms; production gates remain false."
