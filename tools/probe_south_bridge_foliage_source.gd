extends "res://tools/catalogue_survey.gd"

## Identifies which production foliage system draws the large near-right plant
## in the Settings catalogue's South Bridge frame. This inherits the catalogue
## survey's real scene, Game.debug_teleport_to, player, CameraRig, daylight pin,
## settling, HUD, and baseline capture. It then writes fresh diagnostic frames
## beside that retained original, disabling one foliage category at a time and
## restoring it before moving to the next. No production config or resource is
## written.

const IMPORTED_MATERIALS := preload("res://scripts/world/imported_materials.gd")
const HARVEST_NODE_SCRIPT := preload("res://scripts/world/harvest_node.gd")
const TOOL_PATH := "res://tools/probe_south_bridge_foliage_source.gd"
const BAKED_UNDERSTORY_ASSETS := [
	"Bush_Common",
	"Bush_Common_Flowers",
	"Fern_1",
	"Plant_7",
	"Plant_7_Big",
]
const BAKED_CANOPY_ASSETS := [
	"CommonTree_1",
	"CommonTree_2",
	"CommonTree_3",
	"CommonTree_4",
	"CommonTree_5",
	"CherryBlossom_3",
	"TwistedTree_2",
	"TwistedTree_4",
]
const BAKED_CANOPY_CATEGORIES := {
	"baked_common_tree_1": ["CommonTree_1"],
	"baked_common_tree_2": ["CommonTree_2"],
	"baked_common_tree_3": ["CommonTree_3"],
	"baked_common_tree_4": ["CommonTree_4"],
	"baked_common_tree_5": ["CommonTree_5"],
	"baked_cherry_blossom_3": ["CherryBlossom_3"],
	"baked_twisted_tree_2": ["TwistedTree_2"],
	"baked_twisted_tree_4": ["TwistedTree_4"],
}
const DIAGNOSTIC_CATEGORIES := [
	"field_cover_bushes",
	"baked_understory",
	"authored_props_foliage",
	"authored_harvest_foliage",
	"perimeter_foliage",
	"baked_canopy",
	"baked_common_tree_1",
	"baked_common_tree_2",
	"baked_common_tree_3",
	"baked_common_tree_4",
	"baked_common_tree_5",
	"baked_cherry_blossom_3",
	"baked_twisted_tree_2",
	"baked_twisted_tree_4",
	"all_baked_meshes",
]
const DIAGNOSTIC_SETTLE_FRAMES := 3


func _load_plan() -> bool:
	if not super._load_plan():
		return false
	if _biome_id != "meadows" or _planned.size() != 1:
		push_error("South Bridge foliage probe requires one Meadows destination")
		return false
	var row: Dictionary = _planned[0]
	if str(row.get("destination_display_name", "")) != "The South Bridge" \
			or str(row.get("time", "")) != "day":
		push_error("South Bridge foliage probe requires --subset=south_bridge --times=day")
		return false
	return true


func _capture_row(row: Dictionary) -> void:
	# The unmodified production frame remains the ordinary catalogue record.
	await super._capture_row(row)
	if _records.is_empty() or not _failures.is_empty():
		return
	var fixed_player := _player.global_transform
	var fixed_rig := _rig.global_transform
	var fixed_camera := _camera.global_transform
	var diagnostics: Array[Dictionary] = []
	for category: String in DIAGNOSTIC_CATEGORIES:
		var toggle := _disable_category(category)
		var labels: Array = toggle.get("labels", [])
		if labels.is_empty():
			_failures.append("%s: category resolved no production draw objects" % category)
			continue
		for _frame in DIAGNOSTIC_SETTLE_FRAMES:
			await process_frame
		var record := await _capture_diagnostic(row, category, labels)
		diagnostics.append(record)
		_restore_category(toggle)
		for _frame in DIAGNOSTIC_SETTLE_FRAMES:
			await process_frame
		if not _category_restored(toggle):
			_failures.append("%s: production visibility did not restore" % category)
		if not _same_transform(_player.global_transform, fixed_player) \
				or not _same_transform(_rig.global_transform, fixed_rig) \
				or not _same_transform(_camera.global_transform, fixed_camera):
			_failures.append("%s: player or production camera moved during isolation" % category)
	_manifest["foliage_source_diagnostics"] = diagnostics
	_manifest["diagnostic_frame_count"] = diagnostics.size()
	_manifest["diagnostic_contract"] = (
		"Original production catalogue frame retained; each labelled frame disables " +
		"exactly one foliage category, restores it, and keeps the same player, CameraRig, " +
		"daylight and HUD. Diagnostic isolation only; not campaign evidence.")
	_write_manifest()


func _capture_diagnostic(row: Dictionary, category: String, labels: Array) -> Dictionary:
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	var frame_id := "%s__diag_no_%s" % [str(row.frame_id), category]
	var path := "%s/%s.png" % [_output_dir, frame_id]
	var record := {
		"frame_id": frame_id,
		"file": path,
		"disabled_category": category,
		"disabled_draw_objects": labels.duplicate(),
		"player_position": _vec3(_player.global_position),
		"camera_position": _vec3(_camera.global_position),
		"camera_transform": _transform(_camera.global_transform),
	}
	if image == null or image.is_empty() or image.get_width() != root.size.x \
			or image.get_height() != root.size.y:
		_failures.append("%s: viewport image is empty or wrong-sized" % frame_id)
		return record
	if FileAccess.file_exists(path):
		_failures.append("%s: refusing to overwrite retained diagnostic frame" % frame_id)
		return record
	if image.save_png(path) != OK:
		_failures.append("%s: save_png failed" % frame_id)
		return record
	record["bytes"] = FileAccess.get_file_as_bytes(path).size()
	print("FOLIAGE SOURCE CAPTURE %s -> %s" % [frame_id, path])
	return record


