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

## The ending context itself is covered by test_regional_homecoming; here the
## owner's "same ending, still owed" and "at Grandpa, safe" answers are set.
class GameProbe extends "res://autoload/game_state.gd":
	var owed := true
	var sendable := true
	func _regional_ack_still_owed(transaction_id: String) -> bool: return owed and _regional_ack_intents.has(transaction_id)
	func _regional_ack_sendable(_transaction_id: String) -> bool: return sendable

func _game(hosting: bool) -> Node:
	var game := GameProbe.new()
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

func test_guest_two_pending_stages_each_send_once_on_the_next_reply() -> void:
	var game := _game(false)
	var session: SessionProbe = game.session
	var credits := _intent()
	credits.stage = "regional_credits_seen"
	credits.transaction_id = "regional_ending:character-ack:regional_credits_seen"
	game._queue_regional_ack(_intent())
	game._queue_regional_ack(credits)
	session.reply({"registry_revision": 9})
	assert_eq(session.sent.size(), 2)
	var ids := session.sent.map(func(row: Dictionary) -> String: return row.intent.transaction_id)
	assert_true(ids.has(_intent().transaction_id))
	assert_true(ids.has(credits.transaction_id))
	session.reply({"registry_revision": 10})
	assert_eq(session.sent.size(), 2, "a later unrelated view reply resends nothing")
	game.free()

func test_guest_ack_no_longer_owed_is_forgotten_unsent() -> void:
	var game := _game(false)
	var session: SessionProbe = game.session
	game._queue_regional_ack(_intent())
	game.owed = false # Another party, character, world or session: a new presentation.
	session.reply({"registry_revision": 12})
	assert_eq(session.sent.size(), 0)
	assert_true(game._regional_ack_intents.is_empty())
	game.free()

func test_guest_waits_to_send_until_it_is_back_at_grandpa() -> void:
	var game := _game(false)
	var session: SessionProbe = game.session
	game._queue_regional_ack(_intent())
	game.sendable = false
	session.reply({"registry_revision": 12})
	assert_eq(session.sent.size(), 0, "the host would refuse away from Grandpa")
	assert_false(game._regional_ack_intents.is_empty(), "still owed: kept")
	game.free()

func test_guest_resends_on_a_fresh_view_while_the_caller_still_waits() -> void:
	var game := _game(false)
	var session: SessionProbe = game.session
	var tid: String = _intent().transaction_id
	game._queue_regional_ack(_intent())
	session.reply({"registry_revision": 5}) # Stale revision: the host refuses silently.
	assert_eq(session.sent.size(), 1)
	assert_eq(game.regional_ending_ack_result(tid).get("status"), "pending")
	assert_eq(session.sent.size(), 1, "no resend inside the resend interval")
	game._regional_ack_sent_at[tid] = Time.get_ticks_msec() - game.REGIONAL_ACK_RESEND_MS - 1
	assert_eq(game.regional_ending_ack_result(tid).get("status"), "pending")
	session.reply({"registry_revision": 6})
	assert_eq(session.sent.size(), 2)
	assert_eq(session.sent[1].revision, 6, "the resend uses the fresh view")
	# Past the guest window the game reads (ack_timeout_ms), not a fixed age.
	game._regional_ack_queued_at[tid] = Time.get_ticks_msec() \
		- preload("res://scripts/story/regional_homecoming.gd").ack_timeout_ms(game) - 1000
	game._regional_ack_sent_at[tid] = Time.get_ticks_msec() - game.REGIONAL_ACK_RESEND_MS - 1
	game._regional_ack_viewed_at.clear()
	game.regional_ending_ack_result(tid)
	session.reply({"registry_revision": 7})
	assert_eq(session.sent.size(), 2, "past the window the slower late cadence applies")
	game._regional_ack_sent_at[tid] = Time.get_ticks_msec() - game.REGIONAL_ACK_LATE_RESEND_MS - 1
	game._regional_ack_viewed_at.clear()
	game.regional_ending_ack_result(tid)
	session.reply({"registry_revision": 7})
	assert_eq(session.sent.size(), 3, "past the scene's window an owed ack still resends")
	game.owed = false
	game._regional_ack_sent_at[tid] = Time.get_ticks_msec() - game.REGIONAL_ACK_LATE_RESEND_MS - 1
	game._regional_ack_viewed_at.clear()
	game.regional_ending_ack_result(tid)
	session.reply({"registry_revision": 8})
	assert_eq(session.sent.size(), 3, "an ack no longer owed stops")
	game.free()

