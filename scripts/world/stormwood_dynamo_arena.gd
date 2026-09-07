extends Node3D

## Kitbashed mechanics on the Stormheart Tree's existing top floor. Arena-local
## coordinates are shared by rendered banks, plates, and authoritative rules.
const RULES := preload("res://scripts/world/stormwood_dynamo_rules.gd")
const BOUNDS := preload("res://scripts/characters/render_bounds.gd")
var rules: RefCounted
var _banks: Array[Dictionary] = []
var _plates: Array[MeshInstance3D] = []

func build(policy: RefCounted, simulation_only: bool = false) -> void:
	rules = policy
	for i in int(rules.config.bank_count):
		var point: Vector2 = rules.bank_position(i)
		var bank := Node3D.new()
		bank.name = "CapacitorBank%d" % i
		bank.position = Vector3(point.x, 0, point.y)
		add_child(bank)
		var conduit := StaticBody3D.new()
		conduit.name = "ExposedConduit"
		conduit.collision_layer = 32
		conduit.collision_mask = 0
		conduit.set_meta("dynamo_conduit", i)
		var shape := CollisionShape3D.new()
		var sphere := SphereShape3D.new()
		sphere.radius = 1.25
		shape.shape = sphere
		shape.position.y = 1.25
		conduit.add_child(shape)
		bank.add_child(conduit)
		if simulation_only:
			continue
		var packed := load("res://assets/environment/team_tether/tether_pylon.glb") as PackedScene
		var prop := packed.instantiate() as Node3D
		var bounds := BOUNDS.measure(prop)
		var factor := 7.0 / maxf(0.1, bounds.size.y)
		prop.scale = Vector3.ONE * factor
		prop.position.y = -bounds.position.y * factor
		bank.add_child(prop)
		var light := OmniLight3D.new()
		light.position.y = 4
		light.omni_range = 14
		light.light_color = Color("b5a0ff")
		bank.add_child(light)
		var lane := MeshInstance3D.new()
		lane.name = "DischargeLane%d" % i
		var mesh := PlaneMesh.new()
		mesh.size = Vector2(float(rules.config.arena_radius_m) * 2, float(rules.config.lane_half_width_m) * 2)
		lane.mesh = mesh
		lane.position.y = 0.09
		lane.rotation.y = -TAU * float(i) / float(rules.config.bank_count)
		var material := _glow(Color("8876d8"), 0.1)
		lane.material_override = material
		add_child(lane)
		_banks.append({"node":bank, "lane":lane, "material":material, "light":light})
	if not simulation_only:
		for raw: Array in rules.config.plates:
			var plate := MeshInstance3D.new()
			plate.name = "GroundedRodPlate%d" % _plates.size()
			var mesh := CylinderMesh.new()
			mesh.top_radius = float(rules.config.plate_radius_m)
			mesh.bottom_radius = mesh.top_radius
			mesh.height = 0.12
			plate.mesh = mesh
			plate.position = Vector3(float(raw[0]), 0.14, float(raw[1]))
			plate.material_override = _glow(Color("63d4b0"), 0.45)
			add_child(plate)
			_plates.append(plate)
	show_state(rules.bank_state())

func _glow(colour: Color, energy: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = colour
	material.emission_enabled = true
	material.emission = colour
	material.emission_energy_multiplier = energy
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	return material

func show_state(state: Dictionary) -> void:
	for i in _banks.size():
		var row: Dictionary = _banks[i]
		var active := i == int(state.get("bank", -1))
		var firing := active and str(state.get("state", "")) == "fire"
		var charge := float(state.get("charge", 0.0)) if active else 0.0
		row.light.light_energy = 3.0 if firing else charge * 1.6
		row.lane.visible = active and str(state.get("state", "")) != "recovery"
		row.material.emission_energy_multiplier = 4.0 if firing else charge * 0.7
