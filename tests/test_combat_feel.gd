extends "res://tests/test_case.gd"

## Owner playtest 2026-09-29: power attacks whiffed after a circling opponent
## left the arc locked at wind-up start, and combat felt slow. Pins the shape of
## the fix (strike re-aim, the charged arc, the player pace scale), not the
## tuned numbers.

const MATH := preload("res://scripts/combat/combat_math.gd")


func test_reaim_turns_toward_a_target_that_circled_away() -> void:
	var origin := Vector3.ZERO
	var facing := Vector3(0, 0, -1)
	# Target 60 degrees off the locked facing: outside a 75 degree cone (37.5 half-angle).
	var target := Vector3(sin(deg_to_rad(60.0)), 0, -cos(deg_to_rad(60.0))) * 2.5
	var move := {"range": 3.0, "cone_degrees": 75.0}
	assert_false(MATH.move_connects(move, origin, facing, target), "the locked facing misses the circled target")
	var turned := MATH.reaimed_facing(origin, facing, target, 45.0)
	assert_true(MATH.move_connects(move, origin, turned, target), "after the re-aim the same swing connects")


func test_reaim_turn_is_limited() -> void:
	var origin := Vector3.ZERO
	var facing := Vector3(0, 0, -1)
	var behind := Vector3(0, 0, 3)
	var turned := MATH.reaimed_facing(origin, facing, behind, 45.0)
	var angle := rad_to_deg(Vector3(facing).angle_to(turned))
	assert_true(absf(angle - 45.0) < 0.01, "a target behind the striker is turned toward by at most the limit (%f deg)" % angle)
	assert_false(MATH.move_connects({"range": 3.0, "cone_degrees": 75.0}, origin, turned, behind),
		"a target directly behind still dodges the swing")


func test_reaim_disabled_or_degenerate_leaves_facing_alone() -> void:
	var facing := Vector3(1, 0, 0)
	assert_eq(MATH.reaimed_facing(Vector3.ZERO, facing, Vector3(0, 0, 3), 0.0), facing, "0 degrees disables it")
	assert_eq(MATH.reaimed_facing(Vector3.ZERO, Vector3.ZERO, Vector3(0, 0, 3), 45.0), Vector3.ZERO, "no facing, no turn")
	assert_eq(MATH.reaimed_facing(Vector3.ZERO, facing, Vector3.ZERO, 45.0), facing, "standing inside the target, no turn")


func test_reaim_config_favours_the_power_attack() -> void:
	assert_true(MATH.strike_reaim_degrees(false) > 0.0, "the charged attack re-aims")
	assert_true(MATH.strike_reaim_degrees(false) > MATH.strike_reaim_degrees(true), "and more than the wide-arc quick attack")


func test_player_pace_shortens_timings_and_widens_only_the_charged_arc() -> void:
	var profile := {"windup": 0.55, "recovery": 0.5, "cooldown": 1.2, "cone_degrees": 75.0, "range": 3.0}
	var charged := MATH.with_player_pace(profile, "player_charged")
	var quick := MATH.with_player_pace(profile, "player_quick")
	for key in ["windup", "recovery", "cooldown"]:
		assert_true(float(charged[key]) < float(profile[key]), "%s is shorter after the pace scale" % key)
		assert_true(float(charged[key]) > 0.3 * float(profile[key]), "%s is not collapsed" % key)
	assert_true(float(charged["cone_degrees"]) > 75.0, "the charged arc widens")
	assert_eq(float(quick["cone_degrees"]), 75.0, "the quick arc is untouched")
	assert_eq(float(charged["range"]), 3.0, "reach is untouched")
	assert_eq(float(profile["windup"]), 0.55, "the input profile is not mutated")
