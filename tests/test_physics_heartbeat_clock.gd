extends "res://tests/test_case.gd"

const CLOCK := preload("res://tools/net/physics_heartbeat_clock.gd")

func test_fast_physics_preserves_original_sixty_frame_cadence() -> void:
	var clock := CLOCK.new()
	for frame: int in range(1, 60):
		assert_false(clock.physics_callback(frame, frame * 5, 60))
	assert_true(clock.physics_callback(60, 300, 60))
	assert_eq(clock.last_sample_ms, 300)
	assert_false(clock.physics_callback(61, 305, 60))
	assert_true(clock.physics_callback(120, 600, 60))

func test_slow_live_physics_requests_fresh_sample_on_one_second_boundary() -> void:
	var clock := CLOCK.new()
	assert_false(clock.physics_callback(1, 999, 60))
	assert_true(clock.physics_callback(2, 1000, 60))
	assert_false(clock.physics_callback(3, 1999, 60))
	assert_true(clock.physics_callback(4, 2000, 60))
	assert_true(clock.physics_callback(5, 4500, 60), "a slow but actual callback must sample current state")

func test_frame_maximum_remains_independent_of_wall_clock_sampling() -> void:
	var clock := CLOCK.new()
	assert_true(clock.physics_callback(13, 1000, 60))
	assert_true(clock.physics_callback(60, 1100, 60), "original frame cadence is still a maximum")
	assert_false(clock.physics_callback(61, 2099, 60))
	assert_true(clock.physics_callback(62, 2100, 60))

func test_frozen_physics_cannot_refresh_last_actual_sample() -> void:
	var clock := CLOCK.new()
	assert_true(clock.physics_callback(60, 1000, 60))
	var coordinator_now_ms := 16001
	# No physics callback occurred. The pure scheduler has no timer/emitter and
	# cannot advance this timestamp; the original 15-second silence still fails.
	assert_eq(clock.last_sample_ms, 1000)
	assert_true(coordinator_now_ms - clock.last_sample_ms > 15000)

func test_nonphysics_or_reversed_clock_sample_is_refused() -> void:
	var clock := CLOCK.new()
	assert_false(clock.physics_callback(0, 1000, 60))
	assert_false(clock.physics_callback(1, 1000, 0))
	assert_eq(clock.last_sample_ms, 0)
	assert_true(clock.physics_callback(1, 1000, 60))
	assert_false(clock.physics_callback(2, 999, 60))
	assert_eq(clock.last_sample_ms, 1000)
