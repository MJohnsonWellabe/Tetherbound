extends "res://tools/catalogue_survey.gd"

## South Bridge identity and shading isolation for the procedural bush tier.
const TOOL_PATH := "res://tools/probe_south_bridge_cover_bush.gd"
const COVER_SHADER_PATH := "res://shaders/cover_tier.gdshader"
const ROUGHNESS_LINE := "\tROUGHNESS = 0.95;"
const BACKLIGHT_BLOCK := "\tROUGHNESS = 0.95;\n\tBACKLIGHT = tint_tip * 0.28 * (1.0 - v_wood);"
const RAW_KEYS: Array[StringName] = [&"_height_maps", &"_control_maps", &"_color_maps"]
var _receipts: Array[Dictionary] = []

func _load_plan() -> bool:
	if not super._load_plan():
		return false
	if _biome_id != "meadows" or _planned.size() != 2:
		push_error("cover-bush probe requires Meadows South Bridge only, day and night")
		return false
	for row: Dictionary in _planned:
		if not str(row.frame_id).contains("south_bridge"):
			push_error("cover-bush probe selection contains a non-South-Bridge row")
			return false
	return true

func _capture_row(row: Dictionary) -> void:
	await super._capture_row(row)
	if not _failures.is_empty():
		return
	var targets := _cover_bush_targets()
	if targets.is_empty():
		_failures.append("cover-bush probe found zero live Cover_bushes geometries")
		_write_manifest()
		return
	var source := FileAccess.get_file_as_string(COVER_SHADER_PATH).replace("\r\n", "\n")
	var replacements := source.count(ROUGHNESS_LINE)
	if replacements != 1:
		_failures.append("cover-bush probe expected one shader replacement, got %d" % replacements)
		_write_manifest()
		return
	var material_records := _unique_material_records(targets)
	if material_records.is_empty():
		_failures.append("live Cover_bushes geometry had no production cover material")
		_write_manifest()
		return

	var old_process_mode := _world.process_mode
	_world.process_mode = Node.PROCESS_MODE_DISABLED
	var visibility := {}
	for geometry: GeometryInstance3D in targets:
		visibility[geometry.get_instance_id()] = geometry.visible
		geometry.visible = false
	await _settle()
	await _save_variant(row, "cover-bushes-hidden", {
		"control":"hide_only_procedural_Cover_bushes",
		"target_paths":_target_paths(targets)})
	for geometry: GeometryInstance3D in targets:
		geometry.visible = bool(visibility[geometry.get_instance_id()])

	var backlight_shader := Shader.new()
	backlight_shader.code = source.replace(ROUGHNESS_LINE, BACKLIGHT_BLOCK)
	for record: Dictionary in material_records:
		var material: ShaderMaterial = record.material
		material.shader = backlight_shader
		_restore_bindings(material, record)
		if not _bindings_match(material, record):
			_failures.append("cover-bush probe lost uniforms or raw Terrain3D RIDs")
	await _settle()
	await _save_variant(row, "cover-bushes-backlight028", {
		"control":"Cover_bushes_BACKLIGHT_only", "backlight_strength":0.28,
		"shader_replacement_count":replacements, "target_paths":_target_paths(targets)})

	for record: Dictionary in material_records:
		var material: ShaderMaterial = record.material
		material.shader = record.shader
		_restore_bindings(material, record)
	_world.process_mode = old_process_mode
	var material_ids: Array[int] = []
	var bindings_restored := true
	for record: Dictionary in material_records:
		material_ids.append((record.material as ShaderMaterial).get_instance_id())
		bindings_restored = bindings_restored and (record.material as ShaderMaterial).shader == record.shader and _bindings_match(record.material, record)
	var visibility_restored := true
	for geometry: GeometryInstance3D in targets:
		visibility_restored = visibility_restored and geometry.visible == bool(visibility[geometry.get_instance_id()])
	_receipts.append({"baseline_frame":row.frame_id, "target_count":targets.size(),
		"target_paths":_target_paths(targets), "material_instance_ids":material_ids,
		"shader_replacement_count":replacements, "visibility_restored":visibility_restored,
		"materials_shaders_uniforms_and_raw_rids_restored":bindings_restored,
		"world_process_mode_restored":_world.process_mode == old_process_mode,
		"camera_player_density_normal_texture_brightness_or_gameplay_mutation":false})
	_write_manifest()

