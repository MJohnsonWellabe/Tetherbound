extends RefCounted

## D111 -- OP-0906-05: the Summit Stronghold should read as a domed aviary
## with rustic stone remaining, not a castle keep. This is a STANDALONE
## builder -- nothing in this file is wired into `cloudreach_world.gd` yet.
## `build()` takes a root Node3D and populates it with a low masonry drum
## (real colliders), an open lattice dome over it (no collision -- ribs and
## rings are ornament), aviary furniture, and hands back every node the
## hookup or a test needs by name. `data/config/cloudreach_aviary.json` is
## the only source of numbers; this file has no baked constants beyond a
## couple of internal fallbacks used only when a spec key is missing.
##
## Geometry approach: the drum's wall/plinth rings are built as N straight
## chord segments around an ellipse (rx, rz), each a real collidable box, and
## the four arches are simply chord segments that are SKIPPED across an
## angular gap -- the opening is never "cut out" of a solid ring, it is
## never built there, so a shape-cast through it cannot find a stray sliver
## of collider. The dome is a hemisphere (sphere centred at the drum's top,
## sphere radius `dome.radius_m`) built from meridian ribs (tapered cylinder
## chains) and latitude rings (tori); ribs stop short of the pole at the
## oculus latitude, leaving the top of the dome a genuinely open ring.


static func build(root: Node3D, materials: Dictionary, spec: Dictionary) -> Dictionary:
	var drum_spec: Dictionary = spec.get("drum", {})
	var arch_spec: Dictionary = spec.get("arches", {})
	var dome_spec: Dictionary = spec.get("dome", {})
	var furniture_spec: Dictionary = spec.get("furniture", {})

	var rx := float(drum_spec.get("radius_x_m", 22.0))
	var rz := float(drum_spec.get("radius_z_m", 20.0))
	var drum_height := float(drum_spec.get("height_m", 9.0))

	var gaps := _arch_gaps(arch_spec)

	var masonry := _mat(materials, "masonry", Color("#9a8c78"))
	var stone := _mat(materials, "stone", Color("#8d7862"))
	var timber := _mat(materials, "timber", Color("#8a6a45"))
	var iron := _mat(materials, "iron", Color("#33363b"))
	var rope := _mat(materials, "rope", Color("#8f7048"))
	var lantern_glow := _mat(materials, "lantern", Color("#ffb15c"), false, true)

	var drum_root := Node3D.new()
	drum_root.name = "AviaryDrum"
	root.add_child(drum_root)

	var segment_count := int(drum_spec.get("segment_count", 32))
	var thickness := float(drum_spec.get("wall_thickness_m", 1.6))
	var wall_pieces := _build_ring_course(drum_root, "AviaryWallSegment", rx, rz,
		drum_height * 0.5, thickness, drum_height, stone, true, gaps, segment_count)

	var plinth_height := float(drum_spec.get("plinth_height_m", 0.55))
	var plinth_extra := float(drum_spec.get("plinth_extra_radius_m", 0.35))
	var plinth_pieces := _build_ring_course(drum_root, "AviaryPlinthSegment",
		rx + plinth_extra, rz + plinth_extra, plinth_height * 0.5,
		thickness + plinth_extra * 2.0, plinth_height, masonry, true, gaps, segment_count)

	var piers := _build_piers(drum_root, drum_spec, masonry, rx, rz, drum_height)
	var arches := _build_arch_frames(drum_root, arch_spec, stone, rx, rz)

	var colliders: Array = []
	for piece: Node3D in wall_pieces + plinth_pieces:
		var body := piece.get_node_or_null("Collision")
		if body != null:
			colliders.append(body)
	for pier: Dictionary in piers:
		var body: Node = (pier["node"] as Node3D).get_node_or_null("Collision")
		if body != null:
			colliders.append(body)

	var dome := _build_dome(root, dome_spec, drum_height, timber, iron)
	var veils := _build_veils(root, spec, drum_height, rx, rz, materials)

	var furniture := _build_furniture(root, furniture_spec, dome, timber, rope, iron, lantern_glow,
		arches, rx, rz, thickness)

	var pylon_spec: Dictionary = spec.get("pylon_anchor", {})
	var pylon_height := drum_height + float(dome["sphere_radius"]) * cos(float(dome["apex_alpha"])) \
		+ float(pylon_spec.get("height_above_drum_m", 0.15))
	var pylon_anchor := Transform3D(Basis.IDENTITY, Vector3(0.0, pylon_height, 0.0))

	return {
		"drum": drum_root,
		"dome": dome["root"],
		"ribs": dome["ribs"],
		"latitude_rings": dome["latitude_rings"],
		"oculus_ring": dome["oculus_ring"],
		"arches": arches,
		"piers": piers,
		"veil_panels": veils,
		"perches": furniture["perches"],
		"nests": furniture["nests"],
		"lanterns": furniture["lanterns"],
		"ring_anchors": furniture["ring_anchors"],
		"colliders": colliders,
		"pylon_anchor": pylon_anchor,
		"drum_height_m": drum_height,
		"drum_top_y": drum_height,
		"apex_height_m": drum_height + float(dome["sphere_radius"]),
		"oculus_height_m": float(dome["oculus_height"]),
		"oculus_radius_m": float(dome["oculus_radius"]),
	}


