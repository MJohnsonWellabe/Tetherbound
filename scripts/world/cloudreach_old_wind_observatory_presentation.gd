extends Node3D

## Collisionless identity layer for Old Wind Observatory. The production
## tower remains the core mass; this wraps it with a human-scale court,
## architectural ribs and a readable armillary silhouette.

const CONFIG_PATH := "res://data/config/cloudreach_old_wind_observatory_visual.json"
const RENDER_BOUNDS := preload("res://scripts/characters/render_bounds.gd")
const TWISTED_TREES: Array[PackedScene] = [
	preload("res://assets/environment/stylized_nature/TwistedTree_2.gltf"),
	preload("res://assets/environment/stylized_nature/TwistedTree_4.gltf"),
]
const ROCKS: Array[PackedScene] = [
	preload("res://assets/environment/stylized_nature/Rock_Medium_1.gltf"),
	preload("res://assets/environment/stylized_nature/Rock_Medium_2.gltf"),
	preload("res://assets/environment/stylized_nature/Rock_Medium_3.gltf"),
]
const WIND_BANNER := preload("res://assets/props/quaternius_fantasy/Banner_2_Cloth.gltf")
const BOOK_STAND := preload("res://assets/props/quaternius_fantasy/BookStand.gltf")
const BENCH := preload("res://assets/props/quaternius_fantasy/Bench.gltf")
const TORCH := preload("res://assets/props/quaternius_fantasy/Torch_Metal.gltf")
const DOOR_FRAME := preload("res://assets/buildings/quaternius_medieval/DoorFrame_Flat_WoodDark.gltf")
const DOOR := preload("res://assets/buildings/quaternius_medieval/Door_8_Flat.gltf")
const WINDOW := preload("res://assets/buildings/quaternius_medieval/Window_Thin_Flat1.gltf")

var _built := false


func build(materials: Dictionary, simulation_only: bool = false) -> void:
	if _built:
		return
	_built = true
	if simulation_only:
		return
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(CONFIG_PATH))
	if not parsed is Dictionary:
		push_error("Old Wind Observatory visual config is invalid")
		return
	var cfg := parsed as Dictionary
	var stone := _material(materials, "masonry")
	var trim := _material(materials, "masonry_trim")
	var timber := _material(materials, "weathered_timber")
	var bronze := _bronze()
	var blue := _colour_material(Color(str(cfg.banner_blue)))
	var gold := _colour_material(Color(str(cfg.banner_gold)))
	var glow := _glow_material(Color(str(cfg.wind_glow)))
	_build_dial_court(cfg, stone, trim, bronze, blue)
	_build_tower_ribs(cfg, trim, bronze)
	_build_armillary(cfg, bronze, glow)
	_build_tower_face()
	_build_wind_standards(cfg, timber, blue, gold)
	_build_instruments(cfg, stone, timber)
	_build_night_wayfinding(cfg)
	_build_edge_ecology(cfg)


func _build_dial_court(cfg: Dictionary, stone: Material, trim: Material,
		bronze: Material, blue: Material) -> void:
	_add_cylinder("ObservatoryDialCourt", Vector3(0.0, 0.055, 0.0),
		float(cfg.dial_radius_m), 0.11, stone, "dial_court")
	_add_ring("OuterCompassCourse", 13.5, 14.2, Vector3(0.0, 0.13, 0.0), trim, "wind_dial")
	_add_ring("BronzeCompassCourse", 10.7, 11.05, Vector3(0.0, 0.15, 0.0), bronze, "wind_dial")
	for index in 8:
		var angle := TAU * float(index) / 8.0
		var direction := Vector3(sin(angle), 0.0, cos(angle))
		var ray := _add_box("DialRay%02d" % index, direction * 6.8 + Vector3.UP * 0.16,
			Vector3(0.25 if index % 2 else 0.42, 0.055, 7.3),
			bronze if index % 2 else blue, "wind_dial")
		ray.rotation.y = angle


func _build_tower_ribs(cfg: Dictionary, trim: Material, bronze: Material) -> void:
	var count := int(cfg.tower_rib_count)
	for index in count:
		var angle := TAU * float(index) / float(count)
		var outward := Vector3(sin(angle), 0.0, cos(angle))
		var rib := _add_box("TowerRib%02d" % index,
			outward * float(cfg.tower_rib_radius_m) + Vector3.UP * (float(cfg.tower_rib_height_m) * 0.5),
			Vector3(1.15, float(cfg.tower_rib_height_m), 2.0), trim, "tower_rib")
		rib.rotation.y = angle
	for course: Dictionary in [
		{"name":"LowerTowerCourse", "y":1.6, "inner":6.35, "outer":6.9},
		{"name":"UpperTowerCourse", "y":12.6, "inner":6.4, "outer":7.0},
		{"name":"DomeShoulderCourse", "y":16.2, "inner":6.15, "outer":6.65},
	]:
		_add_ring(str(course.name), float(course.inner), float(course.outer),
			Vector3(0.0, float(course.y), 0.0), bronze, "tower_course")


