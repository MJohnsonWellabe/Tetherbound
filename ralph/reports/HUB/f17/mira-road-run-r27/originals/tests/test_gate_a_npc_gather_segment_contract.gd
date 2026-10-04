extends "res://tests/test_case.gd"

## Regression guard for the Gate B Bram flake.  The continuous smoke is the
## behavioural proof; this small contract makes the precise harness bug cheap
## to catch: a pre-press winner snapshot must never be treated as an activation.

const SEGMENT_PATH := "res://tests/helpers/gate_a_npc_gather_segment.gd"
const SEGMENT := preload("res://tests/helpers/gate_a_npc_gather_segment.gd")
const NAVIGATOR := preload("res://tests/helpers/opening_geometry_navigator.gd")


func test_controller_activation_is_confirmed_by_the_live_arbiter_signal() -> void:
	var source := FileAccess.get_file_as_string(SEGMENT_PATH).replace("\r\n", "\n")
	assert_true(source.contains("_arbiter.connect(\"activated\", activation_handler)"),
		"the helper never observes which provider production actually activated")
	assert_true(source.contains("await _press_and_observe_activation(target)"),
		"the approach still has no post-press activation verdict")
	assert_true(source.contains("activation == ActivationVerdict.COMPETING:"),
		"the approach does not distinguish a competing activation from no activation")
	assert_true(source.contains("activated competing provider"),
		"a competing activation must fail immediately with the actual provider")


func test_activation_verdict_distinguishes_target_competitor_and_nothing() -> void:
	var target := Node.new()
	var competitor := Node.new()
	assert_eq(SEGMENT.activation_verdict(null, target), SEGMENT.ActivationVerdict.NONE)
	assert_eq(SEGMENT.activation_verdict(target, target), SEGMENT.ActivationVerdict.TARGET)
	assert_eq(SEGMENT.activation_verdict(competitor, target), SEGMENT.ActivationVerdict.COMPETING)
	target.free()
	competitor.free()


func test_pre_press_winner_snapshot_is_not_returned_as_success() -> void:
	var source := FileAccess.get_file_as_string(SEGMENT_PATH).replace("\r\n", "\n")
	var start := source.find("func _one_approach(")
	# Isolate the actual function by its next declaration, independent of
	# travel-comment wording or helpers subsequently added after the approach.
	var finish := source.find("\nfunc ", start + 1)
	assert_true(start >= 0 and finish > start, "could not isolate the approach helper")
	if start < 0 or finish <= start:
		return
	var approach := source.substr(start, finish - start)
	assert_false(approach.contains("await _tap_action(&\"interact\")\n\t\t\treturn true"),
		"a stale pre-press winner is still being reported as a successful activation")
	assert_true(approach.contains("_nav.reset()\n\t\t\tcontinue"),
		"a press that activated nothing should resume the same bounded physical approach")
	assert_true(approach.contains("_competing_activation])\n\t\t\t\treturn false"),
		"a competing activation must not enter the no-activation retry path")


func test_fatal_approach_failure_stops_at_the_outer_retry_boundary() -> void:
	var source := FileAccess.get_file_as_string(SEGMENT_PATH).replace("\r\n", "\n")
	var start := source.find("func _walk_to_and_activate(")
	var finish := source.find("\n\n## Frames spent held", start)
	assert_true(start >= 0 and finish > start, "could not isolate the outer activation retry helper")
	var retry := source.substr(start, finish - start)
	var fatal_guard := retry.find("if not _failures.is_empty():\n\t\t\treturn false")
	var retry_delay := retry.find("for _i in 30:")
	assert_true(fatal_guard >= 0,
		"a competing activation failure is not terminal at the outer retry boundary")
	assert_true(retry_delay > fatal_guard,
		"the retry delay still runs before the fatal competing-activation guard")


func test_local_wood_errand_leaves_the_actual_pond_road_before_the_distant_pond() -> void:
	var terrain: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/terrain_playground.json"))
	var pond: Array[Vector2] = []
	for route: Dictionary in (terrain.get("paths", {}) as Dictionary).get("routes", []):
		if str(route.get("label", "")) == "The Pond":
			for pair: Array in route.get("points", []):
				pond.append(Vector2(float(pair[0]), float(pair[1])))
	assert_eq(pond.size(), 8, "the current painted Pond road is the source of headings")
	var prefix: Array[Vector2] = NAVIGATOR._road_prefix_to_goal(pond, Vector2(-8.0, 8.0))
	assert_eq(prefix, [Vector2(20.0, 14.0), Vector2(20.0, -12.0), Vector2(-8.0, -12.0), Vector2(-12.5, 6.5)],
		"the wood errand follows the painted bends and exits beside the resource")
	assert_false(prefix.has(Vector2(-105.0, 115.0)), "a local errand must not first walk to the distant pond")


