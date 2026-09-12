extends Node3D

## Collision-free Stormward threshold. Existing crown, descent and realm gate
## retain traversal and progression ownership.

const CONFIG_PATH := "res://data/config/cloudreach_stormward_overlook_visual.json"
const CASTLE_TOWER := preload("res://assets/buildings/quaternius_castle/SmallSquareTowerBricks.obj")
const CASTLE_WALL := preload("res://assets/buildings/quaternius_castle/TallWallBricks.obj")

var _built := false


func build(materials: Dictionary) -> void:
	if _built:
		return
	_built = true
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(CONFIG_PATH))
	if not parsed is Dictionary:
		push_error("Stormward Overlook visual config is invalid")
		return
	var cfg := parsed as Dictionary
	var masonry := _material(materials, "masonry")
	var trim := _material(materials, "masonry_trim")
	var bronze := _material(materials, "bronze")
	for index in (cfg.get("survey_piers", []) as Array).size():
		var spec := (cfg.survey_piers as Array)[index] as Dictionary
		var piece := _scaled_mesh("StormwardSurveyPier%02d" % (index + 1), CASTLE_TOWER,
			_v3(spec.position), _v3(spec.size), masonry, "survey_pier")
		piece.rotation.z = deg_to_rad(float(spec.get("lean_deg", 0.0)))
	for index in (cfg.get("ruined_wings", []) as Array).size():
		var spec := (cfg.ruined_wings as Array)[index] as Dictionary
		var piece := _scaled_mesh("StormwardRuinedWing%02d" % (index + 1), CASTLE_WALL,
			_v3(spec.position), _v3(spec.size), masonry, "ruined_wing")
		piece.rotation = Vector3(deg_to_rad(float(spec.get("pitch_deg", 0.0))),
			deg_to_rad(float(spec.get("yaw_deg", 0.0))), deg_to_rad(float(spec.get("roll_deg", 0.0))))
	for index in (cfg.get("approach_pavers", []) as Array).size():
		var spec := (cfg.approach_pavers as Array)[index] as Dictionary
		var paver := _box("StormwardPaver%02d" % (index + 1), _v3(spec.position),
			_v3(spec.size), trim, "approach_paver")
		paver.rotation = Vector3(deg_to_rad(float(spec.get("pitch_deg", 0.0))),
			deg_to_rad(float(spec.get("yaw_deg", 0.0))), 0.0)
	_add_needle(cfg.get("stormward_needle", {}) as Dictionary, bronze)
	_add_compass_signal(cfg.get("compass_signal", {}) as Dictionary, bronze)
	_add_banners(cfg.get("banners", []) as Array)
	_add_beacons(cfg.get("beacons", []) as Array, bronze)


func _add_needle(cfg: Dictionary, material: Material) -> void:
	var at := _v3(cfg.get("position", [0.0, 0.16, 4.0]))
	_box("StormwardNeedleStem", at, Vector3(0.7, 0.14, 8.0), material, "stormward_needle")
	for side: float in [-1.0, 1.0]:
		var barb := _box("StormwardNeedleBarb", at + Vector3(side * 1.25, 0.02, 3.5),
			Vector3(0.55, 0.16, 3.6), material, "stormward_needle")
		barb.rotation.y = deg_to_rad(side * 42.0)


func _add_compass_signal(cfg: Dictionary, bronze: Material) -> void:
	var at := _v3(cfg.get("position", [0.0, 6.8, -0.5]))
	var colour := Color(str(cfg.get("colour", "#72dcdb")))
	var ring := MeshInstance3D.new()
	ring.name = "StormwardCompassRing"
	var torus := TorusMesh.new()
	torus.inner_radius = 1.28
	torus.outer_radius = 1.58
	torus.rings = 28
	torus.ring_segments = 10
	ring.mesh = torus
	ring.material_override = bronze
	ring.position = at
	ring.rotation.x = PI * 0.5
	ring.set_meta("stormward_role", "compass_signal")
	add_child(ring)
	var glow_material := StandardMaterial3D.new()
	glow_material.albedo_color = colour
	glow_material.emission_enabled = true
	glow_material.emission = colour
	glow_material.emission_energy_multiplier = 2.5
	var core := _box("StormwardCompassCore", at, Vector3(0.42, 2.1, 0.22),
		glow_material, "compass_signal_core")
	core.rotation.z = deg_to_rad(-18.0)


