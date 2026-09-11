extends Node3D

## Collision-free identity layer for The High Perches. The production landmark
## retains its terrain, six needles, Fly approach and central survey target.

const CONFIG_PATH := "res://data/config/cloudreach_high_perches_visual.json"
const RENDER_BOUNDS := preload("res://scripts/characters/render_bounds.gd")
const ARRIVAL_ARCH := preload("res://assets/buildings/quaternius_castle/WallEntranceBricks.obj")
const BANNER := preload("res://assets/props/quaternius_fantasy/Banner_2_Cloth.gltf")
const TORCH := preload("res://assets/props/built/torch_prop.tscn")
const BENCH := preload("res://assets/props/quaternius_fantasy/Bench.gltf")
const BAG := preload("res://assets/props/quaternius_fantasy/Bag.gltf")
const CRATE := preload("res://assets/props/quaternius_fantasy/Crate_Wooden.gltf")

var _built := false


func build(materials: Dictionary) -> void:
	if _built:
		return
	_built = true
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(CONFIG_PATH))
	if not parsed is Dictionary:
		push_error("High Perches visual config is invalid")
		return
	var cfg := parsed as Dictionary
	var stone := _material(materials, "masonry")
	var stone_light := _material(materials, "masonry_trim")
	var timber := _material(materials, "weathered_timber")
	var bronze := _bronze(materials)
	var blue := _colour_material(Color(str(cfg.get("banner_blue", "#315f9a"))))
	var gold := _colour_material(Color(str(cfg.get("banner_gold", "#d6ad52"))))
	_add_arrival_arch(cfg, stone_light)
	_add_compass(cfg, stone_light, bronze, blue)
	_add_roosts(cfg, stone, timber, bronze)
	_add_banners(cfg, blue, gold)
	_add_signals(cfg)
	_add_supplies(cfg)


func _add_arrival_arch(cfg: Dictionary, material: Material) -> void:
	var arch := MeshInstance3D.new()
	arch.name = "HighPerchesArrivalArch"
	arch.mesh = ARRIVAL_ARCH
	arch.material_override = material
	var bounds := ARRIVAL_ARCH.get_aabb()
	var size := _v3(cfg.get("arrival_arch_size_m", [11.0, 10.5, 2.5]))
	arch.scale = size / bounds.size
	var at := _v3(cfg.get("arrival_arch_position", [0.0, 0.0, -15.0]))
	arch.position = at - Vector3(bounds.get_center().x * arch.scale.x,
		bounds.position.y * arch.scale.y, bounds.get_center().z * arch.scale.z)
	arch.rotation.y = deg_to_rad(float(cfg.get("arrival_arch_yaw_deg", 0.0)))
	arch.set_meta("high_perches_role", "arrival_portal")
	add_child(arch)
	_add_box("ArrivalCrown", at + Vector3(0.0, 10.8, 0.0), Vector3(12.2, 0.7, 3.0), material, "arrival_portal")


func _add_compass(cfg: Dictionary, stone: Material, bronze: Material, blue: Material) -> void:
	_add_cylinder("LandingApron", Vector3(0.0, 0.065, 0.0), 7.15, 0.13, stone, "landing_apron")
	_add_ring("OuterWindCompass", cfg.get("compass_outer_radii_m", [6.15, 6.65]) as Array,
		Vector3(0.0, 0.145, 0.0), bronze, "wind_compass")
	_add_ring("InnerWindCompass", cfg.get("compass_inner_radii_m", [2.0, 2.35]) as Array,
		Vector3(0.0, 0.15, 0.0), blue, "wind_compass")
	for index in 8:
		var angle := TAU * float(index) / 8.0
		var direction := Vector3(sin(angle), 0.0, cos(angle))
		var centre := direction * 4.35 + Vector3.UP * 0.15
		var ray := _add_box("CompassRay%02d" % (index + 1), centre,
			Vector3(0.22 if index % 2 else 0.34, 0.055, 3.8), bronze if index % 2 else blue,
			"wind_compass")
		ray.rotation.y = angle


