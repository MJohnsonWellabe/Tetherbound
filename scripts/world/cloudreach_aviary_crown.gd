extends RefCounted

## P2-022: open stone bays above the existing drum piers, following the
## inspected Sky Aviary board's masonry-to-dome transition and warm lanterns.
## Original geometry using the existing aviary stone helper and installed
## Quaternius lantern. No reference pixels, new collision, or walkable floor.
const PARTS := preload("res://scripts/world/cloudreach_aviary.gd")
const STONES := preload("res://scripts/world/cloudreach_aviary_towers.gd")


static func build(parent: Node3D, spec: Dictionary, drum: Dictionary,
		stone: Material, trim: Material) -> Node3D:
	if not bool(spec.get("enabled", false)):
		return null
	if parent.has_node("AviaryCrownArcade"):
		return parent.get_node("AviaryCrownArcade") as Node3D
	var root := Node3D.new()
	root.name = "AviaryCrownArcade"
	parent.add_child(root)
	var width := float(spec.get("width_m", 8.2))
	var post := float(spec.get("post_width_m", 0.9))
	var depth := float(spec.get("depth_m", 1.3))
	var clear_height := float(spec.get("clear_height_m", 5.4))
	var inner_radius := (width - post * 2.0) * 0.5
	var spring_y := clear_height - inner_radius
	var base_y := float(drum.get("height_m", 9.0)) + float(spec.get("base_offset_m", 0.2))
	var inset := float(spec.get("radial_inset_m", 0.0))
	var rx := float(drum.get("radius_x_m", 27.0)) - inset
	var rz := float(drum.get("radius_z_m", 27.0)) - inset
	var cornice: Dictionary = spec.get("cornice", {})
	if bool(cornice.get("enabled", true)):
		# A real continuous entablature gives the open bays architectural mass
		# and joins their extrados to the dome's lower panels. It rests on the
		# voussoirs, above the original route clear height, without a collider.
		var seat_y := base_y + clear_height + post
		var lower_height := float(cornice.get("lower_height_m", 0.35))
		var upper_height := float(cornice.get("upper_height_m", 0.3))
		var projection := float(cornice.get("projection_m", 0.3))
		var segments := int(cornice.get("segments", 64))
		_ring(root, "CrownEntablature", rx, rz, depth + projection * 2.0,
			seat_y + lower_height * 0.5, lower_height, segments, stone)
		_ring(root, "CrownWeatheringCourse", rx, rz, depth + projection,
			seat_y + lower_height + upper_height * 0.5, upper_height, segments, trim)
	var angles: Array = drum.get("pier_angles_deg", []).duplicate()
	var bay_count := int(spec.get("bay_count", 0))
	if bay_count > 0:
		angles.clear()
		for index in bay_count:
			angles.append(float(index) * 360.0 / float(bay_count))
	var bay_index := 0
	for raw: Variant in angles:
		var angle := deg_to_rad(float(raw))
		var bay := Node3D.new()
		bay.name = "CrownBay%d" % int(raw)
		bay.position = Vector3(cos(angle) * rx, base_y, sin(angle) * rz)
		# X follows the drum tangent; positive Z faces out from the dome.
		bay.rotation.y = PI * 0.5 - angle
		root.add_child(bay)
		PARTS._box(bay, "CrownSill", Vector3.ZERO,
			Vector3(width + 0.4, 0.4, depth + 0.3), trim, false)
		for side: float in [-1.0, 1.0]:
			PARTS._box(bay, "ArcadePier", Vector3(side * (width - post) * 0.5, spring_y * 0.5, 0),
				Vector3(post, spring_y, depth), stone, false)
			PARTS._box(bay, "ArcadeCapital", Vector3(side * (width - post) * 0.5, spring_y, 0),
				Vector3(post + 0.22, 0.24, depth + 0.18), trim, false)
		for segment in 13:
			var arch := MeshInstance3D.new()
			arch.name = "CrownVoussoir%d" % segment
			arch.mesh = STONES._arch_stone(float(segment) * PI / 13.0 + 0.008,
				float(segment + 1) * PI / 13.0 - 0.008,
				inner_radius, inner_radius + post, depth, spring_y, 0.0)
			arch.material_override = stone
			bay.add_child(arch)
		# The whole crown has a masonry rhythm. Practical lights are bounded,
		# rather than one overlapping OmniLight in every decorative bay.
		bay_index += 1
		if (bay_index - 1) % maxi(1, int(spec.get("lantern_every", 1))) != 0:
			continue
		PARTS._install_prop(bay, PARTS.WALL_LANTERN, "CrownLantern",
			Vector3(-(width - post) * 0.5, 0.65, depth * 0.5 + 0.02),
			float(spec.get("lantern_height_m", 1.4)), 0.0, false)
		var light := OmniLight3D.new()
		light.name = "CrownLanternLight"
		light.position = Vector3(-(width - post) * 0.5, 1.4, depth * 0.5 + 0.8)
		light.light_color = Color(str(spec.get("lantern_colour", "#ffbe7b")))
		light.light_energy = float(spec.get("lantern_energy", 2.2))
		light.omni_range = float(spec.get("lantern_range_m", 20.0))
		light.shadow_enabled = false
		bay.add_child(light)
	return root


static func _ring(root: Node3D, label: String, rx: float, rz: float, depth: float,
		y: float, height: float, segments: int, material: Material) -> void:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	for index in segments:
		var a := TAU * float(index) / segments
		var b := TAU * float(index + 1) / segments
		var points: Array[Vector3] = []
		for level: float in [-0.5, 0.5]:
			for pair: Vector2 in [Vector2(a, -0.5), Vector2(b, -0.5), Vector2(b, 0.5), Vector2(a, 0.5)]:
				points.append(Vector3(cos(pair.x) * (rx + depth * pair.y),
					y + height * level, sin(pair.x) * (rz + depth * pair.y)))
		# Moving the arch helper's XY ring to XZ reverses its handedness;
		# reverse each triangle to retain Godot's outward clockwise faces.
		for face: Array in [[0, 3, 2, 1], [4, 5, 6, 7], [0, 1, 5, 4], [1, 2, 6, 5], [2, 3, 7, 6], [3, 0, 4, 7]]:
			STONES._triangle(tool, points[face[0]], points[face[2]], points[face[1]])
			STONES._triangle(tool, points[face[0]], points[face[3]], points[face[2]])
	tool.generate_normals()
	var ring := MeshInstance3D.new()
	ring.name = label
	ring.mesh = tool.commit()
	ring.material_override = material
	root.add_child(ring)
