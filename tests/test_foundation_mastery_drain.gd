extends "res://tests/test_case.gd"

## F44/F19 (coordinator ruling 2026-10-11): a long fight leaves ~100 queued
## combat_mastery duties for one character. Each still commits as its own row
## and receipt and settles one at a time (its owner apply is deferred to the
## next frame); while one is settling the scan reports a backlog and
## FoundationComposition rescans after multiplayer.json
## session.foundation_backlog_scan_interval_s instead of 1 s. Real retry scan,
## ledger, authority, owner apply and disk writer; the deferred owner apply is
## invoked here exactly as ledger_rpc's creature_training_settle op calls it.
const DATA := preload("res://tests/test_foundation_resources.gd")
const SAVE := preload("res://tests/test_foundation_resource_save.gd")
const MASTERY := preload("res://tests/test_combat_mastery_delivery.gd")
const RECORD := preload("res://scripts/net/character_record_rules.gd")
const AUTHORITY := preload("res://scripts/net/character_authority.gd")
const DUTIES := 100

class DrainSession extends SAVE.FixtureSession:
	func _retry_combat_mastery_sources() -> void: pass
	func _altar_peer_in_combat(_peer: int) -> bool: return false
	func _ordinary_round_pending_characters() -> Dictionary: return {}
	func admitted_character_state(peer: int) -> Dictionary:
		return get("_character_authority").call("state", _authority_character(peer))
	## Named seam: no deployed actor bodies exist in a unit fixture, so the
	## host's actor-vitals baseline has nothing to propose for a mastery row.
	func _training_actor_baseline_proposals(_peer: int, _row: Dictionary) -> Dictionary:
		return {"ok": true, "proposals": [], "admitted": {}, "revision": 0}
	func _cfg(key: String, fallback: Variant) -> Variant:
		var shipped: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/multiplayer.json"))
		return shipped.get("session", {}).get(key, fallback) if shipped is Dictionary else fallback


func _receipt(action_id: String) -> String:
	return "craft:combat_mastery_%s:%s" % [action_id.sha256_text(), DATA.CHARACTER]


func _mastery_duty(before: Dictionary, index: int) -> Dictionary:
	var duty: Dictionary = MASTERY.new()._duty(before)
	var action_id := "drain-hit-%03d" % index
	duty.intent.action_id = action_id
	duty.context.source_key = "combat_mastery:" + action_id
	duty.context.outcome.action_id = action_id
	return duty


func _owned_receipts(game: Node) -> Array:
	return (RECORD.portable_projection(game.local.save_data()).redesign_character.transaction_receipts as Array) \
		.filter(func(r: Variant) -> bool: return str(r).begins_with("craft:combat_mastery_"))


func _scan(session: Node, rpc: Node, game: Node) -> bool:
	session._retry_foundation_events()
	var backlog: bool = session.get("foundation_backlog") == true
	var id := preload("res://scripts/creatures/essence.gd").training_delivery_id(game.world.reward_delivery_namespace, DATA.CHARACTER)
	var latest: Variant = game.world.reward_deliveries.get(id)
	if latest is Dictionary and latest.get("status") == "pending":
		rpc._process_creature_training(latest.duplicate(true)) # The deferred owner apply.
	return backlog


