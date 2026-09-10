extends "res://tools/catalogue_survey.gd"

## Matched OFF control for interpolated grass grounding. It keeps each live
## ShaderMaterial object and copies Terrain3D's raw texture-array RIDs back after
## swapping only its Shader, so camera-follow writes continue to hit production.

const TOOL_PATH := "res://tools/probe_grass_nearest_height_control.gd"
const SHADER_PATH := "res://shaders/grass_field.gdshader"
const CALL := "ground_h = grass_surface_height(terrain_uv, coord);"
const OLD_FETCH := "ground_h = texelFetch(_height_maps, coord, 0).r;"
const BIOMES := ["meadows", "stormwood", "water"]

var _receipt: Dictionary = {}
var _materials: Array[ShaderMaterial] = []
var _snapshots: Dictionary = {}
var _control_shader: Shader


func _load_plan() -> bool:
	if not super._load_plan():
		return false
	if _biome_id not in BIOMES:
		push_error("nearest-height grass control requires Meadows, Stormwood, or Water")
		return false
	return true


func _mount_production_world() -> bool:
	var mounted := await super._mount_production_world()
	if not mounted:
		return false
	var code := FileAccess.get_file_as_string(SHADER_PATH).replace("\r\n", "\n")
	var replacements := code.count(CALL)
	if replacements != 1:
		_failures.append("nearest-height control expected one grounding call, got %d" % replacements)
		_write_manifest()
		return false
	_control_shader = Shader.new()
	_control_shader.code = code.replace(CALL, OLD_FETCH)
	var paths := {}
	var targets := _grass_targets()
	if targets.is_empty():
		_failures.append("nearest-height control found no mounted grass-field materials")
		_write_manifest()
		return false
	for geometry: GeometryInstance3D in targets:
		var material := geometry.material_override as ShaderMaterial
		var identity := material.get_instance_id()
		if not paths.has(identity):
			paths[identity] = []
		(paths[identity] as Array).append(str(_world.get_path_to(geometry)))
		if _snapshots.has(identity):
			continue
		var snapshot := _snapshot(material)
		_snapshots[identity] = snapshot
		_materials.append(material)
		material.shader = _control_shader
		_restore(material, snapshot)
		if not _matches(material, snapshot):
			_failures.append("nearest-height control lost parameters or raw Terrain3D RIDs")
			_write_manifest()
			return false
	var records: Array[Dictionary] = []
	for material: ShaderMaterial in _materials:
		var identity := material.get_instance_id()
		records.append({"material_instance_id": identity, "node_paths": paths[identity],
			"raw_bindings": _raw_receipt(material), "material_object_replaced": false})
	_receipt = {"biome": _biome_id, "replacement_count": replacements,
		"unique_materials": _materials.size(), "materials": records,
		"control": "nearest Terrain3D height texel only",
		"camera_player_density_masks_clearances_mesh_palette_or_gameplay_mutation": false}
	_write_manifest()
	return _failures.is_empty()


func _grass_targets() -> Array[GeometryInstance3D]:
	var out: Array[GeometryInstance3D] = []
	var pending: Array[Node] = [_world]
	while not pending.is_empty():
		var node := pending.pop_back() as Node
		for child: Node in node.get_children():
			pending.append(child)
		if node is GeometryInstance3D:
			var geometry := node as GeometryInstance3D
			var material := geometry.material_override as ShaderMaterial
			if material != null and material.shader != null \
					and material.shader.resource_path == SHADER_PATH:
				out.append(geometry)
	return out


func _snapshot(material: ShaderMaterial) -> Dictionary:
	var parameters := {}
	for property: Dictionary in material.get_property_list():
		var property_name := str(property.get("name", ""))
		if property_name.begins_with("shader_parameter/"):
			var parameter := property_name.trim_prefix("shader_parameter/")
			parameters[parameter] = material.get_shader_parameter(parameter)
	var raw := {}
	for key: StringName in [&"_height_maps", &"_control_maps", &"_color_maps"]:
		raw[key] = RenderingServer.material_get_param(material.get_rid(), key)
	return {"shader": material.shader, "parameters": parameters, "raw": raw}


func _restore(material: ShaderMaterial, snapshot: Dictionary) -> void:
	for parameter: String in snapshot.parameters:
		material.set_shader_parameter(parameter, snapshot.parameters[parameter])
	for key: StringName in snapshot.raw:
		var rid: RID = snapshot.raw[key]
		if rid.is_valid():
			RenderingServer.material_set_param(material.get_rid(), key, rid)


func _matches(material: ShaderMaterial, snapshot: Dictionary) -> bool:
	for parameter: String in snapshot.parameters:
		if material.get_shader_parameter(parameter) != snapshot.parameters[parameter]:
			return false
	for key: StringName in snapshot.raw:
		var expected: RID = snapshot.raw[key]
		var actual: RID = RenderingServer.material_get_param(material.get_rid(), key)
		if not expected.is_valid() or actual != expected:
			return false
	return true


func _raw_receipt(material: ShaderMaterial) -> Dictionary:
	var out := {}
	for key: StringName in [&"_height_maps", &"_control_maps", &"_color_maps"]:
		var rid: RID = RenderingServer.material_get_param(material.get_rid(), key)
		out[str(key)] = {"rid": str(rid), "valid": rid.is_valid()}
	return out


func _finish(complete: bool) -> void:
	for material: ShaderMaterial in _materials:
		var snapshot: Dictionary = _snapshots[material.get_instance_id()]
		material.shader = snapshot.shader
		_restore(material, snapshot)
	_receipt["restored_original_shaders_and_bindings"] = _materials.all(func(material: ShaderMaterial) -> bool:
		return material.shader == _snapshots[material.get_instance_id()].shader \
				and _matches(material, _snapshots[material.get_instance_id()]))
	_manifest["grass_nearest_height_control"] = _receipt.duplicate(true)
	_manifest["capture_tool"] = {"path": TOOL_PATH,
		"sha256": FileAccess.get_file_as_string(TOOL_PATH).sha256_text()}
	super._finish(complete)
