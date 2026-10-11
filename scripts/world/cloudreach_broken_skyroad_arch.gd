extends Node3D

const CONFIG_PATH := "res://data/config/cloudreach_broken_skyroad_arch_visual.json"
const STONE_SHADER := preload("res://shaders/cloudreach_skyroad_stone.gdshader")
var _built := false
var _stone: ShaderMaterial
var _joint := 0.08
var _bevel := 0.10
var _serial := 0
var _mortar: SurfaceTool


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
	_joint = float(cfg.get("joint_m", 0.08))
	_bevel = float(cfg.get("edge_bevel_m", 0.10))
	_stone = ShaderMaterial.new()
	_stone.shader = STONE_SHADER
	_stone.set_shader_parameter("rock_texture", preload("res://assets/environment/terrain/stylised/rock_scree_Color.png"))
	_stone.set_shader_parameter("base_y", global_position.y)
	_mortar = SurfaceTool.new()
	_mortar.begin(Mesh.PRIMITIVE_TRIANGLES)
	_mortar.set_color(Color(0.63, 0.63, 0.63))
	for key: String in cfg.get("stone", {}):
		var value: Variant = cfg.stone[key]
		_stone.set_shader_parameter(key, Color(str(value)) if value is String else value)
	var outer := float(cfg.get("outer_half_width_m", 13.0))
	var opening := float(cfg.get("opening_half_width_m", 7.7))
	var spring := float(cfg.get("spring_height_m", 6.0))
	var rise := float(cfg.get("opening_rise_m", 6.8))
	var ring := float(cfg.get("arch_ring_m", 2.2))
	var depth := float(cfg.get("depth_m", 5.5))
	var course := float(cfg.get("course_height_m", 1.2))
	# Individual pier courses replace the stretched gateway. Above the spring
	# they step clear of the arch extrados, exposing broken masonry shoulders.
	# The spring/rise keep the old opening clear; no collider changes.
	for side: float in [-1.0, 1.0]:
		var height := float(cfg.get("west_height_m" if side < 0.0 else "east_height_m", 16.8))
		for row in ceili(height / course):
			var y0 := float(row) * course
			var y1 := minf(height, y0 + course)
			var inner := opening
			if y0 >= spring - 0.001:
				var t := clampf((y0 - spring) / (rise + ring), 0.0, 1.0)
				inner = maxf(2.8, (opening + ring) * sqrt(maxf(0.0, 1.0 - t * t)))
			var edge := outer - maxf(0.0, y0 - 12.0) * (0.17 if side < 0.0 else 0.30)
			if inner >= edge - 0.35:
				continue
			var count := maxi(1, ceili((edge - inner) / float(cfg.get("stone_length_m", 2.0))))
			for block in count:
				var t0 := float(block) / float(count)
				var t1 := float(block + 1) / float(count)
				if block > 0:
					t0 += (0.11 if row % 2 == 0 else -0.11) / float(count)
				if block < count - 1:
					t1 += (0.11 if row % 2 == 0 else -0.11) / float(count)
				var x0 := side * lerpf(inner, edge, t0)
				var x1 := side * lerpf(inner, edge, t1)
				var face: Array[Vector2] = [Vector2(x0, y0), Vector2(x1, y0),
					Vector2(x1, y1), Vector2(x0, y1)]
				_add_stone("PierCourse", face, depth, "pier_course")
	var segments := int(cfg.get("voussoir_count", 21))
	for index in segments:
		var a := PI * float(index) / float(segments)
		var b := PI * float(index + 1) / float(segments)
		var face: Array[Vector2] = [
			Vector2(cos(a) * opening, spring + sin(a) * rise),
			Vector2(cos(b) * opening, spring + sin(b) * rise),
			Vector2(cos(b) * (opening + ring), spring + sin(b) * (rise + ring)),
			Vector2(cos(a) * (opening + ring), spring + sin(a) * (rise + ring))]
		_add_stone("ArchVoussoir", face, depth + 0.12, "arch_voussoir")
	for raw: Dictionary in cfg.get("rubble", []):
		var size := _v3(raw.get("size_m", [2.6, 1.3, 2.0]))
		# Unequal clipped corners read as broken hewn stones, not box props.
		var face: Array[Vector2] = [Vector2(-0.50, -0.25), Vector2(-0.28, -0.50),
			Vector2(0.33, -0.44), Vector2(0.50, -0.16), Vector2(0.39, 0.37),
			Vector2(0.06, 0.50), Vector2(-0.42, 0.29)]
		for i in face.size():
			face[i] *= Vector2(size.x, size.y)
		var block := _add_stone("FallenVoussoir", face, size.z, "fallen_crown")
		block.position = _v3(raw.get("at", [11.0, 0.0, 4.0]))
		block.rotation_degrees = _v3(raw.get("rotation_deg", [0.0, 15.0, 12.0]))
		_seat_rubble(block)
	var joints := MeshInstance3D.new()
	joints.name = "RecessedStoneJoints"
	joints.mesh = _mortar.commit()
	joints.material_override = _stone
	add_child(joints)
	_build_fracture(cfg)


