extends Node3D

## Deterministic scenic cover for the Water archipelago. It deliberately owns
## no collision or harvest state: island routes and encounters keep using the
## authored Terrain3D surface while clustered foliage supplies scale, depth and
## regional identity. Every accepted point comes from the same heightfield the
## committed terrain bake uses.
const CONFIG_PATH := "res://data/config/water_vegetation.json"
const CAMP_CONFIG_PATH := "res://data/config/water_camps.json"
const CHARACTER_CONFIG_PATH := "res://data/config/water_characters.json"
const ENCOUNTER_CONFIG_PATH := "res://data/config/water_encounters.json"
const MAX_ATTEMPTS_PER_POINT := 12
const IMPORTED_MATERIALS := preload("res://scripts/world/imported_materials.gd")

var placed_by_layer: Dictionary = {}
var placed_by_island: Dictionary = {}
var rendered_by_model: Dictionary = {}
var rendered_by_island_layer: Dictionary = {}
var material_textures: Dictionary = {}
var visibility_cells: Array[Dictionary] = []
var _prepared_meshes: Dictionary = {}
var _world_config: Dictionary
var _rules: Dictionary
var _field: RefCounted
var _exclusion_points: Array[Dictionary] = []
var _route_segments: Array[Dictionary] = []


func build(world_config: Dictionary, field: RefCounted) -> void:
	_world_config = world_config
	_field = field
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(CONFIG_PATH))
	if not parsed is Dictionary or _field == null:
		push_error("Water vegetation needs valid rules and the Water heightfield")
		return
	_rules = parsed
	_compile_exclusions()
	var batches: Dictionary = {}
	for island: Dictionary in _world_config.get("islands", []):
		_place_island(island, batches)
	for batch_key: String in batches:
		var batch: Dictionary = batches[batch_key]
		_build_batch(str(batch.model), str(batch.label), batch.origin, batch.placements)
	_prepared_meshes.clear()
	print("[water vegetation] %d instances in %d model batches; layers=%s islands=%s" % [
		_total_placed(), batches.size(), JSON.stringify(placed_by_layer),
		JSON.stringify(placed_by_island)])


## Veilfall's radial mountain has almost no naturally flat samples. Its exterior
## presentation supplies explicit points on authored geological caps through
## this same batching/material path, so the installed foliage remains one Water
## family and still uses local visibility cells. The caller owns support proof.
func add_authored_placements(placements: Array[Dictionary]) -> void:
	var batches: Dictionary = {}
	for raw: Dictionary in placements:
		var model_path := str(raw.get("model", ""))
		var position: Vector3 = raw.get("position", Vector3.INF)
		if model_path.is_empty() or not position.is_finite():
			push_warning("Water authored vegetation skipped an invalid placement")
			continue
		_append_batch(batches, model_path, str(raw.get("island_id", "veilfall")), position, {
			"position": position,
			"normal": raw.get("normal", Vector3.UP),
			"yaw": float(raw.get("yaw", 0.0)),
			"scale": float(raw.get("scale", 1.0)),
			"align_to_slope": bool(raw.get("align_to_slope", false)),
			"visibility_range_m": float(raw.get("visibility_range_m", 720.0)),
			"layer": str(raw.get("layer", "authored_grove")),
			"island_id": str(raw.get("island_id", "veilfall")),
		})
	for batch_key: String in batches:
		var batch: Dictionary = batches[batch_key]
		_build_batch(str(batch.model), str(batch.label), batch.origin, batch.placements)
	_prepared_meshes.clear()


