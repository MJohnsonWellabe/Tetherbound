extends "res://tests/test_case.gd"

## PERF (F26#5): scripts/world/detail_cull.gd gives small unranged geometry a
## screen-size visibility range. Godot tests a node's range against the centre
## of its whole box, so a wide MultiMesh batch must never be ranged by one
## instance's size (review BLOCK, 4182f3ac: perimeter hedges vanished whole).

const DETAIL_CULL := preload("res://scripts/world/detail_cull.gd")
const CFG := {"enabled": true, "pixels": 2.5, "reference_lines": 1080.0, "reference_fov_deg": 70.0,
	"min_range_m": 150.0, "fade_fraction": 0.1, "ignore_beyond_m": 9000.0, "skip_emissive": true,
	"emissive_skip_max_size_m": 1.5, "skip_subtrees": ["Stronghold"]}


func _box_mesh(size: Vector3, material: Material = null) -> BoxMesh:
	var mesh := BoxMesh.new()
	mesh.size = size
	if material != null:
		mesh.material = material
	return mesh


func _multimesh(instance_mesh: Mesh, positions: Array[Vector3]) -> MultiMeshInstance3D:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = instance_mesh
	mm.instance_count = positions.size()
	for index in positions.size():
		mm.set_instance_transform(index, Transform3D(Basis.IDENTITY, positions[index]))
	var node := MultiMeshInstance3D.new()
	node.multimesh = mm
	return node


func test_a_wide_multimesh_is_never_ranged_by_one_instance() -> void:
	# A 2 m hedge repeated along an 8 km edge: one instance would earn ~600 m.
	var positions: Array[Vector3] = []
	for index in 41:
		positions.append(Vector3(0.0, 0.0, float(index) * 200.0))
	var hedge := _multimesh(_box_mesh(Vector3(2.0, 2.0, 2.0)), positions)
	var root := Node3D.new()
	root.add_child(hedge)
	DETAIL_CULL.apply(hedge, CFG)
	assert_eq(hedge.visibility_range_end, 0.0, "an 8 km batch keeps drawing near the camera")
	root.free()


func test_a_multimesh_empty_when_measured_is_never_ranged() -> void:
	# Review B1 (cc22c6c5): pickup_glow.gd builds its Motes and Auras empty and
	# fills them later with every glowing pickup in the realm. Ranged by one
	# 2 m quad (~617 m), a key far from the centre of all pickups lost its glow.
	var empty := _multimesh(_box_mesh(Vector3(2.0, 2.0, 2.0)), [])
	var root := Node3D.new()
	root.add_child(empty)
	DETAIL_CULL.apply(empty, CFG)
	assert_eq(empty.visibility_range_end, 0.0, "a batch filled later has no known spread")
	root.free()


func test_a_single_instance_multimesh_is_never_ranged() -> void:
	# One instance at build time can grow later the same way.
	var positions: Array[Vector3] = [Vector3(3.0, 0.0, 3.0)]
	var single := _multimesh(_box_mesh(Vector3(1.0, 1.0, 1.0)), positions)
	var root := Node3D.new()
	root.add_child(single)
	DETAIL_CULL.apply(single, CFG)
	assert_eq(single.visibility_range_end, 0.0, "a lone instance may be a batch that grows")
	root.free()


func _at(points: Array[Vector3], basis: Basis = Basis.IDENTITY) -> Array[Transform3D]:
	var out: Array[Transform3D] = []
	for point: Vector3 in points:
		out.append(Transform3D(basis, point))
	return out


func test_spread_is_the_half_diagonal_of_every_instance_and_its_mesh() -> void:
	# The headless renderer keeps no instance buffer, so the maths is tested on
	# the transforms directly. A 600 m square patch of 2 m props: the box is
	# 602 x 2 x 602, half-diagonal ~425.7 m. Its nearest instance would vanish
	# ~190 m out if the range were not pushed out by this much.
	var box := AABB(Vector3(-1.0, -1.0, -1.0), Vector3(2.0, 2.0, 2.0))
	var patch := _at([Vector3.ZERO, Vector3(600.0, 0.0, 0.0), Vector3(0.0, 0.0, 600.0), Vector3(600.0, 0.0, 600.0)])
	var plain: Dictionary = DETAIL_CULL.measure_instances(patch, box, Vector3.ONE)
	assert_between(float(plain.half_diagonal), 425.0, 426.5, "half-diagonal of a 600 m patch")
	assert_between(float(plain.size), 1.99, 2.01, "one 2 m prop")
	var doubled: Dictionary = DETAIL_CULL.measure_instances(patch, box, Vector3(2.0, 2.0, 2.0))
	assert_between(float(doubled.half_diagonal), 850.0, 853.0, "node scale scales the spread")


