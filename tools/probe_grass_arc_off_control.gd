extends "res://tools/catalogue_survey.gd"

## Matched OFF control for blade-local arc. Mutates only one uniform on each
## live grass ShaderMaterial and restores the exact prior value/object afterward.
const TOOL_PATH := "res://tools/probe_grass_arc_off_control.gd"
const SHADER_PATH := "res://shaders/grass_field.gdshader"
const BIOMES := ["meadows", "stormwood", "water"]
var _materials: Array[ShaderMaterial] = []
var _prior: Dictionary = {}
var _receipt: Dictionary = {}

func _load_plan() -> bool:
	if not super._load_plan():
		return false
	if _biome_id not in BIOMES:
		push_error("grass arc OFF control requires Meadows, Stormwood, or Water")
		return false
	return true

func _mount_production_world() -> bool:
	if not await super._mount_production_world():
		return false
	var pending: Array[Node] = [_world]
	while not pending.is_empty():
		var node := pending.pop_back() as Node
		for child: Node in node.get_children():
			pending.append(child)
		if node is GeometryInstance3D:
			var material := (node as GeometryInstance3D).material_override as ShaderMaterial
			if material != null and material.shader != null and material.shader.resource_path == SHADER_PATH:
				if not _prior.has(material.get_instance_id()):
					_prior[material.get_instance_id()] = material.get_shader_parameter("blade_arc_angle")
					_materials.append(material)
	if _materials.is_empty():
		_failures.append("grass arc OFF control found zero live material targets")
		_write_manifest()
		return false
	for material: ShaderMaterial in _materials:
		material.set_shader_parameter("blade_arc_angle", 0.0)
	_receipt = {"biome": _biome_id, "target_count": _materials.size(),
		"material_instance_ids": _materials.map(func(m: ShaderMaterial): return m.get_instance_id()),
		"changed_parameter_only": "blade_arc_angle", "off_value_radians": 0.0,
		"material_shader_or_raw_terrain_bindings_replaced": false,
		"camera_player_density_masks_clearances_mesh_palette_or_gameplay_mutation": false}
	_write_manifest()
	return true

func _finish(complete: bool) -> void:
	for material: ShaderMaterial in _materials:
		material.set_shader_parameter("blade_arc_angle", _prior[material.get_instance_id()])
	_receipt["restored"] = _materials.all(func(m: ShaderMaterial):
		return m.get_shader_parameter("blade_arc_angle") == _prior[m.get_instance_id()])
	_manifest["grass_arc_off_control"] = _receipt
	_manifest["capture_tool"] = {"path": TOOL_PATH,
		"sha256": FileAccess.get_file_as_string(TOOL_PATH).sha256_text()}
	super._finish(complete)
