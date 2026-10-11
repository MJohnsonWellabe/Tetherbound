extends Node3D

const CONFIG_PATH := "res://data/config/cloudreach_broken_skyroad_arch_visual.json"
const STONE := preload("res://assets/buildings/quaternius_medieval/Prop_Brick1.gltf")

var _built := false
var _source: Array = []
var _bounds := AABB()
var _palette: Array[Color] = []
var _stone_material: StandardMaterial3D
var _mortar := 0.04
var _winding_sign := 1.0


func build(_materials: Dictionary) -> void:
	if _built:
		return
	_built = true
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(CONFIG_PATH))
	if not parsed is Dictionary:
		push_error("Broken Skyroad Arch visual config is invalid")
		return
	var cfg := parsed as Dictionary
	rotation.y = deg_to_rad(float(cfg.get("gateway_yaw_deg", -24.0)))
	if not _prepare_stone(cfg):
		return
	_mortar = float(cfg.get("mortar_gap_m", 0.04))
	var requested := _v3(cfg.get("gateway_size_m", [26.0, 19.0, 5.5]))
	var spring := float(cfg.get("spring_height_m", 8.0))
	var inner := float(cfg.get("inner_radius_fraction", 0.6384615385))
	var radius := Vector2(requested.x * 0.5, requested.y - spring)
	var gateway := _tools()
	# Bonded pier courses meet the radial arch at its spring line. Headers
	# alternate with two depth leaves, avoiding uninterrupted vertical joints.
	var pier_width := radius.x * (1.0 - inner)
	var pier_courses := int(cfg.get("pier_courses", 8))
	for side: float in [-1.0, 1.0]:
		_append_courses(gateway, Vector3(side * (radius.x - pier_width * 0.5), spring * 0.5, 0),
			Vector3(pier_width, spring, requested.z), pier_courses)
	# Deform the installed bevelled stone into real annular wedges. The two
	# radial courses retain an intact inner arch and a broken outer shoulder.
	var count := int(cfg.get("voussoirs_per_course", 17))
	var radial_courses := int(cfg.get("radial_courses", 2))
	var missing: Array = cfg.get("broken_outer_voussoirs", [12, 13])
	var step := PI / float(count)
	for band in radial_courses:
		var lo := lerpf(inner, 1.0, float(band) / radial_courses)
		var hi := lerpf(inner, 1.0, float(band + 1) / radial_courses)
		var radial_gap := _mortar / (2.0 * radius.y)
		for index in count:
			if band == radial_courses - 1 and missing.has(index):
				continue
			var angle := -PI * 0.5 + (index + 0.5) * step
			var gap_angle := _mortar / (radius.y * (lo + hi) * 0.5)
			for leaf in 2:
				_append_stone(gateway, Vector3(0, 0, (leaf - 0.5) * requested.z * 0.5),
					Vector3.ONE, (index + band + leaf) % _palette.size(), {
						"angle": angle, "span": step - gap_angle,
						"inner": lo + radial_gap, "outer": hi - radial_gap,
						"radius": radius, "spring": spring,
						"depth": requested.z * 0.5 - _mortar})
	_add_mesh("InstalledSkyroadGateway", gateway, Vector3.ZERO, 0.0, "installed_gateway")
	# The same stone, grain and bevels continue through the smaller bonded
	# buttresses; oversized unrelated cobble panels no longer cover the piers.
	for spec: Dictionary in [
		{"name": "WestButtressLower", "at": Vector3(-13.0, 2.0, 0.4), "size": Vector3(5.0, 4.0, 7.5), "yaw": -7.0},
		{"name": "WestButtressUpper", "at": Vector3(-12.3, 5.3, 0.2), "size": Vector3(3.8, 3.0, 6.2), "yaw": 5.0},
		{"name": "EastBrokenFoot", "at": Vector3(12.5, 1.3, -0.4), "size": Vector3(5.2, 2.6, 7.0), "yaw": 11.0},
	]:
		var buttress := _tools()
		var size: Vector3 = spec.size
		_append_courses(buttress, Vector3.ZERO, size, maxi(2, int(round(size.y))))
		_add_mesh(str(spec.name), buttress, spec.at as Vector3, float(spec.yaw), "grounded_buttress")
	for spec: Dictionary in [
		{"at": Vector3(10.7, 0.8, 5.5), "size": Vector3(7.5, 1.7, 3.2), "yaw": 18.0, "roll": 9.0},
		{"at": Vector3(14.0, 0.65, 1.8), "size": Vector3(4.3, 1.35, 3.4), "yaw": -28.0, "roll": -5.0},
		{"at": Vector3(8.3, 0.5, -5.0), "size": Vector3(3.0, 1.0, 2.8), "yaw": 31.0, "roll": 12.0},
	]:
		var fallen := _tools()
		var size: Vector3 = spec.size
		var pieces := maxi(1, int(ceil(size.x / float(cfg.get("fallen_stone_max_width_m", 2.6)))))
		for piece in pieces:
			_append_stone(fallen, Vector3(((piece + 0.5) / pieces - 0.5) * size.x, 0, 0),
				Vector3(size.x / pieces - _mortar, size.y, size.z), piece % _palette.size())
		var block := _add_mesh("FallenCrownStone", fallen, spec.at as Vector3, float(spec.yaw), "fallen_crown")
		block.rotation.z = deg_to_rad(float(spec.roll))
		var lowest := INF
		var fallen_vertices: PackedVector3Array = block.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
		for vertex: Vector3 in fallen_vertices:
			lowest = minf(lowest, (block.basis * vertex).y)
		block.position.y = -lowest + float(cfg.get("fallen_ground_clearance_m", 0.02))
	var fracture_colour := Color(str(cfg.get("fracture_colour", "#70e0d6")))
	var glow := StandardMaterial3D.new()
	glow.albedo_color = fracture_colour
	glow.emission_enabled = true
	glow.emission = fracture_colour
	glow.emission_energy_multiplier = 2.1
	for index in 3:
		var shard := MeshInstance3D.new()
		shard.name = "WindFracture%02d" % (index + 1)
		var prism := PrismMesh.new()
		prism.size = Vector3(0.35 + index * 0.08, 2.6 - index * 0.35, 0.24)
		shard.mesh = prism
		shard.material_override = glow
		shard.position = Vector3(7.7 + index * 1.25, 13.8 - index * 1.8, 0.3)
		shard.rotation.z = deg_to_rad(-18.0 + index * 13.0)
		shard.set_meta("skyroad_arch_role", "wind_fracture")
		add_child(shard)
	var light := OmniLight3D.new()
	light.name = "SkyroadFractureLight"
	light.light_color = fracture_colour
	light.light_energy = 3.0
	light.omni_range = 17.0
	light.shadow_enabled = false
	light.position = Vector3(8.5, 11.5, 1.0)
	light.set_meta("skyroad_arch_role", "fracture_light")
	add_child(light)


