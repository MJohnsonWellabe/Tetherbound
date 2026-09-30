extends RefCounted

## F26 prototype. Device-local presentation only; never a character/world
## mutation, RPC or combat input. project.godot points its preboot override at
## OVERRIDE_PATH. Compatibility remains the authored default (RD-25).
const CONFIG_PATH := "res://data/config/art.json"
const OVERRIDE_PATH := "user://graphics_override.cfg"
const PRESETS: Array[String] = ["Low", "Medium", "High"]
const FEATURES: Array[String] = ["volumetric_fog", "ssao", "ssil", "glow"]

static var _loaded := false
static var _config: Dictionary = {}
static var _choice := "Low"
static var _base := "Low"
static var _custom: Dictionary = {}
static var _overlay := false
static var _applied_shadow_profile := ""


static func load_preferences() -> void:
	if _loaded:
		return
	_loaded = true
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(CONFIG_PATH))
	if parsed is Dictionary and parsed.get("graphics_presets") is Dictionary:
		_config = parsed["graphics_presets"].duplicate(true)
	var stored := ConfigFile.new()
	if stored.load(OVERRIDE_PATH) != OK or not _usable_document(stored):
		# A refused promotion/rollback retains the previous generation. Startup
		# conservatively chose Low if the canonical file was absent; retaining
		# the device choice here allows an explicit restart after recovery.
		if stored.load(OVERRIDE_PATH + ".previous") != OK or not _usable_document(stored):
			return
	var selected := str(stored.get_value("tetherbound_graphics", "preset", "Low"))
	var base := str(stored.get_value("tetherbound_graphics", "base", "Low"))
	if not PRESETS.has(base) or not (PRESETS.has(selected) or selected == "Custom"):
		return
	_base = base
	_choice = selected
	var overrides: Variant = stored.get_value("tetherbound_graphics", "custom", {})
	_custom = overrides.duplicate(true) if overrides is Dictionary else {}
	_overlay = bool(stored.get_value("tetherbound_graphics", "overlay", false))


static func selected() -> String:
	load_preferences()
	return _choice


static func forward_plus() -> bool:
	return RenderingServer.get_current_rendering_method() == "forward_plus"


static func requested_renderer() -> String:
	load_preferences()
	return "gl_compatibility" if _base == "Low" else "forward_plus"


static func restart_required() -> bool:
	return requested_renderer() != RenderingServer.get_current_rendering_method()


static func values() -> Dictionary:
	load_preferences()
	var authored: Variant = _config.get(_base, {})
	var out: Dictionary = authored.duplicate(true) if authored is Dictionary else {}
	if _choice == "Custom":
		for key: String in FEATURES:
			if _custom.get(key) is bool:
				out[key] = _custom[key]
		for key: String in ["shadow_quality", "draw_distance"]:
			var options: Variant = _config.get(key + "_options", {})
			if options is Dictionary and options.has(_custom.get(key)):
				out[key] = _custom[key]
	# A selected Medium awaiting restart, or a driver fallback to OpenGL, must
	# never enable unsupported features on the renderer actually running.
	if not forward_plus():
		for key: String in FEATURES:
			out[key] = false
	return out


static func choose(preset: String) -> Error:
	load_preferences()
	if not PRESETS.has(preset):
		return ERR_INVALID_PARAMETER
	return _commit(preset, preset, {}, _overlay)


static func customize(key: String, value: Variant) -> Error:
	load_preferences()
	if FEATURES.has(key):
		if not (value is bool) or _base == "Low" or not forward_plus():
			return ERR_INVALID_PARAMETER
	elif key == "shadow_quality" or key == "draw_distance":
		var options: Variant = _config.get(key + "_options", {})
		if not (options is Dictionary) or not options.has(value):
			return ERR_INVALID_PARAMETER
	else:
		return ERR_INVALID_PARAMETER
	var custom := _custom.duplicate(true)
	custom[key] = value
	return _commit("Custom", _base, custom, _overlay)


static func set_overlay(enabled: bool) -> Error:
	load_preferences()
	return _commit("Custom", _base, _custom, enabled)


static func overlay_enabled() -> bool:
	load_preferences()
	return _overlay


static func _commit(choice: String, base: String, custom: Dictionary, overlay: bool) -> Error:
	# One device document holds preferences and preboot renderer choice. A
	# failed write leaves the in-memory choice unchanged and reports to the UI.
	var doc := ConfigFile.new()
	doc.set_value("tetherbound_graphics", "preset", choice)
	doc.set_value("tetherbound_graphics", "base", base)
	doc.set_value("tetherbound_graphics", "custom", custom)
	doc.set_value("tetherbound_graphics", "overlay", overlay)
	doc.set_value("rendering", "renderer/rendering_method", "gl_compatibility" if base == "Low" else "forward_plus")
	var error := _persist_document(doc)
	if error != OK:
		return error
	_choice = choice
	_base = base
	_custom = custom.duplicate(true)
	_overlay = overlay
	return OK


static func _usable_document(doc: ConfigFile) -> bool:
	var base := str(doc.get_value("tetherbound_graphics", "base", ""))
	var choice := str(doc.get_value("tetherbound_graphics", "preset", ""))
	return PRESETS.has(base) and (PRESETS.has(choice) or choice == "Custom") \
		and (choice == "Custom" or choice == base) \
		and doc.get_value("tetherbound_graphics", "custom", null) is Dictionary \
		and doc.get_value("tetherbound_graphics", "overlay", null) is bool \
		and str(doc.get_value("rendering", "renderer/rendering_method", "")) == ("gl_compatibility" if base == "Low" else "forward_plus")


