extends "res://tests/test_case.gd"

const THRESHOLD := preload("res://scripts/world/trail_camp_roadside_threshold.gd")
const PROPS_PATH := "res://data/config/bands/band1_lower_meadows/props.json"
const VEGETATION_PATH := "res://data/config/bands/band1_lower_meadows/vegetation.json"
const SHARED_VEGETATION_PATH := "res://data/config/vegetation.json"
const FIRE := Vector2(344.0, 935.0)
const LOOP_SOUTH := Vector2(300.0, 880.0)
const LOOP_NORTH := Vector2(370.0, 950.0)
const CAMP_CLEARING := Vector2(344.0, 935.0)
const CAMP_CLEARING_RADIUS := 9.0
const ARRIVAL_LENS := Vector2(339.7, 919.7)
const ARRIVAL_LENS_RADIUS := 7.0


func test_roadside_threshold_is_installed_visible_source_art_without_collision() -> void:
	var threshold := THRESHOLD.new()
	threshold.call("build", Vector3.ZERO, 45.0)
	assert_true(threshold.get_node_or_null(^"RoadsidePostLeft") != null
		and threshold.get_node_or_null(^"RoadsidePostRight") != null
		and threshold.get_node_or_null(^"ThresholdBeam") != null
		and threshold.get_node_or_null(^"TrailCampBoard") != null,
		"Trail Camp lost its road-spanning threshold silhouette")
	assert_true(threshold.get_node_or_null(^"TrailCampLabelFront") != null
		and threshold.get_node_or_null(^"TrailCampLabelBack") != null,
		"Trail Camp threshold lost its explicit two-sided place label")
	assert_true(is_equal_approx((threshold.get_node(^"TrailCampLabelFront") as Label3D).rotation.y, PI)
		and is_zero_approx((threshold.get_node(^"TrailCampLabelBack") as Label3D).rotation.y),
		"Trail Camp label faces no longer read normally from both approaches")
	for side: String in ["LeftApproachLantern", "RightApproachLantern"]:
		assert_true(threshold.get_node_or_null(NodePath("%s/InstalledWallLantern" % side)) != null
			and threshold.get_node_or_null(NodePath("%s/VisibleWarmSource" % side)) != null,
			"Trail Camp threshold returned to a primitive/invisible lantern")
		var light := threshold.get_node(NodePath("%s/ApproachWarmPool" % side)) as OmniLight3D
		assert_true(light.omni_range <= 6.0 and light.light_energy >= 1.5
			and light.light_energy <= 1.8,
			"Trail Camp threshold light is no longer a bounded local pool")
	assert_eq(threshold.find_children("*", "CollisionShape3D", true, false).size(), 0,
		"presentation-only Trail Camp threshold introduced a route obstacle")
	threshold.free()


func test_threshold_flanks_the_route_and_stays_outside_functional_camp_circles() -> void:
	var parsed := JSON.parse_string(FileAccess.get_file_as_string(PROPS_PATH)) as Dictionary
	assert_true(not parsed.is_empty(), "Band 1 props did not parse")
	var camp: Dictionary = {}
	for raw: Variant in parsed.get("clusters", []):
		if raw is Dictionary and str((raw as Dictionary).get("name", "")) == "trail_camp":
			camp = raw
	assert_false(camp.is_empty(), "Trail Camp prop cluster is missing")
	if camp.is_empty():
		return
	var threshold := camp.get("roadside_threshold", {}) as Dictionary
	var raw_at := threshold.get("at", []) as Array
	assert_eq(raw_at.size(), 2, "Trail Camp roadside threshold has no authored x/z")
	if raw_at.size() < 2:
		return
	var at := Vector2(float(raw_at[0]), float(raw_at[1]))
	assert_true(_distance_to_segment(at, LOOP_SOUTH, LOOP_NORTH) <= 0.10,
		"Trail Camp threshold left the authored Oak Grove Ring road mouth")
	assert_true(2.65 - 1.8 >= 0.8,
		"Trail Camp threshold posts no longer flank the 3.6m travel ribbon")
	assert_true(at.distance_to(FIRE) >= 6.5,
		"roadside threshold collapsed into the fire/rest furniture composition")
	var rest := camp.get("rest", {}) as Dictionary
	var rest_raw := rest.get("at", []) as Array
	var rest_at := Vector2(float(rest_raw[0]), float(rest_raw[1]))
	assert_true(at.distance_to(rest_at) > float(rest.get("radius", 0.0)),
		"roadside threshold entered the Rest until morning trigger")
	var creature_bed := rest.get("creature_bed", {}) as Dictionary
	var bed_raw := creature_bed.get("at", []) as Array
	var bed_at := Vector2(float(bed_raw[0]), float(bed_raw[1]))
	assert_true(at.distance_to(bed_at) > 2.6,
		"roadside threshold entered the creature-bed interaction circle")
	var source := FileAccess.get_file_as_string("res://scripts/world/props.gd")
	assert_true(source.contains('get("roadside_threshold", {})')
		and source.contains("TRAIL_CAMP_ROADSIDE_THRESHOLD.new()"),
		"production props dispatcher no longer builds the roadside threshold")


