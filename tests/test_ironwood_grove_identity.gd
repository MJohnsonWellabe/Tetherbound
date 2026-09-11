extends "res://tests/test_case.gd"

const HARVEST_PATH := "res://data/config/bands/band4_upper_meadows_ironwood/harvest.json"
const VEGETATION_PATH := "res://data/config/bands/band4_upper_meadows_ironwood/vegetation.json"
const SPAWNS_PATH := "res://data/config/bands/band4_upper_meadows_ironwood/spawns.json"
const SPECIES_PATH := "res://data/creatures/species.json"
const CAPTURE_HARNESS := preload("res://tools/capture_ironwood_grove_identity.gd")
const PRESENTATION := preload("res://scripts/world/ironwood_grove_presentation.gd")
const PRESENTATION_PATH := "res://data/config/ironwood_grove_presentation.json"
const ROUTE_A := Vector2(-300.0, 4990.0)
const ROUTE_B := Vector2(-420.0, 5140.0)
const APPROACH := Vector2(-321.0, 5025.0)
const GROVE_CENTRE := Vector2(-344.0, 5075.0)
const CAMERA_ARM_M := 5.2


class FlatWorld:
	extends Node3D

	func ground_height_at(_x: float, _z: float) -> float:
		return 0.0


func test_named_ironwood_grove_has_a_varied_old_growth_canopy() -> void:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(HARVEST_PATH))
	assert_true(parsed is Dictionary, "Band 4 harvest data did not parse")
	if not parsed is Dictionary:
		return
	var scales: Array[float] = []
	var positions: Array[Vector2] = []
	for raw: Variant in (parsed as Dictionary).get("nodes", []):
		if not raw is Dictionary:
			continue
		var node := raw as Dictionary
		var order := int(node.get("order", -1))
		if order < 4000 or order > 4004:
			continue
		scales.append(float(node.get("model_scale", 0.0)))
		var at: Array = node.get("at", [])
		if at.size() >= 2:
			positions.append(Vector2(float(at[0]), float(at[1])))
	assert_eq(scales.size(), 5, "the named grove lost one of its five ironwoods")
	if scales.size() != 5:
		return
	var mature := scales.filter(func(value: float) -> bool: return value >= 0.60)
	assert_true(mature.size() >= 3,
		"Ironwood Grove no longer has a three-crown old-growth mass")
	assert_true(scales.min() <= 0.40 and scales.max() >= 0.80,
		"Ironwood Grove lost its young-to-elder scale story")
	var elders := scales.filter(func(value: float) -> bool: return value >= 0.90)
	assert_true(elders.size() >= 2 and scales.max() <= 1.0,
		"Ironwood Grove lost its paired 15-20m approach hierarchy")
	for point in positions:
		assert_true(point.distance_to(Vector2(-345.0, 5060.0)) <= 32.0,
			"an authored grove tree drifted out of the named composition")

	var vegetation: Variant = JSON.parse_string(FileAccess.get_file_as_string(VEGETATION_PATH))
	assert_true(vegetation is Dictionary, "Band 4 vegetation data did not parse")
	if not vegetation is Dictionary:
		return
	var identity_glade: Dictionary = {}
	for raw: Variant in (vegetation as Dictionary).get("clearings", []):
		if raw is Dictionary and int((raw as Dictionary).get("order", -1)) == 4003:
			identity_glade = raw as Dictionary
			break
	assert_false(identity_glade.is_empty(), "Ironwood Grove lost its bounded identity glade")
	if identity_glade.is_empty():
		return
	assert_true(Vector2(float(identity_glade.get("x", 0.0)), float(identity_glade.get("z", 0.0))).distance_to(Vector2(-344.0, 5075.0)) <= 1.0,
		"Ironwood identity glade drifted off the authored crown cluster")
	assert_true(float(identity_glade.get("radius", 0.0)) >= 16.0 and float(identity_glade.get("radius", 0.0)) <= 20.0,
		"Ironwood identity glade no longer isolates the crown without stripping the corridor")

	var arrival_lens: Dictionary = {}
	for raw: Variant in (vegetation as Dictionary).get("clearings", []):
		if raw is Dictionary and int((raw as Dictionary).get("order", -1)) == 4006:
			arrival_lens = raw as Dictionary
			break
	assert_false(arrival_lens.is_empty(),
		"the measured Ironwood route-arrival occluders have no bounded sightline lens")
	if arrival_lens.is_empty():
		return
	var lens_centre := Vector2(float(arrival_lens.get("x", 0.0)), float(arrival_lens.get("z", 0.0)))
	var lens_radius := float(arrival_lens.get("radius", 0.0))
	assert_true(lens_radius >= 12.0 and lens_radius <= 12.5,
		"the Ironwood arrival lens no longer clears the R7 decorative sapling screen")
	for blocked_tree: Vector2 in [
		Vector2(-319.19, 5028.28),
		Vector2(-316.14, 5029.68),
		Vector2(-316.30, 5022.94),
		Vector2(-329.06, 5016.29),
	]:
		assert_true(blocked_tree.distance_to(lens_centre) < lens_radius,
			"a production-measured foreground trunk remains inside the Grove arrival camera wedge")
	assert_true(Vector2(-311.18, 5027.80).distance_to(lens_centre) > lens_radius,
		"the scoped Ironwood sightline correction stripped both lateral framing trees")
	for harvest_point: Vector2 in positions:
		assert_true(harvest_point.distance_to(lens_centre) > lens_radius,
			"the arrival lens overlaps an authored ironwood harvest seat")
	var spawn_data := JSON.parse_string(FileAccess.get_file_as_string(SPAWNS_PATH)) as Dictionary
	for encounter_order: int in [4007, 4103]:
		var encounter := _spawn(spawn_data, encounter_order)
		var encounter_at := Vector2(float(encounter.centre[0]), float(encounter.centre[2]))
		assert_true(encounter_at.distance_to(lens_centre) > lens_radius,
			"the decorative sightline lens overlaps functional encounter %d" % encounter_order)


