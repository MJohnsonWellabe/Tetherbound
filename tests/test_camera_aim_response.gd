extends "res://tests/test_case.gd"

## Catch aim's near-target slowdown must help with precision without making a
## close, circling creature mechanically impossible to track on controller.

const CAMERA_RIG := preload("res://scripts/player/camera_rig.gd")
const THROW_AIM := preload("res://scripts/combat/throw_aim.gd")


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


func test_launch_assist_leads_a_moving_target_over_windup_and_flight() -> void:
	var origin := Vector3.ZERO
	var centre := Vector3(0.0, 1.0, -7.0)
	var velocity := Vector3(3.4, 0.0, 0.0)
	var predicted: Vector3 = THROW_AIM.predict_launch_point(
		origin, centre, velocity, 17.0, 14.0, 0.18, 0.85, 4.5, 2.6)
	assert_true(predicted.x > centre.x + 1.5,
		"a 3.4m/s circling target must be led beyond its current body")
	assert_true(predicted.x <= centre.x + 2.6,
		"the launch assist must stay inside its configured distance bound")


func test_launch_assist_is_zero_for_a_stationary_target() -> void:
	var centre := Vector3(0.0, 1.0, -7.0)
	var predicted: Vector3 = THROW_AIM.predict_launch_point(
		Vector3.ZERO, centre, Vector3.ZERO, 17.0, 14.0, 0.18, 0.85, 4.5, 2.6)
	assert_almost_eq(predicted.distance_to(centre), 0.0, 0.001)


func test_launch_assist_clamps_pathological_target_velocity() -> void:
	var centre := Vector3(0.0, 1.0, -7.0)
	var predicted: Vector3 = THROW_AIM.predict_launch_point(
		Vector3.ZERO, centre, Vector3(100.0, 0.0, 0.0),
		17.0, 14.0, 0.18, 0.85, 4.5, 2.6)
	assert_true(predicted.distance_to(centre) <= 2.601,
		"launch assist escaped its maximum lead distance")


func test_launch_assist_checks_body_metres_not_camera_degrees() -> void:
	var inside := THROW_AIM.reticle_body_geometry(
		Vector3.ZERO, Vector3.FORWARD, Vector3(0.59, 0.0, -6.0), 0.60, 1.0)
	var outside := THROW_AIM.reticle_body_geometry(
		Vector3.ZERO, Vector3.FORWARD, Vector3(0.61, 0.0, -6.0), 0.60, 1.0)
	assert_true(bool(inside["inside_body"]),
		"0.59m screen-ray offset must be inside a 0.60m body")
	assert_false(bool(outside["inside_body"]),
		"0.61m screen-ray offset must remain ineligible despite a small angular error")


func test_launch_assist_rejects_an_ally_as_the_first_los_hit() -> void:
	var target := Node.new()
	var target_child := Node.new()
	target.add_child(target_child)
	var ally := Node.new()
	assert_true(THROW_AIM.first_hit_belongs_to_target(target_child, target))
	assert_false(THROW_AIM.first_hit_belongs_to_target(ally, target),
		"an ally body in front of the wild must deny launch assist")