func _save_variant(row: Dictionary, suffix: String, evidence: Dictionary) -> void:
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	var frame_id := "%s__%s" % [str(row.frame_id), suffix]
	var path := "%s/%s.png" % [_output_dir, frame_id]
	if image == null or image.is_empty() or image.get_width() != root.size.x \
			or image.get_height() != root.size.y:
		_failures.append("%s: viewport image is empty or wrong-sized" % frame_id)
	elif image.save_png(path) != OK:
		_failures.append("%s: save_png failed" % frame_id)
	else:
		var record := row.duplicate(true)
		record["frame_id"] = frame_id
		record["file"] = path
		record["player_position"] = _vec3(_player.global_position)
		record["camera_position"] = _vec3(_camera.global_position)
		record["camera_transform"] = _transform(_camera.global_transform)
		record["observed_clock"] = {"requested":str(row.time),
			"world_look":str(_look.call("time_of_day")) if _look.has_method("time_of_day") else "unavailable"}
		record["diagnostic"] = evidence.duplicate(true)
		record["bytes"] = FileAccess.get_file_as_bytes(path).size()
		_records.append(record)
		print("COVER BUSH DIAGNOSTIC %s -> %s" % [frame_id, path])
	_write_manifest()

func _cover_bush_targets() -> Array[GeometryInstance3D]:
	var out: Array[GeometryInstance3D] = []
	var pending: Array[Node] = [_world]
	while not pending.is_empty():
		var node := pending.pop_back() as Node
		for child: Node in node.get_children():
			pending.append(child)
		if not node is GeometryInstance3D:
			continue
		var geometry := node as GeometryInstance3D
		var material := geometry.material_override as ShaderMaterial
		if material == null or material.shader == null or material.shader.resource_path != COVER_SHADER_PATH:
			continue
		var cursor: Node = geometry
		while cursor != null and cursor != _world:
			if cursor.name == &"Cover_bushes":
				out.append(geometry)
				break
			cursor = cursor.get_parent()
	return out

func _target_paths(targets: Array[GeometryInstance3D]) -> Array[String]:
	var paths: Array[String] = []
	for target: GeometryInstance3D in targets:
		paths.append(str(_world.get_path_to(target)))
	return paths

func _unique_material_records(targets: Array[GeometryInstance3D]) -> Array[Dictionary]:
	var records: Array[Dictionary] = []
	var seen := {}
	for geometry: GeometryInstance3D in targets:
		var material := geometry.material_override as ShaderMaterial
		if material == null or seen.has(material.get_instance_id()):
			continue
		seen[material.get_instance_id()] = true
		var parameters := {}
		for property: Dictionary in material.get_property_list():
			var property_name := str(property.get("name", ""))
			if property_name.begins_with("shader_parameter/"):
				var parameter := property_name.trim_prefix("shader_parameter/")
				parameters[parameter] = material.get_shader_parameter(parameter)
		var raw := {}
		for key: StringName in RAW_KEYS:
			raw[key] = RenderingServer.material_get_param(material.get_rid(), key)
		records.append({"material":material, "shader":material.shader,
			"parameters":parameters, "raw":raw})
	return records

func _restore_bindings(material: ShaderMaterial, record: Dictionary) -> void:
	for parameter: String in record.parameters:
		material.set_shader_parameter(parameter, record.parameters[parameter])
	for key: StringName in record.raw:
		var rid: RID = record.raw[key]
		if rid.is_valid():
			RenderingServer.material_set_param(material.get_rid(), key, rid)

func _bindings_match(material: ShaderMaterial, record: Dictionary) -> bool:
	for parameter: String in record.parameters:
		if material.get_shader_parameter(parameter) != record.parameters[parameter]:
			return false
	for key: StringName in record.raw:
		var expected: RID = record.raw[key]
		var actual: RID = RenderingServer.material_get_param(material.get_rid(), key)
		if not expected.is_valid() or actual != expected:
			return false
	return true

func _settle() -> void:
	for _frame in 4:
		await process_frame

func _finish(_complete: bool) -> void:
	_manifest["south_bridge_cover_bush_diagnostic"] = _receipts.duplicate(true)
	_manifest["capture_tool"] = {"path":TOOL_PATH,
		"sha256":FileAccess.get_file_as_string(TOOL_PATH).sha256_text()}
	super._finish(_failures.is_empty() and _records.size() == _planned.size() * 3)