func test_road_prefix_keeps_authored_order_and_uses_the_first_nearest_exit() -> void:
	var road: Array[Vector2] = [Vector2(0.0, 0.0), Vector2(4.0, 0.0), Vector2(8.0, 0.0)]
	assert_eq(NAVIGATOR._road_prefix_to_goal(road, Vector2(2.0, 1.0)), [road[0]],
		"equally near road nodes choose the first exit without extending the errand")
	assert_eq(NAVIGATOR._road_prefix_to_goal(road, Vector2(9.0, 0.0)), road,
		"a goal at the distant end retains every authored bend")
	var empty: Array[Vector2] = []
	assert_eq(NAVIGATOR._road_prefix_to_goal(empty, Vector2.ZERO), empty,
		"an empty road supplies no synthetic waypoint")


func test_road_prefix_refuses_malformed_and_out_of_scope_inputs() -> void:
	var malformed: Array[Vector2] = [Vector2.ZERO, Vector2.INF]
	assert_eq(NAVIGATOR._road_prefix_to_goal(malformed, Vector2.ZERO), [], "nonfinite road input supplies no heading")
	var road: Array[Vector2] = [Vector2.ZERO, Vector2(10.0, 0.0)]
	assert_eq(NAVIGATOR._road_prefix_to_goal(road, Vector2.INF), [], "nonfinite goal supplies no heading")
	assert_eq(NAVIGATOR._road_prefix_to_goal(road, Vector2(191.0, 0.0)), [], "an exit beyond the unchanged 180m scope is refused")
	var broken: Array[Vector2] = [Vector2.ZERO, Vector2(181.0, 0.0)]
	assert_eq(NAVIGATOR._road_prefix_to_goal(broken, Vector2.ZERO), [], "an invalid distant edge cannot be hidden by clipping the prefix")
	var oversized: Array[Vector2] = []
	for index in 65:
		oversized.append(Vector2(float(index), 0.0))
	assert_eq(NAVIGATOR._road_prefix_to_goal(oversized, Vector2.ZERO), [], "the original64 road-input bound is retained")


func test_actual_stone_heading_accounts_for_the_concave_fence() -> void:
	var boundary := preload("res://scripts/world/village_boundary.gd")
	var outline := boundary.outline(boundary.load_config())
	var west_wood := Vector2(-8.0, 8.0)
	var east_wood := Vector2(36.0, -16.0)
	var east_stone := Vector2(47.0, -34.5)
	assert_true(Geometry2D.is_point_in_polygon(east_wood, outline), "the real wood goal is inside")
	assert_true(Geometry2D.is_point_in_polygon(east_stone, outline), "the real stone goal is inside")
	assert_eq(SEGMENT.stone_road_hint(east_wood, east_stone, outline, 1.55), SEGMENT.StoneRoadHint.MEADOW,
		"inside endpoints must not imply a direct route across the southeast fence notch")
	for stone: Vector2 in [Vector2(-18.0, 6.0), Vector2(22.0, -34.0), east_stone]:
		assert_eq(SEGMENT.stone_road_hint(west_wood, stone, outline, 1.55), SEGMENT.StoneRoadHint.DIRECT,
			"the current western wood site retains interior direct stone headings")
	for stone: Vector2 in [Vector2(-18.0, 6.0), Vector2(22.0, -34.0)]:
		assert_eq(SEGMENT.stone_road_hint(east_wood, stone, outline, 1.55), SEGMENT.StoneRoadHint.DIRECT,
			"nearby eastern wood does not force every stone errand through the meadow")


