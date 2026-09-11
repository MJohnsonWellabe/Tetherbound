extends Node3D

## Visual-only composition for Broken Skyroad Arch. The landmark mesa retains
## traversal collision; this layer supplies the authored ruin silhouette.

const CONFIG_PATH := "res://data/config/cloudreach_broken_skyroad_arch_visual.json"
const CASTLE_TOWER := preload("res://assets/buildings/quaternius_castle/SmallSquareTowerBricks.obj")
const CASTLE_WALL := preload("res://assets/buildings/quaternius_castle/TallWallBricks.obj")

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
	rotation.y = deg_to_rad(float(cfg.get("route_yaw_deg", 0.0)))
	var masonry := _material(materials, "masonry")
	var trim := _material(materials, "stone_light")
	var path := _material(materials, "path")
	var bronze := _material(materials, "bronze")
	for index in (cfg.get("standing_supports", []) as Array).size():
		var spec := (cfg.standing_supports as Array)[index] as Dictionary
		var piece := _add_scaled_mesh("RuinedSupport%02d" % (index + 1), CASTLE_TOWER,
			_v3(spec.position), _v3(spec.size), masonry, "standing_support")
		piece.rotation.z = deg_to_rad(float(spec.get("lean_deg", 0.0)))
	_add_broken_arch_curve(cfg.get("arch_curve", {}) as Dictionary, masonry, trim)
	for index in (cfg.get("skyroad_fragments", []) as Array).size():
		var spec := (cfg.skyroad_fragments as Array)[index] as Dictionary
		var fragment := _add_scaled_mesh("SuspendedSkyroadFragment%02d" % (index + 1),
			CASTLE_WALL, _v3(spec.position), _v3(spec.size), masonry, "skyroad_fragment")
		fragment.rotation = Vector3(deg_to_rad(float(spec.get("pitch_deg", 0.0))),
			deg_to_rad(float(spec.get("yaw_deg", 0.0))),
			deg_to_rad(float(spec.get("roll_deg", 0.0))))
	for index in (cfg.get("fallen_spans", []) as Array).size():
		var spec := (cfg.fallen_spans as Array)[index] as Dictionary
		var piece := _add_scaled_mesh("FallenSkyroadSpan%02d" % (index + 1), CASTLE_WALL,
			_v3(spec.position), _v3(spec.size), masonry, "fallen_span")
		piece.rotation = Vector3(deg_to_rad(float(spec.get("pitch_deg", 0.0))),
			deg_to_rad(float(spec.get("yaw_deg", 0.0))),
			deg_to_rad(float(spec.get("roll_deg", 0.0))))
	for index in (cfg.get("approach_pavers", []) as Array).size():
		var spec := (cfg.approach_pavers as Array)[index] as Dictionary
		var paver := _add_box("SkyroadPaver%02d" % (index + 1), _v3(spec.position),
			_v3(spec.size), path, "approach_paver")
		paver.rotation.y = deg_to_rad(float(spec.get("yaw_deg", 0.0)))
	_add_signal(cfg.get("route_signal", {}) as Dictionary, bronze)
	_add_night_lights(cfg.get("night_lights", []) as Array)


func _add_broken_arch_curve(cfg: Dictionary, masonry: Material, trim: Material) -> void:
	var centre := _v3(cfg.get("centre", [0.0, 4.4, 0.0]))
	var radius := float(cfg.get("radius_x_m", 6.2))
	var rise := float(cfg.get("rise_y_m", 5.0))
	var count := int(cfg.get("segment_count", 15))
	var missing_raw := cfg.get("missing_segments", [3, 4]) as Array
	var missing := {}
	for raw: Variant in missing_raw:
		missing[int(raw)] = true
	for index in count:
		if missing.has(index):
			continue
		var angle := PI * float(index) / float(count - 1)
		var at := centre + Vector3(cos(angle) * radius, sin(angle) * rise, 0.0)
		var stone := _add_box("ArchVoussoir%02d" % (index + 1), at,
			Vector3(1.45, 2.0, 4.25), masonry,
			"arch_voussoir")
		stone.rotation.z = angle - PI * 0.5
	var keystone := _add_box("FracturedKeystone", centre + Vector3(0.0, rise + 0.15, -0.05),
		Vector3(1.75, 2.35, 4.5), trim, "fractured_keystone")
	keystone.rotation.z = deg_to_rad(-7.0)


