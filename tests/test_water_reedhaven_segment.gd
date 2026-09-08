extends "res://tests/test_case.gd"

const SEGMENT := preload("res://tests/helpers/water_reedhaven_segment.gd")


func test_result_never_reports_success_before_explicit_segment_completion() -> void:
	var segment := SEGMENT.new()
	assert_false(segment.result().ok)
	assert_false(SEGMENT.verdict(false, []))
	assert_false(SEGMENT.verdict(true, ["missing production prompt"]))
	assert_true(SEGMENT.verdict(true, []))
