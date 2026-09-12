extends "res://tests/test_case.gd"

## Static contract for the one-boot production receipt. Visual correctness is
## decided by the emitted day/night frames, not by this source-level test.

const CAPTURE := preload("res://tools/capture_meadows_0912_wayfinding_and_pulls.gd")
const TERRAIN_PATH := "res://data/config/terrain_playground.json"
const OBJECTIVES_PATH := "res://data/progression/objectives.json"


func _read(path: String) -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	assert_true(parsed is Dictionary, "%s is not a JSON object" % path)
	return parsed as Dictionary if parsed is Dictionary else {}


func _road_points() -> Array[Vector2]:
	var out: Array[Vector2] = []
	var trail := _read(TERRAIN_PATH).get("trail", {}) as Dictionary
	for raw: Variant in (trail.get("bands", []) as Array):
		var band := raw as Dictionary
		if str(band.get("id", "")) != "band1_lower_meadows":
			continue
		for point_raw: Variant in (band.get("points", []) as Array):
			var point := point_raw as Array
			out.append(Vector2(float(point[0]), float(point[1])))
	return out


func _distance_to_road(point: Vector2) -> float:
	var road := _road_points()
	var nearest := INF
	for index in range(road.size() - 1):
		var a := road[index]
		var ab := road[index + 1] - a
		var along := clampf((point - a).dot(ab) / ab.length_squared(), 0.0, 1.0)
		nearest = minf(nearest, point.distance_to(a + ab * along))
	return nearest


func _objective_position(id: String) -> Vector2:
	for raw: Variant in (_read(OBJECTIVES_PATH).get("main", []) as Array):
		var entry := raw as Dictionary
		if str(entry.get("id", "")) != id:
			continue
		var position := (entry.get("beacon", {}) as Dictionary).get("position", []) as Array
		return Vector2(float(position[0]), float(position[1]))
	return Vector2(INF, INF)


func test_capture_requires_a_fresh_explicit_project_output() -> void:
	assert_eq(CAPTURE.requested_output(["--output=res://shots/0912-R1"]),
		"res://shots/0912-R1")
	assert_eq(CAPTURE.requested_output([]), "")
	assert_true(CAPTURE.valid_output_request("res://shots/0912-R1"))
	for invalid: String in ["", "res://", "user://shots", "C:/shots", "res://../shots", "res:\\shots"]:
		assert_false(CAPTURE.valid_output_request(invalid), "unsafe output passed: %s" % invalid)
	var source := FileAccess.get_file_as_string(
		"res://tools/capture_meadows_0912_wayfinding_and_pulls.gd")
	assert_true(source.contains("DirAccess.dir_exists_absolute"),
		"the capture no longer refuses an existing evidence directory")
	assert_true(source.contains("FileAccess.file_exists(path)"),
		"individual evidence frames can be overwritten")


func test_one_boot_plan_covers_both_features_at_day_and_night() -> void:
	var plan := CAPTURE.capture_plan()
	assert_eq(plan.size(), 6)
	var kinds := {}
	var orders := {}
	for view: Dictionary in plan:
		kinds[str(view.kind)] = int(kinds.get(str(view.kind), 0)) + 1
		for order_raw: Variant in (view.orders as Array):
			var order := int(order_raw)
			orders[order] = true
	assert_eq(int(kinds.get("objective", 0)), 2)
	assert_eq(int(kinds.get("wayfarer_signal", 0)), 2)
	assert_eq(int(kinds.get("south_trail_creatures", 0)), 2)
	for order: int in [1913, 1914, 1915]:
		assert_true(orders.has(order), "capture plan omits authored order %d" % order)
	var source := FileAccess.get_file_as_string(
		"res://tools/capture_meadows_0912_wayfinding_and_pulls.gd")
	assert_eq(source.count("var packed := load(SCENE)"), 1,
		"the combined evidence tool must boot the production world exactly once")
	assert_true(source.contains('const TIMES: Array[String] = ["day", "night"]'))
	assert_true(source.contains('"expected_frame_count": VIEWS.size() * TIMES.size()'))


func test_every_claimed_road_view_is_seated_on_the_authored_south_trail() -> void:
	var checked := 0
	for view: Dictionary in CAPTURE.capture_plan():
		if str(view.seat) != "road":
			continue
		checked += 1
		assert_true(_distance_to_road(view.stand as Vector2) <= 0.1,
			"%s is not actually on the authored road" % str(view.id))
	assert_eq(checked, 5)


func test_objective_views_use_the_real_south_bridge_destination_at_two_scales() -> void:
	var destination := _objective_position("head_to_south_bridge")
	assert_eq(destination, Vector2(14.0, 1314.0))
	var objective_views: Array[Dictionary] = []
	for view: Dictionary in CAPTURE.capture_plan():
		if str(view.kind) == "objective":
			objective_views.append(view)
	assert_eq(objective_views.size(), 2)
	assert_eq(objective_views[0].target as Vector2, destination)
	assert_eq(objective_views[1].target as Vector2, destination)
	assert_true((objective_views[0].stand as Vector2).distance_to(destination) >= 450.0,
		"road approach no longer proves distance readability")
	assert_true((objective_views[1].stand as Vector2).distance_to(destination) <= 90.0,
		"near-destination view is no longer near the beacon base")


func test_harness_uses_authored_subjects_and_writes_a_complete_manifest() -> void:
	var source := FileAccess.get_file_as_string(
		"res://tools/capture_meadows_0912_wayfinding_and_pulls.gd")
	for required: String in ["WayfarerSignalFire", "BandPickup_b1_candy_wayfarer_signal",
			"BandPickup_b1_potion_wayfarer_signal", "wild_creatures", "active_objective_id",
			"dismiss_active_creature", "companion_dismissed_through_production_path",
			"CAPTURE_CHECK.readable_problems_for_camera", "no readable %s",
			'"planned_frames"', '"captured_frame_count"', '"capture_finished_utc"',
			'"complete"', '"failures"']:
		assert_true(source.contains(required), "capture/manifest omits '%s'" % required)
	assert_false(source.contains("spawn_wild"),
		"production receipt must not inject display-only creatures")


func test_signal_views_use_an_ordinary_over_shoulder_seat() -> void:
	var checked := 0
	for view: Dictionary in CAPTURE.capture_plan():
		if str(view.kind) != "wayfarer_signal":
			continue
		checked += 1
		assert_between(absf(float(view.get("side", 0.0))), 1.5, 2.2,
			"%s can put the player directly over the signal/reward subject" % str(view.id))
	assert_eq(checked, 2)
	var source := FileAccess.get_file_as_string(
		"res://tools/capture_meadows_0912_wayfinding_and_pulls.gd")
	assert_true(source.contains("_terrain.call(\"set_camera\", _camera)"),
		"Terrain3D must stream around the actual evidence camera")
