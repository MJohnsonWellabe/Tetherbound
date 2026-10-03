extends "res://tests/test_case.gd"

## Actual Altar service, panel controls, canonical read-only price planner and
## Session reply correlation. Physical station and quote-send/spend boundaries
## are doubles; no ENet, earned level, disk write or saved ACK is claimed.
const SERVICE := preload("res://scripts/ui/altar_service.gd")
const PANEL := preload("res://scripts/ui/altar_panel.gd")
const DATA := preload("res://tests/test_foundation_resources.gd")
const RECORD := preload("res://scripts/net/character_record_rules.gd")
const ESSENCE := preload("res://scripts/creatures/essence.gd")
const PROGRESSION := preload("res://scripts/creatures/progression.gd")
const STATION := "altar:meadows:quote-fixture"

class FixtureGame extends Node:
	var local: RefCounted
	var world: RefCounted
	var session: Node

class FixtureSession extends "res://scripts/net/session.gd":
	var fixture: Node
	var fixture_host := true
	var epoch := "a".repeat(32)
	var station := true
	var quote_record: Dictionary = {}
	var quote_revision := 7
	var inline_quote_reply := false
	var sent_quotes: Array[Dictionary] = []
	var spent: Dictionary = {}
	func _ready() -> void: pass # No physical transport or realm is started.
	func _game() -> Node: return fixture
	func is_host() -> bool: return fixture_host
	func _altar_current_epoch() -> String: return epoch
	func _local_character_id() -> String: return fixture.local.character_id
	func altar_station_available(_key: String) -> bool: return station
	func quote_altar_essence_spend(key: String, uid: String, quote_id: String) -> Dictionary:
		# Exactly the shipping three-argument contract. Only network send is
		# replaced; the guest's receiver below is the actual Session method.
		var envelope := _altar_envelope("altar_quote", key)
		envelope["owned_uid"] = uid
		envelope["quote_id"] = quote_id
		_altar_quote_request = envelope.duplicate(true)
		sent_quotes.append(envelope.duplicate(true))
		if inline_quote_reply:
			altar_essence_quote_completed.emit(key, uid, quote_id, price(uid))
			return {"ok": false, "pending": true, "code": "quote_pending"}
		return price(uid) if fixture_host else {"ok": false, "pending": true, "code": "quote_pending"}
	func price(uid: String) -> Dictionary:
		return ESSENCE.quote_spend(quote_record, fixture.local.character_id, uid,
			quote_revision, ESSENCE.config(), PROGRESSION.config())
	func deliver(envelope: Dictionary, result: Dictionary) -> void:
		_rpc_altar_quote_result(envelope, result)
	func submit_altar_essence_spend(key: String, intent: Dictionary) -> Dictionary:
		spent = {"station_key": key, "intent": intent.duplicate(true)}
		return {"ok": false, "resolved": false, "code": "fixture_no_write"}
	func reconcile_altar_essence_spend(_key: String, _intent: Dictionary) -> Dictionary:
		return {"ok": false, "resolved": false, "code": "fixture_no_write"}

class FixturePanel extends "res://scripts/ui/altar_panel.gd":
	var fixture_party: RefCounted
	var rebuilds := 0
	func _party() -> RefCounted: return fixture_party
	func _rebuild(prefer_payment: bool = false) -> void:
		rebuilds += 1
		super._rebuild(prefer_payment)

func _fixture(host: bool = true, two_creatures: bool = false) -> Dictionary:
	var game := FixtureGame.new()
	game.local = DATA.new()._player()
	game.world = DATA.new()._world()
	var first: RefCounted = game.local.party.at(0)
	first.set("level", 9)
	first.call("_apply_level_stats", PROGRESSION.config())
	game.local.inventory.add("essence_ground", 100)
	if two_creatures:
		game.local.party.add(preload("res://scripts/creatures/creature_species.gd").spawn("terrapup"))
	var session := FixtureSession.new()
	session.fixture_host = host
	session.fixture = game
	game.session = session
	session.quote_record = RECORD.portable_projection(game.local.save_data())
	assert_eq(RECORD.errors(session.quote_record, DATA.CHARACTER), [], "quote starts from a canonical retained owner")
	var holder := Node.new()
	holder.name = "AltarQuoteFixture_" + Crypto.new().generate_random_bytes(8).hex_encode()
	(Engine.get_main_loop() as SceneTree).root.add_child(holder)
	holder.add_child(session)
	holder.add_child(game)
	var service := SERVICE.new()
	service.set("_game", game)
	game.add_child(service)
	var panel := FixturePanel.new()
	panel.fixture_party = game.local.party
	service.add_child(panel)
	service.set("_panel", panel)
	assert_true(panel.configure_service(service))
	return {"holder": holder, "game": game, "session": session, "service": service,
		"panel": panel, "uid": str(first.uid)}

func _free_fixture(f: Dictionary) -> void:
	f.holder.free()

