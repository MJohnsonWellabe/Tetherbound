extends "res://tests/test_case.gd"

const REACH := preload("res://scripts/world/stonewater_reach.gd")
const VEGETATION_PATH := "res://data/config/bands/band3_the_river_lock/vegetation.json"
const PROPS_PATH := "res://data/config/bands/band3_the_river_lock/props.json"
const SPAWNS_PATH := "res://data/config/bands/band3_the_river_lock/spawns.json"


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
	assert_true(reach.get_node_or_null(^"HaulageWreckLandmark/BrokenHaulerWheel") != null
		and reach.get_node_or_null(^"HaulageWreckLandmark/TippedLoadBed") != null,
		"the distant wagon has no readable damage silhouette above the road crest")
	assert_true(reach.get_node_or_null(^"LockwaterOverlookLandmark/LockwaterLens") != null,
		"Lockwater Overlook still has no visible water identity")
	assert_true(reach.get_node_or_null(^"SpringheadLandmark/SpringPool") != null,
		"the Springhead still has no actual visible pool")
	assert_true(reach.get_node_or_null(^"ReachRunLandmark/RunLens_00") != null,
		"Lockwater and Springhead are still isolated puddles rather than one reach")
	assert_true(reach.get_node_or_null(^"LockwaterOverlookLandmark/OverlookRouteStandard") != null,
		"the overlook has no complete installed wayfinding standard")
	assert_true(reach.get_node_or_null(^"LockwaterOverlookLandmark/OverlookDeck") != null,
		"the overlook has no human-scale viewing perch")
	assert_true(reach.get_node_or_null(^"LockwaterOverlookLandmark/OldReachCauseway") != null,
		"Lockwater has no dominant waterwork silhouette")
	assert_true(reach.get_node_or_null(^"SpringheadLandmark/SpringIntakeArch") != null,
		"Springhead does not repeat the waterwork identity")
	assert_true(reach.get_node_or_null(^"SpringheadLandmark/SpringIntakeCascade/IntakeWaterfall") != null,
		"Springhead's aperture looks through to ordinary forest instead of reading as an intake")
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
	assert_true(run_widths.size() == 7 and run_widths[0] >= 5.4 and run_widths[1] >= 6.4
		and run_widths[3] >= 6.8 and run_widths[6] >= 7.2,
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
	assert_true(west.scale.x > east.scale.x,
		"the arrival-side overlook stones have lost their intentional scale hierarchy")
	assert_true(crown.scale.x <= 1.1,
		"the far-bank crown still dominates the causeway like a channel boulder")
	world.free()


func test_waterwork_arches_and_complete_standards_unify_the_sequence() -> void:
	var world := _built()
	var reach := world.get_node(^"StonewaterReach")
	var stats: Dictionary = reach.call("stats")
	assert_eq(int(stats.stone_arches), 2,
		"the repeated Lockwater-to-Springhead waterwork motif is incomplete")
	assert_eq(int(stats.banner_standards), 1,
		"the builder added a second standard that can mask the authored wreck standard")
	assert_eq(int(stats.crested_standards), 1,
		"the installed overlook standard has no dimensional Stonewater identity")
	assert_true(int(stats.masonry_modules) >= 18,
		"the two bare castle arches lost their waterwork buttress/channel dressing")
	assert_eq(int(stats.cascade_sheets), 4,
		"the Springhead intake lost its visible stepped water drop")
	assert_true(reach.get_node_or_null(^"HaulageWreckLandmark/WreckRouteStandard") == null,
		"the redundant builder standard returned in front of the wreck")
	assert_true(reach.get_node_or_null(^"LockwaterOverlookLandmark/OverlookRouteStandard") != null,
		"the overlook has lost its matching route standard")
	assert_true(reach.get_node_or_null(
		^"LockwaterOverlookLandmark/OverlookRouteStandard/StonewaterStandardCrest") != null,
		"the full installed standard still reads as an undecorated flat rectangle")
	assert_true(reach.find_child("WreckPennant", true, false) == null
		and reach.find_child("OverlookPennant", true, false) == null,
		"flat box pennants returned in place of complete installed models")
	for arch_path in [
		^"LockwaterOverlookLandmark/OldReachCauseway",
		^"SpringheadLandmark/SpringIntakeArch",
	]:
		var arch := reach.get_node_or_null(arch_path) as MeshInstance3D
		assert_true(arch != null and arch.mesh == REACH.STONE_ARCH,
			"%s is not built from the installed stone arch" % arch_path)
		if arch != null:
			var material := arch.get_surface_override_material(0) as StandardMaterial3D
			assert_true(material != null and material.albedo_texture == REACH.BRICK_ALBEDO,
				"%s reverted to a flat grey placeholder material" % arch_path)
			if material != null:
				assert_true(material.uv1_triplanar and material.uv1_world_triplanar,
					"%s cannot map masonry onto the installed zero-UV castle mesh" % arch_path)
	world.free()


func test_causeway_front_keeps_stepped_buttresses_clear_of_the_bank_stone() -> void:
	var world := _built()
	var reach := world.get_node(^"StonewaterReach")
	var dress := reach.get_node(^"LockwaterOverlookLandmark/OldReachCausewayWaterworkDress")
	for side in ["West", "East"]:
		var upright := dress.get_node_or_null(NodePath("Buttress_%s" % side)) as MeshInstance3D
		var foot := dress.get_node_or_null(NodePath("ButtressFoot_%s" % side)) as MeshInstance3D
		assert_true(upright != null and foot != null,
			"the causeway %s buttress has no readable stepped front plane" % side)
		if upright != null and foot != null:
			var upright_box := upright.mesh as BoxMesh
			var foot_box := foot.mesh as BoxMesh
			assert_true(upright_box.size.z >= 3.4 and upright.position.z >= 1.1,
				"the causeway %s upright still projects flush with the arch" % side)
			assert_true(foot_box.size.z >= 5.9 and foot.position.z >= 3.2,
				"the causeway %s foot still has no visible forward step" % side)
			var upright_material := upright_box.material as StandardMaterial3D
			assert_true(upright_material != null and not upright_material.emission_enabled,
				"the causeway %s buttress was made emissive to fake night separation" % side)
	var approach_stand := Vector2(-104.0, 3465.0)
	var approach_axis := REACH.CAUSEWAY - approach_stand
	var run_stone := reach.get_node(^"ReachRunLandmark/RunStoneWest") as Node3D
	var crown_stone := reach.get_node(^"LockwaterOverlookLandmark/CrownStone") as Node3D
	var run_offset := Vector2(run_stone.position.x, run_stone.position.z) - approach_stand
	var crown_offset := Vector2(crown_stone.position.x, crown_stone.position.z) - approach_stand
	var run_clearance := absf(approach_axis.cross(run_offset)) / approach_axis.length()
	var crown_clearance := absf(approach_axis.cross(crown_offset)) / approach_axis.length()
	assert_true(run_clearance >= 10.0 and run_stone.scale.x <= 0.8,
		"the west run stone can still mask the causeway front")
	assert_true(crown_clearance >= 24.0 and crown_stone.scale.x <= 1.1,
		"the oversized crown stone still blocks the production approach sightline")
	var causeway := reach.get_node(^"LockwaterOverlookLandmark/OldReachCauseway") as MeshInstance3D
	var causeway_material := causeway.get_surface_override_material(0) as StandardMaterial3D
	assert_true(causeway_material != null and not causeway_material.emission_enabled,
		"the causeway was made emissive to force its night value")
	assert_true(causeway_material.albedo_color.get_luminance()
		> REACH.STONE_DARK.get_luminance(),
		"the causeway has no modest diffuse separation from surrounding rock")
	var lamp := reach.get_node(^"LockwaterOverlookLandmark/CausewayLantern") as OmniLight3D
	assert_true(Vector2(lamp.position.x, lamp.position.z).distance_to(REACH.CAUSEWAY) >= 3.5,
		"the causeway night light is still trapped inside its own masonry")
	assert_between(lamp.light_energy, 2.6, 3.0,
		"the causeway night light is either unchanged or overpowering")
	var intake := reach.get_node(^"SpringheadLandmark/SpringIntakeArch") as MeshInstance3D
	var intake_material := intake.get_surface_override_material(0) as StandardMaterial3D
	assert_eq(intake_material.albedo_color, REACH.STONE_DARK,
		"the accepted Springhead palette changed with the causeway-only lift")
	world.free()


func test_overlook_standard_supports_instead_of_owning_the_approach() -> void:
	var world := _built()
	var standard := world.get_node(
		^"StonewaterReach/LockwaterOverlookLandmark/OverlookRouteStandard") as Node3D
	var approach_axis := REACH.CAUSEWAY - REACH.APPROACH
	var to_standard := Vector2(standard.position.x, standard.position.z) - REACH.APPROACH
	var lateral_clearance := absf(approach_axis.cross(to_standard)) / approach_axis.length()
	assert_true(lateral_clearance >= 14.0,
		"the standard returned to the centre of the waterworks approach")
	assert_true(standard.scale.x <= 1.7,
		"the route standard can still dominate the causeway silhouette")
	world.free()


func test_springhead_cascade_has_drop_steps_and_clear_bank_reeds() -> void:
	var world := _built()
	var reach := world.get_node(^"StonewaterReach")
	var spring := reach.get_node(^"SpringheadLandmark")
	var cascade := spring.get_node(^"SpringIntakeCascade")
	var waterfall := cascade.get_node(^"IntakeWaterfall") as MeshInstance3D
	var waterfall_box: BoxMesh = waterfall.mesh as BoxMesh if waterfall != null else null
	assert_true(waterfall_box != null and waterfall_box.size.y >= 2.5,
		"the intake has no visible vertical water drop")
	if waterfall_box != null:
		var waterfall_material := waterfall_box.material as StandardMaterial3D
		assert_true(waterfall_material != null and not waterfall_material.emission_enabled,
			"the intake cascade was made self-lit to force its night value")
	assert_true(cascade.get_node_or_null(^"SpillLintel") != null,
		"the cascade has no raised source lip")
	for i in 3:
		assert_true(cascade.get_node_or_null(NodePath("CascadeSheet_%02d" % i)) != null,
			"the cascade step %d has no visible water sheet" % i)
	var reeds := 0
	for child: Node in spring.get_children():
		if not str(child.name).begins_with("Reed_"):
			continue
		reeds += 1
		var reed := child as Node3D
		var offset := Vector2(reed.position.x, reed.position.z) - REACH.SPRING
		var ellipse_distance := Vector2(offset.x / REACH.SPRING_RADII.x,
			offset.y / REACH.SPRING_RADII.y).length()
		assert_true(ellipse_distance >= 1.04,
			"Springhead reed %s is rooted through the visible pool" % child.name)
	assert_eq(reeds, 18, "Springhead bank reeds lost their restrained outer ring")
	var marker := spring.get_node(^"SpringMarkerStone") as Node3D
	assert_true(marker.position.z >= 3574.0 and marker.scale.x <= 0.8,
		"the Springhead marker stone returned to the evidence sightline")
	var intake_lamp := spring.get_node(^"IntakeLantern") as OmniLight3D
	assert_true(Vector2(intake_lamp.position.x, intake_lamp.position.z).distance_to(
		REACH.SPRING_INTAKE) >= 2.8,
		"the intake night light is still buried inside the headwall")
	world.free()


func test_arches_face_the_water_axis_at_landmark_scale() -> void:
	var world := _built()
	var reach := world.get_node(^"StonewaterReach")
	var causeway := reach.get_node(^"LockwaterOverlookLandmark/OldReachCauseway") as MeshInstance3D
	var intake := reach.get_node(^"SpringheadLandmark/SpringIntakeArch") as MeshInstance3D
	assert_eq(Vector2(causeway.position.x, causeway.position.z), Vector2(-84.0, 3482.0),
		"the causeway drifted back to the frame edge where it reads as a slab")
	assert_true(causeway.scale.x >= 4.5 and is_equal_approx(rad_to_deg(causeway.rotation.y), -104.0),
		"the causeway no longer presents a landmark-scale open aperture")
	assert_true(intake.scale.x >= 4.1 and is_equal_approx(rad_to_deg(intake.rotation.y), -133.0),
		"the Springhead intake no longer presents its aperture down the water axis")
	world.free()


func test_arch_collisions_preserve_the_open_waterwork_apertures() -> void:
	var world := _built()
	var reach := world.get_node(^"StonewaterReach")
	for prefix in ["OldReachCauseway", "SpringIntakeArch"]:
		var west := reach.find_child("%sWestJambCollision" % prefix, true, false) as StaticBody3D
		var east := reach.find_child("%sEastJambCollision" % prefix, true, false) as StaticBody3D
		assert_true(west != null and east != null,
			"%s does not have two bounded jamb footprints" % prefix)
		if west != null and east != null:
			assert_true(Vector2(west.position.x, west.position.z).distance_to(
				Vector2(east.position.x, east.position.z)) > 2.5,
				"%s jamb proxies fill the open arch" % prefix)
	world.free()


func test_water_is_nonblocking_and_only_solid_landmarks_collide() -> void:
	var world := _built()
	var reach := world.get_node(^"StonewaterReach")
	for child in reach.find_children("*", "MeshInstance3D", true, false):
		if "water" in str((child as Node).name).to_lower() or "glint" in str((child as Node).name).to_lower() or "pool" in str((child as Node).name).to_lower():
			assert_true((child as Node).find_children("*", "CollisionShape3D", true, false).is_empty(),
				"a decorative water surface blocks traversal")
	var stats: Dictionary = reach.call("stats")
	assert_eq(int(stats.collision_shapes), 17,
		"collision must stay bounded to the wreck, eleven hero stones, shallow deck, and four arch jambs")
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
	assert_eq(int(stats.collision_shapes), 17,
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
		assert_true(material.metallic_specular <= 0.15,
			"shallow Stonewater can still blow out into a white moon highlight")
		assert_true(material.vertex_color_use_as_albedo,
			"the water cannot use its transparent bank fringe")
	var colours: PackedColorArray = lens.mesh.surface_get_arrays(0)[Mesh.ARRAY_COLOR]
	assert_true(not colours.is_empty(), "the water mesh lost its bank-fringe vertex colours")
	var saw_transparent_edge := false
	for colour: Color in colours:
		if colour.a < 0.05:
			saw_transparent_edge = true
			break
	assert_true(saw_transparent_edge,
		"the water reverted to a hard-edged opaque polygon")
	var expected_minimum_vertices := 24 * (3 + (REACH.WATER_RADIAL_RINGS - 1) * 6)
	var vertices: PackedVector3Array = lens.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	assert_true(vertices.size() >= expected_minimum_vertices,
		"the run lost its terrain-following radial tessellation and can expose turf islands")
	assert_true(world.get_node(^"StonewaterReach").find_child("LockwaterGlint", true, false) == null
		and world.get_node(^"StonewaterReach").find_child("SpringInnerGlint", true, false) == null,
		"an overlapping glint sheet can still blow out at night")
	world.free()


func test_water_footprint_clears_local_scatter_and_camera_grass() -> void:
	var world := _built()
	var reach := world.get_node(^"StonewaterReach")
	var stats: Dictionary = reach.call("stats")
	assert_eq(int(stats.water_clear_markers), 19,
		"the connected pools/run do not have complete local grass clearance")
	var markers := 0
	for child: Node in reach.get_children():
		if str(child.name).begins_with("WaterGrassClear_"):
			markers += 1
			assert_true(child.is_in_group("grass_clear"),
				"a water-clear marker does not use the production GrassField contract")
			assert_true(float(child.get_meta("grass_clear_radius", 0.0)) >= 6.0,
				"a water-clear marker is too small to protect its water section")
	assert_eq(markers, 19, "water-clear marker stats do not match the built nodes")
	world.free()


func test_wreck_has_one_offset_authored_standard() -> void:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(PROPS_PATH))
	assert_true(parsed is Dictionary, "Band 3 props did not parse")
	if not parsed is Dictionary:
		return
	var standard := {}
	var count := 0
	for raw_cluster: Variant in (parsed as Dictionary).get("clusters", []):
		var cluster := raw_cluster as Dictionary
		if int(cluster.get("order", -1)) != 3005:
			continue
		for raw_prop: Variant in cluster.get("props", []):
			var prop := raw_prop as Dictionary
			if str(prop.get("model", "")) == "Banner_1":
				standard = prop
				count += 1
	assert_eq(count, 1, "the wreck does not have exactly one authored route standard")
	if not standard.is_empty():
		var at: Array = standard.get("at", [])
		assert_true(at.size() == 2 and float(at[0]) >= REACH.WRECK.x + 6.0,
			"the authored standard can mask the wagon from the road")


func test_springhead_authored_props_remain_on_the_dry_bank() -> void:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(PROPS_PATH))
	assert_true(parsed is Dictionary, "Band 3 props did not parse")
	if not parsed is Dictionary:
		return
	var found := 0
	for raw_cluster: Variant in (parsed as Dictionary).get("clusters", []):
		var cluster := raw_cluster as Dictionary
		if int(cluster.get("order", -1)) != 3007:
			continue
		for raw_prop: Variant in cluster.get("props", []):
			var prop := raw_prop as Dictionary
			var at: Array = prop.get("at", [])
			assert_eq(at.size(), 2, "Springhead prop has no world position")
			if at.size() != 2:
				continue
			var offset := Vector2(float(at[0]), float(at[1])) - REACH.SPRING
			var ellipse_distance := Vector2(offset.x / REACH.SPRING_RADII.x,
				offset.y / REACH.SPRING_RADII.y).length()
			assert_true(ellipse_distance >= 1.04,
				"%s moved back inside the visible Springhead water" % str(prop.get("name", prop.get("model", "prop"))))
			found += 1
	assert_eq(found, 8, "the complete authored Springhead bank cluster was not checked")


