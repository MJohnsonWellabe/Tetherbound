extends "res://tools/_capture_water_gull_rest_signal_site.gd"

## Matched OFF control for the production Water horizon correction. After the
## production world mounts, this restores only the former finite plane, wrapped
## outside-region depth lookup, and Terrain3D FLAT background for every frame.

const TOOL_PATH := "res://tools/probe_water_horizon_off_control.gd"

var _control_bound := false
var _surface: MeshInstance3D
var _terrain_material: Object
var _production_mesh: PlaneMesh
var _production_material: ShaderMaterial
var _production_background := 0
var _control_receipt: Dictionary = {}


func _capture(frame_id: String, movement: String, preset: String, observed: Dictionary,
		extra: Dictionary = {}, require_signal_site: bool = true) -> void:
	if not _control_bound:
		if not _bind_off_control():
			return
	var evidence := extra.duplicate(true)
	evidence["water_horizon_off_control"] = true
	await super._capture(frame_id, movement, preset, observed, evidence, require_signal_site)


func _bind_off_control() -> bool:
	_surface = _world.get_node_or_null(^"WaterSurface") as MeshInstance3D
	var terrain := _world.get_node_or_null(^"Terrain")
	if _surface == null or not _surface.mesh is PlaneMesh \
			or not _surface.material_override is ShaderMaterial or terrain == null:
		_fail("Water horizon OFF control found no mounted surface/terrain bindings")
		return false
	_terrain_material = terrain.get("material")
	if _terrain_material == null:
		_fail("Water horizon OFF control found no mounted Terrain3D material")
		return false
	_production_mesh = _surface.mesh as PlaneMesh
	_production_material = _surface.material_override as ShaderMaterial
	_production_background = int(_terrain_material.get("world_background"))
	var region: Vector4 = _production_material.get_shader_parameter("region")
	var control_mesh := _production_mesh.duplicate(true) as PlaneMesh
	control_mesh.size = Vector2(region.z, region.w)
	var control_material := _production_material.duplicate(false) as ShaderMaterial
	control_material.set_shader_parameter("outside_region_deep_water", false)
	_terrain_material.set("world_background", int(Terrain3DMaterial.WorldBackground.FLAT))
	_surface.mesh = control_mesh
	_surface.material_override = control_material
	_control_bound = true
	_control_receipt = {
		"production_plane_size": [_production_mesh.size.x, _production_mesh.size.y],
		"control_plane_size": [control_mesh.size.x, control_mesh.size.y],
		"height_region": [region.x, region.y, region.z, region.w],
		"production_world_background": _production_background,
		"control_world_background": int(_terrain_material.get("world_background")),
		"control_outside_region_deep_water": control_material.get_shader_parameter(
				"outside_region_deep_water"),
		"gameplay_mutation": false,
	}
	print("WATER HORIZON OFF CONTROL: " + JSON.stringify(_control_receipt))
	return true


func _finish(extra: Dictionary) -> void:
	if _control_bound:
		_surface.mesh = _production_mesh
		_surface.material_override = _production_material
		_terrain_material.set("world_background", _production_background)
		_control_receipt["restored_production_bindings"] = \
				_surface.mesh == _production_mesh \
				and _surface.material_override == _production_material \
				and int(_terrain_material.get("world_background")) == _production_background
	var evidence := extra.duplicate(true)
	evidence["water_horizon_off_control"] = _control_receipt.duplicate(true)
	evidence["capture_tool"] = {"path": TOOL_PATH,
		"sha256": FileAccess.get_file_as_string(TOOL_PATH).sha256_text()}
	super._finish(evidence)
