extends "res://tests/test_case.gd"

## The Stormwood fight pilot presses quick only within the move's reach
## (rowan_visit: out-of-reach whiffs kept a fleeing voltarach alive).
const SEGMENT := preload("res://tests/helpers/stormwood_crown_build_segment.gd")


func test_swing_only_within_reach() -> void:
	assert_true(SEGMENT.swing_now(9.0, 10.5, true, 1000, 900), "in reach, ready, spaced")
	assert_true(SEGMENT.swing_now(10.5, 10.5, true, 1000, 1000), "at the reach boundary")
	assert_false(SEGMENT.swing_now(17.0, 10.5, true, 1000, 900), "out of reach never presses")


func test_swing_respects_readiness_and_spacing() -> void:
	assert_false(SEGMENT.swing_now(5.0, 10.5, false, 1000, 900), "move not ready")
	assert_false(SEGMENT.swing_now(5.0, 10.5, true, 899, 900), "inside the press spacing")
