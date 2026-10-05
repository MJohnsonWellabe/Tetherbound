extends "res://tests/test_case.gd"

## A guest's homecoming acknowledgement is sent only against the host's fresh
## personal-view reply: an empty or pre-arrival cache never supplies the
## revision, and the host path still sends synchronously.
const GAME := preload("res://autoload/game_state.gd")

class SessionProbe extends Node:
	signal homestead_personal_view_completed()
	var hosting := false
	var _foundation_personal_cache: Dictionary = {}
	var host_view: Dictionary = {}
	var view_requests := 0
	var sent: Array = []
	func is_host() -> bool: return hosting
	func local_peer_id() -> int: return 1 if hosting else 20
	func homestead_personal_view() -> Dictionary:
		view_requests += 1
		return host_view.duplicate(true) if hosting else _foundation_personal_cache.duplicate(true)
	func _foundation_send(op: String, key: String, intent: Dictionary, revision: int) -> Dictionary:
		sent.append({"op": op, "key": key, "intent": intent.duplicate(true), "revision": revision})
		return {"ok": false, "resolved": false}
	func _owner_training_row() -> Dictionary: return {}
	func _training_decision(_peer: int, _row: Dictionary) -> Dictionary: return {}
	func reply(view: Dictionary) -> void:
		_foundation_personal_cache = view.duplicate(true)
		homestead_personal_view_completed.emit()

func _game(hosting: bool) -> Node:
	var game := GAME.new()
	game.reset_for_new_game()
	game.local.character_id = "character-ack"
	var session := SessionProbe.new()
	session.hosting = hosting
	game.add_child(session)
	game.session = session
	return game

func _intent() -> Dictionary:
	return {"kind": "regional_ending_ack", "version": 1, "stage": "homecoming_seen",
		"transaction_id": "regional_ending:character-ack:homecoming_seen"}

func test_guest_with_empty_cache_waits_for_fresh_view_then_sends_its_revision() -> void:
	var game := _game(false)
	var session: SessionProbe = game.session
	var result: Dictionary = game._queue_regional_ack(_intent())
	assert_eq(result.get("status"), "pending")
	assert_eq(session.view_requests, 1)
	assert_eq(session.sent.size(), 0)
	session.reply({"registry_revision": 7})
	assert_eq(session.sent.size(), 1)
	assert_eq(session.sent[0].op, "regional_ack")
	assert_eq(session.sent[0].key, "regional_ending:character-ack")
	assert_eq(session.sent[0].revision, 7)
	assert_eq(session.sent[0].intent, _intent())
	session.reply({"registry_revision": 8})
	assert_eq(session.sent.size(), 1, "one acknowledgement per queued intent")
	game.free()

func test_guest_stale_cache_is_not_used_before_the_fresh_reply() -> void:
	var game := _game(false)
	var session: SessionProbe = game.session
	session._foundation_personal_cache = {"registry_revision": 3}
	assert_eq(game._queue_regional_ack(_intent()).get("status"), "pending")
	assert_eq(session.sent.size(), 0)
	session.reply({"registry_revision": 4})
	assert_eq(session.sent.size(), 1)
	assert_eq(session.sent[0].revision, 4)
	game.free()

func test_guest_empty_fresh_reply_sends_nothing() -> void:
	var game := _game(false)
	var session: SessionProbe = game.session
	game._queue_regional_ack(_intent())
	session.reply({})
	assert_eq(session.sent.size(), 0)
	game.free()

func test_host_sends_synchronously_and_refuses_without_a_view() -> void:
	var game := _game(true)
	var session: SessionProbe = game.session
	assert_eq(game._queue_regional_ack(_intent()).get("status"), "refused")
	assert_eq(session.sent.size(), 0)
	assert_true(game._regional_ack_intents.is_empty())
	session.host_view = {"registry_revision": 11}
	assert_eq(game._queue_regional_ack(_intent()).get("status"), "pending")
	assert_eq(session.sent.size(), 1)
	assert_eq(session.sent[0].revision, 11)
	game.free()