func _buttons(root: Node, label: String, enabled_only: bool = true) -> Array[Button]:
	var found: Array[Button] = []
	if root is Button and root.is_visible_in_tree() and root.text == label and (not enabled_only or not root.disabled): found.append(root)
	for child: Node in root.get_children(): found.append_array(_buttons(child, label, enabled_only))
	return found

func _has_ground_payment(f: Dictionary) -> bool:
	return _buttons(f.panel, "Ground Essence · Cost 20 · Have 100").size() == 1

func test_host_quote_uses_three_arguments_and_builds_actual_payment_without_mutating_owner() -> void:
	var f := _fixture()
	var before := var_to_bytes(f.session.quote_record)
	assert_true(f.service.open(STATION))
	assert_eq(f.session.sent_quotes.size(), 1)
	var request: Dictionary = f.session.sent_quotes[0]
	assert_true(f.session._altar_hex_id(request.quote_id))
	assert_eq(request.owned_uid, f.uid)
	assert_eq(request.station_key, STATION)
	assert_true(_has_ground_payment(f), "the shipping panel must expose the real quoted price")
	assert_eq(f.panel._quote.expected_character_revision, 7)
	assert_true(f.service._quote_pending.is_empty(), "a synchronous quote is consumed, not cached")
	assert_eq(var_to_bytes(f.session.quote_record), before)
	assert_true(f.game.world.reward_deliveries.is_empty())
	_free_fixture(f)

func test_guest_quote_rebuilds_from_correlated_actual_session_reply_once() -> void:
	var f := _fixture(false)
	assert_true(f.service.open(STATION))
	assert_false(_has_ground_payment(f))
	var request: Dictionary = f.session.sent_quotes[0]
	var quote: Dictionary = f.session.price(f.uid)
	assert_true(quote.get("ok") == true, str(quote))
	var rebuilds: int = f.panel.rebuilds
	f.session.deliver(request, quote)
	assert_true(_has_ground_payment(f))
	assert_eq(f.panel.rebuilds, rebuilds + 1)
	assert_eq(f.panel._quote, quote)
	assert_true(f.service._quote_pending.is_empty())
	f.session.altar_essence_quote_completed.emit(STATION, f.uid, request.quote_id, quote)
	assert_eq(f.panel.rebuilds, rebuilds + 1, "consumed replies cannot apply twice")
	assert_true(f.game.world.reward_deliveries.is_empty())
	_free_fixture(f)

func test_quote_rejects_wrong_id_key_uid_source_and_session_transport_scope() -> void:
	var f := _fixture(false)
	assert_true(f.service.open(STATION))
	var request: Dictionary = f.session.sent_quotes[0]
	var quote: Dictionary = f.session.price(f.uid)
	var rebuilds: int = f.panel.rebuilds
	for field: String in ["quote_id", "station_key", "owned_uid", "session_epoch", "character_id", "world_namespace"]:
		var forged := request.duplicate(true)
		forged[field] = "b".repeat(32) if field in ["quote_id", "session_epoch"] else "foreign"
		f.session.deliver(forged, quote)
		assert_eq(f.panel.rebuilds, rebuilds, field + " must fail Session correlation")
	f.session.altar_essence_quote_completed.emit(STATION, f.uid, "b".repeat(32), quote)
	f.session.altar_essence_quote_completed.emit("foreign", f.uid, request.quote_id, quote)
	f.session.altar_essence_quote_completed.emit(STATION, "foreign", request.quote_id, quote)
	var other := FixtureSession.new()
	f.service._on_session_quote_completed(STATION, f.uid, request.quote_id, quote, other)
	other.free()
	assert_eq(f.panel.rebuilds, rebuilds, "the UI bridge independently checks its exact correlation")
	assert_false(_has_ground_payment(f))
	f.session.deliver(request, quote)
	assert_true(_has_ground_payment(f), "refused foreign replies do not consume the current original")
	_free_fixture(f)

func test_inline_quote_signal_is_not_overwritten_by_pending_return() -> void:
	var f := _fixture(false)
	f.session.inline_quote_reply = true
	assert_true(f.service.open(STATION))
	assert_true(_has_ground_payment(f))
	assert_eq(f.panel._quote.expected_character_revision, 7)
	assert_false(f.panel._quote_waiting)
	assert_true(f.service._quote_pending.is_empty())
	_free_fixture(f)

func test_malformed_correlated_quote_never_enables_payment() -> void:
	var f := _fixture(false)
	assert_true(f.service.open(STATION))
	for defect: String in ["creature", "level", "revision", "payment", "duplicate_payment"]:
		if defect != "creature": f.panel._refresh_quote()
		var request: Dictionary = f.session.sent_quotes.back()
		var quote: Dictionary = f.session.price(f.uid)
		match defect:
			"creature": quote.creature_uid = "foreign"
			"level": quote.level = 61
			"revision": quote.expected_character_revision = -1
			"payment": quote.payments[0].cost = 0
			"duplicate_payment": quote.payments.append(quote.payments[0].duplicate(true))
		f.session.deliver(request, quote)
		assert_true(f.panel._quote.is_empty(), defect)
		assert_false(_has_ground_payment(f), defect)
		assert_true(f.session.spent.is_empty())
	_free_fixture(f)

