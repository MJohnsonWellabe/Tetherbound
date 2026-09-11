extends Node3D

const CONFIG_PATH := "res://data/config/cloudreach_broken_skyroad_arch_visual.json"
const GATEWAY := preload("res://assets/buildings/quaternius_castle/WallEntranceBricks.obj")

var _built := false


func build(materials: Dictionary) -> void:
	if _built:
		return
	_built = true
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(CONFIG_PATH))
	if not parsed is Dictionary:
		push_error("Broken Skyroad Arch visual config is invalid")
		return
	var cfg := parsed as Dictionary
	rotation.y = deg_to_rad(float(cfg.get("gateway_yaw_deg", -24.0)))
	var stone := _material(materials, "stone_light")
	var dark_stone := _material(materials, "masonry")
	var gate := MeshInstance3D.new()
	gate.name = "InstalledSkyroadGateway"
	gate.mesh = GATEWAY
	gate.material_override = stone
	var bounds := GATEWAY.get_aabb()
	var requested := _v3(cfg.get("gateway_size_m", [26.0, 19.0, 5.5]))
	gate.scale = Vector3(requested.x / maxf(bounds.size.x, 0.01), requested.y / maxf(bounds.size.y, 0.01), requested.z / maxf(bounds.size.z, 0.01))
	gate.position = -Vector3(bounds.get_center().x * gate.scale.x, bounds.position.y * gate.scale.y, bounds.get_center().z * gate.scale.z)
	gate.set_meta("skyroad_arch_role", "installed_gateway")
	add_child(gate)
	# Stepped, asymmetric shoulders visually seat the installed gateway and
	# break the former two-identical-slabs silhouette.
	for spec: Dictionary in [
		{"name": "WestButtressLower", "at": Vector3(-13.0, 2.0, 0.4), "size": Vector3(5.0, 4.0, 7.5), "yaw": -7.0},
		{"name": "WestButtressUpper", "at": Vector3(-12.3, 5.3, 0.2), "size": Vector3(3.8, 3.0, 6.2), "yaw": 5.0},
		{"name": "EastBrokenFoot", "at": Vector3(12.5, 1.3, -0.4), "size": Vector3(5.2, 2.6, 7.0), "yaw": 11.0},
	]:
		_add_block(str(spec.name), spec.at as Vector3, spec.size as Vector3, float(spec.yaw), dark_stone, "grounded_buttress")
	for spec: Dictionary in [
		{"at": Vector3(10.7, 0.8, 5.5), "size": Vector3(7.5, 1.7, 3.2), "yaw": 18.0, "roll": 9.0},
		{"at": Vector3(14.0, 0.65, 1.8), "size": Vector3(4.3, 1.35, 3.4), "yaw": -28.0, "roll": -5.0},
		{"at": Vector3(8.3, 0.5, -5.0), "size": Vector3(3.0, 1.0, 2.8), "yaw": 31.0, "roll": 12.0},
	]:
		var block := _add_block("FallenCrownStone", spec.at as Vector3, spec.size as Vector3, float(spec.yaw), stone, "fallen_crown")
		block.rotation.z = deg_to_rad(float(spec.roll))
	var fracture_colour := Color(str(cfg.get("fracture_colour", "#70e0d6")))
	var glow := StandardMaterial3D.new()
	glow.albedo_color = fracture_colour
	glow.emission_enabled = true
	glow.emission = fracture_colour
	glow.emission_energy_multiplier = 2.1
	for index in 3:
		var shard := MeshInstance3D.new()
		shard.name = "WindFracture%02d" % (index + 1)
		var prism := PrismMesh.new()
		prism.size = Vector3(0.35 + index * 0.08, 2.6 - index * 0.35, 0.24)
		shard.mesh = prism
		shard.material_override = glow
		shard.position = Vector3(7.7 + index * 1.25, 13.8 - index * 1.8, 0.3)
		shard.rotation.z = deg_to_rad(-18.0 + index * 13.0)
		shard.set_meta("skyroad_arch_role", "wind_fracture")
		add_child(shard)
	var light := OmniLight3D.new()
	light.name = "SkyroadFractureLight"
	light.light_color = fracture_colour
	light.light_energy = 3.0
	light.omni_range = 17.0
	light.shadow_enabled = false
	light.position = Vector3(8.5, 11.5, 1.0)
	light.set_meta("skyroad_arch_role", "fracture_light")
	add_child(light)


func _add_block(label: String, at: Vector3, size: Vector3, yaw_deg: float, material: Material, role: String) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.name = label
	var mesh := BoxMesh.new()
	mesh.size = size
	instance.mesh = mesh
	instance.material_override = material
	instance.position = at
	instance.rotation.y = deg_to_rad(yaw_deg)
	instance.set_meta("skyroad_arch_role", role)
	add_child(instance)
	return instance


func _material(materials: Dictionary, key: String) -> Material:
	var value: Variant = materials.get(key)
	if value is Material:
		return value as Material
	var fallback := StandardMaterial3D.new()
	fallback.albedo_color = Color("#77736b")
	fallback.roughness = 0.88
	return fallback


static func _v3(raw: Variant) -> Vector3:
	if raw is Array and (raw as Array).size() >= 3:
		return Vector3(float((raw as Array)[0]), float((raw as Array)[1]), float((raw as Array)[2]))
	return Vector3.ONE
