extends "res://tests/test_case.gd"

## Capture evidence must recognise the tiled GrassField representation shipped
## by the game.  The parent MultiMesh is intentionally empty when cull tiles
## own the instances; treating that as a bare field invalidates every ground
## and water frame even though the rendered grass is present.

const CAPTURE_CHECK := preload("res://tools/capture_check.gd")


class FakeGrassField extends MultiMeshInstance3D:
	var _camera: Camera3D = null
	var _ring_instances: int = 0


func _field(ring_instances: int, legacy_instances: int) -> FakeGrassField:
	var field := FakeGrassField.new()
	field._ring_instances = ring_instances
	if legacy_instances > 0:
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.instance_count = legacy_instances
		field.multimesh = mm
	return field


func test_tiled_grass_counts_as_live_even_when_the_parent_multimesh_is_empty() -> void:
	var field := _field(64, 0)
	assert_true(CAPTURE_CHECK._field_has_instances(field),
		"the shipped tiled field owns instances in child tiles, not its parent MultiMesh")
	field.free()


func test_the_legacy_parent_multimesh_still_counts_as_live() -> void:
	var field := _field(0, 1)
	assert_true(CAPTURE_CHECK._field_has_instances(field),
		"older capture fixtures still expose their instances on the parent MultiMesh")
	field.free()


func test_a_field_with_no_tiled_or_legacy_instances_is_rejected() -> void:
	var field := _field(0, 0)
	assert_false(CAPTURE_CHECK._field_has_instances(field),
		"a genuinely empty GrassField must not validate a bare-ground capture")
	field.free()


## --- creature present and readable (W01-ROUTE-STRIP, 2026-09-04) ------------
##
## Pure-projection checks: the suite has no main loop, so nothing here can (or
## should) touch a Camera3D. `_camera()` is a 70-degree camera at the origin
## looking down -Z, drawing into a 1280x720 frame -- the route strip's own eye.

const FOV := 70.0
const SIZE := Vector2(1280.0, 720.0)


func _camera() -> Transform3D:
	return Transform3D(Basis.IDENTITY, Vector3.ZERO)


## A trainer-sized box (0.8 wide, 1.8 tall) standing on the ground `distance`
## metres straight ahead of the camera, whose eye is 1.0 m above that ground.
func _standing_box(distance: float, side := 0.0) -> AABB:
	return AABB(Vector3(side - 0.4, -1.0, -distance - 0.4), Vector3(0.8, 1.8, 0.8))


func test_a_point_dead_ahead_projects_to_the_frame_centre() -> void:
	var screen: Variant = CAPTURE_CHECK.project_point(_camera(), FOV, SIZE, Vector3(0.0, 0.0, -10.0))
	assert_true(screen is Vector2, "a point in front of the camera projects")
	assert_almost_eq((screen as Vector2).x, SIZE.x * 0.5, 0.01)
	assert_almost_eq((screen as Vector2).y, SIZE.y * 0.5, 0.01)


func test_a_point_to_the_right_and_above_lands_right_of_and_above_centre() -> void:
	var screen: Vector2 = CAPTURE_CHECK.project_point(_camera(), FOV, SIZE, Vector3(2.0, 1.0, -10.0))
	assert_true(screen.x > SIZE.x * 0.5, "+X is screen-right")
	assert_true(screen.y < SIZE.y * 0.5, "+Y is screen-up, i.e. a smaller pixel row")
	# The same arithmetic Camera3D.unproject_position uses: at 10 m a 70-degree
	# vertical FOV sees 2*10*tan(35) = 14.0 m of height, so 1 m up is 1/14 of
	# 720 px above centre.
	var expected_dy := 1.0 / (2.0 * 10.0 * tan(deg_to_rad(FOV * 0.5))) * SIZE.y
	assert_almost_eq(SIZE.y * 0.5 - screen.y, expected_dy, 0.5)


func test_a_point_behind_the_camera_does_not_project() -> void:
	var screen: Variant = CAPTURE_CHECK.project_point(_camera(), FOV, SIZE, Vector3(0.0, 0.0, 5.0))
	assert_true(screen == null, "behind the near plane is not a screen position")


func test_an_empty_frame_is_refused() -> void:
	var problems: Array[String] = CAPTURE_CHECK.readable_problems(_camera(), FOV, SIZE, [])
	assert_eq(problems.size(), 1, "a frame that names no subject is the frame this check refuses")
	assert_true(problems[0].contains("nobody in it"), problems[0] if not problems.is_empty() else "")


