extends "res://tests/test_case.gd"

## Pure logic for the paid Water dock debit escrow (F15 paid-debit crash/retry).
## No scenes, no saves: "crash" is modelled by dropping in-memory state and
## continuing from the last persisted character/world data.

const DEBIT := preload("res://scripts/net/water_dock_debit.gd")
const INVENTORY := preload("res://autoload/inventory.gd")
const ITEM_DB := preload("res://autoload/item_db.gd")

const WORLD := "world-instance-a"
const OTHER_WORLD := "world-instance-b"
const ACTION := "reedhaven_repair"
const COST := {"reed_fiber": 6, "driftwood": 4}


class FakeBag extends RefCounted:
	var items: Dictionary = {}
	var capacity := 1000000
	func count(id: String) -> int:
		return int(items.get(id, 0))
	func total() -> int:
		var n := 0
		for key: String in items:
			n += int(items[key])
		return n
	func add(id: String, n: int) -> int:
		var put := mini(n, maxi(0, capacity - total()))
		if put > 0:
			items[id] = count(id) + put
		return n - put
	func remove(id: String, n: int) -> bool:
		if count(id) < n:
			return false
		items[id] = count(id) - n
		return true


func _state(character: String, reed: int, wood: int) -> Dictionary:
	var bag := FakeBag.new()
	bag.items = {"reed_fiber": reed, "driftwood": wood}
	return {"character_id": character, "escrow": {}, "inventory": bag}


func _receipt(txn: String, payer: String, world: String = WORLD) -> Dictionary:
	return {"action_id": ACTION, "world_instance_id": world, "txn_id": txn, "payer_character_id": payer}


## JSON round trip = what a character save/load does to the escrow map.
func _persisted(state: Dictionary) -> Dictionary:
	var text := JSON.stringify(state.escrow)
	var back: Variant = JSON.parse_string(text)
	return {"character_id": state.character_id, "escrow": back, "inventory": state.inventory}


func test_txn_id_is_deterministic_and_scoped() -> void:
	var a := DEBIT.txn_id(WORLD, ACTION, "cid-1")
	assert_eq(a, DEBIT.txn_id(WORLD, ACTION, "cid-1"))
	assert_eq(a.length(), 64)
	assert_ne(a, DEBIT.txn_id(OTHER_WORLD, ACTION, "cid-1"))
	assert_ne(a, DEBIT.txn_id(WORLD, ACTION, "cid-2"))
	assert_ne(a, DEBIT.txn_id(WORLD, ACTION, "cid-1", 2))
	assert_eq(DEBIT.txn_id("", ACTION, "cid-1"), "")


func test_begin_reserves_exact_cost_and_refuses_second_begin() -> void:
	var s := _state("cid-1", 9, 5)
	var r := DEBIT.begin(s, ACTION, COST, WORLD)
	assert_true(r.ok and r.changed, "begin reserves")
	assert_eq(s.inventory.count("reed_fiber"), 3)
	assert_eq(s.inventory.count("driftwood"), 1)
	var row: Dictionary = s.escrow[r.txn_id]
	assert_eq(row.cost, {"reed_fiber": 6, "driftwood": 4})
	assert_eq(row.status, "pending")
	assert_eq(r.intent, {"txn_id": r.txn_id, "world_instance_id": WORLD})
	var again := DEBIT.begin(s, ACTION, COST, WORLD)
	assert_false(again.ok, "second begin refused")
	assert_eq(again.code, "already_pending")
	assert_false(again.changed)
	assert_eq(s.inventory.count("reed_fiber"), 3, "no second reserve")
	assert_eq(s.escrow.size(), 1)


func test_insufficient_items_change_nothing() -> void:
	var s := _state("cid-1", 6, 3)
	var r := DEBIT.begin(s, ACTION, COST, WORLD)
	assert_false(r.ok)
	assert_eq(r.code, "materials")
	assert_eq(s.inventory.count("reed_fiber"), 6)
	assert_eq(s.inventory.count("driftwood"), 3)
	assert_true(s.escrow.is_empty())
	assert_eq(DEBIT.begin(s, ACTION, {}, WORLD).code, "no_cost")
	assert_eq(DEBIT.begin(s, ACTION, COST, "").code, "malformed")
	assert_eq(DEBIT.begin(s, ACTION, {"reed_fiber": -1}, WORLD).code, "no_cost")
	assert_true(s.escrow.is_empty())


