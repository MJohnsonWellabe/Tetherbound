extends "res://tests/test_case.gd"

const FALLS := preload("res://scripts/world/water_veilfall_falls.gd")

class RidgedFace extends Node3D:
	func ground_height_at(x: float, z: float) -> float:
		# A broad off-centre shoulder: two-edge sampling misses this entirely.
		return 40.0 - x * 0.4 + maxf(0.0, 18.0 - absf(z - 12.0))

func test_broad_cascade_follows_the_face_and_shares_normals() -> void:
	var world := RidgedFace.new()
	var falls := FALLS.new()
	falls._world = world
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var path: Array[Vector3] = [Vector3(0, 40, 0), Vector3(5, 38, 0), Vector3(10, 36, 0)]
	falls._ribbon(surface, path, 96.0, 2.5, 1.0, 0.75)
	var mesh := surface.commit()
	var arrays := mesh.surface_get_arrays(0)
	var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
	var by_position: Dictionary = {}
	var max_span := 0.0
	for index in vertices.size():
		var point := vertices[index]
		assert_true(point.y >= world.ground_height_at(point.x, point.z), "Vertex enters the physical face")
		assert_true(absf(normals[index].length() - 1.0) < 0.001, "Finite unit normal")
		if by_position.has(point):
			assert_true(normals[index].distance_to(by_position[point]) < 0.001, "Joined triangles share lighting")
		by_position[point] = normals[index]
	for index in range(0, vertices.size(), 3):
		var a := vertices[index]
		var b := vertices[index + 1]
		var c := vertices[index + 2]
		var centre := (a + b + c) / 3.0
		assert_true(centre.y >= world.ground_height_at(centre.x, centre.z), "Triangle bridges through the shoulder")
		max_span = maxf(max_span, maxf(absf(a.z - b.z), absf(a.z - c.z)))
	assert_true(max_span <= 6.01, "Wide falls need transverse terrain samples")
	falls.free()
	world.free()
