extends "res://tests/test_case.gd"

const TOWERS := preload("res://scripts/world/cloudreach_aviary_towers.gd")


func _assert_closed_outward(mesh: ArrayMesh) -> void:
	var arrays := mesh.surface_get_arrays(0)
	var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var centre := Vector3.ZERO
	for v in vertices:
		centre += v
	centre /= vertices.size()
	var inward := 0
	var degenerate := 0
	# Each wedge and roof is convex. Godot's clockwise face normal must
	# point away from its interior, not merely agree with generated normals.
	for i in range(0, vertices.size(), 3):
		var a := vertices[i]
		var b := vertices[i + 1]
		var c := vertices[i + 2]
		var outward := (c - a).cross(b - a)
		if outward.length_squared() < 0.000001:
			degenerate += 1
		if outward.dot((a + b + c) / 3.0 - centre) <= 0.0:
			inward += 1
	assert_eq(degenerate, 0, "no degenerate face in the roof or arch stone")
	assert_eq(inward, 0, "every visible face points out of the solid")


func test_roof_and_every_arch_stone_face_outward() -> void:
	_assert_closed_outward(TOWERS._roof(2.65, 4.0))
	for i in 11:
		_assert_closed_outward(TOWERS._arch_stone(float(i) * PI / 11.0 + 0.012,
			float(i + 1) * PI / 11.0 - 0.012, 1.7, 2.2, 0.5, 17.6, 1.95))


func test_extensions_stay_above_ground_portals_without_new_collision() -> void:
	var spec: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/cloudreach_aviary.json"))
	var root := Node3D.new()
	var material := StandardMaterial3D.new()
	# Exercise the retained candidate explicitly; production activation defaults off.
	var towers: Dictionary = spec.towers.duplicate(true)
	towers.enabled = true
	var result := TOWERS.build(root, towers, spec.drum, material, material, material, material)
	assert_eq(result.get_child_count(), 4)
	assert_eq(result.find_children("*", "CollisionObject3D", true, false).size(), 0)
	for tower: Node3D in result.get_children():
		var shaft := tower.get_node("Shaft") as Node3D
		var mesh := shaft.get_child(0) as MeshInstance3D
		var size := (mesh.mesh as BoxMesh).size
		assert_true(size.x <= float(spec.drum.pier_depth_m), "radial shaft fits supporting pier")
		assert_true(size.z <= float(spec.drum.pier_width_m), "tangential shaft fits supporting pier")
		assert_true(tower.position.y + shaft.position.y - size.y * 0.5 >= float(spec.throat.required_clear_height_m))
	root.free()
