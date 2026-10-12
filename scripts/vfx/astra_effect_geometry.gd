extends RefCounted

## Closed, round cross sections. No camera-facing cards or legacy ribbons.
## Bodies have a fixed topology; trail control points are bounded by the lease.
static func tube(points: Array[Vector3], radius: float, sides: int = 8,
		taper: bool = false) -> ArrayMesh:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var count := points.size()
	if count < 2: return ArrayMesh.new()
	sides = clampi(sides, 6, 12)
	for i in count:
		var tangent := (points[mini(i + 1, count - 1)] - points[maxi(i - 1, 0)]).normalized()
		if tangent.is_zero_approx(): tangent = Vector3.FORWARD
		var axis := Vector3.UP if absf(tangent.dot(Vector3.UP)) < 0.9 else Vector3.RIGHT
		var right := tangent.cross(axis).normalized()
		var up := right.cross(tangent).normalized()
		var f := float(i) / float(count - 1)
		var width := radius * (maxf(0.04, sin(f * PI)) if taper else 1.0)
		for j in sides:
			var angle := TAU * float(j) / float(sides)
			var normal := right * cos(angle) + up * sin(angle)
			surface.set_normal(normal)
			surface.set_uv(Vector2(float(j) / float(sides), f))
			surface.add_vertex(points[i] + normal * width)
	for i in count - 1:
		for j in sides:
			var a := i * sides + j
			var b := i * sides + (j + 1) % sides
			for index: int in [a, a + sides, b, b, a + sides, b + sides]: surface.add_index(index)
	# Seal the ends; these are volumes from every camera direction.
	for j in range(1, sides - 1):
		for index: int in [0, j, j + 1, (count - 1) * sides,
				(count - 1) * sides + j + 1, (count - 1) * sides + j]: surface.add_index(index)
	return surface.commit()

static func sphere(radius: float) -> SphereMesh:
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	mesh.radial_segments = 24
	mesh.rings = 12
	return mesh

static func surface(colour: Color, opacity: float = 1.0) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(colour, opacity)
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA if opacity < 1.0 else BaseMaterial3D.TRANSPARENCY_DISABLED
	material.roughness = 0.28
	material.metallic = 0.12
	material.emission_enabled = true
	material.emission = colour
	material.emission_energy_multiplier = 0.55
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	return material
