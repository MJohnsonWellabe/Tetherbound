extends "res://tools/_capture_water_gull_rest_signal_site.gd"

## Matched OFF control for deep-water opacity. The complete production Water
## scene and five Gull Rest views remain unchanged; only the mounted surface's
## deep alpha returns to 0.9 for this process.

const TOOL_PATH := "res://tools/probe_water_deep_opacity_off.gd"
const CONTROL_ALPHA_DEEP := 0.9

var _surface: MeshInstance3D
var _production_mesh: Mesh
var _production_material: ShaderMaterial
var _control_material: ShaderMaterial
var _receipt: Dictionary = {}


func _place_catalogue_pose(game: Node) -> bool:
	if not _bind_control():
		return false
	return await super._place_catalogue_pose(game)


func _bind_control() -> bool:
	_surface = _world.get_node_or_null(^"WaterSurface") as MeshInstance3D
	if _surface == null or not _surface.material_override is ShaderMaterial:
		_fail("deep-opacity OFF control found no mounted WaterSurface material")
		return false
	_production_material = _surface.material_override as ShaderMaterial
	_production_mesh = _surface.mesh
	_control_material = _production_material.duplicate(false) as ShaderMaterial
	_control_material.set_shader_parameter("alpha_deep", CONTROL_ALPHA_DEEP)
	if float(_production_material.get_shader_parameter("alpha_deep")) != 1.0 \
			or float(_control_material.get_shader_parameter("alpha_deep")) != CONTROL_ALPHA_DEEP:
		_fail("deep-opacity OFF control alpha readback did not match production/control contract")
		return false
	if _control_material.get_shader_parameter("alpha_shallow") \
			!= _production_material.get_shader_parameter("alpha_shallow"):
		_fail("deep-opacity OFF control changed shallow alpha")
		return false
	for key: String in ["terrain_height", "wave_normal_a", "wave_normal_b", "foam_noise"]:
		var source_texture := _production_material.get_shader_parameter(key) as Texture2D
		var control_texture := _control_material.get_shader_parameter(key) as Texture2D
		if source_texture == null or control_texture == null \
				or source_texture.get_instance_id() != control_texture.get_instance_id():
			_fail("deep-opacity OFF control did not retain texture binding %s" % key)
			return false
	_surface.material_override = _control_material
	_receipt = {
		"timing": "after production world mount and before first Gull Rest pose",
		"node_path": str(_world.get_path_to(_surface)),
		"production_material_instance_id": _production_material.get_instance_id(),
		"control_material_instance_id": _control_material.get_instance_id(),
		"production_alpha_deep": float(_production_material.get_shader_parameter("alpha_deep")),
		"control_alpha_deep": float(_control_material.get_shader_parameter("alpha_deep")),
		"production_alpha_shallow": float(_production_material.get_shader_parameter("alpha_shallow")),
		"control_alpha_shallow": float(_control_material.get_shader_parameter("alpha_shallow")),
		"mesh_instance_id": _production_mesh.get_instance_id() if _production_mesh != null else 0,
		"mesh_identity_preserved": _surface.mesh == _production_mesh,
		"mutation_scope": "process-local duplicate WaterSurface material alpha_deep only",
		"gameplay_mutation": false,
	}
	print("WATER DEEP OPACITY OFF READBACK: " + JSON.stringify(_receipt))
	return true


func _finish(extra: Dictionary) -> void:
	if _surface != null and _production_material != null:
		_surface.material_override = _production_material
		_receipt["restored_production_material_identity"] = \
				_surface.material_override == _production_material
		_receipt["restored_production_mesh_identity"] = _surface.mesh == _production_mesh
	var evidence := extra.duplicate(true)
	evidence["water_deep_opacity_off_control"] = _receipt.duplicate(true)
	evidence["capture_tool"] = {"path": TOOL_PATH,
		"sha256": FileAccess.get_file_as_string(TOOL_PATH).sha256_text()}
	super._finish(evidence)