func test_crash_after_world_save_reconcile_settles_once() -> void:
	var s := _state("cid-1", 6, 4)
	var txn: String = DEBIT.begin(s, ACTION, COST, WORLD).txn_id
	# Host saved the world receipt; the client crashed before settle/save.
	var loaded := _persisted(s)
	var facts := {ACTION: _receipt(txn, "cid-1")}
	var r := DEBIT.reconcile(loaded, facts, WORLD)
	assert_true(r.changed)
	assert_eq(r.settled, [txn])
	assert_eq(loaded.escrow[txn].status, "settled")
	assert_false(loaded.escrow[txn].has("cost"))
	assert_eq(loaded.inventory.count("reed_fiber"), 0, "items consumed")
	var again := DEBIT.reconcile(loaded, facts, WORLD)
	assert_false(again.changed, "reconcile idempotent")
	assert_eq(loaded.inventory.count("reed_fiber"), 0)
	assert_eq(DEBIT.begin(loaded, ACTION, COST, WORLD).code, "already_paid")


func test_crash_before_world_save_reconcile_resubmits_never_refunds() -> void:
	var s := _state("cid-1", 6, 4)
	var txn: String = DEBIT.begin(s, ACTION, COST, WORLD).txn_id
	var loaded := _persisted(s)
	var r := DEBIT.reconcile(loaded, {}, WORLD)
	assert_false(r.changed, "absence never refunds")
	assert_eq(r.needs_submit, [txn])
	assert_eq(r.refunded, [])
	assert_eq(loaded.escrow[txn].status, "pending")
	assert_eq(loaded.inventory.count("reed_fiber"), 0)
	# The resubmit hits a host whose save fails: explicit, allow-listed refusal.
	var refused := DEBIT.refund(loaded, {"txn_id": txn, "world_instance_id": WORLD, "code": "journal_failed"})
	assert_true(refused.changed)
	assert_eq(loaded.escrow[txn].status, "refunded")
	assert_eq(loaded.escrow[txn].reason, "journal_failed")
	assert_eq(loaded.inventory.count("reed_fiber"), 6)
	assert_eq(loaded.inventory.count("driftwood"), 4)
	assert_true(loaded.inventory.items["reed_fiber"] is int, "refund adds exact ints after JSON load")
	var again := DEBIT.reconcile(loaded, {}, WORLD)
	assert_false(again.changed)
	assert_eq(again.needs_submit, [])
	assert_eq(loaded.inventory.count("reed_fiber"), 6, "refunded once")


func test_in_flight_race_poll_before_host_commit_never_refunds() -> void:
	var s := _state("cid-1", 6, 4)
	var txn: String = DEBIT.begin(s, ACTION, COST, WORLD).txn_id
	# Guest submitted; a reconcile runs before the host commits.
	var early := DEBIT.reconcile(s, {}, WORLD, [txn])
	assert_false(early.changed)
	assert_eq(early.waiting, [txn], "in-flight absence waits")
	assert_eq(early.needs_submit, [])
	assert_eq(s.escrow[txn].status, "pending")
	assert_eq(DEBIT.reconcile(s, {}, WORLD).needs_submit, [txn], "not in flight -> resubmit, still no refund")
	assert_eq(s.inventory.count("reed_fiber"), 0)
	# Host commits: the receipt settles it, no free repair.
	var done := DEBIT.reconcile(s, {ACTION: _receipt(txn, "cid-1")}, WORLD, [txn])
	assert_eq(done.settled, [txn])
	assert_eq(s.inventory.count("reed_fiber"), 0)
	assert_eq(s.inventory.count("driftwood"), 0)


func test_resubmitted_committed_txn_refused_too_far_never_refunds() -> void:
	var s := _state("cid-1", 6, 4)
	var txn: String = DEBIT.begin(s, ACTION, COST, WORLD).txn_id
	for code: String in ["too_far", "wrong_realm", "unknown_character", "unknown_action", "malformed", "busy", ""]:
		var r := DEBIT.refund(s, {"txn_id": txn, "world_instance_id": WORLD, "code": code})
		assert_false(r.changed, "no refund for " + code)
		assert_eq(r.code, "retry_later", code)
	assert_eq(s.escrow[txn].status, "pending")
	assert_eq(s.inventory.count("reed_fiber"), 0)
	# The host answers the next resubmit from its stored receipt.
	var own := DEBIT.refund(s, {"txn_id": txn, "world_instance_id": WORLD, "code": "already_done",
		"receipt": _receipt(txn, "cid-1")})
	assert_eq(own.code, "paid_by_this_txn")
	assert_eq(s.escrow[txn].status, "settled")
	assert_eq(s.inventory.count("reed_fiber"), 0)