func _compile_exclusions() -> void:
	var landmark_clearance := float(_rules.get("landmark_clearance_m", 13.0))
	var island_centres: Dictionary = {}
	for island: Dictionary in _world_config.get("islands", []):
		var centre: Array = island.get("center_xz_m", [])
		if centre.size() == 2:
			island_centres[str(island.get("id", ""))] = Vector2(float(centre[0]), float(centre[1]))
	for anchor: Dictionary in _world_config.get("anchors", []):
		var raw: Array = anchor.get("safe_position", [])
		if raw.size() >= 3:
			_exclusion_points.append({"at": Vector2(float(raw[0]), float(raw[2])),
				"radius": maxf(landmark_clearance, float(anchor.get("scatter_clear_radius_m", 0.0)))})
	for landmark: Dictionary in _world_config.get("landmarks", []):
		var raw: Array = landmark.get("position", [])
		if raw.size() >= 3:
			_exclusion_points.append({"at": Vector2(float(raw[0]), float(raw[2])), "radius": landmark_clearance})
	var camp_config := _read_dictionary(CAMP_CONFIG_PATH)
	var camp_clearance := float(_rules.get("camp_clearance_m", 10.0))
	for camp: Dictionary in camp_config.get("camps", []):
		var raw: Array = camp.get("at", [])
		if raw.size() == 2:
			_exclusion_points.append({"at": Vector2(float(raw[0]), float(raw[1])), "radius": camp_clearance})
	var character_config := _read_dictionary(CHARACTER_CONFIG_PATH)
	var npc_clearance := float(_rules.get("npc_clearance_m", 7.0))
	for collection: String in ["npcs", "trainers"]:
		for character: Dictionary in character_config.get(collection, []):
			var island_id := str(character.get("island_id", ""))
			var offset: Array = character.get("island_local_offset", [])
			if island_centres.has(island_id) and offset.size() >= 3:
				_exclusion_points.append({"at": island_centres[island_id] + Vector2(float(offset[0]), float(offset[2])),
					"radius": npc_clearance})
	var encounter_config := _read_dictionary(ENCOUNTER_CONFIG_PATH)
	var encounter_clearance := float(_rules.get("encounter_clearance_m", 4.5))
	for collection: String in ["wild_sites", "named_encounters", "scripted_encounter_references"]:
		for encounter: Dictionary in encounter_config.get(collection, []):
			var raw: Array = encounter.get("position", [])
			if raw.size() >= 3:
				_exclusion_points.append({"at": Vector2(float(raw[0]), float(raw[2])),
					"radius": encounter_clearance})
	var route_clearance := float(_rules.get("route_clearance_m", 8.0))
	for route: Dictionary in _world_config.get("land_routes", []):
		var points: Array = route.get("polyline", [])
		for index in maxi(0, points.size() - 1):
			var a: Array = points[index]
			var b: Array = points[index + 1]
			_route_segments.append({"a": Vector2(float(a[0]), float(a[2])),
				"b": Vector2(float(b[0]), float(b[2])), "radius": route_clearance})


func _place_island(island: Dictionary, by_model: Dictionary) -> void:
	var centre_raw: Array = island.get("center_xz_m", [])
	var radius := float(island.get("shore_radius_m", 0.0))
	if centre_raw.size() != 2 or radius <= 0.0:
		return
	var island_id := str(island.get("id", ""))
	var centre := Vector2(float(centre_raw[0]), float(centre_raw[1]))
	var profile := str((_rules.get("island_profiles", {}) as Dictionary).get(island_id, "green"))
	var layers: Dictionary = _rules.get("layers", {})
	for layer_name: String in layers:
		var layer: Dictionary = layers[layer_name]
		var profile_scale := float((layer.get("profile_scale", {}) as Dictionary).get(profile, 1.0))
		layer = layer.duplicate()
		layer["max_slope_deg"] = float((layer.get("profile_max_slope_deg", {}) as Dictionary).get(
			profile, layer.get("max_slope_deg", 30.0)))
		var area_scale := clampf(radius / 180.0, 0.55, 1.75)
		var cluster_count := maxi(1, roundi(float(layer.get("clusters", 1)) * profile_scale * area_scale))
		var rng := RandomNumberGenerator.new()
		rng.seed = int(island.get("scatter_seed", 1)) + abs(hash(layer_name))
		for _cluster in cluster_count:
			var cluster := _sample_cluster_centre(rng, centre, radius, layer)
			if not cluster.valid:
				continue
			var count_range: Array = layer.get("per_cluster", [1, 1])
			var amount := rng.randi_range(int(count_range[0]), int(count_range[1]))
			var spread_range: Array = layer.get("cluster_radius_m", [1.0, 1.0])
			var spread := rng.randf_range(float(spread_range[0]), float(spread_range[1]))
			for _member in amount:
				var point := _sample_member(rng, cluster.point, spread, centre, radius, layer)
				if not point.valid:
					continue
				var models: Array = layer.get("models", [])
				if models.is_empty():
					continue
				var model_path := str(models[rng.randi_range(0, models.size() - 1)])
				var scale_range: Array = layer.get("scale", [1.0, 1.0])
				var model_scale := float((layer.get("model_scale", {}) as Dictionary).get(model_path, 1.0))
				_append_batch(by_model, model_path, island_id, point.position, {
					"position": point.position,
					"normal": point.normal,
					"yaw": rng.randf_range(-PI, PI),
					"scale": rng.randf_range(float(scale_range[0]), float(scale_range[1])) * model_scale,
					"align_to_slope": bool(layer.get("align_to_slope", false)),
					"visibility_range_m": float(layer.get("visibility_range_m", 250.0)),
					"layer": layer_name,
					"island_id": island_id,
				})


