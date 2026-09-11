extends Node3D

## Visual-only signal portal for Three Bells Bridge. The production rope bridge
## and ledge retain all traversal collision; every child built here is art only.

const CONFIG_PATH := "res://data/config/cloudreach_three_bells_bridge_visual.json"

var _built := false


func build(materials: Dictionary) -> void:
	if _built:
		return
	_built = true
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(CONFIG_PATH))
	if not parsed is Dictionary:
		push_error("Three Bells Bridge visual config is invalid")
		return
	var cfg := parsed as Dictionary
	rotation.y = deg_to_rad(float(cfg.get("route_yaw_deg", 48.4)))
	var stone := _material(materials, "masonry")
	var stone_light := _material(materials, "stone_light")
	var wood := _material(materials, "weathered_timber")
	var bronze := _bell_material(materials)
	var rope := _material(materials, "rope")
	_add_box("SignalApron", Vector3(0.0, 0.08, 0.0), Vector3(24.0, 0.16, 8.0), stone_light, "signal_apron")
	for index in 2:
		var side := -1.0 if index == 0 else 1.0
		var x := float((cfg.get("stone_pier_x_m", [-10.0, 10.0]) as Array)[index])
		_add_box("BellPier%02d" % (index + 1), Vector3(x, 3.25, 0.0), Vector3(3.2, 6.5, 4.4), stone, "bell_pier")
		_add_box("BellPierCap%02d" % (index + 1), Vector3(x, 6.7, 0.0), Vector3(4.0, 0.55, 5.0), stone_light, "bell_pier_cap")
		_add_box("BellUpright%02d" % (index + 1), Vector3(x, 8.3, 0.0), Vector3(0.65, 3.0, 0.8), wood, "bell_frame")
		_add_cylinder_between("BellKneeBrace%02d" % (index + 1), Vector3(x, 8.8, 0.0), Vector3(x - side * 3.2, 10.1, 0.0), 0.22, wood, "bell_frame")
		_add_beacon("BridgeSignal%02d" % (index + 1), Vector3(x, 10.45, 0.0), Color(str(cfg.get("signal_colour", "#76e4dc"))))
		_add_banner("BridgePennant%02d" % (index + 1), Vector3(x + side * 2.15, 7.8, 0.16), side, cfg)
	_add_box("ThreeBellCrownBeam", Vector3(0.0, 10.0, 0.0), Vector3(22.0, 1.15, 1.35), wood, "bell_frame")
	for strap_x: float in [-9.6, -5.4, 0.0, 5.4, 9.6]:
		_add_box("CrownIronStrap", Vector3(strap_x, 10.0, 0.0), Vector3(0.24, 1.3, 1.48), bronze, "frame_binding")
	for light_x: float in [-5.4, 5.4]:
		var bell_light := OmniLight3D.new()
		bell_light.name = "BellWarmLight"
		bell_light.position = Vector3(light_x, 8.2, 0.8)
		bell_light.light_color = Color("#ffc56f")
		bell_light.light_energy = 2.8
		bell_light.omni_range = 14.0
		bell_light.shadow_enabled = false
		bell_light.set_meta("three_bells_role", "bell_light")
		add_child(bell_light)
	var bell_x := cfg.get("bell_x_m", [-5.4, 0.0, 5.4]) as Array
	var scales := cfg.get("bell_scale", [1.02, 1.18, 0.96]) as Array
	for index in 3:
		var x := float(bell_x[index])
		var bell_scale := float(scales[index])
		_add_cylinder_between("BellRope%02d" % (index + 1), Vector3(x, 9.5, 0.0), Vector3(x, 8.55, 0.0), 0.065, rope, "bell_rope")
		_add_box("BellYoke%02d" % (index + 1), Vector3(x, 8.7, 0.0), Vector3(1.8, 0.34, 0.55), wood, "bell_yoke")
		_add_bell("SkyBell%02d" % (index + 1), Vector3(x, 8.45, 0.0), bell_scale, bronze)