func test_stone_fence_hint_keeps_clearance_and_refuses_invalid_scope() -> void:
	var square := PackedVector2Array([Vector2.ZERO, Vector2(10.0, 0.0), Vector2(10.0, 10.0), Vector2(0.0, 10.0)])
	assert_eq(SEGMENT.stone_road_hint(Vector2(1.0, 2.0), Vector2(1.0, 8.0), square, 1.55), SEGMENT.StoneRoadHint.MEADOW,
		"a parallel interior heading inside the arrival clearance prefers the road")
	assert_eq(SEGMENT.stone_road_hint(Vector2(5.0, 2.0), Vector2(5.0, 8.0), square, 1.55), SEGMENT.StoneRoadHint.DIRECT)
	assert_eq(SEGMENT.stone_road_hint(Vector2.INF, Vector2.ONE, square, 1.55), SEGMENT.StoneRoadHint.INVALID)
	assert_eq(SEGMENT.stone_road_hint(Vector2.ONE, Vector2.INF, square, 1.55), SEGMENT.StoneRoadHint.INVALID)
	assert_eq(SEGMENT.stone_road_hint(Vector2(-1.0, 2.0), Vector2.ONE, square, 1.55), SEGMENT.StoneRoadHint.INVALID)
	assert_eq(SEGMENT.stone_road_hint(Vector2.ONE, Vector2.ONE, PackedVector2Array(), 1.55), SEGMENT.StoneRoadHint.INVALID)
	assert_eq(SEGMENT.stone_road_hint(Vector2.ONE, Vector2.ONE, square, INF), SEGMENT.StoneRoadHint.INVALID)
	assert_eq(SEGMENT.stone_road_hint(Vector2.ONE, Vector2.ONE, square, 1.66), SEGMENT.StoneRoadHint.INVALID)
	var too_long := PackedVector2Array([Vector2.ZERO, Vector2(400.0, 0.0), Vector2(400.0, 10.0), Vector2(0.0, 10.0)])
	assert_eq(SEGMENT.stone_road_hint(Vector2.ONE, Vector2(200.0, 1.0), too_long, 1.55), SEGMENT.StoneRoadHint.INVALID)
	var malformed := PackedVector2Array([Vector2.ZERO, Vector2.INF, Vector2.ONE])
	assert_eq(SEGMENT.stone_road_hint(Vector2.ONE, Vector2.ONE, malformed, 1.55), SEGMENT.StoneRoadHint.INVALID)
	var oversized := PackedVector2Array()
	for index in 65:
		oversized.append(Vector2(float(index), float(index % 2)))
	assert_eq(SEGMENT.stone_road_hint(Vector2.ONE, Vector2.ONE, oversized, 1.55), SEGMENT.StoneRoadHint.INVALID)


func test_ordinary_preview_uses_locomotion_speed_and_preserves_cached_momentum() -> void:
	assert_almost_eq(NAVIGATOR.ordinary_preview_reach(5.0, 8.6, 1.0, 5.0, 120.0, 1.0 / 60.0), 8.6 / 60.0, 0.000001,
		"the 120m/s safety ceiling must not create a 2m ordinary-step preview")
	assert_almost_eq(NAVIGATOR.ordinary_preview_reach(5.0, 8.6, 1.0, 12.0, 120.0, 1.0 / 60.0), 0.2, 0.000001)
	assert_almost_eq(NAVIGATOR.ordinary_preview_reach(5.0, 8.6, 0.8, 0.0, 120.0, 1.0 / 60.0), 6.88 / 60.0, 0.000001)
	assert_true(is_nan(NAVIGATOR.ordinary_preview_reach(5.0, 8.6, INF, 0.0, 120.0, 1.0 / 60.0)))
	assert_true(is_nan(NAVIGATOR.ordinary_preview_reach(5.0, 8.6, 1.0, -1.0, 120.0, 1.0 / 60.0)))
	assert_true(is_nan(NAVIGATOR.ordinary_preview_reach(5.0, 4.0, 1.0, 0.0, 120.0, 1.0 / 60.0)))


func test_prospective_tangent_does_not_push_into_the_unreported_opposite_wall() -> void:
	var future := NAVIGATOR.wall_heading(Vector3.BACK, Vector3.RIGHT, false)
	assert_eq(future, Vector3.BACK)
	assert_almost_eq(future.dot(Vector3.LEFT), 0.0, 0.000001,
		"Mira's future counter hint cannot shove the capsule into her east wall")
	var live := NAVIGATOR.wall_heading(Vector3.BACK, Vector3.RIGHT, true)
	assert_true(live.x > 0.0, "actual shallow wall contact retains its original outward relief")
	assert_almost_eq(live.length(), 1.0, 0.000001)


