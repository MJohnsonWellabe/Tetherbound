extends "res://tests/test_case.gd"

const TREE := preload("res://scripts/world/stormheart_tree.gd")

func test_split_tree_builds_real_bark_and_leaf_surfaces_around_existing_floors() -> void:
	var tree := TREE.new()
	tree.build()
	for id: String in ["EastLivingTrunk", "WestLivingTrunk", "CrownBough0", "ButtressRoot1"]:
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
	assert_true(tree.get_node_or_null("LivingCanopy0") != null, "the split trunk carries installed-family leaves")
	for child in tree.get_children():
		if child is MeshInstance3D and str(child.name).begins_with("ButtressRoot"):
			var bounds: AABB = child.mesh.get_aabb()
			assert_false(bounds.has_point(Vector3(0,6,-44)), "buttress stays out of the southern approach mouth")
			assert_false(bounds.has_point(Vector3(0,150,31)), "buttress stays out of the Water departure")
			assert_true(bounds.end.y > 10 and bounds.position.y < 0,
				"root joins the raised trunk and seats its terminal into the terrain")
	tree.free()
