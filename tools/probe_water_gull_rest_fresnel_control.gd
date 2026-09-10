extends "res://tools/_capture_water_gull_rest_signal_site.gd"

## Matched OFF control for the five-frame Gull Rest production-camera capture.
## The world, poses, ordinary input, clocks and capture sequence remain owned by
## the base tool. Only the five former WaterSurface shader defaults are restored.

const TOOL_PATH := "res://tools/probe_water_gull_rest_fresnel_control.gd"
var _control_readback: Dictionary = {}


func _place_catalogue_pose(game: Node) -> bool:
	if not _apply_fresnel_control():
		return false
	return await super._place_catalogue_pose(game)


func _apply_fresnel_control() -> bool:
	var surface := _world.get_node_or_null(^"WaterSurface") as MeshInstance3D
	if surface == null:
		_fail("Fresnel OFF control found no production WaterSurface")
		return false
	var material := surface.material_override as ShaderMaterial
	if material == null:
		_fail("Fresnel OFF control found no bound WaterSurface ShaderMaterial")
		return false
	material.set_shader_parameter("fresnel_colour", Color(0.73, 0.78, 0.81, 1.0))
	material.set_shader_parameter("fresnel_power", 4.0)
	material.set_shader_parameter("fresnel_strength", 0.65)
	material.set_shader_parameter("roughness_value", 0.12)
	material.set_shader_parameter("wave_uv_scale", 0.09)
	var colour: Color = material.get_shader_parameter("fresnel_colour")
	_control_readback = {
		"timing": "after production world mount and before the first capture pose",
		"node_path": str(_world.get_path_to(surface)),
		"material_instance_id": material.get_instance_id(),
		"shader_path": material.shader.resource_path if material.shader != null else "",
		"fresnel_colour": [colour.r, colour.g, colour.b, colour.a],
		"fresnel_power": float(material.get_shader_parameter("fresnel_power")),
		"fresnel_strength": float(material.get_shader_parameter("fresnel_strength")),
		"roughness_value": float(material.get_shader_parameter("roughness_value")),
		"wave_uv_scale": float(material.get_shader_parameter("wave_uv_scale")),
		"mutation_scope": "process-local parameters on the mounted WaterSurface material",
	}
	print("GULL REST FRESNEL OFF READBACK: " + JSON.stringify(_control_readback))
	return true


func _finish(extra: Dictionary) -> void:
	var evidence := extra.duplicate(true)
	evidence["water_fresnel_control"] = _control_readback.duplicate(true)
	evidence["capture_tool"] = {
		"path": TOOL_PATH,
		"sha256": FileAccess.get_file_as_string(TOOL_PATH).sha256_text(),
	}
	evidence["control_contract"] = (
		"The base tool's mounted production Water scene, five poses, player, CameraRig, " +
		"ordinary look/travel input and day/night clocks. Only Fresnel colour, power, " +
		"strength, roughness and wave UV scale use their former defaults.")
	super._finish(evidence)