func test_each_instance_is_sized_by_its_own_transform() -> void:
	# Codex review of 33e131af: a batch of 2 m meshes placed at 4x scale is an
	# 8 m object; sized by the mesh alone it would range at a quarter distance.
	var box := AABB(Vector3(-1.0, -1.0, -1.0), Vector3(2.0, 2.0, 2.0))
	var big := _at([Vector3.ZERO, Vector3(50.0, 0.0, 0.0)], Basis.IDENTITY.scaled(Vector3(4.0, 4.0, 4.0)))
	assert_between(float(DETAIL_CULL.measure_instances(big, box, Vector3.ONE).size), 7.99, 8.01)
	var tall := _at([Vector3.ZERO, Vector3(50.0, 0.0, 0.0)], Basis(Vector3.RIGHT, PI * 0.5).scaled(Vector3(1.0, 1.0, 6.0)))
	assert_true(float(DETAIL_CULL.measure_instances(tall, box, Vector3.ONE).size) >= 11.9,
		"a stretched, rotated instance keeps its long axis")


func test_spread_is_unknown_for_empty_single_or_unreadable_batches() -> void:
	var box := AABB(Vector3(-1.0, -1.0, -1.0), Vector3(2.0, 2.0, 2.0))
	var none: Array[Transform3D] = []
	assert_eq(float(DETAIL_CULL.measure_instances(none, box, Vector3.ONE).half_diagonal), INF)
	assert_eq(float(DETAIL_CULL.measure_instances(_at([Vector3(5.0, 0.0, 5.0)]), box, Vector3.ONE).half_diagonal), INF)
	# Several instances reading one origin: a dummy renderer's empty buffer.
	assert_eq(float(DETAIL_CULL.measure_instances(_at([Vector3.ZERO, Vector3.ZERO, Vector3.ZERO]), box, Vector3.ONE).half_diagonal), INF)


func test_a_small_mesh_is_ranged_and_a_large_one_is_not() -> void:
	var root := Node3D.new()
	var prop := MeshInstance3D.new()
	prop.mesh = _box_mesh(Vector3(2.0, 2.0, 2.0))
	root.add_child(prop)
	var cliff := MeshInstance3D.new()
	cliff.mesh = _box_mesh(Vector3(60.0, 80.0, 60.0))
	root.add_child(cliff)
	DETAIL_CULL.apply(prop, CFG)
	DETAIL_CULL.apply(cliff, CFG)
	# 2 m at 2.5 px on 1080 lines at 70 deg: about 617 m.
	assert_between(prop.visibility_range_end, 550.0, 700.0, "a 2 m prop culls past ~600 m")
	assert_eq(cliff.visibility_range_end, 0.0, "a landmark-scale silhouette keeps its reach")
	root.free()


func test_the_stronghold_spine_and_small_lamps_are_left_alone() -> void:
	var root := Node3D.new()
	var stronghold := Node3D.new()
	stronghold.name = "Stronghold"
	root.add_child(stronghold)
	var merlon := MeshInstance3D.new()
	merlon.mesh = _box_mesh(Vector3(1.0, 1.0, 1.0))
	stronghold.add_child(merlon)
	var glow := StandardMaterial3D.new()
	glow.emission_enabled = true
	var lamp := MeshInstance3D.new()
	lamp.mesh = _box_mesh(Vector3(0.4, 0.4, 0.4), glow)
	root.add_child(lamp)
	DETAIL_CULL.apply(merlon, CFG)
	DETAIL_CULL.apply(lamp, CFG)
	assert_eq(merlon.visibility_range_end, 0.0, "the landmark spine never pops")
	assert_eq(lamp.visibility_range_end, 0.0, "a lit lamp reads as a point of light at any distance")
	root.free()


func test_an_authored_range_is_respected() -> void:
	var root := Node3D.new()
	var authored := MeshInstance3D.new()
	authored.mesh = _box_mesh(Vector3(1.0, 1.0, 1.0))
	authored.visibility_range_end = 42.0
	root.add_child(authored)
	DETAIL_CULL.apply(authored, CFG)
	assert_eq(authored.visibility_range_end, 42.0)
	root.free()