func test_a_subject_behind_the_camera_is_not_readable() -> void:
	var problems: Array[String] = CAPTURE_CHECK.readable_problems(_camera(), FOV, SIZE, [
		{"name": "trainer", "aabb": AABB(Vector3(-0.4, -1.0, 3.0), Vector3(0.8, 1.8, 0.8))},
	])
	assert_eq(problems.size(), 1)
	assert_true(problems[0].contains("behind the capture camera"), problems[0])


func test_a_subject_too_far_away_is_too_small_to_read() -> void:
	# 1.8 m at 60 m through a 70-degree lens is ~2% of the frame's height.
	var problems: Array[String] = CAPTURE_CHECK.readable_problems(_camera(), FOV, SIZE, [
		{"name": "bramblebun", "aabb": _standing_box(60.0)},
	])
	assert_eq(problems.size(), 1)
	assert_true(problems[0].contains("of the frame's height"), problems[0])


func test_a_subject_technically_on_screen_but_mostly_cropped_is_refused() -> void:
	# At 6 m the half-frame width is 6*tan(35)*(1280/720) = 7.47 m. A box whose
	# centre sits at 7.5 m to the side has about half of itself past the edge:
	# its AABB still INTERSECTS the frame (the old `_subject_problems` passes
	# it), which is exactly the "AABB technically on screen" pass this check
	# exists to reject.
	var box := _standing_box(6.0, 7.5)
	var projected: Dictionary = CAPTURE_CHECK.projected_rect(_camera(), FOV, SIZE, box)
	assert_false(bool(projected["behind"]))
	assert_true(Rect2(Vector2.ZERO, SIZE).intersects(projected["rect"]),
		"the box must still touch the frame, or this test proves nothing about cropping")
	var problems: Array[String] = CAPTURE_CHECK.readable_problems(_camera(), FOV, SIZE, [
		{"name": "trainer", "aabb": box},
	])
	assert_eq(problems.size(), 1, str(problems))
	assert_true(problems[0].contains("cropped by the frame edge"), problems[0])


func test_trainer_and_companion_side_by_side_at_six_metres_are_readable() -> void:
	var problems: Array[String] = CAPTURE_CHECK.readable_problems(_camera(), FOV, SIZE, [
		{"name": "trainer", "aabb": _standing_box(6.0, -1.0)},
		{"name": "terrapup", "aabb": _standing_box(6.0, 1.0)},
	])
	assert_eq(problems.size(), 0, str(problems))


func test_one_unreadable_subject_fails_the_whole_frame() -> void:
	var problems: Array[String] = CAPTURE_CHECK.readable_problems(_camera(), FOV, SIZE, [
		{"name": "trainer", "aabb": _standing_box(6.0, -1.0)},
		{"name": "bramblebun", "aabb": _standing_box(70.0, 1.0)},
	])
	assert_eq(problems.size(), 1, str(problems))
	assert_true(problems[0].begins_with("'bramblebun'"), problems[0])