func test_capture_uses_real_road_and_rejects_buried_eyes() -> void:
	var capture := FileAccess.get_file_as_string(
		"res://tools/capture_trail_camp_subject_identity.gd")
	for stand: Vector2 in [Vector2(326.0, 906.0), Vector2(333.0, 913.0),
			Vector2(340.0, 920.0)]:
		assert_true(_distance_to_segment(stand, LOOP_SOUTH, LOOP_NORTH) <= 0.05,
			"Trail Camp arrival proof left the authored Oak Grove Ring road")
	assert_true(capture.contains("func _surface(")
		and capture.contains("direct_space_state.intersect_ray(query)"),
		"Trail Camp capture returned to analytic-only camera grounding")
	assert_true(capture.contains("func _camera_clear(")
		and capture.contains("fixed camera eye intersects production geometry"),
		"Trail Camp capture no longer rejects a buried/occupied camera")
	assert_false(capture.contains('"camera_up": 4.4')
		or capture.contains('"eye": Vector2(324.16, 901.04)'),
		"Trail Camp proof returned to the rejected elevated shoulder experiment")
	assert_true(capture.contains('"eye": Vector2(326.0, 906.0)')
		and capture.contains('"camera_up": 2.15'),
		"Trail Camp proof no longer uses an ordinary authored-road eye")
	assert_false(capture.contains("func _sightline_clear("),
		"Trail Camp acceptance returned to a single physics ray through collisionless foliage")


func test_arrival_lens_is_minimal_road_centred_and_only_shallowly_joins_camp() -> void:
	var parsed := JSON.parse_string(FileAccess.get_file_as_string(VEGETATION_PATH)) as Dictionary
	assert_true(not parsed.is_empty(), "Band 1 vegetation did not parse")
	var lens: Dictionary = {}
	var footprint_has_lens := false
	for raw: Variant in parsed.get("clearings", []):
		if raw is Dictionary and int((raw as Dictionary).get("order", -1)) == 1914:
			lens = raw
	for raw: Variant in parsed.get("footprints", []):
		if raw is Dictionary and int((raw as Dictionary).get("order", -1)) == 1914:
			footprint_has_lens = true
	assert_false(lens.is_empty(), "Trail Camp arrival vegetation lens is missing")
	assert_false(footprint_has_lens, "Trail Camp lens became a ground-cover-stripping footprint")
	if lens.is_empty():
		return
	var at := Vector2(float(lens.get("x", NAN)), float(lens.get("z", NAN)))
	var radius := float(lens.get("radius", NAN))
	assert_true(at.is_equal_approx(ARRIVAL_LENS), "Trail Camp arrival lens footprint drifted")
	assert_true(is_equal_approx(radius, ARRIVAL_LENS_RADIUS) and radius <= 7.0,
		"Trail Camp arrival lens widened beyond its measured minimum")
	assert_true(_distance_to_segment(at, LOOP_SOUTH, LOOP_NORTH) <= 0.01,
		"Trail Camp arrival lens left the exact road-to-threshold axis")
	var overlap := radius + CAMP_CLEARING_RADIUS - at.distance_to(CAMP_CLEARING)
	assert_true(overlap > 0.0 and overlap <= 0.25,
		"Trail Camp arrival lens no longer shallowly joins the retained camp clearing")


func test_arrival_lens_preserves_ground_cover_layers() -> void:
	var parsed := JSON.parse_string(FileAccess.get_file_as_string(SHARED_VEGETATION_PATH)) as Dictionary
	assert_true(not parsed.is_empty(), "Shared vegetation policy did not parse")
	var layers := parsed.get("layers", {}) as Dictionary
	for layer_name: String in ["grass", "drygrass", "flowers", "path_stones", "groundmat"]:
		var layer := layers.get(layer_name, {}) as Dictionary
		assert_false(layer.is_empty(), "%s vegetation layer is missing" % layer_name)
		assert_true(layer.get("cleared_by_clearings", true) == false,
			"Trail Camp clearing would strip preserved %s ground cover" % layer_name)


func _distance_to_segment(point: Vector2, start: Vector2, finish: Vector2) -> float:
	var along := finish - start
	var t := clampf((point - start).dot(along) / along.length_squared(), 0.0, 1.0)
	return point.distance_to(start + along * t)
