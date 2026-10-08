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
var _shipping := false
var _weather_name := "clear"
var _candidate_applied := false
var _candidate_verified := false
var _shore_motion_requested := false
var _shore_motion_saved := false
var _seed := 2042
var _save_fixture := ""
var _explicit_stands := false


func _run() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg == "--f39-candidate":
			_candidate = true
		elif arg == "--f39-shipping":
			_shipping = true
		elif arg == "--shore-motion":
			_shore_motion_requested = true
		elif arg.begins_with("--f39-weather="):
			_weather_name = arg.trim_prefix("--f39-weather=")
		elif arg.begins_with("--seed="):
			var raw := arg.trim_prefix("--seed=")
			if not raw.is_valid_int():
				push_error("F39 seed must be an integer")
				quit(2)
				return
			_seed = int(raw)
	if _shipping and _candidate:
		push_error("F39 shipping capture cannot also request candidate overrides")
		quit(2)
		return
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
	# Reuse the explicit stand format from capture_f26_low_stands for bounded
	# hero-distance views. Production travel/floor/camera/material guards below
	# still apply; a refused stand never falls back to a nearby successful one.
	var stands: Array[Dictionary] = []
	for arg: String in OS.get_cmdline_user_args():
		if not arg.begins_with("--cand="):
			continue
		var parts := arg.trim_prefix("--cand=").split(",")
		if parts.size() != 3:
			push_error("F39 stand requires x,z,heading_deg")
			return false
		for part: String in parts:
			if not part.is_valid_float() or not is_finite(float(part)):
				push_error("F39 stand coordinates/heading must be finite")
				return false
		for time_name: String in _times:
			stands.append({"frame_id": "water__stand_%02d__%s" % [stands.size(), time_name],
				"biome_id": "water", "destination_index": 0,
				"position_xz": [float(parts[0]), float(parts[1])],
				"view_heading_deg": float(parts[2]), "time": time_name,
				"f39_heading_offset_deg": 0.0,
				"explicit_visual_stand": true})
	if not stands.is_empty():
		_explicit_stands = true
		_planned = stands
		return true
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


