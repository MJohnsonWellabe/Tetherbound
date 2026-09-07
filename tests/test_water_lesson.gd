extends "res://tests/test_case.gd"

const LESSON := preload("res://scripts/world/water_lesson.gd")


func _lesson() -> RefCounted:
	return LESSON.new({"surface_polyline": [[0, 0, 0], [60, 0, 0]]})


func test_real_course_requires_swimming_then_dry_arrival() -> void:
	var lesson := _lesson()
	assert_false(lesson.observe(1, Vector3.ZERO, 0))
	for x in range(1, 61):
		assert_false(lesson.observe(1, Vector3(x, 0, 0), 1))
	assert_true(lesson.observe(1, Vector3(60, 1, 1), 0))
	assert_false(lesson.observe(1, Vector3(60, 1, 1), 0))


func test_teleport_walking_and_other_players_cannot_complete_your_lesson() -> void:
	var lesson := _lesson()
	lesson.observe(1, Vector3.ZERO, 0)
	assert_false(lesson.observe(1, Vector3(60, 0, 0), 1))
	assert_false(lesson.observe(1, Vector3(60, 1, 0), 0))
	lesson.observe(2, Vector3.ZERO, 0)
	for x in range(1, 61):
		lesson.observe(2, Vector3(x, 1, 0), 0)
	assert_false(lesson.observe(2, Vector3(60, 1, 0), 0))
	lesson.observe(3, Vector3.ZERO, 0)
	for x in range(1, 61):
		lesson.observe(3, Vector3(x, 0, 0), 1)
	assert_false(lesson.observe(4, Vector3(60, 1, 0), 0))
	assert_true(lesson.observe(3, Vector3(60, 1, 0), 0))


func test_short_loops_do_not_replace_the_swimming_course() -> void:
	var lesson := _lesson()
	lesson.observe(1, Vector3.ZERO, 0)
	for loop in 10:
		for x in range(1, 7):
			lesson.observe(1, Vector3(x, 0, 0), 1)
		for x in range(6, -1, -1):
			lesson.observe(1, Vector3(x, 0, 0), 1)
	for x in range(1, 61):
		lesson.observe(1, Vector3(x, 1, 0), 0)
	assert_false(lesson.observe(1, Vector3(60, 1, 0), 0))
