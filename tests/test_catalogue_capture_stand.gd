extends "res://tests/test_case.gd"

const CAPTURE := preload("res://tools/phase2_capture_locations.gd")


func test_respawn_and_stale_camera_are_rejected_instead_of_mislabeled() -> void:
	var stand := Vector2(210.0, 2350.0)
	var respawn := Vector3(0.0, 2.9, 162.0)
	assert_false(CAPTURE.capture_stand_failure(stand, respawn,
		Vector3(208.3, 72.1, 2352.9), 3.5, 8.2).is_empty())
	assert_false(CAPTURE.capture_stand_failure(stand, Vector3(210, 69.6, 2350),
		Vector3(0, 5, 162), 3.5, 8.2).is_empty())
	assert_false(CAPTURE.capture_stand_failure(stand, Vector3(213, 69.6, 2350),
		Vector3(213, 72, 2355), 3.5, 8.2).is_empty())


func test_valid_stand_allows_small_settling_but_rejects_obstruction() -> void:
	var stand := Vector2(210.0, 2350.0)
	var player := Vector3(210.2, 69.6, 2350.1)
	assert_eq(CAPTURE.capture_stand_failure(stand, player,
		Vector3(208.3, 72.1, 2353.5), 3.5, 8.2), "")
	assert_false(CAPTURE.capture_stand_failure(stand, player,
		player + Vector3.UP, 3.5, 8.2).is_empty())
	assert_false(CAPTURE.capture_stand_failure(stand, Vector3.INF,
		Vector3.ZERO, 3.5, 8.2).is_empty())