func _add_bell(label: String, at: Vector3, scale_value: float, material: Material) -> void:
	var bell_root := Node3D.new()
	bell_root.name = label
	bell_root.position = at
	bell_root.set_meta("three_bells_role", "readable_bell")
	add_child(bell_root)
	var profile: Array[Vector2] = [Vector2(0.24, 0.0), Vector2(0.52, -0.22), Vector2(0.7, -0.82), Vector2(1.05, -1.55), Vector2(1.42, -1.92), Vector2(1.46, -2.12)]
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	tool.set_material(material)
	for row in profile.size() - 1:
		for column in 32:
			var a := TAU * float(column) / 32.0
			var b := TAU * float(column + 1) / 32.0
			var p := Vector3(cos(a) * profile[row].x, profile[row].y, sin(a) * profile[row].x) * scale_value
			var q := Vector3(cos(b) * profile[row].x, profile[row].y, sin(b) * profile[row].x) * scale_value
			var r := Vector3(cos(a) * profile[row + 1].x, profile[row + 1].y, sin(a) * profile[row + 1].x) * scale_value
			var s := Vector3(cos(b) * profile[row + 1].x, profile[row + 1].y, sin(b) * profile[row + 1].x) * scale_value
			_add_triangle(tool, p, q, r)
			_add_triangle(tool, q, s, r)
	tool.generate_normals()
	var shell := MeshInstance3D.new()
	shell.name = "FlaredBronzeShell"
	shell.mesh = tool.commit()
	bell_root.add_child(shell)
	var lip := MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = 1.28 * scale_value
	torus.outer_radius = 1.52 * scale_value
	torus.rings = 32
	torus.ring_segments = 8
	lip.mesh = torus
	lip.material_override = material
	lip.position.y = -2.05 * scale_value
	bell_root.add_child(lip)
	_add_cylinder_to(bell_root, "ClapperStem", Vector3(0.0, -1.35, 0.0) * scale_value, 0.11 * scale_value, 1.75 * scale_value, material, "bell_clapper")
	_add_cylinder_to(bell_root, "ClapperHead", Vector3(0.0, -2.12, 0.0) * scale_value, 0.28 * scale_value, 0.34 * scale_value, material, "bell_clapper")


func _add_banner(label: String, at: Vector3, side: float, cfg: Dictionary) -> void:
	var mesh := ArrayMesh.new()
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = PackedVector3Array([Vector3.ZERO, Vector3(side * 2.2, -0.55, 0.0), Vector3.ZERO + Vector3(0.0, -2.8, 0.0)])
	arrays[Mesh.ARRAY_INDEX] = PackedInt32Array([0, 1, 2])
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	var flag := MeshInstance3D.new()
	flag.name = label
	flag.mesh = mesh
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(str(cfg.get("banner_blue", "#315f9a"))) if side < 0.0 else Color(str(cfg.get("banner_gold", "#d6ad52")))
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.roughness = 0.85
	flag.material_override = material
	flag.position = at
	flag.set_meta("three_bells_role", "route_pennant")
	add_child(flag)


func _add_beacon(label: String, at: Vector3, colour: Color) -> void:
	var material := StandardMaterial3D.new()
	material.albedo_color = colour
	material.emission_enabled = true
	material.emission = colour
	material.emission_energy_multiplier = 2.4
	var orb := MeshInstance3D.new()
	orb.name = label
	var mesh := SphereMesh.new()
	mesh.radius = 0.34
	mesh.height = 0.68
	orb.mesh = mesh
	orb.material_override = material
	orb.position = at
	orb.set_meta("three_bells_role", "bridge_signal")
	add_child(orb)


func _add_box(label: String, at: Vector3, size: Vector3, material: Material, role: String) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.name = label
	var mesh := BoxMesh.new()
	mesh.size = size
	instance.mesh = mesh
	instance.material_override = material
	instance.position = at
	instance.set_meta("three_bells_role", role)
	add_child(instance)
	return instance


func _add_cylinder_between(label: String, a: Vector3, b: Vector3, radius: float, material: Material, role: String) -> MeshInstance3D:
	var instance := _add_cylinder_to(self, label, a.lerp(b, 0.5), radius, a.distance_to(b), material, role)
	instance.quaternion = Quaternion(Vector3.UP, (b - a).normalized())
	return instance


func _add_cylinder_to(parent: Node3D, label: String, at: Vector3, radius: float, height: float, material: Material, role: String) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.name = label
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = 12
	instance.mesh = mesh
	instance.material_override = material
	instance.position = at
	instance.set_meta("three_bells_role", role)
	parent.add_child(instance)
	return instance


func _bell_material(materials: Dictionary) -> StandardMaterial3D:
	var base := _material(materials, "bronze") as StandardMaterial3D
	var result := base.duplicate() as StandardMaterial3D if base != null else StandardMaterial3D.new()
	result.albedo_color = Color("#a8833e")
	result.metallic = 0.7
	result.roughness = 0.38
	result.cull_mode = BaseMaterial3D.CULL_DISABLED
	return result


func _material(materials: Dictionary, key: String) -> Material:
	var value: Variant = materials.get(key)
	if value is Material:
		return value as Material
	var fallback := StandardMaterial3D.new()
	fallback.albedo_color = Color("#766b58")
	fallback.roughness = 0.82
	return fallback


func _add_triangle(tool: SurfaceTool, a: Vector3, b: Vector3, c: Vector3) -> void:
	tool.set_uv(Vector2(0.0, 0.0))
	tool.add_vertex(a)
	tool.set_uv(Vector2(1.0, 0.0))
	tool.add_vertex(b)
	tool.set_uv(Vector2(0.0, 1.0))
	tool.add_vertex(c)
