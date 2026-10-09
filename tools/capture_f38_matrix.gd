extends "res://tools/phase2_capture_locations.gd"

## Queue-only visual fixture; debug travel/time/weather, never earned evidence.
## Reuses production-camera grounding, obstruction rejection and manifests.
## Run on the SAME integrated SHA with --f38-baseline / --f38-candidate.
const F38_PLAN := "res://ralph/reports/R2-F38/capture-definition.json"
const GRAPHICS := preload("res://scripts/ui/graphics_prefs.gd")
var _f38_weather := "clear"
var _f38_preset := "High"
var _f38_source := ""
var _f38_views_supplied := false
var _f38_exterior_mode := ""
var _f38_tuft_patch_mode := ""
var _f38_requested_views: Array[String] = []


func _run() -> void:
	# F38's preset argument does not enter the generic --preset bootstrap.
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--f38-preset="):
			_f38_preset = arg.trim_prefix("--f38-preset=")
	if _f38_preset in ["Medium", "High"]:
		_required_capture_raster = Vector2i(1920, 1080)
		root.size = _required_capture_raster
	await process_frame
	if _required_capture_raster != Vector2i.ZERO and root.size != _required_capture_raster:
		push_error("F38 viewport did not accept the required 1920x1080 raster")
		quit(1)
		return
	await super._run()


func _parse_args() -> bool:
	_biome_id = "meadows"
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--f38-views="):
			_f38_views_supplied = true
			for view: String in arg.trim_prefix("--f38-views=").split(",", false):
				if view not in ["approach", "gameplay", "reverse", "close"]:
					push_error("F38 views must name an existing authored matrix view")
					return false
				_f38_requested_views.append(view)
			if _f38_requested_views.is_empty():
				return false
		elif arg.begins_with("--f38-tuft-patches="):
			_f38_tuft_patch_mode = arg.trim_prefix("--f38-tuft-patches=")
			if _f38_tuft_patch_mode not in ["baseline", "candidate"]:
				push_error("F38 tuft comparison requires baseline or candidate")
				return false
		elif arg.begins_with("--f38-exterior="):
			_f38_exterior_mode = arg.trim_prefix("--f38-exterior=")
			if _f38_exterior_mode not in ["baseline", "candidate"]:
				push_error("F38 exterior comparison requires baseline or candidate")
				return false
		elif arg.begins_with("--f38-preset="):
			_f38_preset = arg.trim_prefix("--f38-preset=")
		elif arg.begins_with("--source-commit="):
			_f38_source = arg.trim_prefix("--source-commit=")
			if _f38_source.is_empty():
				push_error("F38 source commit cannot be empty when supplied")
				return false
		elif arg.begins_with("--views="):
			_f38_views_supplied = true
	if not _f38_source.is_empty():
		var source_pattern := RegEx.new()
		source_pattern.compile("^[0-9a-f]{40}$")
		if source_pattern.search(_f38_source) == null:
			push_error("F38 source commit must be an exact SHA when supplied")
			return false
	if not ["Low", "Medium", "High"].has(_f38_preset):
		push_error("F38 preset must be Low, Medium or High")
		return false
	if not super._parse_args():
		return false
	# The inherited generic survey admits approach/close only. Select existing
	# F38 reverse/gameplay rows here without weakening its argument validation.
	if not _f38_requested_views.is_empty():
		_views.assign(_f38_requested_views)
	if not _f38_exterior_mode.is_empty():
		var grass: Dictionary = preload("res://scripts/world/grass_field.gd").config()
		var verge: Dictionary = grass.get("road_verge", {})
		verge["enabled"] = _f38_exterior_mode == "candidate"
		grass["road_verge"] = verge
	if not _f38_tuft_patch_mode.is_empty():
		var grass: Dictionary = preload("res://scripts/world/grass_field.gd").config()
		var patch: Dictionary = grass.get("tuft_patches", {})
		patch["enabled"] = _f38_tuft_patch_mode == "candidate"
		grass["tuft_patches"] = patch
	# Process-local fixture override, never persist the owner's device setting.
	# Explicit renderer at launch must match this preset before world boot.
	GRAPHICS.load_preferences()
	GRAPHICS._base = _f38_preset
	GRAPHICS._choice = _f38_preset
	GRAPHICS._custom = {}
	if GRAPHICS.restart_required():
		push_error("F38 launch renderer does not match requested preset")
		return false
	return true