## Numeric self-check: does the arch geometry `build()` will actually
## construct clear both authored throat lines (portal_z bands), with the
## required half-width/clear-height margin? Pure math, no scene tree
## required -- mirrors exactly the angles `_build_ring_course` skips.
static func throat_clear(spec: Dictionary) -> bool:
	var drum_spec: Dictionary = spec.get("drum", {})
	var arch_spec: Dictionary = spec.get("arches", {})
	var throat_spec: Dictionary = spec.get("throat", {})
	var rz := float(drum_spec.get("radius_z_m", 20.0))
	var half_angle := deg_to_rad(float(arch_spec.get("throat_half_angle_deg", 25.0)))
	var opening_half_z := rz * sin(half_angle)
	var required_half_width := float(throat_spec.get("required_half_width_m", 5.0))
	var required_clear_height := float(throat_spec.get("required_clear_height_m", 8.0))
	var throat_clear_height := float(arch_spec.get("throat_clear_height_m", 0.0))
	if throat_clear_height < required_clear_height:
		return false
	var axis: Array = throat_spec.get("axis_z", [-1.5, 7.5])
	for z: Variant in axis:
		if absf(float(z)) >= opening_half_z:
			return false
	return opening_half_z >= required_half_width


## ---- materials --------------------------------------------------------

static func _mat(materials: Dictionary, key: String, fallback_color: Color,
		translucent: bool = false, emissive: bool = false) -> Material:
	var found: Variant = materials.get(key)
	if found is Material:
		return found
	var material := StandardMaterial3D.new()
	material.albedo_color = fallback_color
	material.roughness = 0.85
	if translucent:
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		material.cull_mode = BaseMaterial3D.CULL_DISABLED
		material.albedo_color.a = 0.24
		material.emission_enabled = true
		material.emission = fallback_color
		material.emission_energy_multiplier = 0.5
	elif emissive:
		material.emission_enabled = true
		material.emission = fallback_color
		material.emission_energy_multiplier = 2.0
	return material


## ---- ellipse ring geometry --------------------------------------------

static func _drum_point(theta: float, rx: float, rz: float, y: float) -> Vector3:
	return Vector3(cos(theta) * rx, y, sin(theta) * rz)


static func _drum_normal(theta: float, rx: float, rz: float) -> Vector3:
	var n := Vector3(cos(theta) / maxf(rx, 0.01), 0.0, sin(theta) / maxf(rz, 0.01))
	return n.normalized() if n.length_squared() > 0.0001 else Vector3.RIGHT


static func _segment_basis(a: Vector3, b: Vector3) -> Basis:
	var forward := (b - a).normalized()
	if forward.length_squared() < 0.0001:
		forward = Vector3.FORWARD
	var right := Vector3.UP.cross(forward).normalized()
	if right.length_squared() < 0.001:
		right = Vector3.RIGHT
	var up := forward.cross(right).normalized()
	return Basis(right, up, forward)


static func _angular_diff_deg(a: float, b: float) -> float:
	return fmod(a - b + 540.0, 360.0) - 180.0


