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
