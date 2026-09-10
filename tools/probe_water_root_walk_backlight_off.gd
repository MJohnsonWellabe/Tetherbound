extends "res://tools/catalogue_survey.gd"

## Matched control for FOLIAGE-BACKLIGHT01 at the production Water catalogue's
## Reedhaven Root Walk. The helper cache is pinned to zero before the production
## world is loaded, so ordinary material construction follows the same call graph
## but leaves StandardMaterial3D backlight disabled. Production config and
## resources are never written.

const IMPORTED_MATERIALS := preload("res://scripts/world/imported_materials.gd")
const TOOL_PATH := "res://tools/probe_water_root_walk_backlight_off.gd"


func _load_plan() -> bool:
	if not super._load_plan():
		return false
	if _biome_id != "water" or _planned.size() != 1:
		push_error("Water backlight control requires one Water destination")
		return false
	var row: Dictionary = _planned[0]
	if str(row.get("destination_display_name", "")) != "Reedhaven Root Walk" \
			or str(row.get("time", "")) != "day":
		push_error("Water backlight control requires --subset=root_walk --times=day")
		return false
	return true


func _mount_production_world() -> bool:
	# This assignment must precede PackedScene load/instantiation: WaterVegetation
	# prepares and caches its imported materials while the production world builds.
	IMPORTED_MATERIALS._foliage_backlight_strength = 0.0
	_manifest["foliage_backlight_control"] = {
		"requested_strength": 0.0,
		"helper_cached_strength_before_world_load":
			IMPORTED_MATERIALS._foliage_backlight_strength,
		"timing": "set before production PackedScene load and instantiation",
	}
	var mounted := await super._mount_production_world()
	if not mounted:
		return false
	var audit := _audit_bound_thin_foliage_materials()
	var control: Dictionary = _manifest["foliage_backlight_control"]
	control.merge(audit, true)
	_manifest["foliage_backlight_control"] = control
	if int(audit.get("thin_foliage_surface_count", 0)) <= 0:
		_failures.append("backlight control found no bound thin-foliage surfaces")
	if int(audit.get("backlight_enabled_surface_count", 0)) != 0:
		_failures.append("backlight control left a bound thin-foliage surface enabled")
	_write_manifest()
	return _failures.is_empty()


func _audit_bound_thin_foliage_materials() -> Dictionary:
	var records: Array[Dictionary] = []
	var seen: Dictionary = {}
	for node: Node in _world.find_children("*", "MeshInstance3D", true, false):
		var instance := node as MeshInstance3D
		if instance.mesh != null:
			_audit_mesh(instance.mesh, str(_world.get_path_to(instance)), records, seen)
	for node: Node in _world.find_children("*", "MultiMeshInstance3D", true, false):
		var instance := node as MultiMeshInstance3D
		if instance.multimesh != null and instance.multimesh.mesh != null:
			_audit_mesh(instance.multimesh.mesh, str(_world.get_path_to(instance)), records, seen)
	var enabled_count := 0
	for record: Dictionary in records:
		if bool(record.get("backlight_enabled", false)):
			enabled_count += 1
	return {
		"helper_cached_strength_after_world_load":
			IMPORTED_MATERIALS._foliage_backlight_strength,
		"thin_foliage_surface_count": records.size(),
		"backlight_enabled_surface_count": enabled_count,
		"bound_thin_foliage_materials": records,
	}


func _audit_mesh(mesh: Mesh, owner_path: String, records: Array[Dictionary],
		seen: Dictionary) -> void:
	for surface in mesh.get_surface_count():
		var material := mesh.surface_get_material(surface) as BaseMaterial3D
		if material == null or not IMPORTED_MATERIALS.is_thin_foliage_material(
				material.resource_name):
			continue
		var identity := material.get_instance_id()
		if seen.has(identity):
			continue
		seen[identity] = true
		records.append({
			"owner_path": owner_path,
			"material_name": material.resource_name,
			"backlight_enabled": material.backlight_enabled,
			"backlight": [material.backlight.r, material.backlight.g,
				material.backlight.b, material.backlight.a],
		})


func _write_manifest() -> void:
	_manifest["capture_tool"] = {
		"path": TOOL_PATH,
		"sha256": FileAccess.get_file_as_string(TOOL_PATH).sha256_text(),
	}
	_manifest["control_contract"] = (
		"Exact production Water scene, Game.debug_teleport_to, player, CameraRig, " +
		"daylight and HUD. Only the imported-material helper's process-local cached " +
		"foliage backlight strength is pinned to zero before world load. Production " +
		"configuration remains unchanged.")
	super._write_manifest()