func _build_armillary(cfg: Dictionary, bronze: Material, glow: Material) -> void:
	var centre := _v3(cfg.get("armillary_position", [0.0, 10.5, -6.9]))
	var radii := cfg.armillary_radii_m as Array
	var horizontal := _add_ring("ArmillaryHorizon", float(radii[0]), float(radii[1]), centre,
		bronze, "armillary")
	horizontal.rotation.x = PI * 0.5
	var meridian := _add_ring("ArmillaryMeridian", float(radii[0]), float(radii[1]), centre,
		bronze, "armillary")
	meridian.rotation.x = PI * 0.5
	meridian.rotation.y = deg_to_rad(42.0)
	var wind_plane := _add_ring("ArmillaryWindPlane", float(radii[0]) - 0.55,
		float(radii[1]) - 0.55, centre, glow, "armillary")
	wind_plane.rotation.x = PI * 0.5
	wind_plane.rotation.y = deg_to_rad(-42.0)
	var core := MeshInstance3D.new()
	core.name = "WindReadingCore"
	var sphere := SphereMesh.new()
	sphere.radius = 0.78
	sphere.height = 1.56
	core.mesh = sphere
	core.position = centre
	core.material_override = glow
	core.set_meta("observatory_role", "armillary")
	add_child(core)
	for index in 4:
		var angle := TAU * float(index) / 4.0 + PI * 0.25
		var finish := centre + Vector3(sin(angle) * 4.8, cos(angle) * 4.8, 0.75)
		_add_cylinder_between("ArmillaryBrace%02d" % index, centre, finish,
			0.12, bronze, "armillary")
	var armillary_fill := OmniLight3D.new()
	armillary_fill.name = "ArmillaryNightFill"
	armillary_fill.position = centre + Vector3(0.0, 0.0, -1.2)
	armillary_fill.light_color = Color(str(cfg.wind_glow))
	armillary_fill.light_energy = float(cfg.get("armillary_night_energy", 0.72))
	armillary_fill.omni_range = float(cfg.get("armillary_night_range_m", 17.0))
	armillary_fill.omni_attenuation = 1.4
	armillary_fill.shadow_enabled = false
	armillary_fill.set_meta("observatory_role", "night_wayfinding")
	add_child(armillary_fill)


func _build_tower_face() -> void:
	var doorway := Node3D.new()
	doorway.name = "ObservatoryKeeperDoorway"
	doorway.position = Vector3(0.0, 0.05, -6.72)
	doorway.rotation.y = PI
	doorway.set_meta("observatory_role", "tower_opening")
	add_child(doorway)
	_add_imported(doorway, "KeeperDoor", DOOR, Vector3.ZERO, 3.25)
	_add_imported(doorway, "KeeperDoorFrame", DOOR_FRAME, Vector3(0.0, 0.0, -0.05), 3.55)
	for side: float in [-1.0, 1.0]:
		var window := _add_imported(self, "WindLedgerWindow%s" % ("L" if side < 0.0 else "R"),
			WINDOW, Vector3(side * 4.2, 3.6, -5.15), 2.25)
		window.rotation.y = PI + side * 0.68
		window.set_meta("observatory_role", "tower_opening")


func _build_wind_standards(cfg: Dictionary, timber: Material, blue: Material, gold: Material) -> void:
	var positions := cfg.banner_positions as Array
	for index in positions.size():
		var at := _v3(positions[index])
		_add_cylinder("WindStandardMast%02d" % index, at + Vector3.UP * 3.1,
			0.10, 6.2, timber, "wind_standard")
		var banner := WIND_BANNER.instantiate() as Node3D
		banner.name = "ObservatoryWindBanner%02d" % index
		var bounds := RENDER_BOUNDS.measure(banner)
		var factor := 2.8 / maxf(bounds.size.y, 0.01)
		banner.scale = Vector3.ONE * factor
		banner.position = at + Vector3(0.0, 5.7, 0.0) - Vector3(bounds.get_center().x,
			bounds.get_center().y, bounds.get_center().z) * factor
		banner.rotation.y = atan2(-at.x, -at.z)
		_override_material(banner, blue if index % 2 == 0 else gold)
		banner.set_meta("observatory_role", "wind_standard")
		add_child(banner)


func _build_instruments(cfg: Dictionary, stone: Material, timber: Material) -> void:
	var positions := cfg.instrument_positions as Array
	for index in positions.size():
		var at := _v3(positions[index])
		var station := Node3D.new()
		station.name = "WindKeeperStation%02d" % index
		station.position = at
		station.rotation.y = atan2(-at.x, -at.z)
		station.set_meta("observatory_role", "instrument_station")
		add_child(station)
		_add_cylinder_to(station, "InstrumentPlinth", Vector3(0.0, 0.20, 0.0), 1.25, 0.40,
			stone, "instrument_station")
		_add_imported(station, "WindLedger", BOOK_STAND, Vector3(0.0, 0.38, 0.0), 1.65)
		_add_imported(station, "KeeperBench", BENCH, Vector3(2.0, 0.0, 0.3), 1.15)
		# A simple sighting tube makes each station face the central wind gauge.
		var tube := _add_cylinder_to(station, "SightingTube", Vector3(0.0, 2.45, -0.15),
			0.16, 2.2, timber, "instrument_station")
		tube.rotation.x = PI * 0.5