func test_current_grove_has_a_dedicated_production_evidence_harness() -> void:
	assert_true(CAPTURE_HARNESS != null,
		"Ironwood Grove fell back to the stale pre-crown generic location strip")
	assert_true(CAPTURE_HARNESS.approach_distance_m() >= 50.0
		and CAPTURE_HARNESS.approach_distance_m() <= 60.0,
		"Ironwood arrival proof drifted outside the landmark's real-route 50-60m approach")
	var source := FileAccess.get_file_as_string("res://tools/capture_ironwood_grove_identity.gd")
	assert_true(source.contains("IRONWOOD-GROVE-IDENTITY-R8-WORKFLOW")
		and source.contains('"fov": 62.0') and source.contains('"fov": 58.0'),
		"R8 evidence lost its documented hero/workyard composition")
	for forbidden in ["creature.visible = false", "encounter.visible = false", "queue_free()"]:
		assert_false(source.contains(forbidden),
			"R6 evidence must crop functional creature clutter by composition, not mutation")


func test_r6_presentation_keeps_the_five_harvest_seats_and_makes_age_visible_at_the_roots() -> void:
	var harvest := JSON.parse_string(FileAccess.get_file_as_string(HARVEST_PATH)) as Dictionary
	var config := JSON.parse_string(FileAccess.get_file_as_string(PRESENTATION_PATH)) as Dictionary
	assert_true(not harvest.is_empty() and not config.is_empty(),
		"Ironwood harvest/presentation data did not parse")
	if harvest.is_empty() or config.is_empty():
		return
	var harvest_by_order := {}
	for raw: Variant in harvest.get("nodes", []):
		if raw is Dictionary:
			var row := raw as Dictionary
			var order := int(row.get("order", -1))
			if order >= 4000 and order <= 4004:
				harvest_by_order[order] = row
	var footings := config.get("tree_footings", []) as Array
	assert_eq(harvest_by_order.size(), 5, "the functional grove no longer has exactly five ironwoods")
	assert_eq(footings.size(), 5, "R6 lost an age-specific ironwood root footing")
	if harvest_by_order.size() != 5 or footings.size() != 5:
		return
	var radii: Array[float] = []
	for raw: Variant in footings:
		var footing := raw as Dictionary
		var order := int(footing.get("harvest_order", -1))
		assert_true(harvest_by_order.has(order), "a root footing is not tied to a live ironwood")
		if not harvest_by_order.has(order):
			continue
		var node := harvest_by_order[order] as Dictionary
		assert_eq(int(node.get("amount", 0)), 3, "R6 changed an ironwood yield")
		var at := _at(footing.get("at", []))
		assert_true(at.is_equal_approx(_at(node.get("at", []))),
			"an R6 root footing drifted away from its functional harvest seat")
		radii.append(float(footing.get("root_radius_m", 0.0)))
	assert_true(radii.min() <= 1.7 and radii.max() >= 5.0,
		"the young-to-elder story is not legible in the root footprint")
	assert_true(float(footings[0].root_radius_m) > float(footings[2].root_radius_m)
		and float(footings[2].root_radius_m) > float(footings[4].root_radius_m),
		"root hierarchy no longer tracks elder, mature, and young ironwoods")