func _add_roosts(cfg: Dictionary, stone: Material, timber: Material, bronze: Material) -> void:
	var positions := cfg.get("roost_positions", []) as Array
	for index in positions.size():
		var raw := positions[index] as Array
		var at := Vector3(float(raw[0]), 0.0, float(raw[1]))
		var toward := Vector2(-at.x, -at.z).normalized()
		var yaw := atan2(toward.x, toward.y)
		var root := Node3D.new()
		root.name = "KeeperRoost%02d" % (index + 1)
		root.position = at
		root.rotation.y = yaw
		root.set_meta("high_perches_role", "raised_roost")
		add_child(root)
		_add_cylinder_to(root, "RoostMasonryFoot", Vector3(0.0, 0.18, 0.0), 1.75, 0.36, stone, "raised_roost")
		for side: float in [-1.0, 1.0]:
			_add_box_to(root, "RoostUpright", Vector3(side * 1.45, 1.75, 0.0),
				Vector3(0.32, 3.2, 0.38), timber, "raised_roost")
			_add_cylinder_between(root, "RoostBrace", Vector3(side * 1.45, 0.4, 0.0),
				Vector3(side * 0.55, 2.55, 0.0), 0.10, timber, "raised_roost")
		_add_box_to(root, "CreatureRestBeam", Vector3(0.0, 2.75, 0.0),
			Vector3(4.25, 0.42, 0.62), timber, "raised_roost")
		for strap_x: float in [-1.25, 1.25]:
			_add_box_to(root, "RestBeamBinding", Vector3(strap_x, 2.75, 0.0),
				Vector3(0.18, 0.5, 0.72), bronze, "roost_binding")


func _add_banners(cfg: Dictionary, blue: Material, gold: Material) -> void:
	var positions := cfg.get("banner_positions", []) as Array
	for index in positions.size():
		var banner := BANNER.instantiate() as Node3D
		banner.name = "HighPerchesWindBanner%02d" % (index + 1)
		var bounds := RENDER_BOUNDS.measure(banner)
		var factor := 3.8 / maxf(bounds.size.y, 0.01)
		banner.scale = Vector3.ONE * factor
		var at := _v3(positions[index])
		banner.position = at - Vector3(bounds.get_center().x, bounds.get_center().y, bounds.get_center().z) * factor
		banner.rotation.y = 0.0 if index < 2 else (PI * 0.5 if index == 2 else -PI * 0.5)
		banner.set_meta("high_perches_role", "wind_banner")
		add_child(banner)
		_override_material(banner, blue if index % 2 == 0 else gold)


func _add_signals(cfg: Dictionary) -> void:
	var positions := cfg.get("signal_positions", []) as Array
	var colour := Color(str(cfg.get("signal_colour", "#f1aa63")))
	for index in positions.size():
		var at := _v3(positions[index])
		var torch := TORCH.instantiate() as Node3D
		torch.name = "HighPerchesLandingSignal%02d" % (index + 1)
		torch.position = at
		torch.scale = Vector3.ONE * 1.15
		torch.set_meta("high_perches_role", "landing_signal")
		add_child(torch)
		var light := OmniLight3D.new()
		light.name = "HighPerchesWarmLight%02d" % (index + 1)
		light.position = at + Vector3.UP * 2.15
		light.light_color = colour
		light.light_energy = float(cfg.get("signal_light_energy", 2.25))
		light.omni_range = float(cfg.get("signal_light_range_m", 12.0))
		light.omni_attenuation = 1.25
		light.shadow_enabled = false
		light.set_meta("high_perches_role", "landing_light")
		add_child(light)


func _add_supplies(cfg: Dictionary) -> void:
	var positions := cfg.get("supply_positions", []) as Array
	for index in positions.size():
		var root := Node3D.new()
		root.name = "KeeperSupplyCluster%02d" % (index + 1)
		root.position = _v3(positions[index])
		root.rotation.y = -0.45 if index == 0 else 0.55
		root.set_meta("high_perches_role", "keeper_supplies")
		add_child(root)
		_add_imported(root, "KeeperBench", BENCH, Vector3.ZERO, 1.45)
		_add_imported(root, "KeeperBag", BAG, Vector3(1.55, 0.0, 0.55), 0.72)
		_add_imported(root, "FeedCrate", CRATE, Vector3(-1.45, 0.0, 0.4), 0.78)


