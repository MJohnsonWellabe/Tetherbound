extends Node3D

## Visual-only realization of First Shore's authored horizon viewpoint. The
## stones form an asymmetric aperture around the existing northward island and
## Veilfall sightline; no route, encounter, terrain, or collision is owned here.

const CONFIG_PATH := "res://data/config/water_first_shore_horizon_stones.json"
const RENDER_BOUNDS := preload("res://scripts/characters/render_bounds.gd")

var _built := false


func build(water_world: Node3D) -> void:
	if _built:
		return
	_built = true
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(CONFIG_PATH))
	if not parsed is Dictionary:
		push_error("First Shore Horizon Stones config is invalid")
		return
	var cfg := parsed as Dictionary
	var site := _v2(cfg.get("site_xz", []))
	var stone_positions: Dictionary = {}
	for raw: Variant in cfg.get("stones", []):
		if raw is not Dictionary:
			continue
		var spec := raw as Dictionary
		var offset := _v2(spec.get("offset_xz", []))
		var at := site + offset
		var ground := _ground(water_world, at)
		if not is_finite(ground):
			push_error("Horizon stone %s received a non-finite terrain sample" % str(spec.get("id", "")))
			continue
		var stone := _fit_size(str(spec.get("model", "")), spec.get("size_m", []),
			str(spec.get("id", "HorizonStone")))
		if stone == null:
			continue
		var bounds := RENDER_BOUNDS.measure(stone)
		stone.position = Vector3(at.x, ground - bounds.position.y * stone.scale.y, at.y)
		stone.rotation_degrees = Vector3(float(spec.get("lean_deg", 0.0)),
			float(spec.get("yaw_deg", 0.0)), 0.0)
		stone.set_meta("horizon_role", "standing_stone" if str(spec.get("id", "")) != "SightStone" else "sighting_stone")
		stone.set_meta("terrain_contact_y", ground)
		stone.set_meta("authored_size_m", spec.get("size_m", []))
		add_child(stone)
		stone_positions[str(spec.get("id", ""))] = Vector3(at.x, ground, at.y)
	for raw: Variant in cfg.get("base_markers", []):
		if raw is Dictionary:
			_add_base_marker(raw as Dictionary, stone_positions, water_world)


func _add_base_marker(spec: Dictionary, stone_positions: Dictionary, water_world: Node3D) -> void:
	var stone_id := str(spec.get("stone_id", ""))
	if not stone_positions.has(stone_id):
		return
	var marker := _fit_height(str(spec.get("scene", "")), float(spec.get("height_m", 1.0)),
		str(spec.get("id", "HorizonLantern")))
	if marker == null:
		return
	var origin: Vector3 = stone_positions[stone_id]
	var offset := _v2(spec.get("offset_xz", []))
	var at := Vector2(origin.x + offset.x, origin.z + offset.y)
	var ground := _ground(water_world, at)
	if not is_finite(ground):
		marker.free()
		push_error("Horizon marker %s received a non-finite terrain sample" % marker.name)
		return
	var bounds := RENDER_BOUNDS.measure(marker)
	marker.position = Vector3(at.x, ground - bounds.position.y * marker.scale.y, at.y)
	marker.set_meta("horizon_role", "base_practical")
	add_child(marker)
	var light := OmniLight3D.new()
	light.name = "%sLight" % marker.name
	light.position = marker.position + Vector3.UP * float(spec.get("height_m", 1.0))
	light.light_color = Color("f1ab58")
	light.light_energy = float(spec.get("light_energy", 0.76))
	light.omni_range = float(spec.get("light_range_m", 7.0))
	light.shadow_enabled = false
	light.set_meta("horizon_role", "base_practical_light")
	add_child(light)


func _fit_height(path: String, height: float, node_name: String) -> Node3D:
	var packed := load(path) as PackedScene
	if packed == null:
		push_error("Horizon Stones model missing: %s" % path)
		return null
	var node := packed.instantiate() as Node3D
	if node == null:
		push_error("Horizon Stones model has no Node3D root: %s" % path)
		return null
	node.name = node_name
	var bounds := RENDER_BOUNDS.measure(node)
	if bounds.size.y <= 0.001:
		node.free()
		push_error("Horizon Stones model has no measurable height: %s" % path)
		return null
	var factor := height / bounds.size.y
	node.scale = Vector3.ONE * factor
	return node


func _fit_size(path: String, raw_size: Variant, node_name: String) -> Node3D:
	if raw_size is not Array or (raw_size as Array).size() < 3:
		push_error("Horizon stone %s has no authored XYZ size" % node_name)
		return null
	var packed := load(path) as PackedScene
	if packed == null:
		push_error("Horizon Stones model missing: %s" % path)
		return null
	var node := packed.instantiate() as Node3D
	if node == null:
		push_error("Horizon Stones model has no Node3D root: %s" % path)
		return null
	node.name = node_name
	var bounds := RENDER_BOUNDS.measure(node)
	if bounds.size.x <= 0.001 or bounds.size.y <= 0.001 or bounds.size.z <= 0.001:
		node.free()
		push_error("Horizon Stones model has no measurable XYZ bounds: %s" % path)
		return null
	var size := raw_size as Array
	node.scale = Vector3(float(size[0]) / bounds.size.x,
		float(size[1]) / bounds.size.y, float(size[2]) / bounds.size.z)
	return node


func _ground(water_world: Node3D, at: Vector2) -> float:
	if water_world == null or not water_world.has_method("ground_height_at"):
		return NAN
	return float(water_world.call("ground_height_at", at.x, at.y))


static func point_segment_distance(point: Vector2, start: Vector2, end: Vector2) -> float:
	var delta := end - start
	if delta.length_squared() <= 0.000001:
		return point.distance_to(start)
	var amount := clampf((point - start).dot(delta) / delta.length_squared(), 0.0, 1.0)
	return point.distance_to(start + delta * amount)


static func route_edge_clearance(site: Vector2, footprint_radius: float,
		route_width: float, segments: Array) -> float:
	var clearance := INF
	for raw: Variant in segments:
		if raw is Array and (raw as Array).size() == 2:
			var segment := raw as Array
			clearance = minf(clearance, point_segment_distance(site,
				_v2(segment[0]), _v2(segment[1])) - footprint_radius - route_width * 0.5)
	return clearance


static func _v2(raw: Variant) -> Vector2:
	if raw is Array and (raw as Array).size() >= 2:
		return Vector2(float((raw as Array)[0]), float((raw as Array)[1]))
	return Vector2.INF
