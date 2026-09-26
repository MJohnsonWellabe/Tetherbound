extends "res://tests/test_case.gd"

## Regression: a host realm crossing after a guest reconnect. `epoch` is a
## per-process counter that `reset()` bumps on every session teardown, so after a
## guest drops and rejoins (or the host process restarts) the two sides never
## share it. The client used to drop the host's `_install_host_move` /
## `_clear_host_move` whenever the host's epoch differed from its own, never
## acknowledged, and the host's `begin_host()` waited out TIMEOUT_MS (120 s) and
## refused the crossing. Two-peer proof of the same path:
## ralph/reports/STORMWOOD-PROGRESS/f11_3/repro_host_crossing_after_rejoin/.

const TRANSITION := preload("res://scripts/net/realm_transition.gd")


class SessionStub extends Node:
	var peer := 1
	func is_active() -> bool:
		return true
	func is_host() -> bool:
		return peer == 1
	func local_peer_id() -> int:
		return peer
	func peers() -> Array:
		return []


func _client_after_rejoin() -> Node:
	var parent := SessionStub.new()
	parent.peer = 40
	var transition := TRANSITION.new()
	parent.add_child(transition)
	# The guest's first session and its drop: one teardown more than the host.
	transition.reset()
	return transition


func test_a_rejoined_client_installs_the_host_move_of_a_host_with_another_epoch() -> void:
	var transition := _client_after_rejoin()
	assert_eq(int(transition.epoch), 2, "the rejoined guest's own epoch moved on")
	assert_true(transition.has_method("accept_host_move"),
		"the client half of _install_host_move is a synchronous, testable seam")
	if transition.has_method("accept_host_move"):
		assert_true(bool(transition.call("accept_host_move", 1, 1, "meadows", "stormwood")),
			"the host (epoch 1) moving is installed by a guest whose own epoch is 2")
		assert_eq(Array(transition._host_move), ["meadows", "stormwood"])
		assert_false(bool(transition.call("accept_host_move", 1, 0, "meadows", "cloudreach")),
			"an older generation from the same host is still stale")
	transition.get_parent().free()


func test_a_rejoined_client_clears_the_host_move_it_installed() -> void:
	var transition := _client_after_rejoin()
	# The move as the client holds it once installed from a host whose epoch is 1.
	transition._host_move.assign(["meadows", "stormwood"])
	transition._host_move_generation = 1
	transition.set("_host_move_epoch", 1)
	transition._clear_host_move(7, 1)
	assert_eq(Array(transition._host_move), ["meadows", "stormwood"],
		"a clear naming another host epoch is not this move's")
	transition._clear_host_move(1, 1)
	assert_true(transition._host_move.is_empty(),
		"the host's clear (its epoch 1, generation 1) releases the move on a guest whose epoch is 2")
	transition.get_parent().free()


func test_reset_starts_host_move_generations_again() -> void:
	var transition := _client_after_rejoin()
	transition._host_move_generation = 5
	transition.reset()
	assert_eq(int(transition._host_move_generation), 0,
		"a restarted host's first move (generation 1) is not stale on the next session")
	transition.get_parent().free()