func _prepare_stone(cfg: Dictionary) -> bool:
	var scene := STONE.instantiate()
	var stack: Array[Node] = [scene]
	var source_material: Material
	while not stack.is_empty():
		var node: Node = stack.pop_back()
		if node is MeshInstance3D and (node as MeshInstance3D).mesh != null:
			var visual := node as MeshInstance3D
			_source = visual.mesh.surface_get_arrays(0)
			_bounds = visual.mesh.get_aabb()
			source_material = visual.get_active_material(0)
			break
		for child: Node in node.get_children():
			stack.append(child)
	# Prop_Brick1 is one mesh in an identity-transform node; its authored UVs,
	# bevel geometry and texture family are preserved, not the old cliff atlas.
	scene.free()
	if _source.is_empty() or _bounds.size.x <= 0.0 or _bounds.size.y <= 0.0 or _bounds.size.z <= 0.0:
		push_error("Broken Skyroad Arch installed stone mesh is missing")
		return false
	var vertices: PackedVector3Array = _source[Mesh.ARRAY_VERTEX]
	var normals: PackedVector3Array = _source[Mesh.ARRAY_NORMAL]
	var indices: PackedInt32Array = _source[Mesh.ARRAY_INDEX]
	var first_face := (vertices[indices[1]] - vertices[indices[0]]).cross(vertices[indices[2]] - vertices[indices[0]])
	_winding_sign = signf(first_face.dot(normals[indices[0]] + normals[indices[1]] + normals[indices[2]]))
	_stone_material = source_material.duplicate() as StandardMaterial3D if source_material is StandardMaterial3D else StandardMaterial3D.new()
	_stone_material.albedo_color = Color.WHITE
	_stone_material.vertex_color_use_as_albedo = true
	_stone_material.metallic = 0.0
	_stone_material.roughness = float(cfg.get("stone_roughness", 0.92))
	for tint: String in cfg.get("stone_tints", ["#c3b296", "#b7a88e", "#cdbc9f"]):
		_palette.append(Color(tint))
	return not _palette.is_empty()