func _add_banners(specs: Array) -> void:
	for index in specs.size():
		var spec := specs[index] as Dictionary
		var banner := MeshInstance3D.new()
		banner.name = "StormwardStreamer%02d" % (index + 1)
		var plane := PlaneMesh.new()
		plane.orientation = PlaneMesh.FACE_Z
		plane.size = _v2(spec.get("size", [2.2, 5.5]))
		plane.subdivide_width = 2
		plane.subdivide_depth = 4
		banner.mesh = plane
		var cloth := StandardMaterial3D.new()
		cloth.albedo_color = Color(str(spec.get("colour", "#315f6c")))
		cloth.roughness = 0.85
		cloth.cull_mode = BaseMaterial3D.CULL_DISABLED
		banner.material_override = cloth
		banner.position = _v3(spec.position)
		banner.set_meta("stormward_role", "direction_streamer")
		add_child(banner)


func _add_beacons(specs: Array, bronze: Material) -> void:
	for index in specs.size():
		var spec := specs[index] as Dictionary
		var at := _v3(spec.position)
		var colour := Color(str(spec.get("colour", "#72dcdb")))
		_cylinder("StormwardBeaconBowl%02d" % (index + 1), at, 0.62, 0.32, bronze, "beacon_bowl")
		var glow_material := StandardMaterial3D.new()
		glow_material.albedo_color = colour
		glow_material.emission_enabled = true
		glow_material.emission = colour
		glow_material.emission_energy_multiplier = 2.8
		var glow := MeshInstance3D.new()
		glow.name = "StormwardBeaconGlow%02d" % (index + 1)
		glow.mesh = SphereMesh.new()
		glow.material_override = glow_material
		glow.position = at + Vector3.UP * 0.75
		glow.set_meta("stormward_role", "beacon_glow")
		add_child(glow)
		var light := OmniLight3D.new()
		light.name = "StormwardBeaconLight%02d" % (index + 1)
		light.position = at + Vector3.UP
		light.light_color = colour
		light.light_energy = float(spec.get("energy", 2.6))
		light.omni_range = float(spec.get("range_m", 16.0))
		light.shadow_enabled = false
		light.set_meta("stormward_role", "beacon_light")
		add_child(light)


func _scaled_mesh(label: String, mesh: Mesh, at: Vector3, size: Vector3,
		material: Material, role: String) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.name = label
	instance.mesh = mesh
	instance.material_override = material
	var bounds := mesh.get_aabb()
	instance.scale = size / bounds.size
	instance.position = at - bounds.get_center() * instance.scale
	instance.set_meta("stormward_role", role)
	add_child(instance)
	return instance


func _box(label: String, at: Vector3, size: Vector3, material: Material,
		role: String) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.name = label
	var mesh := BoxMesh.new()
	mesh.size = size
	instance.mesh = mesh
	instance.material_override = material
	instance.position = at
	instance.set_meta("stormward_role", role)
	add_child(instance)
	return instance


func _cylinder(label: String, at: Vector3, radius: float, height: float,
		material: Material, role: String) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.name = label
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius * 0.82
	mesh.bottom_radius = radius
	mesh.height = height
	instance.mesh = mesh
	instance.material_override = material
	instance.position = at
	instance.set_meta("stormward_role", role)
	add_child(instance)
	return instance


func _material(materials: Dictionary, key: String) -> Material:
	var value: Variant = materials.get(key)
	if value is Material:
		return value as Material
	var fallback := StandardMaterial3D.new()
	fallback.albedo_color = Color("#817865")
	return fallback


static func _v2(raw: Variant) -> Vector2:
	return Vector2(float(raw[0]), float(raw[1])) if raw is Array and raw.size() >= 2 else Vector2.ZERO


static func _v3(raw: Variant) -> Vector3:
	return Vector3(float(raw[0]), float(raw[1]), float(raw[2])) if raw is Array and raw.size() >= 3 else Vector3.ZERO