func test_springhead_ground_creatures_stay_on_dry_banks() -> void:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(SPAWNS_PATH))
	assert_true(parsed is Dictionary, "Band 3 spawns did not parse")
	if not parsed is Dictionary:
		return
	var expected := {
		3017: [Vector2(-31.0, 3531.0), 12.0],
		3018: [Vector2(27.0, 3584.0), 12.0],
		3102: [Vector2(22.0, 3561.0), 3.0],
		3911: [Vector2(15.0, 3542.0), 3.0],
	}
	var found := 0
	for raw_spawn: Variant in (parsed as Dictionary).get("spawns", []):
		var spawn := raw_spawn as Dictionary
		var order := int(spawn.get("order", -1))
		if not expected.has(order):
			continue
		var centre: Array = spawn.get("centre", [])
		var contract: Array = expected[order]
		assert_eq(Vector2(float(centre[0]), float(centre[2])), contract[0],
			"Springhead spawn %d drifted back over the water" % order)
		assert_eq(float(spawn.get("radius", 0.0)), contract[1],
			"Springhead spawn %d can spread back into the pool" % order)
		found += 1
	assert_eq(found, expected.size(), "not all Springhead dry-bank spawn contracts were found")


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
	for required_view in [
		"09-haulage-wreck-night", "10-causeway-front-day", "11-causeway-reverse-day",
		"12-causeway-front-night", "13-causeway-reverse-night", "14-spring-arrival-night",
		"15-haulage-wreck-oblique-day", "16-haulage-wreck-oblique-night", "17-road-arrival-night",
	]:
		assert_true(source.contains(required_view),
			"the repaired Stonewater evidence plan omits %s" % required_view)
	assert_true(source.contains('^"PlaygroundHUD"'),
		"the focused evidence harness no longer targets the dominant exploration HUD")
	assert_true(source.contains('overlay.set("visible", false)'),
		"the evidence harness leaves HUD or modal overlays over the location")
	assert_true(source.contains("player.process_mode = Node.PROCESS_MODE_DISABLED"),
		"the evidence player can move after being placed")
	assert_true(source.contains(".velocity = Vector3.ZERO"),
		"the frozen player retains locomotion velocity between evidence stands")
	assert_true(source.contains("FRESH_OUTPUT.create_fresh"),
		"the capture harness can overwrite previously judged Stonewater evidence")
	assert_true(source.contains('Vector2(-2.0, 3562.0)')
		and source.contains('Vector2(0.0, 3568.0)'),
		"Springhead evidence returned to the tree/creature-occluded seats")
	assert_true(source.contains('Vector2(-89.0, 3264.0)'),
		"wreck oblique evidence returned to the creature-occluded east seat")