func _prepare_capture_shell() -> bool:
	if not super._prepare_capture_shell():
		return false
	if not _f38_exterior_mode.is_empty():
		var beacon := _world.get_node_or_null("ObjectiveBeacon")
		if beacon == null:
			_failures.append("F38 production objective beacon unavailable")
			return false
		var config: Dictionary = beacon.get("_config")
		var nearby: Dictionary = config.get("nearby_occlusion", {})
		nearby["enabled"] = _f38_exterior_mode == "candidate"
		config["nearby_occlusion"] = nearby
	return true


func _load_plan() -> bool:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(F38_PLAN))
	if not parsed is Dictionary:
		return false
	var index := 0
	for site: Dictionary in parsed.sites:
		index += 1
		if not _matches_subset(str(site.id).to_lower()):
			continue
		for time_name: String in _times:
			for weather_name: String in parsed.weather:
				for view: Dictionary in parsed.views:
					var selector := "close" if str(view.id) == "detail" else str(view.id)
					if _f38_views_supplied and selector not in _views:
						continue
					var heading := float(site.heading_deg) + float(view.heading_offset_deg)
					_planned.append({
						"frame_id": "%s__%s__%s__%s" % [site.id, time_name, weather_name, view.id],
						"identity": site.id, "biome_id": "meadows", "biome_display_name": "Meadows",
						"band_id": site.region, "band_display_name": site.region,
						"destination_index": index, "spot_index_in_band": index,
						"destination_display_name": site.id, "position_xz": site.at,
						"view_heading_deg": heading, "time": time_name, "view": view.id,
						"weather": weather_name, "stand_offsets_m": [float(view.offset_m)],
						"stand_laterals_m": [0.0], "preset": _f38_preset,
						"arrival_on_process_frame": true,
					})
	return not _planned.is_empty()


func _begin_manifest() -> void:
	super._begin_manifest()
	_manifest["f38_definition"] = F38_PLAN
	_manifest["source_commit"] = _f38_source
	var presentation: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/meadows_catalog_presentation.json"))
	_manifest["shipping_presentation_enabled"] = bool(presentation.get("enabled", false)) if presentation is Dictionary else false
	_manifest["preset"] = GRAPHICS.selected()
	_manifest["f38_arrival_clock"] = "20 process_frame ticks; other capture defaults remain20 physics_frame"
	_manifest["f38_explicit_view_filter"] = _views.duplicate() if _f38_views_supplied else []
	_manifest["renderer"] = RenderingServer.get_current_rendering_method()
	_manifest["candidate"] = OS.get_cmdline_user_args().has("--f38-candidate")
	_manifest["fixture_limit"] = "Debug travel with strict fixed stands; real fight and earned F17 walk are separate required proofs. Rejected stands are missing evidence."
	_manifest["f38_exterior_fixture"] = _f38_exterior_mode
	_manifest["f38_tuft_patch_fixture"] = _f38_tuft_patch_mode
	_manifest["f38_exterior_scope"] = "Explicit process-local road-verge/nearby-beacon comparison. Tracked gates stay OFF. Original stands, camera, footing, time/weather and image guards retained. Changed exterior rows are missing cluster pieces, not full F38 or performance acceptance."