func _disable_category(category: String) -> Dictionary:
	var states: Array[Dictionary] = []
	match category:
		"field_cover_bushes":
			var cover := _world.get_node_or_null(^"GrassField/Cover_bushes") as GeometryInstance3D
			if cover != null:
				_record_visible(states, cover)
		"baked_understory":
			_record_terrain_mesh_assets(states, BAKED_UNDERSTORY_ASSETS)
			_update_terrain_instances()
		"authored_props_foliage":
			_record_leaf_geometry(states, _world.get_node_or_null(^"Props"))
		"authored_harvest_foliage":
			for child: Node in _world.get_children():
				if child.get_script() == HARVEST_NODE_SCRIPT:
					_record_leaf_geometry(states, child)
		"perimeter_foliage":
			var perimeter := _world.get_node_or_null(^"WorldPerimeter")
			if perimeter != null:
				for node: Node in perimeter.find_children("*", "GeometryInstance3D", true, false):
					if str(node.name).begins_with("Hedge") or str(node.name).begins_with("Tree"):
						_record_visible(states, node as GeometryInstance3D)
		"baked_canopy":
			_record_terrain_mesh_assets(states, BAKED_CANOPY_ASSETS)
			_update_terrain_instances()
		"all_baked_meshes":
			_record_terrain_mesh_assets(states, [], true)
			_update_terrain_instances()
		_:
			if BAKED_CANOPY_CATEGORIES.has(category):
				_record_terrain_mesh_assets(states, BAKED_CANOPY_CATEGORIES[category])
				_update_terrain_instances()
	var labels: Array[String] = []
	for state: Dictionary in states:
		labels.append(str(state.label))
	return {"category": category, "states": states, "labels": labels}


func _record_terrain_mesh_assets(states: Array[Dictionary], asset_names: Array,
		all_assets := false) -> void:
	var terrain := _world.get_node_or_null(^"Terrain")
	if terrain == null or not terrain.has_method("get_assets"):
		return
	var assets: Object = terrain.call("get_assets")
	if assets == null or not assets.has_method("get_mesh_list"):
		return
	for asset: Object in (assets.call("get_mesh_list") as Array):
		if asset == null or not asset.has_method("is_enabled") \
				or not asset.has_method("set_enabled"):
			continue
		var asset_name := str(asset.get("name"))
		if not all_assets and asset_name not in asset_names:
			continue
		# Disabled assets do not currently draw and therefore are not evidence for
		# a source-isolation frame. Record only live production mesh assets.
		if not bool(asset.call("is_enabled")):
			continue
		states.append({"object": asset, "kind": "enabled", "before": true,
			"label": "Terrain3DMeshAsset/%s" % asset_name})
		asset.call("set_enabled", false)


func _record_leaf_geometry(states: Array[Dictionary], under: Node) -> void:
	if under == null:
		return
	if under is MeshInstance3D and _mesh_has_thin_foliage(under as MeshInstance3D):
		_record_visible(states, under as MeshInstance3D)
	for node: Node in under.find_children("*", "MeshInstance3D", true, false):
		var mesh_instance := node as MeshInstance3D
		if _mesh_has_thin_foliage(mesh_instance):
			_record_visible(states, mesh_instance)


func _mesh_has_thin_foliage(instance: MeshInstance3D) -> bool:
	if instance.mesh == null:
		return false
	for surface in instance.mesh.get_surface_count():
		var material := instance.get_active_material(surface)
		if material != null and IMPORTED_MATERIALS.is_thin_foliage_material(
				material.resource_name):
			return true
	return false


func _record_visible(states: Array[Dictionary], node: GeometryInstance3D) -> void:
	states.append({"object": node, "kind": "visible", "before": node.visible,
		"label": str(_world.get_path_to(node))})
	node.visible = false


func _restore_category(toggle: Dictionary) -> void:
	for state: Dictionary in toggle.get("states", []):
		var object: Object = state.get("object")
		if object == null or not is_instance_valid(object):
			continue
		if str(state.kind) == "enabled":
			object.call("set_enabled", bool(state.before))
		else:
			(object as GeometryInstance3D).visible = bool(state.before)
	if _is_baked_mesh_category(str(toggle.get("category", ""))):
		_update_terrain_instances()


func _category_restored(toggle: Dictionary) -> bool:
	for state: Dictionary in toggle.get("states", []):
		var object: Object = state.get("object")
		if object == null or not is_instance_valid(object):
			return false
		if str(state.kind) == "enabled":
			if bool(object.call("is_enabled")) != bool(state.before):
				return false
		elif (object as GeometryInstance3D).visible != bool(state.before):
			return false
	return true


func _update_terrain_instances() -> void:
	var terrain := _world.get_node_or_null(^"Terrain")
	if terrain == null or not terrain.has_method("get_instancer"):
		return
	var instancer: Object = terrain.call("get_instancer")
	if instancer != null and instancer.has_method("update_mmis"):
		instancer.call("update_mmis", true)


func _is_baked_mesh_category(category: String) -> bool:
	return category == "baked_understory" or category == "baked_canopy" \
		or category == "all_baked_meshes" or BAKED_CANOPY_CATEGORIES.has(category)


func _same_transform(a: Transform3D, b: Transform3D) -> bool:
	return a.origin.is_equal_approx(b.origin) \
		and a.basis.x.is_equal_approx(b.basis.x) \
		and a.basis.y.is_equal_approx(b.basis.y) \
		and a.basis.z.is_equal_approx(b.basis.z)


func _write_manifest() -> void:
	_manifest["capture_tool"] = {
		"path": TOOL_PATH,
		"sha256": FileAccess.get_file_as_string(TOOL_PATH).sha256_text(),
	}
	super._write_manifest()