func test_allow_listed_refusal_refunds_once() -> void:
	for code: String in DEBIT.REFUND_CODES:
		var s := _state("cid-1", 6, 4)
		var txn: String = DEBIT.begin(s, ACTION, COST, WORLD).txn_id
		var reason := {"txn_id": txn, "world_instance_id": WORLD, "code": code}
		var r := DEBIT.refund(s, reason)
		assert_true(r.ok and r.changed, "refund on " + code)
		assert_eq(s.escrow[txn].status, "refunded")
		assert_eq(s.inventory.count("reed_fiber"), 6)
		var again := DEBIT.refund(s, reason)
		assert_false(again.changed)
		assert_eq(again.code, "already_refunded")
		assert_eq(s.inventory.count("reed_fiber"), 6, "once only: " + code)
	assert_eq(DEBIT.REFUND_CODES, ["materials", "prerequisite", "journal_failed"])


func test_refund_due_retried_in_another_world() -> void:
	var s := _state("cid-1", 6, 4)
	var txn: String = DEBIT.begin(s, ACTION, COST, WORLD).txn_id
	s.inventory.items = {"stone": 5}
	s.inventory.capacity = 5
	assert_eq(DEBIT.refund(s, {"txn_id": txn, "world_instance_id": WORLD, "code": "materials"}).code, "no_room")
	assert_eq(s.escrow[txn].status, "refund_due")
	s.inventory.capacity = 1000
	var loaded := _persisted(s)
	var r := DEBIT.reconcile(loaded, {}, OTHER_WORLD)
	assert_eq(r.refunded, [txn], "owed items return in any world")
	assert_eq(loaded.escrow[txn].status, "refunded")
	assert_eq(loaded.inventory.count("reed_fiber"), 6)
	assert_eq(loaded.inventory.count("driftwood"), 4)
	assert_false(DEBIT.reconcile(loaded, {}, OTHER_WORLD).changed)
	# Pending rows keep wrong-world protection.
	var p: String = DEBIT.begin(loaded, "other_paid", COST, WORLD).txn_id
	var other := DEBIT.reconcile(loaded, {}, OTHER_WORLD)
	assert_false(other.changed)
	assert_eq(other.needs_submit, [])
	assert_eq(loaded.escrow[p].status, "pending")


func test_restored_world_allows_new_attempt_after_settled_tombstone() -> void:
	var s := _state("cid-1", 12, 8)
	var first: String = DEBIT.begin(s, ACTION, COST, WORLD).txn_id
	assert_true(DEBIT.settle(s, _receipt(first, "cid-1")).changed)
	assert_eq(DEBIT.begin(s, ACTION, COST, WORLD).code, "already_paid", "no facts: conservative block")
	assert_eq(DEBIT.begin(s, ACTION, COST, WORLD, {ACTION: _receipt(first, "cid-1")}).code, "already_paid")
	assert_eq(s.inventory.count("reed_fiber"), 6)
	# Host world restored to before the repair: the action fact is absent.
	var retry := DEBIT.begin(s, ACTION, COST, WORLD, {})
	assert_true(retry.ok and retry.changed)
	assert_eq(retry.txn_id, DEBIT.txn_id(WORLD, ACTION, "cid-1", 2))
	assert_eq(s.escrow[retry.txn_id].attempt, 2)
	assert_eq(s.escrow[first].status, "settled", "old tombstone kept")
	assert_eq(s.inventory.count("reed_fiber"), 0)
	assert_eq(DEBIT.begin(s, ACTION, COST, WORLD, {}).code, "already_pending")


func test_retry_after_refund_starts_fresh_txn() -> void:
	var s := _state("cid-1", 6, 4)
	var first: String = DEBIT.begin(s, ACTION, COST, WORLD).txn_id
	assert_true(DEBIT.refund(s, {"txn_id": first, "world_instance_id": WORLD, "code": "journal_failed"}).changed)
	var retry := DEBIT.begin(s, ACTION, COST, WORLD)
	assert_true(retry.ok)
	assert_ne(retry.txn_id, first)
	assert_eq(retry.txn_id, DEBIT.txn_id(WORLD, ACTION, "cid-1", 2))
	assert_eq(s.escrow[retry.txn_id].attempt, 2)
	assert_eq(s.inventory.count("reed_fiber"), 0)
	# The world receipt names the retry, so the old tombstone stays refunded.
	var r := DEBIT.reconcile(s, {ACTION: _receipt(retry.txn_id, "cid-1")}, WORLD)
	assert_eq(r.settled, [retry.txn_id])
	assert_eq(s.escrow[first].status, "refunded")
	assert_eq(s.inventory.count("reed_fiber"), 0)


