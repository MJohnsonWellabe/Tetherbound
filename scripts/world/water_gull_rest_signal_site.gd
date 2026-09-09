extends Node3D

## Water-local presentation for Gull Rest's authored signal-spire landmark.
## The optional-island route, encounters and progression remain owned by their
## existing systems. This node contributes one terrain-fitted timber lookout,
## matching support collision, and its visible practical signal flame.

const CONFIG_PATH := "res://data/config/water_gull_rest_signal_site.json"
const RENDER_BOUNDS := preload("res://scripts/characters/render_bounds.gd")

var _built := false
var _platform_y := NAN


func build(water_world: Node3D) -> void:
	if _built:
		return
	_built = true
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(CONFIG_PATH))
	if not parsed is Dictionary:
		push_error("Gull Rest signal site config is invalid")
		return
	var cfg := parsed as Dictionary
	var centre := _v2(cfg.get("site_xz", []))
	var support_specs: Array = cfg.get("supports", [])
	var feet: Array[float] = []
	for raw: Variant in support_specs:
		if raw is Dictionary:
			var spec := raw as Dictionary
			var offset := _v2(spec.get("offset_xz", []))
			feet.append(_ground(water_world, centre + offset))
	if feet.size() != support_specs.size() or feet.is_empty():
		push_error("Gull Rest signal site has incomplete terrain support samples")
		return
	for foot: float in feet:
		if not is_finite(foot):
			push_error("Gull Rest signal site received a non-finite terrain support sample")
			return
	var highest_foot := feet[0]
	for foot: float in feet:
		highest_foot = maxf(highest_foot, foot)
	_platform_y = highest_foot + float(cfg.get("platform_height_above_highest_foot_m", 4.4))
	for index in support_specs.size():
		_add_support(centre, support_specs[index] as Dictionary, feet[index], _platform_y)
	_add_raised_piece(centre, cfg.get("platform", {}), _platform_y)
	for raw: Variant in cfg.get("rails", []):
		if raw is Dictionary:
			_add_raised_piece(centre, raw as Dictionary, _platform_y)
	_add_signal(centre, cfg.get("signal", {}), cfg.get("light", {}))


func platform_y() -> float:
	return _platform_y


func _add_support(centre: Vector2, spec: Dictionary, ground: float, top_y: float) -> void:
	var piece := _instantiate(str(spec.get("model", "")), str(spec.get("id", "Support")))
	if piece == null:
		return
	var offset := _v2(spec.get("offset_xz", []))
	var scale_xz: Array = spec.get("scale_xz", [1.0, 1.0])
	var bounds := RENDER_BOUNDS.measure(piece)
	if bounds.size.y <= 0.001:
		piece.free()
		push_error("Gull Rest signal support has no measurable height")
		return
	piece.scale = Vector3(float(scale_xz[0]), (top_y - ground) / bounds.size.y, float(scale_xz[1]))
	piece.rotation.y = deg_to_rad(float(spec.get("yaw_deg", 0.0)))
	piece.position = Vector3(centre.x + offset.x, ground - bounds.position.y * piece.scale.y,
		centre.y + offset.y)
	piece.set_meta("signal_role", "terrain_support")
	piece.set_meta("terrain_foot_y", ground)
	piece.set_meta("platform_y", top_y)
	add_child(piece)
	_add_matching_support_collision(piece, bounds)


func _add_matching_support_collision(piece: Node3D, bounds: AABB) -> void:
	var body := StaticBody3D.new()
	body.name = piece.name + "Collision"
	body.rotation.y = piece.rotation.y
	var scaled_centre := Vector3(bounds.get_center().x * piece.scale.x,
		bounds.get_center().y * piece.scale.y, bounds.get_center().z * piece.scale.z)
	body.position = piece.position + Basis(Vector3.UP, piece.rotation.y) * scaled_centre
	var shape_node := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(bounds.size.x * piece.scale.x, bounds.size.y * piece.scale.y,
		bounds.size.z * piece.scale.z)
	shape_node.shape = shape
	body.add_child(shape_node)
	body.set_meta("signal_role", "support_collision")
	add_child(body)


func _add_raised_piece(centre: Vector2, raw: Variant, floor_y: float) -> void:
	if not raw is Dictionary:
		return
	var spec := raw as Dictionary
	var piece := _instantiate(str(spec.get("model", "")), str(spec.get("id", "RaisedPiece")))
	if piece == null:
		return
	var offset := _v2(spec.get("offset_xz", []))
	var scale_raw: Array = spec.get("scale", [1.0, 1.0, 1.0])
	piece.scale = Vector3(float(scale_raw[0]), float(scale_raw[1]), float(scale_raw[2]))
	piece.rotation.y = deg_to_rad(float(spec.get("yaw_deg", 0.0)))
	var bounds := RENDER_BOUNDS.measure(piece)
	piece.position = Vector3(centre.x + offset.x, floor_y - bounds.position.y * piece.scale.y,
		centre.y + offset.y)
	piece.set_meta("signal_role", "platform" if str(spec.get("id", "")).contains("platform") else "rail")
	add_child(piece)


func _add_signal(centre: Vector2, signal_cfg: Dictionary, light_cfg: Dictionary) -> void:
	var packed := load(str(signal_cfg.get("scene", ""))) as PackedScene
	if packed == null:
		push_error("Gull Rest signal flame scene is missing")
		return
	var signal_node := packed.instantiate() as Node3D
	if signal_node == null:
		push_error("Gull Rest signal flame has no Node3D root")
		return
	signal_node.name = "SignalFlame"
	var signal_scale := float(signal_cfg.get("scale", 1.0))
	signal_node.scale = Vector3.ONE * signal_scale
	signal_node.position = Vector3(centre.x, _platform_y + float(signal_cfg.get("base_lift_m", 0.04)), centre.y)
	signal_node.set_meta("signal_role", "signal_flame")
	add_child(signal_node)
	var light := OmniLight3D.new()
	light.name = "SignalLight"
	light.light_color = Color(str(light_cfg.get("colour", "#f4a64a")))
	light.light_energy = float(light_cfg.get("energy", 1.35))
	light.omni_range = float(light_cfg.get("range_m", 9.0))
	light.shadow_enabled = bool(light_cfg.get("shadow_enabled", false))
	var flame_offset := Vector3(0.0, 0.84, 0.0)
	if signal_node.has_method("flame_local_position"):
		flame_offset = signal_node.call("flame_local_position")
	light.position = signal_node.position + flame_offset * signal_scale
	light.set_meta("signal_role", "practical_light")
	add_child(light)


func _instantiate(path: String, node_name: String) -> Node3D:
	var packed := load(path) as PackedScene
	if packed == null:
		push_error("Gull Rest signal site model missing: %s" % path)
		return null
	var node := packed.instantiate() as Node3D
	if node == null:
		push_error("Gull Rest signal site model has no Node3D root: %s" % path)
		return null
	node.name = node_name
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
