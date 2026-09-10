extends "res://tools/catalogue_survey.gd"

## Matched OFF control for the Water Fresnel material candidate. The complete
## production realm is mounted first; only five parameters on its already-bound
## WaterSurface ShaderMaterial are restored to the prior shader defaults.

const TOOL_PATH := "res://tools/probe_water_fresnel_control.gd"


func _load_plan() -> bool:
	if not super._load_plan():
		return false
	if _biome_id != "water":
		push_error("Water Fresnel control requires --biome=water")
		return false
	return true


func _mount_production_world() -> bool:
	var mounted := await super._mount_production_world()
	if not mounted:
		return false
	var surface := _world.get_node_or_null(^"WaterSurface") as MeshInstance3D
	if surface == null:
		_failures.append("Water Fresnel control found no production WaterSurface")
		_write_manifest()
		return false
	var material := surface.material_override as ShaderMaterial
	if material == null:
		_failures.append("Water Fresnel control found no bound WaterSurface ShaderMaterial")
		_write_manifest()
		return false
	material.set_shader_parameter("fresnel_colour", Color(0.73, 0.78, 0.81, 1.0))
	material.set_shader_parameter("fresnel_power", 4.0)
	material.set_shader_parameter("fresnel_strength", 0.65)
	material.set_shader_parameter("roughness_value", 0.12)
	material.set_shader_parameter("wave_uv_scale", 0.09)
	var colour: Color = material.get_shader_parameter("fresnel_colour")
	_manifest["water_fresnel_control"] = {
		"timing": "after production world mount and before capture preparation",
		"node_path": str(_world.get_path_to(surface)),
		"material_instance_id": material.get_instance_id(),
		"shader_path": material.shader.resource_path if material.shader != null else "",
		"fresnel_colour": [colour.r, colour.g, colour.b, colour.a],
		"fresnel_power": float(material.get_shader_parameter("fresnel_power")),
		"fresnel_strength": float(material.get_shader_parameter("fresnel_strength")),
		"roughness_value": float(material.get_shader_parameter("roughness_value")),
		"wave_uv_scale": float(material.get_shader_parameter("wave_uv_scale")),
		"mutation_scope": "process-local visual parameters on the existing WaterSurface material only",
		"player_camera_geometry_or_gameplay_state_mutation": false,
	}
	_write_manifest()
	return true


func _write_manifest() -> void:
	_manifest["capture_tool"] = {
		"path": TOOL_PATH,
		"sha256": FileAccess.get_file_as_string(TOOL_PATH).sha256_text(),
	}
	_manifest["control_contract"] = (
		"Exact mounted production Water scene, player, CameraRig, foliage, terrain, " +
		"surface geometry and gameplay state. Only Fresnel colour/power/strength, " +
		"roughness and wave UV scale are restored to the prior shader defaults on " +
		"the existing WaterSurface ShaderMaterial.")
	super._write_manifest()
