extends "res://tests/test_case.gd"

const REACH := preload("res://scripts/world/stonewater_reach.gd")
const VEGETATION_PATH := "res://data/config/bands/band3_the_river_lock/vegetation.json"


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
	assert_true(reach.get_node_or_null(^"ReachRunLandmark/RunLens_00") != null,
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
	assert_true(float(stats.water_area_m2) >= 2100.0,
		"the connected watercourse has collapsed back to prop-scale pools")
	var run_widths: Array = (REACH as Script).get_script_constant_map().get("RUN_WIDTHS", [])
	assert_true(run_widths.size() == 7 and run_widths[0] >= 3.4 and run_widths[1] >= 4.6
		and run_widths[3] >= 4.8 and run_widths[6] >= 4.9,
		"the named reach narrowed back into a cyan path")
	assert_between(float(stats.region_to_overlook_m), 25.0, 40.0,
		"the named region centre cannot see its overlook composition")
	assert_between(float(stats.approach_to_overlook_m), 35.0, 55.0,
		"the ordinary approach is not an establishing distance")
	assert_true(float(stats.sequence_span_m) >= 300.0,
		"the pass collapsed the broad wreck-to-spring sequence into one set piece")
	world.free()


func test_overlook_keeps_the_water_axis_open_instead_of_rebuilding_a_boulder_row() -> void:
	var world := _built()
	var reach := world.get_node(^"StonewaterReach")
	var west := reach.get_node(^"LockwaterOverlookLandmark/WestGateStone") as Node3D
	var east := reach.get_node(^"LockwaterOverlookLandmark/EastGateStone") as Node3D
	var crown := reach.get_node(^"LockwaterOverlookLandmark/CrownStone") as Node3D
	assert_true(west.position.x < REACH.LOCKWATER.x - 10.0,
		"west stone has drifted back across the open arrival view")
	assert_true(east.position.x > REACH.LOCKWATER.x + 10.0,
		"east stone has drifted back into the water centre")
	assert_true(crown.position.z > REACH.LOCKWATER.y + 18.0,
		"crown stone has collapsed back into the flat foreground boulder row")
	assert_true(west.scale.x > east.scale.x and crown.scale.x > east.scale.x,
		"overlook stones have lost the intentional scale hierarchy")
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


func test_stone_riffles_break_up_the_exposed_run_without_blocking_the_route() -> void:
	var world := _built()
	var reach := world.get_node(^"StonewaterReach")
	var stats: Dictionary = reach.call("stats")
	assert_eq(int(stats.riffle_clusters), 4,
		"the connected run has lost its authored stone-riffle rhythm")
	assert_eq(int(stats.riffle_stones), 16,
		"riffles no longer conceal enough of the flat water/ground-cover contacts")
	for cluster_name in ["WestRiffle", "MiddleRiffle", "LowerRiffle", "SpringRiffle"]:
		var cluster := reach.get_node_or_null(NodePath("ReachRunLandmark/%s" % cluster_name))
		assert_true(cluster != null, "%s is missing from the production reach" % cluster_name)
		if cluster != null:
			assert_eq(cluster.get_child_count(), 4,
				"%s no longer has an intentionally sparse four-stone composition" % cluster_name)
			assert_true(cluster.find_children("*", "CollisionShape3D", true, false).is_empty(),
				"%s changes the existing route with new collision" % cluster_name)
	assert_eq(int(stats.collision_shapes), 10,
		"the visual riffle pass unexpectedly changed traversal collision")
	world.free()


func test_shallow_water_material_does_not_emit_or_read_as_metal() -> void:
	var world := _built()
	var lens := world.get_node(^"StonewaterReach/ReachRunLandmark/RunLens_00") as MeshInstance3D
	var material := lens.material_override as StandardMaterial3D
	assert_true(material != null, "the production water ribbon has no material")
	if material != null:
		assert_false(material.emission_enabled,
			"shallow Stonewater is self-lit and will flatten to cyan in shade")
		assert_eq(material.metallic, 0.0,
			"shallow Stonewater still uses a metallic highlight response")
		assert_true(material.roughness >= 0.4,
			"shallow Stonewater is still polished enough to read as plastic")
	world.free()


func test_springhead_has_a_bounded_canopy_clearing_without_balding_the_reach() -> void:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(VEGETATION_PATH))
	assert_true(parsed is Dictionary, "Band 3 vegetation did not parse")
	if not parsed is Dictionary:
		return
	var spring_clearing := {}
	for raw: Variant in (parsed as Dictionary).get("clearings", []):
		var clearing := raw as Dictionary
		if str(clearing.get("id", "")) == "stonewater_springhead_basin":
			spring_clearing = clearing
			break
	assert_false(spring_clearing.is_empty(), "mature canopy can hide the Springhead basin")
	if spring_clearing.is_empty():
		return
	assert_eq(Vector2(float(spring_clearing.x), float(spring_clearing.z)), REACH.SPRING,
		"Springhead clearing drifted off the actual pool")
	assert_between(float(spring_clearing.radius), 14.0, 17.0,
		"Springhead clearing is either ineffective or strips the surrounding wood")


func test_production_world_wires_stonewater_after_existing_authored_props() -> void:
	var source := FileAccess.get_file_as_string("res://scripts/world/playground_world.gd")
	assert_true(source.contains('stonewater.name = "StonewaterReach"'),
		"the production Meadows scene does not build Stonewater Reach")
	assert_true(source.find('props.call("build")') < source.find('stonewater.name = "StonewaterReach"'),
		"the identity layer no longer builds over the authored props sequence")


func test_capture_hides_overlays_and_freezes_player_motion() -> void:
	var source := FileAccess.get_file_as_string("res://tools/capture_stonewater_reach_identity.gd")
	assert_true(source.contains('^"PlaygroundHUD"'),
		"the focused evidence harness no longer targets the dominant exploration HUD")
	assert_true(source.contains('overlay.set("visible", false)'),
		"the evidence harness leaves HUD or modal overlays over the location")
	assert_true(source.contains("player.process_mode = Node.PROCESS_MODE_DISABLED"),
		"the evidence player can move after being placed")
	assert_true(source.contains(".velocity = Vector3.ZERO"),
		"the frozen player retains locomotion velocity between evidence stands")
	assert_true(source.contains("STONEWATER-REACH-R5"),
		"the capture harness would overwrite previously judged Stonewater evidence")
