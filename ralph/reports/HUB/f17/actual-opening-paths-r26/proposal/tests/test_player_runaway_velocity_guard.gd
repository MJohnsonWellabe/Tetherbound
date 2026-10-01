extends "res://tests/test_case.gd"

const PLAYER := preload("res://scripts/player/player_controller.gd")


func test_grounded_platform_impulse_is_discarded_before_it_can_become_lethal() -> void:
	var player: CharacterBody3D = PLAYER.new()
	player._max_speed = 120.0
	player._was_on_floor = true
	player._fall_speed = 903.0
	player.velocity = Vector3(700.0, -570.0, 0.0)

	player._clamp_runaway_velocity()

	assert_eq(player.velocity, Vector3.ZERO)
	assert_eq(player._fall_speed, 0.0)
	player.free()


func test_real_airborne_fall_keeps_its_direction_when_bounded() -> void:
	var player: CharacterBody3D = PLAYER.new()
	player._max_speed = 120.0
	player._was_on_floor = false
	player.velocity = Vector3(0.0, -903.0, 0.0)

	player._clamp_runaway_velocity()

	assert_almost_eq(player.velocity.length(), 120.0, 0.001)
	assert_true(player.velocity.y < 0.0)
	player.free()


func test_idle_flat_floor_keeps_native_recovery_while_slopes_keep_the_stop() -> void:
	assert_false(PLAYER.idle_slope_stop(Vector3.ZERO, Vector3.UP, Vector3.UP),
		"CI6173 Tam's flat native UP floor must retain its ordinary recovery")
	assert_true(PLAYER.idle_slope_stop(Vector3.ZERO, Vector3(0, cos(0.35), sin(0.35)), Vector3.UP),
		"idle stability on the original sloped treads remains enabled")
	assert_false(PLAYER.idle_slope_stop(Vector3.FORWARD, Vector3(0, cos(0.35), sin(0.35)), Vector3.UP),
		"active locomotion retains its original slope policy")
	assert_true(PLAYER.idle_slope_stop(Vector3.ZERO, Vector3.ZERO, Vector3.UP),
		"missing floor normal cannot masquerade as a flat floor")


func test_idle_flat_floor_policy_uses_the_current_up_direction() -> void:
	assert_false(PLAYER.idle_slope_stop(Vector3.ZERO, Vector3.RIGHT, Vector3.RIGHT))
	assert_true(PLAYER.idle_slope_stop(Vector3.ZERO, Vector3.UP, Vector3.RIGHT))
