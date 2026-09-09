extends "res://tests/test_case.gd"

const HISTORY := preload("res://scripts/net/realm_receiver_history.gd")

func test_completed_departure_stays_closed_until_actual_reentry_ready() -> void:
	var history := HISTORY.new()
	history.retire(20, "meadows", "1:20:1")
	assert_eq(history.token_for(20, "meadows"), "1:20:1")
	# Starting or failing another load does not acknowledge readiness.
	var expected := history.token_for(20, "meadows")
	assert_eq(history.token_for(20, "meadows"), expected)
	assert_true(history.admit_ready(20, "meadows", expected, history.epoch))
	assert_eq(history.token_for(20, "meadows"), "")

func test_stale_readiness_cannot_clear_newer_departure() -> void:
	var history := HISTORY.new()
	history.retire(20, "meadows", "1:20:1")
	var old := history.token_for(20, "meadows")
	history.retire(20, "meadows", "1:20:2")
	assert_false(history.admit_ready(20, "meadows", old, history.epoch))
	assert_eq(history.token_for(20, "meadows"), "1:20:2")

func test_rollback_ready_reopens_source_without_touching_other_receivers() -> void:
	var history := HISTORY.new()
	history.retire(20, "meadows", "1:20:1")
	history.retire(30, "meadows", "1:30:2")
	assert_true(history.admit_ready(20, "meadows", "1:20:1", history.epoch))
	assert_eq(history.token_for(30, "meadows"), "1:30:2")
	assert_eq(history.token_for(20, "water_archipelago"), "")
	assert_eq(history.token_for(40, "meadows"), "")

func test_disconnect_and_new_session_do_not_inherit_previous_identity() -> void:
	var history := HISTORY.new()
	history.retire(20, "meadows", "1:20:1")
	history.disconnect_peer(20)
	assert_eq(history.token_for(20, "meadows"), "")
	history.retire(20, "meadows", "1:20:2")
	var previous_epoch := history.epoch
	history.reset()
	assert_eq(history.token_for(20, "meadows"), "")
	history.retire(20, "meadows", "2:20:1")
	assert_false(history.admit_ready(20, "meadows", "2:20:1", previous_epoch))
	assert_eq(history.token_for(20, "meadows"), "2:20:1")
