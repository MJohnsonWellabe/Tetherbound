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
	var piers: Array[MeshInstance3D] = []
	for index in (cfg.get("survey_piers", []) as Array).size():
		var spec := (cfg.survey_piers as Array)[index] as Dictionary
		var piece := _scaled_mesh("StormwardSurveyPier%02d" % (index + 1), CASTLE_TOWER,
			_v3(spec.position), _v3(spec.size), masonry, "survey_pier")
		piece.rotation.z = deg_to_rad(float(spec.get("lean_deg", 0.0)))
		piers.append(piece)
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
	_add_compass_support(cfg, piers, _material(materials, "weathered_timber"), bronze)
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


## The survey instrument hangs from a timber arch seated in the actual
## imported pier walls. Sample their transformed bounds, including lean and
## origin compensation, rather than assuming their authored centres survive.
func _add_compass_support(cfg: Dictionary, piers: Array[MeshInstance3D],
		timber: Material, bronze: Material) -> void:
	if piers.size() < 2:
		return
	var spec: Dictionary = cfg.get("compass_support", {})
	var seats: Array[Vector3] = []
	for pier: MeshInstance3D in [piers[0], piers[1]]:
		var bounds := pier.mesh.get_aabb()
		var local := bounds.position + bounds.size * Vector3(0.5,
			float(spec.get("pier_height_fraction", 0.78)),
			float(spec.get("pier_front_fraction", 0.09)))
		seats.append(pier.transform * local)
	var rise := float(spec.get("arch_rise_m", 4.5))
	var half_width := float(spec.get("beam_half_width_m", 0.34))
	var half_depth := float(spec.get("beam_half_depth_m", 0.34))
	var segments := maxi(8, int(spec.get("arch_segments", 24)))
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	tool.set_material(timber)
	# A chamfered section gives the lintel lit edges and a substantial curved
	# silhouette. End faces close inside masonry; no unsupported trim slab.
	var section := PackedVector2Array([
		Vector2(-0.72, -1.0), Vector2(0.72, -1.0), Vector2(1.0, -0.72),
		Vector2(1.0, 0.72), Vector2(0.72, 1.0), Vector2(-0.72, 1.0),
		Vector2(-1.0, 0.72), Vector2(-1.0, -0.72)])
	var rings: Array[PackedVector3Array] = []
	for i in segments + 1:
		var t := float(i) / float(segments)
		var centre := _arch_point(seats[0], seats[1], rise, t)
		var tangent := (seats[1] - seats[0] + Vector3.UP * rise * PI * cos(PI * t)).normalized()
		var cross_axis := Vector3.FORWARD.cross(tangent).normalized()
		var ring := PackedVector3Array()
		for corner: Vector2 in section:
			ring.append(centre + cross_axis * corner.x * half_width + Vector3.FORWARD * corner.y * half_depth)
		rings.append(ring)
	for i in segments:
		var a_centre := _arch_point(seats[0], seats[1], rise, float(i) / float(segments))
		var b_centre := _arch_point(seats[0], seats[1], rise, float(i + 1) / float(segments))
		for side in section.size():
			var next := (side + 1) % section.size()
			var outward := ((rings[i][side] + rings[i][next]) * 0.5 - a_centre \
				+ (rings[i + 1][side] + rings[i + 1][next]) * 0.5 - b_centre).normalized()
			_arch_triangle(tool, rings[i][side], rings[i + 1][side], rings[i][next], outward)
			_arch_triangle(tool, rings[i][next], rings[i + 1][side], rings[i + 1][next], outward)
	var start_normal := (seats[0] - _arch_point(seats[0], seats[1], rise, 0.001)).normalized()
	var end_normal := (seats[1] - _arch_point(seats[0], seats[1], rise, 0.999)).normalized()
	for side in section.size():
		var next := (side + 1) % section.size()
		_arch_triangle(tool, seats[0], rings[0][side], rings[0][next], start_normal)
		_arch_triangle(tool, seats[1], rings[segments][next], rings[segments][side], end_normal)
	var arch := MeshInstance3D.new()
	arch.name = "StormwardCompassLintel"
	arch.mesh = tool.commit()
	arch.set_meta("stormward_role", "compass_support")
	add_child(arch)
	var at := _v3(cfg.get("compass_signal", {}).get("position", [0.0, 7.1, -0.8]))
	var ring_radius := (1.28 + 1.58) * 0.5
	var hanger_x := 0.75
	for side: float in [-1.0, 1.0]:
		var anchor := at + Vector3(side * hanger_x,
			sqrt(ring_radius * ring_radius - hanger_x * hanger_x), 0.0)
		var t := clampf((anchor.x - seats[0].x) / (seats[1].x - seats[0].x), 0.0, 1.0)
		_rod("StormwardCompassHanger", anchor,
			_arch_point(seats[0], seats[1], rise, t), 0.055, bronze)
	# The vane sits on an axle through the ring, rather than glowing in air.
	_rod("StormwardCompassAxle", at + Vector3(-ring_radius, 0.0, 0.06),
		at + Vector3(ring_radius, 0.0, 0.06), 0.045, bronze)


func _arch_point(a: Vector3, b: Vector3, rise: float, t: float) -> Vector3:
	return a.lerp(b, t) + Vector3.UP * rise * sin(PI * t)


func _arch_triangle(tool: SurfaceTool, a: Vector3, b: Vector3, c: Vector3,
		outward: Vector3) -> void:
	# Godot's front face is clockwise. The radial/cap hint makes winding
	# independent of either pier's lean and gives each chamfer a lit face.
	var normal := (b - a).cross(c - a).normalized()
	if normal.dot(outward) > 0.0:
		var swap := b
		b = c
		c = swap
		normal = -normal
	tool.set_normal(-normal)
	for point: Vector3 in [a, b, c]:
		tool.set_uv(Vector2(point.x, point.y + point.z) * 0.35)
		tool.add_vertex(point)


func _rod(label: String, a: Vector3, b: Vector3, radius: float, material: Material) -> void:
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = a.distance_to(b)
	mesh.radial_segments = 10
	var instance := MeshInstance3D.new()
	instance.name = label
	instance.mesh = mesh
	instance.material_override = material
	instance.position = (a + b) * 0.5
	instance.quaternion = Quaternion(Vector3.UP, (b - a).normalized())
	instance.set_meta("stormward_role", "compass_support")
	add_child(instance)


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