func _prepare_capture_shell() -> bool:
	if not super._prepare_capture_shell():
		return false
	# Tidewake currently mounts WorldLook without a WorldWeather service.
	# Its empty production delta is clear weather, not a simulated rain state.
	# Reject unsupported weather before spending a settle interval per pose.
	if _weather == null:
		var delta: Variant = _look.get("_weather")
		if _weather_name != "clear" or not (delta is Dictionary) or not delta.is_empty():
			_failures.append("F39 requested weather unavailable: production WorldLook has no matching clear delta/WorldWeather service")
			return false
		_manifest["f39_weather_source"] = "production WorldLook empty weather delta; no WorldWeather service"
	elif not _weather.has_method("set_weather") or not _weather.has_method("weather"):
		_failures.append("F39 production weather service API unavailable")
		return false
	else:
		var order: Variant = _weather.get("_order")
		if _weather.get_meta(&"tidewake_presentation_only", false) != true \
				or _weather.is_in_group("weather") or not (order is Array) or not order.is_empty():
			_failures.append("F39 weather must be non-cycling presentation only, outside canonical weather queries")
			return false
		_manifest["f39_weather_source"] = str(_weather.get_path())
		_manifest["f39_weather_scope"] = "Presentation fixture only; no canonical weather group, automatic episode, durable state or co-op weather proof"
	return true


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
		var flow_settings: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(FLOW.VISUAL_CONFIG))
		# Recapture shipping materials as mounted. Preserve the original local
		# before/after comparison modes for their retained paired proofs.
		if not _shipping:
			fall_settings["enabled"] = _candidate
			flow_settings["enabled"] = _candidate
			flow_settings["ridges_enabled"] = _candidate
		var observations: Array[Dictionary] = []
		var falls_count := 0
		var flow_count := 0
		for found: Node in _world.find_children("*", "MeshInstance3D", true, false):
			if found.name == "VeilfallFallColumns":
				if not _shipping:
					FALLS.apply_visual_settings((found as MeshInstance3D).material_override as ShaderMaterial, fall_settings)
				falls_count += 1
				observations.append(_observe_material(found as MeshInstance3D,
					["visual_far_core_enabled"], FALLS.VISUAL_UNIFORMS, fall_settings))
			elif found.get_script() == FLOW:
				if not _shipping:
					found.call("apply_visual_settings", flow_settings)
				flow_count += 1
				observations.append(_observe_material(found as MeshInstance3D,
					["visual_groups_enabled", "visual_ridges_enabled"], FLOW.VISUAL_UNIFORMS, flow_settings))
		_manifest["f39_material_observations"] = observations
		_manifest["f39_matched_falls_nodes"] = falls_count
		_manifest["f39_matched_flow_nodes"] = flow_count
		var surface := _world.get_node_or_null("WaterSurface") as MeshInstance3D
		var shore_settings: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/water_offshore_visual.json"))
		var shore_enabled := bool(shore_settings.get("enabled", false)) and bool(shore_settings.get("shore_foam_enabled", false))
		_manifest["f39_shipping_shore_foam_enabled"] = shore_enabled
		if surface == null:
			_failures.append("F39 production WaterSurface material was not found")
		else:
			var shore_uniforms := ["shore_foam_breakup_m", "shore_foam_breakup_scale", "shore_foam_strength", "shore_foam_patch_start", "shore_foam_patch_full"]
			var expected := {"enabled": shore_enabled, "shader": {}}
			for key: String in shore_uniforms:
				expected.shader[key] = shore_settings.get(key)
			var shore_observed := _observe_material(surface, [], shore_uniforms, expected)
			var surface_material := surface.material_override as ShaderMaterial
			var installed := surface_material != null and surface_material.shader != null \
				and surface_material.shader.code.contains("vec2 shore_foam_uv =") \
				and surface_material.shader.code.contains("float shore_patch = smoothstep(shore_foam_patch_start, shore_foam_patch_full,") \
				and surface_material.shader.code.contains("foam *= shore_foam_strength * shore_patch;")
			shore_observed.gates["shore_foam_installed"] = installed
			if installed != shore_enabled:
				shore_observed.matches_requested = false
				_failures.append("F39 installed shore foam gate differs from shipping config")
			observations.append(shore_observed)
		if falls_count == 0 or flow_count == 0:
			_failures.append("F39 production falls/current materials were not both found")
		_candidate_verified = not observations.is_empty()
		for observed: Dictionary in observations:
			_candidate_verified = _candidate_verified and bool(observed.get("matches_requested", false))
		_candidate_verified = _candidate_verified and falls_count > 0 and flow_count > 0 and surface != null
		_manifest["f39_material_override_verified"] = _candidate_verified
	if not _candidate_verified:
		_write_manifest()
		return
	await super._capture_row(row)
	if _shore_motion_requested and not _shore_motion_saved and _failures.is_empty() \
			and str(row.time) == "night" and not _records.is_empty() and _records.back().frame_id == row.frame_id:
		_shore_motion_saved = true
		await _capture_shore_motion(row)


func _finish(complete: bool) -> void:
	if _shore_motion_requested and not _shore_motion_saved:
		_failures.append("F39 requested shore motion requires a successfully captured night stand")
	super._finish(complete)