func _capture_row(row: Dictionary) -> void:
	var house := _world.get_node_or_null("GrandpaHouse")
	if house == null:
		_failures.append("F38 authored farmhouse unavailable")
		_write_manifest()
		return
	var requested: Dictionary = house.get("_floor_presentation")
	var furniture_surfaces := 0
	for node: Node in house.find_children("*", "Node3D", true, false):
		furniture_surfaces += int(node.get_meta("farmhouse_furniture_dielectric_surfaces", 0))
	_manifest["f38_furniture_dielectric_surfaces"] = furniture_surfaces
	var house_recipe: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/building_prefabs.json"))["prefabs"]["farmhouse_shell"]
	var lighting: Dictionary = house_recipe.get("interior_lighting", {})
	var window_candidate := bool(lighting.get("window_glow_candidate_enabled", false)) or OS.get_cmdline_user_args().has("--farmhouse-window-glow-candidate")
	var expected_window_energy := float(lighting.get("window_glow_candidate_energy", 0.20)) if window_candidate else float(house_recipe["retint"]["MI_WindowGlass"]["energy"])
	var expected_window_alpha := float(lighting.get("window_glow_candidate_alpha", 0.09545451402664185)) if window_candidate else Color(str(house_recipe["retint"]["MI_WindowGlass"]["color"])).a
	var window_energies: Array[float] = []
	var window_alphas: Array[float] = []
	var window_transparency: Array[int] = []
	var shell := house.get_node_or_null("KitShell")
	if shell != null:
		for node: Node in shell.find_children("*", "MeshInstance3D", true, false):
			var mesh := node as MeshInstance3D
			if mesh.mesh == null:
				continue
			for surface: int in mesh.mesh.get_surface_count():
				var material := mesh.get_active_material(surface) as BaseMaterial3D
				if material != null and material.resource_name == "MI_WindowGlass":
					window_energies.append(material.emission_energy_multiplier)
					window_alphas.append(material.albedo_color.a)
					window_transparency.append(material.transparency)
	_manifest["f38_window_glow"] = {"candidate": window_candidate, "expected_energy": expected_window_energy, "actual_energies": window_energies, "expected_alpha": expected_window_alpha, "actual_alphas": window_alphas, "transparency_modes": window_transparency}
	# Godot4.7 imports the authored glTF alphaModeBLEND as depth-prepass
	# alpha. Keep this strict guard bound to that canonical imported mode.
	if window_energies.is_empty() or window_energies.any(func(value: float) -> bool: return not is_equal_approx(value, expected_window_energy)) \
		or window_alphas.any(func(value: float) -> bool: return not is_equal_approx(value, expected_window_alpha)) \
		or window_transparency.any(func(value: int) -> bool: return value != BaseMaterial3D.TRANSPARENCY_ALPHA_DEPTH_PRE_PASS):
		_failures.append("F38 actual farmhouse window emission/alpha/transparency differs from authored setting")
		_write_manifest()
		return
	var tiled_bindings := 0
	var seam_bindings := 0
	for node: Node in house.find_children("*", "MeshInstance3D", true, false):
		var mesh := node as MeshInstance3D
		if mesh.mesh == null:
			continue
		for surface: int in mesh.mesh.get_surface_count():
			var material := mesh.get_active_material(surface)
			if material is StandardMaterial3D and bool(material.get_meta("floor_band_tiled", false)):
				tiled_bindings += 1
				if bool(material.get_meta("floor_board_seams", false)) and material.detail_enabled \
						and material.detail_albedo != null and material.detail_normal == material.normal_texture:
					seam_bindings += 1
	var tiled := tiled_bindings > 0
	_manifest["f38_floor_band_tiled"] = tiled
	_manifest["f38_floor_band_tiled_bindings"] = tiled_bindings
	_manifest["f38_floor_board_seam_bindings"] = seam_bindings
	if tiled != bool(requested.get("tile_cropped_band", false)):
		_failures.append("F38 actual farmhouse floor tiling differs from authored setting")
		_write_manifest()
		return
	if bool(requested.get("board_seams_enabled", false)) and (seam_bindings == 0 or seam_bindings != tiled_bindings):
		_failures.append("F38 actual farmhouse board detail differs from authored setting")
		_write_manifest()
		return
	_f38_weather = str(row.weather)
	var started := Time.get_ticks_msec()
	await super._capture_row(row)
	if not _records.is_empty() and _records.back().get("frame_id") == row.frame_id:
		if not _f38_exterior_mode.is_empty():
			var field := _world.get_node_or_null("GrassField")
			var material := field.get("_material") as ShaderMaterial if field != null else null
			var beacon := _world.get_node_or_null("ObjectiveBeacon") as Node3D
			var beam := beacon.get("_beam_material") as StandardMaterial3D if beacon != null else null
			var enabled := _f38_exterior_mode == "candidate"
			var grass_actual := {}
			if material != null:
				for key: String in ["road_verge_enabled", "road_verge_base_mask", "road_verge_strength", "road_verge_height_floor"]:
					grass_actual[key] = material.get_shader_parameter(key)
			var grass_cfg: Dictionary = preload("res://scripts/world/grass_field.gd").config().get("road_verge", {})
			var path_mask: int = preload("res://scripts/world/grass_field.gd").texture_mask(field.call("_terrain_texture_names"), ["path"]) if field != null else 0
			var distance_m := _camera.global_position.distance_to(beacon.global_position) if beacon != null else INF
			var beacon_cfg: Dictionary = beacon.get("_config") if beacon != null else {}
			var expected_depth: bool = preload("res://scripts/world/objective_beacon.gd").nearby_beam_depth_test(distance_m, beacon_cfg)
			var matched: bool = material != null and material.shader != null and material.shader.resource_path == "res://shaders/grass_field.gdshader" \
				and grass_actual.get("road_verge_enabled") == enabled and path_mask > 0 \
				and int(grass_actual.get("road_verge_base_mask", 0)) == path_mask \
				and is_equal_approx(float(grass_actual.get("road_verge_strength", -1.0)), float(grass_cfg.get("strength", 0.75))) \
				and is_equal_approx(float(grass_actual.get("road_verge_height_floor", -1.0)), float(grass_cfg.get("height_floor", 0.35))) \
				and beam != null and beacon_cfg.get("nearby_occlusion", {}).get("enabled") == enabled \
				and beam.no_depth_test == (not expected_depth)
			var beacon_id := str(beacon.call("active_objective_id")) if beacon != null else ""
			var beacon_visible: bool = beacon.call("beam_visible") == true if beacon != null else false
			if row.get("identity") == "farm_to_hall" and row.get("view") == "reverse" \
				and (beacon_id.is_empty() or not beacon_visible or distance_m > 40.0):
				matched = false
				_failures.append("%s: nearby facade-obstruction witness is absent; no substituted stand" % str(row.frame_id))
			var record: Dictionary = _records.back()
			record["exterior_observation"] = {"mode": _f38_exterior_mode, "grass_uniforms": grass_actual,
				"path_mask": path_mask, "beacon_id": beacon_id,
				"beacon_visible": beacon_visible,
				"camera_beacon_distance_m": distance_m if is_finite(distance_m) else -1.0,
				"expected_depth_test": expected_depth, "actual_no_depth_test": beam.no_depth_test if beam != null else null,
				"matches_requested": matched}
			if not matched:
				_failures.append("%s: actual exterior candidate state mismatch" % str(row.frame_id))
		if not _f38_tuft_patch_mode.is_empty():
			var field := _world.get_node_or_null("GrassField")
			var cfg: Dictionary = preload("res://scripts/world/grass_field.gd").config()
			var patch: Dictionary = cfg.get("tuft_patches", {})
			var enabled := _f38_tuft_patch_mode == "candidate"
			var observations := []
			var matched: bool = patch.get("enabled") == enabled
			for far: bool in [false, true]:
				var material := field.get("_far_material" if far else "_material") as ShaderMaterial if field != null else null
				var actual := {}
				var expected := {
					"drift_contrast" if far else "clump_contrast": 1.0 if enabled else float(cfg.clump_contrast),
					"drift_patch_start" if far else "clump_patch_start": float(patch.start) if enabled else 0.0,
					"drift_patch_full" if far else "clump_patch_full": float(patch.full) if enabled else 0.0,
				}
				var path := "res://shaders/far_cover.gdshader" if far else "res://shaders/grass_field.gdshader"
				matched = matched and material != null and material.shader != null and material.shader.resource_path == path
				for key: String in expected:
					actual[key] = material.get_shader_parameter(key) if material != null else null
					matched = matched and actual[key] != null and is_equal_approx(float(actual[key]), float(expected[key]))
				observations.append({"far": far, "shader": material.shader.resource_path if material != null and material.shader != null else "", "actual": actual, "expected": expected})
			_records.back()["tuft_patch_observation"] = {"mode": _f38_tuft_patch_mode, "materials": observations, "matches_requested": matched}
			if not matched:
				_failures.append("%s: actual near/far tuft-patch state mismatch" % str(row.frame_id))
		_records.back()["capture_wall_ms"] = Time.get_ticks_msec() - started
		_records.back()["process_cpu_ms"] = Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0
		_records.back()["physics_cpu_ms"] = Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0
		_records.back()["timing_limit"] = "CPU monitor sample and capture wall time; neither is GPU frame-time or Ally performance acceptance."
		_write_manifest()


func _pin_time(time_name: String) -> Dictionary:
	var observed := await super._pin_time(time_name)
	if observed.is_empty():
		return observed
	if _weather == null or not _weather.has_method("set_weather"):
		_failures.append("F38 production weather unavailable")
		return {}
	_weather.set_process(true)
	_weather.set_physics_process(true)
	var weather_rng: Variant = _weather.get("_rng")
	if weather_rng is RandomNumberGenerator:
		weather_rng.seed = _seed
	_weather.call("set_weather", _f38_weather)
	for frame: int in 90:
		await physics_frame
	_weather.set_process(false)
	_weather.set_physics_process(false)
	observed["requested_weather"] = _f38_weather
	if not _weather.has_method("weather") or str(_weather.call("weather")) != _f38_weather:
		_failures.append("F38 requested weather did not bind")
		return {}
	observed["actual_weather"] = str(_weather.call("weather"))
	return observed