func test_duplicate_settle_and_refund_are_noops() -> void:
	var s := _state("cid-1", 12, 8)
	var paid: String = DEBIT.begin(s, ACTION, COST, WORLD).txn_id
	var receipt := _receipt(paid, "cid-1")
	assert_true(DEBIT.settle(s, receipt).changed)
	var dup := DEBIT.settle(s, receipt)
	assert_true(dup.ok)
	assert_false(dup.changed)
	assert_eq(dup.code, "already_settled")
	var late := DEBIT.refund(s, {"txn_id": paid, "world_instance_id": WORLD, "code": "journal_failed"})
	assert_false(late.changed, "settled row never refunds")
	assert_eq(s.inventory.count("reed_fiber"), 6)
	var t := _state("cid-1", 6, 4)
	var txn: String = DEBIT.begin(t, "other_paid", COST, WORLD).txn_id
	var reason := {"txn_id": txn, "world_instance_id": WORLD, "code": "journal_failed"}
	assert_true(DEBIT.refund(t, reason).changed)
	var again := DEBIT.refund(t, reason)
	assert_false(again.changed)
	assert_eq(again.code, "already_refunded")
	assert_eq(t.inventory.count("reed_fiber"), 6)
	assert_false(DEBIT.settle(t, {"action_id": "other_paid", "world_instance_id": WORLD,
		"txn_id": txn, "payer_character_id": "cid-1"}).changed, "refunded row never settles")
	assert_eq(t.inventory.count("reed_fiber"), 6)


func test_wrong_world_never_settles_or_refunds() -> void:
	var s := _state("cid-1", 6, 4)
	var txn: String = DEBIT.begin(s, ACTION, COST, WORLD).txn_id
	assert_false(DEBIT.settle(s, _receipt(txn, "cid-1", OTHER_WORLD)).changed)
	assert_eq(DEBIT.refund(s, {"txn_id": txn, "world_instance_id": OTHER_WORLD, "code": "prerequisite"}).code, "wrong_world")
	assert_eq(DEBIT.refund(s, {"txn_id": txn, "world_instance_id": WORLD, "code": "wrong_world"}).code, "wrong_world")
	var r := DEBIT.reconcile(s, {}, OTHER_WORLD)
	assert_false(r.changed, "foreign world absence is not authoritative")
	var foreign := DEBIT.reconcile(s, {ACTION: _receipt(txn, "cid-1", OTHER_WORLD)}, WORLD)
	assert_false(foreign.changed, "foreign receipt in this world's facts is left alone")
	assert_eq(foreign.waiting, [txn])
	assert_eq(s.escrow[txn].status, "pending")
	assert_eq(s.inventory.count("reed_fiber"), 0)


func test_receipt_paid_by_other_character_refunds_this_row() -> void:
	var s := _state("cid-1", 6, 4)
	var mine: String = DEBIT.begin(s, ACTION, COST, WORLD).txn_id
	var theirs := DEBIT.txn_id(WORLD, ACTION, "cid-2")
	# Guest cid-2 won the race: settling on their receipt must not consume ours.
	assert_false(DEBIT.settle(s, _receipt(theirs, "cid-2")).changed)
	assert_false(DEBIT.settle(s, _receipt(mine, "cid-2")).changed, "payer must be this character")
	var r := DEBIT.reconcile(s, {ACTION: _receipt(theirs, "cid-2")}, WORLD)
	assert_eq(r.refunded, [mine])
	assert_eq(s.escrow[mine].reason, "paid_by_other")
	assert_eq(s.inventory.count("reed_fiber"), 6)
	assert_eq(s.inventory.count("driftwood"), 4)


