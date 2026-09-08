extends "res://tests/test_case.gd"
const HANDOFF := preload("res://tests/helpers/earned_stormward_handoff.gd")
const ROUTE := preload("res://tests/helpers/cloudreach_live_segment.gd")

class Clock extends Node:
	signal physics_tick

func test_handoff_restores_real_travel_clock_and_disconnects_before_world_destruction() -> void:
	var route := ROUTE.new()
	var handoff := HANDOFF.new()
	var clock := Clock.new()
	var callback := Callable(route, "_record_frame")
	handoff._watch_travel(clock.physics_tick, callback)
	clock.physics_tick.emit()
	assert_almost_eq(route.simulated_seconds, 1.0 / 60.0)
	clock.physics_tick.emit()
	assert_almost_eq(route.simulated_seconds, 2.0 / 60.0)
	handoff._stop_travel_watches()
	assert_false(clock.physics_tick.is_connected(callback))
	clock.physics_tick.emit()
	assert_almost_eq(route.simulated_seconds, 2.0 / 60.0)
	assert_eq(handoff._travel_watches, [])
	clock.free()
	handoff._stop_travel_watches()

func test_missing_context_fails_without_travel_watchers() -> void:
	var handoff := HANDOFF.new()
	var outcome: Dictionary = await handoff.run(null, null)
	assert_false(outcome.ok)
	assert_false(outcome.failures.is_empty())
	assert_eq(handoff._travel_watches, [])
