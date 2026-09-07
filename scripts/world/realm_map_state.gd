extends "res://autoload/map_state.gd"

## Data-driven map state for a realm whose world contract supplies bounds,
## landmarks and regions. Cloudreach keeps its specialised wrapper because its
## navigation and terrain survey have extra behaviour; new realms use this
## common shape without inheriting Cloudreach's story rules.

var _realm_id := ""
var _display_name := ""
var _bounds: Dictionary = {}
var _world_data: Dictionary = {}
var _progression: RefCounted
var _discovery_radius := 35.0
var _height_tolerance := 16.0
var _terrain: Texture2D


func configure_realm(realm_id: String, definition: Dictionary, world: Dictionary,
		chapter: Dictionary, tuning: Dictionary, progression: RefCounted) -> void:
	_realm_id = realm_id
	_display_name = str(definition.get("display_name", realm_id.capitalize()))
	_world_data = world.duplicate(true)
	_progression = progression
	_discovery_radius = float(tuning.get("landmark_discovery_radius_m",35.0))
	_height_tolerance = float(tuning.get("landmark_height_tolerance_m",16.0))
	_bounds = world.get("realm", {}).get("world_bounds", {})
	var cell := maxf(1.0, float(tuning.get("map_cell_m", 8.0)))
	set_extent(
		Vector2(float(_bounds.get("min_x", -1024.0)), float(_bounds.get("min_z", -1024.0))),
		maxi(1, ceili((float(_bounds.get("max_x", 1024.0)) - float(_bounds.get("min_x", -1024.0))) / cell)),
		maxi(1, ceili((float(_bounds.get("max_z", 1024.0)) - float(_bounds.get("min_z", -1024.0))) / cell)),
		cell)
	var landmarks: Array = []
	for landmark: Dictionary in world.get("landmarks", []):
		var entry := landmark.duplicate(true)
		entry["discover_radius"] = _discovery_radius
		var at: Variant = entry.get("position", [])
		if at is Array and (at as Array).size() >= 3:
			entry["position"] = [at[0], at[2]]
		landmarks.append(entry)
	configure({"landmarks": landmarks, "regions": [], "minimap_span_m": 160.0})
	for region: Dictionary in world.get("regions", []):
		var at: Variant = region.get("position", [])
		if at is Array and (at as Array).size() >= 3:
			_region_defs[str(region.get("id", ""))] = {
				"display_name": str(region.get("display_name", region.get("id", ""))),
				"centre": Vector2(float(at[0]), float(at[2])), "radius": 150.0,
			}


func world_bounds() -> Dictionary:
	return _bounds.duplicate(true)


func _allowed(flag: String) -> bool:
	return flag.is_empty() or (_progression != null and bool(_progression.call("has",flag)))


func _discover_landmarks_near(at: Vector3) -> bool:
	var changed := false
	for landmark: Dictionary in _world_data.get("landmarks",[]):
		var id := str(landmark.get("id",""))
		var p: Array = landmark.get("position",[])
		if p.size()!=3 or _discovered.has(id) or not _allowed(str(landmark.get("requires_unlock",""))):
			continue
		var offset := at-Vector3(float(p[0]),float(p[1]),float(p[2]))
		if Vector2(offset.x,offset.z).length()<=_discovery_radius and absf(offset.y)<=_height_tolerance:
			_discovered[id] = true
			changed = true
	return changed


func update_region(at: Vector3) -> void:
	var id := ""
	for region: Dictionary in _world_data.get("regions",[]):
		var b: Dictionary = region.get("bounds",{})
		if b.is_empty() or not _allowed(str(region.get("access",{}).get("requires_unlock",""))):
			continue
		if at.x>=float(b.min_x) and at.x<=float(b.max_x) and at.z>=float(b.min_z) and at.z<=float(b.max_z) and at.y>=float(b.get("min_y",-INF)) and at.y<=float(b.get("max_y",INF)):
			id = str(region.id)
			break
	if id == _current_region_id:
		return
	_current_region_id = id
	if not id.is_empty() and not _discovered_regions.has(id):
		_discovered_regions[id] = true
		_pending_region_announcement = str(_region_defs[id].display_name)
		revision += 1


func bake_terrain(world: Node) -> Texture2D:
	if _terrain != null:
		return _terrain
	if world == null or not world.has_method("ground_height_at"):
		return null
	var canvas := Image.create(160,214,false,Image.FORMAT_RGB8)
	for z in 214:
		for x in 160:
			var wx := lerpf(float(_bounds.min_x),float(_bounds.max_x),(x+0.5)/160.0)
			var wz := lerpf(float(_bounds.min_z),float(_bounds.max_z),(z+0.5)/214.0)
			var h := float(world.call("ground_height_at",wx,wz))
			canvas.set_pixel(x,z,Color("203842") if h<0 else Color("355d50").lerp(Color("aab696"),clampf(h/180.0,0,1)))
	_terrain = ImageTexture.create_from_image(canvas)
	return _terrain


func map_display_name() -> String:
	return _display_name


func save_data() -> Dictionary:
	var data := super.save_data()
	data["realm_id"] = _realm_id
	return data


func load_data(data: Dictionary) -> void:
	# MapState's descriptor validation protects a new realm from another
	# realm's fog bytes. The realm tag adds an explicit ownership check first.
	if str(data.get("realm_id", "")) != _realm_id:
		super.load_data({})
		return
	super.load_data(data)
