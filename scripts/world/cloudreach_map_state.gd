extends "res://autoload/map_state.gd"

## Same production MapState API and discovery payload, but instance-owned realm
## extent and 3D discovery. Never mutates Meadows' static grid/cache or save.
var _bounds: Dictionary = {}
var _cell := 8.0
var _world_data: Dictionary = {}
var _chapter_data: Dictionary = {}
var _progression: RefCounted
var _flags_revision := -1
var _discovery_radius := 35.0
var _height_tolerance := 12.0
var _terrain: Texture2D


func configure_cloudreach(world: Dictionary, chapter: Dictionary, progression: RefCounted) -> void:
	_world_data = world
	_chapter_data = chapter
	_progression = progression
	_flags_revision = -1
	_terrain = null
	var tuning: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/cloudreach_atmosphere.json"))
	_cell = maxf(1.0, float(tuning.get("map_cell_m", 8.0)))
	_discovery_radius = float(tuning.get("landmark_discovery_radius_m", 35.0))
	_height_tolerance = float(tuning.get("landmark_height_tolerance_m", 12.0))
	_bounds = world.get("realm", {}).get("world_bounds", {})
	var definitions: Array = []
	for landmark: Dictionary in world.get("landmarks", []):
		var entry := landmark.duplicate(true)
		var at: Array = entry["position"]
		entry["position"] = [at[0], at[2]]
		entry["discover_radius"] = 0.0
		entry["silhouette"] = false
		definitions.append(entry)
	configure({"landmarks": definitions, "regions": [], "minimap_span_m": 160.0})
	_visited.resize(cell_grid_x() * cell_grid_z())
	_visited.fill(0)
	_visited_count = 0
	_mark_fog_dirty_all()
	for region: Dictionary in world.get("regions", []):
		var at: Array = region["position"]
		_region_defs[str(region["id"])] = {"display_name": region["display_name"],
			"centre": Vector2(float(at[0]), float(at[2])), "radius": 150.0}


func world_bounds() -> Dictionary:
	return _bounds.duplicate()


func map_display_name() -> String:
	return "Cloudreach Cliffs"


func cell_grid_x() -> int:
	return maxi(1, ceili((float(_bounds.get("max_x", 1600)) - float(_bounds.get("min_x", -1600))) / _cell))


func cell_grid_z() -> int:
	return maxi(1, ceili((float(_bounds.get("max_z", 6000)) - float(_bounds.get("min_z", -500))) / _cell))


func cell_size() -> float:
	return _cell


func world_to_cell(at: Vector3) -> Vector2i:
	return Vector2i(floori((at.x - float(_bounds.get("min_x", -1600))) / _cell),
		floori((at.z - float(_bounds.get("min_z", -500))) / _cell))


func cell_at(x: int, z: int) -> bool:
	return x >= 0 and z >= 0 and x < cell_grid_x() and z < cell_grid_z() \
		and _visited[z * cell_grid_x() + x] == 1


func is_discovered(at: Vector3) -> bool:
	var cell := world_to_cell(at)
	return cell_at(cell.x, cell.y)


func discovered_fraction() -> float:
	return float(_visited_count) / maxf(1, _visited.size())


func _reveal_cells(at: Vector3, radius: float) -> bool:
	var centre := world_to_cell(at)
	var reach := ceili(radius / _cell)
	var changed := false
	for z in range(maxi(0, centre.y - reach), mini(cell_grid_z(), centre.y + reach + 1)):
		for x in range(maxi(0, centre.x - reach), mini(cell_grid_x(), centre.x + reach + 1)):
			var index := z * cell_grid_x() + x
			if index >= _visited.size() or _visited[index] != 0:
				continue
			var point := Vector2(float(_bounds.get("min_x", -1600)) + (x + 0.5) * _cell,
				float(_bounds.get("min_z", -500)) + (z + 0.5) * _cell)
			if point.distance_to(Vector2(at.x, at.z)) > radius:
				continue
			_visited[index] = 1
			_visited_count += 1
			_mark_fog_dirty(x, z)
			changed = true
	return changed


static func region_at(world: Dictionary, at: Vector3) -> String:
	var best := ""
	var distance := INF
	for region: Dictionary in world.get("regions", []):
		var b: Dictionary = region["bounds"]
		if at.x < float(b["min_x"]) or at.x > float(b["max_x"]) \
				or at.y < float(b["min_y"]) or at.y > float(b["max_y"]) \
				or at.z < float(b["min_z"]) or at.z > float(b["max_z"]):
			continue
		var p: Array = region["position"]
		var candidate := Vector3(float(p[0]), float(p[1]), float(p[2])).distance_squared_to(at)
		if candidate < distance:
			distance = candidate
			best = str(region["id"])
	return best


func update_region(at: Vector3) -> void:
	var id := region_at(_world_data, at)
	for entry: Dictionary in _world_data.get("regions", []):
		if str(entry["id"]) == id and not _has(str(entry.get("access", {}).get("requires_unlock", ""))):
			id = ""
	if id == _current_region_id:
		return
	_current_region_id = id
	if not id.is_empty() and not _discovered_regions.has(id):
		_discovered_regions[id] = true
		_pending_region_announcement = str(_region_defs[id]["display_name"])
		revision += 1


