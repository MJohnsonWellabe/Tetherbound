extends TestCase

const GUARD := preload("res://tools/gate_f/chip_damage_guard.gd")
const MATH := preload("res://scripts/combat/combat_math.gd")


func test_already_wounded_target_stops_before_first_swing() -> void:
	var upper := GUARD.upper_bound(9.0, 20.0, 20.0, 1.0, 1.0)
	var result := GUARD.decision(9.5, 40.0, upper, 0.01)
	assert_true(result.ok)
	assert_false(result.safe)
	assert_true(upper >= MATH.rolled_damage(9.0, 20.0, 20.0, 1.0))


func test_bound_covers_production_rolls_types_moves_wind_and_critical() -> void:
	var config := MATH.config()
	var exhaustion := float(config.get("wind", {}).get("exhausted_power_scale", 0.6))
	var critical := maxf(1.0, float(config.get("poise", {}).get("crit_scale", 1.5)))
	for type_mult in [0.5, 1.0, 1.5]:
		for move_power in [0.75, 1.0, 1.4]:
			var upper := GUARD.upper_bound(9.0, 31.0, 14.0, move_power, type_mult)
			for power_scale in [1.0, exhaustion]:
				for critical_scale in [1.0, critical]:
					for roll in [0.0, 0.5, 1.0]:
						var actual: float = MATH.rolled_damage(9.0 * power_scale, 31.0, 14.0, roll, move_power, type_mult) * critical_scale
						assert_true(actual <= upper + 0.00001)


func test_strict_floor_boundary_and_healthy_target() -> void:
	assert_false(GUARD.decision(11.0, 100.0, 10.0, 0.01).safe)
	assert_true(GUARD.decision(11.01, 100.0, 10.0, 0.01).safe)
	assert_true(GUARD.decision(100.0, 100.0, 10.0, 0.01).safe)


func test_invalid_or_fainted_values_fail_closed() -> void:
	assert_false(GUARD.decision(0.0, 100.0, 10.0, 0.01).ok)
	assert_false(GUARD.decision(NAN, 100.0, 10.0, 0.01).ok)
	assert_false(GUARD.decision(20.0, 100.0, INF, 0.01).ok)
	assert_false(GUARD.decision(20.0, 100.0, 10.0, -0.1).ok)
