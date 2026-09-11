extends Node3D

## Visual-only dressing for the old arch footing at The Capacitor Grove.
## The functional footing, encounter, pickup and road remain owned by their
## existing runtimes. This crescent makes the site legible from the road while
## keeping the nine-metre socket open and adding no collision.

const CONFIG_PATH := "res://data/config/stormwood_capacitor_grove.json"
const PYLON_PATH := "res://assets/environment/team_tether/tether_pylon.glb"
const BOUNDS := preload("res://scripts/characters/render_bounds.gd")
const PYLON_MATERIALS := preload("res://scripts/world/tether_pylon_materials.gd")

const METAL := Color("263943")
const STORMGLASS := Color("70d4e8")


func build(world: Node3D, simulation_only: bool = false) -> void:
	if get_child_count() > 0:
		return
	var config: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(CONFIG_PATH))
	var origin := Vector2(float(config.origin[0]), float(config.origin[1]))
	var origin_ground := float(world.call("ground_height_at", origin.x, origin.y))
	var crown_points: Array[Vector3] = []
	for raw: Dictionary in config.get("banks", []):
		var local_xz := Vector2(float(raw.at[0]), float(raw.at[1]))
		var bank := Node3D.new()
		bank.name = "CapacitorBank_%s" % str(raw.id)
		bank.position = Vector3(local_xz.x, _local_ground(world, origin + local_xz, origin_ground), local_xz.y)
		add_child(bank)
		_add_plinth(bank)
		var height_m := float(raw.height_m)
		if not simulation_only:
			_add_pylon(bank, height_m)
		_add_charge_rings(bank, height_m)
		crown_points.append(bank.position + Vector3(0.0, height_m * 0.82, 0.0))
	var collector_height := float(config.get("collector_height_m", 8.0))
	var collector := Node3D.new()
	collector.name = "OverheadCollector"
	collector.position = Vector3(0.0, collector_height, 4.8)
	add_child(collector)
	_add_collector_crown(collector)
	for i in crown_points.size():
		_add_beam("ConductorArc%d" % i, crown_points[i], collector.position, 0.12, _glow(STORMGLASS, 1.35))
	_add_beam("WestGroundBus", Vector3(-10.5, 0.22, 3.5), Vector3(-4.8, 0.22, 0.0), 0.18, _metal())
	_add_beam("EastGroundBus", Vector3(10.5, 0.22, 3.5), Vector3(4.8, 0.22, 0.0), 0.18, _metal())
	var light := OmniLight3D.new()
	light.name = "CapacitorAfterglow"
	light.position = collector.position
	light.light_color = STORMGLASS
	light.omni_range = float(config.get("night_light_range_m", 17.0))
	light.light_energy = float(config.get("night_light_energy", 1.45))
	light.shadow_enabled = true
	add_child(light)


func _local_ground(world: Node3D, xz: Vector2, origin_ground: float) -> float:
	return float(world.call("ground_height_at", xz.x, xz.y)) - origin_ground + 0.16


func _add_pylon(bank: Node3D, target_height: float) -> void:
	var packed := load(PYLON_PATH) as PackedScene
	if packed == null:
		return
	var prop := packed.instantiate() as Node3D
	prop.name = "InstalledPylon"
	PYLON_MATERIALS.apply(prop, true)
	var bounds := BOUNDS.measure(prop)
	var factor := target_height / maxf(0.1, bounds.size.y)
	prop.scale = Vector3.ONE * factor
	prop.position.y = -bounds.position.y * factor + 0.28
	bank.add_child(prop)


func _add_plinth(bank: Node3D) -> void:
	var plinth := MeshInstance3D.new()
	plinth.name = "GroundedPlinth"
	var mesh := CylinderMesh.new()
	mesh.top_radius = 2.15
	mesh.bottom_radius = 2.6
	mesh.height = 0.35
	plinth.mesh = mesh
	plinth.position.y = 0.16
	plinth.material_override = _metal()
	bank.add_child(plinth)


func _add_charge_rings(bank: Node3D, target_height: float) -> void:
	for i in 3:
		var ring := MeshInstance3D.new()
		ring.name = "ChargeRing%d" % i
		var mesh := TorusMesh.new()
		mesh.inner_radius = 1.28 - float(i) * 0.12
		mesh.outer_radius = mesh.inner_radius + 0.13
		ring.mesh = mesh
		ring.position.y = target_height * (0.28 + float(i) * 0.22)
		ring.material_override = _glow(STORMGLASS, 0.9)
		bank.add_child(ring)


func _add_collector_crown(parent: Node3D) -> void:
	var core := MeshInstance3D.new()
	core.name = "StormglassCore"
	var mesh := SphereMesh.new()
	mesh.radius = 0.7
	mesh.height = 1.4
	core.mesh = mesh
	core.material_override = _glow(STORMGLASS, 1.8)
	parent.add_child(core)
	for i in 4:
		var vane := MeshInstance3D.new()
		vane.name = "CollectorVane%d" % i
		var vane_mesh := BoxMesh.new()
		vane_mesh.size = Vector3(0.18, 2.6, 0.46)
		vane.mesh = vane_mesh
		vane.position = Vector3(cos(float(i) * PI * 0.5) * 1.25, 0.0, sin(float(i) * PI * 0.5) * 1.25)
		vane.rotation.y = -float(i) * PI * 0.5
		vane.material_override = _metal()
		parent.add_child(vane)


func _add_beam(node_name: String, from: Vector3, to: Vector3, radius: float, material: Material) -> void:
	var delta := to - from
	var beam := MeshInstance3D.new()
	beam.name = node_name
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = delta.length()
	beam.mesh = mesh
	beam.position = (from + to) * 0.5
	beam.quaternion = Quaternion(Vector3.UP, delta.normalized())
	beam.material_override = material
	add_child(beam)


func _metal() -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = METAL
	material.metallic = 0.55
	material.roughness = 0.48
	return material


func _glow(colour: Color, energy: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = colour.darkened(0.32)
	material.emission_enabled = true
	material.emission = colour
	material.emission_energy_multiplier = energy
	return material
