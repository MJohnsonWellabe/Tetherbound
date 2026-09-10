extends "res://tools/probe_grass_nearest_height_control.gd"

## Combined matched control against the pre-grounding, pre-arc grass form.
## The base tool swaps only interpolated height back to nearest while preserving
## live ShaderMaterial objects and raw Terrain3D RIDs; this layer disables arc.
const COMBINED_TOOL_PATH := "res://tools/probe_grass_original_geometry_control.gd"
var _combined_receipt: Dictionary = {}

func _mount_production_world() -> bool:
	if not await super._mount_production_world():
		return false
	if _materials.is_empty():
		_failures.append("combined original grass control found zero live material targets")
		_write_manifest()
		return false
	for material: ShaderMaterial in _materials:
		material.set_shader_parameter("blade_arc_angle", 0.0)
		if float(material.get_shader_parameter("blade_arc_angle")) != 0.0:
			_failures.append("combined original grass control could not disable blade arc")
	_combined_receipt = {"biome": _biome_id, "target_count": _materials.size(),
		"material_instance_ids": _materials.map(func(m: ShaderMaterial): return m.get_instance_id()),
		"controls": ["nearest Terrain3D height texel", "blade_arc_angle=0"],
		"material_objects_or_raw_terrain_bindings_replaced_by_arc_layer": false,
		"camera_player_density_masks_clearances_mesh_palette_or_gameplay_mutation": false}
	_write_manifest()
	return _failures.is_empty()

func _finish(complete: bool) -> void:
	_manifest["grass_original_geometry_control"] = _combined_receipt.duplicate(true)
	_manifest["combined_capture_tool"] = {"path": COMBINED_TOOL_PATH,
		"sha256": FileAccess.get_file_as_string(COMBINED_TOOL_PATH).sha256_text()}
	super._finish(complete)
