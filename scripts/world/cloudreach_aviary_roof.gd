extends RefCounted

## Two roof courses follow the existing dome ribs. Their open clerestory and
## open crown preserve the aviary silhouette while giving it real roof mass.
const CONFIG_PATH := "res://data/config/cloudreach_aviary_roof.json"
const BOUNDS := preload("res://scripts/characters/render_bounds.gd")
const LANTERN := preload("res://assets/props/quaternius_fantasy/Lantern_Wall.gltf")
const SLATE_COLOUR := preload("res://assets/buildings/quaternius_medieval/T_RockTrim_BaseColor.png")
const SLATE_NORMAL := preload("res://assets/buildings/quaternius_medieval/T_RockTrim_Normal.png")

static func build(parent: Node3D, radius: float, drum_height: float,
		iron: Material, lantern_glow: Material) -> void:
	if parent.has_node("AviaryRoofCourses"):
		return
	var config: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(CONFIG_PATH))
	var root := Node3D.new()
	root.name = "AviaryRoofCourses"
	parent.add_child(root)
	var material := StandardMaterial3D.new()
	material.albedo_texture = SLATE_COLOUR
	material.normal_enabled = true
	material.normal_texture = SLATE_NORMAL
	material.normal_scale = 0.35
	material.albedo_color = Color(str(config.slate_tint))
	material.uv1_triplanar = true
	material.uv1_scale = Vector3.ONE * float(config.texture_scale)
	material.roughness = 0.82
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	for row: Dictionary in config.courses:
		var mesh := MeshInstance3D.new()
		mesh.name = str(row.id)
		mesh.mesh = _course_mesh(radius + float(config.surface_offset_m), drum_height,
			deg_to_rad(float(row.from_polar_deg)), deg_to_rad(float(row.to_polar_deg)),
			int(config.angular_segments), int(config.course_rows), float(config.thickness_m))
		mesh.material_override = material
		root.add_child(mesh)
	# Lanterns hang from two existing meridian ribs underneath the upper
	# course. Their finite ranges illuminate roof/stone, not the whole sky.
	var lamps: Dictionary = config.lamps
	var polar := deg_to_rad(float(lamps.roof_polar_deg))
	for raw: Variant in lamps.angles_deg:
		var phi := deg_to_rad(float(raw))
		var anchor := _point(radius, drum_height, polar, phi)
		var height := float(lamps.height_m)
		var lamp_base := anchor - Vector3.UP * (float(lamps.drop_m) + height)
		var lantern := LANTERN.instantiate() as Node3D
		var bounds := BOUNDS.measure(lantern)
		var factor := height / maxf(bounds.size.y, 0.01)
		lantern.scale = Vector3.ONE * factor
		lantern.position = lamp_base - Vector3(bounds.get_center().x, bounds.position.y, bounds.get_center().z) * factor
		root.add_child(lantern)
		var chain := MeshInstance3D.new()
		chain.name = "RoofLanternChain"
		var cylinder := CylinderMesh.new()
		cylinder.top_radius = float(lamps.chain_radius_m)
		cylinder.bottom_radius = float(lamps.chain_radius_m)
		cylinder.height = float(lamps.drop_m)
		cylinder.radial_segments = 8
		chain.mesh = cylinder
		chain.material_override = iron
		chain.position = anchor - Vector3.UP * float(lamps.drop_m) * 0.5
		root.add_child(chain)
		var light := OmniLight3D.new()
		light.name = "UpperSanctuaryLight"
		light.position = lamp_base + Vector3.UP * height * 0.4
		light.light_color = Color(str(lamps.colour))
		light.light_energy = float(lamps.energy)
		light.omni_range = float(lamps.range_m)
		light.shadow_enabled = false
		root.add_child(light)
		var core := MeshInstance3D.new()
		core.name = "RoofLanternFlame"
		var flame := SphereMesh.new()
		flame.radius = height * 0.08
		flame.height = height * 0.22
		flame.radial_segments = 12
		flame.rings = 6
		core.mesh = flame
		core.material_override = lantern_glow
		core.position = light.position
		root.add_child(core)

static func _point(radius: float, height: float, polar: float, phi: float) -> Vector3:
	return Vector3(cos(phi) * sin(polar) * radius,
		height + cos(polar) * radius, sin(phi) * sin(polar) * radius)

static func _course_mesh(radius: float, height: float, start: float, finish: float,
		segments: int, rows: int, thickness: float) -> ArrayMesh:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	for side in 2:
		var r := radius - float(side) * thickness
		for row in rows:
			var a := lerpf(start, finish, float(row) / rows)
			var b := lerpf(start, finish, float(row + 1) / rows)
			for segment in segments:
				var p := TAU * float(segment) / segments
				var q := TAU * float(segment + 1) / segments
				_quad(tool, _point(r, height, a, p), _point(r, height, b, p),
					_point(r, height, b, q), _point(r, height, a, q), side == 1,
					Vector3(0, height, 0), 1.0 if side == 0 else -1.0)
	# Closed eave/fascia edges give the slate a visible thickness from below.
	for edge: float in [start, finish]:
		for segment in segments:
			var p := TAU * float(segment) / segments
			var q := TAU * float(segment + 1) / segments
			_quad(tool, _point(radius, height, edge, p), _point(radius, height, edge, q),
				_point(radius - thickness, height, edge, q), _point(radius - thickness, height, edge, p), edge == start,
				Vector3(0, height, 0), -1.0 if edge == start else 1.0, true)
	tool.index()
	return tool.commit()

static func _quad(tool: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3,
		reverse: bool, centre: Vector3, normal_sign: float, fascia: bool = false) -> void:
	var points: Array[Vector3] = [a, c, b, a, d, c] if reverse else [a, b, c, a, c, d]
	for point: Vector3 in points:
		var normal := (point - centre).normalized()
		if fascia:
			var outward := Vector3(normal.x, 0.0, normal.z).normalized()
			normal = outward * normal.y - Vector3.UP * Vector2(normal.x, normal.z).length()
		tool.set_normal(normal * normal_sign)
		tool.add_vertex(point)