func _build_night_wayfinding(cfg: Dictionary) -> void:
	var positions := cfg.lantern_positions as Array
	for index in positions.size():
		var at := _v3(positions[index])
		_add_imported(self, "ObservatoryTorch%02d" % index, TORCH, at, 2.2)
		var light := OmniLight3D.new()
		light.name = "ObservatoryWarmPool%02d" % index
		light.position = at + Vector3.UP * 2.0
		light.light_color = Color("#f0ad66")
		light.light_energy = float(cfg.night_light_energy)
		light.omni_range = float(cfg.night_light_range_m)
		light.omni_attenuation = 1.35
		light.shadow_enabled = false
		light.set_meta("observatory_role", "night_wayfinding")
		add_child(light)


func _build_edge_ecology(cfg: Dictionary) -> void:
	for index in (cfg.twisted_trees as Array).size():
		var spec := (cfg.twisted_trees as Array)[index] as Dictionary
		var model_index := clampi(int(spec.model), 0, TWISTED_TREES.size() - 1)
		var tree := TWISTED_TREES[model_index].instantiate() as Node3D
		tree.name = "ObservatoryWindTree%02d" % index
		_place_imported(tree, _v3(spec.at), float(spec.height_m))
		tree.rotation.y = deg_to_rad(float(spec.yaw_deg))
		tree.set_meta("observatory_role", "edge_ecology")
		add_child(tree)
	var rocks := cfg.rock_positions as Array
	for index in rocks.size():
		var rock := ROCKS[index % ROCKS.size()].instantiate() as Node3D
		rock.name = "ObservatoryEdgeRock%02d" % index
		_place_imported(rock, _v3(rocks[index]), 1.15 + float(index % 3) * 0.28)
		rock.rotation.y = float(index) * 0.83
		rock.set_meta("observatory_role", "edge_ecology")
		add_child(rock)


func _add_imported(parent: Node3D, label: String, packed: PackedScene,
		at: Vector3, target_height: float) -> Node3D:
	var instance := packed.instantiate() as Node3D
	instance.name = label
	_place_imported(instance, at, target_height)
	instance.set_meta("observatory_role", "instrument_station")
	parent.add_child(instance)
	return instance


func _place_imported(instance: Node3D, at: Vector3, target_height: float) -> void:
	var bounds := RENDER_BOUNDS.measure(instance)
	var factor := target_height / maxf(bounds.size.y, 0.01)
	instance.scale = Vector3.ONE * factor
	instance.position = at - Vector3(bounds.get_center().x * factor,
		bounds.position.y * factor, bounds.get_center().z * factor)


func _add_box(label: String, at: Vector3, size: Vector3,
		material: Material, role: String) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.name = label
	var mesh := BoxMesh.new()
	mesh.size = size
	node.mesh = mesh
	node.position = at
	node.material_override = material
	node.set_meta("observatory_role", role)
	add_child(node)
	return node


func _add_cylinder(label: String, at: Vector3, radius: float, height: float,
		material: Material, role: String) -> MeshInstance3D:
	return _add_cylinder_to(self, label, at, radius, height, material, role)


func _add_cylinder_to(parent: Node3D, label: String, at: Vector3, radius: float,
		height: float, material: Material, role: String) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.name = label
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = 24
	node.mesh = mesh
	node.position = at
	node.material_override = material
	node.set_meta("observatory_role", role)
	parent.add_child(node)
	return node


func _add_ring(label: String, inner: float, outer: float, at: Vector3,
		material: Material, role: String) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.name = label
	var mesh := TorusMesh.new()
	mesh.inner_radius = inner
	mesh.outer_radius = outer
	mesh.rings = 48
	mesh.ring_segments = 8
	node.mesh = mesh
	node.position = at
	node.material_override = material
	node.set_meta("observatory_role", role)
	add_child(node)
	return node


func _add_cylinder_between(label: String, a: Vector3, b: Vector3, radius: float,
		material: Material, role: String) -> MeshInstance3D:
	var node := _add_cylinder(label, a.lerp(b, 0.5), radius, a.distance_to(b), material, role)
	node.quaternion = Quaternion(Vector3.UP, (b - a).normalized())
	return node


func _material(materials: Dictionary, key: String) -> Material:
	var value: Variant = materials.get(key)
	if value is Material:
		return value as Material
	var fallback := StandardMaterial3D.new()
	fallback.albedo_color = Color("#776f62")
	fallback.roughness = 0.84
	return fallback


func _bronze() -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = Color("#a97e3e")
	material.metallic = 0.62
	material.roughness = 0.38
	return material


func _colour_material(colour: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = colour
	material.roughness = 0.76
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	return material


func _glow_material(colour: Color) -> StandardMaterial3D:
	var material := _colour_material(colour.darkened(0.22))
	material.emission_enabled = true
	material.emission = colour
	material.emission_energy_multiplier = 1.15
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