func _capture_shore_motion(row: Dictionary) -> void:
	# Reuse the first supported night stand; shader TIME stays live. No pose,
	# camera, input, weather, animation or movement-processing override.
	var began := Time.get_ticks_msec()
	var next_sample := began
	var body_at := _player.global_position
	var camera_at := _camera.global_transform
	var samples: Array[Dictionary] = []
	while Time.get_ticks_msec() - began < 12000:
		await process_frame
		if Time.get_ticks_msec() < next_sample:
			continue
		await RenderingServer.frame_post_draw
		var captured := Time.get_ticks_msec()
		if not _player.is_on_floor() or _player.global_position.distance_to(body_at) > .02 \
				or _camera.global_position.distance_to(camera_at.origin) > .02 \
				or _camera.global_basis.get_rotation_quaternion().angle_to(camera_at.basis.get_rotation_quaternion()) > .001:
			_failures.append("F39 shore motion lost its supported ordinary body/camera pose")
			break
		var pixels := root.get_texture().get_image()
		var path := "%s/%s-motion-%03d.jpg" % [_output_dir, str(row.frame_id), samples.size()]
		if pixels == null or pixels.is_empty() or pixels.get_size() != root.size or pixels.save_jpg(path, .95) != OK:
			_failures.append("F39 shore motion native frame is missing, wrong-sized or unsaved")
			break
		samples.append({"file": path, "elapsed_ms": captured, "body": _vec3(_player.global_position),
			"camera": _vec3(_camera.global_position), "on_floor": _player.is_on_floor()})
		next_sample = captured + 200
	if samples.size() < 3 or int(samples[-1].elapsed_ms) - int(samples[0].elapsed_ms) < 10000:
		_failures.append("F39 shore motion requires at least three actual samples spanning ten seconds")
	_manifest["f39_shore_motion"] = {"frame_id": row.frame_id, "samples": samples,
		"resolution": [root.size.x, root.size.y], "encoding": "native JPEG95; actual variable sample timestamps; no interpolation",
		"scope": "Stationary supported production-camera view with live shader TIME only; no movement/earned/fight/frame-time claim"}
	_write_manifest()


func _observe_material(node: MeshInstance3D, gates: Array, uniforms: Array,
		settings: Dictionary) -> Dictionary:
	var observed := {"node": str(node.get_path()), "gates": {}, "uniforms": {}, "matches_requested": true}
	var material := node.material_override as ShaderMaterial
	if material == null or material.shader == null:
		observed.matches_requested = false
	else:
		for key: String in gates:
			var actual: Variant = material.get_shader_parameter(key)
			observed.gates[key] = actual
			var enabled := bool(settings.get("enabled", false))
			var expected := enabled and bool(settings.get("ridges_enabled", false)) if key == "visual_ridges_enabled" else enabled
			if actual != expected:
				observed.matches_requested = false
		for key: String in uniforms:
			var actual: Variant = material.get_shader_parameter(key)
			observed.uniforms[key] = actual
			if bool(settings.get("enabled", false)) and settings.get("shader", {}).has(key):
				if actual == null or not is_equal_approx(float(actual), float(settings.shader[key])):
					observed.matches_requested = false
	if not bool(observed.matches_requested):
		_failures.append("F39 visual material override did not match request: %s" % str(node.get_path()))
	return observed


func _pin_time(time_name: String) -> Dictionary:
	var observed: Dictionary = await super._pin_time(time_name)
	if observed.is_empty():
		return {}
	if _weather == null:
		var delta: Variant = _look.get("_weather")
		if _weather_name != "clear" or not (delta is Dictionary) or not delta.is_empty():
			_failures.append("F39 production clear weather delta changed before capture")
			return {}
		observed["f39_weather"] = "clear"
		observed["f39_weather_source"] = str(_manifest.get("f39_weather_source", ""))
		return observed
	var order: Variant = _weather.get("_order")
	if _weather.get_meta(&"tidewake_presentation_only", false) != true \
			or _weather.is_in_group("weather") or not (order is Array) or not order.is_empty():
		_failures.append("F39 presentation weather entered canonical queries or enabled cycling before capture")
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
	_manifest["f39_shipping"] = _shipping
	_manifest["f39_material_mode"] = "Observe production materials; no visual override" if _shipping else "Process-local candidate/baseline comparison override"
	_manifest["f39_seed"] = _seed
	_manifest["f39_weather"] = _weather_name
	_manifest["f39_heading_offsets_deg"] = [0.0] if _explicit_stands else HEADINGS
	_manifest["f39_explicit_stands"] = _explicit_stands
	_manifest["f39_isolated_save_fixture"] = _save_fixture
	_manifest["f39_limitations"] = "Teleported stands and camera headings; no earned route, close detail, actual fight, device or judge proof. Shipping observation or process-local candidate/baseline override as declared above; no production config gates are changed."
