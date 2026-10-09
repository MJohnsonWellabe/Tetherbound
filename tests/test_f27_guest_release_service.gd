extends "res://tests/test_case.gd"

## F27#1 guest release (scripts/net/essence_release_service.gd): the host may
## refuse the payout, never the release. A guest's request that the host
## refuses for any non-stale reason, or whose refreshed revision never changes,
## still frees the chosen creature locally with no payout; a refusal that lands
## while the owner guard is closed is retried until it opens. A refusal never
## yields a sixth or touches anything but the one released creature.
const SERVICE := preload("res://scripts/net/essence_release_service.gd")
const PARTY := preload("res://autoload/party.gd")
const SPECIES := preload("res://scripts/creatures/creature_species.gd")


class FakeSession extends Node:
	signal foundation_reply_received(envelope: Dictionary, result: Dictionary)
	var _foundation_personal_cache: Dictionary = {}
	var reply: Dictionary = {}
	var sent: int = 0
	func is_host() -> bool: return false
	func is_active() -> bool: return true
	func homestead_personal_view() -> Dictionary: return _foundation_personal_cache.duplicate(true)
	func request_essence_release(_pending_uid: String, _intent: Dictionary, _revision: int) -> Dictionary:
		sent += 1
		return reply.duplicate(true)


class FakeLocal extends RefCounted:
	var redesign_character := {"release_receipts": []}


class FakeGame extends Node:
	var pending_catch: RefCounted
	var party: RefCounted
	var local: RefCounted = FakeLocal.new()
	var session: Node
	var messages: Array[String] = []
	func push_world_message(text: String) -> void: messages.append(text)


var _blocked := false


func _setup(reply: Dictionary) -> Dictionary:
	var game := FakeGame.new()
	var session := FakeSession.new()
	session.reply = reply
	game.session = session
	var party: RefCounted = PARTY.new()
	party.call("bind_owner_mutation_guard", func() -> bool: return _blocked)
	for i in 5: party.call("add", SPECIES.spawn("terrapup"))
	game.party = party
	var rows: Array = []
	for creature: RefCounted in party.call("members"):
		rows.append({"uid": str(creature.get("uid")), "species_id": "terrapup", "creature_type": "ground", "secondary_type": "", "level": 5})
	session._foundation_personal_cache = {"party": rows, "registry_revision": 7}
	game.pending_catch = SPECIES.spawn("bramblebun")
	var service: Node = SERVICE.new()
	service._game = game
	var results: Array = []
	service.release_completed.connect(func(id: String, result: Dictionary) -> void: results.append(result))
	return {"game": game, "session": session, "service": service, "results": results, "party": party}


func _submit(fixture: Dictionary) -> String:
	var game: FakeGame = fixture.game
	var released := str((fixture.party as RefCounted).call("at", 0).get("uid"))
	var id := "release-%d" % randi()
	assert_true(fixture.service.call("owns_pending_capture", game.pending_catch), "the guest service owns a full-belt ordinary catch")
	fixture.service.call("submit_release", {"release_id": id, "pending_uid": str(game.pending_catch.get("uid")),
		"released_uid": released, "expected_character_revision": 7})
	return released


func _tick(fixture: Dictionary, frames: int) -> void:
	for i in frames: fixture.service.call("_process", 0.016)


func _free(fixture: Dictionary) -> void:
	_blocked = false
	(fixture.service as Node).free()
	(fixture.session as Node).free()
	(fixture.game as Node).free()


func _assert_released_unpaid(fixture: Dictionary, released: String, label: String) -> void:
	var game: FakeGame = fixture.game
	var party: RefCounted = fixture.party
	var owned: Array = []
	for creature: RefCounted in party.call("members"): owned.append(str(creature.get("uid")))
	assert_eq(int(party.call("size")), 5, label + ": still exactly five")
	assert_false(owned.has(released), label + ": the chosen creature went free")
	assert_true(game.pending_catch == null, label + ": the newcomer joined")
	assert_eq((fixture.results as Array).size(), 1, label + ": one completion")
	var result: Dictionary = (fixture.results as Array)[0] if not (fixture.results as Array).is_empty() else {}
	assert_true(result.get("ok") == true and result.get("resolved") == true and not str(result.get("unpaid_reason", "")).is_empty(),
		label + ": completed unpaid with a reason " + str(result))


func test_a_terminal_ceremony_refusal_releases_unpaid() -> void:
	var fixture := _setup({"ok": false, "resolved": true, "terminal_refusal": true, "code": "release_ceremony_unavailable"})
	var released := _submit(fixture)
	_tick(fixture, 2)
	_assert_released_unpaid(fixture, released, "ceremony unavailable")
	_free(fixture)


func test_an_unchanging_stale_refusal_releases_unpaid_after_the_bound() -> void:
	var fixture := _setup({"ok": false, "resolved": true, "terminal_refusal": true, "code": "source_or_revision_changed"})
	var released := _submit(fixture)
	_tick(fixture, 10)
	assert_eq((fixture.results as Array).size(), 0, "waits for a fresh revision first")
	_tick(fixture, SERVICE.REFRESH_FRAMES + 5)
	_assert_released_unpaid(fixture, released, "revision never refreshed")
	assert_eq(int(fixture.session.sent), 1, "no resend against the same revision")
	_free(fixture)


func test_a_refusal_while_the_owner_guard_is_closed_retries_until_it_opens() -> void:
	var fixture := _setup({"ok": false, "resolved": false, "code": "owner_passive_recording_unavailable"})
	_blocked = true
	var released := _submit(fixture)
	_tick(fixture, 30)
	assert_eq((fixture.results as Array).size(), 0, "nothing happens while the owner guard is closed")
	assert_true(fixture.game.pending_catch != null, "the catch stays parked, not lost")
	_blocked = false
	_tick(fixture, 2)
	_assert_released_unpaid(fixture, released, "guard reopened")
	_free(fixture)


func test_a_saved_host_row_finishes_paid_and_is_never_also_released_unpaid() -> void:
	var fixture := _setup({"ok": false, "resolved": false, "durable": true, "code": "awaiting_saved_decision"})
	var released := _submit(fixture)
	_tick(fixture, 5)
	assert_eq((fixture.results as Array).size(), 0, "waits for the owner's saved row")
	# The owner applies the host row: the creature leaves with its receipt.
	var party: RefCounted = fixture.party
	party.call("remove_at", 0)
	fixture.game.local.redesign_character.release_receipts.append("release:" + released)
	_tick(fixture, 2)
	assert_eq(int(party.call("size")), 5, "the newcomer took the freed holder")
	assert_true(fixture.game.pending_catch == null)
	var result: Dictionary = (fixture.results as Array)[0]
	assert_true(result.get("ok") == true and not result.has("unpaid_reason"), "completed as the paid release " + str(result))
	assert_eq(fixture.game.messages.size(), 0, "no unpaid message")
	_free(fixture)
