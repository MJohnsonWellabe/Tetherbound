extends "res://tests/test_case.gd"

const TREE := preload("res://scripts/world/stormheart_tree.gd")

func test_split_tree_builds_real_bark_and_leaf_surfaces_around_existing_floors() -> void:
	var tree := TREE.new()
	tree.build()
	var crown := "BranchCrownWestLow" if tree._presentation_enabled("branching_crown") else "CrownBough0"
	for id: String in ["EastLivingTrunk", "WestLivingTrunk", crown, "ButtressRoot1"]:
		var mesh := tree.get_node_or_null(id) as MeshInstance3D
		assert_true(mesh != null, id + " is built")
		if mesh != null:
			assert_true(mesh.mesh.get_surface_count() > 0, id + " carries a rendered surface")
	for height in [6.0,150.0,174.0]:
		for index in 32:
			var at: Vector3 = tree._trunk_point(float(index)*TAU/32,height,true)
			assert_true(Vector2(at.x,at.z).length() >= 45.99,
				"visual bark remains outside the entire 44 m physical arena")
	for id: String in ["OuterWorks", "DynamoCore", "CrownChamber", "HollowTrunkAscent"]:
		assert_true(tree.get_node_or_null(id) is StaticBody3D, id + " keeps its production floor")
	var canopy := "BranchLeavesWestLow0" if tree._presentation_enabled("branching_crown") else "LivingCanopy0"
	assert_true(tree.get_node_or_null(canopy) != null, "the split trunk carries installed-family leaves")
	for child in tree.get_children():
		if child is MeshInstance3D and str(child.name).begins_with("ButtressRoot"):
			var bounds: AABB = child.mesh.get_aabb()
			assert_false(bounds.has_point(Vector3(0,6,-44)), "buttress stays out of the southern approach mouth")
			assert_false(bounds.has_point(Vector3(0,150,31)), "buttress stays out of the Water departure")
			assert_true(bounds.end.y > 10 and bounds.position.y < 0,
				"root joins the raised trunk and seats its terminal into the terrain")
	tree.free()


func test_charge_uses_exact_round_sections_and_preserves_release_state() -> void:
	var tree := TREE.new()
	tree.simulation_only = true
	tree.build()
	tree._presentation = tree._read_presentation()
	tree._finished_energy_seam()
	var root := tree.get_node("ForkedHeartCharge")
	var batch := root.get_child(0) as MultiMeshInstance3D
	assert_eq(batch.multimesh.instance_count,38,"all32 charge links and six branches remain")
	var mesh := batch.multimesh.mesh as CylinderMesh
	assert_true(mesh != null,"charge uses a round CPU mesh rather than a flat box")
	if mesh == null:
		tree.free()
		return
	assert_almost_eq(mesh.height,1.0)
	assert_almost_eq(mesh.top_radius,0.5)
	assert_almost_eq(mesh.bottom_radius,0.5)
	assert_true(mesh.radial_segments>=12,"round section has actual side normals")
	for index in 32:
		var start := Vector3(sin(index*1.9)*3.0,8.0+index*7.0,5.0)
		var finish := Vector3(sin((index+1)*1.9)*3.0,15.0+index*7.0,5.0)
		var width := float(tree._presentation.core_finish.width_m)
		var pose: Transform3D = tree._charge_pose(start,finish,width)
		assert_true((pose*Vector3(0,-0.5,0)).distance_to(start)<0.00001,"round link begins at authored anchor")
		assert_true((pose*Vector3(0,0.5,0)).distance_to(finish)<0.00001,"round link ends at authored anchor")
		assert_almost_eq(pose.basis.x.length(),width,0.00001)
		assert_almost_eq(pose.basis.z.length(),width,0.00001)
		assert_true(absf(pose.basis.x.dot(pose.basis.y))<0.00001,"tilted section stays orthogonal")
	tree.set_core_released(true)
	assert_eq(tree._core_material.albedo_color,Color(str(tree._presentation.core_finish.cooled_colour)))
	assert_almost_eq(tree._core_material.emission_energy_multiplier,float(tree._presentation.core_finish.cooled_energy))
	for light: OmniLight3D in tree._core_lights:
		assert_false(light.visible,"authoritative release still extinguishes each core light")
	tree.set_core_released(false)
	assert_almost_eq(tree._core_material.emission_energy_multiplier,float(tree._presentation.core_finish.energy))
	assert_eq(root.find_children("*","CollisionObject3D",true,false).size(),0,"charge never adds physical geometry")
	tree.free()


func test_charge_branch_is_clear_of_actual_crown_floor_faces() -> void:
	var tree := TREE.new()
	tree.simulation_only = true
	tree.build()
	var crown := tree.get_node("CrownChamber") as StaticBody3D
	var collider := crown.get_child(0) as CollisionShape3D
	var shape := collider.shape as ConcavePolygonShape3D
	var original_faces: PackedVector3Array = shape.get_faces()
	var start := Vector3(sin(23.0*1.9)*3.0,169.0,5.0)
	var finish := start+Vector3(6,5,2)
	var width := 0.16
	var actual_intersection := false
	for index in range(0,original_faces.size(),3):
		actual_intersection = actual_intersection or Geometry3D.segment_intersects_triangle(start,finish,
			original_faces[index],original_faces[index+1],original_faces[index+2]) != null
	assert_true(actual_intersection,"original branch22 ends on the real Crown floor, outside its well")
	var clipped: Vector3 = tree._charge_branch_tip(start,finish,width)
	assert_true(clipped.distance_to(finish)>0.05,"physical face contact shortens the offending visual branch")
	var pose: Transform3D = tree._charge_pose(start,clipped,width)
	var vertices: PackedVector3Array = tree._charge_mesh().surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	for vertex: Vector3 in vertices:
		assert_true((pose*vertex).y<(TREE.CORE_HEIGHT+24.0),"entire round branch ends below the actual floor plane")
	assert_eq(shape.get_faces(),original_faces,"visual clipping preserves physical floor faces byte-for-byte")
	var safe_start := Vector3(sin(3.0*1.9)*3.0,29.0,5.0)
	var safe_finish := safe_start+Vector3(6,5,2)
	assert_true(tree._charge_branch_tip(safe_start,safe_finish,width).distance_to(safe_finish)<0.00001,
		"nonintersecting branch retains its authored endpoint")
	tree.free()