func test_road_slice_returns_in_original_reverse_order_and_refuses_broken_input() -> void:
	var road: Array[Vector2] = [Vector2.ZERO, Vector2(4, 0), Vector2(8, 0), Vector2(10, 0)]
	assert_eq(NAVIGATOR.road_slice(road, Vector2(9, 1), Vector2(1, 1)),
		[Vector2(9, 0), Vector2(8, 0), Vector2(4, 0), Vector2(1, 0)])
	assert_eq(NAVIGATOR.road_slice(road, Vector2(1, 1), Vector2(9, 1)),
		[Vector2(1, 0), Vector2(4, 0), Vector2(8, 0), Vector2(9, 0)])
	var malformed: Array[Vector2] = [Vector2.ZERO, Vector2.INF]
	assert_eq(NAVIGATOR.road_slice(malformed, Vector2.ZERO, Vector2.ONE), [])
	assert_eq(NAVIGATOR.road_slice(road, Vector2.INF, Vector2.ZERO), [])
	assert_eq(NAVIGATOR.road_slice(road, Vector2(0, 181), Vector2.ZERO), [])


func test_mira_return_uses_painted_bends_and_same_standoff_without_stepping_onto_lip() -> void:
	var terrain: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/terrain_playground.json"))
	var road: Array[Vector2] = []
	for route: Dictionary in terrain.paths.routes:
		if str(route.get("label", "")) == "Practice Meadow":
			for pair: Array in route.points:
				road.append(Vector2(float(pair[0]), float(pair[1])))
	var hint := SEGMENT.mira_approach_hint(Vector3(31.15487, -0.028295, -42.58252), Vector3(27, 0.85, 5),
		Vector3(27, 0.9, 7.9), Vector3(4, 0.1, 2), 0.4, 0.001, road)
	assert_eq(hint.size(), 8)
	assert_true(hint.has(Vector2(14.6, -31)), "return around the camp uses the original painted bend")
	assert_eq(hint[hint.size() - 2], Vector2(20, 6.3))
	assert_eq(hint.back(), Vector2(27, 6.65))
	assert_true(hint.back().distance_to(Vector2(27, 7.6)) < 1.0, "the original1m standoff threshold still decides arrival")
	assert_almost_eq(SEGMENT.DOOR_STANDOFF, 2.6, 0.000001)
	assert_almost_eq(SEGMENT.DOOR_STEP_IN, 2.2, 0.000001)
	assert_eq(SEGMENT.mira_approach_hint(Vector3.ZERO, Vector3(27, 0.85, 5), Vector3(27, 0.9, 7.9),
		Vector3(4, 0.1, 2), 0.2, 0.001, road), [], "the route cannot shrink the capsule")
	assert_eq(SEGMENT.mira_approach_hint(Vector3.ZERO, Vector3(27, 0.85, 5), Vector3(27, 0.9, 7.9),
		Vector3(4, 0.2, 2), 0.4, 0.001, road), [], "a higher lip cannot inherit this full-capsule corridor")
	assert_eq(SEGMENT.mira_approach_hint(Vector3.ZERO, Vector3(27, 0.85, 5), Vector3(27, 0.9, 7.9),
		Vector3(4, 0.1, 2), 0.4, 0.01, road), [], "the original skin remains mandatory")


func test_indoor_movement_resume_uses_the_existing_doorway_axis() -> void:
	assert_true(SEGMENT.doorway_resume_goal(Vector3(44, 0.85, 7), Vector3.BACK).is_equal_approx(Vector3(44, 0.85, 4.8)),
		"Bram's first resume heads along the central aisle rather than into the guest furniture")
	assert_true(SEGMENT.doorway_resume_goal(Vector3(27, 0.85, 5), Vector3.BACK).is_equal_approx(Vector3(27, 0.85, 2.8)),
		"Mira uses the same inward point as the original exit leg")
	assert_true(SEGMENT.doorway_resume_goal(Vector3(5, 1, 8), Vector3.LEFT).is_equal_approx(Vector3(7.2, 1, 8)))
	assert_false(SEGMENT.doorway_resume_goal(Vector3.INF, Vector3.BACK).is_finite())
	assert_false(SEGMENT.doorway_resume_goal(Vector3.ZERO, Vector3.ZERO).is_finite())
	assert_false(SEGMENT.doorway_resume_goal(Vector3.ZERO, Vector3.UP).is_finite())
	assert_false(SEGMENT.doorway_resume_goal(Vector3.ZERO, Vector3.BACK * 2.0).is_finite())
