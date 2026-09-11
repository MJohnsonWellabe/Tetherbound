extends "res://tests/test_case.gd"

const REACH := preload("res://scripts/world/stonewater_reach.gd")


class GroundFixture extends Node3D:
	func ground_height_at(x: float, z: float) -> float:
		return 3.0 + x * 0.001 - z * 0.0004


func _built() -> Node3D:
	var world := GroundFixture.new()
	var reach: Node3D = REACH.new()
	reach.name = "StonewaterReach"
	world.add_child(reach)
	assert_true(bool(reach.call("build", world)), "Stonewater Reach failed its production build path")
	return world


func test_broad_sequence_has_three_distinct_landmark_beats() -> void:
	var world := _built()
	var reach := world.get_node(^"StonewaterReach")
	assert_true(reach.get_node_or_null(^"HaulageWreckLandmark/WreckedHauler") != null,
		"the opening beat has no commercial-scale haulage wreck")
	assert_true(reach.get_node_or_null(^"LockwaterOverlookLandmark/LockwaterLens") != null,
		"Lockwater Overlook still has no visible water identity")
	assert_true(reach.get_node_or_null(^"SpringheadLandmark/SpringPool") != null,
		"the Springhead still has no actual visible pool")
	assert_true(reach.get_node_or_null(^"ReachRunLandmark/StonewaterRun") != null,
		"Lockwater and Springhead are still isolated puddles rather than one reach")
	assert_true(reach.get_node_or_null(^"LockwaterOverlookLandmark/OverlookBeaconPost") != null,
		"the overlook has no vertical wayfinding silhouette")
	assert_true(reach.get_node_or_null(^"LockwaterOverlookLandmark/OverlookDeck") != null,
		"the overlook has no human-scale viewing perch")
	world.free()


func test_water_and_stone_composition_is_large_enough_for_an_ordinary_camera() -> void:
	var world := _built()
	var stats: Dictionary = world.get_node(^"StonewaterReach").call("stats")
	assert_true(float(stats.water_area_m2) >= 300.0,
		"Stonewater water surfaces are still prop-scale")
	assert_true(int(stats.hero_stones) >= 5,
		"the overlook/spring lack a large stone silhouette family")
	assert_true(int(stats.reeds) >= 40,
		"the visible water has no readable wet-bank vegetation")
	assert_eq(int(stats.run_sections), 6,
		"the named reach no longer has its complete winding water run")
	assert_true(float(stats.water_area_m2) >= 1200.0,
		"the connected watercourse has collapsed back to prop-scale pools")
	assert_between(float(stats.region_to_overlook_m), 25.0, 40.0,
		"the named region centre cannot see its overlook composition")
	assert_between(float(stats.approach_to_overlook_m), 35.0, 55.0,
		"the ordinary approach is not an establishing distance")
	assert_true(float(stats.sequence_span_m) >= 300.0,
		"the pass collapsed the broad wreck-to-spring sequence into one set piece")
	world.free()


func test_water_is_nonblocking_and_only_solid_landmarks_collide() -> void:
	var world := _built()
	var reach := world.get_node(^"StonewaterReach")
	for child in reach.find_children("*", "MeshInstance3D", true, false):
		if "water" in str((child as Node).name).to_lower() or "glint" in str((child as Node).name).to_lower() or "pool" in str((child as Node).name).to_lower():
			assert_true((child as Node).find_children("*", "CollisionShape3D", true, false).is_empty(),
				"a decorative water surface blocks traversal")
	var stats: Dictionary = reach.call("stats")
	assert_eq(int(stats.collision_shapes), 10,
		"collision must stay bounded to the wreck, eight hero stones, and shallow deck")
	world.free()


func test_production_world_wires_stonewater_after_existing_authored_props() -> void:
	var source := FileAccess.get_file_as_string("res://scripts/world/playground_world.gd")
	assert_true(source.contains('stonewater.name = "StonewaterReach"'),
		"the production Meadows scene does not build Stonewater Reach")
	assert_true(source.find('props.call("build")') < source.find('stonewater.name = "StonewaterReach"'),
		"the identity layer no longer builds over the authored props sequence")