func test_quote_rejects_same_session_new_epoch_or_changed_character_world_context() -> void:
	for field: String in ["epoch", "character", "world", "namespace", "local_object", "world_object", "session_object", "station"]:
		var f := _fixture(false)
		assert_true(f.service.open(STATION))
		var request: Dictionary = f.session.sent_quotes[0]
		var quote: Dictionary = f.session.price(f.uid)
		var rebuilds: int = f.panel.rebuilds
		var replacement: Node = null
		match field:
			"epoch": f.session.epoch = "b".repeat(32)
			"character": f.game.local.character_id = "other-owner"
			"world": f.game.world.world_id = "other-slot"
			"namespace": f.game.world.reward_delivery_namespace = "other-namespace"
			"local_object": f.game.local = DATA.new()._player()
			"world_object": f.game.world = DATA.new()._world()
			"session_object":
				replacement = FixtureSession.new()
				f.game.session = replacement
			"station": f.session.station = false
		# Model even a wrongly forwarded signal: UI fences supplement Session.
		f.session.altar_essence_quote_completed.emit(STATION, f.uid, request.quote_id, quote)
		assert_eq(f.panel.rebuilds, rebuilds, field)
		assert_true(f.panel._quote.is_empty(), field)
		assert_true(f.service._quote_pending.is_empty(), field + " invalidates the candidate")
		if replacement != null: replacement.free()
		_free_fixture(f)

func test_closed_reopened_or_reselected_panel_rejects_previous_quote() -> void:
	for change: String in ["close", "reopen", "same_selection", "other_selection"]:
		var f := _fixture(false, true)
		assert_true(f.service.open(STATION))
		var original: Dictionary = f.session.sent_quotes[0]
		var quote: Dictionary = f.session.price(f.uid)
		if change in ["close", "reopen"]:
			f.panel.close()
			assert_true(f.service._quote_pending.is_empty())
			if change == "reopen":
				f.panel._process(0.0)
				assert_true(f.service.open(STATION))
		else:
			f.panel._select_creature(f.uid if change == "same_selection" else str(f.game.local.party.at(1).uid))
		var rebuilds: int = f.panel.rebuilds
		f.session.altar_essence_quote_completed.emit(STATION, f.uid, original.quote_id, quote)
		assert_eq(f.panel.rebuilds, rebuilds, change)
		assert_true(f.panel._quote.is_empty(), change)
		if change != "close":
			var current: Dictionary = f.session.sent_quotes.back()
			assert_ne(current.quote_id, original.quote_id)
			f.session.deliver(current, f.session.price(current.owned_uid))
			assert_false(f.panel._quote.is_empty(), "the new open/selection still receives its own quote")
		_free_fixture(f)

func test_spend_keeps_original_five_fields_and_requests_fresh_quote_after_terminal_result() -> void:
	var f := _fixture(false)
	assert_true(f.service.open(STATION))
	var original: Dictionary = f.session.sent_quotes[0]
	f.session.deliver(original, f.session.price(f.uid))
	f.panel._spend("essence_ground")
	var intent: Dictionary = f.session.spent.intent
	assert_eq(intent.size(), 5, "no quote id, cost, balance or cap is sent as authority")
	assert_true(f.session._altar_hex_id(intent.spend_id))
	assert_eq(intent.creature_uid, f.uid)
	assert_eq(intent.expected_level, 9)
	assert_eq(intent.expected_character_revision, 7)
	assert_eq(intent.payment_item, "essence_ground")
	assert_eq(f.service._pending.request, intent, "the original transaction survives quote invalidation")
	assert_eq(f.panel._pending_id, intent.spend_id)
	assert_true(f.service._quote_pending.is_empty())
	assert_true(f.panel._quote.is_empty())
	f.service.invalidate_essence_quote()
	assert_eq(f.service._pending.request, intent)
	f.session.altar_essence_quote_completed.emit(STATION, f.uid, original.quote_id, f.session.price(f.uid))
	assert_true(f.panel._quote.is_empty(), "late quote cannot restore buttons during an original spend")
	# Explicit terminal refusal fixture: no journal/owner-save success claim.
	f.session.altar_essence_spend_completed.emit(STATION, intent.spend_id,
		{"ok": false, "resolved": true, "durable": false, "code": "fixture_refused"})
	assert_true(f.service._pending.is_empty())
	assert_eq(f.session.sent_quotes.size(), 2)
	var fresh: Dictionary = f.session.sent_quotes.back()
	assert_ne(fresh.quote_id, original.quote_id)
	f.session.deliver(fresh, f.session.price(f.uid))
	assert_true(_has_ground_payment(f))
	assert_true(f.game.world.reward_deliveries.is_empty())
	_free_fixture(f)