func test_r8_has_a_grounded_arrival_coherent_old_growth_and_visible_craft_process() -> void:
	var config := JSON.parse_string(FileAccess.get_file_as_string(PRESENTATION_PATH)) as Dictionary
	assert_true(not config.is_empty(), "Ironwood presentation config did not parse")
	if config.is_empty():
		return
	var hero := config.get("hero_tree", {}) as Dictionary
	var hero_at := _at(hero.get("at", []))
	assert_true(hero_at.is_equal_approx(Vector2(-342.0, 5078.0)),
		"R6 hero drifted away from the elder harvest seat")
	assert_true(float(hero.get("height_m", 0.0)) >= 18.0
		and float(hero.get("canopy_width_m", 0.0)) >= 16.0,
		"Ironwood Grove lost its road-visible old-growth silhouette")
	assert_eq(str(hero.get("model", "")),
		"res://assets/environment/meadows/ironwood/ironwood_ancient_tree.glb",
		"Ironwood Grove lost its selected Meshy ancient-tree hero")
	assert_true(hero_at.distance_to(APPROACH) <= 60.0,
		"old-growth hero is not visible from the real route arrival")
	var floor := config.get("arrival_floor", {}) as Dictionary
	assert_false(floor.has("inlays"),
		"the rejected pale overlapping soil inlays returned in R6")
	var waypoints := floor.get("waypoints", []) as Array
	assert_true(waypoints.size() >= 5,
		"R6 lost the continuous terrain-conforming route into the hero tree")
	assert_true(float(floor.get("half_width_m", 0.0)) <= 2.3,
		"R6 arrival wear expanded back into a broad flat soil field")
	var canopy_lobes := hero.get("canopy_lobes", []) as Array
	assert_true(canopy_lobes.size() >= 9,
		"R6 lost the overlapping old-growth canopy mass")
	var broad_lobes := 0
	for raw_lobe: Variant in canopy_lobes:
		var lobe := raw_lobe as Dictionary
		var size := lobe.get("size", []) as Array
		assert_true(size.size() == 3 and float(size[0]) >= 5.2 and float(size[1]) >= 3.4,
			"an R6 canopy lobe regressed to a branch-tip pom-pom")
		if size.size() == 3 and float(size[0]) >= 6.5:
			broad_lobes += 1
	assert_true(broad_lobes >= 3,
		"R6 lost the broad overlapping core that unifies the old-growth canopy")
	var glade := config.get("crafting_glade", {}) as Dictionary
	for key: String in ["workbench", "anvil", "tool_rack", "timber", "stump", "raw_stock", "timber_shelter", "lumber_stack", "hewing_bay", "board_rack"]:
		assert_true(glade.has(key), "worked glade lost its %s" % key)
	assert_true((glade.get("timber", []) as Array).size() >= 3
		and (glade.get("lumber_stack", []) as Array).size() >= 5,
		"worked glade no longer shows a substantial ironwood timber stack")
	var raw_stock := glade.get("raw_stock", {}) as Dictionary
	var hewing := glade.get("hewing_bay", {}) as Dictionary
	var seasoning := glade.get("board_rack", {}) as Dictionary
	assert_true(int(raw_stock.get("log_count", 0)) >= 4
		and float(hewing.get("beam_length_m", 0.0)) <= 4.5
		and int(seasoning.get("board_count", 0)) >= 7,
		"R8 lost the raw-stock, compact cutting, or finished-board stage")
	assert_true(_at(raw_stock.get("at", [])).distance_to(_at(hewing.get("at", []))) >= 4.5
		and _at(hewing.get("at", [])).distance_to(_at(seasoning.get("at", []))) >= 3.5,
		"R8 craft stages collapsed back into one unreadable prop pile")
	var source := FileAccess.get_file_as_string("res://scripts/world/playground_world.gd")
	assert_true(source.contains("IRONWOOD_GROVE_PRESENTATION.new()")
		and source.contains('ironwood_grove.name = "IronwoodGrovePresentation"')
		and source.contains("if not simulation_only:"),
		"production Meadows no longer mounts the R6 grove identity layer")
	var world := FlatWorld.new()
	var presentation := PRESENTATION.new()
	world.add_child(presentation)
	assert_true(bool(presentation.call("build", world)),
		"R6 Ironwood presentation did not build its complete authored composition")
	var stats := presentation.call("stats") as Dictionary
	assert_true(int(stats.get("root_segments", 0)) >= 27,
		"R6 did not build the five-tree root hierarchy")
	assert_true(int(stats.get("installed_props", 0)) >= 14,
		"R6 worked glade did not build its installed shelter, tools and timber")
	assert_true(int(stats.get("path_markers", 0)) >= 6,
		"R6 worked glade lost its path threshold")
	assert_true(bool(stats.get("hero_model_installed", false))
		or (int(stats.get("hero_branches", 0)) >= 16
		and int(stats.get("hero_leaf_clusters", 0)) >= 9),
		"Ironwood lost both its selected model and procedural fallback silhouette")
	assert_true(int(stats.get("arrival_stations", 0)) >= 24,
		"R6 lost the continuous terrain-conforming worn arrival")
	assert_true(int(stats.get("workyard_structures", 0)) >= 4
		and int(stats.get("craft_processes", 0)) >= 3,
		"R8 lost its raw-stock, hewing, or seasoning craft stage")
	assert_eq(int(stats.get("collision_shapes", -1)), 0,
		"collisionless grove presentation introduced a route/harvest obstacle")
	assert_true(presentation.get_node_or_null(^"AncientIronwoodHero") != null
		and presentation.get_node_or_null(^"IronwoodWornArrival") != null
		and presentation.get_node_or_null(^"IronwoodWornArrival/TerrainConformingWearRibbon") != null
		and presentation.get_node_or_null(^"WorkedIronwoodGlade/InstalledTimberShelter") != null
		and presentation.get_node_or_null(^"WorkedIronwoodGlade/InstalledToolRack/InstalledAxe") != null
		and presentation.get_node_or_null(^"WorkedIronwoodGlade/InstalledToolRack/InstalledPickaxe") != null
		and presentation.get_node_or_null(^"WorkedIronwoodGlade/RawIronwoodStockCradle/UnmilledIronwoodLog_00") != null
		and presentation.get_node_or_null(^"WorkedIronwoodGlade/InstalledTimberShelter/SawGantryHeader") != null
		and presentation.get_node_or_null(^"WorkedIronwoodGlade/ActiveHewingBay/HewingAxe") != null
		and presentation.get_node_or_null(^"WorkedIronwoodGlade/ActiveHewingBay/RoundInfeedStock") != null
		and presentation.get_node_or_null(^"WorkedIronwoodGlade/ActiveHewingBay/ShapedIronwoodBlank") != null
		and presentation.get_node_or_null(^"WorkedIronwoodGlade/ActiveHewingBay/SuspendedFrameSawBlade") != null
		and presentation.get_node_or_null(^"WorkedIronwoodGlade/SeasoningBoardRack/FinishedBoardBundle") != null,
		"R6 lost its hero focal, grounded wear ribbon, or installed craft process")
	assert_true(presentation.get_node_or_null(^"WorkedIronwoodGlade/InstalledTimberShelter/SeasoningHeader") == null
		and presentation.get_node_or_null(^"WorkedIronwoodGlade/InstalledTimberShelter/WorkedHeaderBeam") == null,
		"R8 restored the oversized empty double-rail silhouette")
	assert_true(presentation.get_node_or_null(^"RoadVisibleCrownThreshold") == null
		and presentation.get_node_or_null(^"PairedElderCrown") == null,
		"the rejected grey scaffold crown frames returned in R4")
	world.remove_child(presentation)
	presentation.free()
	world.free()