func test_guest_window_outlasts_the_host_window_for_a_slow_round_trip() -> void:
	var homecoming := preload("res://scripts/story/regional_homecoming.gd")
	var guest := _game(false)
	var host := _game(true)
	assert_true(homecoming.ack_timeout_ms(guest) > homecoming.ack_timeout_ms(host),
		"a guest's host round trip gets the longer window")
	assert_eq(homecoming.ack_timeout_ms(host), int(float(homecoming._settings().ack_timeout_seconds) * 1000.0))
	# CI 37298008163 shard 5: at ~1 fps the first view reply came after 8 s,
	# so the guest dropped its ack unsent. 12 s later it still sends.
	var session: SessionProbe = guest.session
	guest._queue_regional_ack(_intent())
	guest._regional_ack_waiting[_intent().transaction_id] = Time.get_ticks_msec() - 12000
	session.reply({"registry_revision": 9})
	assert_eq(session.sent.size(), 1, "a slow first reply inside the guest window still sends")
	guest.free()
	host.free()


class SettlingSession extends SessionProbe:
	var row: Dictionary = {}
	var commits := 0
	func _owner_training_row() -> Dictionary: return row.duplicate(true)
	func _training_decision(_peer: int, current: Dictionary) -> Dictionary:
		return {"ok": true, "saved": true} if current.get("action") == "regional_ack" else {}
	func _foundation_send(op: String, key: String, intent: Dictionary, revision: int) -> Dictionary:
		sent.append({"op": op, "key": key, "intent": intent.duplicate(true), "revision": revision})
		# The host journals one row per transaction id; a repeat returns it.
		if row.get("intent") != intent: commits += 1
		row = {"action": "regional_ack", "intent": intent.duplicate(true)}
		return {"ok": false, "resolved": false}

## Coordinator #4 design check: a guest whose presentation window expires
## before any reply (slow machine, ending transition) still has its
## homecoming settle, and exactly once.
func test_an_expired_guest_ack_still_settles_exactly_once() -> void:
	var game := GameProbe.new()
	game.reset_for_new_game()
	game.local.character_id = "character-ack"
	var session := SettlingSession.new()
	game.add_child(session)
	game.session = session
	var tid: String = _intent().transaction_id
	game._queue_regional_ack(_intent())
	# The scene's window passes with no reply at all.
	game._regional_ack_queued_at[tid] = Time.get_ticks_msec() - 120000
	game._regional_ack_waiting[tid] = Time.get_ticks_msec() - 120000
	session.reply({"registry_revision": 3})
	assert_eq(session.sent.size(), 1, "the late reply still sends the owed ack")
	assert_eq(session.commits, 1)
	game._regional_ack_tick_left = 0.0
	game._tick_orphaned_regional_acks(0.0)
	assert_true(game._regional_ack_intents.is_empty(), "settled: the background ack is done")
	for _i in 3:
		game._regional_ack_tick_left = 0.0
		game._tick_orphaned_regional_acks(0.0)
		session.reply({"registry_revision": 4})
	assert_eq(session.sent.size(), 1, "nothing is sent after it settles")
	assert_eq(session.commits, 1, "settled exactly once")
	game.free()


## Review: the real "still owed" decision, with only the ending's journey
## context stubbed.
class JourneyProbe extends "res://autoload/game_state.gd":
	var journey: Dictionary = {}
	var sendable := false
	func _regional_ack_journey() -> Dictionary: return journey.duplicate(true)
	func _regional_ack_sendable(_transaction_id: String) -> bool: return sendable

func _journey_game() -> JourneyProbe:
	var game := JourneyProbe.new()
	game.reset_for_new_game()
	game.local.character_id = "character-ack"
	var session := SessionProbe.new()
	game.add_child(session)
	game.session = session
	var intent := _intent()
	game.journey = {"homecoming_seen": false}
	for field: String in preload("res://scripts/story/regional_homecoming.gd").CONTEXT_FIELDS:
		game.journey[field] = intent.get(field)
	game._regional_ack_intents[intent.transaction_id] = intent
	return game

