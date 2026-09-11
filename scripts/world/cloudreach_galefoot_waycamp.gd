extends Node3D

## Focused presentation layer for Galefoot Waycamp. The settlement houses and
## working RestPoint remain owned by their production systems; this adds the
## missing communal hearth, human-scale seating and a warm night landmark.

const CONFIG_PATH := "res://data/config/cloudreach_galefoot_waycamp_visual.json"
const RENDER_BOUNDS := preload("res://scripts/characters/render_bounds.gd")
const BONFIRE := preload("res://assets/props/quaternius_survival/Bonfire.obj")
const BONFIRE_FIRE := preload("res://assets/props/quaternius_survival/Bonfire_Fire.obj")
const BENCH := preload("res://assets/props/quaternius_fantasy/Bench.gltf")
const CRATE := preload("res://assets/props/quaternius_fantasy/Crate_Wooden.gltf")
const BARREL := preload("res://assets/props/quaternius_fantasy/Barrel.gltf")

var _built := false


func build(materials: Dictionary) -> void:
	if _built:
		return
	_built = true
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(CONFIG_PATH))
	if not parsed is Dictionary:
		push_error("Galefoot Waycamp visual config is invalid")
		return
	var cfg := parsed as Dictionary
	_add_hearth(cfg.get("hearth", {}) as Dictionary, materials)
	for index in (cfg.get("benches", []) as Array).size():
		var spec := (cfg.benches as Array)[index] as Dictionary
		_add_scene("HearthBench%02d" % (index + 1), BENCH, _v3(spec.position),
			float(spec.get("height_m", 1.15)), float(spec.get("yaw_deg", 0.0)),
			"hearth_seat")
	_add_lantern_line(cfg.get("lantern_line", {}) as Dictionary, materials)
	for index in (cfg.get("supply_corner", []) as Array).size():
		var spec := (cfg.supply_corner as Array)[index] as Dictionary
		var packed: PackedScene = CRATE if str(spec.get("asset", "")) == "crate" else BARREL
		_add_scene("WaycampSupply%02d" % (index + 1), packed, _v3(spec.position),
			float(spec.get("height_m", 1.0)), float(spec.get("yaw_deg", 0.0)),
			"supply_dressing")


func _add_hearth(cfg: Dictionary, materials: Dictionary) -> void:
	var at := _v3(cfg.get("position", [-4.0, 0.12, -1.0]))
	_add_mesh("GalefootCommunalBonfire", BONFIRE, at,
		float(cfg.get("bonfire_width_m", 4.2)), _material(materials, "weathered_timber"),
		"communal_hearth", true)
	var flame_material := StandardMaterial3D.new()
	flame_material.albedo_color = Color("#ff9f45")
	flame_material.emission_enabled = true
	flame_material.emission = Color("#ff8a32")
	flame_material.emission_energy_multiplier = 2.2
	_add_mesh("GalefootCommunalFlame", BONFIRE_FIRE, at + Vector3.UP * 0.35,
		float(cfg.get("flame_height_m", 2.8)), flame_material, "communal_flame", false)
	var light := OmniLight3D.new()
	light.name = "GalefootHearthLight"
	light.light_color = Color(str(cfg.get("light_colour", "#ffb568")))
	light.light_energy = float(cfg.get("light_energy", 4.2))
	light.omni_range = float(cfg.get("light_range_m", 24.0))
	light.shadow_enabled = false
	light.position = at + Vector3.UP * 2.4
	light.set_meta("waycamp_role", "hearth_light")
	add_child(light)