func test_r8_night_fill_reveals_roots_and_trunk_without_icy_canopy_clipping() -> void:
	var config := JSON.parse_string(FileAccess.get_file_as_string(PRESENTATION_PATH)) as Dictionary
	var lights := config.get("night_lights", []) as Array
	assert_eq(lights.size(), 5, "Ironwood Grove should have two hero pools and three work/route pools")
	var hero_light_count := 0
	var raised_canopy_fill_count := 0
	for raw: Variant in lights:
		var light := raw as Dictionary
		assert_true(float(light.get("range_m", 0.0)) <= 18.0,
			"Ironwood night fill expanded beyond the named location")
		assert_true(float(light.get("energy", 0.0)) <= 1.6,
			"Ironwood night fill became a floodlight")
		assert_true(_at(light.get("at", [])).distance_to(GROVE_CENTRE) <= 34.0,
			"Ironwood night fill escaped the route/grove/glade composition")
		if str(light.get("name", "")).begins_with("Elder"):
			hero_light_count += 1
			assert_true(float(light.get("range_m", 0.0)) >= 12.0,
				"the old-growth roots or bark will disappear at night")
			assert_true(float(light.get("energy", 0.0)) <= 1.2,
				"R8 elder fill can bleach the Meshy bark or foliage")
			if float(light.get("height_m", 0.0)) >= 6.0:
				raised_canopy_fill_count += 1
	assert_eq(hero_light_count, 2, "R8 should own exactly two bounded hero lights")
	assert_eq(raised_canopy_fill_count, 0,
		"R8 should light roots and trunk, not clip the generated canopy blue-white")