## Every arch (throat + side) becomes a {angle, half} gap the wall/plinth
## ring builders skip a chord segment across, plus a small authored margin
## so a chord segment's OWN half-width never clips into the opening.
static func _arch_gaps(arch_spec: Dictionary) -> Array:
	var margin := float(arch_spec.get("arch_gap_margin_deg", 2.0))
	var gaps: Array = []
	for angle: Variant in arch_spec.get("throat_angles_deg", [0.0, 180.0]):
		gaps.append({"angle": float(angle), "half": float(arch_spec.get("throat_half_angle_deg", 25.0)) + margin,
			"kind": "throat"})
	for angle: Variant in arch_spec.get("side_angles_deg", [90.0, 270.0]):
		gaps.append({"angle": float(angle), "half": float(arch_spec.get("side_half_angle_deg", 16.0)) + margin,
			"kind": "side"})
	return gaps


## `half_span_deg` is the checked interval's own half-width (a wall chord
## segment spans an angular RANGE, not a point) -- skip the whole segment if
## ANY part of it falls inside a gap, not merely its midpoint, or a chord
## whose midpoint sits just outside a gap can still physically straddle the
## gap's edge and leave a sliver of collider inside the required opening.
static func _segment_in_gap(mid_deg: float, gaps: Array, half_span_deg: float = 0.0) -> bool:
	for gap: Dictionary in gaps:
		if absf(_angular_diff_deg(mid_deg, float(gap["angle"]))) <= float(gap["half"]) + half_span_deg:
			return true
	return false


static func _box(parent: Node, label: String, centre: Vector3, size: Vector3,
		material: Material, collision: bool, basis: Basis = Basis.IDENTITY) -> Node3D:
	var node := Node3D.new()
	node.name = label
	node.position = centre
	node.basis = basis
	parent.add_child(node)
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mesh.mesh = box
	mesh.material_override = material
	node.add_child(mesh)
	if collision:
		var body := StaticBody3D.new()
		body.name = "Collision"
		var shape_node := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = size
		shape_node.shape = shape
		body.add_child(shape_node)
		node.add_child(body)
	return node


static func _cylinder(parent: Node, label: String, centre: Vector3, radius: float,
		height: float, material: Material) -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	mesh.name = label
	mesh.position = centre
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = radius
	cylinder.bottom_radius = radius
	cylinder.height = height
	mesh.mesh = cylinder
	mesh.material_override = material
	parent.add_child(mesh)
	return mesh


static func _cylinder_between(parent: Node, label: String, a: Vector3, b: Vector3,
		radius: float, material: Material) -> MeshInstance3D:
	var delta := b - a
	if delta.length_squared() < 0.0001:
		delta = Vector3.UP * 0.01
	var node := _cylinder(parent, label, a.lerp(b, 0.5), radius, delta.length(), material)
	var up := delta.normalized()
	var right := up.cross(Vector3.FORWARD).normalized()
	if right.length_squared() < 0.001:
		right = Vector3.RIGHT
	var forward := right.cross(up).normalized()
	node.basis = Basis(right, up, forward)
	return node


static func _build_ring_course(root: Node3D, label: String, rx: float, rz: float,
		y_centre: float, thickness: float, height: float, material: Material,
		collision: bool, gaps: Array, segment_count: int) -> Array:
	var pieces: Array = []
	for i in segment_count:
		var a0 := TAU * float(i) / float(segment_count)
		var a1 := TAU * float(i + 1) / float(segment_count)
		var mid_deg := rad_to_deg((a0 + a1) * 0.5)
		var half_span_deg := rad_to_deg(a1 - a0) * 0.5
		if _segment_in_gap(mid_deg, gaps, half_span_deg):
			continue
		var p0 := _drum_point(a0, rx, rz, y_centre)
		var p1 := _drum_point(a1, rx, rz, y_centre)
		var centre := (p0 + p1) * 0.5
		var chord := p0.distance_to(p1)
		var basis := _segment_basis(p0, p1)
		pieces.append(_box(root, label, centre, Vector3(thickness, height, chord), material, collision, basis))
	return pieces


## ---- piers + crenellation stubs ("still keep some rustic stone") ------

