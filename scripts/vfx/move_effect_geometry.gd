extends RefCounted

## All bodies are real depth-tested meshes on Compatibility as well as
## Forward+. No screen-space distortion or GPU particles are required.
static func material(colour: Color, opacity: float = 1.0, lit: bool = false) -> StandardMaterial3D:
	var out := StandardMaterial3D.new()
	out.albedo_color = Color(colour.r, colour.g, colour.b, opacity)
	out.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL if lit else BaseMaterial3D.SHADING_MODE_UNSHADED
	out.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA if opacity < 1.0 else BaseMaterial3D.TRANSPARENCY_DISABLED
	out.blend_mode = BaseMaterial3D.BLEND_MODE_MIX
	out.cull_mode = BaseMaterial3D.CULL_DISABLED
	out.roughness = 0.8
	out.no_depth_test = false
	return out

static func shape(kind: String, size: float, profile: Dictionary = {}) -> Mesh:
	match kind:
		"stone", "orb", "bubble":
			var sphere := SphereMesh.new()
			sphere.radius = size
			sphere.height = size * 2.0
			sphere.radial_segments = int(profile.get("segments", 8 if kind == "stone" else 16))
			sphere.rings = int(profile.get("rings", 4 if kind == "stone" else 8))
			return sphere
		"shard", "spike", "cone", "stream":
			var cylinder := CylinderMesh.new()
			cylinder.top_radius = size * float(profile.get("tip_ratio", 0.0 if kind != "stream" else 0.7))
			cylinder.bottom_radius = size
			cylinder.height = size * float(profile.get("height_ratio", 3.0))
			cylinder.radial_segments = int(profile.get("segments", 5 if kind in ["shard", "spike"] else 12))
			return cylinder
		"ring", "crescent", "sigil":
			return band(size, float(profile.get("width", 0.16)), float(profile.get("arc_degrees", 150.0 if kind == "crescent" else 360.0)), int(profile.get("segments", 24)))
		"wave":
			return wave(size, profile)
		"vortex":
			return vortex(size, profile)
		"beam":
			return ribbon([Vector3.ZERO, Vector3.UP * size], float(profile.get("width", 0.09)), Color.WHITE)
	push_error("Unknown effect geometry %s" % kind)
	return null

static func band(radius: float, width: float, arc_degrees: float, segments: int) -> ImmediateMesh:
	var mesh := ImmediateMesh.new()
	mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	var arc := deg_to_rad(arc_degrees)
	for i in segments:
		var a := arc * float(i) / float(segments)
		var b := arc * float(i + 1) / float(segments)
		quad(mesh, Vector3(cos(a), 0.0, sin(a)) * radius,
			Vector3(cos(b), 0.0, sin(b)) * radius,
			Vector3(cos(b), 0.0, sin(b)) * (radius + width),
			Vector3(cos(a), 0.0, sin(a)) * (radius + width), Color.WHITE, Color.WHITE)
	mesh.surface_end()
	return mesh

static func wave(size: float, profile: Dictionary) -> ImmediateMesh:
	var mesh := ImmediateMesh.new()
	mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	var segments := int(profile.get("segments", 16))
	var width := size * float(profile.get("width_ratio", 3.2))
	for i in segments:
		var x0 := lerpf(-width, width, float(i) / float(segments))
		var x1 := lerpf(-width, width, float(i + 1) / float(segments))
		var y0 := size * (0.75 + 0.35 * cos(x0 / maxf(width, 0.01) * PI))
		var y1 := size * (0.75 + 0.35 * cos(x1 / maxf(width, 0.01) * PI))
		quad(mesh, Vector3(x0, 0.0, size * 0.3), Vector3(x1, 0.0, size * 0.3),
			Vector3(x1, y1, -size * 0.25), Vector3(x0, y0, -size * 0.25), Color(0.3, 0.7, 0.95), Color(0.9, 0.98, 1.0))
		quad(mesh, Vector3(x0, y0, -size * 0.25), Vector3(x1, y1, -size * 0.25),
			Vector3(x1, y1 * 0.9, -size * 0.5), Vector3(x0, y0 * 0.9, -size * 0.5), Color.WHITE, Color(0.6, 0.85, 1.0))
	mesh.surface_end()
	return mesh

static func vortex(size: float, profile: Dictionary) -> ImmediateMesh:
	var points: Array[Vector3] = []
	var segments := int(profile.get("segments", 36))
	var turns := float(profile.get("turns", 3.0))
	for i in segments + 1:
		var t := float(i) / float(segments)
		var angle := t * turns * TAU
		var radius := size * lerpf(0.2, 1.0, t)
		points.append(Vector3(cos(angle) * radius, t * size * 3.0, sin(angle) * radius))
	return ribbon(points, size * float(profile.get("ribbon_ratio", 0.13)), Color.WHITE)

static func ribbon(points: Array[Vector3], width: float, colour: Color) -> ImmediateMesh:
	var mesh := ImmediateMesh.new()
	if points.size() < 2 or width <= 0.0: return mesh
	mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in points.size() - 1:
		var tangent := (points[i + 1] - points[i]).normalized()
		var side := tangent.cross(Vector3.UP).normalized()
		if side.length_squared() < 0.001: side = Vector3.RIGHT
		var other := tangent.cross(side).normalized()
		var thickness := width * lerpf(0.25, 1.0, float(i + 1) / float(points.size() - 1))
		var tail := colour.lerp(Color(0.08, 0.1, 0.15), 0.45)
		for axis: Vector3 in [side, other]:
			quad(mesh, points[i] - axis * thickness, points[i] + axis * thickness,
				points[i + 1] + axis * thickness, points[i + 1] - axis * thickness, tail, colour)
	mesh.surface_end()
	return mesh

static func quad(mesh: ImmediateMesh, a: Vector3, b: Vector3, c: Vector3, d: Vector3,
		near_colour: Color, far_colour: Color) -> void:
	# RGB gradient only; opacity belongs to material alpha on Compatibility.
	for pair: Array in [[a, near_colour], [b, near_colour], [c, far_colour], [a, near_colour], [c, far_colour], [d, far_colour]]:
		var colour: Color = pair[1]
		mesh.surface_set_color(Color(colour.r, colour.g, colour.b, 1.0))
		mesh.surface_add_vertex(pair[0])