func test_ordinary_burrowback_cluster_clears_the_grove_route_camera() -> void:
	var source: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(SPAWNS_PATH))
	var ordinary := _spawn(source, 4103)
	var alpha := _spawn(source, 4007)
	assert_false(ordinary.is_empty(), "Ironwood ordinary Burrowback cluster is missing")
	assert_false(alpha.is_empty(), "Ironwood authored Burrowback alpha is missing")
	if ordinary.is_empty() or alpha.is_empty():
		return
	assert_eq(str(ordinary.species), "burrowback")
	assert_eq(str(ordinary.table), "meadows_rock")
	assert_eq(int(ordinary.count), 3)
	assert_false(ordinary.has("alpha"), "ordinary Grove ecology became a second alpha")
	assert_eq(str(alpha.species), "burrowback")
	assert_eq(int(alpha.count), 1)
	assert_almost_eq(float(alpha.alpha.scale), 1.35)
	assert_eq(int(alpha.alpha.level_bonus), 4)

	var at := Vector2(float(ordinary.centre[0]), float(ordinary.centre[2]))
	var old_at := Vector2(-330.0, 5030.0)
	var species: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(SPECIES_PATH))
	var body_radius := float(species.species.burrowback.placeholder.radius)
	var envelope := float(ordinary.radius) + float(ordinary.wander_radius) \
		+ body_radius + CAMERA_ARM_M
	var route_distance := Geometry2D.get_closest_point_to_segment(at, ROUTE_A, ROUTE_B).distance_to(at)
	var old_route_distance := Geometry2D.get_closest_point_to_segment(old_at, ROUTE_A, ROUTE_B).distance_to(old_at)
	assert_true(route_distance > envelope,
		"ordinary spawn disc, fitted body, wander and production camera arm must clear the Grove route")
	assert_false(old_route_distance > envelope,
		"the former route-overlapping cluster centre must fail the same visibility bound")
	assert_true(at.distance_to(APPROACH) - float(ordinary.radius)
		- float(ordinary.wander_radius) - body_radius >= 20.0,
		"an ordinary Burrowback can still enter screen-filling range at the validated approach")
	assert_true(at.distance_to(GROVE_CENTRE) <= 35.0,
		"the ordinary fight stopped belonging to the Ironwood Grove ecology")
	var alpha_at := Vector2(float(alpha.centre[0]), float(alpha.centre[2]))
	assert_true(at.distance_to(alpha_at) >= 40.0,
		"ordinary Burrowbacks overlap the authored solitary Grove alpha")


func _spawn(source: Dictionary, order: int) -> Dictionary:
	for raw: Variant in source.get("spawns", []):
		if raw is Dictionary and int((raw as Dictionary).get("order", -1)) == order:
			return raw as Dictionary
	return {}


func _at(raw: Variant) -> Vector2:
	if not raw is Array or (raw as Array).size() < 2:
		return Vector2(INF, INF)
	return Vector2(float(raw[0]), float(raw[1]))