func test_fit_distance_backs_off_until_all_three_subjects_are_inside_the_safe_area() -> void:
	# Three boxes on the ground around a focus point 20 m out: a trainer 4 m
	# to one side, and two creatures 3 m apart along the camera's axis.
	var focus := Vector3(0.0, 0.0, -20.0)
	var subjects := [
		{"name": "trainer", "aabb": AABB(focus + Vector3(-4.4, 0.0, -0.4), Vector3(0.8, 1.8, 0.8))},
		{"name": "ally", "aabb": AABB(focus + Vector3(-0.6, 0.0, 1.0), Vector3(1.2, 1.4, 1.2))},
		{"name": "wild", "aabb": AABB(focus + Vector3(-0.6, 0.0, -2.0), Vector3(1.2, 1.4, 1.2))},
	]
	var bearing := Vector3(0.0, 0.0, 1.0)
	var d: float = CAPTURE_CHECK.fit_distance(focus, bearing, 1.6, 0.9, FOV, SIZE, subjects)
	assert_true(d > 0.0, "some distance under 30 m fits three bodies within 5 m of each other")
	# The solved distance is the SMALLEST that fits: a quarter metre closer
	# must push at least one box out of the safe area.
	var safe := Rect2(SIZE * 0.06, SIZE * 0.88)
	var closer: Transform3D = CAPTURE_CHECK.camera_transform_at(focus, bearing, d - 0.25, 1.6, 0.9)
	var all_in_closer := true
	var cam: Transform3D = CAPTURE_CHECK.camera_transform_at(focus, bearing, d, 1.6, 0.9)
	for subject: Dictionary in subjects:
		var at_d: Dictionary = CAPTURE_CHECK.projected_rect(cam, FOV, SIZE, subject["aabb"])
		assert_true(safe.encloses(at_d["rect"]), "%s fits at the solved distance" % subject["name"])
		var at_closer: Dictionary = CAPTURE_CHECK.projected_rect(closer, FOV, SIZE, subject["aabb"])
		if bool(at_closer["behind"]) or not safe.encloses(at_closer["rect"]):
			all_in_closer = false
	assert_false(all_in_closer, "a quarter metre closer no longer fits everything -- the solve is minimal")
	# And the trainer, the subject a two-creature solve forgets, is the one
	# that dictates it: solving for the creatures alone lands closer.
	var creatures_only: float = CAPTURE_CHECK.fit_distance(focus, bearing, 1.6, 0.9, FOV, SIZE,
		[subjects[1], subjects[2]])
	assert_true(creatures_only < d, "the trainer's off-axis box is what pushes the camera back")


func test_fit_distance_reports_no_fit_when_nothing_fits() -> void:
	var focus := Vector3(0.0, 0.0, -20.0)
	var subjects := [{"name": "far", "aabb": AABB(focus + Vector3(200.0, 0.0, 0.0), Vector3.ONE)}]
	var d: float = CAPTURE_CHECK.fit_distance(focus, Vector3(0.0, 0.0, 1.0), 1.6, 0.9, FOV, SIZE, subjects,
		0.06, 3.0, 10.0)
	assert_eq(d, -1.0)


func test_a_subject_hidden_inside_another_subjects_silhouette_is_refused() -> void:
	# A trainer 10 m out, dead centre, and a looming companion 5 m out whose
	# box covers the trainer's entirely: both are "on screen", both are big
	# enough, and the trainer cannot be seen. W01 run 2's fight frame.
	var problems: Array[String] = CAPTURE_CHECK.readable_problems(_camera(), FOV, SIZE, [
		{"name": "trainer", "aabb": _standing_box(10.0)},
		{"name": "companion", "aabb": AABB(Vector3(-1.2, -1.0, -6.2), Vector3(2.4, 2.4, 2.4))},
	])
	assert_eq(problems.size(), 1, str(problems))
	assert_true(problems[0].contains("overlap on screen"), problems[0])


func test_two_subjects_side_by_side_do_not_count_as_overlapping() -> void:
	var problems: Array[String] = CAPTURE_CHECK.readable_problems(_camera(), FOV, SIZE, [
		{"name": "trainer", "aabb": _standing_box(6.0, -1.2)},
		{"name": "companion", "aabb": AABB(Vector3(0.2, -1.0, -7.2), Vector3(2.4, 2.4, 2.4))},
	])
	assert_eq(problems.size(), 0, str(problems))


func test_a_subject_that_fills_the_frame_is_a_close_up_not_a_scene() -> void:
	# A 2.8 m body four metres out is ~56% of the frame's height and still
	# wholly inside the frame, so only the cap can refuse it.
	var box := AABB(Vector3(-0.6, -1.0, -4.4), Vector3(1.2, 2.8, 0.8))
	var problems: Array[String] = CAPTURE_CHECK.readable_problems(_camera(), FOV, SIZE,
		[{"name": "companion", "aabb": box}], {"max_height_frac": 0.5})
	assert_eq(problems.size(), 1, str(problems))
	assert_true(problems[0].contains("close-up"), problems[0])
	# Without the cap the same frame is accepted: the cap is opt-in.
	assert_eq(CAPTURE_CHECK.readable_problems(_camera(), FOV, SIZE, [{"name": "companion", "aabb": box}]).size(), 0)


