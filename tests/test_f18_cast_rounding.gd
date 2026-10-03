extends "res://tests/test_case.gd"

const ARRIVAL := preload("res://scripts/net/foundation_portal_arrival.gd")

func test_actual_float32_cast_coordinates_do_not_accumulate_a_false_height_refusal() -> void:
	var capsule := CapsuleShape3D.new()
	capsule.radius = .4
	var body := CharacterBody3D.new()
	var floor_y := Vector3(0, .01, 0).y
	var start := Vector3(0, floor_y + capsule.radius, 0)
	var motion := Vector3(0, -2.0 * capsule.radius, 0)
	var safe := .49609375
	var unsafe := .5
	var clearance: float = absf(motion.y) * (unsafe - safe)
	var maximum_y: float = floor_y + body.safe_margin + clearance
	var old_landing := start + motion * safe + Vector3(0, body.safe_margin, 0)
	assert_true(old_landing.y > maximum_y, "actual native float32 values reproduce the old conservative false refusal")
	var candidate: float = ARRIVAL._cast_landing_y(float(start.y), float(motion.y), safe,
		float(body.safe_margin), float(floor_y), clearance)
	assert_true(is_finite(candidate) and candidate <= maximum_y)
	assert_true(Vector3(0, candidate, 0).y <= Vector3(0, maximum_y, 0).y)
	body.free()

func test_scalar_boundary_refuses_above_bound_even_when_float32_encoding_hides_the_difference() -> void:
	var margin := .001
	var highest := .125
	var maximum_y := highest + margin
	var boundary: float = ARRIVAL._cast_landing_y(highest, 0.0, 0.0, margin, highest, 0.0)
	assert_eq(boundary, maximum_y)
	var above := maximum_y + .000000000001
	assert_eq(Vector3(0, above, 0).y, Vector3(0, maximum_y, 0).y)
	assert_false(is_finite(ARRIVAL._cast_landing_y(highest + .000000000001, 0.0, 0.0, margin, highest, 0.0)))
	assert_false(is_finite(ARRIVAL._cast_landing_y(INF, -.8, .5, margin, highest, 0.0)))