static func _persist_document(doc: ConfigFile) -> Error:
	# ConfigFile.save cannot confirm buffered/flush success. Stage and verify
	# bytes first; preserve the prior document until promotion succeeds.
	# This is a per-device file transaction, not an OS power-loss guarantee.
	var bytes := doc.encode_to_text().to_utf8_buffer()
	var temporary := OVERRIDE_PATH + ".pending-" + Crypto.new().generate_random_bytes(16).hex_encode()
	var file := FileAccess.open(temporary, FileAccess.WRITE)
	if file == null:
		return ERR_FILE_CANT_OPEN
	file.store_buffer(bytes)
	var write_error := file.get_error()
	file.flush()
	var flush_error := file.get_error()
	var complete := write_error == OK and flush_error == OK and file.get_position() == bytes.size()
	file.close()
	if complete:
		var check := FileAccess.open(temporary, FileAccess.READ)
		complete = check != null
		if check != null:
			complete = check.get_length() == bytes.size() and check.get_buffer(bytes.size()) == bytes
			check.close()
	var checked := ConfigFile.new()
	complete = complete and checked.load(temporary) == OK and _usable_document(checked)
	if not complete:
		DirAccess.remove_absolute(temporary)
		return ERR_FILE_CANT_WRITE
	var previous := OVERRIDE_PATH + ".previous"
	var moved_previous := false
	if FileAccess.file_exists(OVERRIDE_PATH):
		var current := ConfigFile.new()
		if current.load(OVERRIDE_PATH) == OK and _usable_document(current):
			if FileAccess.file_exists(previous) and DirAccess.remove_absolute(previous) != OK:
				DirAccess.remove_absolute(temporary)
				return ERR_FILE_CANT_WRITE
			if DirAccess.rename_absolute(OVERRIDE_PATH, previous) != OK:
				DirAccess.remove_absolute(temporary)
				return ERR_FILE_CANT_WRITE
			moved_previous = true
		elif DirAccess.remove_absolute(OVERRIDE_PATH) != OK:
			# Never displace a valid recovery copy with a damaged canonical file.
			DirAccess.remove_absolute(temporary)
			return ERR_FILE_CANT_WRITE
	if DirAccess.rename_absolute(temporary, OVERRIDE_PATH) != OK:
		if moved_previous:
			DirAccess.rename_absolute(previous, OVERRIDE_PATH)
		DirAccess.remove_absolute(temporary)
		return ERR_FILE_CANT_WRITE
	# Retaining the previous generation is intentional: readers can recover it
	# if a later load encounters a damaged canonical document.
	return OK


static func apply_environment(environment: Environment) -> void:
	if environment == null:
		return
	var cfg := values()
	if cfg.is_empty():
		return
	environment.volumetric_fog_enabled = bool(cfg.get("volumetric_fog", false))
	environment.ssao_enabled = bool(cfg.get("ssao", false))
	environment.ssil_enabled = bool(cfg.get("ssil", false))
	environment.glow_enabled = bool(cfg.get("glow", false))
	environment.volumetric_fog_density = float(cfg.get("volumetric_fog_density", 0.0))
	environment.volumetric_fog_length = float(cfg.get("volumetric_fog_length", 64.0))
	environment.volumetric_fog_sky_affect = float(cfg.get("volumetric_fog_sky_affect", 0.0))


static func apply_viewport(viewport: Viewport) -> void:
	if viewport == null:
		return
	var cfg := values()
	var distances: Variant = _config.get("draw_distance_options", {})
	if distances is Dictionary:
		var distance: Variant = distances.get(cfg.get("draw_distance", "Normal"), {})
		if distance is Dictionary:
			viewport.mesh_lod_threshold = float(distance.get("lod_threshold", 1.0))
	var shadows: Variant = _config.get("shadow_quality_options", {})
	if shadows is Dictionary:
		var quality: Variant = shadows.get(cfg.get("shadow_quality", "Medium"), {})
		if quality is Dictionary:
			var profile := str(cfg.get("shadow_quality", "Medium"))
			if profile != _applied_shadow_profile:
				RenderingServer.directional_shadow_atlas_set_size(int(quality.get("atlas_size", 2048)), false)
				RenderingServer.directional_soft_shadow_filter_set_quality(int(quality.get("filter_quality", 2)) as RenderingServer.ShadowQuality)
				_applied_shadow_profile = profile


static func apply_sun(sun: DirectionalLight3D) -> void:
	if sun == null:
		return
	# Terrain3D's Compatibility path samples the sun shadow map even when
	# shading is disabled. Keep the map valid; zero opacity removes visible
	# shadows without triggering the known fully-black ground defect.
	# Off consequently retains the minimum atlas cost on this path.
	if values().get("shadow_quality", "Medium") == "Off":
		sun.shadow_enabled = true
		sun.shadow_opacity = 0.0


static func apply_camera(camera: Camera3D) -> void:
	if camera == null:
		return
	var cfg := values()
	var distances: Variant = _config.get("draw_distance_options", {})
	if distances is Dictionary:
		var distance: Variant = distances.get(cfg.get("draw_distance", "Normal"), {})
		if distance is Dictionary:
			camera.far = maxf(camera.near + 1.0, float(distance.get("far", camera.far)))
