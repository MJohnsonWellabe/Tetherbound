extends Node3D

## Collision-free identity layer for the existing flight-lesson dais/perches.

const CONFIG_PATH := "res://data/config/cloudreach_flight_aerie_visual.json"
const RENDER_BOUNDS := preload("res://scripts/characters/render_bounds.gd")

var _built := false


func build(materials: Dictionary) -> void:
	if _built:
		return
	_built = true
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(CONFIG_PATH))
	if not parsed is Dictionary:
		push_error("Flight Aerie visual config is invalid")
		return
	var cfg := parsed as Dictionary
	var blue := _colour_material(Color(str(cfg.get("banner_blue", "#315f9a"))), false)
	var gold := _colour_material(Color(str(cfg.get("banner_gold", "#d6ad52"))), false)
	_add_ring("AerieOuterCompass", cfg.get("outer_ring_m", [10.3, 10.8]) as Array, blue)
	_add_ring("AerieInnerCompass", cfg.get("inner_ring_m", [5.7, 6.1]) as Array, gold)
	for index in 8:
		var angle := TAU * float(index) / 8.0
		var radial := MeshInstance3D.new()
		radial.name = "LaunchCompassRay%02d" % (index + 1)
		var mesh := BoxMesh.new()
		mesh.size = Vector3(0.20, 0.055, 4.2)
		radial.mesh = mesh
		radial.material_override = gold if index % 2 == 0 else blue
		radial.position = Vector3(sin(angle) * 8.1, 0.14, cos(angle) * 8.1)
		radial.rotation.y = angle
		radial.set_meta("flight_aerie_role", "launch_compass")
		add_child(radial)
	_add_banners(cfg)
	_add_signals(cfg)


func _add_ring(label: String, radii: Array, material: Material) -> void:
	var ring := MeshInstance3D.new()
	ring.name = label
	var mesh := TorusMesh.new()
	mesh.inner_radius = float(radii[0])
	mesh.outer_radius = float(radii[1])
	mesh.rings = 48
	mesh.ring_segments = 8
	ring.mesh = mesh
	ring.material_override = material
	ring.position.y = 0.14
	# TorusMesh's axle is local Y, so its unrotated plane is already the X/Z
	# launch floor. Rotating it around X would stand the compass upright like a
	# portal and cut across the Fly lesson instead of marking the dais.
	ring.set_meta("flight_aerie_role", "launch_compass")
	add_child(ring)


func _add_banners(cfg: Dictionary) -> void:
	var packed := load(str(cfg.get("banner_scene", ""))) as PackedScene
	if packed == null:
		push_error("Flight Aerie banner asset is missing")
		return
	for index in (cfg.get("banner_positions", []) as Array).size():
		var banner := packed.instantiate() as Node3D
		banner.name = "AerieWindBanner%02d" % (index + 1)
		var bounds := RENDER_BOUNDS.measure(banner)
		var factor := 3.6 / maxf(bounds.size.y, 0.01)
		banner.scale = Vector3.ONE * factor
		var position := _v3((cfg.banner_positions as Array)[index])
		banner.position = position - Vector3(bounds.get_center().x, bounds.get_center().y, bounds.get_center().z) * factor
		banner.rotation.y = atan2(position.x, position.z) + PI
		banner.set_meta("flight_aerie_role", "wind_banner")
		add_child(banner)
		_override_material(banner, _colour_material(
			Color(str(cfg.get("banner_blue", "#315f9a"))) if index != 1 else Color(str(cfg.get("banner_gold", "#d6ad52"))), false))


func _add_signals(cfg: Dictionary) -> void:
	var colour := Color(str(cfg.get("signal_colour", "#72e4dc")))
	var packed := load(str(cfg.get("signal_scene", ""))) as PackedScene
	if packed == null:
		push_error("Flight Aerie signal asset is missing")
		return
	for index in (cfg.get("signal_positions", []) as Array).size():
		var position := _v3((cfg.signal_positions as Array)[index])
		var signal_node := packed.instantiate() as Node3D
		signal_node.name = "AerieLandingSignal%02d" % (index + 1)
		var bounds := RENDER_BOUNDS.measure(signal_node)
		var factor := float(cfg.get("signal_height_m", 1.65)) / maxf(bounds.size.y, 0.01)
		signal_node.scale = Vector3.ONE * factor
		signal_node.position = position - Vector3(bounds.get_center().x * factor,
			bounds.position.y * factor, bounds.get_center().z * factor)
		signal_node.set_meta("flight_aerie_role", "landing_signal")
		add_child(signal_node)
		var light := OmniLight3D.new()
		light.name = "AerieLandingLight%02d" % (index + 1)
		light.light_color = colour
		light.light_energy = float(cfg.get("signal_light_energy", 2.35))
		light.omni_range = float(cfg.get("signal_light_range_m", 10.5))
		light.shadow_enabled = false
		var flame_local := Vector3.UP * bounds.end.y
		if signal_node.has_method("flame_local_position"):
			flame_local = signal_node.call("flame_local_position")
		light.position = signal_node.position + flame_local * factor
		light.set_meta("flight_aerie_role", "landing_light")
		add_child(light)


func _colour_material(colour: Color, emissive: bool) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = colour
	material.roughness = 0.75
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	if emissive:
		material.emission_enabled = true
		material.emission = colour
		material.emission_energy_multiplier = 2.1
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