func _append_batch(batches: Dictionary, model_path: String, island_id: String,
		position: Vector3, placement: Dictionary) -> void:
	var batch_cell := float(_rules.get("batch_cell_m", 96.0))
	var cell := Vector2i(floori(position.x / batch_cell), floori(position.z / batch_cell))
	var batch_key := "%s::%d:%d::%s" % [island_id, cell.x, cell.y, model_path]
	if not batches.has(batch_key):
		batches[batch_key] = {"model": model_path,
			"label": "%s_%d_%d" % [island_id, cell.x, cell.y],
			"origin": Vector3((cell.x + 0.5) * batch_cell, 0.0, (cell.y + 0.5) * batch_cell),
			"placements": []}
	((batches[batch_key] as Dictionary).placements as Array).append(placement)


func _sample_cluster_centre(rng: RandomNumberGenerator, centre: Vector2, radius: float,
		layer: Dictionary) -> Dictionary:
	for _attempt in MAX_ATTEMPTS_PER_POINT:
		var angle := rng.randf_range(-PI, PI)
		var radial := radius * sqrt(rng.randf_range(0.04, 0.72))
		var point := centre + Vector2(cos(angle), sin(angle)) * radial
		var accepted := _accept(point, centre, radius, layer)
		if bool(accepted.get("valid", false)):
			return {"valid": true, "point": point}
	return {"valid": false}


func _sample_member(rng: RandomNumberGenerator, cluster: Vector2, spread: float,
		centre: Vector2, radius: float, layer: Dictionary) -> Dictionary:
	for _attempt in MAX_ATTEMPTS_PER_POINT:
		var angle := rng.randf_range(-PI, PI)
		var point := cluster + Vector2(cos(angle), sin(angle)) * spread * sqrt(rng.randf())
		var accepted := _accept(point, centre, radius, layer)
		if bool(accepted.get("valid", false)):
			return accepted
	return {"valid": false}


func _accept(point: Vector2, centre: Vector2, radius: float, layer: Dictionary) -> Dictionary:
	if point.distance_to(centre) > radius - float(_rules.get("shore_margin_m", 10.0)):
		return {"valid": false}
	for exclusion: Dictionary in _exclusion_points:
		if point.distance_to(exclusion.at) < float(exclusion.radius):
			return {"valid": false}
	for segment: Dictionary in _route_segments:
		if point.distance_to(Geometry2D.get_closest_point_to_segment(point, segment.a, segment.b)) < float(segment.radius):
			return {"valid": false}
	var height := float(_field.call("height_at", point.x, point.y))
	if not is_finite(height) or height < float(layer.get("min_height_m", 1.0)):
		return {"valid": false}
	var normal := Vector3.UP
	if _field.has_method("normal_at"):
		normal = _field.call("normal_at", point.x, point.y, 1.5)
	var slope := rad_to_deg(acos(clampf(normal.y, -1.0, 1.0)))
	if slope > float(layer.get("max_slope_deg", 30.0)):
		return {"valid": false}
	return {"valid": true, "position": Vector3(point.x, height - 0.04, point.y), "normal": normal}


func _build_batch(model_path: String, batch_label: String, origin: Vector3, placements: Array) -> void:
	if placements.is_empty() or not ResourceLoader.exists(model_path):
		if not placements.is_empty():
			push_warning("Water vegetation skipped missing model: " + model_path)
		return
	var mesh_instances: Array[Dictionary] = _prepared_meshes_for(model_path)
	if mesh_instances.is_empty():
		return
	for source_mesh: Dictionary in mesh_instances:
		var batch := MultiMeshInstance3D.new()
		batch.name = "%s_%s_%s" % [batch_label, model_path.get_file().get_basename(), source_mesh.name]
		var multi := MultiMesh.new()
		multi.transform_format = MultiMesh.TRANSFORM_3D
		multi.mesh = source_mesh.mesh
		multi.instance_count = placements.size()
		for index in placements.size():
			var placement: Dictionary = placements[index]
			var basis := Basis(Vector3.UP, float(placement.yaw))
			if bool(placement.align_to_slope):
				basis = Basis(Quaternion(Vector3.UP, placement.normal)) * basis
			basis = basis.scaled(Vector3.ONE * float(placement.scale))
			multi.set_instance_transform(index,
				Transform3D(basis, placement.position - origin) * (source_mesh.transform as Transform3D))
		batch.multimesh = multi
		batch.position = origin
		batch.visibility_range_end = float((placements[0] as Dictionary).visibility_range_m)
		batch.visibility_range_end_margin = minf(80.0, batch.visibility_range_end * 0.2)
		batch.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_SELF
		add_child(batch)
	visibility_cells.append({"label": batch_label, "origin": [origin.x, origin.y, origin.z],
		"model": model_path, "instances": placements.size(),
		"visibility_range_m": float((placements[0] as Dictionary).visibility_range_m),
		"mesh_surfaces": mesh_instances.size()})
	for placement: Dictionary in placements:
		var layer_name := str(placement.layer)
		var island_id := str(placement.island_id)
		placed_by_layer[layer_name] = int(placed_by_layer.get(layer_name, 0)) + 1
		placed_by_island[island_id] = int(placed_by_island.get(island_id, 0)) + 1
		var island_layer := "%s/%s" % [island_id, layer_name]
		rendered_by_island_layer[island_layer] = int(rendered_by_island_layer.get(island_layer, 0)) + 1
	rendered_by_model[model_path] = int(rendered_by_model.get(model_path, 0)) + placements.size()


