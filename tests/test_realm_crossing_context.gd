extends "res://tests/test_case.gd"

const GAME := preload("res://autoload/game_state.gd")
const TRANSITION := preload("res://scripts/net/realm_transition.gd")

class SessionProbe extends Node:
	var realm_transition: Node
	var active := true
	var hosting := false
	func is_active() -> bool: return active
	func is_host() -> bool: return hosting
	func local_peer_id() -> int: return 1 if hosting else 20

func _game() -> Node:
	var game := GAME.new()
	game.reset_for_new_game()
	var session := SessionProbe.new()
	var transition := TRANSITION.new()
	session.add_child(transition)
	session.realm_transition = transition
	game.add_child(session)
	game.session = session
	game._realm_crossing_owner = 5
	return game

func test_epoch_session_and_owner_cancellation_are_independent_of_realm_readiness() -> void:
	var game := _game()
	var captured: Dictionary = game._realm_crossing_context()
	assert_true(game._realm_crossing_valid(captured))
	game.session.realm_transition.reset()
	assert_false(game._realm_crossing_valid(captured), "a ready scene cannot revive an old Session epoch")
	var newer: Dictionary = game._realm_crossing_context()
	assert_true(game._realm_crossing_valid(newer))
	game.session.active = false
	assert_false(game._realm_crossing_valid(newer))
	game.session.active = true
	game._realm_crossing_owner = 6
	assert_false(game._realm_crossing_valid(newer), "old overlay owner cannot finish newer crossing")
	game.free()

func test_new_game_and_unexpected_realm_change_cancel_captured_context() -> void:
	var game := _game()
	var captured: Dictionary = game._realm_crossing_context()
	game.current_realm = "water"
	assert_false(game._realm_crossing_valid(captured))
	game.current_realm = "meadows"
	assert_true(game._realm_crossing_valid(captured))
	game.reset_for_new_game()
	assert_false(game._realm_crossing_valid(captured))
	assert_eq(game._realm_crossing_owner, 0)
	game.free()

func test_solo_context_preserves_no_network_transaction() -> void:
	var game := _game()
	game.session.active = false
	game.session.hosting = true
	var captured: Dictionary = game._realm_crossing_context()
	assert_false(captured.client)
	assert_false(captured.active)
	assert_true(game._realm_crossing_valid(captured))
	game.free()
