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