func _tools() -> Array[SurfaceTool]:
	var tools: Array[SurfaceTool] = []
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	tool.set_material(_stone_material)
	tools.append(tool)
	return tools


func _append_courses(tools: Array[SurfaceTool], centre: Vector3, size: Vector3, courses: int) -> void:
	var height := size.y / float(courses)
	for row in courses:
		var splits: Array[float] = [0.0, 0.5, 1.0]
		if row % 2 != 0:
			splits.assign([0.0, 0.25, 0.75, 1.0])
		var leaves := 2 if row % 2 == 0 else 1
		for col in splits.size() - 1:
			var width := (splits[col + 1] - splits[col]) * size.x
			for leaf in leaves:
				var at := centre + Vector3((splits[col + 1] + splits[col] - 1.0) * size.x * 0.5,
					(row + 0.5) * height - size.y * 0.5, ((leaf + 0.5) / leaves - 0.5) * size.z)
				_append_stone(tools, at, Vector3(width - _mortar, height - _mortar, size.z / leaves - _mortar),
					(row + col + leaf) % _palette.size())


func _append_stone(tools: Array[SurfaceTool], centre: Vector3, size: Vector3, palette_index: int, wedge: Dictionary = {}) -> void:
	var vertices: PackedVector3Array = _source[Mesh.ARRAY_VERTEX]
	var uvs: PackedVector2Array = _source[Mesh.ARRAY_TEX_UV]
	var indices: PackedInt32Array = _source[Mesh.ARRAY_INDEX]
	var points := PackedVector3Array()
	for index in vertices.size():
		var unit := (vertices[index] - _bounds.get_center()) / _bounds.size
		var point := unit * size
		if not wedge.is_empty():
			var angle: float = float(wedge.angle) + unit.x * float(wedge.span)
			var r := lerpf(float(wedge.inner), float(wedge.outer), unit.y + 0.5)
			var radii: Vector2 = wedge.radius
			point = Vector3(sin(angle) * r * radii.x, float(wedge.spring) + cos(angle) * r * radii.y,
				unit.z * float(wedge.depth))
		points.append(centre + point)
	# Per-stone vertex colours share one material and one surface per part,
	# rather than one draw submission for every block or tint.
	var tool := tools[0]
	tool.set_color(_palette[palette_index])
	for triangle in range(0, indices.size(), 3):
		var a := points[indices[triangle]]
		var b := points[indices[triangle + 1]]
		var c := points[indices[triangle + 2]]
		# The source's smooth normals can face inward after very anisotropic
		# scaling. Face normals from the finished triangles keep every bevel
		# and wedge correctly lit, with the importer's original winding.
		tool.set_normal((b - a).cross(c - a).normalized() * _winding_sign)
		for corner in 3:
			var index := indices[triangle + corner]
			tool.set_uv(uvs[index])
			tool.add_vertex(points[index])


func _add_mesh(label: String, tools: Array[SurfaceTool], at: Vector3, yaw_deg: float, role: String) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.name = label
	var mesh := ArrayMesh.new()
	for tool: SurfaceTool in tools:
		tool.index()
		tool.generate_tangents()
		tool.commit(mesh)
	instance.mesh = mesh
	instance.position = at
	instance.rotation.y = deg_to_rad(yaw_deg)
	instance.set_meta("skyroad_arch_role", role)
	add_child(instance)
	return instance


static func _v3(raw: Variant) -> Vector3:
	if raw is Array and (raw as Array).size() >= 3:
		return Vector3(float((raw as Array)[0]), float((raw as Array)[1]), float((raw as Array)[2]))
	return Vector3.ONE
