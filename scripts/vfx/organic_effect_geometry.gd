extends RefCounted

## Original mesh silhouettes for contact slashes, living/rootstone spires and
## pulsing ribs. Data controls their envelope; none is collision geometry.
static func ribs(size: float, profile: Dictionary) -> ImmediateMesh:
	var mesh := ImmediateMesh.new()
	var segments := clampi(int(profile.get("segments", 32)), 12, 48)
	var sides := 6
	var width := maxf(0.005, float(profile.get("width", 0.08)))
	var style := str(profile.get("rib_style", "heal"))
	var lobes := clampi(int(profile.get("rib_lobes", 7)), 3, 12)
	mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in segments:
		for j in sides:
			var a := _rib_point(float(i) / segments, float(j) / sides, size, width, lobes, style)
			var b := _rib_point(float(i + 1) / segments, float(j) / sides, size, width, lobes, style)
			var c := _rib_point(float(i + 1) / segments, float(j + 1) / sides, size, width, lobes, style)
			var d := _rib_point(float(i) / segments, float(j + 1) / sides, size, width, lobes, style)
			_quad(mesh, a, b, c, d)
	mesh.surface_end()
	return mesh

static func _rib_point(u: float, v: float, size: float, width: float, lobes: int, style: String) -> Vector3:
	var angle := u * TAU
	var rib := sin(angle * lobes)
	var radius := size
	var lift := 0.0
	match style:
		"quake":
			radius += width * rib * 0.8
			lift = absf(rib) * width * 3.0
		"psychic":
			radius *= 1.0 + 0.09 * rib
			lift = cos(angle * 3.0) * width * 2.0
		_:
			radius *= 1.0 + 0.04 * rib
			lift = sin(angle * 2.0) * width * 1.5
	var radial := Vector3(cos(angle), 0, sin(angle))
	return radial * (radius + cos(v * TAU) * width) + Vector3.UP * (lift + sin(v * TAU) * width)

static func slash(size: float, profile: Dictionary) -> ImmediateMesh:
	var mesh := ImmediateMesh.new()
	var segments := clampi(int(profile.get("segments", 28)), 12, 40)
	var arc := deg_to_rad(float(profile.get("arc_degrees", 145.0)))
	var width := size * float(profile.get("slash_width_scale", 0.25))
	mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in segments:
		var u0 := float(i) / segments
		var u1 := float(i + 1) / segments
		var a := _slash_point(u0, -1.0, size, width, arc)
		var b := _slash_point(u1, -1.0, size, width, arc)
		var c := _slash_point(u1, 1.0, size, width, arc)
		var d := _slash_point(u0, 1.0, size, width, arc)
		_quad(mesh, a, b, c, d)
		# A second bowed flank gives the crescent depth at oblique cameras.
		_quad(mesh, a, b, (b + c) * 0.5 + Vector3.UP * width * 0.5, (a + d) * 0.5 + Vector3.UP * width * 0.5)
	mesh.surface_end()
	return mesh

static func _slash_point(u: float, edge: float, size: float, width: float, arc: float) -> Vector3:
	var angle := (u - 0.5) * arc
	var taper := pow(maxf(0.0, sin(u * PI)), 0.7)
	var radius := size + edge * width * taper
	return Vector3(cos(angle) * radius, sin(u * PI) * width * 0.35, sin(angle) * radius)

static func root_spire(size: float, profile: Dictionary) -> ImmediateMesh:
	var mesh := ImmediateMesh.new()
	var height := size * float(profile.get("height_ratio", 3.0))
	var sides := clampi(int(profile.get("segments", 7)), 5, 10)
	mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in sides:
		var a := TAU * float(i) / sides
		var b := TAU * float(i + 1) / sides
		var lower_a := Vector3(cos(a) * size, -height * 0.5, sin(a) * size)
		var lower_b := Vector3(cos(b) * size, -height * 0.5, sin(b) * size)
		var upper_a := Vector3(cos(a) * size * 0.45 + size * 0.1, height * 0.08, sin(a) * size * 0.45)
		var upper_b := Vector3(cos(b) * size * 0.45 + size * 0.1, height * 0.08, sin(b) * size * 0.45)
		_quad(mesh, lower_b, lower_a, upper_a, upper_b)
		_triangle(mesh, upper_b, upper_a, Vector3(-size * 0.2, height * 0.5, size * 0.12))
		# Low alternating root buttresses stay inside the authored envelope.
		if i % 2 == 0:
			_triangle(mesh, lower_a, upper_a, Vector3(cos(a + 0.2) * size * 0.75, -height * 0.45, sin(a + 0.2) * size * 0.75))
	mesh.surface_end()
	return mesh

static func _quad(mesh: ImmediateMesh, a: Vector3, b: Vector3, c: Vector3, d: Vector3) -> void:
	_triangle(mesh, a, b, c)
	_triangle(mesh, a, c, d)

static func _triangle(mesh: ImmediateMesh, a: Vector3, b: Vector3, c: Vector3) -> void:
	var normal := (b - a).cross(c - a).normalized()
	if normal.is_zero_approx(): return
	for point: Vector3 in [a, b, c]:
		mesh.surface_set_normal(normal)
		mesh.surface_set_color(Color.WHITE)
		mesh.surface_add_vertex(point)