static func _build_piers(root: Node3D, drum_spec: Dictionary, masonry: Material,
		rx: float, rz: float, drum_height: float) -> Array:
	var piers: Array = []
	var extra := float(drum_spec.get("pier_extra_radius_m", 0.6))
	var width := float(drum_spec.get("pier_width_m", 3.2))
	var depth := float(drum_spec.get("pier_depth_m", 2.4))
	var stub_count := int(drum_spec.get("crenellation_count_per_pier", 3))
	var stub_size_raw: Array = drum_spec.get("crenellation_size_m", [0.9, 0.9, 0.9])
	var stub_size := Vector3(float(stub_size_raw[0]), float(stub_size_raw[1]), float(stub_size_raw[2]))
	var stub_gap := float(drum_spec.get("crenellation_gap_m", 1.1))
	for angle_deg: Variant in drum_spec.get("pier_angles_deg", [45.0, 135.0, 225.0, 315.0]):
		var theta := deg_to_rad(float(angle_deg))
		var centreline := _drum_point(theta, rx, rz, drum_height * 0.5)
		var normal := _drum_normal(theta, rx, rz)
		var basis := _segment_basis(_drum_point(theta - 0.02, rx, rz, 0.0), _drum_point(theta + 0.02, rx, rz, 0.0))
		var pier_node := _box(root, "AviaryPier", centreline + normal * extra,
			Vector3(depth, drum_height, width), masonry, true, basis)
		for k in stub_count:
			var offset := (float(k) - float(stub_count - 1) * 0.5) * stub_gap
			_box(pier_node, "AviaryCrenellation",
				Vector3(0.0, drum_height * 0.5 + stub_size.y * 0.5, offset),
				stub_size, masonry, false)
		piers.append({"angle_deg": float(angle_deg), "node": pier_node})
	return piers


## ---- arch frames (visual only -- the opening is already collision-free) -

static func _build_arch_frames(root: Node3D, arch_spec: Dictionary, stone: Material,
		rx: float, rz: float) -> Array:
	var jamb_width := float(arch_spec.get("jamb_width_m", 1.1))
	var lintel_thickness := float(arch_spec.get("lintel_thickness_m", 0.9))
	var margin := deg_to_rad(float(arch_spec.get("arch_gap_margin_deg", 2.0)))
	var arches: Array = []
	var groups := [
		{"kind": "throat", "angles": arch_spec.get("throat_angles_deg", [0.0, 180.0]),
			"half": float(arch_spec.get("throat_half_angle_deg", 25.0)),
			"clear_height": float(arch_spec.get("throat_clear_height_m", 8.5))},
		{"kind": "side", "angles": arch_spec.get("side_angles_deg", [90.0, 270.0]),
			"half": float(arch_spec.get("side_half_angle_deg", 16.0)),
			"clear_height": float(arch_spec.get("side_clear_height_m", 7.0))},
	]
	# The jamb posts sit at the SAME angle the wall/plinth rings stop building
	# at (half_angle + margin, see `_arch_gaps`), not at the raw half_angle --
	# a jamb centred right on the nominal opening edge has its own footprint
	# (jamb_width wide, and wider still once its box is seen edge-on at this
	# angle) straddling that edge, which was clipping the capsule shape-cast
	# at the z=7.5 portal line by a few centimetres. Placing it flush with
	# the real wall-gap boundary keeps the reported opening width the same
	# shape (still comfortably >= PORTAL_HALF_WIDTH) with the jamb's mass
	# entirely outside the swept capsule.
	for group: Dictionary in groups:
		var half_angle := deg_to_rad(float(group["half"])) + margin
		var clear_height: float = group["clear_height"]
		for angle_deg: Variant in group["angles"]:
			var theta := deg_to_rad(float(angle_deg))
			var left := _drum_point(theta - half_angle, rx, rz, 0.0)
			var right := _drum_point(theta + half_angle, rx, rz, 0.0)
			var arch_root := Node3D.new()
			arch_root.name = "AviaryArch"
			root.add_child(arch_root)
			var jamb_basis := _segment_basis(_drum_point(theta - half_angle - 0.02, rx, rz, 0.0),
				_drum_point(theta - half_angle + 0.02, rx, rz, 0.0))
			_box(arch_root, "AviaryJambLeft", left + Vector3.UP * clear_height * 0.5,
				Vector3(jamb_width, clear_height, jamb_width), stone, false, jamb_basis)
			_box(arch_root, "AviaryJambRight", right + Vector3.UP * clear_height * 0.5,
				Vector3(jamb_width, clear_height, jamb_width), stone, false, jamb_basis)
			var lintel_basis := _segment_basis(left, right)
			_box(arch_root, "AviaryLintel", (left + right) * 0.5 + Vector3.UP * clear_height,
				Vector3(jamb_width * 1.4, lintel_thickness, left.distance_to(right) + jamb_width),
				stone, false, lintel_basis)
			arches.append({
				"kind": group["kind"], "angle_deg": float(angle_deg),
				"half_angle_deg": rad_to_deg(half_angle), "clear_height_m": clear_height,
				"half_width_m": left.distance_to(right) * 0.5, "node": arch_root,
			})
	return arches


