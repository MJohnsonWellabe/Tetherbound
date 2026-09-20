extends Node3D

## Collision-free route markers for the small physical recovery shoals. Their
## terrain and water safety are authored by water_world.json / WaterHeightfield;
## this layer only makes each otherwise-low landing visible to a person.

const RENDER_BOUNDS := preload("res://scripts/characters/render_bounds.gd")
const SAFE_RADIUS_M := 6.0
const SAFE_CLEARANCE_M := 0.05

var _built := false


func build(water_world: Node3D, world_config: Dictionary) -> void:
	if _built:
		return
	_built = true
	var marker_spec: Variant = world_config.get("rest_shoal_marker", {})
	if marker_spec is not Dictionary:
		push_error("Water rest-shoal marker config is invalid")
		return
	var marker := marker_spec as Dictionary
	for raw: Variant in world_config.get("rest_shoals", []):
		if raw is Dictionary:
			_add_shoal(raw as Dictionary, marker, water_world)


func _add_shoal(shoal: Dictionary, marker: Dictionary, water_world: Node3D) -> void:
	var id := str(shoal.get("id", ""))
	var centre := _v2(shoal.get("center_xz_m", []))
	if id.is_empty() or not _finite_v2(centre):
		push_error("Water rest shoal has no finite id/centre")
		return
	var stone := _fit_size(str(marker.get("model", "")), marker.get("size_m", []),
		"RestShoalStone_%s" % id)
	if stone == null:
		return
	var stone_bounds := RENDER_BOUNDS.measure(stone)
	var stone_radius := _horizontal_radius(stone_bounds, stone.scale)
	var requested_offset := _v2(marker.get("offset_xz_m", []))
	if not _finite_v2(requested_offset) or requested_offset.length_squared() <= 0.000001:
		stone.free()
		push_error("Water rest-shoal marker has no usable offset_xz_m")
		return
	# Keep all rendered stone outside the six-metre recovery centre. The
	# configured [6, 4] offset is nearly sufficient, but the fitted diagonal
	# bound needs a few centimetres more to clear it at every yaw.
	var direction := requested_offset.normalized()
	var marker_distance := maxf(requested_offset.length(),
		SAFE_RADIUS_M + stone_radius + SAFE_CLEARANCE_M)
	var stone_at := centre + direction * marker_distance
	if not _ground_node(stone, stone_bounds, stone_at, water_world, id, "stone"):
		return
	stone.rotation.y = atan2(-direction.y, -direction.x)
	stone.set_meta("rest_shoal_id", id)
	stone.set_meta("rest_shoal_role", "wayfinding_stone")
	stone.set_meta("safe_radius_clearance_m", marker_distance - stone_radius - SAFE_RADIUS_M)
	add_child(stone)

	var torch := _fit_height(str(marker.get("torch_scene", "")),
		float(marker.get("torch_height_m", 1.3)), "RestShoalTorch_%s" % id)
	if torch == null:
		return
	var torch_bounds := RENDER_BOUNDS.measure(torch)
	# The practical shares the stone's outward side, keeping both its visual
	# footprint and its small pool of light out of the usable recovery centre.
	var torch_radius := _horizontal_radius(torch_bounds, torch.scale)
	var torch_at := stone_at + direction * (stone_radius + torch_radius + 0.18)
	if not _ground_node(torch, torch_bounds, torch_at, water_world, id, "torch"):
		return
	torch.rotation.y = stone.rotation.y
	torch.set_meta("rest_shoal_id", id)
	torch.set_meta("rest_shoal_role", "wayfinding_practical")
	add_child(torch)
	_add_light(id, torch_at, _ground(water_world, torch_at), marker)


func _ground_node(node: Node3D, bounds: AABB, at: Vector2, water_world: Node3D,
		shoal_id: String, role: String) -> bool:
	var ground := _ground(water_world, at)
	if not is_finite(ground):
		node.free()
		push_error("Water rest shoal %s %s received a non-finite terrain sample" % [shoal_id, role])
		return false
	node.position = Vector3(at.x, ground - bounds.position.y * node.scale.y, at.y)
	node.set_meta("terrain_contact_y", ground)
	return true


func _add_light(id: String, at: Vector2, ground: float, marker: Dictionary) -> void:
	if not is_finite(ground):
		return
	var light := OmniLight3D.new()
	light.name = "RestShoalLight_%s" % id
	light.position = Vector3(at.x, ground + float(marker.get("torch_height_m", 1.3)), at.y)
	light.light_color = Color("f1ab58")
	light.light_energy = 0.58
	light.omni_range = 5.0
	light.shadow_enabled = false
	light.set_meta("rest_shoal_id", id)
	light.set_meta("rest_shoal_role", "wayfinding_practical_light")
	add_child(light)


func _fit_size(path: String, raw_size: Variant, node_name: String) -> Node3D:
	if raw_size is not Array or (raw_size as Array).size() < 3:
		push_error("Water rest-shoal stone %s has no authored XYZ size" % node_name)
		return null
	var node := _instantiate(path, node_name)
	if node == null:
		return null
	var bounds := RENDER_BOUNDS.measure(node)
	if bounds.size.x <= 0.001 or bounds.size.y <= 0.001 or bounds.size.z <= 0.001:
		node.free()
		push_error("Water rest-shoal stone has no measurable XYZ bounds: %s" % path)
		return null
	var size := raw_size as Array
	node.scale = Vector3(float(size[0]) / bounds.size.x, float(size[1]) / bounds.size.y,
		float(size[2]) / bounds.size.z)
	return node


func _fit_height(path: String, height: float, node_name: String) -> Node3D:
	var node := _instantiate(path, node_name)
	if node == null:
		return null
	var bounds := RENDER_BOUNDS.measure(node)
	if bounds.size.y <= 0.001:
		node.free()
		push_error("Water rest-shoal torch has no measurable height: %s" % path)
		return null
	node.scale = Vector3.ONE * (height / bounds.size.y)
	return node


func _instantiate(path: String, node_name: String) -> Node3D:
	var packed := load(path) as PackedScene
	if packed == null:
		push_error("Water rest-shoal model missing: %s" % path)
		return null
	var node := packed.instantiate() as Node3D
	if node == null:
		push_error("Water rest-shoal model has no Node3D root: %s" % path)
		return null
	node.name = node_name
	return node


func _ground(water_world: Node3D, at: Vector2) -> float:
	if water_world == null or not water_world.has_method("ground_height_at"):
		return NAN
	return float(water_world.call("ground_height_at", at.x, at.y))


static func _horizontal_radius(bounds: AABB, scale: Vector3) -> float:
	# Imported roots are not guaranteed to sit at the centre of their visible
	# mesh. Use both scaled AABB ends, then circumscribe that root-relative box
	# so the safe disk stays clear at every marker yaw.
	var x_extent := maxf(absf(bounds.position.x * scale.x), absf(bounds.end.x * scale.x))
	var z_extent := maxf(absf(bounds.position.z * scale.z), absf(bounds.end.z * scale.z))
	return Vector2(x_extent, z_extent).length()


static func _v2(raw: Variant) -> Vector2:
	if raw is Array and (raw as Array).size() >= 2:
		return Vector2(float((raw as Array)[0]), float((raw as Array)[1]))
	return Vector2.INF


static func _finite_v2(value: Vector2) -> bool:
	return is_finite(value.x) and is_finite(value.y)