func test_a_long_fights_mastery_queue_drains_one_row_per_short_rescan_each_receipt_once_in_order_across_a_reload() -> void:
	var fixture := DATA.new()
	var directory := "user://test_mastery_drain_%s/" % Crypto.new().generate_random_bytes(12).hex_encode()
	var game := SAVE.FixtureGame.new()
	game.local = fixture._player()
	game.world = fixture._world()
	var session := DrainSession.new()
	session.fixture = game
	game.session = session
	var authority := AUTHORITY.new()
	session.set("_character_authority", authority)
	var writer := SAVE.BoolWriter.new()
	writer.world_store = preload("res://scripts/save/world_save.gd").new(directory.path_join("worlds"))
	writer.character_store = preload("res://scripts/save/character_save.gd").new(directory.path_join("characters"))
	game.save_system = writer
	var rpc := SAVE.FixtureRpc.new()
	rpc.name = "LedgerRpc"
	rpc.fixture = game
	rpc.ledger = preload("res://scripts/net/world_ledger.gd").new(game.world)
	session.add_child(rpc)
	session.get("_registry").call("add", 1, DATA.CHARACTER)
	var before := RECORD.portable_projection(game.local.save_data())
	assert_true(authority.bind_world("resource-namespace"))
	assert_true(authority.seed_admitted_character(before, DATA.CHARACTER).ok)
	assert_true(writer.save_world_prepared(game, "resource-slot"))
	assert_true(writer.save_character_prepared(game, DATA.CHARACTER))
	var expected: Array[String] = []
	for index in DUTIES:
		var duty := _mastery_duty(before, index)
		var journal: Dictionary = rpc.journal_foundation_event("mastery:" + str(duty.intent.action_id), [duty])
		assert_true(journal.get("durable") == true, "duty %d journals: %s" % [index, str(journal)])
		expected.append(_receipt(str(duty.intent.action_id)))
	var interval := float(session._cfg("foundation_backlog_scan_interval_s", 1.0))
	assert_true(interval * DUTIES <= 30.0, "a %d-duty drain at the shipped %.2f s backlog interval clears within 30 s" % [DUTIES, interval])
	# Three scans, then a reload from disk mid-drain.
	for _i in 3: assert_true(_scan(session, rpc, game), "a scan that committed a still-settling duty reports a backlog")
	var mid := _owned_receipts(game)
	assert_eq(mid, expected.slice(0, 3), "one duty settles per scan, in duty order")
	assert_true(writer.save_world_prepared(game, "resource-slot"))
	game.world.load_data(writer.world_store.call("read", "resource-slot"))
	game.local.load_data(writer.character_store.call("read", DATA.CHARACTER))
	authority = AUTHORITY.new()
	session.set("_character_authority", authority)
	assert_true(authority.bind_world("resource-namespace"))
	assert_true(authority.seed_admitted_character(RECORD.portable_projection(game.local.save_data()), DATA.CHARACTER).ok)
	# As session.admitted_character_state does after a load.
	assert_true(authority.recover_durable_training(DATA.CHARACTER, game.world.reward_deliveries).get("ok") == true)
	rpc.ledger = preload("res://scripts/net/world_ledger.gd").new(game.world)
	# After a reload the scan's order is FOUNDATION_RETRY_ORDER over the reloaded
	# world (its delivery order); the drain must follow exactly that order.
	var resumed: Array[String] = expected.slice(0, 3)
	for work: Dictionary in preload("res://scripts/net/foundation_retry_order.gd").ordered(
			game.world.reward_deliveries, game.world.reward_delivery_namespace, game.world.world_id):
		var r := _receipt(str(work.duty.intent.action_id))
		if work.duty.action == "combat_mastery" and not resumed.has(r): resumed.append(r)
	var scans := 3
	while scans < DUTIES + 5 and _owned_receipts(game).size() < DUTIES:
		_scan(session, rpc, game)
		scans += 1
	var owned := _owned_receipts(game)
	assert_eq(owned.size(), DUTIES, "the whole queue drains, one row per backlog scan (%d scans)" % scans)
	assert_true(scans <= DUTIES + 1, "no scan is wasted beyond the reload's one (%d)" % scans)
	assert_eq(owned, resumed, "every receipt exactly once, in the scan's retry order, across the reload")
	var unique := {}
	for r: String in owned: unique[r] = true
	assert_eq(unique.size(), DUTIES, "no receipt is duplicated or dropped")
	assert_false(_scan(session, rpc, game), "an empty queue reports no backlog")
	assert_eq(_owned_receipts(game), resumed, "a further scan pays nothing again")
	SAVE.new()._close(game, rpc, directory)