func test_already_done_refusal_needs_receipt_and_never_refunds_own_payment() -> void:
	var s := _state("cid-1", 6, 4)
	var txn: String = DEBIT.begin(s, ACTION, COST, WORLD).txn_id
	var bare := DEBIT.refund(s, {"txn_id": txn, "world_instance_id": WORLD, "code": "already_done"})
	assert_eq(bare.code, "needs_receipt")
	assert_false(bare.changed)
	var foreign := DEBIT.refund(s, {"txn_id": txn, "world_instance_id": WORLD, "code": "already_done",
		"receipt": _receipt("not-a-real-txn", "", OTHER_WORLD)})
	assert_eq(foreign.code, "needs_receipt", "a receipt that proves nothing decides nothing")
	# A lost ack then a retry: host says already_done, receipt names our txn.
	var own := DEBIT.refund(s, {"txn_id": txn, "world_instance_id": WORLD, "code": "already_done",
		"receipt": _receipt(txn, "cid-1")})
	assert_eq(own.code, "paid_by_this_txn")
	assert_eq(s.escrow[txn].status, "settled")
	assert_eq(s.inventory.count("reed_fiber"), 0)


func test_refund_without_room_stays_owed_until_room() -> void:
	var s := _state("cid-1", 6, 4)
	var txn: String = DEBIT.begin(s, ACTION, COST, WORLD).txn_id
	s.inventory.items = {"stone": 5}
	s.inventory.capacity = 8
	var r := DEBIT.refund(s, {"txn_id": txn, "world_instance_id": WORLD, "code": "prerequisite"})
	assert_eq(r.code, "no_room")
	assert_eq(s.escrow[txn].status, "refund_due")
	assert_eq(s.inventory.total(), 8)
	var owed := 0
	for key: String in s.escrow[txn].cost:
		owed += int(s.escrow[txn].cost[key])
	assert_eq(owed, 7, "exactly the unreturned remainder is journaled")
	s.inventory.capacity = 1000
	var loaded := _persisted(s)
	var done := DEBIT.reconcile(loaded, {ACTION: _receipt(txn, "cid-1")}, WORLD)
	assert_eq(done.refunded, [txn], "refund_due finishes; a late receipt cannot flip it")
	assert_eq(loaded.inventory.count("reed_fiber"), 6)
	assert_eq(loaded.inventory.count("driftwood"), 4)


func test_rows_roundtrip_as_plain_json() -> void:
	var s := _state("cid-1", 6, 4)
	var txn: String = DEBIT.begin(s, ACTION, COST, WORLD).txn_id
	var text := JSON.stringify(s.escrow)
	var back: Variant = JSON.parse_string(text)
	assert_true(back is Dictionary)
	var row: Dictionary = back[txn]
	for key: String in row:
		var v: Variant = row[key]
		assert_true(typeof(v) in [TYPE_STRING, TYPE_FLOAT, TYPE_INT, TYPE_DICTIONARY], "json-safe " + key)
	assert_eq(DEBIT.open_txns({"character_id": "cid-1", "escrow": back}), [txn])
	# Another character loading this file cannot touch the row.
	var stranger := {"character_id": "cid-2", "escrow": back, "inventory": FakeBag.new()}
	assert_false(DEBIT.reconcile(stranger, {}, WORLD).changed)
	assert_eq(DEBIT.open_txns(stranger), [])


func test_real_inventory_object_adapter() -> void:
	var inv: RefCounted = INVENTORY.new(ITEM_DB.new())
	inv.add("reed_fiber", 6)
	inv.add("driftwood", 4)
	var s := {"character_id": "cid-1", "escrow": {}, "inventory": inv}
	var txn: String = DEBIT.begin(s, ACTION, COST, WORLD).txn_id
	assert_eq(inv.count("reed_fiber"), 0)
	assert_eq(DEBIT.reconcile(s, {}, WORLD).needs_submit, [txn])
	assert_eq(inv.count("reed_fiber"), 0, "absence never refunds")
	DEBIT.refund(s, {"txn_id": txn, "world_instance_id": WORLD, "code": "prerequisite"})
	assert_eq(inv.count("reed_fiber"), 6)
	assert_eq(inv.count("driftwood"), 4)
	assert_eq(s.escrow[txn].status, "refunded")


func test_callable_dictionary_adapter() -> void:
	var bag := FakeBag.new()
	bag.items = {"reed_fiber": 6, "driftwood": 4}
	var s := {"character_id": "cid-1", "escrow": {},
		"inventory": {"count": bag.count, "add": bag.add, "remove": bag.remove}}
	assert_true(DEBIT.begin(s, ACTION, COST, WORLD).ok)
	assert_eq(bag.count("driftwood"), 0)
