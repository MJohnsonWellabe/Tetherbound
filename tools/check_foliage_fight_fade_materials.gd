extends SceneTree
## Root-granted isolated GPU proof; no world/autoload or production flag edits.
## Reads the actual five eligible glTFs via runtime GLTFDocument, then renders
## their materials on a fixed lit quad. This does not prove imported tree
## geometry, production retint coverage, art acceptance or camera integration.
const FADE := preload("res://scripts/world/foliage_fight_fade.gd")
const CONFIG := "res://data/config/foliage_camera_visibility.json"
const SIZE := Vector2i(192, 192)
const PIXEL_TOLERANCE := 1.0 / 255.0 + 0.000001
var _out := ""
var _errors: Array[String] = []
var _inventory: Array = []
var _cases: Array = []
var _geometry: MeshInstance3D
var _camera: Camera3D
var _normals := 0
var _cutouts := 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--out="): _out = arg.trim_prefix("--out=")
	if DisplayServer.get_name() == "headless" or not _out.is_absolute_path() \
		or DirAccess.dir_exists_absolute(_out) or FileAccess.file_exists(_out):
		push_error("F10 material check requires a display and an absent absolute --out directory")
		quit(1)
		return
	if DirAccess.make_dir_recursive_absolute(_out) != OK:
		push_error("Cannot create F10 material output")
		quit(1)
		return
	root.size = SIZE
	root.msaa_3d = Viewport.MSAA_DISABLED
	root.use_taa = false
	var world := WorldEnvironment.new()
	world.environment = Environment.new()
	world.environment.background_mode = Environment.BG_COLOR
	world.environment.background_color = Color(0.02, 0.03, 0.05)
	world.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	world.environment.ambient_light_color = Color.WHITE
	world.environment.ambient_light_energy = 0.2
	root.add_child(world)
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-35, -25, 0)
	light.shadow_enabled = false
	root.add_child(light)
	_geometry = MeshInstance3D.new()
	root.add_child(_geometry)
	_camera = Camera3D.new()
	_camera.position = Vector3(0, 0, 3)
	root.add_child(_camera)
	_camera.make_current()
	var config: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(CONFIG))
	var cfg: Dictionary = config.line_of_sight_fade.duplicate(true)
	_check(cfg.enabled == false, "Production LOS flag must still be OFF")
	cfg.enabled = true # Local fixture only; no file or production scene mutation.
	var seen := {}
	for model: String in cfg.models:
		var state := GLTFState.new()
		state.handle_binary_image_mode = GLTFState.HANDLE_BINARY_IMAGE_MODE_EMBED_AS_UNCOMPRESSED
		var error := GLTFDocument.new().append_from_file(ProjectSettings.globalize_path(model), state)
		if error != OK:
			_check(false, "glTF read failed: " + model)
			continue
		var materials := state.get_materials()
		_check(not materials.is_empty(), "No glTF materials: " + model)
		for index in materials.size():
			var source := materials[index] as StandardMaterial3D
			if source == null:
				_check(false, "Expected StandardMaterial3D: " + model)
				continue
			var supported := FADE.STANDARD.supported(source)
			_inventory.append({"model": model, "material_index": index, "name": source.resource_name,
				"supported_raw_gltf": supported, "non_default_unimplemented": _unimplemented(source),
				"normal_enabled": source.normal_enabled, "textured": source.albedo_texture != null,
				"cutout": source.transparency == BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR})
			# These installed files share material definitions; render each named
			# definition once while inventory retains all eight model/material rows.
			if seen.has(source.resource_name): continue
			seen[source.resource_name] = true
			if not supported:
				_check(false, "Raw glTF material not convertible: " + source.resource_name)
				continue
			await _material_case(source, model, cfg, model.get_file().get_basename() + "_" + str(index))
	_check(_normals >= 1, "No actual normal map passed its visible negative control")
	_check(_cutouts >= 1, "No actual cutout foliage exercised")
	_check(_inventory.size() == 8, "Expected all eight eligible model/material rows")
	var report := {"fixture_only": true, "renderer": RenderingServer.get_current_rendering_method(),
		"gpu": RenderingServer.get_video_adapter_name(), "viewport": root.size,
		"pixel_tolerance": PIXEL_TOLERANCE, "inventory": _inventory, "cases": _cases, "errors": _errors,
		"limits": "Runtime glTF materials on a lit quad; not editor import overrides, actual tree geometry, production retint, world wiring or art acceptance."}
	var file := FileAccess.open(_out.path_join("material-proof.json"), FileAccess.WRITE)
	if file == null:
		_check(false, "Cannot save material proof")
	else:
		file.store_string(JSON.stringify(report, "\t"))
		file.flush()
		_check(file.get_error() == OK, "Material proof write failed")
		file.close()
	for message: String in _errors: push_error(message)
	if _errors.is_empty(): print("F10_MATERIAL_EQUIVALENCE_COMPLETE: ", _cases.size(), " materials; no art acceptance")
	quit(0 if _errors.is_empty() else 1)


