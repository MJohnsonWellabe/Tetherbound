extends "res://tests/test_case.gd"

const DIRECTOR := preload("res://scripts/combat/cloudreach_encounter_director.gd")


class GapDirector:
	extends "res://scripts/combat/cloudreach_encounter_director.gd"
	func _wild_support(at: Vector3, _radius: float, _wild: Node3D) -> Vector3:
		return Vector3.INF if at.x > 1.0 and at.x < 2.0 else at


func test_failed_final_wander_candidate_stops_instead_of_accepting_the_last_bad_roll() -> void:
	var current := Vector3(2, 180, 3)
	var unsupported := Vector3(9, 180, 3)
	assert_eq(DIRECTOR.CliffWild.checked_destination(unsupported, current,
		func(_candidate: Vector3) -> bool: return false), current)
	assert_eq(DIRECTOR.CliffWild.checked_destination(Vector3.INF, current, Callable()), current)
	assert_eq(DIRECTOR.CliffWild.checked_destination(unsupported, current,
		func(candidate: Vector3) -> bool: return candidate.x < 4), current)


func test_supported_wander_target_is_preserved_and_not_replaced_by_home() -> void:
	var current := Vector3(2, 180, 3)
	var target := Vector3(3, 180, 4)
	assert_eq(DIRECTOR.CliffWild.checked_destination(target, current,
		func(candidate: Vector3) -> bool: return candidate.x < 4), target)
	assert_eq(DIRECTOR.CliffWild.checked_destination(target, current, Callable()), target)


func test_missing_world_or_nonfinite_path_cannot_certify_a_spawn() -> void:
	var director := DIRECTOR.new()
	assert_false(director._wild_support(Vector3.ZERO, 0.5, null).is_finite())
	assert_false(director._wild_path_supported(Vector3.ZERO, Vector3.INF, 0.5, null))
	assert_false(director._wild_path_supported(Vector3.ZERO, Vector3(25, 0, 0), 0.5, null))
	assert_false(director._wild_path_supported(Vector3.ZERO, Vector3.ONE, 0.5, null))
	director.free()


func test_supported_endpoints_do_not_certify_a_path_across_a_gap() -> void:
	var director := GapDirector.new()
	assert_true(director._wild_support(Vector3.ZERO, 0.5, null).is_finite())
	assert_true(director._wild_support(Vector3(3, 0, 0), 0.5, null).is_finite())
	assert_false(director._wild_path_supported(Vector3.ZERO, Vector3(3, 0, 0), 0.5, null))
	assert_true(director._wild_path_supported(Vector3.ZERO, Vector3(0.75, 0, 0), 0.5, null))
	director.free()