func _prepared_meshes_for(model_path: String) -> Array[Dictionary]:
	if _prepared_meshes.has(model_path):
		return _prepared_meshes[model_path]
	var packed := load(model_path) as PackedScene
	if packed == null:
		push_warning("Water vegetation model could not be loaded: " + model_path)
		_prepared_meshes[model_path] = []
		return []
	var source := packed.instantiate()
	var mesh_instances: Array[Dictionary] = []
	_collect_meshes(source, Transform3D.IDENTITY, model_path, mesh_instances)
	source.free()
	_prepared_meshes[model_path] = mesh_instances
	return mesh_instances


func _collect_meshes(node: Node, parent_transform: Transform3D, model_path: String,
		into: Array[Dictionary]) -> void:
	var relative := parent_transform
	if node is Node3D:
		relative = parent_transform * (node as Node3D).transform
	if node is MeshInstance3D and (node as MeshInstance3D).mesh != null:
		var source := node as MeshInstance3D
		into.append({"name": str(source.name), "mesh": _presentation_mesh(source, model_path),
			"transform": relative})
	for child: Node in node.get_children():
		_collect_meshes(child, relative, model_path, into)


func _presentation_mesh(source: MeshInstance3D, model_path: String) -> Mesh:
	var mesh := source.mesh.duplicate(true) as Mesh
	for surface in mesh.get_surface_count():
		var material: Material = source.material_override
		if material == null:
			material = source.get_surface_override_material(surface)
		if material == null:
			material = mesh.surface_get_material(surface)
		if material == null:
			continue
		var prepared := material.duplicate(true) as Material
		if prepared is StandardMaterial3D:
			var standard := prepared as StandardMaterial3D
			if standard.resource_name in ["Leaves_NormalTree", "Leaves_TwistedTree"]:
				var leaf_path := "res://assets/environment/stylized_nature/derived/Leaves_NormalTree_C_desat55_b100.png" \
					if model_path.contains("Bush_Common") else \
					"res://assets/environment/stylized_nature/derived/Leaves_NormalTree_C_desat55.png"
				standard.albedo_texture = load(leaf_path) as Texture2D
				standard.albedo_color = Color("79a76f") if model_path.contains("Bush_Common") else Color("8fb77d")
			elif standard.resource_name == "Flowers":
				standard.albedo_color = Color("bca6cb")
			IMPORTED_MATERIALS.apply_thin_foliage_backlight(standard.resource_name, standard)
			material_textures["%s|%s" % [model_path, standard.resource_name]] = \
				standard.albedo_texture.resource_path if standard.albedo_texture != null else ""
		mesh.surface_set_material(surface, prepared)
	return mesh


func _total_placed() -> int:
	var total := 0
	for count: int in placed_by_layer.values():
		total += count
	return total


func _read_dictionary(path: String) -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not parsed is Dictionary:
		push_error("Water vegetation could not parse exclusion source: " + path)
		return {}
	return parsed


func diagnostic_receipt() -> Dictionary:
	return {
		"total_instances": _total_placed(),
		"model_counts": rendered_by_model.duplicate(true),
		"layer_counts": placed_by_layer.duplicate(true),
		"island_counts": placed_by_island.duplicate(true),
		"island_layer_counts": rendered_by_island_layer.duplicate(true),
		"visibility_cells": visibility_cells.duplicate(true),
		"material_textures": material_textures.duplicate(true),
		"exclusion_point_count": _exclusion_points.size(),
		"route_segment_count": _route_segments.size(),
	}
