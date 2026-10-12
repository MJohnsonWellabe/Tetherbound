extends RefCounted

## P2-022: open stone bays above the existing drum piers, following the
## inspected Sky Aviary board's masonry-to-dome transition and warm lanterns.
## Original geometry using the existing aviary stone helper and installed
## Quaternius lantern. No reference pixels, new collision, or walkable floor.
const PARTS := preload("res://scripts/world/cloudreach_aviary.gd")
const STONES := preload("res://scripts/world/cloudreach_aviary_towers.gd")


static func build(parent: Node3D, spec: Dictionary, drum: Dictionary,
		stone: Material, trim: Material, node_name: String = "AviaryCrownArcade") -> Node3D:
	if not bool(spec.get("enabled", false)):
		return null
	if parent.has_node(NodePath(node_name)):
		return parent.get_node(NodePath(node_name)) as Node3D
	var root := Node3D.new()
	root.name = node_name
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
	var gallery: Dictionary = spec.get("upper_gallery", {})
	var gallery_enabled := bool(gallery.get("enabled", false))
	var bay_index := 0
	# The rejected gallery candidate owns these visible flame cores too.
	# OFF retains the installed housings and the original production lights.
	var flame: StandardMaterial3D = null
	if gallery_enabled:
		flame = StandardMaterial3D.new()
		flame.albedo_color = Color(str(spec.get("lantern_colour", "#ffbe7b")))
		flame.emission_enabled = true
		flame.emission = flame.albedo_color
		flame.emission_energy_multiplier = float(spec.get("lantern_core_emission", 2.0))
	var core_offset: Array = spec.get("lantern_core_offset", [0.0, 0.27, 0.2])
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
		if not bool(spec.get("lanterns_enabled", true)):
			continue
		if (bay_index - 1) % maxi(1, int(spec.get("lantern_every", 1))) != 0:
			continue
		var lamp_at := Vector3(-(width - post) * 0.5, 0.65, depth * 0.5 + 0.02)
		var lamp_height := float(spec.get("lantern_height_m", 1.4))
		PARTS._install_prop(bay, PARTS.WALL_LANTERN, "CrownLantern",
			lamp_at, lamp_height, 0.0, false)
		if gallery_enabled:
			var core_at := lamp_at + Vector3(float(core_offset[0]),
				float(core_offset[1]), float(core_offset[2])) * lamp_height
			PARTS._cylinder(bay, "CrownLanternFlame", core_at,
				float(spec.get("lantern_core_radius_m", 0.065)),
				float(spec.get("lantern_core_height_m", 0.2)), flame)
		var light := OmniLight3D.new()
		light.name = "CrownLanternLight"
		light.position = Vector3(-(width - post) * 0.5, 1.4, depth * 0.5 + 0.8)
		light.light_color = Color(str(spec.get("lantern_colour", "#ffbe7b")))
		light.light_energy = float(gallery.get("crown_light_energy", 2.0)) if gallery_enabled else float(spec.get("lantern_energy", 2.2))
		light.omni_range = float(gallery.get("crown_light_range_m", 16.0)) if gallery_enabled else float(spec.get("lantern_range_m", 20.0))
		light.shadow_enabled = false
		bay.add_child(light)
	if gallery_enabled:
		# The board's upper arcade rests on a continuous inward gallery ledge.
		# It is visual architecture above the existing route-wing clearance.
		var floor_height := float(gallery.get("floor_height_m", 0.4))
		var floor_top := float(gallery.get("floor_top_m", 15.45))
		var outer_radius := rx + depth * 0.5 + 0.3
		var inner_radius_gallery := float(gallery.get("floor_inner_radius_m", 22.5))
		var floor_radius := (outer_radius + inner_radius_gallery) * 0.5
		_ring(root, "UpperGalleryLedge", floor_radius, floor_radius,
			outer_radius - inner_radius_gallery, floor_top - floor_height * 0.5,
			floor_height, int(cornice.get("segments", 64)), trim)
		var upper_spec := spec.duplicate(true)
		upper_spec.erase("upper_gallery")
		upper_spec.merge(gallery, true)
		upper_spec["enabled"] = true
		upper_spec["base_offset_m"] = floor_top - float(drum.get("height_m", 9.0))
		upper_spec["lanterns_enabled"] = false
		build(parent, upper_spec, drum, stone, trim, "AviaryUpperGallery")
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
