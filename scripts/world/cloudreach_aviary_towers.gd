extends RefCounted

## Original project geometry, drawn from the inspected Sky Aviary board's
## open belfries, slate roofs and limestone courses. No reference pixels or
## third-party mesh data. These extensions stand on the existing drum piers.
const PARTS := preload("res://scripts/world/cloudreach_aviary.gd")


static func build(parent: Node3D, spec: Dictionary, drum: Dictionary,
		stone: Material, trim: Material, roof_material: Material, gold: Material) -> Node3D:
	var root := Node3D.new()
	root.name = "AviaryBelvederes"
	parent.add_child(root)
	if not bool(spec.get("enabled", false)):
		return root
	var base_y := float(drum.get("height_m", 9.0))
	var rx := float(drum.get("radius_x_m", 27.0)) + float(drum.get("pier_extra_radius_m", 0.6))
	var rz := float(drum.get("radius_z_m", 27.0)) + float(drum.get("pier_extra_radius_m", 0.6))
	var shaft_height := float(spec.get("shaft_height_m", 15.0))
	var shaft_width := float(spec.get("shaft_width_m", 2.2))
	var shaft_depth := float(spec.get("shaft_depth_m", 3.0))
	var gallery_width := float(spec.get("gallery_width_m", 4.4))
	var gallery_height := float(spec.get("gallery_height_m", 4.2))
	var post_width := float(spec.get("post_width_m", 0.5))
	var roof_height := float(spec.get("roof_height_m", 4.0))
	for raw: Variant in drum.get("pier_angles_deg", []):
		var angle := deg_to_rad(float(raw))
		var tower := Node3D.new()
		tower.name = "Belvedere%d" % int(raw)
		tower.position = Vector3(cos(angle) * rx, base_y, sin(angle) * rz)
		# Local X is radial, as on the original pier; the shaft stays
		# within that pier's 2.4 m radial x 3.2 m tangential footprint.
		tower.rotation.y = -angle
		root.add_child(tower)
		PARTS._box(tower, "Shaft", Vector3(0, shaft_height * 0.5, 0),
			Vector3(shaft_width, shaft_height, shaft_depth), stone, false)
		for fraction: float in [0.0, 0.45, 1.0]:
			PARTS._box(tower, "StoneCourse", Vector3(0, shaft_height * fraction, 0),
				Vector3(shaft_width + 0.28, 0.32, shaft_depth + 0.28), trim, false)
		var deck_y := shaft_height + 0.3
		PARTS._box(tower, "GalleryFloor", Vector3(0, deck_y, 0),
			Vector3(gallery_width, 0.6, gallery_width), trim, false)
		var opening_base := deck_y + 0.3
		var half := (gallery_width - post_width) * 0.5
		for sx: float in [-1.0, 1.0]:
			for sz: float in [-1.0, 1.0]:
				PARTS._box(tower, "BelfryPier", Vector3(sx * half, opening_base + gallery_height * 0.5, sz * half),
					Vector3(post_width, gallery_height, post_width), stone, false)
		# Four real open arches, with radial wedge stones rather than a dark
		# decal pretending to be a window. No new collision crosses a route.
		var inner_radius := (gallery_width - post_width * 2.0) * 0.5
		var spring_y := opening_base + gallery_height - inner_radius - post_width
		for side in 4:
			var arch := Node3D.new()
			arch.name = "BelfryArch%d" % side
			arch.rotation.y = float(side) * PI * 0.5
			tower.add_child(arch)
			for i in 11:
				var mesh := MeshInstance3D.new()
				mesh.name = "Voussoir%d" % i
				mesh.mesh = _arch_stone(float(i) * PI / 11.0 + 0.012,
					float(i + 1) * PI / 11.0 - 0.012, inner_radius,
					inner_radius + post_width, post_width, spring_y, half)
				mesh.material_override = trim
				arch.add_child(mesh)
		var eaves_y := opening_base + gallery_height
		PARTS._box(tower, "Eaves", Vector3(0, eaves_y, 0),
			Vector3(gallery_width + 0.6, 0.4, gallery_width + 0.6), trim, false)
		var roof := MeshInstance3D.new()
		roof.name = "SlateHipRoof"
		roof.mesh = _roof((gallery_width + 0.9) * 0.5, roof_height)
		roof.position.y = eaves_y + 0.2
		roof.material_override = roof_material
		tower.add_child(roof)
		PARTS._cylinder(tower, "Finial", Vector3(0, eaves_y + roof_height + 0.7, 0),
			0.08, 1.4, gold)
	return root


static func _triangle(tool: SurfaceTool, a: Vector3, b: Vector3, c: Vector3) -> void:
	for p: Vector3 in [a, b, c]:
		tool.set_uv(Vector2(p.x, p.y))
		tool.add_vertex(p)


static func _arch_stone(a: float, b: float, inner: float, outer: float,
		depth: float, y: float, z: float) -> ArrayMesh:
	var points: Array[Vector3] = []
	for plane: float in [-0.5, 0.5]:
		for pair: Vector2 in [Vector2(a, inner), Vector2(b, inner), Vector2(b, outer), Vector2(a, outer)]:
			points.append(Vector3(cos(pair.x) * pair.y, y + sin(pair.x) * pair.y, z + depth * plane))
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	for face: Array in [[0, 3, 2, 1], [4, 5, 6, 7], [0, 1, 5, 4], [1, 2, 6, 5], [2, 3, 7, 6], [3, 0, 4, 7]]:
		_triangle(tool, points[face[0]], points[face[1]], points[face[2]])
		_triangle(tool, points[face[0]], points[face[2]], points[face[3]])
	tool.generate_normals()
	return tool.commit()


static func _roof(half: float, height: float) -> ArrayMesh:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var corners: Array[Vector3] = [Vector3(-half, 0, -half), Vector3(half, 0, -half),
		Vector3(half, 0, half), Vector3(-half, 0, half)]
	for i in 4:
		_triangle(tool, corners[i], corners[(i + 1) % 4], Vector3(0, height, 0))
	_triangle(tool, corners[0], corners[2], corners[1])
	_triangle(tool, corners[0], corners[3], corners[2])
	tool.generate_normals()
	return tool.commit()
