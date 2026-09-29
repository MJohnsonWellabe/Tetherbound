extends "res://tests/test_case.gd"

## RUN-LEAN. Pins scripts/player/run_gait.gd (steady forward sprint lean and
## ground-speed-tracking playback scale) and the movement.json tunables that
## drive it. Pure statics, no scene tree.

const RUN_GAIT := preload("res://scripts/player/run_gait.gd")
const WALK := 5.0
const SPRINT := 8.6

var _feel: Dictionary = {}


func before_each() -> void:
	var parsed: Variant = JSON.parse_string(
		FileAccess.get_file_as_string("res://data/config/movement.json"))
	_feel = (parsed as Dictionary).get("gait_feel", {})


func _lean(speed: float) -> float:
	return RUN_GAIT.lean_target_deg(speed, WALK, SPRINT, float(_feel.get("run_lean_max_deg", 0.0)))


func test_lean_is_zero_at_rest_and_walk() -> void:
	assert_almost_eq(_lean(0.0), 0.0, 0.0001, "rest")
	assert_almost_eq(_lean(WALK), 0.0, 0.0001, "walk speed")
	assert_almost_eq(_lean(3.0), 0.0, 0.0001, "below walk")


func test_lean_rises_monotonically_to_configured_max() -> void:
	var max_deg := float(_feel.get("run_lean_max_deg", 0.0))
	assert_between(max_deg, 8.0, 12.0, "configured max lean in the owner's 8-12 degree band")
	var prev := -1.0
	for i in 41:
		var v := WALK + (SPRINT - WALK) * float(i) / 40.0
		var lean := _lean(v)
		assert_true(lean >= prev, "monotonic at %.2f m/s" % v)
		prev = lean
	assert_almost_eq(_lean(SPRINT), max_deg, 0.0001, "max at sprint speed")
	assert_almost_eq(_lean(SPRINT + 3.0), max_deg, 0.0001, "never exceeds max")


func test_lean_ease_converges_and_returns_to_zero() -> void:
	var lean := 0.0
	for i in 60:  # 1 s at 60 Hz, tau 0.15 s
		lean = RUN_GAIT.ease_toward(lean, 8.0, 1.0 / 60.0, 0.15)
	assert_between(lean, 7.9, 8.0, "eased in within about a second")
	var mid := RUN_GAIT.ease_toward(0.0, 8.0, 0.15, 0.15)
	assert_almost_eq(mid, 8.0 * (1.0 - exp(-1.0)), 0.0001, "one tau reaches 63 percent")
	for i in 120:
		lean = RUN_GAIT.ease_toward(lean, 0.0, 1.0 / 60.0, 0.15)
	assert_almost_eq(lean, 0.0, 0.01, "back to zero at rest")
	assert_eq(RUN_GAIT.ease_toward(3.0, 5.0, 0.0, 0.15), 3.0, "zero delta holds")


func test_playback_scale_monotonic_and_clamped() -> void:
	var cad := float(_feel.get("sprint_cadence_scale", 1.0))
	var lo := float(_feel.get("gait_rate_min", 0.5))
	var hi := float(_feel.get("gait_rate_max", 1.4))
	assert_between(cad, 0.6, 1.0, "sprint cadence factor slows, never speeds up")
	var prev := -1.0
	for i in 61:
		var s := 0.5 * float(i) / 4.0  # 0..15 m/s
		var scale: float = RUN_GAIT.playback_scale(s, SPRINT, cad, lo, hi)
		assert_true(scale >= prev, "monotonic at %.2f m/s" % s)
		assert_between(scale, lo, hi, "clamped at %.2f m/s" % s)
		prev = scale
	assert_almost_eq(RUN_GAIT.playback_scale(SPRINT, SPRINT, cad, lo, hi), cad, 0.0001, "full sprint = cadence factor")
	assert_eq(RUN_GAIT.playback_scale(0.0, SPRINT, cad, lo, hi), lo, "floor")
	assert_eq(RUN_GAIT.playback_scale(99.0, SPRINT, cad, lo, hi), hi, "ceiling")
	assert_eq(RUN_GAIT.playback_scale(7.0, 0.0, cad, lo, hi), 1.0, "no reference = 1x")
