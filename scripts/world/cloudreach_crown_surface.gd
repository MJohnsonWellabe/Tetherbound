extends RefCounted

## CPU query of the exact production crown triangles. Used by placement and
## reconnect before physics is available; no raycast or approximate heightfield.
const CELL_M := 24.0
var bounds := AABB()
var _triangles := PackedVector3Array()
var _cells: Dictionary = {}

func build(local_triangles: PackedVector3Array, transform: Transform3D) -> void:
	_triangles.clear()
	_cells.clear()
	var first := true
	for point: Vector3 in local_triangles:
		var world := transform * point
		_triangles.append(world)
		if first:
			bounds = AABB(world, Vector3.ZERO)
			first = false
		else:
			bounds = bounds.expand(world)
	for i in range(0, _triangles.size() - 2, 3):
		var a := _triangles[i]
		var b := _triangles[i + 1]
		var c := _triangles[i + 2]
		var low := Vector2(minf(a.x, minf(b.x, c.x)), minf(a.z, minf(b.z, c.z)))
		var high := Vector2(maxf(a.x, maxf(b.x, c.x)), maxf(a.z, maxf(b.z, c.z)))
		for x in range(floori(low.x / CELL_M), floori(high.x / CELL_M) + 1):
			for z in range(floori(low.y / CELL_M), floori(high.y / CELL_M) + 1):
				var key := Vector2i(x, z)
				if not _cells.has(key):
					_cells[key] = PackedInt32Array()
				var entries: PackedInt32Array = _cells[key]
				entries.append(i)
				_cells[key] = entries

## X is height and Y the absolute upward normal component. NAN means no face.
func sample(x: float, z: float) -> Vector2:
	for i: int in _cells.get(Vector2i(floori(x / CELL_M), floori(z / CELL_M)), PackedInt32Array()):
		var a := _triangles[i]
		var b := _triangles[i + 1]
		var c := _triangles[i + 2]
		var determinant := (b.z - c.z) * (a.x - c.x) + (c.x - b.x) * (a.z - c.z)
		if absf(determinant) < 0.000001:
			continue
		var u := ((b.z - c.z) * (x - c.x) + (c.x - b.x) * (z - c.z)) / determinant
		var v := ((c.z - a.z) * (x - c.x) + (a.x - c.x) * (z - c.z)) / determinant
		var w := 1.0 - u - v
		if minf(u, minf(v, w)) < -0.00001:
			continue
		return Vector2(u * a.y + v * b.y + w * c.y, absf((b - a).cross(c - a).normalized().y))
	return Vector2(NAN, 0.0)