## ---- dome: meridian ribs + latitude rings + oculus --------------------

static func _dome_point(alpha: float, phi: float, radius: float, centre_y: float) -> Vector3:
	return Vector3(radius * sin(alpha) * cos(phi), centre_y + radius * cos(alpha), radius * sin(alpha) * sin(phi))


static func _build_dome(root: Node3D, dome_spec: Dictionary, drum_height: float,
		timber: Material, iron: Material) -> Dictionary:
	var radius := float(dome_spec.get("radius_m", 23.0))
	var meridians := maxi(int(dome_spec.get("meridian_count", 16)), 3)
	var rib_segments := maxi(int(dome_spec.get("rib_segments", 5)), 1)
	var base_r := float(dome_spec.get("rib_base_radius_m", 0.35))
	var tip_r := float(dome_spec.get("rib_tip_radius_m", 0.2))
	var oculus_radius := float(dome_spec.get("oculus_radius_m", 6.0))
	var ring_tube := float(dome_spec.get("ring_tube_radius_m", 0.16))
	var oculus_tube := float(dome_spec.get("oculus_ring_tube_radius_m", 0.4))
	var ring_count := maxi(int(dome_spec.get("latitude_ring_count", 5)), 0)

	var alpha_rim := PI * 0.5
	var alpha_top := asin(clampf(oculus_radius / maxf(radius, 0.01), -1.0, 1.0))

	var dome_root := Node3D.new()
	dome_root.name = "AviaryDome"
	root.add_child(dome_root)

	var ribs: Array = []
	for m in meridians:
		var phi := TAU * float(m) / float(meridians)
		var rib_root := Node3D.new()
		rib_root.name = "AviaryRib"
		dome_root.add_child(rib_root)
		var prev := _dome_point(alpha_rim, phi, radius, drum_height)
		for s in rib_segments:
			var t := float(s + 1) / float(rib_segments)
			var alpha := lerpf(alpha_rim, alpha_top, t)
			var point := _dome_point(alpha, phi, radius, drum_height)
			var frac := float(s) / float(maxi(rib_segments - 1, 1))
			var rib_radius := lerpf(base_r, tip_r, frac)
			_cylinder_between(rib_root, "AviaryRibSegment", prev, point, rib_radius, timber)
			prev = point
		ribs.append(rib_root)

	var rings: Array = []
	for r in ring_count:
		var t := float(r + 1) / float(ring_count + 1)
		var alpha := lerpf(alpha_rim, alpha_top, t)
		var radius_here := radius * sin(alpha)
		var height_here := drum_height + radius * cos(alpha)
		var torus := TorusMesh.new()
		torus.inner_radius = maxf(radius_here - ring_tube, 0.05)
		torus.outer_radius = radius_here + ring_tube
		var ring_node := MeshInstance3D.new()
		ring_node.name = "AviaryLatitudeRing"
		ring_node.mesh = torus
		ring_node.material_override = iron
		ring_node.position = Vector3(0.0, height_here, 0.0)
		dome_root.add_child(ring_node)
		rings.append(ring_node)

	var oculus_torus := TorusMesh.new()
	oculus_torus.inner_radius = maxf(oculus_radius - oculus_tube, 0.05)
	oculus_torus.outer_radius = oculus_radius + oculus_tube
	var oculus_node := MeshInstance3D.new()
	oculus_node.name = "AviaryOculusRing"
	oculus_node.mesh = oculus_torus
	oculus_node.material_override = iron
	var oculus_height := drum_height + radius * cos(alpha_top)
	oculus_node.position = Vector3(0.0, oculus_height, 0.0)
	dome_root.add_child(oculus_node)

	return {
		"root": dome_root, "ribs": ribs, "latitude_rings": rings, "oculus_ring": oculus_node,
		"apex_alpha": alpha_top, "sphere_radius": radius, "sphere_centre_y": drum_height,
		"oculus_height": oculus_height, "oculus_radius": oculus_radius,
	}


## ---- wind veils near the drum crown ------------------------------------

