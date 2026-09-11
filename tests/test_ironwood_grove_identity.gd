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
	assert_true(lens_radius >= 4.0 and lens_radius <= 4.5,
		"the Ironwood arrival lens is no longer the measured three-tree correction")
	for blocked_tree: Vector2 in [
		Vector2(-319.19, 5028.28),
		Vector2(-316.14, 5029.68),
		Vector2(-316.30, 5022.94),
	]:
		assert_true(blocked_tree.distance_to(lens_centre) < lens_radius,
			"a production-measured foreground trunk remains inside the Grove arrival camera wedge")
	for framing_tree: Vector2 in [Vector2(-311.18, 5027.80), Vector2(-329.06, 5016.29)]:
		assert_true(framing_tree.distance_to(lens_centre) > lens_radius,
			"the scoped Ironwood sightline correction stripped a lateral framing tree")
	for harvest_point: Vector2 in positions:
		assert_true(harvest_point.distance_to(lens_centre) > lens_radius,
			"the arrival lens overlaps an authored ironwood harvest seat")


func test_current_grove_has_a_dedicated_production_evidence_harness() -> void:
	assert_true(CAPTURE_HARNESS != null,
		"Ironwood Grove fell back to the stale pre-crown generic location strip")
	assert_true(CAPTURE_HARNESS.approach_distance_m() >= 50.0
		and CAPTURE_HARNESS.approach_distance_m() <= 60.0,
		"Ironwood arrival proof drifted outside the landmark's real-route 50-60m approach")


func test_r3_presentation_keeps_the_five_harvest_seats_and_makes_age_visible_at_the_roots() -> void:
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
	assert_eq(footings.size(), 5, "R3 lost an age-specific ironwood root footing")
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
		assert_eq(int(node.get("amount", 0)), 3, "R3 changed an ironwood yield")
		var at := _at(footing.get("at", []))
		assert_true(at.is_equal_approx(_at(node.get("at", []))),
			"an R3 root footing drifted away from its functional harvest seat")
		radii.append(float(footing.get("root_radius_m", 0.0)))
	assert_true(radii.min() <= 1.7 and radii.max() >= 5.0,
		"the young-to-elder story is not legible in the root footprint")
	assert_true(float(footings[0].root_radius_m) > float(footings[2].root_radius_m)
		and float(footings[2].root_radius_m) > float(footings[4].root_radius_m),
		"root hierarchy no longer tracks elder, mature, and young ironwoods")


func test_r3_has_a_real_route_crown_and_authored_working_glade_without_new_collision() -> void:
	var config := JSON.parse_string(FileAccess.get_file_as_string(PRESENTATION_PATH)) as Dictionary
	assert_true(not config.is_empty(), "Ironwood presentation config did not parse")
	if config.is_empty():
		return
	var threshold := config.get("route_threshold", {}) as Dictionary
	var threshold_at := _at(threshold.get("centre", []))
	assert_true(threshold_at.distance_to(APPROACH) <= 26.0,
		"Ironwood crown threshold is no longer visible from the real route arrival")
	assert_true(threshold_at.distance_to(GROVE_CENTRE) >= 24.0
		and threshold_at.distance_to(GROVE_CENTRE) <= 34.0,
		"Ironwood crown threshold collapsed into the grove or left its approach")
	assert_true(float(threshold.get("height_m", 0.0)) >= 5.8
		and float(threshold.get("half_width_m", 0.0)) >= 3.8,
		"Ironwood crown threshold lost its road-scale silhouette")
	var elder := config.get("elder_crown", {}) as Dictionary
	assert_true(float(elder.get("height_m", 0.0)) >= 7.0
		and float(elder.get("width_m", 0.0)) >= 6.5,
		"the paired elders lost their shared crown focal")
	var glade := config.get("crafting_glade", {}) as Dictionary
	for key: String in ["workbench", "anvil", "tool_rack", "timber", "stump"]:
		assert_true(glade.has(key), "worked glade lost its %s" % key)
	assert_true((glade.get("timber", []) as Array).size() >= 3,
		"worked glade no longer shows an ironwood timber stack")
	var source := FileAccess.get_file_as_string("res://scripts/world/playground_world.gd")
	assert_true(source.contains("IRONWOOD_GROVE_PRESENTATION.new()")
		and source.contains('ironwood_grove.name = "IronwoodGrovePresentation"')
		and source.contains("if not simulation_only:"),
		"production Meadows no longer mounts the R3 grove identity layer")
	var world := FlatWorld.new()
	var presentation := PRESENTATION.new()
	world.add_child(presentation)
	assert_true(bool(presentation.call("build", world)),
		"R3 Ironwood presentation did not build its complete authored composition")
	var stats := presentation.call("stats") as Dictionary
	assert_true(int(stats.get("root_segments", 0)) >= 27,
		"R3 did not build the five-tree root hierarchy")
	assert_true(int(stats.get("installed_props", 0)) >= 8,
		"R3 worked glade did not build its installed tools and timber")
	assert_true(int(stats.get("path_markers", 0)) >= 6,
		"R3 worked glade lost its path threshold")
	assert_eq(int(stats.get("collision_shapes", -1)), 0,
		"collisionless grove presentation introduced a route/harvest obstacle")
	assert_true(presentation.get_node_or_null(^"RoadVisibleCrownThreshold") != null
		and presentation.get_node_or_null(^"PairedElderCrown") != null
		and presentation.get_node_or_null(^"WorkedIronwoodGlade/InstalledToolRack/InstalledAxe") != null
		and presentation.get_node_or_null(^"WorkedIronwoodGlade/InstalledToolRack/InstalledPickaxe") != null,
		"R3 lost its crown focal or installed craft tools")
	world.remove_child(presentation)
	presentation.free()
	world.free()


func test_r3_night_fill_is_restrained_and_local() -> void:
	var config := JSON.parse_string(FileAccess.get_file_as_string(PRESENTATION_PATH)) as Dictionary
	var lights := config.get("night_lights", []) as Array
	assert_eq(lights.size(), 3, "Ironwood Grove should have exactly three local wayfinding pools")
	for raw: Variant in lights:
		var light := raw as Dictionary
		assert_true(float(light.get("range_m", 0.0)) <= 8.0,
			"Ironwood night fill expanded beyond the named location")
		assert_true(float(light.get("energy", 0.0)) <= 1.25,
			"Ironwood night fill became a floodlight")
		assert_true(_at(light.get("at", [])).distance_to(GROVE_CENTRE) <= 34.0,
			"Ironwood night fill escaped the route/grove/glade composition")


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
