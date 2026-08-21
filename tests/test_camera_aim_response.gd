extends "res://tests/test_case.gd"

## Catch aim's near-target slowdown must help with precision without making a
## close, circling creature mechanically impossible to track on controller.

const CAMERA_RIG := preload("res://scripts/player/camera_rig.gd")


func test_near_target_assist_slows_fine_stick_input() -> void:
	var requested := 0.6
	var fine := CAMERA_RIG.aim_assist_scale(0.35, requested)
	assert_almost_eq(fine, requested, 0.001)


func test_near_target_assist_preserves_full_deflection_speed() -> void:
	var full := CAMERA_RIG.aim_assist_scale(1.0, 0.6)
	assert_almost_eq(full, 1.0, 0.001)


func test_near_target_assist_blends_without_a_speed_step() -> void:
	var previous := CAMERA_RIG.aim_assist_scale(0.0, 0.6)
	for step in range(1, 21):
		var current := CAMERA_RIG.aim_assist_scale(float(step) / 20.0, 0.6)
		assert_true(current >= previous,
			"more stick deflection must never make target tracking slower")
		previous = current