static func _build_veils(root: Node3D, spec: Dictionary, drum_height: float,
		rx: float, rz: float, materials: Dictionary) -> Array:
	var veil_spec: Dictionary = spec.get("veil_panels", {})
	var count := int(veil_spec.get("count", 6))
	var height := float(veil_spec.get("height_m", 3.6))
	var base_offset := float(veil_spec.get("base_offset_m", 0.3))
	var meridians := maxi(int(spec.get("dome", {}).get("meridian_count", 16)), 3)
	var veil_material := _mat(materials, "veil", Color(0.33, 0.78, 0.84, 0.24), true)
	var panels: Array = []
	for p in count:
		var phi_a := TAU * float(p) / float(count)
		var phi_b := phi_a + TAU / float(meridians)
		var pa := _drum_point(phi_a, rx, rz, drum_height + base_offset)
		var pb := _drum_point(phi_b, rx, rz, drum_height + base_offset)
		var width := pa.distance_to(pb)
		var basis := _segment_basis(pa, pb)
		var panel := MeshInstance3D.new()
		panel.name = "AviaryWindVeil"
		var plane := PlaneMesh.new()
		plane.orientation = PlaneMesh.FACE_Z
		plane.size = Vector2(width, height)
		panel.mesh = plane
		panel.material_override = veil_material
		panel.position = (pa + pb) * 0.5 + Vector3.UP * height * 0.5
		panel.basis = basis
		root.add_child(panel)
		panels.append(panel)
	return panels


## ---- aviary furniture: perches, nests, lanterns, ring anchors ---------