func _add_lantern_line(cfg: Dictionary, materials: Dictionary) -> void:
	var start := _v3(cfg.get("from", [-11.0, 6.8, 3.0]))
	var finish := _v3(cfg.get("to", [8.0, 6.8, 3.0]))
	var count := maxi(int(cfg.get("bulb_count", 7)), 3)
	var sag := float(cfg.get("sag_m", 1.15))
	var bulb_material := StandardMaterial3D.new()
	bulb_material.albedo_color = Color(str(cfg.get("bulb_colour", "#ffd98a")))
	bulb_material.emission_enabled = true
	bulb_material.emission = bulb_material.albedo_color
	bulb_material.emission_energy_multiplier = 2.0
	var points: Array[Vector3] = []
	for index in count:
		var t := float(index) / float(count - 1)
		var point := start.lerp(finish, t)
		point.y -= sin(t * PI) * sag
		points.append(point)
		var bulb := MeshInstance3D.new()
		bulb.name = "WaycampLantern%02d" % (index + 1)
		var sphere := SphereMesh.new()
		sphere.radius = 0.075
		sphere.height = 0.20
		bulb.mesh = sphere
		bulb.material_override = bulb_material
		bulb.position = point
		bulb.set_meta("waycamp_role", "lantern_bulb")
		add_child(bulb)
		if index > 0:
			_add_cable("WaycampLanternCable%02d" % index, points[index - 1], point,
				_material(materials, "weathered_timber"))
	var light := OmniLight3D.new()
	light.name = "WaycampLanternFill"
	light.light_color = Color(str(cfg.get("bulb_colour", "#ffd98a")))
	light.light_energy = float(cfg.get("light_energy", 1.7))
	light.omni_range = float(cfg.get("light_range_m", 18.0))
	light.shadow_enabled = false
	light.position = start.lerp(finish, 0.5) - Vector3.UP * (sag * 0.6)
	light.set_meta("waycamp_role", "lantern_light")
	add_child(light)


func _add_cable(label: String, a: Vector3, b: Vector3, material: Material) -> void:
	var cable := MeshInstance3D.new()
	cable.name = label
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.035
	mesh.bottom_radius = 0.035
	mesh.height = a.distance_to(b)
	mesh.radial_segments = 8
	cable.mesh = mesh
	cable.material_override = material
	cable.position = a.lerp(b, 0.5)
	cable.quaternion = Quaternion(Vector3.UP, (b - a).normalized())
	cable.set_meta("waycamp_role", "lantern_cable")
	add_child(cable)


func _add_scene(label: String, packed: PackedScene, at: Vector3, height: float,
		yaw_deg: float, role: String) -> Node3D:
	var instance := packed.instantiate() as Node3D
	instance.name = label
	var bounds := RENDER_BOUNDS.measure(instance)
	var factor := height / maxf(bounds.size.y, 0.01)
	instance.scale = Vector3.ONE * factor
	instance.position = at - Vector3(bounds.get_center().x, bounds.position.y,
		bounds.get_center().z) * factor
	instance.rotation.y = deg_to_rad(yaw_deg)
	instance.set_meta("waycamp_role", role)
	add_child(instance)
	return instance


func _add_mesh(label: String, mesh: Mesh, at: Vector3, target: float,
		material: Material, role: String, by_width: bool) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.name = label
	instance.mesh = mesh
	instance.material_override = material
	var bounds := mesh.get_aabb()
	var source := maxf(bounds.size.x, bounds.size.z) if by_width else bounds.size.y
	var factor := target / maxf(source, 0.01)
	instance.scale = Vector3.ONE * factor
	instance.position = at - Vector3(bounds.get_center().x, bounds.position.y,
		bounds.get_center().z) * factor
	instance.set_meta("waycamp_role", role)
	add_child(instance)
	return instance


func _material(materials: Dictionary, key: String) -> Material:
	var value: Variant = materials.get(key)
	if value is Material:
		return value as Material
	var fallback := StandardMaterial3D.new()
	fallback.albedo_color = Color("#79664f")
	fallback.roughness = 0.85
	return fallback


static func _v3(raw: Variant) -> Vector3:
	if raw is Array and (raw as Array).size() >= 3:
		return Vector3(float((raw as Array)[0]), float((raw as Array)[1]), float((raw as Array)[2]))
	return Vector3.ZERO
