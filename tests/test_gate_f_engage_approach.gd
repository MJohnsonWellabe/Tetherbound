extends TestCase

const APPROACH := preload("res://tools/gate_f/engage_approach.gd")


func test_selected_identity_and_actual_winning_provider_are_both_required() -> void:
	var selected := RefCounted.new()
	var other_wild := RefCounted.new()
	var director := RefCounted.new()
	var gather := RefCounted.new()
	var offer := {"label": "Engage Bramblebun", "actionable": true}
	assert_true(APPROACH.matches(selected, selected, director, director, offer, true))
	assert_false(APPROACH.matches(selected, other_wild, director, director, offer, true))
	assert_false(APPROACH.matches(selected, selected, director, gather, offer, true))
	assert_false(APPROACH.matches(selected, selected, director, director, offer, false))
	assert_false(APPROACH.matches(null, null, director, director, offer, true))


func test_disabled_statement_and_wrong_verb_cannot_authorize_input() -> void:
	var selected := RefCounted.new()
	var director := RefCounted.new()
	for offer in [{}, {"label": "Gather deadwood"},
			{"label": "Engage Bramblebun", "actionable": false}, {"label": "Put Bramblebun away"}]:
		assert_false(APPROACH.matches(selected, selected, director, director, offer, true))


func test_four_distinct_stances_follow_live_target_without_modifying_it() -> void:
	var target := Vector3(25.0, 0.94, -43.0)
	var direction := Vector3(1.0, 7.0, 0.0)
	var stances: Array[Vector3] = []
	for index in 4:
		var point := APPROACH.stance(target, direction, index)
		assert_true(absf(point.distance_to(target) - 1.2) < 0.001)
		assert_eq(point.y, target.y)
		assert_false(stances.has(point))
		stances.append(point)
		var moved := APPROACH.stance(target + Vector3(2, 0, 3), direction, index)
		assert_true(moved.distance_to(point + Vector3(2, 0, 3)) < 0.001)
	assert_true(stances[0].x > target.x)
	assert_true(stances[3].x < target.x)
	assert_true(APPROACH.stance(target, Vector3.ZERO, 0).is_finite())