static func _build_furniture(root: Node3D, furniture_spec: Dictionary, dome: Dictionary,
		timber: Material, rope: Material, iron: Material, lantern_glow: Material,
		arches: Array, drum_rx: float, drum_rz: float, wall_thickness: float) -> Dictionary:
	var perch_count := int(furniture_spec.get("perch_count", 10))
	var length_min := float(furniture_spec.get("perch_length_min_m", 4.0))
	var length_max := float(furniture_spec.get("perch_length_max_m", 6.0))
	var height_min := float(furniture_spec.get("perch_height_min_m", 12.0))
	var height_max := float(furniture_spec.get("perch_height_max_m", 20.0))
	var perch_radius := float(furniture_spec.get("perch_radius_m", 0.14))
	var rope_tail := float(furniture_spec.get("perch_rope_tail_m", 1.5))
	var radius := float(dome.get("sphere_radius", 23.0))
	var centre_y := float(dome.get("sphere_centre_y", 9.0))

	var furniture_root := Node3D.new()
	furniture_root.name = "AviaryFurniture"
	root.add_child(furniture_root)

	var perches: Array = []
	for i in perch_count:
		var length_fraction := fmod(float(i) * 0.6180339887, 1.0)
		var height_fraction := fmod(float(i) * 0.3819660113 + 0.15, 1.0)
		var target_length := lerpf(length_min, length_max, length_fraction)
		var height_here := lerpf(height_min, height_max, height_fraction)
		var alpha := acos(clampf((height_here - centre_y) / maxf(radius, 0.01), -1.0, 1.0))
		var radius_here := maxf(radius * sin(alpha), 0.5)
		var angular_span := 2.0 * asin(clampf(target_length / (2.0 * radius_here), 0.0, 1.0))
		var phi_a := TAU * float(i) / float(maxi(perch_count, 1))
		var phi_b := phi_a + angular_span
		var point_a := Vector3(radius_here * cos(phi_a), height_here, radius_here * sin(phi_a))
		var point_b := Vector3(radius_here * cos(phi_b), height_here, radius_here * sin(phi_b))
		var perch_root := Node3D.new()
		perch_root.name = "AviaryPerch"
		furniture_root.add_child(perch_root)
		_cylinder_between(perch_root, "PerchBeam", point_a, point_b, perch_radius, timber)
		var midpoint := (point_a + point_b) * 0.5
		_cylinder_between(perch_root, "PerchRopeTail", midpoint, midpoint + Vector3.DOWN * rope_tail,
			perch_radius * 0.4, rope)
		perches.append({"node": perch_root, "midpoint": midpoint, "height_m": height_here})

	var nests: Array = []
	var nest_radius := float(furniture_spec.get("nest_radius_m", 0.85))
	var nest_cone_height := float(furniture_spec.get("nest_cone_height_m", 0.9))
	for index: Variant in furniture_spec.get("nest_indices", [0, 4, 8]):
		var slot := int(index)
		if slot < 0 or slot >= perches.size():
			continue
		var perch: Dictionary = perches[slot]
		var at: Vector3 = (perch["midpoint"] as Vector3) + Vector3.DOWN * (nest_radius * 0.5)
		var nest_root := Node3D.new()
		nest_root.name = "AviaryNest"
		furniture_root.add_child(nest_root)
		var basket := TorusMesh.new()
		basket.inner_radius = maxf(nest_radius - 0.2, 0.05)
		basket.outer_radius = nest_radius
		var rim := MeshInstance3D.new()
		rim.name = "NestRim"
		rim.mesh = basket
		rim.material_override = rope
		rim.position = at
		nest_root.add_child(rim)
		var cone := CylinderMesh.new()
		cone.top_radius = 0.0
		cone.bottom_radius = nest_radius * 0.9
		cone.height = nest_cone_height
		var body := MeshInstance3D.new()
		body.name = "NestBody"
		body.mesh = cone
		body.material_override = rope
		body.position = at + Vector3.DOWN * (nest_cone_height * 0.5)
		nest_root.add_child(body)
		nests.append(nest_root)

	var lanterns: Array = []
	var lantern_post_height := float(furniture_spec.get("lantern_post_height_m", 3.4))
	var lantern_post_radius := float(furniture_spec.get("lantern_post_radius_m", 0.12))
	var lantern_box_size := float(furniture_spec.get("lantern_box_size_m", 0.32))
	for arch: Dictionary in arches:
		if lanterns.size() >= int(furniture_spec.get("lantern_count", 4)):
			break
		var arch_node: Node3D = arch["node"]
		var flank: Node3D = arch_node.get_node_or_null("AviaryJambRight") as Node3D
		if flank == null:
			continue
		var base := arch_node.position + flank.position
		var lantern_root := Node3D.new()
		lantern_root.name = "AviaryLantern"
		furniture_root.add_child(lantern_root)
		_cylinder(lantern_root, "LanternPost", base + Vector3.UP * lantern_post_height * 0.5,
			lantern_post_radius, lantern_post_height, timber)
		var glow := MeshInstance3D.new()
		glow.name = "LanternGlow"
		var box := BoxMesh.new()
		box.size = Vector3.ONE * lantern_box_size
		glow.mesh = box
		glow.material_override = lantern_glow
		glow.position = base + Vector3.UP * (lantern_post_height + lantern_box_size * 0.5)
		lantern_root.add_child(glow)
		lanterns.append(lantern_root)

	var ring_anchors: Array = []
	var anchor_count := int(furniture_spec.get("ring_anchor_count", 6))
	var anchor_radius := float(furniture_spec.get("ring_anchor_radius_m", 0.28))
	var anchor_height := float(furniture_spec.get("ring_anchor_height_m", 1.4))
	var anchor_gaps := _arch_gaps_from_list(arches)
	var placed := 0
	var attempt := 0
	while placed < anchor_count and attempt < anchor_count * 6:
		var theta := TAU * float(attempt) / float(anchor_count * 3)
		attempt += 1
		if _segment_in_gap(rad_to_deg(theta), anchor_gaps):
			continue
		var wall_point := _drum_point(theta, drum_rx, drum_rz, anchor_height)
		var outward := _drum_normal(theta, drum_rx, drum_rz)
		var anchor_torus := TorusMesh.new()
		anchor_torus.inner_radius = maxf(anchor_radius - 0.06, 0.02)
		anchor_torus.outer_radius = anchor_radius
		var anchor_node := MeshInstance3D.new()
		anchor_node.name = "AviaryRingAnchor"
		anchor_node.mesh = anchor_torus
		anchor_node.material_override = iron
		anchor_node.rotation.x = PI * 0.5
		anchor_node.position = wall_point + outward * (wall_thickness * 0.5 + anchor_radius * 0.5)
		furniture_root.add_child(anchor_node)
		ring_anchors.append(anchor_node)
		placed += 1

	return {"perches": perches.map(func(p: Dictionary) -> Node3D: return p["node"]),
		"nests": nests, "lanterns": lanterns, "ring_anchors": ring_anchors}


static func _arch_gaps_from_list(arches: Array) -> Array:
	var gaps: Array = []
	for arch: Dictionary in arches:
		gaps.append({"angle": float(arch["angle_deg"]), "half": float(arch["half_angle_deg"])})
	return gaps