func test_still_owed_follows_the_same_ending_and_the_unsaved_stage() -> void:
	var game := _journey_game()
	var tid: String = _intent().transaction_id
	assert_true(game._regional_ack_still_owed(tid), "same ending, stage unsaved")
	for field: String in ["character_id", "world_instance_id", "session_epoch", "party_signature"]:
		var before: Variant = game.journey[field]
		game.journey[field] = "changed"
		assert_false(game._regional_ack_still_owed(tid), field + " changed: a new presentation")
		game.journey[field] = before
	game.journey.homecoming_seen = true
	assert_false(game._regional_ack_still_owed(tid), "the stage is already saved")
	game.journey = {}
	assert_false(game._regional_ack_still_owed(tid), "no ending context")
	game.free()

func test_an_owed_ack_away_from_grandpa_sends_no_view_requests() -> void:
	var game := _journey_game()
	var session: SessionProbe = game.session
	var tid: String = _intent().transaction_id
	game._regional_ack_queued_at[tid] = Time.get_ticks_msec() - 120000
	var before := session.view_requests
	for _i in 20:
		game._regional_ack_tick_left = 0.0
		game._tick_orphaned_regional_acks(0.0)
	assert_eq(session.view_requests, before, "unsendable past the window: no requests at all")
	game.sendable = true
	for _i in 20:
		game._regional_ack_tick_left = 0.0
		game._tick_orphaned_regional_acks(0.0)
		game._regional_ack_waiting.clear() # No reply arrives.
	assert_eq(session.view_requests, before + 1, "back at Grandpa: one request per late resend interval")
	assert_false(game._regional_ack_intents.is_empty(), "still owed")
	game.free()


class RetainedSession extends Node:
	var retained: Dictionary = {}
	func retained_training_transaction(actions: Array) -> Dictionary:
		return retained.duplicate(true) if actions == ["regional_ack"] else {}


func test_a_host_journalled_ack_is_waited_out_past_the_window() -> void:
	# f20_ending (guest, slow frame rate): the round trip took ~25 s, past the
	# 24 s window, after the host had durably journalled the acknowledgement.
	# The presentation gave up and credits never opened. The window bounds
	# reaching the host; once this exact intent is journalled it only settles.
	var homecoming := preload("res://scripts/story/regional_homecoming.gd")
	var game := GAME.new()
	var session := RetainedSession.new()
	game.session = session
	var intent := {"kind": "regional_ending_ack", "stage": homecoming.SEEN_FLAG, "transaction_id": "regional_ending:c:homecoming_seen"}
	assert_false(homecoming.ack_journalled(game, intent), "nothing journalled: the window still applies")
	session.retained = {"intent": intent.duplicate(true)}
	assert_true(homecoming.ack_journalled(game, intent), "this exact intent is the host's durable row")
	var credits := intent.duplicate(true)
	credits.stage = homecoming.CREDITS_SEEN_FLAG
	assert_false(homecoming.ack_journalled(game, credits), "another stage's row is not this acknowledgement")
	assert_false(homecoming.ack_journalled(game, {}), "an empty intent is never journalled")
	game.session = null
	assert_false(homecoming.ack_journalled(game, intent), "no session: the window applies")
	assert_true(homecoming.ack_settle_ceiling_ms() > homecoming.ack_timeout_ms(game),
		"a journalled ack still has a finite ceiling, past the reach window")
	session.free()
	game.free()


func test_an_ack_forgotten_because_its_stage_saved_still_reads_committed() -> void:
	# f20_ending (render f20-diag3-a): the waiting drain forgot a guest's ack
	# once homecoming_seen was saved, before Grandpa's scene polled it; the
	# scene read "refused" for a saved acknowledgement and credits never
	# opened. A forget because its own stage saved keeps the committed result.
	var game := _journey_game()
	var intent := _intent()
	game.journey.homecoming_seen = true
	game._forget_regional_ack(intent.transaction_id)
	var result: Dictionary = game.regional_ending_ack_result(intent.transaction_id)
	assert_eq(result.get("status"), "committed", "a saved ack is not refused")
	for field: String in intent:
		assert_eq(result.get(field), intent[field], "the committed result carries its original " + field)
	game.free()
	var unsaved := _journey_game()
	unsaved._forget_regional_ack(intent.transaction_id)
	assert_eq(unsaved.regional_ending_ack_result(intent.transaction_id).get("status"), "refused",
		"an ack forgotten unsaved (a new presentation) stays refused")
	unsaved.free()
	var moved := _journey_game()
	moved.journey.homecoming_seen = true
	moved.journey.session_epoch = "another_epoch"
	moved._forget_regional_ack(intent.transaction_id)
	assert_eq(moved.regional_ending_ack_result(intent.transaction_id).get("status"), "refused",
		"saved under a different ending is not this ack")
	moved.free()