func regions() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for entry: Dictionary in super.regions():
		for authored: Dictionary in _world_data.get("regions", []):
			if authored["id"] == entry["id"] and _has(str(authored.get("access", {}).get("requires_unlock", ""))):
				out.append(entry)
	return out


## Optional world map_terrain_texture() hook can return this cached actual
## Cloudreach height survey to both existing map widgets. Map art is top-down,
## so the highest surface is intentional here, unlike creature/throw seating.
func bake_terrain(world: Node) -> Texture2D:
	if _terrain != null:
		return _terrain
	if world == null or not world.has_method("ground_height_at"):
		return null
	var width := 160
	var height := 325
	var image := Image.create(width, height, false, Image.FORMAT_RGB8)
	for z in height:
		for x in width:
			var wx := lerpf(float(_bounds["min_x"]), float(_bounds["max_x"]), (x + 0.5) / width)
			var wz := lerpf(float(_bounds["min_z"]), float(_bounds["max_z"]), (z + 0.5) / height)
			var ground := float(world.call("ground_height_at", wx, wz))
			var color := Color("94b8c3") if is_nan(ground) else Color("60875a").lerp(Color("d0bd8f"), clampf(ground / 1500.0, 0, 1))
			image.set_pixel(x, z, color)
	_terrain = ImageTexture.create_from_image(image)
	return _terrain


func _has(flag: String) -> bool:
	return flag.is_empty() or (_progression != null and bool(_progression.call("has", flag)))


func _allowed(id: String) -> bool:
	if id == "waterward_overlook":
		return _has("captain_veyra_defeated") and _has("cloudreach_winds_restored") and _has("waterward_route_revealed")
	for entry: Dictionary in _world_data.get("landmarks", []):
		if str(entry["id"]) == id:
			return _has(str(entry.get("requires_unlock", "")))
	return false


func landmarks() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for entry: Dictionary in super.landmarks():
		if bool(entry.get("dynamic", false)) or _allowed(str(entry["id"])):
			out.append(entry)
	return out


func discover_landmark(id: String) -> bool:
	return super.discover_landmark(id) if _allowed(id) else false


func _discover_landmarks_near(at: Vector3) -> bool:
	var changed := false
	for entry: Dictionary in _world_data.get("landmarks", []):
		var p: Array = entry["position"]
		var offset := at - Vector3(float(p[0]), float(p[1]), float(p[2]))
		if Vector2(offset.x, offset.z).length() <= _discovery_radius and absf(offset.y) <= _height_tolerance:
			changed = discover_landmark(str(entry["id"])) or changed
	return changed


func sync_navigation(progression: RefCounted, at: Vector3) -> void:
	_progression = progression
	if progression != null and int(progression.get("revision")) != _flags_revision:
		_flags_revision = int(progression.get("revision"))
		revision += 1
	update_region(at)
	var navigation: Dictionary = _chapter_data.get("map_navigation", {})
	for entry: Dictionary in navigation.get("region_landmarks", []):
		var event := str(entry["unlock_event"])
		if (event == "region_entered" and _discovered_regions.has(str(entry["region_id"]))) \
				or (event != "region_entered" and _has(event)):
			discover_landmark(str(entry["landmark_id"]))
	for entry: Dictionary in navigation.get("unlock_events", []):
		if _has(str(entry["flag_id"])):
			for id: String in entry.get("reveals_landmark_ids", []):
				discover_landmark(id)


func reveal_all() -> void:
	_visited.fill(1)
	_visited_count = _visited.size()
	for id: String in _landmark_defs:
		discover_landmark(id)
	_mark_fog_dirty_all()
	revision += 1


func save_data() -> Dictionary:
	var data := super.save_data()
	data.merge({"realm_id": "cloudreach", "grid_x": cell_grid_x(), "grid_z": cell_grid_z(),
		"cell": _cell, "origin_x": _bounds.get("min_x", -1600), "origin_z": _bounds.get("min_z", -500)}, true)
	return data


func load_data(data: Dictionary) -> void:
	_discovered.clear()
	_discovered_regions.clear()
	_dynamic.clear()
	_visited.fill(0)
	_visited_count = 0
	_current_region_id = ""
	_pending_region_announcement = ""
	if str(data.get("realm_id", "")) == "cloudreach":
		if int(data.get("grid_x", 0)) == cell_grid_x() and int(data.get("grid_z", 0)) == cell_grid_z() \
				and float(data.get("cell", 0)) == _cell \
				and float(data.get("origin_x", INF)) == float(_bounds.get("min_x", -1600)) \
				and float(data.get("origin_z", INF)) == float(_bounds.get("min_z", -500)):
			var decoded := Marshalls.base64_to_raw(str(data.get("visited_b64", "")))
			if decoded.size() == _visited.size():
				for i in decoded.size():
					_visited[i] = 1 if decoded[i] == 1 else 0
					_visited_count += _visited[i]
		for id: Variant in data.get("landmarks", []):
			if id is String and _landmark_defs.has(id):
				_discovered[id] = true
		for id: Variant in data.get("regions", []):
			if id is String and _region_defs.has(id):
				_discovered_regions[id] = true
		for entry: Dictionary in data.get("dynamic_markers", []):
			var p: Array = entry.get("position", [])
			if p.size() == 2:
				_dynamic[str(entry.get("id", ""))] = {"icon": entry.get("icon", ""), "position": Vector2(float(p[0]), float(p[1]))}
	_mark_fog_dirty_all()
	revision += 1