func _material_case(source: StandardMaterial3D, model: String, cfg: Dictionary, label: String) -> void:
	_check(source.albedo_texture != null, label + ": missing real albedo texture")
	var mesh := _quad(source)
	var fade := FADE.new()
	var converted := fade.apply(mesh, model, "stormwood", cfg)
	_check(fade.has_materials(), label + ": no converted material")
	var stock := await _capture(mesh, label + "_stock")
	var decorated := await _capture(converted, label + "_converted")
	if stock == null or decorated == null: return
	var stats := _visible(stock)
	_check(stats.pixels >= 256 and stats.colours >= 16, label + ": texture/lighting control is empty or flat")
	var difference := _difference(stock, decorated)
	_check(difference.max_error <= PIXEL_TOLERANCE, label + ": stock/converted pixels differ")
	var row := {"label": label, "name": source.resource_name, "stock": stats, "equivalence": difference}
	if source.normal_enabled:
		_check(source.normal_texture != null, label + ": normal mapping has no texture")
		var flat := source.duplicate() as StandardMaterial3D
		flat.normal_enabled = false
		var control := await _capture(_quad(flat), label + "_normal_disabled")
		if control != null:
			row.normal_control = _difference(stock, control)
			_check(row.normal_control.changed_pixels >= 16, label + ": normal map has no observable effect")
			if row.normal_control.changed_pixels >= 16: _normals += 1
	if source.transparency == BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR:
		var opaque := source.duplicate() as StandardMaterial3D
		opaque.transparency = BaseMaterial3D.TRANSPARENCY_DISABLED
		var control := await _capture(_quad(opaque), label + "_cutout_disabled")
		if control != null:
			row.cutout_control = _difference(stock, control)
			_check(row.cutout_control.changed_pixels >= 16, label + ": cutout has no observable effect")
			if row.cutout_control.changed_pixels >= 16: _cutouts += 1
	# Actual source texture reused as a deliberately unsupported detail layer.
	# Identity plus full raster equality proves fallback keeps it, not a simpler
	# substitute. Activating the rejected fade must not alter its appearance.
	var detailed := source.duplicate() as StandardMaterial3D
	detailed.detail_enabled = true
	detailed.detail_albedo = source.albedo_texture
	var detail_mesh := _quad(detailed)
	var detail_fade := FADE.new()
	var retained := detail_fade.apply(detail_mesh, model, "stormwood", cfg)
	_check(retained.surface_get_material(0) == detailed and not detail_fade.has_materials(), label + ": unsupported detail replaced")
	var original_detail := await _capture(detail_mesh, label + "_detail_original")
	detail_fade.target(1, Vector3(0, 0, -3))
	detail_fade.update(_camera.global_position, 0.2)
	var retained_detail := await _capture(retained, label + "_detail_retained")
	if original_detail != null and retained_detail != null:
		row.detail_preservation = _difference(original_detail, retained_detail)
		_check(row.detail_preservation.max_error == 0.0, label + ": unsupported detail raster changed")
	_cases.append(row)


func _quad(material: Material) -> QuadMesh:
	var mesh := QuadMesh.new()
	mesh.size = Vector2(2, 2)
	mesh.material = material
	return mesh


func _capture(mesh: Mesh, name: String) -> Image:
	_geometry.mesh = mesh
	for frame in 3:
		await process_frame
		await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	if image == null or image.is_empty() or image.get_size() != SIZE:
		_check(false, "Missing/wrong-size image: " + name)
		return null
	_check(image.save_png(_out.path_join(name + ".png")) == OK, "Image save failed: " + name)
	return image


func _difference(a: Image, b: Image) -> Dictionary:
	var max_error := 0.0
	var changed := 0
	for y in SIZE.y:
		for x in SIZE.x:
			var p := a.get_pixel(x, y)
			var q := b.get_pixel(x, y)
			var error := maxf(maxf(absf(p.r - q.r), absf(p.g - q.g)), maxf(absf(p.b - q.b), absf(p.a - q.a)))
			max_error = maxf(max_error, error)
			if error > PIXEL_TOLERANCE: changed += 1
	return {"max_error": max_error, "changed_pixels": changed}


func _visible(image: Image) -> Dictionary:
	var background := image.get_pixel(0, 0)
	var pixels := 0
	var colours := {}
	for y in SIZE.y:
		for x in SIZE.x:
			var p := image.get_pixel(x, y)
			if maxf(absf(p.r - background.r), maxf(absf(p.g - background.g), absf(p.b - background.b))) > 0.02:
				pixels += 1
				if colours.size() < 512: colours[p.to_rgba32()] = true
	return {"pixels": pixels, "colours": colours.size()}


func _unimplemented(source: StandardMaterial3D) -> Array:
	var defaults := StandardMaterial3D.new()
	var result: Array = []
	for property: Dictionary in source.get_property_list():
		var key := str(property.name)
		if (int(property.usage) & PROPERTY_USAGE_STORAGE) == 0 or key in FADE.STANDARD.SUPPORTED or key.begins_with("metadata/"): continue
		if source.get(key) != defaults.get(key): result.append(key)
	return result


func _check(ok: bool, message: String) -> void:
	if not ok: _errors.append(message)