func _add_night_lights(specs: Array) -> void:
	for index in specs.size():
		var spec := specs[index] as Dictionary
		var light := OmniLight3D.new()
		light.name = "ArchSeparationLight%02d" % (index + 1)
		light.position = _v3(spec.get("position", [0.0, 3.0, -1.5]))
		light.light_color = Color(str(spec.get("colour", "#83b9d8")))
		light.light_energy = float(spec.get("energy", 2.0))
		light.omni_range = float(spec.get("range_m", 12.0))
		light.shadow_enabled = false
		light.set_meta("broken_arch_role", "night_separation_light")
		add_child(light)


func _add_signal(cfg: Dictionary, bronze: Material) -> void:
	var at := _v3(cfg.get("position", [0.0, 10.8, -0.4]))
	var colour := Color(str(cfg.get("colour", "#72dcdb")))
	var ring := MeshInstance3D.new()
	ring.name = "SkyroadSignalRing"
	var torus := TorusMesh.new()
	torus.inner_radius = 0.68
	torus.outer_radius = 0.86
	torus.rings = 24
	torus.ring_segments = 8
	ring.mesh = torus
	ring.material_override = bronze
	ring.position = at
	ring.rotation.x = PI * 0.5
	ring.set_meta("broken_arch_role", "route_signal")
	add_child(ring)
	var glow_material := StandardMaterial3D.new()
	glow_material.albedo_color = colour
	glow_material.emission_enabled = true
	glow_material.emission = colour
	glow_material.emission_energy_multiplier = 2.8
	var glow := MeshInstance3D.new()
	glow.name = "SkyroadSignalGlow"
	var glow_mesh := SphereMesh.new()
	glow_mesh.radius = 0.38
	glow_mesh.height = 0.76
	glow.mesh = glow_mesh
	glow.material_override = glow_material
	glow.position = at
	glow.set_meta("broken_arch_role", "route_signal_glow")
	add_child(glow)
	var light := OmniLight3D.new()
	light.name = "SkyroadSignalLight"
	light.position = at + Vector3(0.0, 0.2, 0.0)
	light.light_color = colour
	light.light_energy = float(cfg.get("light_energy", 3.0))
	light.omni_range = float(cfg.get("light_range_m", 16.0))
	light.shadow_enabled = false
	light.set_meta("broken_arch_role", "route_signal_light")
	add_child(light)


func _add_scaled_mesh(label: String, mesh: Mesh, at: Vector3, size: Vector3,
		material: Material, role: String) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.name = label
	instance.mesh = mesh
	instance.material_override = material
	var bounds := mesh.get_aabb()
	instance.scale = size / bounds.size
	instance.position = at - bounds.get_center() * instance.scale
	instance.set_meta("broken_arch_role", role)
	add_child(instance)
	return instance


func _add_box(label: String, at: Vector3, size: Vector3, material: Material,
		role: String) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.name = label
	var mesh := BoxMesh.new()
	mesh.size = size
	instance.mesh = mesh
	instance.material_override = material
	instance.position = at
	instance.set_meta("broken_arch_role", role)
	add_child(instance)
	return instance


func _material(materials: Dictionary, key: String) -> Material:
	var value: Variant = materials.get(key)
	if value is Material:
		return value as Material
	var fallback := StandardMaterial3D.new()
	fallback.albedo_color = Color("#817865")
	fallback.roughness = 0.84
	return fallback


static func route_clear_half_width(cfg: Dictionary) -> float:
	return float(cfg.get("route_clear_half_width_m", 4.5))


static func _v3(raw: Variant) -> Vector3:
	if raw is Array and (raw as Array).size() >= 3:
		return Vector3(float((raw as Array)[0]), float((raw as Array)[1]),
			float((raw as Array)[2]))
	return Vector3.ZERO