func _add_stone(label: String, outline: Array[Vector2], depth: float, role: String) -> MeshInstance3D:
	var centre := Vector2.ZERO
	for point: Vector2 in outline:
		centre += point
	centre /= float(outline.size())
	if role != "fallen_crown":
		# Continuous recessed bedding ties the courses together. Only the
		# exposed stone faces are separated; joints are not open sky slots.
		var front: Array[Vector3] = []
		var back: Array[Vector3] = []
		for point: Vector2 in outline:
			front.append(Vector3(point.x, point.y, -depth * 0.5 + _bevel * 1.6))
			back.append(Vector3(point.x, point.y, depth * 0.5 - _bevel * 1.6))
		for i in outline.size():
			var j := (i + 1) % outline.size()
			var edge := (outline[i] + outline[j]) * 0.5 - centre
			_quad(_mortar, front[i], front[j], back[j], back[i], Vector3(edge.x, edge.y, 0.0))
		for i in range(1, outline.size() - 1):
			_triangle(_mortar, front[0], front[i], front[i + 1], Vector3.FORWARD)
			_triangle(_mortar, back[0], back[i], back[i + 1], Vector3.BACK)
	var rings: Array = []
	# Chamfered borders catch light at real joints. Full-depth edges stay
	# inset by the joint so neighboring stones never overlap.
	for band in 4:
		var z := depth * (-0.5 if band < 2 else 0.5)
		if band == 1:
			z += _bevel
		elif band == 2:
			z -= _bevel
		var inset := _joint * 0.5 + (_bevel if band == 0 or band == 3 else 0.0)
		var points: Array[Vector3] = []
		for point: Vector2 in outline:
			var delta := centre - point
			var p := point + delta.normalized() * minf(inset, delta.length() * 0.2)
			points.append(Vector3(p.x, p.y, z))
		rings.append(points)
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var shade := 0.92 + 0.14 * (0.5 + 0.5 * sin(float(_serial) * 7.13))
	tool.set_color(Color(shade, shade, shade))
	for band in 3:
		for i in outline.size():
			var j := (i + 1) % outline.size()
			var edge := (outline[i] + outline[j]) * 0.5 - centre
			var outward := Vector3(edge.x, edge.y, 0.0)
			_quad(tool, rings[band][i], rings[band][j], rings[band + 1][j], rings[band + 1][i], outward)
	for band in [0, 3]:
		var outward := Vector3.FORWARD if band == 0 else Vector3.BACK
		for i in range(1, outline.size() - 1):
			_triangle(tool, rings[band][0], rings[band][i], rings[band][i + 1], outward)
	var block := MeshInstance3D.new()
	block.name = "%s%03d" % [label, _serial]
	_serial += 1
	block.mesh = tool.commit()
	block.material_override = _stone
	block.set_meta("skyroad_arch_role", role)
	add_child(block)
	return block


func _quad(tool: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3, outward: Vector3) -> void:
	_triangle(tool, a, b, c, outward)
	_triangle(tool, a, c, d, outward)


func _triangle(tool: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, outward: Vector3) -> void:
	var cross := (b - a).cross(c - a)
	if cross.length_squared() < 0.00000001:
		return
	# Godot front faces are clockwise; explicit normals point out of the stone.
	if cross.dot(outward) > 0.0:
		var swap := b
		b = c
		c = swap
		cross = -cross
	tool.set_normal(-cross.normalized())
	tool.add_vertex(a)
	tool.add_vertex(b)
	tool.add_vertex(c)


func _seat_rubble(block: MeshInstance3D) -> void:
	var world: Node = self
	while world != null and not world.has_method("ground_height_at"):
		world = world.get_parent()
	if world == null:
		return
	var faces := block.mesh.get_faces()
	var lowest := INF
	for point: Vector3 in faces:
		lowest = minf(lowest, (block.global_transform * point).y)
	var lift := -INF
	for point: Vector3 in faces:
		var at := block.global_transform * point
		if at.y > lowest + 0.30:
			continue
		var ground := float(world.call("ground_height_at", at.x, at.z))
		if not is_finite(ground):
			block.free()
			return
		lift = maxf(lift, ground - at.y)
	if is_finite(lift):
		block.global_position.y += lift - 0.10


func _build_fracture(cfg: Dictionary) -> void:
	var colour := Color(str(cfg.get("fracture_colour", "#70c6ba")))
	var glow := StandardMaterial3D.new()
	glow.albedo_color = colour
	glow.emission_enabled = true
	glow.emission = colour
	glow.emission_energy_multiplier = float(cfg.get("fracture_emission", 0.65))
	# Small mineral seams sit on upper masonry instead of floating in the arch.
	for i in 3:
		var shard := MeshInstance3D.new()
		shard.name = "WindFracture%02d" % i
		var prism := PrismMesh.new()
		prism.size = Vector3(0.10, 0.8 - float(i) * 0.12, 0.06)
		shard.mesh = prism
		shard.material_override = glow
		shard.position = Vector3(10.5 - float(i) * 0.4, 11.4 + float(i) * 0.9, -2.78)
		shard.rotation.z = deg_to_rad(-18.0 + float(i) * 13.0)
		add_child(shard)


static func _v3(raw: Variant) -> Vector3:
	if raw is Array and (raw as Array).size() >= 3:
		return Vector3(float(raw[0]), float(raw[1]), float(raw[2]))
	return Vector3.ZERO