func _add_imported(parent: Node3D, label: String, packed: PackedScene, at: Vector3, target_height: float) -> void:
	var instance := packed.instantiate() as Node3D
	instance.name = label
	var bounds := RENDER_BOUNDS.measure(instance)
	var factor := target_height / maxf(bounds.size.y, 0.01)
	instance.scale = Vector3.ONE * factor
	instance.position = at - Vector3(bounds.get_center().x * factor, bounds.position.y * factor,
		bounds.get_center().z * factor)
	instance.set_meta("high_perches_role", "keeper_supplies")
	parent.add_child(instance)


func _add_ring(label: String, radii: Array, at: Vector3, material: Material, role: String) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.name = label
	var mesh := TorusMesh.new()
	mesh.inner_radius = float(radii[0])
	mesh.outer_radius = float(radii[1])
	mesh.rings = 48
	mesh.ring_segments = 8
	instance.mesh = mesh
	instance.material_override = material
	instance.position = at
	instance.set_meta("high_perches_role", role)
	add_child(instance)
	return instance


func _add_cylinder(label: String, at: Vector3, radius: float, height: float, material: Material, role: String) -> MeshInstance3D:
	return _add_cylinder_to(self, label, at, radius, height, material, role)


func _add_cylinder_to(parent: Node3D, label: String, at: Vector3, radius: float, height: float, material: Material, role: String) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.name = label
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = 32
	instance.mesh = mesh
	instance.material_override = material
	instance.position = at
	instance.set_meta("high_perches_role", role)
	parent.add_child(instance)
	return instance


func _add_box(label: String, at: Vector3, size: Vector3, material: Material, role: String) -> MeshInstance3D:
	return _add_box_to(self, label, at, size, material, role)


func _add_box_to(parent: Node3D, label: String, at: Vector3, size: Vector3, material: Material, role: String) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.name = label
	var mesh := BoxMesh.new()
	mesh.size = size
	instance.mesh = mesh
	instance.material_override = material
	instance.position = at
	instance.set_meta("high_perches_role", role)
	parent.add_child(instance)
	return instance


func _add_cylinder_between(parent: Node3D, label: String, a: Vector3, b: Vector3, radius: float, material: Material, role: String) -> MeshInstance3D:
	var instance := _add_cylinder_to(parent, label, a.lerp(b, 0.5), radius, a.distance_to(b), material, role)
	instance.quaternion = Quaternion(Vector3.UP, (b - a).normalized())
	return instance


func _material(materials: Dictionary, key: String) -> Material:
	var value: Variant = materials.get(key)
	if value is Material:
		return value as Material
	var fallback := StandardMaterial3D.new()
	fallback.albedo_color = Color("#766b58")
	fallback.roughness = 0.82
	return fallback


func _bronze(materials: Dictionary) -> StandardMaterial3D:
	var base := _material(materials, "bronze") as StandardMaterial3D
	var result := base.duplicate() as StandardMaterial3D if base != null else StandardMaterial3D.new()
	result.albedo_color = Color("#b38b45")
	result.metallic = 0.58
	result.roughness = 0.42
	return result


func _colour_material(colour: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = colour
	material.roughness = 0.78
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	return material


func _override_material(node: Node, material: Material) -> void:
	if node is MeshInstance3D:
		(node as MeshInstance3D).material_override = material
	for child: Node in node.get_children():
		_override_material(child, material)


static func _v3(raw: Variant) -> Vector3:
	if raw is Array and (raw as Array).size() >= 3:
		return Vector3(float((raw as Array)[0]), float((raw as Array)[1]), float((raw as Array)[2]))
	return Vector3.ZERO
