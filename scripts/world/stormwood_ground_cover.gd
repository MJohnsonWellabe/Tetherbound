extends "res://scripts/world/grass_field.gd"

## P2-039: realm-local mesh vocabulary for the existing terrain-bound field.
## Keep its placement, clearances, camera following and terrain binding. These
## are decorative moss cushions, curled leaves and small fallen root fragments;
## no scatter, harvest, collision or actor scale changes.
func _cover_mesh(kind: String) -> ArrayMesh:
	match kind:
		"stormwood_moss":
			return _moss_cushions()
		"stormwood_litter":
			return _forest_litter()
	return super._cover_mesh(kind)


func _moss_cushions() -> ArrayMesh:
	var points := PackedVector3Array()
	var shades := PackedVector2Array()
	# Separate lobes with unequal outlines and gaps, never a ground-cover sheet.
	for lobe in 5:
		var angle := float(lobe) * 2.39996
		var centre := Vector3(sin(angle), 0.0, cos(angle)) * (0.08 + float(lobe) * 0.055)
		var radius := 0.13 + float((lobe * 3) % 5) * 0.022
		var crown := centre + Vector3(0.025, 0.075 + float(lobe % 3) * 0.025, -0.018)
		for edge in 6:
			var a := angle + TAU * float(edge) / 6.0
			var b := angle + TAU * float(edge + 1) / 6.0
			var ra := radius * (0.78 + float((edge + lobe) % 3) * 0.13)
			var rb := radius * (0.78 + float((edge + lobe + 1) % 3) * 0.13)
			_append_face(points, shades, centre + Vector3(sin(a) * ra, -0.025, cos(a) * ra),
				crown, centre + Vector3(sin(b) * rb, -0.025, cos(b) * rb),
				Vector2(0.15, 0.8), Vector2(0.85, 0.5), Vector2(0.2, 0.8))
	return _forest_mesh(points, shades)


func _forest_litter() -> ArrayMesh:
	var points := PackedVector3Array()
	var shades := PackedVector2Array()
	# Folded diamond leaves: actual raised centre ridges and pointed ends, not
	# coplanar alpha cards. Their undersides intersect the soil at the stem.
	for leaf in 3:
		var angle := float(leaf) * 2.39996 + 0.3
		var along := Vector3(sin(angle), 0.0, cos(angle))
		var across := Vector3(along.z, 0.0, -along.x)
		var centre := along * (0.13 + float(leaf) * 0.075)
		var stem := centre - along * 0.15 + Vector3.DOWN * 0.012
		var tip := centre + along * (0.20 + float(leaf) * 0.025) + Vector3.UP * 0.027
		var left := centre - across * 0.085 + Vector3.UP * 0.012
		var right := centre + across * 0.11 + Vector3.UP * 0.008
		var ridge := centre + Vector3.UP * (0.055 + float(leaf) * 0.01)
		var ring: Array[Vector3] = [stem, left, tip, right]
		for edge in 4:
			_append_face(points, shades, ring[edge], ridge, ring[(edge + 1) % 4],
				Vector2(0.35, 0.6), Vector2(0.8, 0.6), Vector2(0.5, 0.6))
	# Two intersecting, tapering woody ribs. Endpoints sit below the sampled
	# ground, while the uneven ridge gives small roots/twigs a contact silhouette.
	_append_root(points, shades, Vector3(-0.34, -0.025, -0.20), Vector3(0.34, -0.02, 0.18), 0.052)
	_append_root(points, shades, Vector3(0.04, 0.015, 0.03), Vector3(-0.20, -0.025, 0.29), 0.032)
	return _forest_mesh(points, shades)


func _append_root(points: PackedVector3Array, shades: PackedVector2Array,
		start: Vector3, end: Vector3, width: float) -> void:
	var direction := (end - start).normalized()
	var side := Vector3(direction.z, 0.0, -direction.x).normalized()
	for segment in 3:
		var t0 := float(segment) / 3.0
		var t1 := float(segment + 1) / 3.0
		var a := start.lerp(end, t0) + side * sin(t0 * PI) * 0.05
		var b := start.lerp(end, t1) + side * sin(t1 * PI) * 0.05
		var wa := width * (1.0 - t0 * 0.7)
		var wb := width * (1.0 - t1 * 0.7)
		var ca := a + Vector3.UP * sin(t0 * PI) * 0.095
		var cb := b + Vector3.UP * sin(t1 * PI) * 0.095
		for sign_value: float in [-1.0, 1.0]:
			var ea := a + side * wa * sign_value
			var eb := b + side * wb * sign_value
			_append_face(points, shades, ea, ca, cb, Vector2(0.1, 2.0), Vector2(0.7, 2.0), Vector2(0.7, 2.0))
			_append_face(points, shades, ea, cb, eb, Vector2(0.1, 2.0), Vector2(0.7, 2.0), Vector2(0.1, 2.0))


func _append_face(points: PackedVector3Array, shades: PackedVector2Array,
		a: Vector3, b: Vector3, c: Vector3, sa: Vector2, sb: Vector2, sc: Vector2) -> void:
	# Godot uses clockwise front faces. Keep the visible side facing upward.
	if (c - a).cross(b - a).y < 0.0:
		points.append_array([a, c, b])
		shades.append_array([sa, sc, sb])
	else:
		points.append_array([a, b, c])
		shades.append_array([sa, sb, sc])


func _forest_mesh(points: PackedVector3Array, shades: PackedVector2Array) -> ArrayMesh:
	var normals := PackedVector3Array()
	var uvs := PackedVector2Array()
	var uv2s := PackedVector2Array()
	var indices := PackedInt32Array()
	for face in range(0, points.size(), 3):
		var normal := (points[face + 2] - points[face]).cross(points[face + 1] - points[face]).normalized()
		for corner in 3:
			var index := face + corner
			normals.append(normal)
			uvs.append(Vector2(0.5, shades[index].x))
			uv2s.append(Vector2(0.5, shades[index].y))
			indices.append(index)
	return _mesh_from(points, normals, uvs, indices, uv2s)
