extends RefCounted

## Transport the cross-section continuously: changing the UP reference midway
## through a helix twists low-sided tubes into the old kinked ribbon shape.
## A wake tapers only at its trailing end; its head joins the projectile fully.
static func tube(points: Array[Vector3], radius: float, sides: int = 12,
		wake: bool = false) -> ArrayMesh:
	if points.size() < 2: return ArrayMesh.new()
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var right := Vector3.ZERO
	for i in points.size():
		var tangent := (points[mini(i + 1, points.size() - 1)] - points[maxi(i - 1, 0)]).normalized()
		if tangent.is_zero_approx(): tangent = Vector3.FORWARD
		right = (right - tangent * right.dot(tangent)).normalized()
		if right.is_zero_approx():
			right = tangent.cross(Vector3.UP if absf(tangent.y) < 0.9 else Vector3.RIGHT).normalized()
		var up := right.cross(tangent).normalized()
		var f := float(i) / float(points.size() - 1)
		var width := radius * (lerpf(0.04, 1.0, sqrt(f)) if wake else 1.0)
		for j in sides:
			var angle := TAU * float(j) / float(sides)
			var normal := right * cos(angle) + up * sin(angle)
			surface.set_normal(normal)
			surface.set_uv(Vector2(float(j) / float(sides), f))
			surface.add_vertex(points[i] + normal * width)
	for i in points.size() - 1:
		for j in sides:
			var a := i * sides + j
			var b := i * sides + (j + 1) % sides
			# Godot uses clockwise front faces. Keep outward faces visible with
			# the r2 energy material's back-face culling.
			for index: int in [a, b, a + sides, b, b + sides, a + sides]: surface.add_index(index)
	for j in range(1, sides - 1):
		for index: int in [0, j + 1, j, (points.size() - 1) * sides,
				(points.size() - 1) * sides + j, (points.size() - 1) * sides + j + 1]: surface.add_index(index)
	return surface.commit()
