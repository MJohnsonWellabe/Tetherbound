extends "res://tests/test_case.gd"

## The F40 matrix's offset views: a 12 m approach that backs off a ledge steps
## in toward the stand (or turns slightly) to the first grounded point, and an
## all-void stand still fails closed.
const FALLBACK := preload("res://tools/capture_view_fallback.gd")


func test_grounded_approach_is_kept_unchanged() -> void:
	var chosen := FALLBACK.resolve(Vector2.ZERO, Vector2(0.0, 1.0), -12.0, func(_p: Vector2) -> bool: return true)
	assert_false(bool(chosen.fallback))
	assert_almost_eq(float(chosen.offset_m), -12.0)
	assert_almost_eq(float(chosen.position_xz[1]), -12.0)


func test_void_behind_the_stand_resolves_to_the_nearest_grounded_point() -> void:
	# Ground ends 7 m behind the stand: -12 and -10 and -8 are void, -6 is ground.
	var ledge := func(p: Vector2) -> bool: return p.y >= -7.0
	var chosen := FALLBACK.resolve(Vector2.ZERO, Vector2(0.0, 1.0), -12.0, ledge)
	assert_true(bool(chosen.fallback))
	assert_almost_eq(float(chosen.offset_m), -6.0)
	assert_almost_eq(float(chosen.turn_deg), 0.0)
	assert_almost_eq(float(chosen.position_xz[1]), -6.0, 0.001)


func test_a_turn_is_tried_only_after_every_step_on_the_heading() -> void:
	# Only the half-plane x < -1 has ground: no straight-back point qualifies.
	var side := func(p: Vector2) -> bool: return p.x < -1.0
	var chosen := FALLBACK.resolve(Vector2.ZERO, Vector2(0.0, 1.0), -12.0, side)
	assert_true(bool(chosen.fallback))
	assert_almost_eq(absf(float(chosen.turn_deg)), 15.0)
	assert_true(float(chosen.position_xz[0]) < -1.0)


func test_all_void_fails_closed() -> void:
	assert_true(FALLBACK.resolve(Vector2.ZERO, Vector2(0.0, 1.0), -12.0, func(_p: Vector2) -> bool: return false).is_empty())


func test_offsets_never_come_closer_than_four_metres() -> void:
	assert_eq(FALLBACK.candidates(-12.0), [-12.0, -10.0, -8.0, -6.0, -4.0])
	assert_eq(FALLBACK.candidates(3.0), [3.0])
