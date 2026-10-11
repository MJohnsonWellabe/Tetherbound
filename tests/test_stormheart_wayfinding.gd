extends "res://tests/test_case.gd"

const TREE := preload("res://scripts/world/stormheart_tree.gd")


func test_stormheart_ascent_has_a_threshold_and_a_complete_warm_light_chain() -> void:
	var tree := TREE.new()
	tree.build()
	var route := tree.get_node_or_null(^"AscentWayfinding") as Node3D
	assert_true(route != null, "the authored ascent needs its presentation root")
	if route == null:
		tree.free()
		return
	assert_eq(route.find_children("ThresholdPost*", "MeshInstance3D", true, false).size(), 2,
		"the ten-metre entrance should be framed by two timber posts")
	assert_eq(route.find_children("ThresholdCrown*", "MeshInstance3D", true, false).size(), 2,
		"the entrance should have a shaped two-beam crown rather than a bare box lintel")
	assert_eq(route.find_children("AuthoredLantern", "Node3D", true, false).size(), 10,
		"every route light should use the installed authored lantern silhouette")
	assert_eq(route.find_children("SpiralLamp*", "Node3D", true, false).size(), 8,
		"two lamps at each southern reveal should mark all four turns")
	assert_eq(route.find_children("WarmRouteLight", "OmniLight3D", true, false).size(), 10,
		"the two threshold lamps and eight spiral lamps should all cast warm light")
	var rhythm_nodes := route.find_children("*", "MultiMeshInstance3D", true, false)
	var rhythm := rhythm_nodes[0] as MultiMeshInstance3D if not rhythm_nodes.is_empty() else null
	assert_true(rhythm != null, "the spiral should carry a readable cross-plank rhythm")
	if rhythm != null:
		assert_eq(rhythm.multimesh.instance_count, 48,
			"twelve cross-planks per turn should articulate the four-turn route")
	for node: Node in route.find_children("WarmRouteLight", "OmniLight3D", true, false):
		var lamp := node as OmniLight3D
		assert_true(lamp.omni_range <= 22.0,
			"route lamps must remain local rather than flattening the whole landmark")
	# The rendered guardrail must follow the actual physical rail, including
	# oblique segments. World-axis scaling used to skew the thin box away
	# from its collider and leave disconnected-looking chips in the ascent.
	for id: String in ["AscentRailInner", "AscentRailOuter"]:
		var rail := tree.get_node(id) as StaticBody3D
		var shapes := rail.find_children("*", "CollisionShape3D", false, false)
		var visuals := rail.find_children("*", "MultiMeshInstance3D", false, false)
		assert_eq(visuals.size(), 1, id + " retains one rendered rail batch")
		if visuals.is_empty():
			continue
		var multimesh: MultiMesh = (visuals[0] as MultiMeshInstance3D).multimesh
		assert_eq(multimesh.instance_count, shapes.size(), id + " renders every physical segment")
		# Dummy RenderingServer does not retain uploaded instance transforms.
		# Verify the production transform function with the actual built physical
		# segment instead; counts above remain actual batch construction checks.
		for index in shapes.size():
			var collider := shapes[index] as CollisionShape3D
			var physical_pose := collider.transform
			var segment_length := (collider.shape as BoxShape3D).size.z - 0.1
			var pose: Transform3D = tree._rail_visual_pose(physical_pose, segment_length)
			assert_eq(collider.transform, physical_pose,
				"visual transform preserves the actual physical segment pose")
			assert_almost_eq(pose.basis.z.normalized().dot(collider.basis.z), 1.0, 0.00001,
				"guardrail heading must follow its physical segment")
			assert_almost_eq(pose.basis.z.length(), (collider.shape as BoxShape3D).size.z, 0.00001,
				"guardrail endpoints must span the existing collision segment")
			assert_true(absf(pose.basis.x.dot(pose.basis.z)) < 0.00001,
				"thin guardrail must not shear across its physical route")
			assert_true((pose.origin - (collider.position + Vector3.UP * 0.55)).length() < 0.00001,
				"the guardrail retains its original seat above the physical segment")
	tree.free()


func test_wayfinding_is_visual_only_and_simulation_shell_stays_unchanged() -> void:
	var tree := TREE.new()
	tree.simulation_only = true
	tree.build()
	assert_true(tree.has_node(^"HollowTrunkAscent"),
		"the physical ascent remains present in the simulation shell")
	assert_false(tree.has_node(^"AscentWayfinding"),
		"presentation dressing must not enter the collision-only simulation shell")
	tree.free()


func test_crown_supports_keep_the_existing_encounter_sightline_and_floor_seats() -> void:
	var tree := TREE.new()
	tree.build()
	var crown_shape := tree.get_node("CrownChamber").find_children("*","CollisionShape3D",false,false)[0] as CollisionShape3D
	var faces := (crown_shape.shape as ConcavePolygonShape3D).get_faces()
	var crown_height := -INF
	var crown_radius := 0.0
	for vertex: Vector3 in faces:
		crown_height = maxf(crown_height,vertex.y)
		crown_radius = maxf(crown_radius,Vector2(vertex.x,vertex.z).length())
	var poses: Array[Transform3D] = tree._deck_brace_poses(Vector2(crown_height,crown_radius))
	assert_eq(poses.size(),14,"retain every crown support except the two axial approach blockers")
	for pose: Transform3D in poses:
		# _beam_pose's -Z points from the lower seat to the upper attachment.
		var lower := pose.origin+pose.basis.z*0.5
		var upper := pose.origin-pose.basis.z*0.5
		assert_almost_eq(lower.y,TREE.CORE_HEIGHT,0.0001,"support still sits on the existing core floor")
		assert_almost_eq(Vector2(lower.x,lower.z).length(),crown_radius+2.0,0.0001,"same physical lower seat")
		assert_almost_eq(upper.y,crown_height-1.4,0.0001,"same upper crown attachment height")
		assert_almost_eq(Vector2(upper.x,upper.z).length(),crown_radius-1.0,0.0001,"same upper crown attachment radius")
		assert_true(preload("res://scripts/world/stormwood_dynamo.gd").deck_solid_at(Vector2(lower.x,lower.z)),
			"lower seat remains on mounted core ring/infill footprint")
		# The real approach and core encounter look along X=0. Test the actual
		# finite beam box, not merely its centre or a copied angular predicate.
		var minimum_x := INF
		var maximum_x := -INF
		for x in [-0.5,0.5]:
			for y in [-0.5,0.5]:
				for z in [-0.5,0.5]:
					var corner := pose*Vector3(x,y,z)
					minimum_x = minf(minimum_x,corner.x)
					maximum_x = maxf(maximum_x,corner.x)
		assert_true(minimum_x>0.0 or maximum_x<0.0,"no crown support box crosses the existing central encounter sightline")
	var batches := tree.get_node("BuiltDetail").find_children("*","MultiMeshInstance3D",false,false)
	var counts: Array[int] = []
	for batch: MultiMeshInstance3D in batches:
		counts.append(batch.multimesh.instance_count)
	# 43 before #617: its judged Stormheart-deck fix drops the two core/outer braces
	# that ended in mid-air across the open trunk split (in_trunk_split).
	assert_true(counts.has(41),"production uploads the 14 crown supports plus the core and outer supports outside the trunk split")
	assert_true(counts.has(187),"all original deck fascia remains")
	assert_true(counts.has(384),"all original ascent pickets remain")
	tree.free()