func test_fit_distance_backs_off_further_when_a_height_cap_is_given() -> void:
	var focus := Vector3(0.0, 0.0, -20.0)
	var subjects := [
		{"name": "trainer", "aabb": AABB(focus + Vector3(-4.4, 0.0, -0.4), Vector3(0.8, 1.8, 0.8))},
		{"name": "ally", "aabb": AABB(focus + Vector3(-1.2, 0.0, 1.0), Vector3(2.4, 2.4, 2.4))},
	]
	var bearing := Vector3(0.0, 0.0, 1.0)
	var plain: float = CAPTURE_CHECK.fit_distance(focus, bearing, 1.6, 0.9, FOV, SIZE, subjects)
	var capped: float = CAPTURE_CHECK.fit_distance(focus, bearing, 1.6, 0.9, FOV, SIZE, subjects,
		0.06, 3.0, 30.0, 0.25, 0.4)
	assert_true(plain > 0.0 and capped > 0.0, "both solves find a distance")
	assert_true(capped > plain, "the cap pushes the eye further out than the bare fit (%.2f vs %.2f)" % [capped, plain])
	var cam: Transform3D = CAPTURE_CHECK.camera_transform_at(focus, bearing, capped, 1.6, 0.9)
	var ally: Dictionary = CAPTURE_CHECK.projected_rect(cam, FOV, SIZE, subjects[1]["aabb"])
	assert_true((ally["rect"] as Rect2).size.y <= SIZE.y * 0.4 + 0.5, "at the capped distance the ally is under the cap")


func test_fit_distance_refuses_a_solve_that_leaves_the_smallest_subject_a_smudge() -> void:
	# A looming companion and a low, small opponent beside it. Any distance
	# that keeps the companion under half the frame leaves the opponent under
	# a fifth of it, so there is no honest framing from this bearing.
	var focus := Vector3(0.0, 0.0, -20.0)
	var subjects := [
		{"name": "ally", "aabb": AABB(focus + Vector3(-1.2, 0.0, 0.0), Vector3(2.4, 2.6, 2.4))},
		{"name": "opponent", "aabb": AABB(focus + Vector3(1.4, 0.0, 0.0), Vector3(1.0, 0.7, 1.0))},
	]
	var bearing := Vector3(0.0, 0.0, 1.0)
	var without: float = CAPTURE_CHECK.fit_distance(focus, bearing, 1.6, 0.9, FOV, SIZE, subjects,
		0.06, 3.0, 30.0, 0.25, 0.5)
	assert_true(without > 0.0, "with only a maximum, some distance satisfies the solve")
	var cam: Transform3D = CAPTURE_CHECK.camera_transform_at(focus, bearing, without, 1.6, 0.9)
	var small: Dictionary = CAPTURE_CHECK.projected_rect(cam, FOV, SIZE, subjects[1]["aabb"])
	assert_true((small["rect"] as Rect2).size.y < SIZE.y * 0.18,
		"and that distance is exactly the one that leaves the opponent a smudge")
	var with_floor: float = CAPTURE_CHECK.fit_distance(focus, bearing, 1.6, 0.9, FOV, SIZE, subjects,
		0.06, 3.0, 30.0, 0.25, 0.5, 0.18)
	assert_eq(with_floor, -1.0, "with both bounds this bearing has no honest framing and says so")


func test_fit_distance_with_both_bounds_still_solves_a_fair_matchup() -> void:
	var focus := Vector3(0.0, 0.0, -20.0)
	var subjects := [
		{"name": "ally", "aabb": AABB(focus + Vector3(-1.6, 0.0, 0.0), Vector3(1.6, 1.6, 1.6))},
		{"name": "opponent", "aabb": AABB(focus + Vector3(0.6, 0.0, 0.0), Vector3(1.4, 1.4, 1.4))},
	]
	var d: float = CAPTURE_CHECK.fit_distance(focus, Vector3(0.0, 0.0, 1.0), 1.6, 0.9, FOV, SIZE, subjects,
		0.06, 3.0, 30.0, 0.25, 0.5, 0.18)
	assert_true(d > 0.0, "two comparable fighters are framable under both bounds")
	var cam: Transform3D = CAPTURE_CHECK.camera_transform_at(focus, Vector3(0.0, 0.0, 1.0), d, 1.6, 0.9)
	for subject: Dictionary in subjects:
		var r: Rect2 = CAPTURE_CHECK.projected_rect(cam, FOV, SIZE, subject["aabb"])["rect"]
		assert_between(r.size.y / SIZE.y, 0.18, 0.5, "%s sits between the two bounds" % subject["name"])
