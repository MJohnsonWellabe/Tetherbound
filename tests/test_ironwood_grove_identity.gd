extends "res://tests/test_case.gd"

const HARVEST_PATH := "res://data/config/bands/band4_upper_meadows_ironwood/harvest.json"
const VEGETATION_PATH := "res://data/config/bands/band4_upper_meadows_ironwood/vegetation.json"
const SPAWNS_PATH := "res://data/config/bands/band4_upper_meadows_ironwood/spawns.json"
const SPECIES_PATH := "res://data/creatures/species.json"
const CAPTURE_HARNESS := preload("res://tools/capture_ironwood_grove_identity.gd")
const ROUTE_A := Vector2(-300.0, 4990.0)
const ROUTE_B := Vector2(-420.0, 5140.0)
const APPROACH := Vector2(-321.0, 5025.0)
const GROVE_CENTRE := Vector2(-344.0, 5075.0)
const CAMERA_ARM_M := 5.2


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


func test_current_grove_has_a_dedicated_production_evidence_harness() -> void:
	assert_true(CAPTURE_HARNESS != null,
		"Ironwood Grove fell back to the stale pre-crown generic location strip")
	assert_true(CAPTURE_HARNESS.approach_distance_m() >= 50.0
		and CAPTURE_HARNESS.approach_distance_m() <= 60.0,
		"Ironwood arrival proof drifted outside the landmark's real-route 50-60m approach")


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
