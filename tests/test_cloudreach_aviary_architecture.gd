extends "res://tests/test_case.gd"

const AVIARY := preload("res://scripts/world/cloudreach_aviary.gd")
const CONFIG := "res://data/config/cloudreach_aviary.json"


func _config() -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string(CONFIG)) as Dictionary


func test_curved_stone_arches_preserve_the_entire_existing_clear_height() -> void:
	var spec := _config()
	var root := Node3D.new()
	var arches: Array = AVIARY._build_arch_frames(root, spec.arches, StandardMaterial3D.new(), 27.0, 27.0)
	assert_eq(arches.size(), 4)
	for arch: Dictionary in arches:
		var node := arch.node as Node3D
		var mesh_node := node.get_node_or_null("AviaryStoneArch") as MeshInstance3D
		assert_true(mesh_node != null, "each entrance has a real curved stone mesh")
		if mesh_node == null:
			continue
		assert_true(node.get_node_or_null("AviaryLintel") == null, "a flat bar no longer masks the curved opening")
		var arrays: Array = mesh_node.mesh.surface_get_arrays(0)
		var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
		var min_y := INF
		var max_y := -INF
		var wrong_winding := 0
		var degenerate := 0
		for i in range(0, vertices.size(), 3):
			var cross := (vertices[i + 1] - vertices[i]).cross(vertices[i + 2] - vertices[i])
			if cross.length_squared() < 0.000001:
				degenerate += 1
			if cross.dot(normals[i]) >= 0.0:
				wrong_winding += 1
		for vertex: Vector3 in vertices:
			var point := mesh_node.transform * vertex
			min_y = minf(min_y, point.y)
			max_y = maxf(max_y, point.y)
		assert_eq(degenerate, 0, "stone reveals have real area")
		assert_eq(wrong_winding, 0, "front faces agree with outward stone normals")
		assert_true(min_y >= float(arch.clear_height_m) - 0.001,
			"no voussoir intrudes into the existing rectangular route clearance")
		assert_true(max_y > min_y + 3.5, "the curved crown rises visibly above its springline")
		assert_eq(node.find_children("*", "CollisionObject3D", true, false).size(), 0,
			"the arch frame does not introduce a new route collider")
	root.free()


func test_architecture_preserves_ground_boxes_footing_inputs_and_pylon_anchor() -> void:
	var spec := _config()
	spec.interior.enabled = false
	spec.membrane.enabled = false
	var root := Node3D.new()
	var result: Dictionary = AVIARY.build(root, {}, spec)
	var bodies: Array = result.colliders
	assert_eq(bodies.size(), 20, "eight original walls, eight plinths and four piers")
	assert_eq(root.find_children("*", "CollisionObject3D", true, false).size(), 20,
		"visual trim and installed entry lanterns add no physics bodies")
	for body: StaticBody3D in bodies:
		var piece := body.get_parent() as Node3D
		var mesh := piece.get_child(0) as MeshInstance3D
		var shape := (body.get_child(0) as CollisionShape3D).shape as BoxShape3D
		assert_true(mesh != null and mesh.mesh is BoxMesh, "production seating still sees its original first BoxMesh")
		if mesh == null or not mesh.mesh is BoxMesh:
			continue
		assert_eq((mesh.mesh as BoxMesh).size, shape.size, "footing input retains original collision dimensions")
		assert_eq(mesh.position, Vector3.ZERO)
		if str(piece.name).begins_with("AviaryPier"):
			assert_eq(shape.size, Vector3(2.4, 9.0, 3.2))
			assert_almost_eq(piece.position.y, 4.5)
			assert_false(mesh.visible, "the full pier box remains a seating witness, not the visible shaft")
	assert_almost_eq(float(result.oculus_radius_m), 6.0)
	assert_almost_eq(float(result.apex_height_m), 36.0)
	var anchor: Transform3D = result.pylon_anchor
	assert_almost_eq(anchor.origin.y, 35.474893, 0.0001, "existing summit pylon anchor remains fixed")
	assert_almost_eq(anchor.origin.x, 0.0)
	assert_almost_eq(anchor.origin.z, 0.0)
	root.free()


func test_dome_has_primary_ribs_and_entry_lamps_mount_from_jamb_feet() -> void:
	var spec := _config()
	spec.interior.enabled = false
	spec.membrane.enabled = false
	var root := Node3D.new()
	var result: Dictionary = AVIARY.build(root, {}, spec)
	var primary_count := 0
	var primary_radius := 0.0
	var secondary_radius := 0.0
	for rib: Node3D in result.ribs:
		var mesh := (rib.get_child(0) as MeshInstance3D).mesh as CylinderMesh
		if bool(rib.get_meta("primary_rib", false)):
			primary_count += 1
			primary_radius = mesh.bottom_radius
		else:
			secondary_radius = mesh.bottom_radius
	assert_eq(primary_count, 8)
	assert_true(primary_radius >= secondary_radius * 2.0, "major supports read separately from the secondary lattice")
	assert_true((result.dome as Node3D).get_node_or_null("AviarySpringRing") != null)
	assert_eq((result.lanterns as Array).size(), 4)
	for lantern: Node3D in result.lanterns:
		assert_almost_eq(lantern.position.y, float(spec.furniture.lantern_post_height_m), 0.001,
			"entry lamps mount from the actual jamb foot, not its centre")
		assert_true(lantern.get_node_or_null("AviaryEntryLanternHousing") != null)
		var light := lantern.get_node_or_null("AviaryEntryLanternLight") as OmniLight3D
		assert_true(light != null)
		if light != null:
			assert_true(light.light_energy > 0.0 and light.omni_range > 0.0)
			assert_false(light.shadow_enabled, "entry accents do not add outdoor shadow light cost")
	root.free()
