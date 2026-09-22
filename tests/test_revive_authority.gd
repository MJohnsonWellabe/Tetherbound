extends "res://tests/test_case.gd"

const AUTHORITY := preload("res://scripts/net/revive_authority.gd")


func _views(reviver_at: Vector3 = Vector3(0, 0, 0), target_at: Vector3 = Vector3(1, 0, 0)) -> Dictionary:
	return {
		1: {"valid": true, "position": reviver_at, "realm": "water", "body_id": 101},
		2: {"valid": true, "position": target_at, "realm": "water", "body_id": 202},
		3: {"valid": true, "position": Vector3(1.2, 0, 0), "realm": "water", "body_id": 303},
	}


func _opened() -> RefCounted:
	var service := AUTHORITY.new()
	assert_true(service.note_down(2, 10, "water", 45.0))
	return service


func test_host_clock_completes_only_at_three_seconds_and_consumes_window_first() -> void:
	var service := _opened()
	var views := _views()
	assert_eq(service.start(1, 2, 10, 1, views).kind, "started")
	var early: Array[Dictionary] = service.tick(2.99, views)
	assert_eq(early[-1].kind, "progress")
	assert_true(service.has_window(2))
	var done: Array[Dictionary] = service.tick(0.01, views)
	assert_eq(done[-1].kind, "completed")
	assert_false(service.has_window(2), "completion consumes authorization before its event")
	assert_eq(service.start(3, 2, 10, 1, views).kind, "rejected",
		"there is no direct completion/revive API after host consumption")


func test_duplicate_replay_and_competing_reviver_never_reset_or_double_grant() -> void:
	var service := _opened()
	var views := _views()
	assert_eq(service.start(1, 2, 10, 4, views).kind, "started")
	assert_eq(service.tick(1.0, views)[-1].elapsed, 1.0)
	var duplicate: Dictionary = service.start(1, 2, 10, 4, views)
	assert_eq(duplicate.kind, "duplicate")
	assert_almost_eq(float(duplicate.elapsed), 1.0)
	assert_eq(service.start(3, 2, 10, 1, views).reason, "busy")
	var completed: Array[Dictionary] = service.tick(2.0, views)
	assert_eq(completed[-1].kind, "completed")
	assert_eq(service.tick(1.0, views).size(), 0, "a completed target cannot grant again")
	assert_false(service.note_down(2, 10, "water", 45.0), "same window replay cannot reopen")
	assert_true(service.note_down(2, 11, "water", 45.0), "newer target window is distinct")


func test_host_tick_cancels_movement_range_body_and_realm_changes() -> void:
	var service := _opened()
	var views := _views()
	assert_eq(service.start(1, 2, 10, 1, views).kind, "started")
	views[1].position = Vector3(0.31, 0, 0)
	assert_eq(service.tick(0.1, views)[-1].reason, "moved")

	service = _opened()
	views = _views()
	assert_eq(service.start(1, 2, 10, 1, views).kind, "started")
	views[2].position = Vector3(3, 0, 0)
	assert_eq(service.tick(0.1, views)[-1].reason, "out_of_range")

	service = _opened()
	views = _views()
	assert_eq(service.start(1, 2, 10, 1, views).kind, "started")
	views[2].body_id = 999
	assert_eq(service.tick(0.1, views)[-1].reason, "body_replaced")

	service = _opened()
	views = _views()
	assert_eq(service.start(1, 2, 10, 1, views).kind, "started")
	views[1].realm = "meadows"
	assert_eq(service.tick(0.1, views)[-1].reason, "realm_changed")


func test_window_expiry_and_attempt_replacement_cancel_authorization_without_death() -> void:
	var service := AUTHORITY.new()
	assert_true(service.note_down(2, 10, "water", 0.2))
	var expiry := service.tick(0.2, _views())
	assert_eq(expiry[-1].reason, "window_expired")
	assert_false(service.has_window(2))

	service = _opened()
	var views := _views()
	assert_eq(service.start(1, 2, 10, 2, views).kind, "started")
	assert_true(service.note_down(2, 11, "water", 45.0))
	var replaced := service.tick(0.0, views)
	assert_eq(replaced[0].reason, "window_replaced")
	assert_true(service.record_for(1).is_empty(),
		"new target window does not retain stale authorization")


func test_cancel_highwater_refuses_old_start_and_old_cancel_cannot_stop_new_attempt() -> void:
	var service := _opened()
	var views := _views()
	service.cancel(1, 5)
	assert_eq(service.start(1, 2, 10, 5, views).reason, "stale_attempt")
	assert_eq(service.start(1, 2, 10, 6, views).kind, "started")
	service.cancel(1, 5)
	assert_false(service.record_for(1).is_empty(), "old cancel cannot stop a newer active attempt")
	assert_eq(service.tick(0.1, views)[-1].kind, "progress")
	service.cancel(1, 6)
	assert_true(service.record_for(1).is_empty())
	assert_eq(service.start(1, 2, 10, 7, views).kind, "started")


func test_nonfinite_and_unregistered_views_are_rejected() -> void:
	var service := AUTHORITY.new()
	assert_false(service.note_down(0, 1, "water", 1.0))
	assert_false(service.note_down(2, 1, "", 1.0))
	assert_true(service.note_down(2, 1, "water", 45.0))
	assert_eq(service.start(1, 2, 1, 1, {}).reason, "invalid_peer")
	var views := _views()
	views[1].position = Vector3.INF
	assert_eq(service.start(1, 2, 1, 1, views).reason, "invalid_peer")


func test_one_reviver_cannot_open_two_targets_and_acceptance_advances_attempt_order() -> void:
	var service := _opened()
	var views := _views()
	assert_true(service.note_down(3, 20, "water", 45.0))
	assert_eq(service.start(1, 2, 10, 5, views).kind, "started")
	assert_eq(service.start(1, 3, 20, 6, views).reason, "reviver_busy",
		"one host channel belongs to one reviver as well as one target")
	assert_eq(service.start(1, 3, 20, 4, views).reason, "stale_attempt",
		"a later accepted start advances the reviver's attempt ordering")


func test_reviver_becoming_downed_cancels_the_host_channel() -> void:
	var service := _opened()
	var views := _views()
	assert_eq(service.start(1, 2, 10, 1, views).kind, "started")
	assert_true(service.note_down(1, 20, "water", 45.0))
	var events: Array[Dictionary] = service.tick(0.1, views)
	assert_eq(events[-1].kind, "cancelled")
	assert_eq(events[-1].reason, "reviver_downed")
	assert_true(service.record_for(1).is_empty())
